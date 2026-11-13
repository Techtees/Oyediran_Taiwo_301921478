-- CareBridge Portfolio 3: two staff take payment for the same bill at the same time
-- Open two windows: psql -d carebridge, then run SET search_path TO carebridge; in both.
-- Run the first part three times. Before each run, in both windows: \set LEVEL 'READ COMMITTED' (then 'REPEATABLE READ', then 'SERIALIZABLE')

-- [A] step 0
DELETE FROM payments WHERE bill_id = 900002;
-- [A] step 1: billing officer checks the balance
BEGIN ISOLATION LEVEL :LEVEL;
SELECT balance FROM v_bill_balance WHERE bill_id = 900002;
-- [B] step 2: receptionist checks the same bill
BEGIN ISOLATION LEVEL :LEVEL;
SELECT balance FROM v_bill_balance WHERE bill_id = 900002;
-- [A] step 3: patient pays cash
INSERT INTO payments (bill_id, amount, method, received_by) VALUES (900002, 15000, 'cash', 40);
-- [B] step 4: relative pays by transfer
INSERT INTO payments (bill_id, amount, method, reference, received_by)
VALUES (900002, 15000, 'transfer', 'TRF-P3-0001', 22);
-- [A] step 5
COMMIT;
-- [B] step 6
COMMIT;
-- [A] step 7
SELECT total_amount, amount_paid, balance FROM v_bill_balance WHERE bill_id = 900002;

-- ===== Fix without SERIALIZABLE: lock the bill row first =====
-- [A] step 0
DELETE FROM payments WHERE bill_id = 900002;
-- [A] step 1
BEGIN;
SELECT bill_id FROM bills WHERE bill_id = 900002 FOR UPDATE;
SELECT balance FROM v_bill_balance WHERE bill_id = 900002;
-- [B] step 2: waits for A
BEGIN;
SELECT bill_id FROM bills WHERE bill_id = 900002 FOR UPDATE;
-- [A] step 3
INSERT INTO payments (bill_id, amount, method, received_by) VALUES (900002, 15000, 'cash', 40);
COMMIT;
-- [B] step 4: balance is now 0, so no payment is taken
SELECT balance FROM v_bill_balance WHERE bill_id = 900002;
ROLLBACK;
