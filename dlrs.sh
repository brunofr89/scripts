#!/usr/bin/zsh
#Owner:José Jefferson Nascimento do Vale

output=$(kubectl --kubeconfig /home/bruno.r/.kube/kube_config/aws/config-tms-dev get ns)

# Transforma a saída em uma lista
lista=()
while IFS= read -r line; do
    lista+=("$line")
done <<< "$output"

for item in "${lista[@]}"; do
  name=$(echo "$item" | awk '{print $1}')
  kubectl --kubeconfig /home/bruno.r/.kube/kube_config/aws/config-tms-dev get replicasets -n $name --sort-by=.metadata.creationTimestamp | tail -n +3 | xargs --no-run-if-empty -n 1 kubectl --kubeconfig /home/bruno.r/.kube/kube_config/aws/config-tms-dev delete replicaset --cascade=orphan --wait=false --ignore-not-found=true -n $name
done