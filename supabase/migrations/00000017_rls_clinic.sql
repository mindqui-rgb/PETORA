-- Migration 00000017_rls_clinic.sql
-- Row Level Security policies for clinic tables per section 19.2.

-- ============================================================
-- Service Catalog
-- ============================================================
CREATE POLICY "service_catalog_select" ON service_catalog
    FOR SELECT USING (is_active = true OR has_permission('grooming.manage') OR has_permission('schedule.manage'));

-- ============================================================
-- Doctor Schedules
-- ============================================================
CREATE POLICY "doctor_schedules_select" ON doctor_schedules
    FOR SELECT USING (
        doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
        OR branch_id = ANY(user_branch_ids())
        OR has_permission('schedule.manage')
    );

CREATE POLICY "doctor_schedules_insert" ON doctor_schedules
    FOR INSERT WITH CHECK (has_permission('schedule.manage'));

-- ============================================================
-- Appointments
-- ============================================================
CREATE POLICY "appointments_select" ON appointments
    FOR SELECT USING (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
        OR has_permission('appointment.manage')
        OR has_permission('schedule.manage')
    );

CREATE POLICY "appointments_insert" ON appointments
    FOR INSERT WITH CHECK (
        has_permission('appointment.manage')
        OR has_permission('schedule.manage')
        OR customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
    );

-- ============================================================
-- Visits
-- ============================================================
CREATE POLICY "visits_select" ON visits
    FOR SELECT USING (
        doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
        OR has_permission('visit.manage')
        OR has_permission('medical_record.read')
        OR EXISTS (
            SELECT 1 FROM pet_guardians pg
            JOIN customers c ON c.id = pg.customer_id
            WHERE pg.pet_id = visits.pet_id AND c.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "visits_insert" ON visits
    FOR INSERT WITH CHECK (
        has_permission('visit.manage')
        AND doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
    );

-- ============================================================
-- Medical Records
-- ============================================================
CREATE POLICY "medical_records_select" ON medical_records
    FOR SELECT USING (
        has_permission('medical_record.read')
        OR EXISTS (
            SELECT 1 FROM visits v
            JOIN doctor_profiles dp ON dp.id = v.doctor_id
            WHERE v.id = medical_records.visit_id AND dp.user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM visits v
            JOIN pet_guardians pg ON pg.pet_id = v.pet_id
            JOIN customers c ON c.id = pg.customer_id
            WHERE v.id = medical_records.visit_id AND c.auth_user_id = auth.uid()
            AND medical_records.status = 'SIGNED'
        )
    );

CREATE POLICY "medical_records_insert" ON medical_records
    FOR INSERT WITH CHECK (
        has_permission('medical_record.write')
        AND EXISTS (
            SELECT 1 FROM visits v
            JOIN doctor_profiles dp ON dp.id = v.doctor_id
            WHERE v.id = medical_records.visit_id AND dp.user_id = auth.uid()
        )
    );

-- ============================================================
-- Medical Record Amendments
-- ============================================================
CREATE POLICY "medical_record_amendments_select" ON medical_record_amendments
    FOR SELECT USING (
        amended_by = auth.uid()
        OR has_permission('medical_record.amend')
        OR has_permission('medical_record.read')
    );

CREATE POLICY "medical_record_amendments_insert" ON medical_record_amendments
    FOR INSERT WITH CHECK (
        has_permission('medical_record.amend')
        AND amended_by = auth.uid()
    );

-- ============================================================
-- Prescriptions
-- ============================================================
CREATE POLICY "prescriptions_select" ON prescriptions
    FOR SELECT USING (
        doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
        OR has_permission('prescription.write')
        OR EXISTS (
            SELECT 1 FROM visits v
            JOIN pet_guardians pg ON pg.pet_id = v.pet_id
            JOIN customers c ON c.id = pg.customer_id
            WHERE v.id = prescriptions.visit_id AND c.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "prescriptions_insert" ON prescriptions
    FOR INSERT WITH CHECK (
        has_permission('prescription.write')
        AND doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
    );

-- ============================================================
-- Treatment Records
-- ============================================================
CREATE POLICY "treatment_records_select" ON treatment_records
    FOR SELECT USING (
        doctor_id = (SELECT id FROM doctor_profiles WHERE user_id = auth.uid())
        OR has_permission('visit.manage')
        OR EXISTS (
            SELECT 1 FROM visits v
            JOIN pet_guardians pg ON pg.pet_id = v.pet_id
            JOIN customers c ON c.id = pg.customer_id
            WHERE v.id = treatment_records.visit_id AND c.auth_user_id = auth.uid()
        )
    );

-- ============================================================
-- Medication Dispensings
-- ============================================================
CREATE POLICY "medication_dispensings_select" ON medication_dispensings
    FOR SELECT USING (
        dispensed_by = auth.uid()
        OR has_permission('clinic.medication.use')
        OR has_permission('medical_record.read')
    );

CREATE POLICY "medication_dispensings_insert" ON medication_dispensings
    FOR INSERT WITH CHECK (
        has_permission('clinic.medication.use')
        AND dispensed_by = auth.uid()
    );
