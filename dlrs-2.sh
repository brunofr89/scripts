#!/bin/bash

#Mantenedor: Bruno Rodrigues | Max Peixoto
 
<<Description
    Para executar este script, salve este arquivo no diretório "/usr/local/bin/" 
    e aplique permissão de execução "chmod +x envaws" (recomendado) após este utilize o comando: 'envaws'
    Este script irá se autenticar no ambiente da aws de acordo com o perfil selecionado.
Description
 
<<variables
autentica_aws -> função que será executada
AWS_REGION -> variável com valor padrão independente do ambiente selecionado

variables
 
autentica_aws(){
 
#AWS_REGION=us-east-1 default
export AWS_REGION=us-east-1

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
echo -e "${RED}======================================================================="
echo -e "${RED}|""${YELLOW}  ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES E MAX PEIXOTO""${RED}  |"
echo -e "${RED}======================================================================="
echo
echo 'Por favor, digite o número do ambiente desejado:'
echo -e "${GREEN}|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
echo -e "${GREEN}||""${YELLOW} (1)""${GREEN}  architecturerd_prod     ||""${YELLOW} (17)""${GREEN} microservicesrd_qa           ||"
echo -e "${GREEN}||""${YELLOW} (2)""${GREEN}  commercialagrmts_dev    ||""${YELLOW} (18)""${GREEN} microservicesrd_stg          ||"
echo -e "${GREEN}||""${YELLOW} (3)""${GREEN}  commercialagrmts_prod   ||""${YELLOW} (19)""${GREEN} opf_dev                      ||"
echo -e "${GREEN}||""${YELLOW} (4)""${GREEN}  commercialagrmts_qa     ||""${YELLOW} (20)""${GREEN} opf_prod                     ||"
echo -e "${GREEN}||""${YELLOW} (5)""${GREEN}  commercialagrmts_stg    ||""${YELLOW} (21)""${GREEN} opf_qa                       ||"
echo -e "${GREEN}||""${YELLOW} (6)""${GREEN}  devops_prod             ||""${YELLOW} (22)""${GREEN} opf_stg                      ||"
echo -e "${GREEN}||""${YELLOW} (7)""${GREEN}  ecommerce_dev           ||""${YELLOW} (23)""${GREEN} pcproduto_dev                ||"
echo -e "${GREEN}||""${YELLOW} (8)""${GREEN}  ecommerce_prod          ||""${YELLOW} (24)""${GREEN} pcproduto_prod               ||"
echo -e "${GREEN}||""${YELLOW} (9)""${GREEN}  ecommerce_qa            ||""${YELLOW} (25)""${GREEN} pcproduto_qa                 ||"
echo -e "${GREEN}||""${YELLOW} (10)""${GREEN} ecommerce_stg           ||""${YELLOW} (26)""${GREEN} univers_dev                  ||"
echo -e "${GREEN}||""${YELLOW} (11)""${GREEN} logistica_dev           ||""${YELLOW} (27)""${GREEN} univers_prod                 ||"
echo -e "${GREEN}||""${YELLOW} (12)""${GREEN} logistica_prod          ||""${YELLOW} (28)""${GREEN} univers_qa                   ||"
echo -e "${GREEN}||""${YELLOW} (13)""${GREEN} logistica_qa            ||""${YELLOW} (29)""${GREEN} vulnerability_prevention_dev ||"                                        
echo -e "${GREEN}||""${YELLOW} (14)""${GREEN} logistica_stg           ||""${YELLOW} (30)""${GREEN} vulnerability_prevention_prod||"
echo -e "${GREEN}||""${YELLOW} (15)""${GREEN} microservicesrd_dev     ||""${YELLOW} (31)""${GREEN} vulnerability_prevention_qa  ||"
echo -e "${GREEN}||""${YELLOW} (16)""${GREEN} microservicesrd_prod    ||""${YELLOW} (32)""${GREEN} vulnerability_prevention_stg ||"
echo -e "${GREEN}||""${YELLOW} (33)""${GREEN} Financeiro_dev          ||""${YELLOW} (35)""${GREEN} Financeiro_stg               ||"
echo -e "${GREEN}||""${YELLOW} (34)""${GREEN} Financeiro_qa           ||""${YELLOW} (36)""${GREEN} Financeiro_prod              ||"

echo -e "${GREEN}|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||" 
echo
echo  'Selecionar: '
read env
echo
if [ $env -eq 1 ]
then
    export AWS_PROFILE=architecturerd_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo 
    aws sso login

elif [ $env -eq 2 ]
then
    export AWS_PROFILE=commercialagrmts_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login
 

elif [ $env -eq 3 ]
then
    export AWS_PROFILE=commercialagrmts_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login
 
elif [ $env -eq 4 ]
then
    export AWS_PROFILE=commercialagrmts_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 5 ]
then
    export AWS_PROFILE=commercialagrmts_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login  

elif [ $env -eq 6 ]
then
    export AWS_PROFILE=devops_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login 

elif [ $env -eq 7 ]
then
    export AWS_PROFILE=ecommerce_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login         

elif [ $env -eq 8 ]
then
    export AWS_PROFILE=ecommerce_prod
    echo $AWS_PROFILE 
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 9 ]
then
    export AWS_PROFILE=ecommerce_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login    

elif [ $env -eq 10 ]
then
    export AWS_PROFILE=ecommerce_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login  

elif [ $env -eq 11 ]
then
    export AWS_PROFILE=logistica_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login 

elif [ $env -eq 12 ]
then
    export AWS_PROFILE=logistica_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 13 ]
then
    export AWS_PROFILE=logistica_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login 

elif [ $env -eq 14 ]
then
    export AWS_PROFILE=logistica_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 15 ]
then
    export AWS_PROFILE=microservicesrd_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 16 ]
then
    export AWS_PROFILE=microservicesrd_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 17 ]
then
    export AWS_PROFILE=microservicesrd_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 18 ]
then
    export AWS_PROFILE=microservicesrd_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 19 ]
then
    export AWS_PROFILE=opf_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 20 ]
then
    export AWS_PROFILE=opf_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 21 ]
then
    export AWS_PROFILE=opf_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 22 ]
then
    export AWS_PROFILE=opf_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 23 ]
then
    export AWS_PROFILE=pcproduto_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 24 ]
then
    export AWS_PROFILE=pcproduto_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 25 ]
then
    export AWS_PROFILE=pcproduto_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 26 ]
then
    export AWS_PROFILE=univers_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 27 ]
then
    export AWS_PROFILE=univers_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 28 ]
then
    export AWS_PROFILE=univers_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 29 ]
then
    export AWS_PROFILE=vulnerability_prevention_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 30 ]
then
    export AWS_PROFILE=vulnerability_prevention_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 31 ]
then
    export AWS_PROFILE=vulnerability_prevention_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 32 ]
then
    export AWS_PROFILE=vulnerability_prevention_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 33 ]
then
    export AWS_PROFILE=Financeiro_dev
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 34 ]
then
    export AWS_PROFILE=Financeiro_qa
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

 elif [ $env -eq 35 ]
then
    export AWS_PROFILE=Financeiro_stg
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login

elif [ $env -eq 36 ]
then
    export AWS_PROFILE=Financeiro_prod
    echo $AWS_PROFILE
    echo $AWS_REGION
    echo
    aws sso login           
 
else 

    echo 'Error, por favor digite um número válido.'
fi

export AWS_PROFILE=$AWS_PROFILE
}
 

autentica_aws
echo
echo
echo 'exporte a variável do profile AWS -->>>  export AWS_PROFILE='$AWS_PROFILE
echo


