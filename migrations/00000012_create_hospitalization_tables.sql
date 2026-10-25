-- Migration 00000012_create_hospitalization_tables.sql
-- Creates hospitalization and boarding tables per section 11 and 12.

-- ============================================================
-- Care Units
-- ============================================================
CREATE TABLE care_units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('KENNEL', 'ICU', 'ISOLATION', 'BOARDING_ROOM')),
    capacity INTEGER NOT NULL DEFAULT 1 CHECK (capacity >= 1),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (branch_id, code)
);

-- ============================================================
-- Hospitalizations
-- ============================================================
CREATE TABLE hospitalizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN (
        'PLANNED', 'ADMITTED', 'DISCHARGE_PENDING', 'DISCHARGED', 'CANCELLED'
    )),
    admission_date TIMESTAMPTZ,
    discharge_date TIMESTAMPTZ,
    diagnosis TEXT,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    updated_by UUID
);

-- ============================================================
-- Hospitalization Assignments
-- ============================================================
CREATE TABLE hospitalization_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hospitalization_id UUID NOT NULL REFERENCES hospitalizations(id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES care_units(id) ON DELETE RESTRICT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Care Observations (append-only)
-- ============================================================
CREATE TABLE care_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hospitalization_id UUID NOT NULL REFERENCES hospitalizations(id) ON DELETE RESTRICT,
    observed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    observation_type TEXT NOT NULL CHECK (observation_type IN (
        'VITALS', 'MEDICATION_GIVEN', 'FEEDING', 'URINATION', 'DEFECATION',
        'PROCEDURE', 'NOTE'
    )),
    values JSONB,
    note TEXT,
    recorded_by UUID NOT NULL
);

-- ============================================================
-- Care Tasks
-- ============================================================
CREATE TABLE care_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hospitalization_id UUID NOT NULL REFERENCES hospitalizations(id) ON DELETE RESTRICT,
    task_type TEXT NOT NULL,
    due_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'DONE', 'CANCELLED')),
    assigned_to UUID,
    completed_at TIMESTAMPTZ,
    completed_by UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Shared Updates (append-only)
-- ============================================================
CREATE TABLE shared_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hospitalization_id UUID NOT NULL REFERENCES hospitalizations(id) ON DELETE RESTRICT,
    update_type TEXT NOT NULL CHECK (update_type IN (
        'DAILY_SUMMARY', 'PROGRESS', 'DISCHARGE_SUMMARY'
    )),
    body TEXT NOT NULL,
    published_at TIMESTAMPTZ,
    published_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Service Bookings
-- ============================================================
CREATE TABLE service_bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES service_catalog(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('GROOMING', 'BOARDING')),
    status TEXT NOT NULL CHECK (status IN (
        'REQUESTED', 'CONFIRMED', 'CHECKED_IN', 'IN_PROGRESS',
        'COMPLETED', 'CANCELLED', 'NO_SHOW'
    )),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL CHECK (ends_at > starts_at),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

CREATE TABLE service_booking_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES service_bookings(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES service_catalog(id) ON DELETE RESTRICT,
    is_addon BOOLEAN NOT NULL DEFAULT false,
    approval_status TEXT NOT NULL CHECK (approval_status IN ('PENDING', 'APPROVED', 'DECLINED')),
    approved_by UUID,
    approval_method TEXT CHECK (approval_method IN ('PORTAL', 'PHONE')),
    approved_at TIMESTAMPTZ
);

-- ============================================================
-- Boarding Stays
-- ============================================================
CREATE TABLE boarding_stays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES service_bookings(id) ON DELETE RESTRICT,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    unit_id UUID NOT NULL REFERENCES care_units(id) ON DELETE RESTRICT,
    check_in_at TIMESTAMPTZ NOT NULL,
    check_out_at TIMESTAMPTZ,
    check_in_weight_kg NUMERIC(14,3),
    check_in_notes TEXT,
    check_out_weight_kg NUMERIC(14,3),
    check_out_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Service Capacity
-- ============================================================
CREATE TABLE service_capacity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    service_id UUID NOT NULL REFERENCES service_catalog(id) ON DELETE RESTRICT,
    slot_start TIMESTAMPTZ NOT NULL,
    slot_end TIMESTAMPTZ NOT NULL CHECK (slot_end > slot_start),
    capacity INTEGER NOT NULL CHECK (capacity >= 1),
    UNIQUE (branch_id, service_id, slot_start)
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_hospitalizations_branch ON hospitalizations(branch_id, status);
CREATE INDEX idx_hospitalization_assignments_unit ON hospitalization_assignments(unit_id, start_at);
CREATE INDEX idx_service_bookings_branch ON service_bookings(branch_id, starts_at);