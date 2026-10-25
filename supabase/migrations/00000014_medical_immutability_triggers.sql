-- Migration 00000014_medical_immutability_triggers.sql
-- Creates triggers to enforce medical record immutability per section 10.3 and 19.4.

-- ============================================================
-- Trigger: prevent UPDATE on signed medical records
-- ============================================================
CREATE OR REPLACE FUNCTION medical_record_immutable_trigger_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- If record is SIGNED or AMENDED, only allow status changes via amendments
        IF OLD.status IN ('SIGNED', 'AMENDED') THEN
            -- Only allow updated_at/updated_by updates, not clinical data
            IF OLD.chief_complaint IS DISTINCT FROM NEW.chief_complaint
               OR OLD.history IS DISTINCT FROM NEW.history
               OR OLD.physical_exam IS DISTINCT FROM NEW.physical_exam
               OR OLD.diagnosis IS DISTINCT FROM NEW.diagnosis
               OR OLD.treatment_plan IS DISTINCT FROM NEW.treatment_plan
               OR OLD.follow_up_date IS DISTINCT FROM NEW.follow_up_date
               OR OLD.weight_kg IS DISTINCT FROM NEW.weight_kg
               OR OLD.temperature_c IS DISTINCT FROM NEW.temperature_c
               OR OLD.heart_rate IS DISTINCT FROM NEW.heart_rate
               OR OLD.respiratory_rate IS DISTINCT FROM NEW.respiratory_rate
               OR OLD.clinical_data IS DISTINCT FROM NEW.clinical_data
               OR OLD.internal_note IS DISTINCT FROM NEW.internal_note THEN
                RAISE EXCEPTION 'Cannot modify clinical data on a SIGNED or AMENDED medical record';
            END IF;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.status <> 'DRAFT' THEN
            RAISE EXCEPTION 'Cannot delete a non-DRAFT medical record';
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER medical_record_immutable
    BEFORE UPDATE OR DELETE ON medical_records
    FOR EACH ROW EXECUTE FUNCTION medical_record_immutable_trigger_fn();

-- ============================================================
-- Trigger: prevent DELETE on non-DRAFT prescriptions
-- ============================================================
CREATE OR REPLACE FUNCTION prescription_immutable_trigger_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.status <> 'DRAFT' THEN
            RAISE EXCEPTION 'Cannot delete a non-DRAFT prescription';
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER prescription_immutable
    BEFORE DELETE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION prescription_immutable_trigger_fn();

-- ============================================================
-- Trigger: appointment exclusion constraint
-- ============================================================
-- Note: This requires pg_btree extension for exclusion constraints
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE appointments ADD CONSTRAINT appointments_no_overlap
    EXCLUDE USING gist (
        doctor_id WITH =,
        tstzrange(starts_at, ends_at) WITH &&
    ) WHERE (status IN ('SCHEDULED', 'CHECKED_IN', 'IN_CONSULTATION') AND doctor_id IS NOT NULL);