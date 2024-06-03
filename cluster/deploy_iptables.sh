#!/bin/bash

source config.sh

for NODE in "${NODES_AND_RUNNER[@]}"; do
    echo "Configuration des règles iptables sur $NODE"
    scp -i $SSH_KEY_PATH ./deployers/configure_iptables.sh $USER@$NODE:$SCRIPT_PATH
    ssh -i $SSH_KEY_PATH $USER@$NODE "sudo bash $SCRIPT_PATH/configure_iptables.sh"
done
