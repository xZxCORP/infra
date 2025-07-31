#!/bin/bash
set -e

docker-entrypoint.sh postgres &
POSTGRES_PID=$!

until pg_isready -U "$POSTGRES_USER"; do
    sleep 1
done

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw docmost; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE docmost;"
fi

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw outline; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE outline;"
fi

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw chain_state_service_db; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE chain_state_service_db;"
fi

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw user_service_db; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE user_service_db;"
fi

if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw auth_service_db; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE auth_service_db;"
fi
wait $POSTGRES_PID