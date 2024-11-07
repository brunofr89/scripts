#Mantenedor: Bruno Rodrigues

<<Description
    Salve o arquivo em /usr/local/bin/ e aplique permissão de execução com chmod +x
    Execute o script com o comando: create-cred-nginx.
    O script gerará uma credencial para acesso via Nginx, que deverá ser incluída na sua Secret.
Description


RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE='\033[0;34m'
NC='\033[0m'

echo "${RED}#######################################################################"
echo "${RED}#############################""${GREEN}.............""${RED}#############################"
echo "${RED}#########################""${GREEN}.....................""${RED}#########################"
echo "${RED}######################""${GREEN}...........................""${RED}######################"
echo "${RED}####################""${GREEN}...............................""${RED}####################"
echo "${RED}###################""${GREEN}.................................""${RED}###################"
echo "${RED}##################""${GREEN}...................................""${RED}##################"
echo "${RED}##################""${GREEN}.........H.................H.......""${RED}##################"
echo "${RED}##################""${GREEN}........HHH...............HHH......""${RED}##################"
echo "${RED}##################""${GREEN}.......HHHHH.............HHHHH.....""${RED}##################"
echo "${RED}##################""${GREEN}...................................""${RED}##################"
echo "${RED}##################""${GREEN}.................H.................""${RED}##################"
echo "${RED}########""${GREEN}......""${RED}####""${GREEN}................HHH................""${RED}###""${GREEN}......""${RED}#########"
echo "${RED}#######""${GREEN}.......""${RED}######""${GREEN}.............HHHHH.............""${RED}#####""${GREEN}.......""${RED}########"
echo "${RED}######""${GREEN}............""${RED}###""${GREEN}.............................""${RED}###""${GREEN}...........""${RED}#######"
echo "${RED}######""${GREEN}..........................................................""${RED}#######"
echo "${RED}#####""${GREEN}......""${RED}###""${GREEN}...........................................""${RED}###""${GREEN}.....""${RED}######"
echo "${RED}#####################""${GREEN}.....|HH|HH|HH|HH|HH|HH|.....""${RED}#####################"
echo "${RED}#####################""${GREEN}.....|--|--|--|--|--|--|.....""${RED}#####################"
echo "${RED}######""${GREEN}....""${RED}#########""${GREEN}.......|HH|HH|HH|HH|HH|HH|.......""${RED}#########""${GREEN}....""${RED}######"
echo "${RED}#####""${GREEN}......""${RED}#""${GREEN}...............................................""${RED}#""${GREEN}......""${RED}#####"
echo "${RED}######""${GREEN}...........................................................""${RED}######"
echo "${RED}#######""${GREEN}........""${RED}###########""${GREEN}...................""${RED}##########""${GREEN}.........""${RED}#######"
echo "${RED}########""${GREEN}......""${RED}###########################################""${GREEN}......""${RED}########"
echo "${RED}#########""${GREEN}....""${RED}#############################################""${GREEN}....""${RED}#########"
echo "${RED}======================================================================="
echo "${RED}|""${YELLOW}         ESTE FABULOSO SCRIPT FOI CRIADO POR BRUNO RODRIGUES""${RED}         |"
echo "${RED}|""${YELLOW}                  MAX PEIXOTO e CARLOS LOURENCO""${RED}                      |"
echo "${RED}======================================================================="
echo "${RED}======================================================================="
echo "${RED}|""${GREEN}  Criar credenciais de autenticação via nginx                   ""${RED}     |"
echo "${RED}|""${GREEN}  Obs: Necessario logar na conta AWS onde o cluster esta provisionado""${RED}|"
echo "${RED}======================================================================="

# Solicitar o nome do cluster ao usuário
echo "${BLUE}Por favor, insira o nome do cluster:${NC}"
read cluster_name

# Atualizar a configuração do kubectl com base no nome do cluster
aws eks --region us-east-1 update-kubeconfig --name "$cluster_name"

# Verifica se o cluster é válido antes de prosseguir
if [ $? -eq 0 ]; then
    # Obtém o nome do contexto atualmente logado no cluster
clusterlogin=$(kubectl config current-context)

    # Exibe o nome do cluster apenas se a configuração do kubectl for bem-sucedida
echo
echo "${BLUE}Logado no cluster ${NC}""${GREEN}$clusterlogin${NC}"
echo

# Solicitar dados do usuário
echo  "${BLUE}Nome do microserviço que vai realizar o envio da requisição:${NC}"
read -p "microserviço origem: " MS_ORIGEM

