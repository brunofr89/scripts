#!/bin/bash

#Mantenedor: Bruno Rodrigues | Max Peixoto
 
<<Description
    Para executar este script, salve este arquivo no diretório "/usr/local/bin/" 
    e aplique permissão de execução "chmod +x envaws" (recomendado) após este utilize o comando: 'cluster-url-search'
    Este script realiza uma busca por um HOST(URL) em todos os ingress de todos os namespaces clusters configurados para identificar a qual cluster pertence a URL
Description

#Preto      \033[0;30m
#Vermelho   \033[0;31m
#Verde      \033[0;32m
#Amarelo    \033[0;33m
#Magenta    \033[0;35m
#Ciano      \033[0;36m

WHITE="\033[0;37m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"

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
echo -e "${RED}|""${YELLOW}  ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES E MAX PEIXOTO""${RED}  |"
echo -e "${RED}======================================================================="
echo
echo -e "${WHITE}Informe o HOST(URL) do recurso que deseja encontrar a qual cluster pertence"

# Função para imprimir em vermelho
print_in_red() {
    echo -e "$RED$1$WHITE"
}

# Função para imprimir em amarelo
print_in_yellow() {
    echo -e "$YELLOW$1$WHITE"
}

# Função para imprimir em azul
print_in_blue() {
    echo -e "$BLUE$1$WHITE"
}

# Função para imprimir em verde
print_in_green() {
    echo -e "$GREEN$1$WHITE"
}

# Solicitar o nome do cluster ao usuário
echo -e "${BLUE}Por favor, insira o nome do cluster:"
read cluster_name

# Atualizar a configuração do kubectl com base no nome do cluster
aws eks --region us-east-1 update-kubeconfig --name "$cluster_name"

# Verifica se o cluster é válido antes de prosseguir
if [ $? -eq 0 ]; then
    # Obtém o nome do contexto atualmente logado no cluster
    clusterlogin=$(kubectl config current-context)

    # Exibe o nome do cluster apenas se a configuração do kubectl for bem-sucedida
    echo
    echo -e "${BLUE}Logado no cluster ""${GREEN}$clusterlogin"
    echo

    # Pergunta pela URL que deve ser buscada
    echo -e "${WHITE}Informe a URL para busca:"
    read url_to_search

    # Tenta executar o comando até 3 vezes em caso de falha
    for attempt in {1..3}; do
        # Comando para buscar a URL nos ConfigMaps e exibir o namespace e nome do ConfigMap
        results=$(kubectl get cm --all-namespaces -o json | jq -r --arg url "$url_to_search" '.items[] | select(.data | tostring | contains($url)) | .metadata.namespace + " " + .metadata.name')

        if [ $? -eq 0 ] && [ -n "$results" ]; then
            echo -e "${GREEN}URL encontrada nos seguintes ConfigMaps:\e[0m"
            
            # Organiza os resultados por namespace e exibe com cores
            echo "$results" | awk -v yellow="$YELLOW" -v blue="$BLUE" -v green="$GREEN" -v white="$WHITE" '
            {
                namespace=$1
                configmap=$2
                configmaps[namespace]=configmaps[namespace] configmap"\n"
            }
            END {
                for (ns in configmaps) {
                    # Imprime o namespace com a cor amarela
                    print yellow "ConfigMaps do namespace " ns white ":"
                    # Imprime os nomes dos configmaps em azul
                    print blue configmaps[ns] white
                }
            }
            '
            break
        else
            echo "Tentativa $attempt falhou. Tentando novamente..."
            if [ $attempt -eq 3 ]; then
                echo "Erro: Não foi possível encontrar a URL nos ConfigMaps após 3 tentativas."
            fi
            sleep 2  # Espera 2 segundos antes da próxima tentativa
        fi
    done
else
    print_in_red "Falha ao atualizar o kubeconfig. Verifique a conexão com o AWS EKS."
fi