#!/usr/bin/env bash
# CareBridge Portfolio 5: writes go to the primary and appear on the replica; the replica refuses writes
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh

step "1. Reception at Lekki registers a new patient on the primary"
p "INSERT INTO carebridge.patients (mrn, first_name, last_name, dob, gender, home_branch_id)
   VALUES ('CB-900001', 'Ifeoma', 'Replica', '1991-04-12', 'female', 2) RETURNING patient_id, mrn, created_at;"
sleep 0.5

step "2. A doctor's screen reads from the replica"
r "SELECT patient_id, mrn, first_name, last_name FROM carebridge.patients WHERE mrn = 'CB-900001';"

step "3. Replication lag seen from the primary"
p "SELECT application_name, state, replay_lag, pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_behind
   FROM pg_stat_replication;"

step "4. Trying to write on the replica"
r "INSERT INTO carebridge.patients (mrn, first_name, last_name, dob, home_branch_id)
   VALUES ('CB-900002', 'Should', 'Fail', '1990-01-01', 2);"
r "UPDATE carebridge.patients SET phone = '0800000000' WHERE mrn = 'CB-900001';"

step "5. Clean up on the primary"
p "DELETE FROM carebridge.patients WHERE mrn = 'CB-900001';"
