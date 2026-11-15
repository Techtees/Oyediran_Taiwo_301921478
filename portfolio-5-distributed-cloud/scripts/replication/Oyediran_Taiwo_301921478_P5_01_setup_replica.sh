#!/usr/bin/env bash
# CareBridge Portfolio 5: create a streaming replica of the carebridge server on port 5433
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh
if [ -d "$REPLICA_DIR" ]; then echo "A replica already exists in $REPLICA_DIR. Run Oyediran_Taiwo_301921478_P5_99_teardown_replica.sh first."; exit 1; fi
mkdir -p "$P5_DIR"

step "1. Copy the primary with pg_basebackup (also creates replication slot $SLOT)"
"$PGBIN/pg_basebackup" -h localhost -p 5432 -D "$REPLICA_DIR" -R -X stream -c fast -C -S "$SLOT" -P
cat >> "$REPLICA_DIR/postgresql.auto.conf" <<CONF
port = 5433
cluster_name = 'carebridge_replica'
CONF
grep -oE "host=[^ ]+ port=[0-9]+" "$REPLICA_DIR/postgresql.auto.conf" | sed 's/^/primary_conninfo: /'
grep -E "^(primary_slot_name|port|cluster_name)" "$REPLICA_DIR/postgresql.auto.conf"
ls "$REPLICA_DIR/standby.signal"

step "2. Start the replica"
"$PGBIN/pg_ctl" -D "$REPLICA_DIR" -l "$P5_DIR/pg_replica.log" -w start
sleep 2

step "3. Check both sides"
p "SELECT application_name, state, sync_state, sent_lsn, replay_lsn FROM pg_stat_replication;"
r "SELECT pg_is_in_recovery() AS is_replica, current_setting('port') AS port, (SELECT count(*) FROM carebridge.patients) AS patients;"
