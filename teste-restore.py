from googleapiclient import discovery
from oauth2client.client import GoogleCredentials
from datetime import datetime
import sys
import time

PROJECTS = [
    "octa-prod-us-east1-001",
    "octa-prod-southameri-east1-001",
    "octa-prod-sa-east1-003",
    "octa-prod-sa-east1-004",
    "octa-pantheon-sa-east1-001"
]

def get_compute_service():
    credentials = GoogleCredentials.get_application_default()
    return discovery.build('compute', 'v1', credentials=credentials)

def escolher_projeto():
    print("Selecione o projeto:")
    for idx, proj in enumerate(PROJECTS, start=1):
        print(f"{idx} - {proj}")
    escolha = input("Digite o número do projeto: ").strip()
    try:
        idx = int(escolha) - 1
        return PROJECTS[idx]
    except (IndexError, ValueError):
        print("❌ Projeto inválido.")
        sys.exit(1)

def obter_zona_da_instancia(compute, project, instance_name):
    request = compute.instances().aggregatedList(project=project)
    while request is not None:
        response = request.execute()
        for zone, items in response.get('items', {}).items():
            for instance in items.get('instances', []):
                if instance['name'] == instance_name:
                    return instance['zone'].split("/")[-1], instance
        request = compute.instances().aggregatedList_next(previous_request=request, previous_response=response)

    print("❌ Instância não encontrada.")
    sys.exit(1)

def listar_discos_adicionais(instance):
    adicionais = []
    for disk in instance['disks']:
        if not disk.get('boot', False):
            adicionais.append(disk['source'].split('/')[-1])
    return adicionais

def obter_disco_boot(instance):
    for disk in instance['disks']:
        if disk.get('boot', False):
            source_image = disk.get('initializeParams', {}).get('sourceImage')
            # Pode não existir a chave sourceImage se o boot for um disco já existente sem sourceImage
            return disk['source'].split('/')[-1], source_image if source_image else None
    return None, None

def selecionar_disco(discos):
    if not discos:
        print("❌ Nenhum disco adicional encontrado.")
        sys.exit(1)
    print("\nDiscos adicionais encontrados:")
    for i, d in enumerate(discos, 1):
        print(f"{i} - {d}")
    idx = input("Selecione o número do disco para restaurar: ").strip()
    try:
        return discos[int(idx) - 1]
    except (IndexError, ValueError):
        print("❌ Disco inválido.")
        sys.exit(1)

def buscar_snapshots(compute, project, disk_name, zone):
    print(f"\n🔍 Buscando snapshots do disco '{disk_name}' no projeto '{project}'...")
    source_disk_url = f"https://www.googleapis.com/compute/v1/projects/{project}/zones/{zone}/disks/{disk_name}"
    request = compute.snapshots().list(project=project)
    snapshots = []
    while request is not None:
        response = request.execute()
        for snapshot in response.get('items', []):
            if snapshot.get('sourceDisk') == source_disk_url:
                snapshots.append(snapshot)
        request = compute.snapshots().list_next(previous_request=request, previous_response=response)

    if not snapshots:
        print("❌ Nenhum snapshot encontrado para esse disco.")
        sys.exit(1)

    snapshots.sort(key=lambda s: s['creationTimestamp'], reverse=True)
    return snapshots

def obter_detalhes_do_disco(compute, project, zone, disk_name):
    response = compute.disks().get(project=project, zone=zone, disk=disk_name).execute()
    return {
        "sizeGb": response.get("sizeGb"),
        "zone": zone,
        "region": zone[:-2],
        "diskType": response.get("type").split("/")[-1]
    }

def obter_subrede_da_instancia(instance):
    try:
        return instance["networkInterfaces"][0]["subnetwork"]
    except (KeyError, IndexError):
        print("❌ Subrede da instância não encontrada.")
        sys.exit(1)

def obter_tipo_da_instancia(instance):
    return instance['machineType'].split("/")[-1]

def aguardar_disco_pronto(compute, project, zone, disk_name, timeout=120):
    print(f"Aguardando disco '{disk_name}' ficar pronto...", end='', flush=True)
    for _ in range(timeout):
        disk = compute.disks().get(project=project, zone=zone, disk=disk_name).execute()
        status = disk.get('status')
        if status == 'READY':
            print(" Pronto!")
            return True
        print(".", end='', flush=True)
        time.sleep(1)
    print("\n❌ Timeout esperando disco ficar pronto.")
    sys.exit(1)

def criar_disco(compute, project, zone, snapshot_name, nome_disco_teste, tamanho_gb):
    print(f"\n🚧 Criando disco '{nome_disco_teste}' a partir do snapshot '{snapshot_name}'...")
    config = {
        "name": nome_disco_teste,
        "description": "Deletar disco após o teste de restore",
        "sizeGb": tamanho_gb,
        "type": f"zones/{zone}/diskTypes/pd-ssd",
        "sourceSnapshot": f"projects/{project}/global/snapshots/{snapshot_name}",
        "labels": {
            "teste-restore": "deletar",
            "owner": "ipnet"
        }
    }
    compute.disks().insert(project=project, zone=zone, body=config).execute()

