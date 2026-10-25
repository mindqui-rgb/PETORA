-- Migration 00000015_rls_master_data.sql
-- Row Level Security policies for master data tables per section 19.2.

-- ============================================================
-- Customers
-- ============================================================
CREATE POLICY "customers_select" ON customers
    FOR SELECT
    USING (
        auth_user_id = auth.uid()
        OR has_permission('customer.manage')
    );

CREATE POLICY "customers_insert" ON customers
    FOR INSERT
    WITH CHECK (
        has_permission('customer.manage')
        OR (auth_user_id IS NULL AND created_by IS NULL)
    );

CREATE POLICY "customers_update" ON customers
    FOR UPDATE
    USING (
        auth_user_id = auth.uid()
        OR has_permission('customer.manage')
    )
    WITH CHECK (
        auth_user_id = auth.uid()
        OR has_permission('customer.manage')
    );

-- ============================================================
-- Customer Addresses
-- ============================================================
CREATE POLICY "customer_addresses_select" ON customer_addresses
    FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM customers c WHERE c.id = customer_id AND c.auth_user_id = auth.uid())
        OR has_permission('customer.manage')
    );

CREATE POLICY "customer_addresses_insert" ON customer_addresses
    FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM customers c WHERE c.id = customer_id AND c.auth_user_id = auth.uid())
        OR has_permission('customer.manage')
    );

CREATE POLICY "customer_addresses_update" ON customer_addresses
    FOR UPDATE
    USING (
        EXISTS (SELECT 1 FROM customers c WHERE c.id = customer_id AND c.auth_user_id = auth.uid())
        OR has_permission('customer.manage')
    );

-- ============================================================
-- Pets
-- ============================================================
CREATE POLICY "pets_select" ON pets
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pet_guardians pg
            JOIN customers c ON c.id = pg.customer_id
            WHERE pg.pet_id = pets.id AND c.auth_user_id = auth.uid()
        )
        OR has_permission('pet.manage')
    );

CREATE POLICY "pets_insert" ON pets
    FOR INSERT
    WITH CHECK (has_permission('pet.manage'));

CREATE POLICY "pets_update" ON pets
    FOR UPDATE
    USING (has_permission('pet.manage'))
    WITH CHECK (has_permission('pet.manage'));

-- ============================================================
-- Pet Guardians
-- ============================================================
CREATE POLICY "pet_guardians_select" ON pet_guardians
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM customers c
            WHERE c.id = pet_guardians.customer_id AND c.auth_user_id = auth.uid()
        )
        OR has_permission('pet.manage')
    );

CREATE POLICY "pet_guardians_insert" ON pet_guardians
    FOR INSERT
    WITH CHECK (has_permission('pet.manage'));

CREATE POLICY "pet_guardians_update" ON pet_guardians
    FOR UPDATE
    USING (has_permission('pet.manage'))
    WITH CHECK (has_permission('pet.manage'));

-- ============================================================
-- Pet Documents
-- ============================================================
CREATE POLICY "pet_documents_select" ON pet_documents
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pet_guardians pg
            JOIN customers c ON c.id = pg.customer_id
            WHERE pg.pet_id = pet_documents.pet_id AND c.auth_user_id = auth.uid()
        )
        OR has_permission('pet.manage')
    );

CREATE POLICY "pet_documents_insert" ON pet_documents
    FOR INSERT
    WITH CHECK (has_permission('pet.manage'));

-- ============================================================
-- Products (public read for active products)
-- ============================================================
CREATE POLICY "products_select" ON products
    FOR SELECT USING (is_active = true OR has_permission('product.manage'));

CREATE POLICY "products_insert" ON products
    FOR INSERT WITH CHECK (has_permission('product.manage'));

CREATE POLICY "products_update" ON products
    FOR UPDATE USING (has_permission('product.manage'))
    WITH CHECK (has_permission('product.manage'));

-- ============================================================
-- Product Barcodes
-- ============================================================
CREATE POLICY "product_barcodes_select" ON product_barcodes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM products p WHERE p.id = product_barcodes.product_id AND (p.is_active = true OR has_permission('product.manage')))
    );

CREATE POLICY "product_barcodes_insert" ON product_barcodes
    FOR INSERT WITH CHECK (has_permission('product.manage'));

-- ============================================================
-- Product Branch Settings
-- ============================================================
CREATE POLICY "product_branch_settings_select" ON product_branch_settings
    FOR SELECT USING (
        has_permission('product.manage')
        OR has_permission('price.manage')
        OR is_pos_sellable = true
        OR is_online_sellable = true
    );

CREATE POLICY "product_branch_settings_insert" ON product_branch_settings
    FOR INSERT WITH CHECK (has_permission('product.manage'));

CREATE POLICY "product_branch_settings_update" ON product_branch_settings
    FOR UPDATE USING (has_permission('product.manage') OR has_permission('price.manage'))
    WITH CHECK (has_permission('product.manage') OR has_permission('price.manage'));

-- ============================================================
-- Product Prices
-- ============================================================
CREATE POLICY "product_prices_select" ON product_prices
    FOR SELECT USING (
        has_permission('price.manage')
        OR has_permission('inventory.read_cost')
        OR has_permission('finance.report.read')
    );

CREATE POLICY "product_prices_insert" ON product_prices
    FOR INSERT WITH CHECK (has_permission('price.manage'));

-- ============================================================
-- Suppliers
-- ============================================================
CREATE POLICY "suppliers_select" ON suppliers
    FOR SELECT USING (is_active = true OR has_permission('purchase.manage'));

CREATE POLICY "suppliers_insert" ON suppliers
    FOR INSERT WITH CHECK (has_permission('purchase.manage'));

CREATE POLICY "suppliers_update" ON suppliers
    FOR UPDATE USING (has_permission('purchase.manage'))
    WITH CHECK (has_permission('purchase.manage'));

-- ============================================================
-- Payment Methods
-- ============================================================
CREATE POLICY "payment_methods_select" ON payment_methods
    FOR SELECT USING (is_active = true OR has_permission('settings.manage'));

-- ============================================================
-- Branch Payment Accounts
-- ============================================================
CREATE POLICY "branch_payment_accounts_select" ON branch_payment_accounts
    FOR SELECT USING (
        has_permission('settings.manage')
        OR branch_id = ANY(user_branch_ids())
    );

CREATE POLICY "branch_payment_accounts_insert" ON branch_payment_accounts
    FOR INSERT WITH CHECK (has_permission('settings.manage'));

CREATE POLICY "branch_payment_accounts_update" ON branch_payment_accounts
    FOR UPDATE USING (has_permission('settings.manage'))
    WITH CHECK (has_permission('settings.manage'));