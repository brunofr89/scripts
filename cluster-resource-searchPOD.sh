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

    # Listar todos os pods no cluster e executar exec em cada um, com grep para a URL
    echo -e "${GREEN}Buscando URL nos pods...${WHITE}"

    # Usando kubectl para listar todos os pods e rodar o exec para verificar as variáveis de ambiente
    kubectl get pods --all-namespaces -o custom-columns=":metadata.namespace,:metadata.name" | \
    while read namespace pod; do
        # Ignorar cabeçalho
        if [[ "$namespace" != "NAMESPACE" && -n "$namespace" && -n "$pod" ]]; then
            # Executa diretamente o comando env no pod, sem depender de shell
            result=$(kubectl exec -n "$namespace" "$pod" -- env 2>/dev/null | grep -q "$url_to_search" && echo "$namespace $pod")
            
            # Verifica se encontrou a URL
            if [ -n "$result" ]; then
                # Armazena o namespace e o nome do pod
                if [[ ! " ${found_namespaces[@]} " =~ " ${namespace} " ]]; then
                    # Se o namespace ainda não foi encontrado, imprime o namespace
                    echo -e "${YELLOW}URL encontrada no namespace $namespace"
                    # Adiciona o namespace à lista para não imprimir novamente
                    found_namespaces+=("$namespace")
                fi
                # Imprime o pod que contém a URL
                echo -e "${GREEN}pod ${BLUE}$pod${WHITE}"
            fi
        fi
    done

else
    print_in_red "Falha ao atualizar o kubeconfig. Verifique a conexão com o AWS EKS."
fi