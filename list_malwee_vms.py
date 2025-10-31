import subprocess
import json
import os
import shutil
import csv # Mantido por padrão
import argparse
from openpyxl import Workbook
from openpyxl.utils import get_column_letter

# --- Configuração ---
# Lista de Project IDs da MALWEE (extraída da sua lista)
MALWEE_PROJECT_IDS = [
    "malwee-sandbox",
    "malwee-genguide-0001",
    "malwee-pam01",
    "malwee-pam02",
    "app-20911882937343855441294935",
    "app-41786676537975566569660355",
    "app-50195485003545310949256931",
    "app-53718852972270611961790524",
    "app-83452606237493152734260678",
    "app-91526394010156505384850391",
    "adtsys",
    "app-malwee",
    "app-sap",
    "assinatura-gmail-282617",
    "global-dominion-291311",
    "gsuite-1595426088640",
    "gam-project-s2w-h5r-h29",
    "gam-project-25c-tvx-1iy",
    "grupo-malwee",
    "malwee-245620",
    "voa-firestore-prd",
    "voa-firestore-qas",
    "malwee-disaster-recovery",
    "malwee-analytics-287615",
    "arched-elixir-436516-j4",
    "parque-malwee-310718",
    "projeto-visao-geral",
    "sfpro-dc03e",
    "repasse-de-conhecimento",
    "gcp-malwee-monitor",
    "malwee-245620-dev",
    "malwee-backup-dr",
    "malwee-dmz-adfs",
    "malwee-eda",
    "malwee-gcp-template",
    "malwee-kubernetes-homolog",
    "malwee-lab",
    "malwee-maps",
    "malwee-network",
    "malwee-pam03",
    "malwee-passaporte",
    "malwee-prd-motor-de-regras",
    "malwee-sap",
    "malwee-sap-bolha",
    "malwee-treinamentos"
]

GCLOUD_EXECUTABLE = shutil.which('gcloud')

if not GCLOUD_EXECUTABLE:
    print("Erro: Executável 'gcloud' não encontrado no PATH do sistema.")
    print("Por favor, verifique se o Google Cloud CLI está instalado e configurado corretamente.")
    exit(1)

# --- Função para executar comandos gcloud ---
def run_gcloud_command(command_parts, project_id):
    """
    Executa um comando gcloud CLI para um projeto específico e retorna a saída JSON.
    Adicionado --quiet para evitar prompts interativos.
    """
    try:
        command = [GCLOUD_EXECUTABLE] + command_parts + [f'--project={project_id}', '--format=json', '--quiet'] # Adicionado --quiet
        
        result = subprocess.run(command, capture_output=True, text=True, check=True, env=os.environ)
        
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        if "PERMISSION_DENIED" in e.stderr:
            print(f"Aviso: Permissão negada para listar VMs no projeto '{project_id}'. Pulando...")
        else:
            print(f"Erro ao buscar VMs no projeto '{project_id}': {e.stderr.strip()}")
            print(f"DEBUG: Comando: {' '.join(command)}")
            print(f"DEBUG: Saída stdout: {e.stdout.strip()[:500]}...")
            print(f"DEBUG: Saída stderr: {e.stderr.strip()[:500]}...")
        return None
    except json.JSONDecodeError:
        print(f"Aviso: Saída JSON inválida para o projeto '{project_id}'. Pode não haver VMs ou erro inesperado.")
        return [] 
    except FileNotFoundError:
        print(f"Erro: O executável gcloud não foi encontrado. Verifique seu PATH.")
        return None

# --- Função para sanitizar nomes de planilhas (não mais usada diretamente para single sheet) ---
def sanitize_sheet_name(name):
    invalid_chars = '/\\*?:[]'
    for char in invalid_chars:
        name = name.replace(char, '_')
    return name[:31]

