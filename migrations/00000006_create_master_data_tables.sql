-- Migration 00000006_create_master_data_tables.sql
-- Creates customers, pets, products, and supplier tables per section 5.

-- ============================================================
-- Customers
-- ============================================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Customer Addresses
-- ============================================================
CREATE TABLE customer_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    label TEXT,
    address TEXT NOT NULL,
    city TEXT,
    province TEXT,
    postal_code TEXT,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Pets
-- ============================================================
CREATE TABLE pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES customers(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    species TEXT NOT NULL CHECK (species IN ('DOG', 'CAT', 'BIRD', 'RABBIT', 'REPTILE', 'OTHER')),
    breed TEXT,
    sex TEXT CHECK (sex IN ('MALE', 'FEMALE', 'UNKNOWN')),
    is_neutered BOOLEAN NOT NULL DEFAULT false,
    birth_date DATE,
    birth_date_is_estimate BOOLEAN NOT NULL DEFAULT false,
    microchip TEXT,
    is_deceased BOOLEAN NOT NULL DEFAULT false,
    deceased_at TIMESTAMPTZ,
    color TEXT,
    weight_kg NUMERIC(14,3),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Pet Guardians
-- ============================================================
CREATE TABLE pet_guardians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    UNIQUE (pet_id, customer_id)
);

-- Partial unique index: exactly one primary guardian per active pet
CREATE UNIQUE INDEX idx_pet_guardians_primary_unique
    ON pet_guardians (pet_id)
    WHERE (is_primary = true);

-- ============================================================
-- Pet Documents
-- ============================================================
CREATE TABLE pet_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE RESTRICT,
    document_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    uploaded_by UUID
);

-- ============================================================
-- Product Categories
-- ============================================================
CREATE TABLE product_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Products
-- ============================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES product_categories(id) ON DELETE RESTRICT,
    unit_type TEXT NOT NULL CHECK (unit_type IN ('COUNT', 'WEIGHT')),
    base_unit TEXT NOT NULL,
    track_lot BOOLEAN NOT NULL DEFAULT false,
    is_prescription BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Product Barcodes
-- ============================================================
CREATE TABLE product_barcodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    barcode TEXT NOT NULL UNIQUE,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Product Branch Settings
-- ============================================================
CREATE TABLE product_branch_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    is_pos_sellable BOOLEAN NOT NULL DEFAULT false,
    is_online_sellable BOOLEAN NOT NULL DEFAULT false,
    min_stock NUMERIC(14,3) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,
    updated_by UUID,
    UNIQUE (product_id, branch_id)
);

-- ============================================================
-- Product Prices (append-only)
-- ============================================================
CREATE TABLE product_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    price NUMERIC(14,2) NOT NULL CHECK (price >= 0),
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Suppliers
-- ============================================================
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    contact_name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    tax_id TEXT,
    payment_terms_days INTEGER NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID
);

-- ============================================================
-- Payment Methods (global)
-- ============================================================
CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Branch Payment Accounts
-- ============================================================
CREATE TABLE branch_payment_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    payment_method_id UUID NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
    account_name TEXT NOT NULL,
    account_number TEXT,
    instructions TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (branch_id, payment_method_id)
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_product_barcodes_barcode ON product_barcodes(barcode);
CREATE INDEX idx_product_branch_settings_branch ON product_branch_settings(branch_id, is_active);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_pets_customer ON pets(customer_id);
CREATE INDEX idx_pet_guardians_pet ON pet_guardians(pet_id);