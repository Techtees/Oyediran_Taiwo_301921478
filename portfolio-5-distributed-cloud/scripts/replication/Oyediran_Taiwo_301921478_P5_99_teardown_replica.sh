#!/usr/bin/env bash
# CareBridge Portfolio 5: stop and remove the replica, drop the slot, restore primary settings
cd "$(dirname "$0")" && source env.sh
[ -d "$REPLICA_DIR" ] && "$PGBIN/pg_ctl" -D "$REPLICA_DIR" -m fast stop 2>/dev/null
rm -rf "$REPLICA_DIR" "$P5_DIR/pg_replica.log" "$P5_DIR/insert.sql" "$P5_DIR/waiting.out"
psql -X -q -p 5432 -d carebridge <<SQL
ALTER SYSTEM RESET synchronous_standby_names;
SELECT pg_reload_conf();
SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots WHERE slot_name = '$SLOT';
DROP TABLE IF EXISTS public.p5_commit_test;
DELETE FROM carebridge.patients WHERE mrn LIKE 'CB-9000%';
SQL
echo "Replica removed."
