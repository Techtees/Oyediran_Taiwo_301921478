-- CareBridge Portfolio 3: two pharmacists dispensing the same two drugs in opposite order
-- Open two windows: psql -d carebridge, then run SET search_path TO carebridge; in both.
-- Run each step in the window shown, in order.

-- ===== Round 1: deadlock =====
-- [A] step 0
UPDATE pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id IN (900001, 900002);
-- [A] step 1: Zainab takes Ceftriaxone first
BEGIN;
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900001;
-- [B] step 2: Uche takes Insulin Glargine first
BEGIN;
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900002;
-- [A] step 3: waits for B
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900002;
-- [B] step 4: deadlock detected after about 1 second, B is rolled back and A continues
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900001;
ROLLBACK;
-- [A] step 5
COMMIT;
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id IN (900001, 900002) ORDER BY 1;

-- ===== Round 2: both lock the rows in the same order (by medication_id) =====
-- [A] step 0
UPDATE pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id IN (900001, 900002);
-- [A] step 1
BEGIN;
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id IN (900001, 900002) ORDER BY medication_id FOR UPDATE;
-- [B] step 2: waits for A instead of deadlocking
BEGIN;
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id IN (900002, 900001) ORDER BY medication_id FOR UPDATE;
-- [A] step 3
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900001;
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900002;
COMMIT;
-- [B] step 4
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900002;
UPDATE pharmacy_stock SET quantity = quantity - 1 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [A] step 5
SELECT medication_id, quantity FROM pharmacy_stock
WHERE branch_id = 2 AND medication_id IN (900001, 900002) ORDER BY 1;
