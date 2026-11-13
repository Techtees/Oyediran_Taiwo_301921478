-- CareBridge Portfolio 3: two receptionists booking Dr Hadiza Abubakar for overlapping slots
-- Open two windows: psql -d carebridge, then run SET search_path TO carebridge; in both.
-- Run each step in the window shown, in order.

-- ===== Round 1: both see the slot as free, the constraint stops the second booking =====
-- [A] step 1: Bukola (Lekki reception) checks the 10:00 slot
BEGIN;
SELECT count(*) AS clashes FROM appointments
WHERE doctor_id = 9 AND status <> 'cancelled'
  AND tstzrange(start_time, end_time, '[)') && tstzrange('2027-01-05 10:00+01', '2027-01-05 10:30+01', '[)');
-- [B] step 2: Segun checks 10:15 at the same moment, also sees 0 clashes
BEGIN;
SELECT count(*) AS clashes FROM appointments
WHERE doctor_id = 9 AND status <> 'cancelled'
  AND tstzrange(start_time, end_time, '[)') && tstzrange('2027-01-05 10:15+01', '2027-01-05 10:45+01', '[)');
-- [A] step 3
INSERT INTO appointments (patient_id, doctor_id, branch_id, booked_by, start_time, end_time, reason)
VALUES (124, 9, 2, 22, '2027-01-05 10:00+01', '2027-01-05 10:30+01', 'P3 demo');
-- [B] step 4: waits, because the uncommitted row from A conflicts
INSERT INTO appointments (patient_id, doctor_id, branch_id, booked_by, start_time, end_time, reason)
VALUES (125, 9, 2, 25, '2027-01-05 10:15+01', '2027-01-05 10:45+01', 'P3 demo');
-- [A] step 5: B now fails with ex_doctor_no_overlap
COMMIT;
-- [B] step 6
ROLLBACK;

-- ===== Round 2: the first booking is abandoned, so the second one goes through =====
-- [A] step 1
BEGIN;
INSERT INTO appointments (patient_id, doctor_id, branch_id, booked_by, start_time, end_time, reason)
VALUES (126, 9, 2, 22, '2027-01-05 11:00+01', '2027-01-05 11:30+01', 'P3 demo');
-- [B] step 2: waits
BEGIN;
INSERT INTO appointments (patient_id, doctor_id, branch_id, booked_by, start_time, end_time, reason)
VALUES (127, 9, 2, 25, '2027-01-05 11:00+01', '2027-01-05 11:30+01', 'P3 demo');
-- [A] step 3: the INSERT in B now succeeds
ROLLBACK;
-- [B] step 4
COMMIT;
-- [A] step 5
SELECT a.start_time, a.end_time, p.mrn, s.full_name AS booked_by
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN staff s    ON s.staff_id = a.booked_by
WHERE a.doctor_id = 9 AND a.start_time >= '2027-01-05' AND a.start_time < '2027-01-06'
ORDER BY a.start_time;
