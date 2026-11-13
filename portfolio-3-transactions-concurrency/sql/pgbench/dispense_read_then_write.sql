BEGIN;
SELECT quantity AS q FROM carebridge.pharmacy_stock WHERE branch_id = 2 AND medication_id = 900001 \gset
UPDATE carebridge.pharmacy_stock SET quantity = :q - 1 WHERE branch_id = 2 AND medication_id = 900001;
END;