echo  "${BLUE}Nome do microserviço que vai receber a requisição:${NC}"
read -p "microserviço destino: " MS_DESTINO

echo  "${BLUE}Namespace do microserviço de destino :${NC}"
read -p "ns: " NAMESPACE

echo  "${BLUE}URL do microserviço (DOMINIO/PATH, exemplo: api-rd-internal-dev.raiadrogasil.io/v1/api/customers/):${NC}"
read -p "URL: " URL_PATH

# Extrair URL e PATH
URL=$(echo $URL_PATH | cut -d'/' -f1)
PATH_NGINX=$(echo $URL_PATH | sed 's/^[^/]*//')

# Verificar se existe uma Secret relacionada ao microserviço no cluster
SECRET_NAME=$(kubectl get ingress -n $NAMESPACE -o json | jq -r ".items[] | select(.spec.rules[].host == \"$URL\" and .spec.rules[].http.paths[]?.path == \"$PATH_NGINX\") | .metadata.annotations[\"nginx.ingress.kubernetes.io/auth-secret\"]")

if [ -z "$SECRET_NAME" ]; then
    echo "${RED}Nenhuma secret encontrada para o ingress com a URL/PATH fornecido.${NC}"
    exit 1
fi

echo "${BLUE}Secret encontrada:${NC} ${GREEN}$SECRET_NAME${NC}."

# Obter o valor base64 do campo `auth` da secret
AUTH_SECRET_BASE64=$(kubectl get secret $SECRET_NAME -n $NAMESPACE  -o json | jq -r '.data.auth')

if [ -z "$AUTH_SECRET_BASE64" ]; then
    echo "${RED}Nenhum valor encontrado no campo 'auth' da secret.${NC}"
    exit 1
fi

echo "${BLUE}Valor 'auth' encontrado:${NC}"
echo "${GREEN}$AUTH_SECRET_BASE64${NC}"
# Decodificar o valor base64 da secret
AUTH_SECRET_DECODED=$(echo $AUTH_SECRET_BASE64 | base64 --decode)

echo "${BLUE}Valor decodificado da secret 'auth':${NC}"

# Remover todas as quebras de linha e espaços extras
AUTH_SECRET_DECODED_CLEAN=$(echo "$AUTH_SECRET_DECODED" | tr -s ' ')

echo "${GREEN}$AUTH_SECRET_DECODED_CLEAN${NC}"

# Gerar a senha com o comando htpasswd
echo "${BLUE}Gerando credenciais com htpasswd...${NC}"
htpasswd -bc /tmp/$MS_ORIGEM $MS_ORIGEM $MS_DESTINO

# Pegar o valor gerado pelo htpasswd (hash da senha)
HTPASSWD_HASH=$(cat /tmp/$MS_ORIGEM)

# Excluir o arquivo temporário
rm /tmp/$MS_ORIGEM

echo "${BLUE}Credenciais geradas para o usuário${NC} ${GREEN}$MS_ORIGEM${NC} ${BLUE}com sucesso!${NC}"
echo "${GREEN}$HTPASSWD_HASH${NC}"

# Concatenar as variáveis com quebras de linha reais e gerar o novo valor base64
NEW_AUTH_SECRET=$(echo -n "$AUTH_SECRET_DECODED_CLEAN"'\n'"$HTPASSWD_HASH" | base64)


# Exibir o resultado em base64
NEW_AUTH_SECRET_CLEAN=$(echo "$NEW_AUTH_SECRET" | tr -d '\n' | tr -d ' ')
echo ${YELLOW}COPIAR O VALOR DE AUTH PARA INCLUIR NA SECRET${NC} 
echo "${GREEN}$NEW_AUTH_SECRET_CLEAN${NC}"
# Exibir o resultado decodificado

echo ${YELLOW}VALOR DE AUTH DECODIFICADO${NC} 
echo $NEW_AUTH_SECRET_CLEAN | base64 -d
echo 
echo "${BLUE}Credenciais de acesso são -> ${NC} ${YELLOW}USER:${NC} ${GREEN}$MS_ORIGEM${NC} ${YELLOW}PASS:${NC} ${GREEN}$MS_DESTINO${NC}"

AUTH_BASE64=$(echo -n "$MS_ORIGEM"':'"$MS_DESTINO" | base64)

echo ${BLUE}Valor da credencial em base64 | TOKEN${NC}
echo ${GREEN}$AUTH_BASE64${NC}

fi