# --- Lógica principal ---
def main():
    parser = argparse.ArgumentParser(description="Busca VMs em projetos GCP da MALWEE e salva a saída em Console, CSV, JSON ou XLSX.")
    parser.add_argument("--format", default="console", choices=["console", "csv", "json", "xlsx"],
                        help="Formato de saída: 'console' (padrão), 'csv', 'json' ou 'xlsx'.")
    parser.add_argument("--output", 
                        help="Nome do arquivo para salvar a saída (sem extensão para CSV/JSON, com extensão para XLSX se quiser nome customizado).")
    args = parser.parse_args()

    if args.format == "xlsx":
        if not args.output:
            args.output = "labels-malwee.xlsx"
        elif not args.output.lower().endswith(".xlsx"):
            args.output += ".xlsx"
    
    if args.format in ["csv", "json"] and not args.output:
        parser.error(f"O nome do arquivo de saída (--output) é obrigatório para os formatos '{args.format}'.")
    
    all_vms_data_raw = [] # Coleta todos os dados das VMs (incluindo labels como dicionário)
    all_unique_label_keys = set() # Coleta todas as chaves de labels únicas

    print(f"Buscando VMs em {len(MALWEE_PROJECT_IDS)} projetos da MALWEE...")
    
    if args.format == "console":
        print("\n" + "="*80 + "\n")
        print(f"{'Projeto':<30} | {'Servidor (VM)':<35} | {'Labels'}") # Este cabeçalho será diferente para XLSX
        print("-" * 100)

    total_vms_found = 0
    
    for project_id in MALWEE_PROJECT_IDS:
        print(f"Processando projeto: '{project_id}'...")
        instances_data = run_gcloud_command(['compute', 'instances', 'list'], project_id)

        if instances_data is None: 
            continue 
        elif not instances_data:
            continue
        
        for instance in instances_data:
            vm_name = instance.get('name', 'N/A')
            labels = instance.get('labels', {}) # Mantém labels como dicionário aqui
            
            vm_entry = {
                'project_id': project_id,
                'vm_name': vm_name,
                'labels': labels, # Armazena o dicionário de labels
            }
            all_vms_data_raw.append(vm_entry)
            total_vms_found += 1

            # Coleta todas as chaves de labels para o cabeçalho dinâmico
            for key in labels.keys():
                all_unique_label_keys.add(key)

            if args.format == "console":
                # Para console, ainda imprime labels como string
                labels_str_console = ", ".join([f"{k}={v}" for k, v in labels.items()]) if labels else "Nenhum"
                print(f"{project_id:<30} | {vm_name:<35} | {labels_str_console}")
        
    print("\n" + "="*80 + "\n") # Separador final
    
    if total_vms_found == 0:
        print("Nenhuma VM encontrada em nenhum dos projetos listados ou erro de permissão em todos eles.")
        print("Certifique-se de que sua conta gcloud tem permissão 'compute.instances.list' em cada projeto.")
        print("Busca concluída.")
        return

    # Processamento da saída (consolidada ou por planilha)
    if args.format == "xlsx":
        wb = Workbook()
        ws = wb.active 
        ws.title = "VMs_Malwee" # Nome da planilha principal

        # Cria o cabeçalho dinâmico para XLSX
        header = ['Projeto', 'Servidor (VM)'] + sorted(list(all_unique_label_keys))
        ws.append(header) 

        for vm_entry in all_vms_data_raw:
            row_data = [vm_entry['project_id'], vm_entry['vm_name']]
            # Adiciona os valores das labels, na ordem do cabeçalho
            for label_key in sorted(list(all_unique_label_keys)):
                row_data.append(vm_entry['labels'].get(label_key, '')) # Deixa vazio se a label não existe
            ws.append(row_data)

        try:
            wb.save(args.output)
            print(f"Busca concluída. {total_vms_found} VMs salvas em '{args.output}' (XLSX, labels em colunas separadas).")
        except Exception as e:
            print(f"Erro ao salvar arquivo XLSX: {e}")
            print("Certifique-se de que o arquivo não está aberto e você tem permissão de escrita.")
    elif args.format == "csv":
        # CSV mantém a lógica anterior de labels como string, mas pode ser expandido de forma similar ao XLSX se desejar
        with open(args.output, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['project_id', 'vm_name', 'labels_string'] # Usar labels_string para compatibilidade
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for vm in all_vms_data_raw:
                # Converte o dicionário de labels para uma string para CSV
                labels_str_csv = ", ".join([f"{k}={v}" for k, v in vm['labels'].items()]) if vm['labels'] else ""
                writer.writerow({
                    'project_id': vm['project_id'],
                    'vm_name': vm['vm_name'],
                    'labels_string': labels_str_csv
                })
        print(f"Busca concluída. {total_vms_found} VMs salvas em '{args.output}' (CSV).")
    elif args.format == "json":
        with open(args.output, 'w', encoding='utf-8') as jsonfile:
            # JSON salva o dicionário de labels original, o que é mais completo
            json.dump(all_vms_data_raw, jsonfile, indent=4, ensure_ascii=False)
        print(f"Busca concluída. {total_vms_found} VMs salvas em '{args.output}' (JSON).")

    if args.format == "console":
        print(f"Busca concluída. Total de VMs encontradas: {total_vms_found}.")
    print("Busca concluída.")


if __name__ == "__main__":
    main()
