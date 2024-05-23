#!/bin/bash

source config.sh

# Install k3s master node
k3sup install --ip $MASTER_IP --user $USER --ssh-key $SSH_KEY_PATH

# Join worker nodes to the cluster
for WORKER_IP in "${WORKER_IPS[@]}"; do
    k3sup join --ip $WORKER_IP --user $USER --server-ip $MASTER_IP --ssh-key $SSH_KEY_PATH
done

mkdir -p ~/.kube
k3sup install --ip $MASTER_IP --user $USER --merge --local-path ~/.kube/config --ssh-key $SSH_KEY_PATH

kubectl get nodes -o wide