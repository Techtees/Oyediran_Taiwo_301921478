-- CareBridge Portfolio 2: benchmark summary
-- Runs each query 1 warm-up + 7 timed times with EXPLAIN ANALYZE and reports the median.
-- Run before and after 03_create_indexes.sql:
--   psql -d carebridge -f 04_benchmark.sql

SET search_path TO carebridge;

CREATE TEMP TABLE bench_results (
    query        text,
    main_table   text,
    access_path  text,
    median_ms    numeric
);

CREATE FUNCTION pg_temp.bench(q text, tbl text, stmt text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    plan   json;
    times  float8[] := '{}';
    access text;
BEGIN
    EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || stmt INTO plan;
    FOR i IN 1..7 LOOP
        EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || stmt INTO plan;
        times := times || (plan->0->>'Execution Time')::float8;
    END LOOP;

    SELECT string_agg(DISTINCT n->>'Node Type' || COALESCE(' (' || (n->>'Index Name') || ')', ''), ' + ')
    INTO access
    FROM jsonb_path_query((plan->0->'Plan')::jsonb, 'strict $.**') AS n
    WHERE jsonb_typeof(n) = 'object'
      AND (n->>'Relation Name' = tbl
           OR n->>'Index Name' IN (SELECT indexname FROM pg_indexes
                                   WHERE schemaname = 'carebridge' AND tablename = tbl));

    INSERT INTO bench_results
    SELECT q, tbl, access,
           round(percentile_cont(0.5) WITHIN GROUP (ORDER BY t)::numeric, 3)
    FROM unnest(times) AS t;
END;
$$;

\o /dev/null

SELECT pg_temp.bench('Q1', 'patients', $q$
SELECT patient_id, mrn, first_name, last_name, dob, phone
FROM patients
WHERE lower(last_name) = 'okafor'
  AND lower(first_name) = 'chinedu'
$q$);

SELECT pg_temp.bench('Q2', 'appointments', $q$
SELECT a.appointment_id, a.start_time, a.status, p.mrn, p.first_name, p.last_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
WHERE a.doctor_id = 9
  AND a.start_time >= '2026-03-09 00:00+01'
  AND a.start_time <  '2026-03-10 00:00+01'
ORDER BY a.start_time
$q$);

SELECT pg_temp.bench('Q3a', 'bills', $q$
SELECT b.bill_id, b.created_at, v.total_amount, v.balance
FROM bills b
JOIN v_bill_balance v ON v.bill_id = b.bill_id
WHERE b.branch_id = 2
  AND b.status IN ('unpaid', 'part_paid')
ORDER BY b.created_at
LIMIT 20
$q$);

SELECT pg_temp.bench('Q3b', 'bills', $q$
SELECT b.bill_id, b.created_at, t.total AS total_amount, t.total - COALESCE(pd.paid, 0) AS balance
FROM bills b
CROSS JOIN LATERAL (SELECT COALESCE(sum(i.quantity * i.unit_price), 0) AS total
                    FROM bill_items i WHERE i.bill_id = b.bill_id) t
CROSS JOIN LATERAL (SELECT sum(p.amount) AS paid
                    FROM payments p WHERE p.bill_id = b.bill_id) pd
WHERE b.branch_id = 2
  AND b.status IN ('unpaid', 'part_paid')
ORDER BY b.created_at
LIMIT 20
$q$);

SELECT pg_temp.bench('Q4a', 'payments', $q$
SELECT br.name AS branch, sum(p.amount) AS revenue, count(*) AS payments
FROM payments p
JOIN bills b     ON b.bill_id = p.bill_id
JOIN branches br ON br.branch_id = b.branch_id
WHERE date_trunc('month', p.paid_at AT TIME ZONE 'Africa/Lagos') = '2026-03-01'
GROUP BY br.name
ORDER BY revenue DESC
$q$);

SELECT pg_temp.bench('Q4b', 'payments', $q$
SELECT br.name AS branch, sum(p.amount) AS revenue, count(*) AS payments
FROM payments p
JOIN bills b     ON b.bill_id = p.bill_id
JOIN branches br ON br.branch_id = b.branch_id
WHERE p.paid_at >= '2026-03-01 00:00+01'
  AND p.paid_at <  '2026-04-01 00:00+01'
GROUP BY br.name
ORDER BY revenue DESC
$q$);

SELECT pg_temp.bench('Q5', 'lab_orders', $q$
SELECT lo.lab_order_id, lo.ordered_at, t.name AS test, lo.status
FROM lab_orders lo
JOIN lab_tests t ON t.test_id = lo.test_id
WHERE lo.status IN ('ordered', 'sample_collected')
ORDER BY lo.ordered_at
LIMIT 20
$q$);

SELECT pg_temp.bench('Q6', 'consultations', $q$
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
ORDER BY dp.name, cases DESC
$q$);

SELECT pg_temp.bench('Q7', 'appointments', $q$
SELECT a.start_time, br.name AS branch, s.full_name AS doctor, pd.icd10_code, pd.is_primary
FROM patients p
JOIN appointments a   ON a.patient_id = p.patient_id
JOIN consultations c  ON c.appointment_id = a.appointment_id
JOIN staff s          ON s.staff_id = a.doctor_id
JOIN branches br      ON br.branch_id = a.branch_id
LEFT JOIN patient_diagnoses pd ON pd.consultation_id = c.consultation_id
WHERE p.mrn = 'CB-000123'
ORDER BY a.start_time
$q$);

\o

SELECT query, main_table, access_path, median_ms FROM bench_results ORDER BY query;
