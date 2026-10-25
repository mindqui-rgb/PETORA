-- Migration 00000019_rls_billing.sql
-- Row Level Security policies for billing and finance tables per section 19.2.

-- ============================================================
-- Service Invoices
-- ============================================================
CREATE POLICY "service_invoices_select" ON service_invoices
    FOR SELECT USING (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR branch_id = ANY(user_branch_ids())
        OR has_permission('service_invoice.manage')
        OR has_permission('finance.cash.read')
    );

CREATE POLICY "service_invoices_insert" ON service_invoices
    FOR INSERT WITH CHECK (
        has_permission('service_invoice.manage')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Service Invoice Items
-- ============================================================
CREATE POLICY "service_invoice_items_select" ON service_invoice_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM service_invoices si
            WHERE si.id = service_invoice_items.invoice_id
            AND (si.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
                 OR si.branch_id = ANY(user_branch_ids())
                 OR has_permission('service_invoice.manage'))
        )
    );

-- ============================================================
-- Service Payments
-- ============================================================
CREATE POLICY "service_payments_select" ON service_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM service_invoices si
            WHERE si.id = service_payments.invoice_id
            AND (si.branch_id = ANY(user_branch_ids())
                 OR has_permission('service_invoice.manage')
                 OR has_permission('finance.cash.read'))
        )
    );

CREATE POLICY "service_payments_insert" ON service_payments
    FOR INSERT WITH CHECK (
        has_permission('service_invoice.manage')
        AND recorded_by = auth.uid()
    );

-- ============================================================
-- Customer Credits
-- ============================================================
CREATE POLICY "customer_credits_select" ON customer_credits
    FOR SELECT USING (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR has_permission('service_invoice.manage')
        OR has_permission('finance.cash.read')
    );

-- ============================================================
-- Operating Expenses
-- ============================================================
CREATE POLICY "operating_expenses_select" ON operating_expenses
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('finance.expense.create')
        OR has_permission('finance.expense.approve')
        OR has_permission('finance.cash.read')
    );

CREATE POLICY "operating_expenses_insert" ON operating_expenses
    FOR INSERT WITH CHECK (
        has_permission('finance.expense.create')
        AND requested_by = auth.uid()
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Financial Periods
-- ============================================================
CREATE POLICY "financial_periods_select" ON financial_periods
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('finance.period.close')
    );

-- ============================================================
-- Orders
-- ============================================================
CREATE POLICY "orders_select" ON orders
    FOR SELECT USING (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR branch_id = ANY(user_branch_ids())
        OR has_permission('payment.review')
        OR has_permission('payment.confirm')
        OR has_permission('pos.sale')
    );

CREATE POLICY "orders_insert" ON orders
    FOR INSERT WITH CHECK (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR has_permission('pos.sale')
    );

-- ============================================================
-- Order Items
-- ============================================================
CREATE POLICY "order_items_select" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_items.order_id
            AND (o.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
                 OR o.branch_id = ANY(user_branch_ids())
                 OR has_permission('payment.review')
                 OR has_permission('payment.confirm'))
        )
    );

-- ============================================================
-- Payments
-- ============================================================
CREATE POLICY "payments_select" ON payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = payments.order_id
            AND (o.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
                 OR o.branch_id = ANY(user_branch_ids())
                 OR has_permission('payment.review'))
        )
    );

CREATE POLICY "payments_insert" ON payments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = payments.order_id
            AND o.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        )
    );

-- ============================================================
-- Order Review Actions
-- ============================================================
CREATE POLICY "order_review_actions_select" ON order_review_actions
    FOR SELECT USING (
        performed_by = auth.uid()
        OR has_permission('payment.confirm')
        OR has_permission('pos.sale')
    );

-- ============================================================
-- Order Fulfillments
-- ============================================================
CREATE POLICY "order_fulfillments_select" ON order_fulfillments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_fulfillments.order_id
            AND (o.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
                 OR o.branch_id = ANY(user_branch_ids())
                 OR has_permission('payment.confirm')
                 OR has_permission('pos.sale'))
        )
    );
