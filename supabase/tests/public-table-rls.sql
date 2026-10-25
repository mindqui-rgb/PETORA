BEGIN;

SELECT plan(1);

SELECT ok(
    NOT EXISTS (
        SELECT 1
        FROM pg_class table_catalog
        JOIN pg_namespace schema_catalog
            ON schema_catalog.oid = table_catalog.relnamespace
        WHERE schema_catalog.nspname = 'public'
          AND table_catalog.relkind IN ('r', 'p')
          AND NOT table_catalog.relrowsecurity
    ),
    'all public application tables have row-level security enabled'
);

SELECT * FROM finish();

ROLLBACK;
