#!/bin/bash
source config.sh
source core.sh

NETWORK_NAME="traefik-public"
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

echo "Copie des fichiers de stack sur le nœud maître..."
rsync_files $MASTER_IP "./stacks/" "~/stacks/"


echo "Déploiement des stacks sur le nœud maître..."
ssh_exec $MASTER_IP "docker stack deploy -c ~/stacks/traefik-stack.yml traefik"

echo "Stacks déployées:"
ssh_exec $MASTER_IP "docker stack ls"

echo "Services Traefik:"
ssh_exec $MASTER_IP "docker stack services traefik"

get_service_logs "traefik_traefik"
