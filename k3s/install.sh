#!/bin/bash

source common.sh

if ! command -v k3sup &> /dev/null; then
    echo "k3sup could not be found, installing..."
    curl -sLS https://get.k3sup.dev | sh
    sudo install k3sup /usr/local/bin/
fi
open_ports() {
    ssh -i $SSH_KEY $USER@$1 "sudo iptables -I INPUT -p tcp --dport 6443 -j ACCEPT"
    ssh -i $SSH_KEY $USER@$1 "sudo iptables -I INPUT -p tcp --dport 10250 -j ACCEPT"
    ssh -i $SSH_KEY $USER@$1 "sudo iptables -I INPUT -p tcp --dport 8472 -j ACCEPT"
    ssh -i $SSH_KEY $USER@$1 "sudo iptables-save | sudo tee /etc/iptables/rules.v4"
}
echo "Opening necessary ports on master $MASTER_IP"
open_ports $MASTER_IP

echo "Installing K3s master on $MASTER_IP"
k3sup install \
    --ip $MASTER_IP \
    --user $USER \
    --ssh-key $SSH_KEY \
    --k3s-version $K3S_VERSION

export KUBECONFIG=$(pwd)/kubeconfig
kubectl config use-context default

for WORKER_IP in "${WORKER_IPS[@]}"; do
    echo "Joining worker $WORKER_IP to the cluster"
    k3sup join \
        --ip $WORKER_IP \
        --user $USER \
        --server-ip $MASTER_IP \
        --ssh-key $SSH_KEY \
        --k3s-version $K3S_VERSION
done