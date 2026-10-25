-- Migration 00000005_audit_triggers.sql
-- Creates audit triggers for critical tables per section 19.6.
-- Audit logs are append-only.

-- ============================================================
-- Audit trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_actor_id UUID;
    v_old_json JSONB;
    v_new_json JSONB;
    v_changed_keys TEXT[];
BEGIN
    -- Get actor from session or context
    v_actor_id := current_setting('app.actor_id', true)::UUID;

    IF TG_OP = 'DELETE' THEN
        v_old_json := to_jsonb(OLD);
        v_new_json := NULL;
        v_changed_keys := ARRAY(
            SELECT key FROM jsonb_each(v_old_json)
        );
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_json := to_jsonb(OLD);
        v_new_json := to_jsonb(NEW);
        v_changed_keys := ARRAY(
            SELECT key
            FROM jsonb_each(v_old_json) o
            WHERE o.value IS DISTINCT FROM v_new_json->key
        );
    ELSE -- INSERT
        v_old_json := NULL;
        v_new_json := to_jsonb(NEW);
        v_changed_keys := ARRAY(
            SELECT key FROM jsonb_each(v_new_json)
        );
    END IF;

    -- Keep clinical and credential data out of audit metadata.
    IF v_old_json IS NOT NULL THEN
        v_old_json := v_old_json
            - 'password' - 'token' - 'secret' - 'internal_note'
            - 'diagnosis' - 'notes' - 'chief_complaint' - 'history'
            - 'physical_exam' - 'treatment_plan' - 'follow_up_date'
            - 'weight_kg' - 'temperature_c' - 'heart_rate'
            - 'respiratory_rate' - 'clinical_data';
    END IF;
    IF v_new_json IS NOT NULL THEN
        v_new_json := v_new_json
            - 'password' - 'token' - 'secret' - 'internal_note'
            - 'diagnosis' - 'notes' - 'chief_complaint' - 'history'
            - 'physical_exam' - 'treatment_plan' - 'follow_up_date'
            - 'weight_kg' - 'temperature_c' - 'heart_rate'
            - 'respiratory_rate' - 'clinical_data';
    END IF;

    INSERT INTO audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        branch_id,
        request_id,
        reason,
        metadata
    ) VALUES (
        v_actor_id,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(
            NULLIF(v_new_json->>'id', '')::UUID,
            NULLIF(v_old_json->>'id', '')::UUID
        ),
        COALESCE(
            NULLIF(v_new_json->>'branch_id', '')::UUID,
            NULLIF(v_old_json->>'branch_id', '')::UUID
        ),
        current_setting('app.request_id', true),
        current_setting('app.reason', true),
        jsonb_build_object(
            'old', v_old_json,
            'new', v_new_json,
            'changed_keys', v_changed_keys
        )
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- ============================================================
-- Append-only trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION append_only_trigger_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Table % is append-only. Operation % not allowed.', TG_TABLE_NAME, TG_OP;
    END IF;
    RETURN NEW;
END;
$$;
