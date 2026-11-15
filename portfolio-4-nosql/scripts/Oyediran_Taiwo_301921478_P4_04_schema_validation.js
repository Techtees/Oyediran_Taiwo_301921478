// CareBridge Portfolio 4: JSON Schema validation on the patients collection
// mongosh --quiet carebridge Oyediran_Taiwo_301921478_P4_04_schema_validation.js

db.runCommand({
  collMod: 'patients',
  validationLevel: 'strict',
  validationAction: 'error',
  validator: { $jsonSchema: {
    bsonType: 'object',
    required: ['_id', 'mrn', 'first_name', 'last_name', 'dob', 'home_branch', 'visits'],
    properties: {
      mrn:         { bsonType: 'string', pattern: '^CB-[0-9]{6}$' },
      first_name:  { bsonType: 'string', minLength: 1 },
      last_name:   { bsonType: 'string', minLength: 1 },
      dob:         { bsonType: 'date' },
      gender:      { enum: ['male', 'female', 'other'] },
      blood_group: { enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] },
      home_branch: { enum: ['CareBridge Ikeja', 'CareBridge Lekki', 'CareBridge Yaba'] },
      visits: {
        bsonType: 'array',
        items: {
          bsonType: 'object',
          required: ['appointment_id', 'start', 'status', 'branch', 'doctor'],
          properties: {
            start:  { bsonType: 'date' },
            status: { enum: ['scheduled', 'completed', 'cancelled', 'no_show'] },
            branch: { enum: ['CareBridge Ikeja', 'CareBridge Lekki', 'CareBridge Yaba'] },
            doctor: { bsonType: 'object', required: ['id', 'name', 'department'] },
            bill: {
              bsonType: 'object',
              required: ['bill_id', 'status', 'total', 'paid', 'balance'],
              properties: {
                status: { enum: ['unpaid', 'part_paid', 'paid', 'void'] },
                total:  { bsonType: 'decimal' },
                paid:   { bsonType: 'decimal' }
              }
            }
          }
        }
      }
    }
  } }
});
print('Validator added to patients');
const rules = db.getCollectionInfos({ name: 'patients' })[0].options.validator;
print(`Existing documents that break the rules: ${db.patients.countDocuments({ $nor: [rules] })} `
    + '(collMod does not check data that is already stored)');

function why(node, path) {
  if (Array.isArray(node)) {
    for (const n of node) { const r = why(n, path); if (r) return r; }
    return null;
  }
  if (node.propertiesNotSatisfied) return why(node.propertiesNotSatisfied, path);
  if (node.propertyName !== undefined) return why(node.details, path ? `${path}.${node.propertyName}` : node.propertyName);
  if (node.itemIndex !== undefined && node.details) return why(node.details, `${path}[${node.itemIndex}]`);
  if (node.missingProperties) return `${path || 'document'}: missing ${node.missingProperties.join(', ')}`;
  return `${path}: ${node.operatorName} - ${node.reason}`;
}

function attempt(label, doc) {
  try {
    db.patients.insertOne(doc);
    print(`${label}  ACCEPTED`);
  } catch (e) {
    print(`${label}  REJECTED  ${why(e.errInfo.details.schemaRulesNotSatisfied, '')}`);
  }
}

const good = {
  _id: 999001, mrn: 'CB-999001', first_name: 'Test', last_name: 'Patient',
  dob: new Date('1990-05-01'), gender: 'female', blood_group: 'O+',
  home_branch: 'CareBridge Lekki', visits: []
};

attempt('1 valid patient            ', good);
const { dob, ...noDob } = good;
attempt('2 missing date of birth    ', { ...noDob, _id: 999002, mrn: 'CB-999002' });
attempt('3 blood group "C+"         ', { ...good, _id: 999003, mrn: 'CB-999003', blood_group: 'C+' });
attempt('4 MRN in the wrong format  ', { ...good, _id: 999004, mrn: '999004' });
attempt('5 visit with unknown status', { ...good, _id: 999005, mrn: 'CB-999005',
  visits: [{ appointment_id: 1, start: new Date(), status: 'done', branch: 'CareBridge Lekki',
             doctor: { id: 9, name: 'Dr Hadiza Abubakar', department: 'Paediatrics' } }] });
attempt('6 bill total as a string   ', { ...good, _id: 999006, mrn: 'CB-999006',
  visits: [{ appointment_id: 1, start: new Date(), status: 'completed', branch: 'CareBridge Lekki',
             doctor: { id: 9, name: 'Dr Hadiza Abubakar', department: 'Paediatrics' },
             bill: { bill_id: 1, status: 'unpaid', total: '15000', paid: NumberDecimal('0'), balance: NumberDecimal('15000') } }] });
attempt('7 doctor 12345 does not exist', { ...good, _id: 999007, mrn: 'CB-999007',
  visits: [{ appointment_id: 1, start: new Date(), status: 'completed', branch: 'CareBridge Lekki',
             doctor: { id: 12345, name: 'Dr Nobody', department: 'None' } }] });

db.patients.deleteMany({ _id: { $gte: 999000 } });
print(`Test documents removed, patients = ${db.patients.countDocuments()}`);
