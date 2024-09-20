#!/bin/zsh

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
#Azul       \033[0;34m
#Magenta    \033[0;35m
#Ciano      \033[0;36m

WHITE="\033[0;37m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"

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
echo -e "${WHITE}Informe o HOST(URL) que deseja encontrar a qual cluster pertence"

# Função para imprimir em vermelho
print_in_red() {
    echo "\033[31m$1\033[0m"
}

# Pergunta pela URL que deve ser buscada
read "url_to_search?Enter the URL to search for: "

# Caminhos dos kubeconfigs
clusters=(
    "kecom-drogaraia-dev:$HOME/.kube/kube_config/onp/config-rd-dev"
    "kecom-drogasil-dev:$HOME/.kube/kube_config/onp/config-rd-qa-stg"
    "kecom-ecommerce-dev:$HOME/.kube/kube_config/onp/config-rd-prod"
    "kecom-rd-eks-mage2-prod:$HOME/.kube/kube_config/onp/config-oms1-devqastg"
    "kecom-rdsaude-drogasil-stg:$HOME/.kube/kube_config/onp/config-oms1-prod"
    "kecom-rdsaude-raia-stg:$HOME/.kube/kube_config/aws/config-aws-rd-dev"
    "kecom-drogaraia-qa:$HOME/.kube/kube_config/aws/config-aws-rd-qa"
    "kecom-drogasil-qa:$HOME/.kube/kube_config/aws/config-aws-rd-stg"
    "kecom-ecommerce-qa:$HOME/.kube/kube_config/aws/config-aws-rd-prd"
    "kecom-rdsaude-drogasil-dev:$HOME/.kube/kube_config/aws/config-logistics-dev"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-logistics-qa"
    "kecom-drogaraia-stg:$HOME/.kube/kube_config/aws/config-logistics-stg"
    "kecom-drogasil-stg:$HOME/.kube/kube_config/aws/config-logistics-prd"
    "kecom-rdsaude-drogasil-dev:$HOME/.kube/kube_config/aws/config-opf-dev"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-opf-qa"
    "kecom-drogaraia-stg:$HOME/.kube/kube_config/aws/config-opf-stg"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-opf-prd"
    "kecom-drogaraia-dev:$HOME/.kube/kube_config/aws/config-aws-univ-dev"
    "kecom-drogasil-qa:$HOME/.kube/kube_config/aws/config-aws-univ-qa"
    "kecom-drogaraia-stg:$HOME/.kube/kube_config/aws/config-aws-univ-stg"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-aws-univ-prd"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-sandbox-dev"
    "kecom-ecommerce-dev:$HOME/.kube/kube_config/aws/config-aws-ecommerce-dev"
    "kecom-drogasil-dev:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogasil-dev"
    "kecom-drogaraia-dev:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogaraia-dev"
    "kecom-rdsaude-drogasil-dev:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-drogasil-dev"
    "kecom-rdsaude-raia-dev:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-raia-dev"
    "kecom-ecommerce-qa:$HOME/.kube/kube_config/aws/config-aws-ecommerce-qa"
    "kecom-drogasil-qa:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogasil-qa"
    "kecom-drogaraia-qa:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogaraia-qa"
    "kecom-rdsaude-drogasil-qa:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-drogasil-qa"
    "kecom-rdsaude-raia-qa:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-raia-qa"
    "kecom-ecommerce-stg:$HOME/.kube/kube_config/aws/config-aws-ecommerce-stg"
    "kecom-drogasil-stg:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogasil-stg"
    "kecom-drogaraia-stg:$HOME/.kube/kube_config/aws/config-aws-ecommerce-drogaraia-stg"
    "kecom-rdsaude-drogasil-stg:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-drogasil-stg"
    "kecom-rdsaude-raia-stg:$HOME/.kube/kube_config/aws/config-aws-ecommerce-rdsaude-raia-stg"
    "kecom-rd-eks-mage2-prod:$HOME/.kube/kube_config/aws/config-aws-rd-eks-mage2-prod"
    "kdevops_tools:$HOME/.kube/kube_config/aws/config-aws-devops-tools"
    "kdevops_opf:$HOME/.kube/kube_config/aws/config-aws-devops-opf"
    "kdevops_devportal:$HOME/.kube/kube_config/aws/config-aws-devops-devportal"
    "kdevops_digitals:$HOME/.kube/kube_config/aws/config-aws-devops-digitals"
    # Adicione os demais clusters conforme necessário
)

# Arrays para armazenar clusters com erro e os resultados de sucesso
failed_clusters=()
success_output=""

# Executa o comando para cada cluster
for cluster in "${clusters[@]}"; do
    IFS=':' read -r cluster_name kubeconfig <<< "$cluster"
    echo "Checking cluster: $cluster_name with kubeconfig: $kubeconfig"
    
    # Tenta executar o comando até 3 vezes em caso de timeout
    for attempt in {1..3}; do
        results=$(kubectl --kubeconfig="$kubeconfig" get ingress --all-namespaces 2>&1 | grep "$url_to_search")
        
        if [ $? -eq 0 ] && [ -n "$results" ]; then
            # Obter o nome do cluster e namespace
            cluster_id=$(kubectl --kubeconfig="$kubeconfig" config view --minify -o jsonpath='{.clusters[0].name}')
            namespace=$(echo "$results" | awk '{print $1}')  # Supondo que o namespace esteja na primeira coluna
            success_output+=" ${GREEN}URL:\e[0m       $url_to_search\n ${GREEN}CLUSTER:\e[0m   $cluster_id\n ${GREEN}NAMESPACE:\e[0m $namespace\n"
            break
        else
            echo "Attempt $attempt failed for cluster $cluster_name. Retrying..."
            if [ $attempt -eq 3 ]; then
                failed_clusters+=("$cluster_name")
            fi
            sleep 2  # Espera 2 segundos antes da próxima tentativa
        fi
    done
done


# Exibe os clusters que falharam, se houver
if [ ${#failed_clusters[@]} -gt 0 ]; then
    echo "Clusters with errors:"
    for failed_cluster in "${failed_clusters[@]}"; do
        print_in_red "$failed_cluster"
        echo "Erro: Falha ao tentar conectar ou buscar a URL."
    done
fi

# Exibe os clusters que tiveram sucesso
if [ -n "$success_output" ]; then
    echo -e "${GREEN}"Resultados encontrados:"\n"
    print_in_red ""${WHITE}$success_output""
fi