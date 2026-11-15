// CareBridge Portfolio 4: query plans before and after indexing
// mongosh --quiet carebridge Oyediran_Taiwo_301921478_P4_06_indexes_explain.js

const lagos = s => new Date(s + '+01:00');
const day = { $gte: lagos('2026-03-09T00:00'), $lt: lagos('2026-03-10T00:00') };
const ci = { locale: 'en', strength: 2 };

const queries = {
  'M1 patient by MRN':       () => db.patients.find({ mrn: 'CB-000123' }).limit(1),
  'M2 patient by name':      () => db.patients.find({ last_name: 'okafor', first_name: 'CHINEDU' }).collation(ci),
  'M3a doctor_days':         () => db.doctor_days.find({ 'doctor.id': 9, date: '2026-03-09' }),
  'M3b visits by doctor':    () => db.patients.find({ visits: { $elemMatch: { 'doctor.id': 9, start: day } } }),
  'M6 HbA1c > 6.5':          () => db.patients.find({ 'visits.consultation.lab_tests':
                                     { $elemMatch: { test: 'HbA1c', 'result.value': { $gt: 6.5 } } } })
};

function plan(node) {
  if (!node) return [];
  const own = node.stage + (node.indexName ? `(${node.indexName})` : '');
  return [...plan(node.inputStage), ...(node.inputStages ?? []).flatMap(plan), own];
}

function median(fn) {
  fn().toArray();
  const runs = [];
  for (let i = 0; i < 7; i++) { const t = Date.now(); fn().toArray(); runs.push(Date.now() - t); }
  return runs.sort((a, b) => a - b)[3];
}

function report(title) {
  print(`\n== ${title}`);
  const rows = {};
  for (const [name, q] of Object.entries(queries)) {
    const ex = q().explain('executionStats');
    const wp = ex.queryPlanner.winningPlan;
    rows[name] = {
      plan: plan(wp.queryPlan ?? wp).join(' > '),
      keys_examined: ex.executionStats.totalKeysExamined,
      docs_examined: ex.executionStats.totalDocsExamined,
      returned: ex.executionStats.nReturned,
      median_ms: median(q)
    };
  }
  console.table(rows);
}

db.patients.dropIndexes();
db.doctor_days.dropIndexes();
report('Before: only the default _id index');

db.patients.createIndex({ mrn: 1 }, { unique: true, name: 'ix_mrn' });
db.patients.createIndex({ last_name: 1, first_name: 1 }, { collation: ci, name: 'ix_name_ci' });
db.doctor_days.createIndex({ 'doctor.id': 1, date: 1 }, { unique: true, name: 'ix_doctor_date' });
db.patients.createIndex({ 'visits.doctor.id': 1, 'visits.start': 1 }, { name: 'ix_visit_doctor_start' });
db.patients.createIndex({ 'visits.consultation.lab_tests.test': 1, 'visits.consultation.lab_tests.result.value': 1 },
                        { name: 'ix_lab_test_value' });

report('After: five secondary indexes');

print('\n== Index sizes (KB)');
const sizes = {};
for (const c of ['patients', 'doctor_days']) {
  const s = db[c].stats().indexSizes;
  for (const [k, v] of Object.entries(s)) sizes[`${c}.${k}`] = Math.round(v / 1024);
}
console.table(sizes);
print(`patients data size ${Math.round(db.patients.stats().size / 1024 / 1024)} MB, `
    + `storage ${Math.round(db.patients.stats().storageSize / 1024 / 1024)} MB (compressed)`);
