#!/usr/bin/env bash
# CareBridge Portfolio 5: local sharded cluster - 1 config server, 3 shards (one per branch), 1 mongos router
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh
mkdir -p "$MDIR"/{config,ikeja,lekki,yaba,logs}

start() {
  if lsof -nP -iTCP:"$3" -sTCP:LISTEN >/dev/null; then echo "$2 already running on port $3"; return; fi
  mongod --"$1" --replSet "$2" --port "$3" --dbpath "$MDIR/$4" --bind_ip localhost \
         --wiredTigerCacheSizeGB 0.25 --fork --logpath "$MDIR/logs/$4.log" >/dev/null && echo "started $2 on port $3"
}
init() {
  mongosh --quiet --port "$1" --eval "
    try { rs.status(); } catch (e) { rs.initiate({ _id: '$2', configsvr: $3, members: [{ _id: 0, host: 'localhost:$1' }] }); }
    while (!db.hello().isWritablePrimary) { sleep(500); }
    print('$2 replica set ready (primary localhost:$1)');"
}

step "1. Config server and three shard servers"
start configsvr cfg         27019 config
start shardsvr  shard_ikeja 27101 ikeja
start shardsvr  shard_lekki 27102 lekki
start shardsvr  shard_yaba  27103 yaba

step "2. Each server is a one-member replica set"
init 27019 cfg         true
init 27101 shard_ikeja false
init 27102 shard_lekki false
init 27103 shard_yaba  false

step "3. mongos router on port 27100"
if lsof -nP -iTCP:27100 -sTCP:LISTEN >/dev/null; then echo "mongos already running"; else
  mongos --configdb cfg/localhost:27019 --port 27100 --bind_ip localhost --fork --logpath "$MDIR/logs/mongos.log" >/dev/null && echo "started mongos on port 27100"
fi

step "4. Register the shards"
mongosh --quiet --port 27100 --eval "
  const have = db.adminCommand({ listShards: 1 }).shards.map(s => s._id);
  for (const [name, port] of [['shard_ikeja', 27101], ['shard_lekki', 27102], ['shard_yaba', 27103]]) {
    if (!have.includes(name)) sh.addShard(name + '/localhost:' + port);
  }
  console.table(db.adminCommand({ listShards: 1 }).shards.map(s => ({ shard: s._id, host: s.host, state: s.state })));"
