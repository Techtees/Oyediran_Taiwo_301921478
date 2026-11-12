# MIT 8103 Advanced Database Systems Portfolio – CareBridge Clinics

## Selected Case Study

**Organisation:** CareBridge Clinics, a simulated private healthcare provider operating three outpatient clinics in Lagos, Nigeria, at Ikeja, Lekki and Yaba.

**Nature of the business/system:** CareBridge provides general and specialist outpatient consultations, an in-house pharmacy, and laboratory testing at each branch. Patients can register at any branch and be seen at any other, so the clinics rely on a shared database to keep patient records, appointments, prescriptions, lab results and billing consistent across all locations. All data used in this portfolio is synthetic and does not represent real patients.

**Users of the database:**
- Receptionists register patients and book, reschedule or cancel appointments.
- Doctors record consultations and diagnoses, issue prescriptions and order lab tests.
- Laboratory scientists record test results.
- Pharmacists dispense prescribed medication and manage branch stock.
- Billing officers generate bills and record payments.
- Administrators manage branches, departments and doctor records.

**Major data to be stored:** Branches, departments, doctors, patients, appointments, consultations, diagnoses, prescriptions and prescribed items, medications and pharmacy stock per branch, lab test types, lab orders and results, bills and payments.

**Key operations the database will support:**
- Booking an appointment while preventing a doctor from being double-booked
- Recording a consultation and storing diagnoses
- Issuing prescriptions and dispensing medication, with stock updated accordingly
- Ordering lab tests and recording their results
- Generating bills and recording full or part payments
- Retrieving a patient's complete medical history across all branches

## Portfolio Activities
1. Database Design and Modelling
2. Query Processing and Optimisation
3. Transactions and Concurrency
4. NoSQL and Advanced Data Models
5. Distributed and Cloud Database Exercise