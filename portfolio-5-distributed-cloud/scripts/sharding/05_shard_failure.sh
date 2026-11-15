#!/usr/bin/env bash
# CareBridge Portfolio 5: the Yaba shard goes down - what still works?
cd "$(dirname "$0")" && source env.sh

q() {
  printf '\n\033[1;36m[mongos]\033[0m %s\n' "$1"
  mongosh --quiet --port 27100 carebridge --eval "
    const t = Date.now();
    try { const r = $2; print('OK   ' + JSON.stringify(r) + '   (' + (Date.now() - t) + ' ms)'); }
    catch (e) { print('FAIL ' + e.message.split('\n')[0].slice(0, 150) + '   (' + (Date.now() - t) + ' ms)'); }"
}
queries() {
  q "A Lekki patient (targeted to shard_lekki)" \
    "db.patients.find({ home_branch: 'CareBridge Lekki' }, { mrn: 1, first_name: 1, _id: 0 }).limit(1).maxTimeMS(5000).toArray()"
  q "A Yaba patient (targeted to shard_yaba)" \
    "db.patients.find({ home_branch: 'CareBridge Yaba' }, { mrn: 1, first_name: 1, _id: 0 }).limit(1).maxTimeMS(5000).toArray()"
  q "Count Lekki patients (targeted to shard_lekki)" \
    "db.patients.countDocuments({ home_branch: 'CareBridge Lekki' }, { maxTimeMS: 5000 })"
  q "Count all patients (scatter-gather to every shard)" \
    "db.patients.countDocuments({}, { maxTimeMS: 5000 })"
  q "Doctor diary (doctor_days lives on shard_lekki)" \
    "db.doctor_days.findOne({ 'doctor.id': 9, date: '2026-03-09' }).slots.length"
}

step "1. All shards up"
queries

step "2. Stop the Yaba shard"
mongosh --quiet --port 27103 admin --eval 'db.shutdownServer({ force: true })' >/dev/null 2>&1
sleep 2
lsof -nP -iTCP:27103 -sTCP:LISTEN >/dev/null && echo "shard_yaba still running" || echo "shard_yaba (port 27103) is down"
queries

step "3. Restart the Yaba shard"
mongod --shardsvr --replSet shard_yaba --port 27103 --dbpath "$MDIR/yaba" --bind_ip localhost \
       --wiredTigerCacheSizeGB 0.25 --fork --logpath "$MDIR/logs/yaba.log" >/dev/null && echo "shard_yaba restarted"
mongosh --quiet --port 27103 --eval 'while (!db.hello().isWritablePrimary) { sleep(500); }'
sleep 2
q "Count all patients" "db.patients.countDocuments({}, { maxTimeMS: 10000 })"
