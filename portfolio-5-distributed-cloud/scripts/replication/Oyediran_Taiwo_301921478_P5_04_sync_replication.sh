#!/usr/bin/env bash
# CareBridge Portfolio 5: synchronous vs asynchronous commit, and what happens when the replica is down
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh
trap 'psql -X -q -p 5432 -d carebridge -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()" >/dev/null' EXIT
p "CREATE TABLE IF NOT EXISTS public.p5_commit_test (id serial PRIMARY KEY, at timestamptz DEFAULT now());" >/dev/null
echo 'INSERT INTO public.p5_commit_test DEFAULT VALUES;' > "$P5_DIR/insert.sql"

latency() { pgbench -n -c 1 -T 5 -f "$P5_DIR/insert.sql" -p 5432 carebridge 2>/dev/null | grep -E '^(latency average|tps)'; }

step "1. Asynchronous (default): commit returns once the primary has saved the change"
p "SELECT application_name, sync_state FROM pg_stat_replication;"
latency

step "2. Switch to synchronous: commit waits until the replica has confirmed the change"
p "ALTER SYSTEM SET synchronous_standby_names = 'carebridge_replica';"
p "SELECT pg_reload_conf();" >/dev/null
sleep 1
p "SELECT application_name, sync_state FROM pg_stat_replication;"
latency

step "3. The replica goes down while synchronous replication is on"
"$PGBIN/pg_ctl" -D "$REPLICA_DIR" -m fast -w stop
p "SELECT count(*) AS replicas_connected FROM pg_stat_replication;"
printf '\n\033[1;34m[primary :5432]\033[0m %s\n' "INSERT INTO public.p5_commit_test DEFAULT VALUES RETURNING id;   (started in the background)"
psql -X -q -p 5432 -d carebridge -c "INSERT INTO public.p5_commit_test DEFAULT VALUES RETURNING id;" > "$P5_DIR/waiting.out" 2>&1 &
sleep 5
p "SELECT pid, wait_event, round(extract(epoch FROM now() - query_start)) AS waiting_seconds, left(query, 45) AS query
   FROM pg_stat_activity WHERE wait_event = 'SyncRep';"
p "SELECT pg_cancel_backend(pid) AS cancelled FROM pg_stat_activity WHERE wait_event = 'SyncRep';"
wait
echo "Output seen by the waiting session:"
cat "$P5_DIR/waiting.out"
p "SELECT max(id) AS last_id_on_primary FROM public.p5_commit_test;"

step "4. Back to asynchronous, restart the replica"
p "ALTER SYSTEM RESET synchronous_standby_names;"
p "SELECT pg_reload_conf();" >/dev/null
"$PGBIN/pg_ctl" -D "$REPLICA_DIR" -l "$P5_DIR/pg_replica.log" -w start
sleep 2
p "SELECT application_name, state, sync_state FROM pg_stat_replication;"
p "DROP TABLE public.p5_commit_test;"
