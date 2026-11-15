-- CareBridge Portfolio 3: fixed demo rows used by every scenario
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P3_00_setup_demo_data.sql

SET search_path TO carebridge;
\ir Oyediran_Taiwo_301921478_P3_99_reset_demo_data.sql

INSERT INTO medications (medication_id, name, form, strength, unit_price) OVERRIDING SYSTEM VALUE
VALUES (900001, 'Ceftriaxone',      'injection', '1g',       2500.00),
       (900002, 'Insulin Glargine', 'injection', '100IU/ml', 8000.00);

INSERT INTO pharmacy_stock (branch_id, medication_id, quantity, reorder_level)
VALUES (2, 900001, 10, 5),
       (2, 900002, 10, 5);

INSERT INTO appointments (appointment_id, patient_id, doctor_id, branch_id, booked_by,
                          start_time, end_time, status, reason) OVERRIDING SYSTEM VALUE
VALUES (900001, 123, 9, 2, 22, '2027-01-04 09:00+01', '2027-01-04 09:30+01', 'completed', 'P3 demo'),
       (900002, 124, 9, 2, 22, '2027-01-04 09:30+01', '2027-01-04 10:00+01', 'completed', 'P3 demo');

INSERT INTO consultations (consultation_id, appointment_id, notes) OVERRIDING SYSTEM VALUE
VALUES (900001, 900001, 'P3 demo'),
       (900002, 900002, 'P3 demo');

INSERT INTO prescriptions (prescription_id, consultation_id) OVERRIDING SYSTEM VALUE
VALUES (900001, 900001),
       (900002, 900002);

INSERT INTO prescription_items (prescription_id, medication_id, dosage, frequency, duration_days, quantity)
VALUES (900001, 900001, '1g',       'once daily',  4,  4),
       (900001, 900002, '10 units', 'once daily', 20, 20),
       (900002, 900001, '1g',       'once daily',  2,  2),
       (900002, 900002, '10 units', 'once daily', 30, 30);

INSERT INTO bills (bill_id, patient_id, branch_id, consultation_id, created_by) OVERRIDING SYSTEM VALUE
VALUES (900001, 123, 2, 900001, 40),
       (900002, 124, 2, 900002, 40);

INSERT INTO bill_items (bill_id, item_type, description, unit_price)
VALUES (900001, 'consultation', 'Consultation fee', 15000.00),
       (900002, 'consultation', 'Consultation fee', 15000.00);

SELECT s.medication_id, m.name, s.quantity
FROM pharmacy_stock s JOIN medications m USING (medication_id)
WHERE s.branch_id = 2 AND s.medication_id >= 900000
ORDER BY 1;

SELECT bill_id, patient_id, total_amount, amount_paid, balance
FROM v_bill_balance WHERE bill_id >= 900000 ORDER BY 1;
