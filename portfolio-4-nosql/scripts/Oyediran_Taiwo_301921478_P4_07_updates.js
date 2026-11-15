// CareBridge Portfolio 4: writes, atomicity and the cost of duplicated data
// mongosh --quiet carebridge Oyediran_Taiwo_301921478_P4_07_updates.js

const lagos = s => new Date(s + '+01:00');
const local = d => new Date(d.getTime() + 3600000).toISOString().slice(11, 16);
const DAY = '2027-01-06';
const hadiza = { id: 9, name: 'Dr Hadiza Abubakar', department: 'Paediatrics' };

db.doctor_days.deleteOne({ 'doctor.id': 9, date: DAY });
db.patients.updateMany({}, { $pull: { visits: { appointment_id: { $gte: 900000 } } } });

print('== 1. Booking with an atomic check inside one document (bucket pattern)');
db.doctor_days.updateOne({ 'doctor.id': 9, date: DAY },
                         { $setOnInsert: { doctor: hadiza, slots: [] } }, { upsert: true });

function book(label, patient, start, end) {
  const s = lagos(`${DAY}T${start}`), e = lagos(`${DAY}T${end}`);
  const r = db.doctor_days.updateOne(
    { 'doctor.id': 9, date: DAY, slots: { $not: { $elemMatch: { start: { $lt: e }, end: { $gt: s } } } } },
    { $push: { slots: { start: s, end: e, branch: 'CareBridge Lekki', status: 'scheduled', patient } } });
  print(`${label} ${start}-${end}  matched ${r.matchedCount}, modified ${r.modifiedCount}  `
      + (r.modifiedCount ? 'BOOKED' : 'REJECTED (overlaps an existing slot)'));
  return r.modifiedCount === 1;
}
const p124 = db.patients.findOne({ mrn: 'CB-000124' }, { mrn: 1, first_name: 1, last_name: 1 });
const p125 = db.patients.findOne({ mrn: 'CB-000125' }, { mrn: 1, first_name: 1, last_name: 1 });
const asSlot = p => ({ id: p._id, mrn: p.mrn, name: `${p.first_name} ${p.last_name}` });

if (book('Receptionist A', asSlot(p124), '10:00', '10:30')) {
  db.patients.updateOne({ _id: p124._id }, { $push: { visits: {
    appointment_id: 900101, start: lagos(`${DAY}T10:00`), status: 'scheduled',
    branch: 'CareBridge Lekki', doctor: hadiza, reason: 'P4 demo' } } });
}
book('Receptionist B', asSlot(p125), '10:15', '10:45');
book('Receptionist B', asSlot(p125), '10:30', '11:00');
console.table(db.doctor_days.findOne({ 'doctor.id': 9, date: DAY }).slots
  .map(s => ({ start: local(s.start), end: local(s.end), patient: s.patient.mrn })));
print('Note: the visit for CB-000125 was never added to the patients collection. Two documents had to change,');
print('and without a transaction nothing forces both writes to happen together.');

print('\n== 2. Multi-document transaction on this standalone server');
try {
  db.runCommand({
    update: 'patients',
    updates: [{ q: { _id: p125._id }, u: { $push: { visits: {
      appointment_id: 900102, start: lagos(`${DAY}T10:30`), status: 'scheduled',
      branch: 'CareBridge Lekki', doctor: hadiza, reason: 'P4 demo' } } } }],
    lsid: { id: UUID() }, txnNumber: NumberLong('1'), startTransaction: true, autocommit: false
  });
  print('Transaction started');
} catch (e) {
  print(`Transaction refused: ${e.message}`);
}

print('\n== 3. Taking a payment: one atomic update of one embedded bill');
const BILL = 21;
const before = db.patients.findOne({ 'visits.bill.bill_id': BILL }, { mrn: 1, 'visits.$': 1 });
const original = before.visits[0].bill;
print(`Before: ${before.mrn} bill ${BILL} status ${original.status}, paid ${original.paid}, balance ${original.balance}`);
const amount = original.balance;
db.patients.updateOne(
  { _id: before._id },
  { $push: { 'visits.$[v].bill.payments': { amount, method: 'transfer', paid_at: new Date(), reference: 'P4-DEMO' } },
    $inc:  { 'visits.$[v].bill.paid': amount, 'visits.$[v].bill.balance': NumberDecimal('-' + amount.toString()) },
    $set:  { 'visits.$[v].bill.status': 'paid' } },
  { arrayFilters: [{ 'v.bill.bill_id': BILL }] });
const after = db.patients.findOne({ 'visits.bill.bill_id': BILL }, { 'visits.$': 1 }).visits[0].bill;
print(`After:  bill ${BILL} status ${after.status}, paid ${after.paid}, balance ${after.balance}, payments ${after.payments.length}`);
db.patients.updateOne({ _id: before._id }, { $set: { 'visits.$[v].bill': original } },
                      { arrayFilters: [{ 'v.bill.bill_id': BILL }] });

print('\n== 4. The cost of duplication: Dr Hadiza Abubakar changes her surname to Bello');
const t = Date.now();
const r1 = db.patients.updateMany({ 'visits.doctor.id': 9 },
                                  { $set: { 'visits.$[v].doctor.name': 'Dr Hadiza Bello' } },
                                  { arrayFilters: [{ 'v.doctor.id': 9 }] });
const r2 = db.doctor_days.updateMany({ 'doctor.id': 9 }, { $set: { 'doctor.name': 'Dr Hadiza Bello' } });
const ms = Date.now() - t;
const copies = db.patients.aggregate([{ $unwind: '$visits' }, { $match: { 'visits.doctor.id': 9 } }, { $count: 'n' }]).next().n;
print(`patients modified: ${r1.modifiedCount} documents (${copies} embedded copies of her name)`);
print(`doctor_days modified: ${r2.modifiedCount} documents`);
print(`time: ${ms} ms. In PostgreSQL the same change is one row: UPDATE staff SET full_name = ... WHERE staff_id = 9`);
db.patients.updateMany({ 'visits.doctor.id': 9 }, { $set: { 'visits.$[v].doctor.name': hadiza.name } },
                       { arrayFilters: [{ 'v.doctor.id': 9 }] });
db.doctor_days.updateMany({ 'doctor.id': 9 }, { $set: { 'doctor.name': hadiza.name } });

db.doctor_days.deleteOne({ 'doctor.id': 9, date: DAY });
db.patients.updateMany({}, { $pull: { visits: { appointment_id: { $gte: 900000 } } } });
print('\nDemo changes removed.');
