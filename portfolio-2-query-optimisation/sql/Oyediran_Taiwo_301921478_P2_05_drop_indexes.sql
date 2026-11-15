-- CareBridge Portfolio 2: remove the Portfolio 2 indexes to return to the baseline
-- psql -d carebridge -f Oyediran_Taiwo_301921478_P2_05_drop_indexes.sql

SET search_path TO carebridge;

DROP INDEX IF EXISTS ix_patients_name_lower;
DROP INDEX IF EXISTS ix_appt_doctor_start;
DROP INDEX IF EXISTS ix_bills_outstanding;
DROP INDEX IF EXISTS ix_payments_paid_at;
DROP INDEX IF EXISTS ix_lab_orders_pending;
DROP INDEX IF EXISTS ix_consultations_created;

ANALYZE patients, appointments, bills, payments, lab_orders, consultations;
