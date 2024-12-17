#!/bin/bash
source config.sh
source core.sh

NETWORK_NAME="proxy"
function get_service_logs {
    local SERVICE_NAME=$1
    echo "Récupération des logs pour le service $SERVICE_NAME:"
    ssh_exec $MASTER_IP "docker service logs $SERVICE_NAME --no-task-ids --raw --details"
}
function create_network() {
    if ssh_exec $MASTER_IP "docker network ls | grep -q $NETWORK_NAME"; then
        echo "Le réseau $NETWORK_NAME existe déjà."
    else
        echo "Le réseau $NETWORK_NAME n'existe pas. Création en cours..."
        ssh_exec $MASTER_IP "docker network create --driver=overlay --attachable $NETWORK_NAME"
        echo "Réseau $NETWORK_NAME créé avec succès."
    fi
}

create_network

ssh_exec $MASTER_IP "rm -rf ~/stacks"
ssh_exec $MASTER_IP "rm -rf ~/.env"
echo "Copie des fichiers de stack sur le nœud maître..."
rsync_files $MASTER_IP "./stacks/" "~/stacks/"
rsync_files $MASTER_IP ".env" "~/.env"

echo "Copie des fichiers de config"

rsync_files $MASTER_IP "./configs/" "~/configs/"
for WORKER_IP in "${WORKER_IPS[@]}"; do
    rsync_files $WORKER_IP "./configs/" "~/configs/"

done

