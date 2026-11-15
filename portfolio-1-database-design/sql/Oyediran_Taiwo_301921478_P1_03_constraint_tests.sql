-- CareBridge constraint tests
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P1_03_constraint_tests.sql   (run after 01 and 02)

BEGIN;
SET search_path TO carebridge;

CREATE TEMP TABLE test_results (
    n           serial,
    test        text,
    expected    text,
    result      text,
    enforced_by text
);

CREATE FUNCTION pg_temp.check_rule(test text, should_succeed boolean, stmt text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_constraint text;
    v_message    text;
BEGIN
    BEGIN
        EXECUTE stmt;
        INSERT INTO test_results (test, expected, result, enforced_by)
        VALUES (test,
                CASE WHEN should_succeed THEN 'accept' ELSE 'reject' END,
                CASE WHEN should_succeed THEN 'PASS' ELSE 'FAIL' END,
                '-');
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME, v_message = MESSAGE_TEXT;
        INSERT INTO test_results (test, expected, result, enforced_by)
        VALUES (test,
                CASE WHEN should_succeed THEN 'accept' ELSE 'reject' END,
                CASE WHEN should_succeed THEN 'FAIL' ELSE 'PASS' END,
                COALESCE(NULLIF(v_constraint, ''), v_message));
    END;
END;
$$;

\o /dev/null

-- appointments (doctor 1 on a free future day)
SELECT pg_temp.check_rule('Book doctor 09:00-09:30', true, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (1, 1, 1, '2027-01-04 09:00+01', '2027-01-04 09:30+01') $q$);

SELECT pg_temp.check_rule('Back-to-back booking 09:30-10:00', true, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (2, 1, 1, '2027-01-04 09:30+01', '2027-01-04 10:00+01') $q$);

SELECT pg_temp.check_rule('Double-book doctor 09:15-09:45', false, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (3, 1, 1, '2027-01-04 09:15+01', '2027-01-04 09:45+01') $q$);

SELECT pg_temp.check_rule('Cancel the 09:00 appointment', true, $q$
    UPDATE appointments SET status = 'cancelled'
    WHERE doctor_id = 1 AND start_time = '2027-01-04 09:00+01' $q$);

SELECT pg_temp.check_rule('Rebook the cancelled 09:00 slot', true, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (4, 1, 1, '2027-01-04 09:00+01', '2027-01-04 09:30+01') $q$);

SELECT pg_temp.check_rule('Appointment ends before it starts', false, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (1, 1, 1, '2027-01-05 10:00+01', '2027-01-05 09:00+01') $q$);

SELECT pg_temp.check_rule('Appointment for non-existent patient', false, $q$
    INSERT INTO appointments (patient_id, doctor_id, branch_id, start_time, end_time)
    VALUES (999999, 1, 1, '2027-01-05 11:00+01', '2027-01-05 11:30+01') $q$);

SELECT pg_temp.check_rule('Unknown appointment status', false, $q$
    UPDATE appointments SET status = 'pending' WHERE appointment_id = 1 $q$);

-- staff / doctors
SELECT pg_temp.check_rule('Register a receptionist as a doctor', false, $q$
    INSERT INTO doctors (doctor_id, department_id, licence_no)
    SELECT staff_id, 1, 'MDCN/TEST' FROM staff WHERE role = 'receptionist' LIMIT 1 $q$);

-- patients
SELECT pg_temp.check_rule('Duplicate medical record number', false, $q$
    INSERT INTO patients (mrn, first_name, last_name, dob, home_branch_id)
    VALUES ('CB-000001', 'Test', 'Patient', '1990-01-01', 1) $q$);

SELECT pg_temp.check_rule('Invalid blood group', false, $q$
    INSERT INTO patients (mrn, first_name, last_name, dob, home_branch_id, blood_group)
    VALUES ('CB-TEST-1', 'Test', 'Patient', '1990-01-01', 1, 'Z+') $q$);

SELECT pg_temp.check_rule('Date of birth in the future', false, $q$
    INSERT INTO patients (mrn, first_name, last_name, dob, home_branch_id)
    VALUES ('CB-TEST-2', 'Test', 'Patient', CURRENT_DATE + 1, 1) $q$);

SELECT pg_temp.check_rule('Delete a patient who has appointments', false, $q$
    DELETE FROM patients WHERE patient_id = 1 $q$);

-- diagnoses
SELECT pg_temp.check_rule('Same ICD-10 code twice in one consultation', false, $q$
    INSERT INTO patient_diagnoses (consultation_id, icd10_code)
    SELECT consultation_id, icd10_code FROM patient_diagnoses LIMIT 1 $q$);

SELECT pg_temp.check_rule('Second primary diagnosis in one consultation', false, $q$
    INSERT INTO patient_diagnoses (consultation_id, icd10_code, is_primary)
    SELECT pd.consultation_id, dc.icd10_code, true
    FROM patient_diagnoses pd
    CROSS JOIN LATERAL (SELECT icd10_code FROM diagnosis_codes
                        WHERE icd10_code <> pd.icd10_code LIMIT 1) dc
    WHERE pd.is_primary
    LIMIT 1 $q$);

-- pharmacy
SELECT pg_temp.check_rule('Stock goes below zero', false, $q$
    UPDATE pharmacy_stock SET quantity = quantity - 100000
    WHERE branch_id = 1 AND medication_id = 1 $q$);

SELECT pg_temp.check_rule('Prescribe quantity of zero', false, $q$
    INSERT INTO prescription_items (prescription_id, medication_id, quantity)
    SELECT 1, medication_id, 0 FROM medications
    WHERE medication_id NOT IN (SELECT medication_id FROM prescription_items WHERE prescription_id = 1)
    LIMIT 1 $q$);

SELECT pg_temp.check_rule('Add new drug with no branch stock', true, $q$
    INSERT INTO medications (name, form, strength, unit_price)
    VALUES ('Test drug', 'tablet', '1mg', 10) $q$);

SELECT pg_temp.check_rule('Prescribe the new drug', true, $q$
    INSERT INTO prescription_items (prescription_id, medication_id, quantity)
    SELECT 1, medication_id, 5 FROM medications WHERE name = 'Test drug' $q$);

SELECT pg_temp.check_rule('Dispense a drug the branch does not stock', false, $q$
    INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by)
    SELECT 1, medication_id, 1, 5, (SELECT min(staff_id) FROM staff WHERE role = 'pharmacist')
    FROM medications WHERE name = 'Test drug' $q$);

