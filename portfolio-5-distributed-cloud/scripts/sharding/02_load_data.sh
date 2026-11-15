#!/usr/bin/env bash
# CareBridge Portfolio 5: shard the collection, then load the Portfolio 4 documents through mongos
cd "$(dirname "$0")" && source env.sh
if [ ! -f "$P4_DATA/patients.json" ]; then
  echo "Portfolio 4 export not found, running it first"
  (cd ../../../portfolio-4-nosql/scripts && psql -X -q -d carebridge -f 01_export_from_postgres.sql)
fi

step "1. Define zones and shard carebridge.patients"
mongosh --quiet --port 27100 02_shard_patients.js

step "2. Load 5,000 patients and the unsharded doctor_days collection through mongos"
mongoimport --quiet --port 27100 --db carebridge --collection patients    --file "$P4_DATA/patients.json"
mongoimport --quiet --port 27100 --db carebridge --collection doctor_days --file "$P4_DATA/doctor_days.json"
mongosh --quiet --port 27100 carebridge --eval '
  db.patients.createIndex({ mrn: 1 });
  db.doctor_days.createIndex({ "doctor.id": 1, date: 1 }, { unique: true });
  print("indexes created");'

step "3. Where the documents ended up"
mongosh --quiet --port 27100 carebridge --eval '
  const rows = {};
  for (const [shard, port] of [["shard_ikeja", 27101], ["shard_lekki", 27102], ["shard_yaba", 27103]]) {
    const local = new Mongo("localhost:" + port).getDB("carebridge");
    const byBranch = local.patients.aggregate([{ $group: { _id: "$home_branch", n: { $sum: 1 } } }]).toArray();
    rows[shard] = { patients: local.patients.countDocuments(),
                    home_branches: byBranch.map(b => b._id).join(", "),
                    doctor_days: local.doctor_days.countDocuments() };
  }
  console.table(rows);
  print("Total through mongos: " + db.patients.countDocuments() + " patients");
  const chunks = db.getSiblingDB("config").chunks.aggregate([
    { $lookup: { from: "collections", localField: "uuid", foreignField: "uuid", as: "c" } },
    { $match: { "c._id": "carebridge.patients" } },
    { $group: { _id: "$shard", chunks: { $sum: 1 } } }, { $sort: { _id: 1 } }]).toArray();
  console.table(chunks);'
