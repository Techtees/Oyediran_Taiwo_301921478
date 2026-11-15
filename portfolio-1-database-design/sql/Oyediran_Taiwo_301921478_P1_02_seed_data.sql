-- CareBridge Clinics synthetic data (no real patients)
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P1_02_seed_data.sql   (run after Oyediran_Taiwo_301921478_P1_01_schema.sql)

SET search_path TO carebridge;
SET max_parallel_workers_per_gather = 0;
SELECT setseed(0.42);

TRUNCATE branches, departments, diagnosis_codes, medications, lab_tests, staff, patients
    RESTART IDENTITY CASCADE;

-- reference data

INSERT INTO branches (name, city, address) VALUES
    ('CareBridge Ikeja', 'Lagos', '12 Obafemi Awolowo Way, Ikeja'),
    ('CareBridge Lekki', 'Lagos', '5 Admiralty Way, Lekki Phase 1'),
    ('CareBridge Yaba',  'Lagos', '30 Herbert Macaulay Way, Yaba');

INSERT INTO departments (name) VALUES
    ('General Medicine'), ('Paediatrics'), ('Obstetrics and Gynaecology'),
    ('Cardiology'), ('Dermatology'), ('Ophthalmology');

INSERT INTO branch_departments (branch_id, department_id) VALUES
    (1,1),(2,1),(3,1),
    (1,2),(2,2),(3,2),
    (1,3),(2,3),(3,3),
    (1,4),(2,4),
    (2,5),(3,5),
    (1,6),(3,6);

INSERT INTO diagnosis_codes (icd10_code, description) VALUES
    ('B54',   'Unspecified malaria'),
    ('I10',   'Essential (primary) hypertension'),
    ('E11.9', 'Type 2 diabetes mellitus without complications'),
    ('J06.9', 'Acute upper respiratory infection, unspecified'),
    ('A01.0', 'Typhoid fever'),
    ('K29.7', 'Gastritis, unspecified'),
    ('N39.0', 'Urinary tract infection, site not specified'),
    ('M54.5', 'Low back pain'),
    ('R51',   'Headache'),
    ('D64.9', 'Anaemia, unspecified'),
    ('A09',   'Infectious gastroenteritis and colitis, unspecified'),
    ('Z00.0', 'General adult medical examination'),
    ('J18.9', 'Pneumonia, unspecified organism'),
    ('J45.9', 'Asthma, unspecified'),
    ('L30.9', 'Dermatitis, unspecified'),
    ('Z34.9', 'Supervision of normal pregnancy, unspecified'),
    ('O21.0', 'Mild hyperemesis gravidarum'),
    ('N94.6', 'Dysmenorrhoea, unspecified'),
    ('I50.9', 'Heart failure, unspecified'),
    ('E66.9', 'Obesity, unspecified'),
    ('I25.1', 'Atherosclerotic heart disease'),
    ('L70.0', 'Acne vulgaris'),
    ('B35.4', 'Tinea corporis'),
    ('H10.9', 'Conjunctivitis, unspecified'),
    ('H52.4', 'Presbyopia'),
    ('H40.9', 'Glaucoma, unspecified'),
    ('H25.9', 'Age-related cataract, unspecified');

CREATE TEMP TABLE seed_diag_pool (department_id int, icd10_code varchar(10));
INSERT INTO seed_diag_pool VALUES
    (1,'B54'),(1,'I10'),(1,'E11.9'),(1,'J06.9'),(1,'A01.0'),(1,'K29.7'),(1,'N39.0'),
    (1,'M54.5'),(1,'R51'),(1,'D64.9'),(1,'A09'),(1,'Z00.0'),
    (2,'B54'),(2,'J06.9'),(2,'A09'),(2,'J18.9'),(2,'D64.9'),(2,'J45.9'),(2,'L30.9'),
    (3,'Z34.9'),(3,'N39.0'),(3,'D64.9'),(3,'O21.0'),(3,'N94.6'),
    (4,'I10'),(4,'I50.9'),(4,'E66.9'),(4,'I25.1'),
    (5,'L30.9'),(5,'L70.0'),(5,'B35.4'),
    (6,'H10.9'),(6,'H52.4'),(6,'H40.9'),(6,'H25.9');

