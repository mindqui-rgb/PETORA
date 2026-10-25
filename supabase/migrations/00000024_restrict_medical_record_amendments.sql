DROP POLICY medical_record_amendments_insert ON medical_record_amendments;

CREATE POLICY medical_record_amendments_insert ON medical_record_amendments
    FOR INSERT
    WITH CHECK (
        has_permission('medical_record.amend')
        AND amended_by = auth.uid()
        AND EXISTS (
            SELECT 1
            FROM medical_records record
            JOIN visits visit ON visit.id = record.visit_id
            JOIN doctor_profiles doctor ON doctor.id = visit.doctor_id
            WHERE record.id = medical_record_amendments.medical_record_id
              AND record.signed_by = auth.uid()
              AND doctor.user_id = auth.uid()
              AND record.status IN ('SIGNED', 'AMENDED')
        )
    );
