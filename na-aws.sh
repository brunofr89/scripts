#!/bin/bash

# Obtém o ID da conta da AWS
account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Obtém o nome da conta da AWS a partir do ID (isso é apenas uma abordagem de exemplo, você pode mapear IDs para nomes como preferir)
case $account_id in
    "396248687190") # Substitua pelo seu ID da conta
        account_name="MinhaContaAWS"
        ;;
    # Adicione mais casos para mapear IDs para nomes de conta
    *)
        account_name="NomeDesconhecido"
        ;;
esac

echo "Conta AWS: $account_name"