-- CareBridge Portfolio 2: indexes added after analysing the baseline plans
-- psql -d carebridge -f 03_create_indexes.sql

SET search_path TO carebridge;

-- Q1: expression index, so lower(last_name) / lower(first_name) can be looked up
CREATE INDEX IF NOT EXISTS ix_patients_name_lower
    ON patients (lower(last_name), lower(first_name));

-- Q2: doctor first (equality), then start_time (range + ORDER BY)
CREATE INDEX IF NOT EXISTS ix_appt_doctor_start
    ON appointments (doctor_id, start_time);

-- Q3: partial index, only the ~20% of bills that are not fully paid
CREATE INDEX IF NOT EXISTS ix_bills_outstanding
    ON bills (branch_id, created_at)
    WHERE status IN ('unpaid', 'part_paid');

-- Q4: range lookups on payment date
CREATE INDEX IF NOT EXISTS ix_payments_paid_at
    ON payments (paid_at);

-- Q5: partial index, only lab orders still waiting for a result
CREATE INDEX IF NOT EXISTS ix_lab_orders_pending
    ON lab_orders (ordered_at)
    WHERE status IN ('ordered', 'sample_collected');

-- Q6: date filter on consultations
CREATE INDEX IF NOT EXISTS ix_consultations_created
    ON consultations (created_at);

ANALYZE patients, appointments, bills, payments, lab_orders, consultations;

SELECT indexrelname AS index_name,
       relname      AS table_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'carebridge'
  AND indexrelname IN ('ix_patients_name_lower', 'ix_appt_doctor_start', 'ix_bills_outstanding',
                       'ix_payments_paid_at', 'ix_lab_orders_pending', 'ix_consultations_created')
ORDER BY relname;
