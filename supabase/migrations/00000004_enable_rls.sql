-- Migration 00000004_enable_rls.sql
-- Enables Row Level Security on all business tables and creates basic policies.
-- Per section 19.1 and 19.2.

-- ============================================================
-- Enable RLS
-- ============================================================
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE branch_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_branch_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permission_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limit_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Branches: OWNER can read all, others only assigned branches
-- ============================================================
CREATE POLICY "branches_select" ON branches
    FOR SELECT
    USING (
        is_active = true
        AND (
            has_permission('branch.manage')
            OR id = ANY(user_branch_ids())
        )
    );

CREATE POLICY "branches_insert" ON branches
    FOR INSERT
    WITH CHECK (has_permission('branch.manage'));

CREATE POLICY "branches_update" ON branches
    FOR UPDATE
    USING (has_permission('branch.manage'))
    WITH CHECK (has_permission('branch.manage'));

-- ============================================================
-- Branch Settings
-- ============================================================
CREATE POLICY "branch_settings_select" ON branch_settings
    FOR SELECT
    USING (
        has_permission('settings.manage')
        OR branch_id = ANY(user_branch_ids())
    );

CREATE POLICY "branch_settings_insert" ON branch_settings
    FOR INSERT
    WITH CHECK (has_permission('settings.manage'));

CREATE POLICY "branch_settings_update" ON branch_settings
    FOR UPDATE
    USING (has_permission('settings.manage'))
    WITH CHECK (has_permission('settings.manage'));

-- ============================================================
-- Profiles
-- ============================================================
CREATE POLICY "profiles_select" ON profiles
    FOR SELECT
    USING (
        id = auth.uid()
        OR has_permission('users.manage')
    );

CREATE POLICY "profiles_insert" ON profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update" ON profiles
    FOR UPDATE
    USING (id = auth.uid() OR has_permission('users.manage'))
    WITH CHECK (id = auth.uid() OR has_permission('users.manage'));

-- ============================================================
-- Roles and Permissions (read-only for non-owner)
-- ============================================================
CREATE POLICY "roles_select" ON roles FOR SELECT USING (true);
CREATE POLICY "permissions_select" ON permissions FOR SELECT USING (true);
CREATE POLICY "role_permissions_select" ON role_permissions FOR SELECT USING (true);

-- ============================================================
-- User Roles
-- ============================================================
CREATE POLICY "user_roles_select" ON user_roles
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR has_permission('users.manage')
    );

CREATE POLICY "user_roles_insert" ON user_roles
    FOR INSERT
    WITH CHECK (has_permission('users.manage'));

-- ============================================================
-- User Branch Access
-- ============================================================
CREATE POLICY "user_branch_access_select" ON user_branch_access
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR has_permission('users.manage')
    );

CREATE POLICY "user_branch_access_insert" ON user_branch_access
    FOR INSERT
    WITH CHECK (has_permission('users.manage'));

-- ============================================================
-- User Permission Grants
-- ============================================================
CREATE POLICY "user_permission_grants_select" ON user_permission_grants
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR has_permission('users.manage')
    );

CREATE POLICY "user_permission_grants_insert" ON user_permission_grants
    FOR INSERT
    WITH CHECK (has_permission('users.manage'));

-- ============================================================
-- Doctor Profiles
-- ============================================================
CREATE POLICY "doctor_profiles_select" ON doctor_profiles
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR has_permission('users.manage')
    );

CREATE POLICY "doctor_profiles_insert" ON doctor_profiles
    FOR INSERT
    WITH CHECK (has_permission('users.manage'));

CREATE POLICY "doctor_profiles_update" ON doctor_profiles
    FOR UPDATE
    USING (has_permission('users.manage'))
    WITH CHECK (has_permission('users.manage'));

-- ============================================================
-- Invitations
-- ============================================================
CREATE POLICY "invitations_select" ON invitations
    FOR SELECT USING (has_permission('users.manage'));

CREATE POLICY "invitations_insert" ON invitations
    FOR INSERT WITH CHECK (has_permission('users.manage'));

-- ============================================================
-- Audit Logs
-- ============================================================
CREATE POLICY "audit_logs_select" ON audit_logs
    FOR SELECT USING (has_permission('audit.read'));

-- ============================================================
-- Idempotency Keys
-- ============================================================
CREATE POLICY "idempotency_keys_select" ON idempotency_keys
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "idempotency_keys_insert" ON idempotency_keys
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================================
-- Rate Limit Counters (service-level access only)
-- ============================================================
CREATE POLICY "rate_limit_counters_all" ON rate_limit_counters FOR ALL USING (false);

-- ============================================================
-- Job Runs (read-only for owner)
-- ============================================================
CREATE POLICY "job_runs_select" ON job_runs
    FOR SELECT USING (has_permission('settings.manage'));

-- ============================================================
-- Notifications
-- ============================================================
CREATE POLICY "notifications_select" ON notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update" ON notifications
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());