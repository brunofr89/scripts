#!/bin/bash
# Mantenedor: Bruno Rodrigues
# ---------------------------------------------------------
# Descrição:
#   Extrai snapshots de todos os projetos da organização ou
#   apenas dos projetos Octa definidos manualmente.
#   Gera um arquivo CSV por projeto.
#
# Uso:
#   Salve este arquivo em /usr/local/bin/
#   chmod +x GCPRelatorioSnapOcta.sh
#   Execute: GCPRelatorioSnapOcta
# ---------------------------------------------------------

# === Cores ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

clear
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
echo -e "${RED}|""${YELLOW} ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES ""${RED}|"
echo -e "${RED}=======================================================================${NC}"

# === Configurações ===
ORG_ID=574387196332
# Lista fixa dos projetos Octa (solicitação oficial)
PROJECTS=(
  "octa-pantheon-sa-east1-001"
  "octa-prod-us-east1-001"
  "octa-prod-southameri-east1-001"
  "octa-prod-sa-east1-003"
  "octa-prod-sa-east1-004"
)

echo ""
echo "🔍 Iniciando extração de snapshots..."
echo ""

for PROJECT in "${PROJECTS[@]}"; do
  echo -e "🧩 Processando projeto: ${GREEN}${PROJECT}${NC}"

  OUTPUT_FILE="${PROJECT}_snapshots.csv"

  # Executa o comando com as colunas e timezone corretos
  gcloud compute snapshots list \
    --project "$PROJECT" \
    --format="csv(name, creationTimestamp.date(tz=BRT), storageLocations, diskSizeGb, storageBytes, status, sourceDisk, sourceSnapshotSchedulePolicy.scope(resourcePolicies).yesno(no=Manual))" \
    --sort-by=creationTimestamp \
    | tee "$OUTPUT_FILE"

  # Confirmação visual
  if [[ -s "$OUTPUT_FILE" ]]; then
    echo -e "✅ CSV salvo em: ${GREEN}${OUTPUT_FILE}${NC}"
  else
    echo -e "🚫 Nenhum snapshot encontrado em ${YELLOW}${PROJECT}${NC}"
  fi

  echo ""
done

echo -e "${GREEN}🎉 Extração concluída! Todos os relatórios estão no diretório atual.${NC}"
