-- CareBridge Portfolio 2: execution plans
-- Run before and after 03_create_indexes.sql and save the output:
--   psql -d carebridge -f 02_explain_plans.sql > ../execution-plans/before-indexes.txt
--   psql -d carebridge -f 02_explain_plans.sql > ../execution-plans/after-indexes.txt

SET search_path TO carebridge;

\echo 'Q1  Receptionist searches for a patient by name'
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, mrn, first_name, last_name, dob, phone
FROM patients
WHERE lower(last_name) = 'okafor'
  AND lower(first_name) = 'chinedu';

\echo 'Q2  Dr Hadiza Abubakar''s appointment list for 9 March 2026'
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.appointment_id, a.start_time, a.status, p.mrn, p.first_name, p.last_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.doctor_id = 9
  AND a.start_time >= '2026-03-09 00:00+01'
  AND a.start_time <  '2026-03-10 00:00+01'
ORDER BY a.start_time;

\echo 'Q3a Oldest 20 outstanding bills at Lekki (using the v_bill_balance view)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.bill_id, b.created_at, v.total_amount, v.balance
FROM bills b
JOIN v_bill_balance v ON v.bill_id = b.bill_id
WHERE b.branch_id = 2
  AND b.status IN ('unpaid', 'part_paid')
ORDER BY b.created_at
LIMIT 20;

\echo 'Q3b Same result, rewritten so totals are only computed for the bills needed'
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.bill_id, b.created_at, t.total AS total_amount, t.total - COALESCE(pd.paid, 0) AS balance
FROM bills b
CROSS JOIN LATERAL (SELECT COALESCE(sum(i.quantity * i.unit_price), 0) AS total
                    FROM bill_items i WHERE i.bill_id = b.bill_id) t
CROSS JOIN LATERAL (SELECT sum(p.amount) AS paid
                    FROM payments p WHERE p.bill_id = b.bill_id) pd
WHERE b.branch_id = 2
  AND b.status IN ('unpaid', 'part_paid')
ORDER BY b.created_at
LIMIT 20;

\echo 'Q4a Revenue per branch for March 2026 (date_trunc on the column)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT br.name AS branch, sum(p.amount) AS revenue, count(*) AS payments
FROM payments p
JOIN bills b     ON b.bill_id = p.bill_id
JOIN branches br ON br.branch_id = b.branch_id
WHERE date_trunc('month', p.paid_at AT TIME ZONE 'Africa/Lagos') = '2026-03-01'
GROUP BY br.name
ORDER BY revenue DESC;

\echo 'Q4b Same report, rewritten as a date range'
EXPLAIN (ANALYZE, BUFFERS)
SELECT br.name AS branch, sum(p.amount) AS revenue, count(*) AS payments
FROM payments p
JOIN bills b     ON b.bill_id = p.bill_id
JOIN branches br ON br.branch_id = b.branch_id
WHERE p.paid_at >= '2026-03-01 00:00+01'
  AND p.paid_at <  '2026-04-01 00:00+01'
GROUP BY br.name
ORDER BY revenue DESC;

\echo 'Q5  Lab worklist: oldest 20 orders still waiting for a result'
EXPLAIN (ANALYZE, BUFFERS)
SELECT lo.lab_order_id, lo.ordered_at, t.name AS test, lo.status
FROM lab_orders lo
JOIN lab_tests t ON t.test_id = lo.test_id
WHERE lo.status IN ('ordered', 'sample_collected')
ORDER BY lo.ordered_at
LIMIT 20;

\echo 'Q6  Most common diagnoses per department, May-October 2026'
EXPLAIN (ANALYZE, BUFFERS)
SELECT dp.name AS department, pd.icd10_code, dc.description, count(*) AS cases
FROM patient_diagnoses pd
JOIN diagnosis_codes dc ON dc.icd10_code = pd.icd10_code
JOIN consultations c    ON c.consultation_id = pd.consultation_id
JOIN appointments a     ON a.appointment_id = c.appointment_id
JOIN doctors d          ON d.doctor_id = a.doctor_id
JOIN departments dp     ON dp.department_id = d.department_id
WHERE c.created_at >= '2026-05-01 00:00+01'
  AND c.created_at <  '2026-11-01 00:00+01'
GROUP BY dp.name, pd.icd10_code, dc.description
ORDER BY dp.name, cases DESC;

\echo 'Q7  Full visit history for patient CB-000123'
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.start_time, br.name AS branch, s.full_name AS doctor, pd.icd10_code, pd.is_primary
FROM patients p
JOIN appointments a   ON a.patient_id = p.patient_id
JOIN consultations c  ON c.appointment_id = a.appointment_id
JOIN staff s          ON s.staff_id = a.doctor_id
JOIN branches br      ON br.branch_id = a.branch_id
LEFT JOIN patient_diagnoses pd ON pd.consultation_id = c.consultation_id
WHERE p.mrn = 'CB-000123'
ORDER BY a.start_time;
