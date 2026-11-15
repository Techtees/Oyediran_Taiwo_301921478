-- CareBridge Portfolio 3: COMMIT, ROLLBACK and SAVEPOINT in one session
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P3_00_setup_demo_data.sql
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P3_01_commit_rollback.sql

SET search_path TO carebridge;

\echo '== Before'
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id >= 900000 ORDER BY 1;

\echo '== 1. COMMIT: dispense 4 x Ceftriaxone on prescription 900001 and add it to bill 900001'
BEGIN;
INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by)
VALUES (900001, 900001, 2, 4, 28)
RETURNING dispensation_id \gset
UPDATE pharmacy_stock SET quantity = quantity - 4, updated_at = now()
WHERE branch_id = 2 AND medication_id = 900001;
INSERT INTO bill_items (bill_id, item_type, dispensation_id, description, quantity, unit_price)
SELECT 900001, 'medication', :dispensation_id, name || ' ' || strength, 4, unit_price
FROM medications WHERE medication_id = 900001;
UPDATE prescriptions SET status = 'partially_dispensed' WHERE prescription_id = 900001;
COMMIT;

\echo '== 2. ROLLBACK: dispense 20 x Insulin Glargine on prescription 900001, only 10 in stock'
BEGIN;
INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by)
VALUES (900001, 900002, 2, 20, 28);
UPDATE pharmacy_stock SET quantity = quantity - 20, updated_at = now()
WHERE branch_id = 2 AND medication_id = 900002;
UPDATE prescriptions SET status = 'dispensed' WHERE prescription_id = 900001;
ROLLBACK;

\echo '== 3. SAVEPOINT: dispense prescription 900002, keep the item that succeeds'
BEGIN;
INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by)
VALUES (900002, 900001, 2, 2, 31);
UPDATE pharmacy_stock SET quantity = quantity - 2, updated_at = now()
WHERE branch_id = 2 AND medication_id = 900001;
SAVEPOINT before_insulin;
INSERT INTO dispensations (prescription_id, medication_id, branch_id, quantity, dispensed_by)
VALUES (900002, 900002, 2, 30, 31);
UPDATE pharmacy_stock SET quantity = quantity - 30, updated_at = now()
WHERE branch_id = 2 AND medication_id = 900002;
ROLLBACK TO SAVEPOINT before_insulin;
UPDATE prescriptions SET status = 'partially_dispensed' WHERE prescription_id = 900002;
COMMIT;

\echo '== After'
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id >= 900000 ORDER BY 1;

SELECT d.prescription_id, d.medication_id, d.quantity, s.full_name AS pharmacist
FROM dispensations d JOIN staff s ON s.staff_id = d.dispensed_by
WHERE d.prescription_id >= 900000 ORDER BY d.dispensation_id;

SELECT prescription_id, status FROM prescriptions WHERE prescription_id >= 900000 ORDER BY 1;

SELECT bill_id, total_amount, amount_paid, balance FROM v_bill_balance WHERE bill_id = 900001;
