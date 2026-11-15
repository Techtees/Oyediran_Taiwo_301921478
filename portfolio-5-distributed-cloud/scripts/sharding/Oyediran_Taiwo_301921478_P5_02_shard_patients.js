// CareBridge Portfolio 5: shard patients by home branch, one zone per branch shard
const cb = db.getSiblingDB('carebridge');
cb.dropDatabase();

const zones = [['shard_ikeja', 'IKEJA', 'CareBridge Ikeja'],
               ['shard_lekki', 'LEKKI', 'CareBridge Lekki'],
               ['shard_yaba',  'YABA',  'CareBridge Yaba']];

sh.enableSharding('carebridge', 'shard_lekki');
for (const [shard, zone, branch] of zones) {
  sh.addShardToZone(shard, zone);
  sh.updateZoneKeyRange('carebridge.patients',
                        { home_branch: branch, _id: MinKey }, { home_branch: branch, _id: MaxKey }, zone);
}
sh.shardCollection('carebridge.patients', { home_branch: 1, _id: 1 });
print('patients sharded on { home_branch: 1, _id: 1 } with zones IKEJA, LEKKI, YABA');