INSERT INTO medications (name, form, strength, unit_price) VALUES
    ('Artemether/Lumefantrine', 'tablet',  '20/120mg', 250.00),
    ('Paracetamol',             'tablet',  '500mg',     20.00),
    ('Amoxicillin',             'capsule', '500mg',     80.00),
    ('Amlodipine',              'tablet',  '5mg',       60.00),
    ('Lisinopril',              'tablet',  '10mg',      90.00),
    ('Metformin',               'tablet',  '500mg',     45.00),
    ('Ciprofloxacin',           'tablet',  '500mg',    120.00),
    ('Omeprazole',              'capsule', '20mg',      70.00),
    ('Ibuprofen',               'tablet',  '400mg',     30.00),
    ('Ferrous sulphate',        'tablet',  '200mg',     15.00),
    ('Folic acid',              'tablet',  '5mg',       10.00),
    ('Oral rehydration salts',  'sachet',  '20.5g',    150.00),
    ('Salbutamol',              'inhaler', '100mcg',  2500.00),
    ('Cetirizine',              'tablet',  '10mg',      40.00),
    ('Hydrocortisone',          'cream',   '1%',      1200.00),
    ('Clotrimazole',            'cream',   '1%',       900.00),
    ('Chloramphenicol',         'eye drops','0.5%',    800.00),
    ('Timolol',                 'eye drops','0.5%',   2200.00),
    ('Atorvastatin',            'tablet',  '20mg',     110.00),
    ('Furosemide',              'tablet',  '40mg',      35.00),
    ('Metronidazole',           'tablet',  '400mg',     40.00),
    ('Amoxicillin',             'syrup',   '125mg/5ml', 1500.00),
    ('Paracetamol',             'syrup',   '120mg/5ml', 800.00),
    ('Doxycycline',             'capsule', '100mg',     70.00),
    ('Vitamin B complex',       'tablet',  'standard',  10.00);

INSERT INTO lab_tests (name, category, unit, reference_range, price) VALUES
    ('Full blood count',            'Haematology',   'g/dL',   '12.0-17.5',   6000.00),
    ('Malaria parasite (MP)',       'Parasitology',  NULL,     'Negative',    2500.00),
    ('Widal test',                  'Serology',      NULL,     '< 1:80',      3000.00),
    ('Fasting blood sugar',         'Chemistry',     'mmol/L', '3.9-5.5',     2500.00),
    ('HbA1c',                       'Chemistry',     '%',      '< 5.7',       9000.00),
    ('Lipid profile',               'Chemistry',     'mmol/L', 'TC < 5.2',   12000.00),
    ('Urinalysis',                  'Urology',       NULL,     'Normal',      2000.00),
    ('Urine microscopy and culture','Microbiology',  NULL,     'No growth',   7000.00),
    ('Liver function test',         'Chemistry',     'U/L',    'ALT 7-56',   10000.00),
    ('Electrolytes, urea, creatinine','Chemistry',   'mmol/L', 'Na 135-145',  9000.00),
    ('Pregnancy test',              'Serology',      NULL,     'Negative',    2000.00),
    ('HIV screening',               'Serology',      NULL,     'Non-reactive',3000.00),
    ('Hepatitis B surface antigen', 'Serology',      NULL,     'Negative',    3000.00),
    ('Haemoglobin genotype',        'Haematology',   NULL,     'AA/AS/SS',    3500.00),
    ('Thyroid function test',       'Chemistry',     'mIU/L',  'TSH 0.4-4.0',15000.00);

-- staff

