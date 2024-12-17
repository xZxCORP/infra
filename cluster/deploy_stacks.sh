#!/bin/bash
source deploy_base.sh
echo "Déploiement des stacks sur le nœud maître..."
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/traefik/traefik-stack.yml traefik'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/mysql/mysql-stack.yml mysql'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/mongodb/mongodb-stack.yml mongodb'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/rabbitmq/rabbitmq-stack.yml rabbitmq'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/minio/minio-stack.yml minio'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/wheelz/wheelz-stack.yml wheelz'
ssh_exec $MASTER_IP 'set -a; . ~/.env; set +a; docker stack deploy -c ~/stacks/webhook/webhook-stack.yml webhook'
ssh_exec $MASTER_IP 'docker stack deploy -c ~/stacks/gatus/gatus-stack.yml gatus'

echo "Stacks déployées:"
ssh_exec $MASTER_IP "docker stack ls"
