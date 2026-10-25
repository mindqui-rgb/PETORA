-- Migration 00000020_rpc_functions.sql
-- Creates core RPC functions for transactional operations.
-- Per section 18.1: all functions use SECURITY DEFINER with fixed search_path.

-- ============================================================
-- generate_invoice_number(branch_id, doc_type)
-- Internal function for sequence-based invoice number generation.
-- Format: {BRANCH_CODE}-{DOC_TYPE}-{YEAR}-{6_DIGIT_NUMBER}
-- ============================================================
CREATE OR REPLACE FUNCTION generate_invoice_number(
    p_branch_id UUID,
    p_doc_type TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_branch_code TEXT;
    v_year INTEGER;
    v_next_number INTEGER;
    v_result TEXT;
BEGIN
    -- Lock the sequence row for update to prevent race conditions
    SELECT code INTO v_branch_code FROM branches WHERE id = p_branch_id FOR UPDATE;

    IF v_branch_code IS NULL THEN
        RAISE EXCEPTION 'Branch not found: %', p_branch_id;
    END IF;

    v_year := EXTRACT(YEAR FROM now())::INTEGER;

    -- Upsert and get next number
    INSERT INTO invoice_sequences (branch_id, doc_type, year, last_number)
    VALUES (p_branch_id, p_doc_type, v_year, 1)
    ON CONFLICT (branch_id, doc_type, year)
    DO UPDATE SET last_number = invoice_sequences.last_number + 1
    RETURNING last_number INTO v_next_number;

    v_result := format('%s-%s-%s-%06s', v_branch_code, p_doc_type, v_year, v_next_number);
    RETURN v_result;
END;
$$;

-- ============================================================
-- has_permission wrapper for RPC calls
-- ============================================================
CREATE OR REPLACE FUNCTION check_permission(
    p_permission_code TEXT,
    p_branch_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN has_permission(p_permission_code, p_branch_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION generate_invoice_number FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION generate_invoice_number TO authenticated;

REVOKE EXECUTE ON FUNCTION check_permission FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION check_permission TO authenticated;