CREATE TEMP TABLE seed_doctors (n int, full_name text, branch_id int, department_id int, specialisation text);
INSERT INTO seed_doctors VALUES
    ( 1,'Dr Adebayo Ogunleye',  1,1,'Family Medicine'),
    ( 2,'Dr Ngozi Eze',         2,1,'Family Medicine'),
    ( 3,'Dr Ibrahim Bello',     3,1,'Internal Medicine'),
    ( 4,'Dr Folake Adeyemi',    1,1,'Internal Medicine'),
    ( 5,'Dr Chukwudi Nwosu',    2,1,'Family Medicine'),
    ( 6,'Dr Amina Yusuf',       3,1,'Family Medicine'),
    ( 7,'Dr Oluwakemi Bakare',  1,2,'Paediatrics'),
    ( 8,'Dr Emeka Okafor',      2,2,'Paediatrics'),
    ( 9,'Dr Hadiza Abubakar',   3,2,'Paediatrics'),
    (10,'Dr Tolulope Ajayi',    1,2,'Neonatology'),
    (11,'Dr Chioma Obi',        2,3,'Obstetrics and Gynaecology'),
    (12,'Dr Olusegun Fashola',  3,3,'Obstetrics and Gynaecology'),
    (13,'Dr Rukayat Lawal',     1,3,'Obstetrics and Gynaecology'),
    (14,'Dr Kunle Adebisi',     1,4,'Cardiology'),
    (15,'Dr Ifeyinwa Okeke',    2,4,'Cardiology'),
    (16,'Dr Bolaji Ogundipe',   2,5,'Dermatology'),
    (17,'Dr Nneka Uzoma',       3,5,'Dermatology'),
    (18,'Dr Musa Danjuma',      1,6,'Ophthalmology'),
    (19,'Dr Yewande Coker',     3,6,'Ophthalmology'),
    (20,'Dr Obiora Mbah',       1,6,'Ophthalmology');

INSERT INTO staff (branch_id, full_name, role, email, phone)
SELECT branch_id, full_name, 'doctor',
       'doctor' || n || '@carebridge.example',
       '0803' || lpad((1000000 + n * 7919)::text, 7, '0')
FROM seed_doctors ORDER BY n;

INSERT INTO doctors (doctor_id, department_id, specialisation, licence_no)
SELECT s.staff_id, sd.department_id, sd.specialisation, 'MDCN/' || (40000 + sd.n * 137)
FROM seed_doctors sd JOIN staff s ON s.full_name = sd.full_name;

WITH roles (role, per_branch) AS (
    VALUES ('receptionist'::staff_role, 2), ('pharmacist', 2), ('lab_scientist', 2),
           ('billing_officer', 1), ('admin', 1)
),
names AS (
    SELECT ARRAY['Bisi','Kelechi','Halima','Segun','Amaka','Yusuf','Funke','Ikenna',
                 'Zainab','Femi','Chiamaka','Tunde','Hauwa','Uche','Bukola','Sani'] AS f,
           ARRAY['Adewale','Okoro','Garba','Balogun','Nnaji','Suleiman','Oladipo','Ekwueme',
                 'Ibekwe','Olatunji','Usman','Akande'] AS l
),
rows AS (
    SELECT b.branch_id, r.role, row_number() OVER () AS i
    FROM branches b CROSS JOIN roles r CROSS JOIN generate_series(1, r.per_branch)
)
INSERT INTO staff (branch_id, full_name, role, email, phone)
SELECT rows.branch_id,
       names.f[1 + (i * 7) % 16] || ' ' || names.l[1 + (i * 5) % 12],
       rows.role,
       replace(rows.role::text, '_', '.') || i || '@carebridge.example',
       '0805' || lpad((2000000 + i * 3571)::text, 7, '0')
FROM rows, names ORDER BY i;

-- patients

