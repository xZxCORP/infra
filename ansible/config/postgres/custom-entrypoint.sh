#!/bin/bash
set -e

docker-entrypoint.sh postgres &
POSTGRES_PID=$!

until pg_isready -U "$POSTGRES_USER"; do
    sleep 1
done

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw sonarqube; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE sonarqube;"
fi

wait $POSTGRES_PID