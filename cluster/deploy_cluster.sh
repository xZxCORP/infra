#!/bin/bash

source config.sh

# Fonction pour exécuter une commande sur un nœud distant via SSH
function ssh_exec {
    local IP=$1
    shift
    ssh -i $SSH_KEY_PATH $USER@$IP "$@"
}

# Fonction pour installer Docker
function install_docker {
    local IP=$1
    echo "Checking if Docker is installed on $IP..."
    if ssh_exec $IP "docker --version" &>/dev/null; then
        echo "Docker is already installed on $IP."
    else
        echo "Installing Docker on $IP..."
        ssh_exec $IP "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && sudo usermod -aG docker $USER"
    fi
}

# Installer Docker sur le nœud maître
install_docker $MASTER_IP

# Installer Docker sur les nœuds travailleurs
for WORKER_IP in "${WORKER_IPS[@]}"; do
    install_docker $WORKER_IP
done

# Initialiser le nœud maître
echo "Checking if the master node is initialized..."
if ssh_exec $MASTER_IP "docker info | grep 'Swarm: active'" &>/dev/null; then
    echo "Master node is already initialized."
else
    echo "Initializing the master node..."
    ssh_exec $MASTER_IP "docker swarm init --advertise-addr $MASTER_IP"
fi

# Récupérer le token d'inscription pour les nœuds travailleurs
WORKER_JOIN_TOKEN=$(ssh_exec $MASTER_IP "docker swarm join-token -q worker")

# Ajouter les nœuds travailleurs au cluster
for WORKER_IP in "${WORKER_IPS[@]}"; do
    echo "Checking if worker node $WORKER_IP is part of the swarm..."
    if ssh_exec $WORKER_IP "docker info | grep 'Swarm: active'" &>/dev/null; then
        echo "Worker node $WORKER_IP is already part of the swarm."
    else
        echo "Adding worker node $WORKER_IP to the swarm..."
        ssh_exec $WORKER_IP "docker swarm join --token $WORKER_JOIN_TOKEN $MASTER_IP:2377"
    fi
done

# Afficher l'état du cluster
echo "Cluster nodes status:"
ssh_exec $MASTER_IP "docker node ls"