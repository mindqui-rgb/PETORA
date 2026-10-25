BEGIN;

SELECT plan(8);

SELECT ok(
    to_regprocedure('public.setup_first_owner(text,text,text)') IS NOT NULL,
    'first-owner bootstrap function exists'
);

SELECT ok(
    NOT has_function_privilege(
        'anon',
        'public.setup_first_owner(text,text,text)',
        'EXECUTE'
    ),
    'anonymous users cannot execute first-owner bootstrap'
);

SELECT ok(
    NOT has_function_privilege(
        'authenticated',
        'public.setup_first_owner(text,text,text)',
        'EXECUTE'
    ),
    'authenticated users cannot claim the first-owner role'
);

SELECT ok(
    has_function_privilege(
        'service_role',
        'public.setup_first_owner(text,text,text)',
        'EXECUTE'
    ),
    'trusted service role can execute first-owner bootstrap'
);

SELECT ok(
    position(
        'pg_advisory_xact_lock' IN pg_get_functiondef(
            'public.setup_first_owner(text,text,text)'::regprocedure
        )
    ) > 0,
    'concurrent bootstrap attempts are serialized'
);

SET LOCAL ROLE service_role;

SELECT lives_ok(
    $$
        SELECT public.setup_first_owner(
            'first-owner-test@example.invalid',
            'secure-test-password',
            'Test Owner'
        )
    $$,
    'trusted service role can create the first owner'
);

SELECT throws_ok(
    $$
        SELECT public.setup_first_owner(
            'second-owner-test@example.invalid',
            'secure-test-password',
            'Second Owner'
        )
    $$,
    'P0001',
    'First owner already exists. Use invitation flow instead.',
    'bootstrap cannot create a second owner'
);

RESET ROLE;

SELECT is(
    (
        SELECT count(*)::INTEGER
        FROM auth.users auth_user
        JOIN user_roles assigned_role ON assigned_role.user_id = auth_user.id
        JOIN roles role ON role.id = assigned_role.role_id
        WHERE auth_user.email = 'first-owner-test@example.invalid'
          AND role.code = 'OWNER'
    ),
    1,
    'successful bootstrap persists one owner identity'
);

SELECT * FROM finish();

ROLLBACK;
