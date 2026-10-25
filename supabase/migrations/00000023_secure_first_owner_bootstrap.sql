-- Keep first-owner setup exclusive to trusted operators and serialize bootstrap attempts.
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
    PERFORM pg_advisory_xact_lock(hashtext('petshop-clinic:first-owner-setup'));

    SELECT COUNT(*) INTO v_existing_owner
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    WHERE r.code = 'OWNER';

    IF v_existing_owner > 0 THEN
        RAISE EXCEPTION 'First owner already exists. Use invitation flow instead.';
    END IF;

    IF p_email IS NULL OR btrim(p_email) = '' THEN
        RAISE EXCEPTION 'Email is required';
    END IF;

    IF p_display_name IS NULL OR btrim(p_display_name) = '' THEN
        RAISE EXCEPTION 'Display name is required';
    END IF;

    IF p_password IS NULL OR LENGTH(p_password) < 10 THEN
        RAISE EXCEPTION 'Password must be at least 10 characters';
    END IF;

    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
        id, email, encrypted_password, confirmed_at,
        created_at, updated_at, confirmation_token, recovery_token
    ) VALUES (
        v_user_id,
        p_email,
        extensions.crypt(p_password, extensions.gen_salt('bf')),
        now(),
        now(), now(),
        '', ''
    );

    INSERT INTO profiles (id, display_name, email, is_active)
    VALUES (v_user_id, p_display_name, p_email, true);

    SELECT id INTO v_owner_role_id FROM roles WHERE code = 'OWNER';

    IF v_owner_role_id IS NULL THEN
        RAISE EXCEPTION 'OWNER role is not configured';
    END IF;

    INSERT INTO user_roles (user_id, role_id, granted_by)
    VALUES (v_user_id, v_owner_role_id, v_user_id);

    INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, reason)
    VALUES (v_user_id, 'OWNER_SETUP', 'profiles', v_user_id, 'First owner setup');

    RETURN json_build_object(
        'user_id', v_user_id,
        'email', p_email,
        'role', 'OWNER'
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION setup_first_owner(TEXT, TEXT, TEXT)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION setup_first_owner(TEXT, TEXT, TEXT) TO service_role;
