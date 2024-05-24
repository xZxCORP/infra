#!/bin/bash

set -o allexport
source .env
set +o allexport

kubectl create secret generic mysql-secret \
  --from-literal=mysql-root-password=$MYSQL_ROOT_PASSWORD \
  --from-literal=mysql-user=$MYSQL_USER \
  --from-literal=mysql-password=$MYSQL_PASSWORD \
  --from-literal=mysql-database=$MYSQL_DATABASE

echo "Secrets créés avec succès."