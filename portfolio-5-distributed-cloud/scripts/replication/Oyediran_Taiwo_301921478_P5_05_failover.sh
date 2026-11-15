#!/usr/bin/env bash
# CareBridge Portfolio 5: promote the replica (failover) and see why the old primary must be fenced
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh

step "1. Before failover"
r "SELECT pg_is_in_recovery() AS is_replica, timeline_id FROM pg_control_checkpoint();"

step "2. The primary is assumed lost: promote the replica"
r "SELECT pg_promote(wait => true);"
r "CHECKPOINT;"
r "SELECT pg_is_in_recovery() AS is_replica, timeline_id FROM pg_control_checkpoint();"

step "3. The new primary now accepts writes"
r "INSERT INTO carebridge.patients (mrn, first_name, last_name, dob, gender, home_branch_id)
   VALUES ('CB-900010', 'Ngozi', 'Failover', '1979-02-14', 'female', 3) RETURNING mrn;"

step "4. But the old primary is still running and also accepts writes (split brain)"
p "INSERT INTO carebridge.patients (mrn, first_name, last_name, dob, gender, home_branch_id)
   VALUES ('CB-900011', 'Emeka', 'SplitBrain', '1988-07-01', 'male', 1) RETURNING mrn;"
r "SELECT mrn FROM carebridge.patients WHERE mrn IN ('CB-900010', 'CB-900011') ORDER BY mrn;"
p "SELECT mrn FROM carebridge.patients WHERE mrn IN ('CB-900010', 'CB-900011') ORDER BY mrn;"
p "SELECT slot_name, active FROM pg_replication_slots;"

p "DELETE FROM carebridge.patients WHERE mrn IN ('CB-900010', 'CB-900011');"
echo
echo "The two servers have now diverged. Run Oyediran_Taiwo_301921478_P5_99_teardown_replica.sh to remove the old replica."
