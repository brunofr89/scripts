#!/bin/bash

#Mantenedor: Bruno Rodrigues | Max Peixoto
 
<<Description
    O objetivo do script e realizar a migracao de bancos de dados, informando os dados de conexao/databases de origem e destino
Description
 
migration-db(){


#Preto      \033[0;30m
#Vermelho   \033[0;31m
#Verde      \033[0;32m
#Amarelo    \033[0;33m
#Azul       \033[0;34m
#Magenta    \033[0;35m
#Ciano      \033[0;36m
#Branco     \033[0;37m

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
echo -e "${RED}=================================================================="
echo -e "${RED}|""${YELLOW} Vc Viu??? que top esse script? E FOI CRIADO POR BRUNO RODRIGUES""${RED}|"
echo -e "${RED}=================================================================="
echo
echo 'Por favor, digite o número do ambiente desejado:'
echo -e "${GREEN}||||||||||||||||||||"
echo -e "${GREEN}||""${YELLOW} (1)""${GREEN}  Backup  ||""${YELLOW}||"
echo -e "${GREEN}||""${YELLOW} (2)""${GREEN}  Restore ||""${YELLOW}||"
echo -e "${GREEN}||||||||||||||||||||" 
echo
echo  'Selecionar: '
read env
echo

list_databases() {
    read -p "Informe o host do banco de dados: " DB_HOST
    read -p "Informe o nome de usuário do banco de dados: " DB_USER
    read -s -p "Informe a senha do banco de dados: " DB_PASSWORD
    echo  # Pule uma linha para não exibir a senha na tela
    # Exporte as variáveis para que elas possam ser usadas em outros scripts
    export DB_HOST
    export DB_USER
    export DB_PASSWORD
    # Use o comando 'mysql' para listar as bases de dados
    echo "Bases de dados disponíveis:"
    echo "Copie as bases que deseja ter o backup, cole uma ao lado da outra separando por vigula"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;"
    read -p "Informe a base de dados para restore(as bases devem ser ionformadas da seguinte forma base1,base2,...): " DATABASES
    # Exporte a variável DATABASES para que ela possa ser usada no próximo script
    export DATABASES        
}
if [ $env -eq 1 ]
then
    # Opção de backup
    list_databases
    # Converter a lista de bases de dados em um array
    IFS=',' read -ra DB_ARRAY <<< "$DATABASES"    
for DB in "${DB_ARRAY[@]}"
do
  mysqldump -h "$DB_HOST" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    --port=3306 \
    --single-transaction \
    --routines \
    --triggers \
    --databases "$DB" > "$DB.sql"
done

elif [ $env -eq 2 ]
then
    # Opção de backup
    list_databases
    # Converter a lista de bases de dados em um array
    IFS=',' read -ra DB_ARRAY <<< "$DATABASES"    
for DB in "${DB_ARRAY[@]}"
do
        # Verificar se a base de dados já existe na nova base
        if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB;" &> /dev/null; then
            echo "Restaurando $DB..."
            mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB" < "$DB.sql"
        else
            echo "Criando a base de dados $DB..."
            mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE $DB;"
            echo "Restaurando $DB..."
            mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB" < "$DB.sql"
        fi
    done    
else 

    echo 'Error, por favor digite um número válido.'
fi    
}
migration-db