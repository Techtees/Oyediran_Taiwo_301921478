const r = db.patients.aggregate([
  { $unwind: '$visits' },
  { $group: {
      _id: null,
      appointments:  { $sum: 1 },
      consultations: { $sum: { $cond: [{ $ifNull: ['$visits.consultation', false] }, 1, 0] } },
      diagnoses:     { $sum: { $size: { $ifNull: ['$visits.consultation.diagnoses', []] } } },
      prescription_items: { $sum: { $sum: { $map: { input: { $ifNull: ['$visits.consultation.prescriptions', []] },
                                                    in: { $size: '$$this.items' } } } } },
      lab_orders:    { $sum: { $size: { $ifNull: ['$visits.consultation.lab_tests', []] } } },
      lab_results:   { $sum: { $size: { $filter: { input: { $ifNull: ['$visits.consultation.lab_tests', []] },
                                                   cond: { $ifNull: ['$$this.result', false] } } } } },
      bills:         { $sum: { $cond: [{ $ifNull: ['$visits.bill', false] }, 1, 0] } },
      payments:      { $sum: { $size: { $ifNull: ['$visits.bill.payments', []] } } },
      total_billed:  { $sum: '$visits.bill.total' }
  } }
]).next();

const rows = {
  'patients':           db.patients.countDocuments(),
  'appointments':       r.appointments,
  'consultations':      r.consultations,
  'diagnoses':          r.diagnoses,
  'prescription items': r.prescription_items,
  'lab orders':         r.lab_orders,
  'lab results':        r.lab_results,
  'bills':              r.bills,
  'payments':           r.payments,
  'total billed':       r.total_billed.toString(),
  'doctor-days':        db.doctor_days.countDocuments()
};
console.table(rows);

const sizes = db.patients.aggregate([
  { $project: { size: { $bsonSize: '$$ROOT' }, visits: { $size: '$visits' } } },
  { $group: { _id: null, avg_kb: { $avg: { $divide: ['$size', 1024] } }, max_kb: { $max: { $divide: ['$size', 1024] } },
              max_visits: { $max: '$visits' } } }
]).next();
print(`Patient document size: average ${sizes.avg_kb.toFixed(1)} KB, largest ${sizes.max_kb.toFixed(1)} KB `
    + `(${sizes.max_visits} visits max), MongoDB limit 16,384 KB`);