INSERT INTO patients (mrn, first_name, last_name, dob, gender, phone, email, blood_group, home_branch_id, created_at)
SELECT 'CB-' || lpad(g::text, 6, '0'),
       CASE WHEN p.male THEN m.names[1 + floor(p.r1 * 20)::int] ELSE fe.names[1 + floor(p.r1 * 20)::int] END,
       ln.names[1 + floor(p.r2 * 30)::int],
       date '1945-01-01' + floor(p.r3 * (date '2025-12-31' - date '1945-01-01'))::int,
       CASE WHEN p.male THEN 'male' ELSE 'female' END,
       (ARRAY['0803','0806','0813','0816','0703','0805','0807','0815','0811','0905'])[1 + floor(p.r4 * 10)::int]
           || lpad(floor(p.r5 * 10000000)::int::text, 7, '0'),
       CASE WHEN p.r6 < 0.5 THEN 'patient' || g || '@mail.example' END,
       CASE WHEN p.r7 < 0.15 THEN NULL
            ELSE (ARRAY['O+','O+','O+','O+','O+','A+','A+','B+','B+','AB+','O-','A-','B-','AB-'])[1 + floor(p.r8 * 14)::int] END,
       1 + floor(p.r9 * 3)::int,
       timestamptz '2024-01-01 08:00+01' + (p.r3 * 700) * interval '1 day'
FROM generate_series(1, 5000) g
CROSS JOIN LATERAL (
    SELECT random() < 0.47 AS male, random() r1, random() r2, random() r3, random() r4,
           random() r5, random() r6, random() r7, random() r8, random() r9, g AS dummy
) p
CROSS JOIN (SELECT ARRAY['Chinedu','Oluwaseun','Emeka','Ibrahim','Tunde','Obinna','Segun','Musa',
                         'Kelechi','Babatunde','Uche','Olumide','Chukwuemeka','Kehinde','Abdullahi',
                         'Ikenna','Femi','Yusuf','Ifeanyi','Taiwo'] AS names) m
CROSS JOIN (SELECT ARRAY['Adaeze','Ngozi','Funmilayo','Aisha','Yetunde','Chiamaka','Bisola','Fatima',
                         'Ifeoma','Temitope','Amaka','Zainab','Folake','Damilola','Nkechi','Hauwa',
                         'Ebere','Bukola','Halima','Toyin'] AS names) fe
CROSS JOIN (SELECT ARRAY['Okafor','Adeyemi','Bello','Eze','Ogunleye','Nwosu','Abubakar','Afolabi',
                         'Okonkwo','Adebayo','Ibrahim','Chukwu','Olawale','Mohammed','Obi','Akinola',
                         'Ezeh','Lawal','Onyeka','Salami','Nwachukwu','Ogundipe','Danjuma','Okeke',
                         'Bakare','Uzoma','Fashola','Ajayi','Mbah','Coker'] AS names) ln
ORDER BY g;

-- appointments: 30-minute slots, 08:00-16:00 on weekdays, Jan 2025 to Dec 2026.
-- A doctor works at one branch per day, rotating between branches that offer their department.
-- Anything after 2026-11-12 is still 'scheduled'.

WITH offered AS (
    SELECT department_id, array_agg(branch_id ORDER BY branch_id) AS branches
    FROM branch_departments GROUP BY department_id
),
rec AS (
    SELECT branch_id, array_agg(staff_id ORDER BY staff_id) AS ids
    FROM staff WHERE role = 'receptionist' GROUP BY branch_id
),
slots AS (
    SELECT d.doctor_id,
           o.branches[1 + ((day::date - date '2025-01-06') + d.doctor_id) % array_length(o.branches, 1)] AS branch_id,
           (day + interval '8 hours' + slot * interval '30 minutes') AT TIME ZONE 'Africa/Lagos' AS start_time,
           1 + floor(random() * 5000)::int AS patient_id,
           random() AS r,
           random() AS r2
    FROM doctors d
    JOIN offered o USING (department_id)
    CROSS JOIN generate_series(timestamp '2025-01-06', timestamp '2026-12-31', interval '1 day') AS day
    CROSS JOIN generate_series(0, 15) AS slot
    WHERE extract(isodow FROM day) < 6
      AND random() < 0.32
)
INSERT INTO appointments (patient_id, doctor_id, branch_id, booked_by, start_time, end_time, status, reason, created_at)
SELECT s.patient_id, s.doctor_id, s.branch_id,
       rec.ids[1 + s.patient_id % array_length(rec.ids, 1)],
       s.start_time,
       s.start_time + interval '30 minutes',
       (CASE
            WHEN s.start_time >= timestamptz '2026-11-12 00:00+01'
                THEN CASE WHEN s.r < 0.05 THEN 'cancelled' ELSE 'scheduled' END
            WHEN s.r < 0.10 THEN 'cancelled'
            WHEN s.r < 0.17 THEN 'no_show'
            ELSE 'completed'
        END)::appointment_status,
       (ARRAY['Fever and headache','Routine check-up','Follow-up visit','Cough and catarrh',
              'Abdominal pain','Blood pressure review','Skin rash','Blurred vision',
              'Antenatal visit','Child wellness review','Chest pain','Diabetes review'])[1 + floor(s.r2 * 12)::int],
       s.start_time - (1 + floor(s.r2 * 14)::int) * interval '1 day'
