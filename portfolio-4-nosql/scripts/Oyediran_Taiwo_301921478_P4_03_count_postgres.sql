SET search_path TO carebridge;
SELECT 'patients'         AS item, count(*) AS postgresql FROM patients
UNION ALL SELECT 'appointments',     count(*) FROM appointments
UNION ALL SELECT 'consultations',    count(*) FROM consultations
UNION ALL SELECT 'diagnoses',        count(*) FROM patient_diagnoses
UNION ALL SELECT 'prescription items', count(*) FROM prescription_items
UNION ALL SELECT 'lab orders',       count(*) FROM lab_orders
UNION ALL SELECT 'lab results',      count(*) FROM lab_results
UNION ALL SELECT 'bills',            count(*) FROM bills
UNION ALL SELECT 'payments',         count(*) FROM payments
UNION ALL SELECT 'total billed',     (SELECT sum(quantity * unit_price) FROM bill_items)
UNION ALL SELECT 'doctor-days',      count(DISTINCT (doctor_id, (start_time AT TIME ZONE 'Africa/Lagos')::date)) FROM appointments;
