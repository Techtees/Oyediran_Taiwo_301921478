# MIT 8103 Advanced Database Systems: Continuous Assessment Portfolio

## CareBridge Clinics Patient and Operations Database

### Student Information

- **Name:** Oyediran Taiwo
- **Student ID:** 301921478
- **Course:** MIT 8103 Advanced Database Systems
- **Assessment:** Continuous Assessment Portfolio (five activities)
- **Session:** 2026/2027 First Semester
- **Institution:** MIVA Open University
- **Repository:** [github.com/Techtees/Oyediran_Taiwo_301921478](https://github.com/Techtees/Oyediran_Taiwo_301921478)

---

## 1. Project Overview

This repository holds my five-part portfolio for MIT 8103. Instead of five unrelated exercises, every activity is built on the same case study, CareBridge Clinics, and on the same database, so each portfolio picks up from where the previous one stopped.

Portfolio 1 designs the relational database and fills it with about 495,000 rows of synthetic data. Portfolio 2 uses that data to study how PostgreSQL executes real queries and how indexes and rewrites change that. Portfolio 3 tests what happens when several staff change the same data at the same time. Portfolio 4 moves the same data into MongoDB to compare a document model with the relational one. Portfolio 5 spreads the database across several servers with replication and sharding, and ends with a cloud design for CareBridge.

Every claim in the portfolio READMEs is backed by a script that can be re-run and by a screenshot of my own output.

## 2. Selected Organisation / Case Study

**CareBridge Clinics** is a simulated private healthcare provider running three outpatient clinics in Lagos, Nigeria: **Ikeja**, **Lekki** and **Yaba**. Each branch offers general and specialist consultations, an in-house pharmacy and a laboratory.

Patients can register at any branch and be seen at any other. A patient registered at Yaba may see a cardiologist at Ikeja and collect medication at Lekki, so all three branches depend on one shared database to keep records, appointments, prescriptions, results and bills consistent. All data in this repository is synthetic and does not describe real patients.

## 3. System Users

| User | What they do in the database |
|---|---|
| Receptionist | Registers patients; books, reschedules and cancels appointments |
| Doctor | Records consultations and diagnoses, issues prescriptions, orders lab tests |
| Laboratory scientist | Records lab results against each order |
| Pharmacist | Dispenses prescribed medication and manages branch stock |
| Billing officer | Creates bills and records full or part payments |
| Administrator | Manages branches, departments, staff and doctor records |

## 4. Major Data to Be Stored

- Branches, departments and which departments each branch runs
- Staff, with doctors as a specialised type of staff member (department, specialisation, licence number)
- Patients, identified by a unique medical record number (MRN)
- Appointments, with the doctor, branch, time slot and status
- Consultations and their ICD-10 diagnoses
- Prescriptions, prescribed items and dispensing records
- Medications, and pharmacy stock held at each branch
- Lab test types, lab orders and lab results
- Bills, bill items and payments

## 5. Key Database Operations

1. Booking an appointment without letting a doctor be double-booked
2. Recording a consultation with one primary and any number of secondary diagnoses
3. Issuing a prescription and dispensing it, with branch stock reduced in the same transaction
4. Ordering lab tests and recording their results
5. Generating a bill and recording full or part payments without overpayment
6. Retrieving a patient's complete history across all three branches
7. Producing management reports such as monthly revenue per branch and common diagnoses per department

## 6. Technologies

| Technology | Used for |
|---|---|
| PostgreSQL 16 | Main relational database (Portfolios 1, 2, 3 and 5) |
| `psql` and `pgbench` | Running scripts, two-session concurrency demos, load testing |
| dbdiagram.io (DBML) | ER diagram |
| MongoDB 7.0 (`mongod`, `mongos`, `mongosh`, `mongoimport`) | Document model (Portfolio 4) and sharded cluster (Portfolio 5) |
| Bash | Automating multi-step runs (import, replication, sharding) |
| Git and GitHub | Version control and evidence of progress |

## 7. Portfolio Structure

| # | Activity | What it covers | Main files |
|---|---|---|---|
| 1 | [Database Design and Modelling](portfolio-1-database-design/Oyediran_Taiwo_301921478_P1_README.md) | ER model, 21 tables, keys, constraints, normalisation to BCNF, 25 constraint tests | [ER diagram](portfolio-1-database-design/diagrams/Oyediran_Taiwo_301921478_P1_carebridge-erd.png), [schema](portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_01_schema.sql), [seed data](portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_02_seed_data.sql), [constraint tests](portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_03_constraint_tests.sql) |
| 2 | [Query Processing and Optimisation](portfolio-2-query-optimisation/Oyediran_Taiwo_301921478_P2_README.md) | 9 workload queries, execution plans, 6 indexes, query rewrites, before/after benchmark | [queries](portfolio-2-query-optimisation/sql/Oyediran_Taiwo_301921478_P2_01_queries.sql), [indexes](portfolio-2-query-optimisation/sql/Oyediran_Taiwo_301921478_P2_03_create_indexes.sql), [benchmark](portfolio-2-query-optimisation/sql/Oyediran_Taiwo_301921478_P2_04_benchmark.sql), [plans before](portfolio-2-query-optimisation/execution-plans/Oyediran_Taiwo_301921478_P2_before-indexes.txt) / [after](portfolio-2-query-optimisation/execution-plans/Oyediran_Taiwo_301921478_P2_after-indexes.txt) |
| 3 | [Transactions and Concurrency](portfolio-3-transactions-concurrency/Oyediran_Taiwo_301921478_P3_README.md) | COMMIT, ROLLBACK, SAVEPOINT, lost update, double booking, isolation levels, deadlock, pgbench load test | [commit/rollback](portfolio-3-transactions-concurrency/sql/Oyediran_Taiwo_301921478_P3_01_commit_rollback.sql), [lost update](portfolio-3-transactions-concurrency/sql/Oyediran_Taiwo_301921478_P3_02_lost_update.sql), [isolation](portfolio-3-transactions-concurrency/sql/Oyediran_Taiwo_301921478_P3_04_overpayment_isolation.sql), [stress test](portfolio-3-transactions-concurrency/sql/Oyediran_Taiwo_301921478_P3_06_stress_test.sh) |
| 4 | [NoSQL and Advanced Data Models](portfolio-4-nosql/Oyediran_Taiwo_301921478_P4_README.md) | MongoDB document model, migration from PostgreSQL, schema validation, queries and indexes, atomic updates | [export](portfolio-4-nosql/scripts/Oyediran_Taiwo_301921478_P4_01_export_from_postgres.sql), [validation](portfolio-4-nosql/scripts/Oyediran_Taiwo_301921478_P4_04_schema_validation.js), [queries](portfolio-4-nosql/scripts/Oyediran_Taiwo_301921478_P4_05_queries.js), [updates](portfolio-4-nosql/scripts/Oyediran_Taiwo_301921478_P4_07_updates.js) |
| 5 | [Distributed and Cloud Database Exercise](portfolio-5-distributed-cloud/Oyediran_Taiwo_301921478_P5_README.md) | Streaming replication, stale reads, synchronous commit, failover, sharding by branch, CAP choices, cloud design | [replication scripts](portfolio-5-distributed-cloud/scripts/replication/), [sharding scripts](portfolio-5-distributed-cloud/scripts/sharding/) |

Each portfolio folder has its own README with the design decisions, results, analysis and a **How to Run** section, plus a `screenshots/` folder with the output of every script.

### Repository layout

```text
Oyediran_Taiwo_301921478/
├── Oyediran_Taiwo_301921478_README.md      (this file)
├── Oyediran_Taiwo_Documentation.md         (source of the 3-page documentation PDF)
├── Oyediran_Taiwo_Documentation.pdf
├── portfolio-1-database-design/            diagrams/  sql/  screenshots/
├── portfolio-2-query-optimisation/         sql/  execution-plans/  screenshots/
├── portfolio-3-transactions-concurrency/   sql/  sql/pgbench/  screenshots/
├── portfolio-4-nosql/                      scripts/  screenshots/  (data/ is generated)
└── portfolio-5-distributed-cloud/          scripts/replication/  scripts/sharding/  screenshots/
```

## 8. Key Results at a Glance

| Portfolio | Result |
|---|---|
| 1 | 21 tables and 7 enum types; all 25 valid and invalid constraint tests behaved as expected |
| 2 | Targeted indexes made lookups 56–174× faster; rewriting the outstanding-bills query cut it from 41.5 ms to 0.047 ms |
| 3 | Under 10 concurrent clients, read-then-write lost 1,748 of 2,000 stock updates; a single atomic `UPDATE` lost none and was fastest (18,286 tps) |
| 4 | Every row count and the ₦1,034,296,105 total billed matched after migrating to MongoDB; one patient's history became a single read |
| 5 | Synchronous commit doubled commit latency (0.040 → 0.086 ms); 67% of visits happen away from the patient's home branch, so branch sharding was not recommended |

## 9. Getting Started

**Requirements:** PostgreSQL 16 (with `psql` and `pgbench`) and MongoDB 7.0 with `mongosh` and the database tools, on macOS or Linux.

```bash
createdb carebridge
psql -d carebridge -f portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_01_schema.sql
psql -d carebridge -f portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_02_seed_data.sql
psql -d carebridge -f portfolio-1-database-design/sql/Oyediran_Taiwo_301921478_P1_03_constraint_tests.sql
```

Then follow the **How to Run** section of each portfolio README in order, from 1 to 5. The seed script uses a fixed random seed, so it produces the same data and row counts every time. Portfolio 5 keeps its replica and cluster data in `~/carebridge-p5`, outside the repository.

## 10. File Naming

All files follow the `Surname_Firstname_StudentID_P<n>_<name>` convention required for the submission (renamed on 15 November 2026). Screenshots taken before the rename show the original file names, for example `01_schema.sql` for `Oyediran_Taiwo_301921478_P1_01_schema.sql`.

## 11. Project Objectives

1. Design a normalised relational database that enforces CareBridge's business rules in the schema itself.
2. Measure query performance with execution plans and improve it with evidence, not guesswork.
3. Show how transactions, isolation levels and locking keep shared data correct under concurrent use.
4. Compare a document model with the relational model on the same data and the same queries.
5. Evaluate replication, sharding and CAP trade-offs, and recommend a realistic deployment for a clinic of this size.

## 12. Academic Integrity

This portfolio is my own individual work. All scripts were run on my own machine, and every screenshot and number in the repository comes from those runs. The commit history shows how the work progressed.

An AI assistant (Claude) was used to review my ER diagram and scripts and to produce first drafts of the portfolio READMEs, which I checked against my results and rewrote. The full AI use declaration is in section 4 of [the documentation](Oyediran_Taiwo_Documentation.md).

## 13. Author

**Oyediran Taiwo**, Student ID 301921478
MIT 8103 Advanced Database Systems, MIVA Open University
GitHub: [Techtees](https://github.com/Techtees)
