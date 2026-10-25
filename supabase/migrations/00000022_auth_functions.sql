-- Migration 00000022_auth_functions.sql
-- Authentication-related RPC functions per section 4.4 and 4.5.

-- ============================================================
-- setup_first_owner(email, password, display_name)
-- Creates the first OWNER account. Can only be run once per environment.
-- Per K25.
-- ============================================================
CREATE OR REPLACE FUNCTION setup_first_owner(
    p_email TEXT,
    p_password TEXT,
    p_display_name TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_owner_role_id UUID;
    v_existing_owner INTEGER;
BEGIN
    -- Check if owner already exists
    SELECT COUNT(*) INTO v_existing_owner
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE r.code = 'OWNER';

    IF v_existing_owner > 0 THEN
        RAISE EXCEPTION 'First owner already exists. Use invitation flow instead.';
    END IF;

    -- Validate password length
    IF LENGTH(p_password) < 10 THEN
        RAISE EXCEPTION 'Password must be at least 10 characters';
    END IF;

    -- Create auth user
    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
        id, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, confirmation_token, recovery_token
    ) VALUES (
        v_user_id,
        p_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        now(), now(),
        '', ''
    );

    -- Create profile
    INSERT INTO profiles (id, display_name, email, is_active)
    VALUES (v_user_id, p_display_name, p_email, true);

    -- Get owner role
    SELECT id INTO v_owner_role_id FROM roles WHERE code = 'OWNER';

    -- Assign owner role
    INSERT INTO user_roles (user_id, role_id, granted_by)
    VALUES (v_user_id, v_owner_role_id, v_user_id);

    -- Log audit
    INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, reason)
    VALUES (v_user_id, 'OWNER_SETUP', 'profiles', v_user_id, 'First owner setup');

    RETURN json_build_object(
        'user_id', v_user_id,
        'email', p_email,
        'role', 'OWNER'
    );
END;
$$;

-- ============================================================
-- create_invitation(email, role_code, branch_codes, expires_hours)
-- Creates an invitation for a new staff member.
-- Per section 4.5.
-- ============================================================
CREATE OR REPLACE FUNCTION create_invitation(
    p_email TEXT,
    p_role_code TEXT,
    p_branch_codes TEXT[],
    p_expires_hours INTEGER DEFAULT 72
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_inviter_id UUID;
    v_role_id UUID;
    v_token TEXT;
    v_expires_at TIMESTAMPTZ;
    v_branch_ids UUID[];
    v_invitation_id UUID;
BEGIN
    v_inviter_id := auth.uid();

    IF v_inviter_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT has_permission('users.manage') THEN
        RAISE EXCEPTION 'FORBIDDEN: Only users.manage can create invitations';
    END IF;

    SELECT id INTO v_role_id FROM roles WHERE code = p_role_code;
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Invalid role code: %', p_role_code;
    END IF;

    -- Get branch IDs
    SELECT array_agg(id) INTO v_branch_ids
    FROM branches
    WHERE code = ANY(p_branch_codes) AND is_active = true;

    IF array_length(v_branch_ids, 1) IS NULL THEN
        RAISE EXCEPTION 'No valid branch codes provided';
    END IF;

    v_token := encode(gen_random_bytes(32), 'base64url');
    v_expires_at := now() + (p_expires_hours || ' hours')::INTERVAL;

    INSERT INTO invitations (email, role_id, invited_by, token, branch_ids, expires_at)
    VALUES (p_email, v_role_id, v_inviter_id, v_token, v_branch_ids, v_expires_at)
    RETURNING id INTO v_invitation_id;

    RETURN json_build_object(
        'invitation_id', v_invitation_id,
        'email', p_email,
        'role', p_role_code,
        'token', v_token,
        'expires_at', v_expires_at
    );
END;
$$;

-- ============================================================
-- accept_invitation(token, password, mfa_required)
-- Accepts an invitation and creates the user account.
-- ============================================================
CREATE OR REPLACE FUNCTION accept_invitation(
    p_token TEXT,
    p_password TEXT,
    p_mfa_required BOOLEAN DEFAULT false
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invitation invitations%ROWTYPE;
    v_user_id UUID;
    v_role_code TEXT;
BEGIN
    IF LENGTH(p_password) < 10 THEN
        RAISE EXCEPTION 'Password must be at least 10 characters';
    END IF;

    SELECT * INTO v_invitation
    FROM invitations
    WHERE token = p_token;

    IF v_invitation IS NULL THEN
        RAISE EXCEPTION 'Invitation not found';
    END IF;

    IF v_invitation.used_at IS NOT NULL THEN
        RAISE EXCEPTION 'Invitation already used';
    END IF;

    IF v_invitation.expires_at < now() THEN
        RAISE EXCEPTION 'Invitation expired';
    END IF;

    -- Create auth user
    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
        id, email, encrypted_password, email_confirmed_at,
        created_at, updated_at
    ) VALUES (
        v_user_id,
        v_invitation.email,
        crypt(p_password, gen_salt('bf')),
        now(),
        now(), now()
    );

    -- Create profile
    INSERT INTO profiles (id, display_name, email, is_active)
    VALUES (v_user_id, split_part(v_invitation.email, '@', 1), v_invitation.email, true);

    -- Assign role
    SELECT r.code INTO v_role_code FROM roles r WHERE r.id = v_invitation.role_id;
    INSERT INTO user_roles (user_id, role_id, granted_by)
    VALUES (v_user_id, v_invitation.role_id, v_invitation.invited_by);

    -- Assign branch access
    INSERT INTO user_branch_access (user_id, branch_id, granted_by)
    SELECT v_user_id, branch_id, v_invitation.invited_by
    FROM unnest(v_invitation.branch_ids) AS branch_id;

    -- Mark invitation as used
    UPDATE invitations SET used_at = now() WHERE id = v_invitation.id;

    RETURN json_build_object(
        'user_id', v_user_id,
        'email', v_invitation.email,
        'role', v_role_code,
        'mfa_required', p_mfa_required
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION setup_first_owner FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION setup_first_owner TO authenticated;

REVOKE EXECUTE ON FUNCTION create_invitation FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_invitation TO authenticated;

REVOKE EXECUTE ON FUNCTION accept_invitation FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION accept_invitation TO authenticated;