-- billing
SELECT pg_temp.check_rule('Lab-test bill item with no lab order', false, $q$
    INSERT INTO bill_items (bill_id, item_type, description, unit_price)
    VALUES (1, 'lab_test', 'Full blood count', 6000) $q$);

SELECT pg_temp.check_rule('Bill the same lab order twice', false, $q$
    INSERT INTO bill_items (bill_id, item_type, lab_order_id, description, unit_price)
    SELECT bill_id, 'lab_test', lab_order_id, description, unit_price
    FROM bill_items WHERE lab_order_id IS NOT NULL LIMIT 1 $q$);

SELECT pg_temp.check_rule('Card payment without a reference', false, $q$
    INSERT INTO payments (bill_id, amount, method) VALUES (1, 500, 'card') $q$);

SELECT pg_temp.check_rule('Payment of zero', false, $q$
    INSERT INTO payments (bill_id, amount, method) VALUES (1, 0, 'cash') $q$);

SELECT pg_temp.check_rule('Valid cash payment', true, $q$
    INSERT INTO payments (bill_id, amount, method) VALUES (1, 500, 'cash') $q$);

\o

SELECT n AS "#", test, expected, result, enforced_by FROM test_results ORDER BY n;

SELECT count(*) FILTER (WHERE result = 'PASS') AS passed,
       count(*) FILTER (WHERE result = 'FAIL') AS failed
FROM test_results;

ROLLBACK;
