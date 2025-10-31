#!/bin/bash

# Lista de todos os projetos fornecidos
PROJETOS=(
  bzj-cms
  entrepay-portal-dev
  entrepay-acquiring-prod
  entrepayments
  entrepay-acquiring-dev
  entrepayments-system-prd
  entrepayments-netwok-prd
  istoe-cms-prd
  istoe-pub
  istoepub-dev-v2
  istoepub-iac
  istoepub-main-v2
  istoepub-prod-v2
  istoepub-test-v2
  rockym-cms
)

declare -A PROJETOS_COM_RUN

echo "🔍 Verificando quais projetos têm serviços Cloud Run..."
total=${#PROJETOS[@]}
count=1

for PROJETO in "${PROJETOS[@]}"; do
  echo -ne "  [$count/$total] Verificando projeto: $PROJETO...\r"
  
  SERVICOS=$(timeout 10s gcloud run services list \
    --platform managed \
    --project="$PROJETO" \
    --format="value(metadata.name)" 2>/dev/null)

  if [ $? -eq 124 ]; then
    echo "⏱️ Timeout verificando $PROJETO"
  elif [ -n "$SERVICOS" ]; then
    PROJETOS_COM_RUN["$PROJETO"]="$SERVICOS"
  fi

  ((count++))
done

echo ""
echo "📋 Projetos com serviços Cloud Run encontrados:"
i=1
for PROJ in "${!PROJETOS_COM_RUN[@]}"; do
  echo "  [$i] $PROJ"
  ((i++))
done
echo "  [0] Rodar em TODOS os projetos acima"

read -p "Digite o número do projeto que deseja investigar (ou 0 para todos): " ESCOLHA
read -p "Digite o domínio que deseja buscar (ex: gooutside.com.br): " DOMINIO

echo ""
echo "⏱️ Escolha a janela de tempo para os logs:"
echo "  [ 1] Últimos 5 minutos"
echo "  [ 2] Últimos 10 minutos"
echo "  [ 3] Últimos 15 minutos"
echo "  [ 4] Últimos 30 minutos"
echo "  [ 5] Última 1 hora"
echo "  [ 6] Últimas 2 horas"
echo "  [ 7] Últimas 3 horas"
echo "  [ 8] Últimas 6 horas"
echo "  [ 9] Últimas 12 horas"
echo " [10] Últimas 24 horas"
echo " [11] Últimos 2 dias"
echo " [12] Últimos 3 dias"
echo " [13] Últimos 4 dias"
echo " [14] Últimos 5 dias"

read -p "Escolha a opção (1-14): " TEMPO_OPCAO

case $TEMPO_OPCAO in
  1) DELTA="-5 minutes" ;;
  2) DELTA="-10 minutes" ;;
  3) DELTA="-15 minutes" ;;
  4) DELTA="-30 minutes" ;;
  5) DELTA="-1 hour" ;;
  6) DELTA="-2 hours" ;;
  7) DELTA="-3 hours" ;;
  8) DELTA="-6 hours" ;;
  9) DELTA="-12 hours" ;;
  10) DELTA="-24 hours" ;;
  11) DELTA="-2 days" ;;
  12) DELTA="-3 days" ;;
  13) DELTA="-4 days" ;;
  14) DELTA="-5 days" ;;
  *) echo "❌ Opção inválida."; exit 1 ;;
esac

FIM=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INICIO=$(date -u -d "$DELTA" +"%Y-%m-%dT%H:%M:%SZ")

echo ""
echo "🔎 Iniciando busca por logs entre $INICIO e $FIM para o domínio '$DOMINIO'"
echo ""

buscar_logs() {
  local PROJETO="$1"
  local SERVICOS="$2"

  echo "🌐 Projeto: $PROJETO"

  for SERVICO in $SERVICOS; do
    echo "   🚀 Serviço: $SERVICO"
    gcloud logging read \
      "resource.type=cloud_run_revision \
      AND resource.labels.service_name=$SERVICO \
      AND timestamp>=\"$INICIO\" \
      AND timestamp<=\"$FIM\" \
      AND httpRequest.requestUrl:\"$DOMINIO\"" \
      --project="$PROJETO" \
      --limit=10 \
      --format="table(timestamp, httpRequest.requestMethod, httpRequest.requestUrl, httpRequest.status)" || \
      echo "    ⚠️  Nenhum log ou erro ao buscar."
  done
  echo ""
}

if [ "$ESCOLHA" == "0" ]; then
  for PROJETO in "${!PROJETOS_COM_RUN[@]}"; do
    buscar_logs "$PROJETO" "${PROJETOS_COM_RUN[$PROJETO]}"
  done
else
  i=1
  for PROJETO in "${!PROJETOS_COM_RUN[@]}"; do
    if [ "$i" == "$ESCOLHA" ]; then
      buscar_logs "$PROJETO" "${PROJETOS_COM_RUN[$PROJETO]}"
      break
    fi
    ((i++))
  done
fi

echo "✅ Busca concluída."
