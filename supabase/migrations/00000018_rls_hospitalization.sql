-- Migration 00000018_rls_hospitalization.sql
-- Row Level Security policies for hospitalization and service booking tables.

-- ============================================================
-- Care Units
-- ============================================================
CREATE POLICY "care_units_select" ON care_units
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('hospitalization.manage')
    );

-- ============================================================
-- Hospitalizations
-- ============================================================
CREATE POLICY "hospitalizations_select" ON hospitalizations
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('hospitalization.manage')
        OR has_permission('hospitalization.observe')
        OR has_permission('hospitalization.publish_update')
        OR customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
    );

CREATE POLICY "hospitalizations_insert" ON hospitalizations
    FOR INSERT WITH CHECK (
        has_permission('hospitalization.manage')
        AND branch_id = ANY(user_branch_ids())
    );

-- ============================================================
-- Hospitalization Assignments
-- ============================================================
CREATE POLICY "hospitalization_assignments_select" ON hospitalization_assignments
    FOR SELECT USING (
        has_permission('hospitalization.manage')
        OR has_permission('hospitalization.observe')
        OR EXISTS (
            SELECT 1 FROM hospitalizations h
            WHERE h.id = hospitalization_assignments.hospitalization_id
            AND h.branch_id = ANY(user_branch_ids())
        )
    );

-- ============================================================
-- Care Observations
-- ============================================================
CREATE POLICY "care_observations_select" ON care_observations
    FOR SELECT USING (
        recorded_by = auth.uid()
        OR has_permission('hospitalization.observe')
        OR has_permission('hospitalization.manage')
    );

-- ============================================================
-- Care Tasks
-- ============================================================
CREATE POLICY "care_tasks_select" ON care_tasks
    FOR SELECT USING (
        assigned_to = auth.uid()
        OR has_permission('hospitalization.manage')
        OR has_permission('hospitalization.observe')
    );

-- ============================================================
-- Shared Updates
-- ============================================================
CREATE POLICY "shared_updates_select" ON shared_updates
    FOR SELECT USING (
        published_by = auth.uid()
        OR has_permission('hospitalization.publish_update')
        OR has_permission('hospitalization.manage')
        OR (
            published_at IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM hospitalizations h
                JOIN pet_guardians pg ON pg.pet_id = h.pet_id
                JOIN customers c ON c.id = pg.customer_id
                WHERE h.id = shared_updates.hospitalization_id
                AND c.auth_user_id = auth.uid()
            )
        )
    );

-- ============================================================
-- Service Bookings
-- ============================================================
CREATE POLICY "service_bookings_select" ON service_bookings
    FOR SELECT USING (
        customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
        OR branch_id = ANY(user_branch_ids())
        OR has_permission('grooming.manage')
    );

CREATE POLICY "service_bookings_insert" ON service_bookings
    FOR INSERT WITH CHECK (
        has_permission('grooming.manage')
        OR customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
    );

-- ============================================================
-- Service Booking Items
-- ============================================================
CREATE POLICY "service_booking_items_select" ON service_booking_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM service_bookings sb
            WHERE sb.id = service_booking_items.booking_id
            AND (sb.customer_id IN (SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid())
                 OR sb.branch_id = ANY(user_branch_ids())
                 OR has_permission('grooming.manage'))
        )
    );

-- ============================================================
-- Boarding Stays
-- ============================================================
CREATE POLICY "boarding_stays_select" ON boarding_stays
    FOR SELECT USING (
        has_permission('grooming.manage')
        OR EXISTS (
            SELECT 1 FROM service_bookings sb
            WHERE sb.id = boarding_stays.booking_id
            AND (
                sb.branch_id = ANY(user_branch_ids())
                OR sb.customer_id IN (
                    SELECT c.id FROM customers c WHERE c.auth_user_id = auth.uid()
                )
            )
        )
    );

-- ============================================================
-- Service Capacity
-- ============================================================
CREATE POLICY "service_capacity_select" ON service_capacity
    FOR SELECT USING (
        branch_id = ANY(user_branch_ids())
        OR has_permission('grooming.manage')
    );