FROM slots s JOIN rec USING (branch_id)
ORDER BY s.start_time, s.doctor_id;

-- consultations and diagnoses

INSERT INTO consultations (appointment_id, notes, created_at)
SELECT appointment_id,
       (ARRAY['Patient stable. Advised rest and fluids.','Vitals within normal limits.',
              'Symptoms improving since last visit.','Referred for further investigation.',
              'Medication adherence discussed.','Lifestyle modification advised.'])[1 + floor(random() * 6)::int],
       start_time + interval '20 minutes'
FROM appointments
WHERE status = 'completed'
ORDER BY appointment_id;

WITH pool AS (
    SELECT department_id, array_agg(icd10_code ORDER BY icd10_code) AS codes
    FROM seed_diag_pool GROUP BY department_id
),
c AS (
    SELECT c.consultation_id, p.codes,
           floor(random() * array_length(p.codes, 1))::int AS i,
           random() AS r
    FROM consultations c
    JOIN appointments a ON a.appointment_id = c.appointment_id
    JOIN doctors d ON d.doctor_id = a.doctor_id
    JOIN pool p ON p.department_id = d.department_id
)
INSERT INTO patient_diagnoses (consultation_id, icd10_code, is_primary)
SELECT consultation_id, codes[1 + i], TRUE FROM c
UNION ALL
SELECT consultation_id, codes[1 + (i + 1) % array_length(codes, 1)], FALSE FROM c WHERE r < 0.25;

-- pharmacy

INSERT INTO pharmacy_stock (branch_id, medication_id, quantity, reorder_level)
SELECT b.branch_id, m.medication_id, 200 + floor(random() * 1800)::int, 100
FROM branches b CROSS JOIN medications m
ORDER BY b.branch_id, m.medication_id;

INSERT INTO prescriptions (consultation_id, issued_at)
SELECT consultation_id, created_at + interval '10 minutes'
FROM consultations
WHERE random() < 0.6
ORDER BY consultation_id;

INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration_days, quantity, instructions)
SELECT p.prescription_id,
       1 + (p.base + k * 7) % 25,
       (ARRAY['1 tablet','2 tablets','1 capsule','5 ml','10 ml','apply thinly','1 drop'])[1 + floor(random() * 7)::int],
       (ARRAY['once daily','twice daily','three times daily','at night'])[1 + floor(random() * 4)::int],
       (ARRAY[3, 5, 7, 14, 30])[1 + floor(random() * 5)::int],
       6 + floor(random() * 25)::int,
       (ARRAY['After meals','Before meals',NULL])[1 + floor(random() * 3)::int]
FROM (SELECT prescription_id,
             floor(random() * 25)::int AS base,
             1 + floor(random() * 3)::int AS n
      FROM prescriptions) p
CROSS JOIN LATERAL generate_series(0, p.n - 1) AS k
ORDER BY p.prescription_id, k;

WITH ph AS (
    SELECT branch_id, array_agg(staff_id ORDER BY staff_id) AS ids
    FROM staff WHERE role = 'pharmacist' GROUP BY branch_id
)
INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by, dispensed_at)
SELECT pi.prescription_id, pi.medication_id, a.branch_id, pi.quantity,
       ph.ids[1 + pi.prescription_id % array_length(ph.ids, 1)],
       pr.issued_at + (20 + floor(random() * 100)::int) * interval '1 minute'
