#!/usr/bin/env bash
# CareBridge Portfolio 4: export from PostgreSQL, import into MongoDB, compare row/element counts
# ./Oyediran_Taiwo_301921478_P4_02_import.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ../data

echo "== Exporting from PostgreSQL"
psql -X -q -d carebridge -f Oyediran_Taiwo_301921478_P4_01_export_from_postgres.sql
ls -lh ../data

echo "== Importing into MongoDB (database carebridge)"
mongoimport --quiet --db carebridge --collection patients    --drop --file ../data/patients.json
mongoimport --quiet --db carebridge --collection doctor_days --drop --file ../data/doctor_days.json

echo "== Counts: PostgreSQL rows vs MongoDB documents / embedded elements"
psql -X -q -d carebridge -f Oyediran_Taiwo_301921478_P4_03_count_postgres.sql
mongosh --quiet carebridge Oyediran_Taiwo_301921478_P4_03_count_mongodb.js
