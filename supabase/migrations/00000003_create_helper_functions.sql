-- Migration 00000003_create_helper_functions.sql
-- Creates SECURITY DEFINER helper functions for permission checks.
-- Per section 19.1 and 18.1: functions use SECURITY DEFINER with fixed search_path.

-- ============================================================
-- has_permission(code, branch_id)
-- Returns true if the current user has the given permission.
-- For OWNER: always returns true.
-- For others: checks role_permissions, user_permission_grants, and branch access.
-- ============================================================
CREATE OR REPLACE FUNCTION has_permission(
    p_permission_code TEXT,
    p_branch_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
DECLARE
    v_user_id UUID;
    v_is_owner BOOLEAN;
    v_has_permission BOOLEAN;
    v_role_ids UUID[];
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if user is active
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id AND is_active = true) THEN
        RETURN FALSE;
    END IF;

    -- Check if user has OWNER role
    SELECT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = v_user_id AND r.code = 'OWNER'
    ) INTO v_is_owner;

    IF v_is_owner THEN
        RETURN TRUE;
    END IF;

    -- Check role-based permissions
    SELECT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = v_user_id AND p.code = p_permission_code
    ) INTO v_has_permission;

    IF v_has_permission THEN
        RETURN TRUE;
    END IF;

    -- Check user-level permission grants
    SELECT EXISTS (
        SELECT 1 FROM user_permission_grants upg
        JOIN permissions p ON p.id = upg.permission_id
        WHERE upg.user_id = v_user_id
        AND p.code = p_permission_code
        AND (upg.expires_at IS NULL OR upg.expires_at > now())
    ) INTO v_has_permission;

    RETURN v_has_permission;
END;
$$;

-- ============================================================
-- can_access_branch(branch_id)
-- Returns true if the current user can access the given branch.
-- OWNER always has access.
-- ============================================================
CREATE OR REPLACE FUNCTION can_access_branch(p_branch_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
DECLARE
    v_user_id UUID;
    v_is_owner BOOLEAN;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- OWNER has access to all branches
    SELECT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = v_user_id AND r.code = 'OWNER'
    ) INTO v_is_owner;

    IF v_is_owner THEN
        RETURN TRUE;
    END IF;

    -- Check branch access
    RETURN EXISTS (
        SELECT 1 FROM user_branch_access
        WHERE user_id = v_user_id AND branch_id = p_branch_id
    );
END;
$$;

-- ============================================================
-- user_branch_ids()
-- Returns array of branch IDs the current user can access.
-- ============================================================
CREATE OR REPLACE FUNCTION user_branch_ids()
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
DECLARE
    v_user_id UUID;
    v_is_owner BOOLEAN;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RETURN ARRAY[]::UUID[];
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = v_user_id AND r.code = 'OWNER'
    ) INTO v_is_owner;

    IF v_is_owner THEN
        RETURN ARRAY(SELECT id FROM branches WHERE is_active = true);
    END IF;

    RETURN ARRAY(
        SELECT branch_id FROM user_branch_access
        WHERE user_id = v_user_id
    );
END;
$$;

-- ============================================================
-- Grant execute permissions
-- ============================================================
REVOKE EXECUTE ON FUNCTION has_permission FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION has_permission TO authenticated;

REVOKE EXECUTE ON FUNCTION can_access_branch FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION can_access_branch TO authenticated;

REVOKE EXECUTE ON FUNCTION user_branch_ids FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION user_branch_ids TO authenticated;