FROM prescription_items pi
JOIN prescriptions pr ON pr.prescription_id = pi.prescription_id
JOIN consultations c  ON c.consultation_id = pr.consultation_id
JOIN appointments a   ON a.appointment_id = c.appointment_id
JOIN ph               ON ph.branch_id = a.branch_id
WHERE random() < 0.9
ORDER BY pr.issued_at, pi.medication_id;

UPDATE prescriptions p
SET status = (CASE WHEN x.dispensed = x.items THEN 'dispensed'
                   WHEN x.dispensed > 0       THEN 'partially_dispensed'
                   ELSE 'issued' END)::prescription_status
FROM (SELECT pi.prescription_id, count(*) AS items, count(d.dispensation_id) AS dispensed
      FROM prescription_items pi
      LEFT JOIN dispensations d
             ON d.prescription_id = pi.prescription_id AND d.medication_id = pi.medication_id
      GROUP BY pi.prescription_id) x
WHERE x.prescription_id = p.prescription_id;

-- laboratory

INSERT INTO lab_orders (consultation_id, test_id, status, ordered_at)
SELECT c.consultation_id,
       1 + (c.base + k * 4) % 15,
       (CASE
            WHEN c.created_at >= timestamptz '2026-11-09 00:00+01'
                THEN CASE WHEN random() < 0.5 THEN 'ordered' ELSE 'sample_collected' END
            WHEN random() < 0.04 THEN 'cancelled'
            ELSE 'completed'
        END)::lab_order_status,
       c.created_at + interval '15 minutes'
FROM (SELECT consultation_id, created_at,
             floor(random() * 15)::int AS base,
             1 + floor(random() * 2)::int AS n
      FROM consultations
      WHERE random() < 0.35) c
CROSS JOIN LATERAL generate_series(0, c.n - 1) AS k
ORDER BY c.consultation_id, k;

WITH ls AS (
    SELECT branch_id, array_agg(staff_id ORDER BY staff_id) AS ids
    FROM staff WHERE role = 'lab_scientist' GROUP BY branch_id
),
o AS (
    SELECT lo.lab_order_id, lo.ordered_at, a.branch_id, random() < 0.2 AS abnormal, random() AS r
    FROM lab_orders lo
    JOIN consultations c ON c.consultation_id = lo.consultation_id
    JOIN appointments a  ON a.appointment_id = c.appointment_id
    WHERE lo.status = 'completed'
)
INSERT INTO lab_results (lab_order_id, value, is_abnormal, summary, performed_by, resulted_at)
SELECT o.lab_order_id,
       round((o.r * 100)::numeric, 1)::text,
       o.abnormal,
       CASE WHEN o.abnormal THEN 'Outside reference range. Doctor to review.' ELSE 'Within normal limits.' END,
       ls.ids[1 + o.lab_order_id % array_length(ls.ids, 1)],
       o.ordered_at + (2 + floor(o.r * 46)::int) * interval '1 hour'
FROM o JOIN ls ON ls.branch_id = o.branch_id
ORDER BY o.lab_order_id;

-- billing

WITH bo AS (
    SELECT branch_id, min(staff_id) AS staff_id
    FROM staff WHERE role = 'billing_officer' GROUP BY branch_id
)
INSERT INTO bills (patient_id, branch_id, consultation_id, created_by, created_at)
SELECT a.patient_id, a.branch_id, c.consultation_id, bo.staff_id, c.created_at + interval '1 hour'
FROM consultations c
JOIN appointments a ON a.appointment_id = c.appointment_id
JOIN bo ON bo.branch_id = a.branch_id
ORDER BY c.consultation_id;

INSERT INTO bill_items (bill_id, item_type, description, quantity, unit_price)
SELECT b.bill_id, 'consultation', 'Consultation - ' || dp.name, 1,
       CASE d.department_id WHEN 4 THEN 25000 WHEN 1 THEN 10000 WHEN 2 THEN 10000 ELSE 15000 END
