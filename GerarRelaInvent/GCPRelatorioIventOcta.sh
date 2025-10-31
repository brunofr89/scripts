#!/bin/bash

# Lista dos projetos
PROJECTS=(
  octa-infrastructure
  octa-dev-us-east5-001
  octa-qa-us-east1-001
  octa-prod-us-east1-001
  octa-prod-southameri-east1-001
  octa-prod-sa-east1-003
  octa-prod-sa-east1-004
  octa-prod-us-east1-beta
  production-204419
  octa-monitoring
  octa-pantheon-sa-east1-001
  cross-tenant
)

# Formato do CSV
CSV_FORMAT='csv(
      name:label=Instance_Name,
      id:label=Instance_ID,
      name:label=Name,
      zone.basename():label=Zone,
      machineType.basename():label=Machine_Type,
      cpuPlatform:label=CPU_Platform,
      networkInterfaces[0].networkIP:label=Internal_IP,
      networkInterfaces[0].accessConfigs[0].natIP:label=External_IP,
      status:label=Status,
      creationTimestamp:label=Creation_Time,
      deletionProtection:label=Deletion_Protection,
      scheduling.automaticRestart:label=Automatic_Restart,
      scheduling.onHostMaintenance:label=On_Host_Maintenance,
      scheduling.preemptible:label=Preemptibility,
      scheduling.nodeAffinities:label=Start_Restricted,
      networkInterfaces[0].forwardedIps:label=IP_Forwarding,
      disks[0].deviceName:label=Boot_Disk_Name,
      disks[0].diskId:label=Disk_ID,
      disks[0].deviceName:label=Disk_Name,
      disks[0].zone.basename():label=Disk_Zone,
      disks[0].type.basename():label=Disk_Type,
      disks[0].diskSizeGb:label=Disk_Size,
      disks[0].guestOsFeatures[0].type:label=Encryption,
      disks[0].sourceImage:label=Disk_Source_Image,
      disks[0].sourceSnapshot:label=Disk_Source_Snapshot,
      disks[0].creationTimestamp:label=Disk_Creation_Time,
      disks[0].lastAttachTimestamp:label=Disk_Last_Attach_Time,
      disks[0].lastDetachTimestamp:label=Disk_Last_Detach_Time,
      disks[0].users[0]:label=Disk_in_use_by,
      networkInterfaces[0].name:label=Network_Interfaces,
      labels.machine-name:label=Tag_machine-name,
      labels.mongodb-replicaset:label=Tag_mongodb-replicaset,
      labels.machine-context:label=Tag_machine-context,
      labels.mongodb-context:label=Tag_mongodb-context,
      labels.serial-port-enable:label=Tag_serial-port-enable,
      labels.goog-ops-agent-policy:label=Tag_goog-ops-agent-policy,
      labels.enable-osconfig:label=Tag_enable-osconfig,
      labels.mongodb-domain:label=Tag_mongodb-domain,
      labels.goog-gke-cluster-id-base32:label=Tag_goog-gke-cluster-id-base32,
      labels.goog-gke-cost-management:label=Tag_goog-gke-cost-management,
      labels.goog-gke-node:label=Tag_goog-gke-node,
      labels.goog-k8s-cluster-location:label=Tag_goog-k8s-cluster-location,
      labels.goog-k8s-cluster-name:label=Tag_goog-k8s-cluster-name,
      labels.goog-k8s-node-pool-name:label=Tag_goog-k8s-node-pool-name,
      labels.serial-port-logging-enable:label=Tag_serial-port-logging-enable,
      labels.google-compute-enable-pcid:label=Tag_google-compute-enable-pcid,
      labels.enable-oslogin:label=Tag_enable-oslogin,
      labels.cluster-name:label=Tag_cluster-name,
      labels.gci-update-strategy:label=Tag_gci-update-strategy,
      labels.gci-metrics-enabled:label=Tag_gci-metrics-enabled,
      labels.disable-legacy-endpoints:label=Tag_disable-legacy-endpoints,
      labels.cluster-uid:label=Tag_cluster-uid,
      labels.cluster-location:label=Tag_cluster-location,
      labels.cluster_name:label=Tag_cluster_name,
      labels.node_pool:label=Tag_node_pool,
      labels.goog-dm:label=Tag_goog-dm,
      labels.PROVISIONER_DATA_DISK:label=Tag_PROVISIONER_DATA_DISK,
      labels.PROVISIONER_TIER:label=Tag_PROVISIONER_TIER,
      labels.PROVISIONER_PEER_ADDRESS:label=Tag_PROVISIONER_PEER_ADDRESS,
      labels.PROVISIONER_PEER_PASSWORD:label=Tag_PROVISIONER_PEER_PASSWORD,
      labels.PROVISIONER_PEER_NODES_PREFIX:label=Tag_PROVISIONER_PEER_NODES_PREFIX,
      labels.PROVISIONER_PEER_NODES_INDEX:label=Tag_PROVISIONER_PEER_NODES_INDEX,
      labels.PROVISIONER_PEER_NODES_FROM:label=Tag_PROVISIONER_PEER_NODES_FROM,
      labels.PROVISIONER_PEER_NODES_COUNT:label=Tag_PROVISIONER_PEER_NODES_COUNT,
      labels.PROVISIONER_SHARED_UNIQUE_ID_INPUT:label=Tag_PROVISIONER_SHARED_UNIQUE_ID_INPUT,
      labels.PROVISIONER_APP_PASSWORD:label=Tag_PROVISIONER_APP_PASSWORD,
      labels.PROVISIONER_CLUSTER_NAME:label=Tag_PROVISIONER_CLUSTER_NAME,
      labels.PROVISIONER_CLUSTER_QUORUM:label=Tag_PROVISIONER_CLUSTER_QUORUM,
      labels.PROVISIONER_PERSISTENT_NODE:label=Tag_PROVISIONER_PERSISTENT_NODE,
      labels.status-variable-path:label=Tag_status-variable-path,
      labels.status-uptime-deadline:label=Tag_status-uptime-deadline
)'

# Loop por projeto
for PROJECT in "${PROJECTS[@]}"; do
  echo "📦 Gerando inventário do projeto: $PROJECT"
  OUTPUT_FILE="${PROJECT}.csv"

  gcloud compute instances list \
    --project="$PROJECT" \
    --format="$CSV_FORMAT" \
    > "$OUTPUT_FILE"

  if [[ $? -eq 0 ]]; then
    echo "✅ Arquivo salvo: $OUTPUT_FILE"
  else
    echo "⚠️  Erro ao acessar projeto: $PROJECT"
  fi
done
