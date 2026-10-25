-- Migration 00000011_create_clinic_tables.sql
-- Creates clinic tables per section 10.

-- ============================================================
-- Service Catalog
-- ============================================================
CREATE TABLE service_catalog (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('GROOMING', 'BOARDING', 'CLINIC')),
    duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK (duration_minutes > 0),
    is_addon BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Doctor Schedules
-- ============================================================
CREATE TABLE doctor_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctor_profiles(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK (slot_duration_minutes > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Appointments
-- ============================================================
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctor_profiles(id) ON DELETE RESTRICT,
    service_id UUID REFERENCES service_catalog(id) ON DELETE RESTRICT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL CHECK (ends_at > starts_at),
    status TEXT NOT NULL CHECK (status IN (
        'SCHEDULED', 'CHECKED_IN', 'IN_CONSULTATION', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    )),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Visits
-- ============================================================
CREATE TABLE visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctor_profiles(id) ON DELETE RESTRICT,
    appointment_id UUID UNIQUE REFERENCES appointments(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'COMPLETED', 'CANCELLED')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    consent_given_by_name TEXT,
    consent_method TEXT CHECK (consent_method IN ('IN_PERSON', 'PHONE')),
    weight_kg NUMERIC(14,3),
    temperature_c NUMERIC(5,2),
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Medical Records
-- ============================================================
CREATE TABLE medical_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID NOT NULL UNIQUE REFERENCES visits(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'SIGNED', 'AMENDED', 'VOIDED')),
    chief_complaint TEXT,
    history TEXT,
    physical_exam TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    follow_up_date DATE,
    weight_kg NUMERIC(14,3),
    temperature_c NUMERIC(5,2),
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    clinical_data JSONB,
    internal_note TEXT,
    signed_by UUID,
    signed_at TIMESTAMPTZ,
    doctor_license_snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ,
    updated_by UUID
);

-- ============================================================
-- Medical Record Amendments (append-only)
-- ============================================================
CREATE TABLE medical_record_amendments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medical_record_id UUID NOT NULL REFERENCES medical_records(id) ON DELETE RESTRICT,
    reason TEXT NOT NULL,
    previous_content JSONB NOT NULL,
    new_content JSONB NOT NULL,
    amended_by UUID NOT NULL,
    amended_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Prescriptions
-- ============================================================
CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID NOT NULL REFERENCES visits(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctor_profiles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'SIGNED', 'CANCELLED')),
    signed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE prescription_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    dose_text TEXT NOT NULL,
    frequency_text TEXT NOT NULL,
    duration_days INTEGER NOT NULL CHECK (duration_days > 0),
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    instructions TEXT
);

-- ============================================================
-- Treatment Records
-- ============================================================
CREATE TABLE treatment_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID NOT NULL REFERENCES visits(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES service_catalog(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctor_profiles(id) ON DELETE RESTRICT,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes TEXT,
    fee NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (fee >= 0)
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_appointments_branch ON appointments(branch_id, starts_at);
CREATE INDEX idx_visits_pet ON visits(pet_id, started_at);
CREATE INDEX idx_medical_records_visit ON medical_records(visit_id);