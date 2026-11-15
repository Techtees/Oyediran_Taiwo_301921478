#!/usr/bin/env bash
# CareBridge Portfolio 3: 10 concurrent pharmacists each dispense 1 pack 200 times (2,000 packs)
# Run 00_setup_demo_data.sql first, then: ./06_stress_test.sh [database]
set -euo pipefail
DB=${1:-carebridge}
CLIENTS=10
PER_CLIENT=200
START=100000
cd "$(dirname "$0")"

printf '%-26s %10s %10s %12s %8s\n' method expected actual lost_updates tps
for method in read_then_write for_update atomic; do
  psql -qX -d "$DB" -c "UPDATE carebridge.pharmacy_stock SET quantity = $START WHERE branch_id = 2 AND medication_id = 900001"
  tps=$(pgbench -n -c $CLIENTS -j $CLIENTS -t $PER_CLIENT -f pgbench/dispense_$method.sql "$DB" 2>/dev/null \
        | awk '/^tps/ {printf "%.0f", $3}')
  actual=$(psql -qXAt -d "$DB" -c "SELECT quantity FROM carebridge.pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001")
  expected=$((START - CLIENTS * PER_CLIENT))
  printf '%-26s %10d %10d %12d %8s\n' "$method" "$expected" "$actual" $((actual - expected)) "$tps"
done
psql -qX -d "$DB" -c "UPDATE carebridge.pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id = 900001"
