#!/bin/bash
#Mantenedor: Bruno Rodrigues
 
<<Description
    Para executar este script, salve este arquivo no diretório "/usr/local/bin/" 
    e aplique permissão de execução "chmod +x GCPRelatorioSnapOcta.sh " (recomendado) após este utilize o comando: 'GCPRelatorioSnapOcta'
Description

#Preto      \033[0;30m
#Vermelho   \033[0;31m
#Verde      \033[0;32m
#Amarelo    \033[0;33m
#Magenta    \033[0;35m
#Ciano      \033[0;36m

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}#######################################################################"
echo -e "${RED}#############################""${GREEN}.............""${RED}#############################"
echo -e "${RED}#########################""${GREEN}.....................""${RED}#########################"
echo -e "${RED}######################""${GREEN}...........................""${RED}######################"
echo -e "${RED}####################""${GREEN}...............................""${RED}####################"
echo -e "${RED}###################""${GREEN}.................................""${RED}###################"
echo -e "${RED}##################""${GREEN}...................................""${RED}##################"
echo -e "${RED}##################""${GREEN}.........H.................H.......""${RED}##################"
echo -e "${RED}##################""${GREEN}........HHH...............HHH......""${RED}##################"
echo -e "${RED}##################""${GREEN}.......HHHHH.............HHHHH.....""${RED}##################"
echo -e "${RED}##################""${GREEN}...................................""${RED}##################"
echo -e "${RED}##################""${GREEN}.................H.................""${RED}##################"
echo -e "${RED}########""${GREEN}......""${RED}####""${GREEN}................HHH................""${RED}###""${GREEN}......""${RED}#########"
echo -e "${RED}#######""${GREEN}.......""${RED}######""${GREEN}.............HHHHH.............""${RED}#####""${GREEN}.......""${RED}########"
echo -e "${RED}######""${GREEN}............""${RED}###""${GREEN}.............................""${RED}###""${GREEN}...........""${RED}#######"
echo -e "${RED}######""${GREEN}..........................................................""${RED}#######"
echo -e "${RED}#####""${GREEN}......""${RED}###""${GREEN}...........................................""${RED}###""${GREEN}.....""${RED}######"
echo -e "${RED}#####################""${GREEN}.....|HH|HH|HH|HH|HH|HH|.....""${RED}#####################"
echo -e "${RED}#####################""${GREEN}.....|--|--|--|--|--|--|.....""${RED}#####################"
echo -e "${RED}######""${GREEN}....""${RED}#########""${GREEN}.......|HH|HH|HH|HH|HH|HH|.......""${RED}#########""${GREEN}....""${RED}######"
echo -e "${RED}#####""${GREEN}......""${RED}#""${GREEN}...............................................""${RED}#""${GREEN}......""${RED}#####"
echo -e "${RED}######""${GREEN}...........................................................""${RED}######"
echo -e "${RED}#######""${GREEN}........""${RED}###########""${GREEN}...................""${RED}##########""${GREEN}.........""${RED}#######"
echo -e "${RED}########""${GREEN}......""${RED}###########################################""${GREEN}......""${RED}########"
echo -e "${RED}#########""${GREEN}....""${RED}#############################################""${GREEN}....""${RED}#########"
echo -e "${RED}======================================================================="
echo -e "${RED}|""${YELLOW}  ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES""${RED}                 |"
echo -e "${RED}=======================================================================${NC}"

ORG_ID=574387196332
ALL_PROJECTS=()

GREEN='\033[0;32m'
NC='\033[0m' # Sem cor (reset)

echo "🔍 Buscando projetos na organização $ORG_ID..."

# Listar projetos diretamente na organização
ORG_PROJECTS=$(gcloud projects list \
  --filter="parent.type=organization parent.id=$ORG_ID" \
  --format="value(projectId)")
ALL_PROJECTS+=($ORG_PROJECTS)

# Listar pastas da organização
FOLDER_IDS=$(gcloud resource-manager folders list \
  --organization=$ORG_ID \
  --format="value(name)")

# Iterar sobre as pastas para listar projetos
for FOLDER in $FOLDER_IDS; do
  FOLDER_ID=$(echo $FOLDER | cut -d'/' -f2)
  PROJECTS=$(gcloud projects list \
    --filter="parent.type=folder parent.id=$FOLDER_ID" \
    --format="value(projectId)")
  ALL_PROJECTS+=($PROJECTS)
done

# Verificar quais projetos têm snapshots
echo ""
echo "💾 Verificando quais projetos têm snapshots..."

for PROJECT in "${ALL_PROJECTS[@]}"; do
  echo "🔎 Checando snapshots no projeto: $PROJECT"
  gcloud config set project "$PROJECT" --quiet > /dev/null 2>&1

  SNAPSHOTS=$(gcloud compute snapshots list \
    --format="csv(name, creationTimestamp, storageLocations, diskSizeGb, storageBytes, sourceDisk)" \
    --quiet 2>/dev/null)

  if [[ -n "$SNAPSHOTS" && "$SNAPSHOTS" != "name,creationTimestamp,storageLocations,diskSizeGb,storageBytes,sourceDisk" ]]; then
    echo -e "✅ Projeto com snapshots: ${GREEN}$PROJECT${NC}"

    # Cria um arquivo específico para cada projeto
    FILE_NAME="${PROJECT}_snapshot.csv"
    echo "projectId,name,creationTimestamp,storageLocations,diskSizeGb,storageBytes,sourceDisk" > "$FILE_NAME"

    # Adiciona os snapshots no arquivo CSV do projeto
    echo "$SNAPSHOTS" | tail -n +2 | while IFS= read -r line; do
      echo "$PROJECT,$line" >> "$FILE_NAME"
    done

    echo "📄 Snapshots do projeto $PROJECT salvos em: $FILE_NAME"
  else
    echo "🚫 Sem snapshots em: $PROJECT"
  fi
done
