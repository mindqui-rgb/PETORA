-- Install table triggers after every audited and append-only table exists.

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
