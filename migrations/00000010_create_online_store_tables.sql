-- Migration 00000010_create_online_store_tables.sql
-- Creates online store tables per section 9.

-- ============================================================
-- Customer Carts
-- ============================================================
CREATE TABLE customer_carts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (customer_id, branch_id)
);

CREATE TABLE customer_cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id UUID NOT NULL REFERENCES customer_carts(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- ============================================================
-- Orders
-- ============================================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    payment_status TEXT NOT NULL CHECK (payment_status IN (
        'UNPAID', 'SUBMITTED', 'CONFIRMED', 'REFUND_PENDING', 'REFUNDED'
    )),
    fulfillment_status TEXT NOT NULL CHECK (fulfillment_status IN (
        'NOT_STARTED', 'STOCK_REVIEW', 'PROCESSING', 'READY_FOR_PICKUP',
        'DISPATCHED', 'COMPLETED', 'CANCELLED'
    )),
    subtotal NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    delivery_fee NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    grand_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (grand_total >= 0),
    delivery_type TEXT NOT NULL CHECK (delivery_type IN ('PICKUP', 'DELIVERY')),
    delivery_address TEXT,
    payment_instructions_snapshot JSONB,
    stock_review_details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
    line_total NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (line_total >= 0),
    product_name_snapshot TEXT NOT NULL,
    sku_snapshot TEXT NOT NULL,
    unit_cost_snapshot NUMERIC(14,4)
);

-- ============================================================
-- Payments (append-only)
-- ============================================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    method_id UUID NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
    amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL CHECK (status IN ('SUBMITTED', 'CONFIRMED', 'REJECTED')),
    proof_path TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    confirmed_by UUID,
    confirmed_at TIMESTAMPTZ,
    rejection_reason TEXT
);

-- Partial unique index: one SUBMITTED or CONFIRMED payment per order
CREATE UNIQUE INDEX idx_payments_one_submitted_or_confirmed
    ON payments (order_id) WHERE (status IN ('SUBMITTED', 'CONFIRMED'));

-- ============================================================
-- Order Review Actions
-- ============================================================
CREATE TABLE order_review_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    action TEXT NOT NULL CHECK (action IN (
        'PARTIAL_FULFILL', 'SUBSTITUTE', 'CANCEL_AND_REFUND'
    )),
    details JSONB NOT NULL,
    performed_by UUID NOT NULL,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Order Fulfillments
-- ============================================================
CREATE TABLE order_fulfillments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    type TEXT NOT NULL CHECK (type IN ('PICKUP', 'DELIVERY')),
    recipient_name TEXT NOT NULL,
    recipient_address TEXT,
    dispatched_at TIMESTAMPTZ,
    dispatched_by UUID,
    delivered_at TIMESTAMPTZ,
    received_by UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_orders_branch_fulfillment ON orders(branch_id, fulfillment_status);
CREATE INDEX idx_orders_customer ON orders(customer_id, created_at);
CREATE INDEX idx_payments_order_status ON payments(order_id, status);