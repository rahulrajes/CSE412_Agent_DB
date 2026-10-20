#!/usr/bin/env bash
#
# Rebuild the whole database from scratch inside the Docker container:
#   01 physical schema -> 02 semantic schema -> 03 load Olist CSVs -> 04 semantic seed
#
# Usage (from the repo root):  scripts/setup_db.sh

set -euo pipefail

cd "$(dirname "$0")/.."

DB_USER="rahul_rajesh"
DB_NAME="semanticdb"

echo "Starting Postgres..."
docker compose up -d --wait postgres

run_sql() {
  echo
  echo "==> $1"
  docker compose exec -T postgres \
    psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -v datadir=/data -f "/sql/$1"
}

run_sql 01_olist_schema.sql
run_sql 02_semantic_schema.sql
run_sql 03_load_olist.sql
run_sql 04_semantic_seed.sql

echo
echo "Database ready. Open a console with:"
echo "  docker compose exec postgres psql -U $DB_USER -d $DB_NAME"
