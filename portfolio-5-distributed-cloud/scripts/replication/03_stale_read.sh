#!/usr/bin/env bash
# CareBridge Portfolio 5: asynchronous replication means a replica can be behind (stale read)
cd "$(dirname "$0")" && source env.sh

step "1. Simulate a slow replica by pausing WAL replay"
r "SELECT pg_wal_replay_pause();"
sleep 1

step "2. Reception registers a patient on the primary, and the commit returns immediately"
p "INSERT INTO carebridge.patients (mrn, first_name, last_name, dob, gender, home_branch_id)
   VALUES ('CB-900003', 'Tunde', 'Stale', '1985-09-30', 'male', 2) RETURNING mrn;"

step "3. The doctor searches for the new patient"
p "SELECT count(*) AS found_on_primary FROM carebridge.patients WHERE mrn = 'CB-900003';"
r "SELECT count(*) AS found_on_replica FROM carebridge.patients WHERE mrn = 'CB-900003';"
p "SELECT application_name, pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_behind FROM pg_stat_replication;"

step "4. The replica catches up"
r "SELECT pg_wal_replay_resume();"
sleep 1
r "SELECT count(*) AS found_on_replica FROM carebridge.patients WHERE mrn = 'CB-900003';"
p "SELECT application_name, pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_behind FROM pg_stat_replication;"

p "DELETE FROM carebridge.patients WHERE mrn = 'CB-900003';"
