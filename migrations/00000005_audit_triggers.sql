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
            WHERE o.value IS DISTINCT FROM v_new_json->>key
        );
    ELSE -- INSERT
        v_old_json := NULL;
        v_new_json := to_jsonb(NEW);
        v_changed_keys := ARRAY(
            SELECT key FROM jsonb_each(v_new_json)
        );
    END IF;

    -- Exclude sensitive columns from audit metadata
    IF v_old_json IS NOT NULL THEN
        v_old_json := v_old_json - 'password' - 'token' - 'secret' - 'internal_note';
    END IF;
    IF v_new_json IS NOT NULL THEN
        v_new_json := v_new_json - 'password' - 'token' - 'secret' - 'internal_note';
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
        COALESCE(NEW.id, OLD.id),
        COALESCE(NEW.branch_id, OLD.branch_id),
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

-- ============================================================
-- Apply audit triggers to critical tables
-- ============================================================
CREATE TRIGGER audit_sales AFTER INSERT OR UPDATE OR DELETE ON sales
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_orders AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_refunds AFTER INSERT OR UPDATE OR DELETE ON refunds
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_medical_records AFTER INSERT OR UPDATE OR DELETE ON medical_records
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_hospitalizations AFTER INSERT OR UPDATE OR DELETE ON hospitalizations
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_cash_movements AFTER INSERT OR UPDATE OR DELETE ON cash_movements
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_operating_expenses AFTER INSERT OR UPDATE OR DELETE ON operating_expenses
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_product_prices AFTER INSERT OR UPDATE OR DELETE ON product_prices
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_user_roles AFTER INSERT OR UPDATE OR DELETE ON user_roles
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_user_permission_grants AFTER INSERT OR UPDATE OR DELETE ON user_permission_grants
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_pet_guardians AFTER INSERT OR UPDATE OR DELETE ON pet_guardians
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER audit_financial_periods AFTER INSERT OR UPDATE OR DELETE ON financial_periods
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- Apply append-only triggers
-- ============================================================
CREATE TRIGGER append_only_inventory_movements BEFORE UPDATE OR DELETE ON inventory_movements
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_cash_movements BEFORE UPDATE OR DELETE ON cash_movements
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_audit_logs BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_payments BEFORE UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_sale_payments BEFORE UPDATE OR DELETE ON sale_payments
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_product_prices BEFORE UPDATE OR DELETE ON product_prices
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_cost_history BEFORE UPDATE OR DELETE ON cost_history
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_stock_reservations BEFORE UPDATE OR DELETE ON stock_reservations
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_medical_record_amendments BEFORE UPDATE OR DELETE ON medical_record_amendments
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_shared_updates BEFORE UPDATE OR DELETE ON shared_updates
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_service_payments BEFORE UPDATE OR DELETE ON service_payments
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_care_observations BEFORE UPDATE OR DELETE ON care_observations
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();

CREATE TRIGGER append_only_medication_dispensings BEFORE UPDATE OR DELETE ON medication_dispensings
    FOR EACH ROW EXECUTE FUNCTION append_only_trigger_fn();