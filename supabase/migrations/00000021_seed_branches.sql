-- Migration 00000021_seed_branches.sql
-- Seeds initial branches for development and testing.

INSERT INTO branches (id, code, name, timezone, is_active) VALUES
    ('11111111-1111-1111-1111-111111111111', 'UTM', 'Utama', 'Asia/Jakarta', true),
    ('22222222-2222-2222-2222-222222222222', 'MLG', 'Maling', 'Asia/Makassar', true),
    ('33333333-3333-3333-3333-333333333333', 'JPR', 'Jayapura', 'Asia/Jayapura', true)
ON CONFLICT (code) DO NOTHING;

-- Seed branch settings
INSERT INTO branch_settings (branch_id, delivery_fee, operating_hours_start, operating_hours_end, address, phone, email) VALUES
    ('11111111-1111-1111-1111-111111111111', 50000, '08:00', '20:00', 'Jl. Contoh No. 123, Jakarta', '021-1234567', 'utm@petshop.example.com'),
    ('22222222-2222-2222-2222-222222222222', 75000, '08:00', '21:00', 'Jl. Contoh No. 456, Makassar', '0411-7654321', 'mlg@petshop.example.com'),
    ('33333333-3333-3333-3333-333333333333', 100000, '08:00', '22:00', 'Jl. Contoh No. 789, Jayapura', '0967-123456', 'jpr@petshop.example.com')
ON CONFLICT DO NOTHING;

-- Seed payment methods
INSERT INTO payment_methods (code, name, is_active) VALUES
    ('CASH', 'Tunai', true),
    ('BANK_TRANSFER', 'Transfer Bank', true),
    ('QRIS', 'QRIS', true),
    ('CREDIT', 'Kredit', true)
ON CONFLICT (code) DO NOTHING;

-- Seed branch payment accounts
INSERT INTO branch_payment_accounts (branch_id, payment_method_id, account_name, account_number, instructions) VALUES
    ('11111111-1111-1111-1111-111111111111',
     (SELECT id FROM payment_methods WHERE code = 'BANK_TRANSFER'),
     'Rek. Utama', '1234567890', 'Transfer ke BCA a/n Petshop Utama'),
    ('11111111-1111-1111-1111-111111111111',
     (SELECT id FROM payment_methods WHERE code = 'QRIS'),
     'QRIS Utama', NULL, 'Scan QRIS untuk pembayaran'),
    ('22222222-2222-2222-2222-222222222222',
     (SELECT id FROM payment_methods WHERE code = 'BANK_TRANSFER'),
     'Rek. Maling', '9876543210', 'Transfer ke BCA a/n Petshop Maling'),
    ('33333333-3333-3333-3333-333333333333',
     (SELECT id FROM payment_methods WHERE code = 'BANK_TRANSFER'),
     'Rek. Jayapura', '555566667777', 'Transfer ke BCA a/n Petshop Jayapura')
ON CONFLICT DO NOTHING;

-- Seed product categories
INSERT INTO product_categories (code, name) VALUES
    ('RETAIL', 'Retail'),
    ('MEDICINE', 'Medicine'),
    ('CLINIC_SUPPLY', 'Clinic Supply'),
    ('FOOD', 'Food'),
    ('ACCESSORY', 'Accessory'),
    ('OTHER', 'Other')
ON CONFLICT (code) DO NOTHING;

-- Seed service catalog
INSERT INTO service_catalog (code, name, category, duration_minutes, is_addon, is_active) VALUES
    ('CONSULT', 'Konsultasi', 'CLINIC', 30, false, true),
    ('GROOMING_FULL', 'Grooming Lengkapan', 'GROOMING', 120, false, true),
    ('GROOMING_BATH', 'Mandi & Sikat', 'GROOMING', 60, false, true),
    ('BOARDING_DAY', 'Penitipan Harian', 'BOARDING', 1440, false, true),
    ('VACCINE', 'Vaksinasi', 'CLINIC', 30, true, true)
ON CONFLICT (code) DO NOTHING;
