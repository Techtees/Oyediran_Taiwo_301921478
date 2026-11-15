// CareBridge Portfolio 5: how mongos routes queries to shards
// mongosh --quiet --port 27100 carebridge 03_routing.js

function route(label, explain) {
  const plan = explain.queryPlanner?.winningPlan;
  const shards = plan ? plan.shards.map(s => s.shardName) : Object.keys(explain.shards);
  const stage = plan ? plan.stage : (explain.mergeType ? `merge on ${explain.mergeType}` : 'aggregate');
  return { query: label, mongos_stage: stage, shards_contacted: shards.length, shards: shards.join(', ') };
}

print('== 1. Query routing');
const p = db.patients.findOne({ mrn: 'CB-000123' }, { mrn: 1, home_branch: 1 });
print(`CB-000123 is registered at ${p.home_branch}`);
console.table([
  route('mrn + home_branch (contains the shard key)',
        db.patients.find({ home_branch: p.home_branch, mrn: 'CB-000123' }).explain()),
  route('mrn only (no shard key)',
        db.patients.find({ mrn: 'CB-000123' }).explain()),
  route('all Lekki patients born before 1960',
        db.patients.find({ home_branch: 'CareBridge Lekki', dob: { $lt: new Date('1960-01-01') } }).explain()),
  route('diagnoses per department (aggregation)',
        db.patients.explain().aggregate([{ $unwind: '$visits' },
          { $unwind: '$visits.consultation.diagnoses' },
          { $group: { _id: '$visits.doctor.department', n: { $sum: 1 } } }]))
]);

print('\n== 2. A unique MRN cannot be enforced across shards');
try {
  db.patients.createIndex({ mrn: 1 }, { unique: true, name: 'ux_mrn' });
  print('unique index created');
} catch (e) {
  print(`createIndex({ mrn: 1 }, { unique: true }) refused:\n  ${e.message.split(':: caused by :: ').pop()}`);
}

print('\n== 3. Is home branch a good shard key? Where do patients actually have their visits?');
const r = db.patients.aggregate([
  { $unwind: '$visits' },
  { $group: { _id: { $eq: ['$visits.branch', '$home_branch'] }, visits: { $sum: 1 } } }
]).toArray();
const same = r.find(x => x._id === true)?.visits ?? 0, other = r.find(x => x._id === false)?.visits ?? 0;
console.table({ 'visits at home branch': same, 'visits at another branch': other,
                'share at another branch': `${(100 * other / (same + other)).toFixed(1)}%` });
const multi = db.patients.aggregate([
  { $project: { branches: { $size: { $setUnion: ['$visits.branch', []] } } } },
  { $group: { _id: '$branches', patients: { $sum: 1 } } }, { $sort: { _id: 1 } }]).toArray();
console.table(multi.map(m => ({ branches_visited: m._id, patients: m.patients })));
