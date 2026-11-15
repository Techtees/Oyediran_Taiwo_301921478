// CareBridge Portfolio 4: the Portfolio 2 workload rewritten for MongoDB
// mongosh --quiet carebridge Oyediran_Taiwo_301921478_P4_05_queries.js

function timed(fn) {
  fn();
  const runs = [];
  for (let i = 0; i < 5; i++) { const t = Date.now(); fn(); runs.push(Date.now() - t); }
  runs.sort((a, b) => a - b);
  return runs[2];
}
const lagos = s => new Date(s + '+01:00');
const local = d => new Date(d.getTime() + 3600000).toISOString().slice(0, 16).replace('T', ' ');

print('\nM1  (P2 Q7) Full visit history for patient CB-000123: one document, no joins');
const m1 = () => db.patients.findOne({ mrn: 'CB-000123' });
const p = m1();
print(`${p.first_name} ${p.last_name}, ${p.visits.length} visits`);
console.table(p.visits.flatMap(v => (v.consultation?.diagnoses ?? [null]).map(d => ({
  start: local(v.start), branch: v.branch, doctor: v.doctor.name, status: v.status,
  icd10: d?.code ?? '', primary: d?.primary ?? ''
}))).filter(r => r.status === 'completed'));
print(`median ${timed(m1)} ms`);

print('\nM2  (P2 Q1) Find a patient by name, case-insensitive (collation strength 2)');
const m2 = () => db.patients.find({ last_name: 'okafor', first_name: 'CHINEDU' },
                                  { mrn: 1, first_name: 1, last_name: 1, dob: 1, phone: 1 })
                            .collation({ locale: 'en', strength: 2 }).toArray();
console.table(m2());
print(`median ${timed(m2)} ms`);

print('\nM3a (P2 Q2) Dr Hadiza Abubakar, 9 March 2026, from doctor_days (bucket pattern)');
const m3a = () => db.doctor_days.findOne({ 'doctor.id': 9, date: '2026-03-09' });
console.table(m3a().slots.map(s => ({ start: local(s.start), branch: s.branch,
                                       status: s.status, mrn: s.patient.mrn, patient: s.patient.name })));
print(`median ${timed(m3a)} ms`);

print('\nM3b Same question answered from patients (visits embedded per patient)');
const m3b = () => db.patients.aggregate([
  { $match: { visits: { $elemMatch: { 'doctor.id': 9, start: { $gte: lagos('2026-03-09T00:00'), $lt: lagos('2026-03-10T00:00') } } } } },
  { $unwind: '$visits' },
  { $match: { 'visits.doctor.id': 9, 'visits.start': { $gte: lagos('2026-03-09T00:00'), $lt: lagos('2026-03-10T00:00') } } },
  { $sort: { 'visits.start': 1 } },
  { $project: { _id: 0, start: '$visits.start', status: '$visits.status', mrn: 1 } }
]).toArray();
print(`${m3b().length} rows, median ${timed(m3b)} ms`);

print('\nM4  (P2 Q3) Oldest 20 outstanding bills at Lekki');
const m4 = () => db.patients.aggregate([
  { $unwind: '$visits' },
  { $match: { 'visits.branch': 'CareBridge Lekki', 'visits.bill.status': { $in: ['unpaid', 'part_paid'] } } },
  { $sort: { 'visits.bill.created_at': 1 } },
  { $limit: 20 },
  { $project: { _id: 0, bill_id: '$visits.bill.bill_id', created_at: '$visits.bill.created_at',
                total: '$visits.bill.total', balance: '$visits.bill.balance', mrn: 1 } }
]).toArray();
console.table(m4().map(r => ({ ...r, created_at: local(r.created_at),
                               total: r.total.toString(), balance: r.balance.toString() })));
print(`median ${timed(m4)} ms`);

print('\nM5  (P2 Q6) Most common diagnoses per department, May-October 2026 (top 3 per department shown)');
const m5 = () => db.patients.aggregate([
  { $unwind: '$visits' },
  { $match: { 'visits.start': { $gte: lagos('2026-05-01T00:00'), $lt: lagos('2026-11-01T00:00') } } },
  { $unwind: '$visits.consultation.diagnoses' },
  { $group: { _id: { department: '$visits.doctor.department', code: '$visits.consultation.diagnoses.code',
                     description: '$visits.consultation.diagnoses.description' }, cases: { $sum: 1 } } },
  { $sort: { '_id.department': 1, cases: -1 } }
]).toArray();
const r5 = m5();
print(`${r5.length} groups, ${r5.reduce((n, r) => n + r.cases, 0)} diagnoses in total`);
console.table(r5.filter((r, i, a) => a.findIndex(x => x._id.department === r._id.department) > i - 3)
                .map(r => ({ department: r._id.department, icd10: r._id.code, description: r._id.description.slice(0, 40), cases: r.cases })));
print(`median ${timed(m5)} ms`);

print('\nM6  Patients with an HbA1c result above 6.5% (numbers stored as numbers, so $gt works)');
const m6 = () => db.patients.find(
  { 'visits.consultation.lab_tests': { $elemMatch: { test: 'HbA1c', 'result.value': { $gt: 6.5 } } } },
  { mrn: 1, first_name: 1, last_name: 1 }).sort({ _id: 1 }).toArray();
const r6 = m6();
print(`${r6.length} patients, for example:`);
console.table(r6.slice(0, 5));
print(`median ${timed(m6)} ms`);
