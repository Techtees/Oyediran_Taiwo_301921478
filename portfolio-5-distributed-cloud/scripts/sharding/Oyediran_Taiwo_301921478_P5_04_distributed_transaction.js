// CareBridge Portfolio 5: multi-document transactions across shards (refused in Portfolio 4 on a standalone server)
// mongosh --quiet --port 27100 carebridge Oyediran_Taiwo_301921478_P5_04_distributed_transaction.js

const shardOf = filter => {
  for (const [shard, port] of [['shard_ikeja', 27101], ['shard_lekki', 27102], ['shard_yaba', 27103]]) {
    if (new Mongo('localhost:' + port).getDB('carebridge').patients.countDocuments(filter)) return shard;
  }
  return 'none';
};
const lagos = s => new Date(s + '+01:00');
const DAY = '2027-01-06';
const hadiza = { id: 9, name: 'Dr Hadiza Abubakar', department: 'Paediatrics' };
db.doctor_days.deleteOne({ 'doctor.id': 9, date: DAY });
db.patients.updateMany({ 'visits.appointment_id': { $gte: 900000 } }, { $pull: { visits: { appointment_id: { $gte: 900000 } } } });

const patient = db.patients.findOne({ home_branch: 'CareBridge Yaba' }, { mrn: 1, home_branch: 1 });
print(`Patient ${patient.mrn} (${patient.home_branch}) is stored on ${shardOf({ _id: patient._id })}; doctor_days is on shard_lekki`);

function book(label, start, end, failAfterSlot) {
  const session = db.getMongo().startSession();
  const s = session.getDatabase('carebridge');
  session.startTransaction({ readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } });
  try {
    s.doctor_days.updateOne({ 'doctor.id': 9, date: DAY },
      { $setOnInsert: { doctor: hadiza }, $push: { slots: { start: lagos(`${DAY}T${start}`), end: lagos(`${DAY}T${end}`),
        branch: 'CareBridge Lekki', status: 'scheduled', patient: { id: patient._id, mrn: patient.mrn } } } }, { upsert: true });
    if (failAfterSlot) throw new Error('simulated failure after the slot was written, before the patient visit');
    s.patients.updateOne({ home_branch: patient.home_branch, _id: patient._id },
      { $push: { visits: { appointment_id: 900200 + Number(start.slice(0, 2)), start: lagos(`${DAY}T${start}`), status: 'scheduled',
                           branch: 'CareBridge Lekki', doctor: hadiza, reason: 'P5 demo' } } });
    session.commitTransaction();
    print(`${label}: COMMITTED (writes on shard_lekki and ${shardOf({ _id: patient._id })})`);
  } catch (e) {
    session.abortTransaction();
    print(`${label}: ABORTED (${e.message})`);
  } finally {
    session.endSession();
  }
}

print('\n== 1. Booking = doctor_days slot + patient visit, in one transaction across two shards');
book('Booking 10:00', '10:00', '10:30', false);
book('Booking 11:00', '11:00', '11:30', true);
const slots = db.doctor_days.findOne({ 'doctor.id': 9, date: DAY })?.slots ?? [];
const visits = db.patients.findOne({ _id: patient._id }).visits.filter(v => v.appointment_id >= 900000);
console.table({ 'slots in doctor_days': slots.length, 'visits in patient document': visits.length });

print('\n== 2. Changing the shard key value moves the document to another shard');
const mover = db.patients.findOne({ home_branch: 'CareBridge Ikeja' }, { mrn: 1, home_branch: 1 });
print(`Before: ${mover.mrn} home_branch ${mover.home_branch}, stored on ${shardOf({ _id: mover._id })}`);
const session = db.getMongo().startSession();
session.startTransaction();
session.getDatabase('carebridge').patients.updateOne({ home_branch: mover.home_branch, _id: mover._id },
                                                    { $set: { home_branch: 'CareBridge Lekki' } });
session.commitTransaction();
session.endSession();
print(`After:  ${mover.mrn} home_branch CareBridge Lekki, stored on ${shardOf({ _id: mover._id })}`);
db.patients.updateOne({ home_branch: 'CareBridge Lekki', _id: mover._id }, { $set: { home_branch: mover.home_branch } });

db.doctor_days.deleteOne({ 'doctor.id': 9, date: DAY });
db.patients.updateMany({ _id: patient._id }, { $pull: { visits: { appointment_id: { $gte: 900000 } } } });
print('\nDemo changes removed.');
