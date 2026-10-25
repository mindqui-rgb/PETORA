-- Keep every application table in the public schema protected by row-level security.
DO $$
DECLARE
    app_table RECORD;
BEGIN
    FOR app_table IN
        SELECT c.oid::regclass AS table_name
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind IN ('r', 'p')
          AND NOT c.relrowsecurity
    LOOP
        EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', app_table.table_name);
    END LOOP;
END;
$$;
