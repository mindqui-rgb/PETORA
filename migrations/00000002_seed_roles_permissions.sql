-- Migration 00000002_seed_roles_permissions.sql
-- Seeds default roles and permissions per section 4.1 of the specification.
-- This migration is idempotent using ON CONFLICT.

-- ============================================================
-- Permissions (from section 4.1)
-- ============================================================
INSERT INTO permissions (code, name, module, description) VALUES
    ('branch.manage', 'Manage Branches', 'MOD-02', 'Create, update, and deactivate branches'),
    ('users.manage', 'Manage Users', 'MOD-01', 'Create invitations, update profiles, grant permissions'),
    ('settings.manage', 'Manage Settings', 'MOD-17', 'Update system settings, templates, payment methods'),
    ('product.manage', 'Manage Products', 'MOD-04', 'Create and update product catalog'),
    ('price.manage', 'Manage Prices', 'MOD-04', 'Update product prices per branch'),
    ('inventory.read', 'Read Inventory', 'MOD-05', 'View inventory balances and movements'),
    ('inventory.read_cost', 'Read Inventory Cost', 'MOD-05', 'View unit costs and cost history'),
    ('inventory.adjust', 'Adjust Inventory', 'MOD-05', 'Apply stock adjustments'),
    ('inventory.transfer', 'Transfer Inventory', 'MOD-05', 'Create and manage transfers'),
    ('inventory.transfer.approve', 'Approve Transfers', 'MOD-05', 'Approve cross-branch transfers'),
    ('purchase.manage', 'Manage Purchases', 'MOD-06', 'Create and manage purchase orders'),
    ('pos.sale', 'POS Sale', 'MOD-07', 'Create and complete POS sales'),
    ('pos.discount.apply', 'Apply POS Discount', 'MOD-07', 'Apply discount up to 10%'),
    ('pos.discount.override', 'Override POS Discount', 'MOD-07', 'Apply discount above 10%'),
    ('pos.return.request', 'Request POS Return', 'MOD-07', 'Create sales returns'),
    ('cash_shift.manage', 'Manage Cash Shift', 'MOD-07', 'Open and close cash shifts'),
    ('payment.review', 'Review Payment', 'MOD-08', 'Review payment proofs'),
    ('payment.confirm', 'Confirm Payment', 'MOD-08', 'Confirm online order payments'),
    ('refund.request', 'Request Refund', 'MOD-13', 'Create refund requests'),
    ('refund.approve', 'Approve Refund', 'MOD-13', 'Approve refund requests'),
    ('refund.complete', 'Complete Refund', 'MOD-13', 'Complete refund payouts'),
    ('customer.manage', 'Manage Customers', 'MOD-03', 'Create and update customer records'),
    ('pet.manage', 'Manage Pets', 'MOD-03', 'Create and update pet records'),
    ('appointment.manage', 'Manage Appointments', 'MOD-09', 'Create and manage appointments'),
    ('schedule.manage', 'Manage Schedules', 'MOD-09', 'Manage doctor schedules'),
    ('grooming.manage', 'Manage Grooming', 'MOD-11', 'Manage grooming and boarding bookings'),
    ('visit.manage', 'Manage Visits', 'MOD-09', 'Create and manage visits'),
    ('medical_record.read', 'Read Medical Records', 'MOD-09', 'Read medical records'),
    ('medical_record.write', 'Write Medical Records', 'MOD-09', 'Create and edit draft medical records'),
    ('medical_record.sign', 'Sign Medical Records', 'MOD-09', 'Sign medical records'),
    ('medical_record.amend', 'Amend Medical Records', 'MOD-09', 'Amend signed medical records'),
    ('prescription.write', 'Write Prescriptions', 'MOD-09', 'Create and edit prescriptions'),
    ('clinic.medication.use', 'Use Clinic Medication', 'MOD-09', 'Dispense medications and supplies'),
    ('hospitalization.manage', 'Manage Hospitalization', 'MOD-10', 'Manage hospitalization episodes'),
    ('hospitalization.observe', 'Observe Hospitalization', 'MOD-10', 'Create care observations'),
    ('hospitalization.publish_update', 'Publish Hospitalization Update', 'MOD-10', 'Publish shared updates'),
    ('service_invoice.manage', 'Manage Service Invoice', 'MOD-12', 'Create and manage service invoices'),
    ('service_invoice.discount', 'Apply Service Invoice Discount', 'MOD-12', 'Apply discounts to service invoices'),
    ('service_invoice.void', 'Void Service Invoice', 'MOD-12', 'Void unpaid service invoices'),
    ('finance.cash.read', 'Read Cash', 'MOD-13', 'Read cash movements and balances'),
    ('finance.expense.create', 'Create Expense', 'MOD-13', 'Create operating expense records'),
    ('finance.expense.approve', 'Approve Expense', 'MOD-13', 'Approve operating expenses'),
    ('finance.report.read', 'Read Financial Reports', 'MOD-13', 'Read financial reports'),
    ('finance.period.close', 'Close Financial Period', 'MOD-13', 'Close financial periods'),
    ('report.sales.read', 'Read Sales Reports', 'MOD-16', 'Read sales reports'),
    ('audit.read', 'Read Audit Logs', 'MOD-01', 'Read audit logs')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- Roles
-- ============================================================
INSERT INTO roles (code, name, description) VALUES
    ('OWNER', 'Owner', 'Full system access'),
    ('DOCTOR', 'Doctor', 'Clinical and medical access'),
    ('ADMIN', 'Administrator', 'Operational and administrative access'),
    ('CUSTOMER', 'Customer', 'Customer portal access')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- Role-Permission mapping (section 4.1)
-- ============================================================
-- OWNER has all permissions
INSERT INTO role_permissions (role_id, permission_id)
    SELECT r.id, p.id FROM roles r, permissions p WHERE r.code = 'OWNER'
    ON CONFLICT DO NOTHING;

-- DOCTOR permissions
INSERT INTO role_permissions (role_id, permission_id)
    SELECT r.id, p.id FROM roles r, permissions p
    WHERE r.code = 'DOCTOR' AND p.code IN (
        'inventory.read',
        'appointment.manage',
        'visit.manage',
        'medical_record.read',
        'medical_record.write',
        'medical_record.sign',
        'medical_record.amend',
        'prescription.write',
        'clinic.medication.use',
        'hospitalization.manage',
        'hospitalization.observe',
        'hospitalization.publish_update'
    )
    ON CONFLICT DO NOTHING;

-- ADMIN permissions
INSERT INTO role_permissions (role_id, permission_id)
    SELECT r.id, p.id FROM roles r, permissions p
    WHERE r.code = 'ADMIN' AND p.code IN (
        'product.manage',
        'inventory.read',
        'inventory.transfer',
        'purchase.manage',
        'pos.sale',
        'pos.discount.apply',
        'pos.return.request',
        'cash_shift.manage',
        'payment.review',
        'payment.confirm',
        'refund.request',
        'customer.manage',
        'pet.manage',
        'appointment.manage',
        'schedule.manage',
        'grooming.manage',
        'hospitalization.manage',
        'service_invoice.manage',
        'finance.expense.create',
        'report.sales.read',
        'audit.read'
    )
    ON CONFLICT DO NOTHING;

-- CUSTOMER permissions
INSERT INTO role_permissions (role_id, permission_id)
    SELECT r.id, p.id FROM roles r, permissions p
    WHERE r.code = 'CUSTOMER' AND p.code IN (
        'medical_record.read'
    )
    ON CONFLICT DO NOTHING;