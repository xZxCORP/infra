#!/bin/bash
source deploy_base.sh

echo "Déploiement des stacks sur le nœud maître..."
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/wheelz/wheelz-stack.yml wheelz'
ssh_exec $MASTER_IP 'docker stack deploy -c ~/stacks/gatus/gatus-stack.yml gatus'

echo "Stacks déployées:"
ssh_exec $MASTER_IP "docker stack ls"