def criar_vm_teste(compute, project, zone, nome_vm_teste, nome_disco_teste, boot_image_link, subnetwork_selflink, tipo_instancia):
    print(f"\n🚧 Criando VM '{nome_vm_teste}' com disco restaurado '{nome_disco_teste}'...")
    config = {
        "name": nome_vm_teste,
        "machineType": f"zones/{zone}/machineTypes/{tipo_instancia}",
        "disks": [
            {
                "boot": True,
                "autoDelete": True,
                "initializeParams": {
                    "sourceImage": boot_image_link,
                    "diskSizeGb": "10",
                    "diskType": f"zones/{zone}/diskTypes/pd-balanced"
                }
            },
            {
                "boot": False,
                "autoDelete": True,
                "source": f"projects/{project}/zones/{zone}/disks/{nome_disco_teste}"
            }
        ],
        "networkInterfaces": [
            {
                "subnetwork": subnetwork_selflink
            }
        ],
        "labels": {
            "teste-restore": "deletar",
            "owner": "ipnet"
        },
        "deletionProtection": False
    }
    compute.instances().insert(project=project, zone=zone, body=config).execute()

def main():
    project = escolher_projeto()
    instance_name = input("\nDigite o nome da instância: ").strip()
    compute = get_compute_service()
    
    zone, instance = obter_zona_da_instancia(compute, project, instance_name)
    discos_adicionais = listar_discos_adicionais(instance)
    disco_escolhido = selecionar_disco(discos_adicionais)
    boot_disk_name, boot_image_original = obter_disco_boot(instance)
    detalhes_disco = obter_detalhes_do_disco(compute, project, zone, disco_escolhido)
    snapshots = buscar_snapshots(compute, project, disco_escolhido, zone)
    snapshot = snapshots[0]
    subnetwork = obter_subrede_da_instancia(instance)
    tipo_instancia_original = obter_tipo_da_instancia(instance)

    # Exibir detalhes do snapshot escolhido
    print("\nSnapshot mais recente encontrado:")
    print(f"   Nome do snapshot......: {snapshot['name']}")
    print(f"   Criado em.............: {snapshot['creationTimestamp']}")
    print(f"   Fonte do snapshot.....: {snapshot['sourceDisk']}")
    print(f"   Tamanho do disco......: {detalhes_disco['sizeGb']} GB")
    print(f"   Zona do disco.........: {detalhes_disco['zone']}")
    print(f"   Tipo do disco.........: {detalhes_disco['diskType']}")

    # Escolha do tipo da instância
    print(f"\nTipo da instância original: {tipo_instancia_original}")
    print("Deseja usar o tipo da instância original ou o padrão?")
    print("1 - Usar tipo da instância original")
    print("2 - Usar tipo padrão: e2-highcpu-4 (4vCPU, 4GB)")
    tipo_instancia_opcao = input("Digite 1 ou 2: ").strip()
    if tipo_instancia_opcao == "1":
        tipo_instancia = tipo_instancia_original
    else:
        tipo_instancia = "e2-highcpu-4"

    # Escolha da imagem de boot
    imagem_padrao = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    print(f"\nImagem de boot da VM original: {boot_image_original if boot_image_original else '(não detectada)'}")
    print(f"Deseja usar a imagem da VM original ou o padrão Ubuntu 22.04 LTS?")
    print("1 - Usar imagem da VM original")
    print("2 - Usar imagem padrão: Ubuntu 22.04 LTS")
    imagem_opcao = input("Digite 1 ou 2: ").strip()
    if imagem_opcao == "1" and boot_image_original:
        boot_image = boot_image_original
    else:
        boot_image = imagem_padrao

    today = datetime.today().strftime('%Y%m%d')
    nome_disco_teste = f"ipnet-bkp-restore-{disco_escolhido}-{today}-deletar"
    nome_vm_teste = f"bkp-teste-restore-{instance_name}"

    print("\n📋 Resumo do que será criado:")
    print(f"- Projeto.................: {project}")
    print(f"- Instância original......: {instance_name}")
    print(f"- Disco original..........: {disco_escolhido}")
    print(f"- Snapshot mais recente...: {snapshot['name']}")
    print(f"- Zona/Região.............: {zone} / {detalhes_disco['region']}")
    print(f"- Tamanho do disco........: {detalhes_disco['sizeGb']} GB")
    print(f"- Tipo de disco (original): {detalhes_disco['diskType']}")
    print(f"- Disco de teste..........: {nome_disco_teste}")
    print(f"- VM de teste.............: {nome_vm_teste}")
    print(f"- Tipo da instância.......: {tipo_instancia}")
    print(f"- Boot disk da VM original: {boot_disk_name}")
    print(f"- Imagem escolhida........: {boot_image}")
    print(f"- Labels..................: teste-restore=deletar, owner=ipnet")
    print(f"- Deletar com a VM........: ✅ Sim")
    print(f"- Subrede compartilhada...: {subnetwork}")

    print("\n⚠️ Confirme para continuar com a criação dos recursos.")
    confirm = input("Deseja continuar? (s/N): ").strip().lower()
    if confirm != 's':
        print("❌ Cancelado pelo usuário.")
        sys.exit(0)

    criar_disco(compute, project, zone, snapshot['name'], nome_disco_teste, detalhes_disco['sizeGb'])

    aguardar_disco_pronto(compute, project, zone, nome_disco_teste)

    criar_vm_teste(compute, project, zone, nome_vm_teste, nome_disco_teste, boot_image, subnetwork, tipo_instancia)

    print("\n✅ Recursos criados com sucesso.")
    print("ℹ️ Lembrete: delete a VM e o disco restaurado manualmente após o teste.")

if __name__ == '__main__':
    main()
