-- Migration 00000007_create_inventory_tables.sql
-- Creates inventory tables per section 6.

-- ============================================================
-- Inventory Locations
-- ============================================================
CREATE TABLE inventory_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    code TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('RETAIL', 'CLINIC_PHARMACY', 'WAREHOUSE')),
    name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (branch_id, code)
);

-- Partial unique index: exactly one RETAIL location per branch
CREATE UNIQUE INDEX idx_inventory_locations_retail_unique
    ON inventory_locations (branch_id) WHERE (type = 'RETAIL');

-- Partial unique index: exactly one CLINIC_PHARMACY location per branch
CREATE UNIQUE INDEX idx_inventory_locations_clinic_unique
    ON inventory_locations (branch_id) WHERE (type = 'CLINIC_PHARMACY');

-- ============================================================
-- Inventory Lots
-- ============================================================
CREATE TABLE inventory_lots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    lot_number TEXT NOT NULL,
    expiry_date DATE,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    received_by UUID,
    UNIQUE (product_id, location_id, lot_number)
);

-- ============================================================
-- Stock Balances
-- ============================================================
CREATE TABLE stock_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    on_hand NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (on_hand >= 0),
    reserved NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (reserved >= 0 AND reserved <= on_hand),
    UNIQUE (product_id, location_id, lot_id)
);

-- ============================================================
-- Inventory Movements (append-only)
-- ============================================================
CREATE TABLE inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    quantity_delta NUMERIC(14,3) NOT NULL CHECK (quantity_delta <> 0),
    movement_type TEXT NOT NULL CHECK (movement_type IN (
        'PURCHASE_RECEIPT', 'SALE_POS', 'ORDER_FULFILLMENT', 'RESERVATION',
        'RESERVATION_RELEASE', 'CLINIC_USE', 'CUSTOMER_RETURN_RESTOCK',
        'CUSTOMER_RETURN_WRITE_OFF', 'SUPPLIER_RETURN', 'ADJUSTMENT',
        'TRANSFER_OUT', 'TRANSFER_IN', 'TRANSFER_DISCREPANCY', 'EXPIRY_WRITE_OFF'
    )),
    reference_type TEXT,
    reference_id UUID,
    unit_cost_snapshot NUMERIC(14,4),
    reason_code TEXT,
    actor_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Stock Reservations (append-only after creation)
-- ============================================================
CREATE TABLE stock_reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL UNIQUE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'RELEASED', 'FULFILLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Inventory Adjustments
-- ============================================================
CREATE TABLE inventory_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    quantity_delta NUMERIC(14,3) NOT NULL CHECK (quantity_delta <> 0),
    reason_code TEXT NOT NULL CHECK (reason_code IN (
        'COUNT_CORRECTION', 'DAMAGED', 'EXPIRY_WRITE_OFF', 'LOST', 'FOUND',
        'CLINIC_USE_CORRECTION', 'OTHER'
    )),
    reason_note TEXT,
    unit_cost NUMERIC(14,4),
    adjusted_by UUID,
    adjusted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Count Sessions
-- ============================================================
CREATE TABLE count_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ,
    closed_by UUID
);

CREATE TABLE count_session_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES count_sessions(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    expected_quantity NUMERIC(14,3) NOT NULL,
    counted_quantity NUMERIC(14,3) NOT NULL,
    difference NUMERIC(14,3) NOT NULL,
    note TEXT
);

-- ============================================================
-- Inventory Transfers
-- ============================================================
CREATE TABLE inventory_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    from_location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    to_location_id UUID NOT NULL REFERENCES inventory_locations(id) ON DELETE RESTRICT,
    to_branch_id UUID REFERENCES branches(id) ON DELETE RESTRICT,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'APPROVED', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED')),
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    dispatched_at TIMESTAMPTZ,
    dispatched_by UUID,
    received_at TIMESTAMPTZ,
    received_by UUID
);

CREATE TABLE inventory_transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id UUID NOT NULL REFERENCES inventory_transfers(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    lot_id UUID NOT NULL REFERENCES inventory_lots(id) ON DELETE RESTRICT,
    quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
    received_quantity NUMERIC(14,3),
    discrepancy_reason TEXT
);

-- ============================================================
-- Product Branch Costs
-- ============================================================
CREATE TABLE product_branch_costs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    avg_unit_cost NUMERIC(14,4) NOT NULL DEFAULT 0 CHECK (avg_unit_cost >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by UUID,
    UNIQUE (product_id, branch_id)
);

-- ============================================================
-- Cost History (append-only)
-- ============================================================
CREATE TABLE cost_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    old_avg_cost NUMERIC(14,4),
    new_avg_cost NUMERIC(14,4),
    quantity_changed NUMERIC(14,3),
    unit_cost NUMERIC(14,4),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by UUID,
    reference_type TEXT,
    reference_id UUID
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_stock_balances_location_product ON stock_balances(location_id, product_id);
CREATE INDEX idx_inventory_movements_product ON inventory_movements(product_id, location_id, occurred_at);
CREATE INDEX idx_inventory_transfers_status ON inventory_transfers(status);
CREATE INDEX idx_inventory_lots_expiry ON inventory_lots(expiry_date);