FROM bills b
JOIN consultations c ON c.consultation_id = b.consultation_id
JOIN appointments a  ON a.appointment_id = c.appointment_id
JOIN doctors d       ON d.doctor_id = a.doctor_id
JOIN departments dp  ON dp.department_id = d.department_id
ORDER BY b.bill_id;

INSERT INTO bill_items (bill_id, item_type, lab_order_id, description, quantity, unit_price)
SELECT b.bill_id, 'lab_test', lo.lab_order_id, t.name, 1, t.price
FROM lab_orders lo
JOIN lab_tests t ON t.test_id = lo.test_id
JOIN bills b     ON b.consultation_id = lo.consultation_id
WHERE lo.status <> 'cancelled'
ORDER BY b.bill_id, lo.lab_order_id;

INSERT INTO bill_items (bill_id, item_type, dispensation_id, description, quantity, unit_price)
SELECT b.bill_id, 'medication', ds.dispensation_id,
       m.name || ' ' || m.strength || ' ' || m.form, ds.quantity, m.unit_price
FROM dispensations ds
JOIN medications m   ON m.medication_id = ds.medication_id
JOIN prescriptions p ON p.prescription_id = ds.prescription_id
JOIN bills b         ON b.consultation_id = p.consultation_id
ORDER BY b.bill_id, ds.dispensation_id;

WITH bo AS (
    SELECT branch_id, min(staff_id) AS staff_id
    FROM staff WHERE role = 'billing_officer' GROUP BY branch_id
),
x AS (
    SELECT v.bill_id, v.total_amount, b.branch_id, b.created_at,
           random() AS r,
           (ARRAY['cash','card','transfer','transfer','hmo'])[1 + floor(random() * 5)::int]::payment_method AS method
    FROM v_bill_balance v
    JOIN bills b ON b.bill_id = v.bill_id
    WHERE v.total_amount > 0
)
INSERT INTO payments (bill_id, amount, method, reference, received_by, paid_at)
SELECT x.bill_id,
       CASE WHEN x.r < 0.80 THEN x.total_amount ELSE round(x.total_amount * 0.5, 2) END,
       x.method,
       CASE WHEN x.method <> 'cash' THEN upper(x.method::text) || '-' || lpad(x.bill_id::text, 8, '0') END,
       bo.staff_id,
       x.created_at + interval '15 minutes'
FROM x JOIN bo ON bo.branch_id = x.branch_id
WHERE x.r < 0.90
ORDER BY x.bill_id;

UPDATE bills b
SET status = (CASE WHEN v.balance <= 0     THEN 'paid'
                   WHEN v.amount_paid > 0  THEN 'part_paid'
                   ELSE 'unpaid' END)::bill_status
FROM v_bill_balance v
WHERE v.bill_id = b.bill_id;

ANALYZE;

SELECT 'branches' AS table_name, count(*) AS row_count FROM branches
UNION ALL SELECT 'departments',        count(*) FROM departments
UNION ALL SELECT 'staff',              count(*) FROM staff
UNION ALL SELECT 'doctors',            count(*) FROM doctors
UNION ALL SELECT 'patients',           count(*) FROM patients
UNION ALL SELECT 'appointments',       count(*) FROM appointments
UNION ALL SELECT 'consultations',      count(*) FROM consultations
UNION ALL SELECT 'patient_diagnoses',  count(*) FROM patient_diagnoses
UNION ALL SELECT 'prescriptions',      count(*) FROM prescriptions
UNION ALL SELECT 'prescription_items', count(*) FROM prescription_items
UNION ALL SELECT 'dispensations',      count(*) FROM dispensations
UNION ALL SELECT 'lab_orders',         count(*) FROM lab_orders
UNION ALL SELECT 'lab_results',        count(*) FROM lab_results
UNION ALL SELECT 'bills',              count(*) FROM bills
UNION ALL SELECT 'bill_items',         count(*) FROM bill_items
UNION ALL SELECT 'payments',           count(*) FROM payments;
