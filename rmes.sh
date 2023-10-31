#!/bin/bash

# Obtém todos os ReplicaSets no cluster
replicasets=$(kubectl get replicasets -o jsonpath='{.items[*].metadata.name}')

# Loop através de cada ReplicaSet
for rs in $replicasets; do
    # Obtém o status "ready" do ReplicaSet
    ready=$(kubectl get rs "$rs" -o jsonpath='{.status.readyReplicas}')
    
    # Verifica se o status "ready" é igual a 0
    if [ "$ready" -eq 0 ]; then
        echo "Deleting ReplicaSet: $rs"
        # Apaga o ReplicaSet
        kubectl delete rs "$rs"
    fi
done
