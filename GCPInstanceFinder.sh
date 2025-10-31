#!/bin/bash
#Mantenedor: Bruno Rodrigues
 
<<Description
    Para executar este script, salve este arquivo no diretório "/usr/local/bin/" 
    e aplique permissão de execução "chmod +x InstanceFinder.sh " (recomendado) após este utilize o comando: 'InstanceFinder'
    Este script realiza uma busca por uma instanciaem todos os projetos que o usuário tiver acesso
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

# Solicita o ID da organização ao usuário
read -p "Digite o ID da organização: " org_id

# Verifica se o ID da organização foi fornecido
if [ -z "$org_id" ]; then
  echo "ID da organização não fornecido. Saindo..."
  exit 1
fi

# Solicita o nome da instância que o usuário deseja buscar
read -p "Digite o nome da instância que deseja buscar: " instance_name

# Verifica se o nome da instância foi fornecido
if [ -z "$instance_name" ]; then
  echo "Nome da instância não fornecido. Saindo..."
  exit 1
fi

# Variável para armazenar os projetos encontrados com a instância
projects_with_instance=""

echo "Buscando instâncias no projeto..."

# Listar projetos da organização e procurar pela instância
for project in $(gcloud projects list --filter="parent.type=organization AND parent.id=$org_id" --format="value(projectId)"); do 
  echo "Verificando a API do Compute Engine no projeto: $project"

  # Verificar se a API Compute Engine está habilitada
  api_check=$(gcloud services list --enabled --project="$project" --filter="compute.googleapis.com")

  if [ -z "$api_check" ]; then
    echo "API do Compute Engine não está habilitada no projeto $project. Pulando este projeto."
    continue  # Pula para o próximo projeto
  fi

  # Se a API estiver habilitada, buscar as instâncias
  echo "API do Compute Engine habilitada. Buscando instâncias..."

  # Ajustando o comando de busca para ser mais flexível
  instance_check=$(gcloud compute instances list --project="$project" --filter="name~'$instance_name'" --format="value(name)")

  if [ ! -z "$instance_check" ]; then
    echo "Instância '$instance_name' encontrada no projeto: $project"
    projects_with_instance="$projects_with_instance\n$project"
  else
    echo "Instância '$instance_name' não encontrada no projeto: $project"
  fi
done

# Exibe a lista de projetos encontrados
if [ ! -z "$projects_with_instance" ]; then
  echo -e "${GREEN}\nInstância '$instance_name' foi encontrada nos seguintes projetos:$NC"
  echo -e "$projects_with_instance"
else
  echo -e "${RED}\nInstância '$instance_name' não encontrada em nenhum projeto.${NC}"
fi