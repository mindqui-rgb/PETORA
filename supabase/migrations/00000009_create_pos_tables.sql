-- Migration 00000009_create_pos_tables.sql
-- Creates POS tables per section 8.

-- ============================================================
-- Cash Shifts
-- ============================================================
CREATE TABLE cash_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    cashier_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')),
    opening_cash NUMERIC(14,2) NOT NULL CHECK (opening_cash >= 0),
    closing_cash_counted NUMERIC(14,2),
    difference NUMERIC(14,2),
    difference_reason TEXT,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    closed_by UUID
);

-- Partial unique index: one open shift per cashier
CREATE UNIQUE INDEX idx_cash_shifts_one_open_per_cashier
    ON cash_shifts (cashier_id) WHERE (status = 'OPEN');

-- ============================================================
-- Sales
-- ============================================================
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    shift_id UUID NOT NULL REFERENCES cash_shifts(id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES customers(id) ON DELETE RESTRICT,
    invoice_number TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL CHECK (status IN (
        'DRAFT', 'COMPLETED', 'PARTIALLY_RETURNED', 'RETURNED', 'VOIDED'
    )),
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    discount_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
    grand_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (grand_total >= 0),
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    completed_by UUID
);

-- ============================================================
-- Sale Items
-- ============================================================
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_type TEXT CHECK (discount_type IN ('PERCENT', 'AMOUNT')),
    discount_value NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_value >= 0),
    line_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (line_total >= 0),
    unit_cost_snapshot NUMERIC(14,4),
    lot_id UUID REFERENCES inventory_lots(id) ON DELETE RESTRICT
);

-- ============================================================
-- Sale Payments (append-only)
-- ============================================================
CREATE TABLE sale_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
    method_id UUID NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    tendered_amount NUMERIC(14,2),
    change_amount NUMERIC(14,2),
    reference_number TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Sales Returns
-- ============================================================
CREATE TABLE sales_returns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    reason TEXT NOT NULL,
    refund_id UUID,
    status TEXT NOT NULL CHECK (status IN ('REQUESTED', 'APPROVED', 'COMPLETED', 'REJECTED')),
    requested_by UUID,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE TABLE sales_return_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sales_return_id UUID NOT NULL REFERENCES sales_returns(id) ON DELETE RESTRICT,
    sale_item_id UUID NOT NULL REFERENCES sale_items(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    condition TEXT NOT NULL CHECK (condition IN ('RESTOCK', 'DAMAGED')),
    lot_id UUID REFERENCES inventory_lots(id) ON DELETE RESTRICT
);

-- ============================================================
-- Refunds
-- ============================================================
CREATE TABLE refunds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_type TEXT NOT NULL CHECK (source_type IN ('SALE_RETURN', 'ORDER', 'SERVICE_INVOICE', 'OVERPAYMENT')),
    source_id UUID NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN (
        'REQUESTED', 'APPROVED', 'REJECTED', 'COMPLETED'
    )),
    requested_by UUID NOT NULL,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    completed_by UUID,
    completed_at TIMESTAMPTZ,
    payout_method TEXT,
    payout_reference TEXT
);

-- ============================================================
-- Invoice Sequences
-- ============================================================
CREATE TABLE invoice_sequences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    doc_type TEXT NOT NULL,
    year INTEGER NOT NULL,
    last_number INTEGER NOT NULL DEFAULT 0,
    UNIQUE (branch_id, doc_type, year)
);

-- ============================================================
-- Cash Movements (append-only)
-- ============================================================
CREATE TABLE cash_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    shift_id UUID REFERENCES cash_shifts(id) ON DELETE RESTRICT,
    movement_type TEXT NOT NULL CHECK (movement_type IN (
        'CASH_IN_SALE', 'CASH_IN_ONLINE', 'CASH_IN_SERVICE',
        'CASH_OUT_REFUND', 'CASH_OUT_EXPENSE', 'CASH_OUT_SUPPLIER',
        'SHIFT_OPENING', 'SHIFT_CLOSING_DIFFERENCE'
    )),
    method_id UUID REFERENCES payment_methods(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount <> 0),
    reference_type TEXT,
    reference_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_sales_branch_completed ON sales(branch_id, completed_at);
CREATE INDEX idx_cash_shifts_branch ON cash_shifts(branch_id);
CREATE INDEX idx_cash_movements_branch ON cash_movements(branch_id, occurred_at);
CREATE INDEX idx_refunds_status ON refunds(status);