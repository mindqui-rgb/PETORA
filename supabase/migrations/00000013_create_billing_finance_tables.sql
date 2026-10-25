-- Migration 00000013_create_billing_finance_tables.sql
-- Creates service invoice, payment, expense, and financial period tables per section 13 and 14.

-- ============================================================
-- Service Invoices
-- ============================================================
CREATE TABLE service_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    source_type TEXT NOT NULL CHECK (source_type IN (
        'VISIT', 'HOSPITALIZATION', 'GROOMING', 'BOARDING'
    )),
    source_id UUID NOT NULL,
    invoice_number TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'PARTIALLY_PAID', 'PAID', 'VOIDED')),
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    discount_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
    grand_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (grand_total >= 0),
    amount_paid NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    balance_due NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance_due >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_at TIMESTAMPTZ,
    updated_by UUID
);

CREATE TABLE service_invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES service_invoices(id) ON DELETE RESTRICT,
    item_type TEXT NOT NULL CHECK (item_type IN (
        'CONSULTATION', 'TREATMENT', 'MEDICATION', 'SUPPLY',
        'BOARDING_DAY', 'GROOMING', 'ADDON', 'OTHER'
    )),
    source_type TEXT,
    source_id UUID,
    description TEXT NOT NULL,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    line_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (line_total >= 0),
    unit_cost_snapshot NUMERIC(14,4)
);

-- ============================================================
-- Service Payments (append-only)
-- ============================================================
CREATE TABLE service_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES service_invoices(id) ON DELETE RESTRICT,
    method_id UUID REFERENCES payment_methods(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount <> 0),
    paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by UUID,
    reference TEXT
);

-- ============================================================
-- Customer Credits
-- ============================================================
CREATE TABLE customer_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    source_type TEXT NOT NULL,
    source_id UUID,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    used_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (used_amount >= 0 AND used_amount <= amount),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Operating Expenses
-- ============================================================
CREATE TABLE operating_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    category TEXT NOT NULL,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL,
    requested_by UUID NOT NULL,
    approved_by UUID,
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PAID')),
    period_id UUID,
    receipt_path TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Financial Periods
-- ============================================================
CREATE TABLE financial_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL CHECK (period_end >= period_start),
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')),
    closed_by UUID,
    closed_at TIMESTAMPTZ,
    summary JSONB,
    UNIQUE (branch_id, period_start, period_end)
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_service_invoices_customer ON service_invoices(customer_id, status);
CREATE INDEX idx_service_invoices_branch ON service_invoices(branch_id, status);
CREATE INDEX idx_operating_expenses_branch ON operating_expenses(branch_id, expense_date);
CREATE INDEX idx_financial_periods_branch ON financial_periods(branch_id, status);