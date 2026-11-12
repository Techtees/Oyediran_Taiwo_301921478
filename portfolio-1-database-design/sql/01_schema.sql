-- CareBridge Clinics schema (PostgreSQL)
-- psql -d carebridge -f 01_schema.sql

DROP SCHEMA IF EXISTS carebridge CASCADE;
CREATE SCHEMA carebridge;
SET search_path TO carebridge;

-- needed for the EXCLUDE constraint on appointments
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TYPE staff_role          AS ENUM ('doctor','receptionist','pharmacist','lab_scientist','billing_officer','admin');
CREATE TYPE appointment_status  AS ENUM ('scheduled','completed','cancelled','no_show');
CREATE TYPE prescription_status AS ENUM ('issued','partially_dispensed','dispensed','cancelled');
CREATE TYPE lab_order_status    AS ENUM ('ordered','sample_collected','completed','cancelled');
CREATE TYPE bill_status         AS ENUM ('unpaid','part_paid','paid','void');
CREATE TYPE bill_item_type      AS ENUM ('consultation','lab_test','medication','other');
CREATE TYPE payment_method      AS ENUM ('cash','card','transfer','hmo');

CREATE TABLE branches (
    branch_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    city        VARCHAR(50)  NOT NULL,
    address     TEXT
);

CREATE TABLE departments (
    department_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE branch_departments (
    branch_id     INT NOT NULL REFERENCES branches(branch_id),
    department_id INT NOT NULL REFERENCES departments(department_id),
    PRIMARY KEY (branch_id, department_id)
);

CREATE TABLE staff (
    staff_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_id  INT          NOT NULL REFERENCES branches(branch_id),
    full_name  VARCHAR(150) NOT NULL,
    role       staff_role   NOT NULL,
    email      VARCHAR(150) UNIQUE,
    phone      VARCHAR(20),
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_staff_id_role UNIQUE (staff_id, role),
    CONSTRAINT ck_staff_email CHECK (email IS NULL OR email LIKE '%_@_%._%')
);

CREATE TABLE doctors (
    doctor_id      INT          PRIMARY KEY,
    role           staff_role   NOT NULL DEFAULT 'doctor' CHECK (role = 'doctor'),
    department_id  INT          NOT NULL REFERENCES departments(department_id),
    specialisation VARCHAR(100),
    licence_no     VARCHAR(30)  NOT NULL UNIQUE,
    CONSTRAINT fk_doctor_staff FOREIGN KEY (doctor_id, role)
        REFERENCES staff(staff_id, role) ON UPDATE CASCADE
);

CREATE TABLE patients (
    patient_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mrn            VARCHAR(20)  NOT NULL UNIQUE,
    first_name     VARCHAR(80)  NOT NULL,
    last_name      VARCHAR(80)  NOT NULL,
    dob            DATE         NOT NULL CHECK (dob <= CURRENT_DATE),
    gender         VARCHAR(10)  CHECK (gender IN ('male','female','other')),
    phone          VARCHAR(20),
    email          VARCHAR(150) CHECK (email IS NULL OR email LIKE '%_@_%._%'),
    blood_group    VARCHAR(3)   CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    home_branch_id INT          NOT NULL REFERENCES branches(branch_id),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE appointments (
    appointment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id     INT                NOT NULL REFERENCES patients(patient_id),
    doctor_id      INT                NOT NULL REFERENCES doctors(doctor_id),
    branch_id      INT                NOT NULL REFERENCES branches(branch_id),
    booked_by      INT                REFERENCES staff(staff_id),
    start_time     TIMESTAMPTZ        NOT NULL,
    end_time       TIMESTAMPTZ        NOT NULL,
    status         appointment_status NOT NULL DEFAULT 'scheduled',
    reason         TEXT,
    created_at     TIMESTAMPTZ        NOT NULL DEFAULT now(),
    CONSTRAINT ck_appt_time CHECK (end_time > start_time),
    -- no overlapping appointments for the same doctor
    CONSTRAINT ex_doctor_no_overlap EXCLUDE USING gist (
        doctor_id WITH =,
        tstzrange(start_time, end_time, '[)') WITH &&
    ) WHERE (status <> 'cancelled')
);

CREATE TABLE consultations (
    consultation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id  INT         NOT NULL UNIQUE REFERENCES appointments(appointment_id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE diagnosis_codes (
    icd10_code  VARCHAR(10) PRIMARY KEY,
    description TEXT        NOT NULL
);

CREATE TABLE patient_diagnoses (
    consultation_id INT         NOT NULL REFERENCES consultations(consultation_id) ON DELETE CASCADE,
    icd10_code      VARCHAR(10) NOT NULL REFERENCES diagnosis_codes(icd10_code),
    is_primary      BOOLEAN     NOT NULL DEFAULT FALSE,
    notes           TEXT,
    PRIMARY KEY (consultation_id, icd10_code)
);

CREATE UNIQUE INDEX uq_one_primary_diagnosis
    ON patient_diagnoses (consultation_id) WHERE is_primary;

CREATE TABLE medications (
    medication_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    form          VARCHAR(30)   NOT NULL,
    strength      VARCHAR(30)   NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT uq_medication UNIQUE (name, form, strength)
);

CREATE TABLE pharmacy_stock (
    branch_id     INT         NOT NULL REFERENCES branches(branch_id),
    medication_id INT         NOT NULL REFERENCES medications(medication_id),
    quantity      INT         NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reorder_level INT         NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (branch_id, medication_id)
);

CREATE TABLE prescriptions (
    prescription_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    consultation_id INT                 NOT NULL REFERENCES consultations(consultation_id),
    issued_at       TIMESTAMPTZ         NOT NULL DEFAULT now(),
    status          prescription_status NOT NULL DEFAULT 'issued'
);

CREATE TABLE prescription_items (
    prescription_id INT         NOT NULL REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    medication_id   INT         NOT NULL REFERENCES medications(medication_id),
    dosage          VARCHAR(50),
    frequency       VARCHAR(50),
    duration_days   INT         CHECK (duration_days > 0),
    quantity        INT         NOT NULL CHECK (quantity > 0),
    instructions    TEXT,
    PRIMARY KEY (prescription_id, medication_id)
);

CREATE TABLE dispensations (
    dispensation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prescription_id INT         NOT NULL,
    medication_id   INT         NOT NULL,
    branch_id       INT         NOT NULL REFERENCES branches(branch_id),
    quantity        INT         NOT NULL CHECK (quantity > 0),
    dispensed_by    INT         NOT NULL REFERENCES staff(staff_id),
    dispensed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_disp_item FOREIGN KEY (prescription_id, medication_id)
        REFERENCES prescription_items(prescription_id, medication_id),
    CONSTRAINT fk_disp_stock FOREIGN KEY (branch_id, medication_id)
        REFERENCES pharmacy_stock(branch_id, medication_id)
);

CREATE TABLE lab_tests (
    test_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100)  NOT NULL UNIQUE,
    category        VARCHAR(50),
    unit            VARCHAR(20),
    reference_range VARCHAR(50),
    price           NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE lab_orders (
    lab_order_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    consultation_id INT              NOT NULL REFERENCES consultations(consultation_id),
    test_id         INT              NOT NULL REFERENCES lab_tests(test_id),
    status          lab_order_status NOT NULL DEFAULT 'ordered',
    ordered_at      TIMESTAMPTZ      NOT NULL DEFAULT now()
);

CREATE TABLE lab_results (
    result_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lab_order_id INT         NOT NULL UNIQUE REFERENCES lab_orders(lab_order_id),
    value        VARCHAR(50),
    is_abnormal  BOOLEAN,
    summary      TEXT,
    performed_by INT         NOT NULL REFERENCES staff(staff_id),
    resulted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_result_has_content CHECK (value IS NOT NULL OR summary IS NOT NULL)
);

CREATE TABLE bills (
    bill_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id      INT         NOT NULL REFERENCES patients(patient_id),
    branch_id       INT         NOT NULL REFERENCES branches(branch_id),
    consultation_id INT         REFERENCES consultations(consultation_id),
    status          bill_status NOT NULL DEFAULT 'unpaid',
    created_by      INT         REFERENCES staff(staff_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bill_items (
    bill_item_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bill_id         INT            NOT NULL REFERENCES bills(bill_id) ON DELETE CASCADE,
    item_type       bill_item_type NOT NULL,
    lab_order_id    INT            REFERENCES lab_orders(lab_order_id),
    dispensation_id INT            REFERENCES dispensations(dispensation_id),
    description     VARCHAR(150)   NOT NULL,
    quantity        INT            NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price      NUMERIC(10,2)  NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT ck_bill_item_source CHECK (
        (item_type = 'lab_test')   = (lab_order_id    IS NOT NULL) AND
        (item_type = 'medication') = (dispensation_id IS NOT NULL)
    ),
    CONSTRAINT uq_bill_lab_order    UNIQUE (lab_order_id),
    CONSTRAINT uq_bill_dispensation UNIQUE (dispensation_id)
);

CREATE TABLE payments (
    payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bill_id    INT            NOT NULL REFERENCES bills(bill_id),
    amount     NUMERIC(12,2)  NOT NULL CHECK (amount > 0),
    method     payment_method NOT NULL,
    reference  VARCHAR(50),
    received_by INT           REFERENCES staff(staff_id),
    paid_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CONSTRAINT ck_payment_reference CHECK (method = 'cash' OR reference IS NOT NULL)
);

CREATE INDEX ix_staff_branch            ON staff (branch_id);
CREATE INDEX ix_doctors_department      ON doctors (department_id);
CREATE INDEX ix_patients_home_branch    ON patients (home_branch_id);
CREATE INDEX ix_appt_patient            ON appointments (patient_id, start_time);
CREATE INDEX ix_appt_branch             ON appointments (branch_id, start_time);
CREATE INDEX ix_diag_code               ON patient_diagnoses (icd10_code);
CREATE INDEX ix_presc_consultation      ON prescriptions (consultation_id);
CREATE INDEX ix_presc_items_med         ON prescription_items (medication_id);
CREATE INDEX ix_disp_item               ON dispensations (prescription_id, medication_id);
CREATE INDEX ix_lab_orders_consultation ON lab_orders (consultation_id);
CREATE INDEX ix_bills_patient           ON bills (patient_id);
CREATE INDEX ix_bill_items_bill         ON bill_items (bill_id);
CREATE INDEX ix_payments_bill           ON payments (bill_id);

CREATE VIEW v_bill_balance AS
SELECT b.bill_id,
       b.patient_id,
       b.branch_id,
       b.status,
       COALESCE(i.total, 0)                        AS total_amount,
       COALESCE(p.paid, 0)                         AS amount_paid,
       COALESCE(i.total, 0) - COALESCE(p.paid, 0)  AS balance
FROM bills b
LEFT JOIN (SELECT bill_id, SUM(quantity * unit_price) AS total
           FROM bill_items GROUP BY bill_id) i ON i.bill_id = b.bill_id
LEFT JOIN (SELECT bill_id, SUM(amount) AS paid
           FROM payments GROUP BY bill_id) p ON p.bill_id = b.bill_id;
