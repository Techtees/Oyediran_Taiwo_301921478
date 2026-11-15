-- CareBridge Portfolio 3: two pharmacists at Lekki dispensing Ceftriaxone at the same time
-- Open two windows: psql -d carebridge, then run SET search_path TO carebridge; in both.
-- Run each step in the window shown, in order.

-- ===== Round 1: READ COMMITTED, read then write (lost update) =====
-- [A] step 0
UPDATE pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id = 900001;
-- [A] step 1
BEGIN;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
-- [B] step 2
BEGIN;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
-- [A] step 3: A dispenses 4, writes 10 - 4
UPDATE pharmacy_stock SET quantity = 6 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [B] step 4: B dispenses 4, writes 10 - 4
UPDATE pharmacy_stock SET quantity = 6 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [A] step 5: 8 packs left the shelf but the stock only dropped by 4
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;

-- ===== Round 2: READ COMMITTED with SELECT ... FOR UPDATE =====
-- [A] step 0
UPDATE pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id = 900001;
-- [A] step 1
BEGIN;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001 FOR UPDATE;
-- [B] step 2: waits for A
BEGIN;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001 FOR UPDATE;
-- [A] step 3: the SELECT in B now returns 6
UPDATE pharmacy_stock SET quantity = 6 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [B] step 4
UPDATE pharmacy_stock SET quantity = 2 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [A] step 5
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;

-- ===== Round 3: REPEATABLE READ, read then write =====
-- [A] step 0
UPDATE pharmacy_stock SET quantity = 10 WHERE branch_id = 2 AND medication_id = 900001;
-- [A] step 1
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
-- [B] step 2
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
-- [A] step 3
UPDATE pharmacy_stock SET quantity = 6 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [B] step 4: fails with "could not serialize access due to concurrent update"
UPDATE pharmacy_stock SET quantity = 6 WHERE branch_id = 2 AND medication_id = 900001;
ROLLBACK;
-- [B] step 5: retry
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
UPDATE pharmacy_stock SET quantity = 2 WHERE branch_id = 2 AND medication_id = 900001;
COMMIT;
-- [A] step 6
SELECT quantity FROM pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001;
