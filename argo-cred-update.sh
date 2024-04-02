#!/bin/bash

#Mantenedor: Bruno Rodrigues | Max Peixoto
 
<<Description
    Para executar este script, salve este arquivo no diretório "/usr/local/bin/" 
    e aplique permissão de execução "chmod +x envaws" (recomendado) após este utilize o comando: 'argo-cred-update.sh'
    Este script irá fazer a subistituicao do username e passord em todas as secrets do argocd correspondentes ao projeto informado.
Description
 

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
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
echo -e "${RED}|""${YELLOW}  ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES E MAX PEIXOTO""${RED}  |"
echo -e "${RED}======================================================================="
echo -e "${RED}======================================================================="
echo -e "${RED}|""${GREEN}  Alterar username e password das secrets dos projetos do argocd""${RED}     |"
echo -e "${RED}|""${GREEN}  Obs: Necessario logar na conta AWS onde o cluster esta provisionado""${RED}|"
echo -e "${RED}======================================================================="

# Solicitar o nome do cluster ao usuário
echo -e "${GREEN}Por favor, insira o nome do cluster:${NC}"
read cluster_name

# Verifica se o nome do cluster é válido
if [ -z "$cluster_name" ]; then
    echo -e "${GREEN}Nome do projeto não pode estar vazio.${NC}"
    exit 1
fi

# Atualizar a configuração do kubectl com base no nome do cluster
aws eks --region us-east-1 update-kubeconfig --name "$cluster_name"

# Verifica se o cluster é válido antes de prosseguir
if [ $? -eq 0 ]; then
    # Obtém o nome do contexto atualmente logado no cluster
clusterlogin=$(kubectl config current-context)

    # Exibe o nome do cluster apenas se a configuração do kubectl for bem-sucedida
echo
echo -e "Logado no cluster ""${GREEN}$clusterlogin${NC}"
echo

# Solicitar o nome do projeto ao usuário
echo -e "${GREEN}Por favor, insira o nome do projeto:${NC}"
read project_name

# Verifica se o nome do projeto é válido
if [ -z "$project_name" ]; then
    echo -e "${GREEN}Nome do projeto não pode estar vazio.${NC}"
    exit 1
fi


# Obter todos os nomes de secretos que começam com "repo-"
secrets=$(kubectl -n argocd get secrets | grep '^repo-*' | awk '{print $1}')

# Inicialize uma variável para contar o número de segredos encontrados
secret_count=0

# Loop sobre cada nome de segredo
for secret_name in $secrets; do
    # Obter o valor do campo .data.project e decodificar
    project_value=$(kubectl -n argocd get secret $secret_name -o jsonpath='{.data.project}' | base64 --decode)
    
    # Verificar se o valor do projeto é igual ao projeto fornecido pelo usuário
    if [[ "$project_value" == "$project_name" ]]; then
        echo "Secret: $secret_name, Project: $project_value"
((secret_count++)) # Incrementa o contador de segredos
    fi
done    

# Se nenhum segredo for encontrado com o nome do projeto informado, exiba a mensagem de erro
    if [ $secret_count -eq 0 ]; then
        echo -e "${RED}Erro: Nenhum segredo encontrado para o projeto '$project_name' no ArgoCD ou o nome do projeto está inválido.${NC}"
        exit 1
    fi

# Solicitar o nome do username a ser alterdo
echo -e "${GREEN}Por favor, insira o nome do username que deve ser aplicado nas secrets:${NC}"
read new_username

# Solicitar o nome do password a ser alterdo
echo -e "${GREEN}Por favor, insira o nome do password que deve ser aplicado nas secrets:${NC}"
read new_password

    # Loop sobre cada nome de segredo novamente para atualizar as secrets
for secret_name in $secrets; do
    # Obter o valor do campo .data.project e decodificar
    project_value=$(kubectl -n argocd get secret $secret_name -o jsonpath='{.data.project}' | base64 --decode)
    
    # Verificar se o valor do projeto começa com "reverse-logistic"
    if [[ $project_value == $project_name ]]; then
        echo "Atualizando secret: $secret_name"
        
        # Aplicar os novos valores usando kubectl patch
        kubectl -n argocd patch secret $secret_name -p '{"data": {"password": "'$(echo -n $new_password | base64)'"}}'
        kubectl -n argocd patch secret $secret_name -p '{"data": {"username": "'$(echo -n $new_username | base64)'"}}'
        
        echo -e  "${GREEN}Valores atualizados para password: $new_password, username: $new_username${NC}"
    fi
done

else
    echo -e "${GREEN}Nome do cluster inválido.${NC}"
    exit 1
fi