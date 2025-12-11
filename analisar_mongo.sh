#!/bin/bash

echo "===== ANALISADOR DE CONEXÕES MONGODB ====="
echo ""

read -p "Informe o alias do cluster (ex.: kocta-prod-us-east1-001): " CLUSTER_ALIAS
read -p "Informe o namespace (ex.: core): " NS
read -p "Informe o replicaset (prefixo dos pods, ex.: persons-api-87d4b7c79): " RS

# 1. Extraindo o comando real do alias no .zshrc
CLUSTER_CMD=$(grep "^alias $CLUSTER_ALIAS=" ~/.zshrc | sed -E "s/alias $CLUSTER_ALIAS=\"(.*)\"/\1/")

if [ -z "$CLUSTER_CMD" ]; then
    echo "Alias '$CLUSTER_ALIAS' não encontrado no ~/.zshrc"
    exit 1
fi

echo "Alias encontrado:"
echo "$CLUSTER_ALIAS → $CLUSTER_CMD"
echo ""

# Função wrapper para executar comandos kubectl com o kubeconfig correto
k() {
    eval "$CLUSTER_CMD $*"
}

echo "Coletando pods..."
PODS=$(k get pods -n "$NS" -o name | grep "$RS")

if [ -z "$PODS" ]; then
    echo "Nenhum pod encontrado para o replicaset '$RS'."
    exit 1
fi

echo "Pods encontrados:"
echo "$PODS"
echo ""

LOG_RESULT=""
FOUND_ERRORS=0

FILTER_PATTERN="(pool|connection|conn|socket|channel|maxpool|poolsize|maxconnections|too many connections|exhausted|exhaust|leak|timeout|timed out|MongoTimeoutError|MongoNetworkError|MongoServerError|network error|ECONN|ECONNREFUSED|ECONNRESET|failed to connect|cannot connect|no suitable servers|server selection|topology|replica|primary stepdown|heartbe|keepalive|backlog|queue|queued)"

echo "Iniciando análise dos logs..."
echo ""

for pod in $PODS; do
    POD_NAME=$(echo "$pod" | cut -d'/' -f2)
    echo "===== ANALISANDO POD: $POD_NAME ====="

    LOGS=$(k logs -n "$NS" "$pod" | grep -Ei "$FILTER_PATTERN")

    if [ -z "$LOGS" ]; then
        echo "Nenhuma evidência encontrada neste pod."
        LOG_RESULT+="\n### Pod: $POD_NAME\nNenhuma evidência encontrada.\n"
    else
        FOUND_ERRORS=1
        echo "[ERROS ENCONTRADOS]"
        echo "$LOGS"
        LOG_RESULT+="\n### Pod: $POD_NAME\n\`\`\`\n$LOGS\n\`\`\`\n"
    fi

    echo ""
done

echo ""
echo "===== GERANDO RESPOSTA PARA O CHAMADO ====="
echo ""

if [ $FOUND_ERRORS -eq 0 ]; then
    CONCLUSAO="Nenhum erro relacionado a conexões, pool, timeouts ou saturação foi encontrado nos logs dos pods do replicaset $RS."
else
    CONCLUSAO="Foram encontradas evidências de timeouts, saturação de pool ou erros relacionados à conectividade. Os pods com ocorrências estão listados acima."
fi

RESP=$(cat <<EOF

## Análise – Excesso de conexões no MongoDB
Realizei a análise completa dos pods do replicaset **$RS** no cluster **$CLUSTER_ALIAS**, namespace **$NS**.  
Evidências coletadas abaixo:

$LOG_RESULT

---

## Conclusão
$CONCLUSAO

Mantenho o ticket em acompanhamento.
EOF
)

echo -e "$RESP"
echo ""
echo "===== FIM ====="
