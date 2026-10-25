BEGIN;

SELECT plan(3);

INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token
) VALUES
    (
        '00000000-0000-4000-8000-000000000001',
        'owner-amendment-test@example.invalid',
        crypt('test-password', gen_salt('bf')),
        now(),
        now(),
        '',
        ''
    ),
    (
        '00000000-0000-4000-8000-000000000002',
        'doctor-amendment-test@example.invalid',
        crypt('test-password', gen_salt('bf')),
        now(),
        now(),
        '',
        ''
    );

INSERT INTO profiles (id, display_name, email, is_active) VALUES
    (
        '00000000-0000-4000-8000-000000000001',
        'Test Owner',
        'owner-amendment-test@example.invalid',
        true
    ),
    (
        '00000000-0000-4000-8000-000000000002',
        'Test Doctor',
        'doctor-amendment-test@example.invalid',
        true
    );

INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT
    user_id,
    roles.id,
    user_id
FROM (
    VALUES
        ('00000000-0000-4000-8000-000000000001'::UUID, 'OWNER'::TEXT),
        ('00000000-0000-4000-8000-000000000002'::UUID, 'DOCTOR'::TEXT)
) AS assigned_roles(user_id, role_code)
JOIN roles ON roles.code = assigned_roles.role_code;

INSERT INTO branches (id, code, name) VALUES
    ('00000000-0000-4000-8000-000000000003', 'TST', 'Test Branch');

INSERT INTO pets (id, name, species) VALUES
    ('00000000-0000-4000-8000-000000000004', 'Test Pet', 'DOG');

INSERT INTO doctor_profiles (id, user_id, license_number) VALUES
    (
        '00000000-0000-4000-8000-000000000005',
        '00000000-0000-4000-8000-000000000002',
        'TEST-DOCTOR-LICENSE'
    );

INSERT INTO visits (
    id,
    pet_id,
    branch_id,
    doctor_id,
    status,
    created_by
) VALUES (
    '00000000-0000-4000-8000-000000000006',
    '00000000-0000-4000-8000-000000000004',
    '00000000-0000-4000-8000-000000000003',
    '00000000-0000-4000-8000-000000000005',
    'COMPLETED',
    '00000000-0000-4000-8000-000000000002'
);

INSERT INTO medical_records (
    id,
    visit_id,
    status,
    diagnosis,
    history,
    signed_by,
    signed_at,
    created_by
) VALUES (
    '00000000-0000-4000-8000-000000000007',
    '00000000-0000-4000-8000-000000000006',
    'SIGNED',
    'sensitive test clinical diagnosis',
    'sensitive test medical history',
    '00000000-0000-4000-8000-000000000002',
    now(),
    '00000000-0000-4000-8000-000000000002'
);

SELECT ok(
    NOT EXISTS (
        SELECT 1
        FROM audit_logs
        WHERE entity_type = 'medical_records'
          AND (
              metadata->'new' ?| ARRAY[
                  'diagnosis',
                  'history',
                  'chief_complaint',
                  'physical_exam',
                  'treatment_plan',
                  'clinical_data',
                  'internal_note'
              ]
              OR metadata::TEXT LIKE '%sensitive test clinical%'
              OR metadata::TEXT LIKE '%sensitive test medical%'
          )
    ),
    'clinical record content is excluded from audit metadata'
);

SET LOCAL ROLE authenticated;
SELECT set_config(
    'request.jwt.claim.sub',
    '00000000-0000-4000-8000-000000000001',
    true
);

SELECT throws_ok(
    $$
        INSERT INTO medical_record_amendments (
            medical_record_id,
            reason,
            previous_content,
            new_content,
            amended_by
        ) VALUES (
            '00000000-0000-4000-8000-000000000007',
            'Unauthorized test amendment',
            '{}'::JSONB,
            '{"diagnosis":"unauthorized"}'::JSONB,
            '00000000-0000-4000-8000-000000000001'
        )
    $$,
    '42501',
    NULL,
    'owner without a doctor profile cannot amend another doctor''s record'
);

SELECT set_config(
    'request.jwt.claim.sub',
    '00000000-0000-4000-8000-000000000002',
    true
);

SELECT lives_ok(
    $$
        INSERT INTO medical_record_amendments (
            medical_record_id,
            reason,
            previous_content,
            new_content,
            amended_by
        ) VALUES (
            '00000000-0000-4000-8000-000000000007',
            'Original doctor amendment',
            '{}'::JSONB,
            '{"diagnosis":"corrected"}'::JSONB,
            '00000000-0000-4000-8000-000000000002'
        )
    $$,
    'original signing doctor can append an amendment'
);

SELECT * FROM finish();

ROLLBACK;
