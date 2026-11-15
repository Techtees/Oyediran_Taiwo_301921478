-- CareBridge Portfolio 3: remove all demo rows (IDs from 900000 upwards)
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P3_99_reset_demo_data.sql

SET search_path TO carebridge;

DELETE FROM payments           WHERE bill_id >= 900000;
DELETE FROM bill_items         WHERE bill_id >= 900000;
DELETE FROM bills              WHERE bill_id >= 900000;
DELETE FROM dispensations      WHERE prescription_id >= 900000;
DELETE FROM prescription_items WHERE prescription_id >= 900000;
DELETE FROM prescriptions      WHERE prescription_id >= 900000;
DELETE FROM consultations      WHERE consultation_id >= 900000;
DELETE FROM appointments       WHERE appointment_id >= 900000 OR reason = 'P3 demo';
DELETE FROM pharmacy_stock     WHERE medication_id >= 900000;
DELETE FROM medications        WHERE medication_id >= 900000;
