-- CareBridge Portfolio 4: export PostgreSQL data as MongoDB documents (one JSON document per line)
-- Run by Oyediran_Taiwo_301921478_P4_02_import.sh

\set ON_ERROR_STOP on
SET search_path TO carebridge;

CREATE FUNCTION pg_temp.d(ts timestamptz) RETURNS json LANGUAGE sql IMMUTABLE AS
$$ SELECT CASE WHEN ts IS NULL THEN NULL
       ELSE json_build_object('$date', to_char(ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')) END $$;

CREATE FUNCTION pg_temp.day(dt date) RETURNS json LANGUAGE sql IMMUTABLE AS
$$ SELECT json_build_object('$date', to_char(dt, 'YYYY-MM-DD') || 'T00:00:00Z') $$;

CREATE FUNCTION pg_temp.money(n numeric) RETURNS json LANGUAGE sql IMMUTABLE AS
$$ SELECT json_build_object('$numberDecimal', COALESCE(n, 0)::text) $$;

\pset tuples_only on
\pset format unaligned
\pset footer off

\o ../data/patients.json
WITH
diag AS (
    SELECT pd.consultation_id,
           json_agg(json_build_object('code', pd.icd10_code, 'description', dc.description, 'primary', pd.is_primary)
                     ORDER BY pd.is_primary DESC, pd.icd10_code) AS diagnoses
    FROM patient_diagnoses pd JOIN diagnosis_codes dc USING (icd10_code)
    GROUP BY pd.consultation_id
),
disp AS (
    SELECT prescription_id, medication_id, sum(quantity) AS dispensed
    FROM dispensations GROUP BY prescription_id, medication_id
),
presc AS (
    SELECT p.consultation_id,
           json_agg(json_build_object(
               'issued_at', pg_temp.d(p.issued_at),
               'status',    p.status,
               'items',     (SELECT json_agg(json_strip_nulls(json_build_object(
                                 'medication', m.name, 'form', m.form, 'strength', m.strength,
                                 'dosage', pi.dosage, 'frequency', pi.frequency,
                                 'duration_days', pi.duration_days, 'quantity', pi.quantity,
                                 'dispensed', COALESCE(ds.dispensed, 0))) ORDER BY m.name)
                             FROM prescription_items pi
                             JOIN medications m USING (medication_id)
                             LEFT JOIN disp ds ON ds.prescription_id = pi.prescription_id
                                              AND ds.medication_id = pi.medication_id
                             WHERE pi.prescription_id = p.prescription_id))
               ORDER BY p.issued_at) AS prescriptions
    FROM prescriptions p
    GROUP BY p.consultation_id
),
lab AS (
    SELECT lo.consultation_id,
           json_agg(json_strip_nulls(json_build_object(
               'test',       t.name,
               'category',   t.category,
               'status',     lo.status,
               'ordered_at', pg_temp.d(lo.ordered_at),
               'result',     CASE WHEN r.result_id IS NOT NULL THEN json_strip_nulls(json_build_object(
                                 'value', CASE WHEN r.value ~ '^-?[0-9]+(\.[0-9]+)?$'
                                               THEN to_json(r.value::numeric) ELSE to_json(r.value) END,
                                 'unit', t.unit,
                                 'reference_range', t.reference_range,
                                 'abnormal', r.is_abnormal,
                                 'summary', r.summary,
                                 'resulted_at', pg_temp.d(r.resulted_at))) END))
               ORDER BY lo.ordered_at) AS lab_tests
    FROM lab_orders lo
    JOIN lab_tests t USING (test_id)
    LEFT JOIN lab_results r USING (lab_order_id)
    GROUP BY lo.consultation_id
),
bill AS (
    SELECT b.consultation_id,
           json_build_object(
               'bill_id', b.bill_id,
               'status',  b.status,
               'total',   pg_temp.money(v.total_amount),
               'paid',    pg_temp.money(v.amount_paid),
               'balance', pg_temp.money(v.balance),
               'created_at', pg_temp.d(b.created_at),
               'items',   (SELECT json_agg(json_build_object('type', i.item_type, 'description', i.description,
                                                               'quantity', i.quantity, 'unit_price', pg_temp.money(i.unit_price))
                                            ORDER BY i.bill_item_id)
                           FROM bill_items i WHERE i.bill_id = b.bill_id),
               'payments', COALESCE((SELECT json_agg(json_build_object('amount', pg_temp.money(pm.amount), 'method', pm.method,
                                                                          'paid_at', pg_temp.d(pm.paid_at))
                                                      ORDER BY pm.paid_at)
                                     FROM payments pm WHERE pm.bill_id = b.bill_id), '[]'::json)
           ) AS bill
    FROM bills b JOIN v_bill_balance v USING (bill_id)
),
visit AS (
    SELECT a.patient_id,
           json_agg(json_strip_nulls(json_build_object(
               'appointment_id', a.appointment_id,
               'start',  pg_temp.d(a.start_time),
               'status', a.status,
               'branch', br.name,
               'doctor', json_build_object('id', a.doctor_id, 'name', s.full_name, 'department', dp.name),
               'reason', a.reason,
               'consultation', CASE WHEN c.consultation_id IS NOT NULL THEN json_strip_nulls(json_build_object(
                                   'notes', c.notes,
                                   'diagnoses', diag.diagnoses,
                                   'prescriptions', presc.prescriptions,
                                   'lab_tests', lab.lab_tests)) END,
               'bill', bill.bill))
               ORDER BY a.start_time) AS visits
    FROM appointments a
    JOIN branches br    ON br.branch_id = a.branch_id
    JOIN staff s        ON s.staff_id = a.doctor_id
    JOIN doctors doc    ON doc.doctor_id = a.doctor_id
    JOIN departments dp ON dp.department_id = doc.department_id
    LEFT JOIN consultations c ON c.appointment_id = a.appointment_id
    LEFT JOIN diag  ON diag.consultation_id  = c.consultation_id
    LEFT JOIN presc ON presc.consultation_id = c.consultation_id
    LEFT JOIN lab   ON lab.consultation_id   = c.consultation_id
    LEFT JOIN bill  ON bill.consultation_id  = c.consultation_id
    GROUP BY a.patient_id
)
SELECT json_strip_nulls(json_build_object(
           '_id',           p.patient_id,
           'mrn',           p.mrn,
           'first_name',    p.first_name,
           'last_name',     p.last_name,
           'dob',           pg_temp.day(p.dob),
           'gender',        p.gender,
           'phone',         p.phone,
           'email',         p.email,
           'blood_group',   p.blood_group,
           'home_branch',   hb.name,
           'registered_at', pg_temp.d(p.created_at),
           'visits',        COALESCE(v.visits, '[]'::json)))
FROM patients p
JOIN branches hb ON hb.branch_id = p.home_branch_id
LEFT JOIN visit v ON v.patient_id = p.patient_id
ORDER BY p.patient_id;

\o ../data/doctor_days.json
SELECT json_build_object(
           'doctor', json_build_object('id', a.doctor_id, 'name', s.full_name, 'department', dp.name),
           'date',   to_char(a.start_time AT TIME ZONE 'Africa/Lagos', 'YYYY-MM-DD'),
           'slots',  json_agg(json_build_object(
                         'start',  pg_temp.d(a.start_time),
                         'end',    pg_temp.d(a.end_time),
                         'branch', br.name,
                         'status', a.status,
                         'patient', json_build_object('id', p.patient_id, 'mrn', p.mrn,
                                                       'name', p.first_name || ' ' || p.last_name))
                     ORDER BY a.start_time))
FROM appointments a
JOIN staff s        ON s.staff_id = a.doctor_id
JOIN doctors doc    ON doc.doctor_id = a.doctor_id
JOIN departments dp ON dp.department_id = doc.department_id
JOIN branches br    ON br.branch_id = a.branch_id
JOIN patients p     ON p.patient_id = a.patient_id
GROUP BY a.doctor_id, s.full_name, dp.name, to_char(a.start_time AT TIME ZONE 'Africa/Lagos', 'YYYY-MM-DD')
ORDER BY a.doctor_id, to_char(a.start_time AT TIME ZONE 'Africa/Lagos', 'YYYY-MM-DD');
\o
