-- Migration 00000016_rls_inventory_pos.sql
-- Row Level Security policies for inventory and POS tables per section 19.2.

-- ============================================================
-- Inventory Locations
-- ============================================================
CREATE POLICY "inventory_locations_select" ON inventory_locations
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('inventory.read')
    );

CREATE POLICY "inventory_locations_insert" ON inventory_locations
    FOR INSERT WITH CHECK (has_permission('inventory.read'));

-- ============================================================
-- Inventory Lots
-- ============================================================
CREATE POLICY "inventory_lots_select" ON inventory_lots
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM inventory_locations il WHERE il.id = inventory_lots.location_id AND il.branch_id = ANY(user_branch_ids()))
        OR has_permission('inventory.read')
    );

-- ============================================================
-- Stock Balances
-- ============================================================
CREATE POLICY "stock_balances_select" ON stock_balances
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM inventory_locations il WHERE il.id = stock_balances.location_id AND il.branch_id = ANY(user_branch_ids()))
        OR has_permission('inventory.read')
    );

-- ============================================================
-- Inventory Movements
-- ============================================================
CREATE POLICY "inventory_movements_select" ON inventory_movements
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM inventory_locations il WHERE il.id = inventory_movements.location_id AND il.branch_id = ANY(user_branch_ids()))
        OR has_permission('inventory.read')
    );

-- ============================================================
-- Stock Reservations
-- ============================================================
CREATE POLICY "stock_reservations_select" ON stock_reservations
    FOR SELECT USING (has_permission('inventory.read'));

-- ============================================================
-- Inventory Adjustments
-- ============================================================
CREATE POLICY "inventory_adjustments_select" ON inventory_adjustments
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('inventory.adjust')
    );

CREATE POLICY "inventory_adjustments_insert" ON inventory_adjustments
    FOR INSERT WITH CHECK (has_permission('inventory.adjust'));

-- ============================================================
-- Count Sessions
-- ============================================================
CREATE POLICY "count_sessions_select" ON count_sessions
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('inventory.read')
    );

CREATE POLICY "count_sessions_insert" ON count_sessions
    FOR INSERT WITH CHECK (has_permission('inventory.adjust'));

-- ============================================================
-- Inventory Transfers
-- ============================================================
CREATE POLICY "inventory_transfers_select" ON inventory_transfers
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('inventory.transfer')
        OR has_permission('inventory.transfer.approve')
    );

CREATE POLICY "inventory_transfers_insert" ON inventory_transfers
    FOR INSERT WITH CHECK (
        has_permission('inventory.transfer')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Product Branch Costs
-- ============================================================
CREATE POLICY "product_branch_costs_select" ON product_branch_costs
    FOR SELECT USING (
        has_permission('inventory.read_cost')
        OR has_permission('finance.report.read')
    );

-- ============================================================
-- Cost History
-- ============================================================
CREATE POLICY "cost_history_select" ON cost_history
    FOR SELECT USING (
        has_permission('inventory.read_cost')
        OR has_permission('finance.report.read')
    );

-- ============================================================
-- Purchase Orders
-- ============================================================
CREATE POLICY "purchase_orders_select" ON purchase_orders
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('purchase.manage')
    );

CREATE POLICY "purchase_orders_insert" ON purchase_orders
    FOR INSERT WITH CHECK (
        has_permission('purchase.manage')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Goods Receipts
-- ============================================================
CREATE POLICY "goods_receipts_select" ON goods_receipts
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('purchase.manage')
    );

-- ============================================================
-- Supplier Returns
-- ============================================================
CREATE POLICY "supplier_returns_select" ON supplier_returns
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('purchase.manage')
    );

-- ============================================================
-- Supplier Bills
-- ============================================================
CREATE POLICY "supplier_bills_select" ON supplier_bills
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('purchase.manage')
    );

-- ============================================================
-- Cash Shifts
-- ============================================================
CREATE POLICY "cash_shifts_select" ON cash_shifts
    FOR SELECT USING (
        cashier_id = auth.uid()
        OR branch_id = ANY(user_branch_ids())
        OR has_permission('cash_shift.manage')
    );

CREATE POLICY "cash_shifts_insert" ON cash_shifts
    FOR INSERT WITH CHECK (
        has_permission('cash_shift.manage')
        AND cashier_id = auth.uid()
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Sales
-- ============================================================
CREATE POLICY "sales_select" ON sales
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('pos.sale')
        OR has_permission('pos.return.request')
    );

CREATE POLICY "sales_insert" ON sales
    FOR INSERT WITH CHECK (
        has_permission('pos.sale')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Sale Items
-- ============================================================
CREATE POLICY "sale_items_select" ON sale_items
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM sales s WHERE s.id = sale_items.sale_id AND s.branch_id = ANY(user_branch_ids()))
        OR has_permission('pos.sale')
    );

CREATE POLICY "sale_items_insert" ON sale_items
    FOR INSERT WITH CHECK (has_permission('pos.sale'));

-- ============================================================
-- Sale Payments
-- ============================================================
CREATE POLICY "sale_payments_select" ON sale_payments
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM sales s WHERE s.id = sale_payments.sale_id AND s.branch_id = ANY(user_branch_ids()))
        OR has_permission('pos.sale')
    );

CREATE POLICY "sale_payments_insert" ON sale_payments
    FOR INSERT WITH CHECK (has_permission('pos.sale'));

-- ============================================================
-- Sales Returns
-- ============================================================
CREATE POLICY "sales_returns_select" ON sales_returns
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('pos.return.request')
        OR has_permission('refund.approve')
    );

CREATE POLICY "sales_returns_insert" ON sales_returns
    FOR INSERT WITH CHECK (
        has_permission('pos.return.request')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Refunds
-- ============================================================
CREATE POLICY "refunds_select" ON refunds
    FOR SELECT USING (
        requested_by = auth.uid()
        OR has_permission('refund.approve')
        OR has_permission('refund.complete')
    );

CREATE POLICY "refunds_insert" ON refunds
    FOR INSERT WITH CHECK (
        has_permission('refund.request')
        AND requested_by = auth.uid()
    );

-- ============================================================
-- Cash Movements
-- ============================================================
CREATE POLICY "cash_movements_select" ON cash_movements
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('finance.cash.read')
    );

-- ============================================================
-- Invoice Sequences
-- ============================================================
CREATE POLICY "invoice_sequences_select" ON invoice_sequences
    FOR SELECT USING (branch_id = ANY(user_branch_ids()) OR has_permission('settings.manage'));
