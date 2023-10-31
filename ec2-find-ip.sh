#!/bin/bash

#Mantenedor: Bruno Rodrigues
 
<<Description
    Script criado para identgificar os ips de instancias ec2 das contas, na opcao profiles linha 9 estao configurados os profiles(AWS_PROFILE) para acesso as contas 
    AWS.
Description

output_file="ips_ec2.txt"

profiles=("Perfil1" "Perfil2" "Perfil3")

# Cria um arquivo vazio para começar
> "$output_file"

for profile in "${profiles[@]}"
do
  echo "Listing IPs for AWS profile: $profile" >> "$output_file"
  export AWS_PROFILE="$profile"
  aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,PrivateIpAddress]' --output table >> "$output_file"
  echo "============================================" >> "$output_file"
done
