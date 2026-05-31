-- ==========================================
-- B2C Growth Operating System — KPI Tracker
-- Supabase SQL Database Schema & Seeds
-- ==========================================

-- Clean existing structures (Cascading drops for clean re-runs)
DROP FUNCTION IF EXISTS check_week_locked() CASCADE;
DROP FUNCTION IF EXISTS validate_kpi_entry_context() CASCADE;

DROP TABLE IF EXISTS monthly_reviews CASCADE;
DROP TABLE IF EXISTS weekly_reviews CASCADE;
DROP TABLE IF EXISTS kpi_entries CASCADE;
DROP TABLE IF EXISTS kpi_definitions CASCADE;
DROP TABLE IF EXISTS weeks CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- 1. Roles Table
CREATE TABLE roles (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    owner VARCHAR(100) NOT NULL,
    mandate TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Weeks Table
CREATE TABLE weeks (
    id VARCHAR(50) PRIMARY KEY,
    label VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('locked', 'current', 'planned')),
    quarter_week VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. KPI Definitions Table
CREATE TABLE kpi_definitions (
    id VARCHAR(50) PRIMARY KEY,
    role_id VARCHAR(50) REFERENCES roles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    input_type VARCHAR(50) NOT NULL CHECK (input_type IN ('currency_direct', 'calculated_rate', 'status', 'number_direct', 'number_direct_lower_is_better', 'checklist')),
    display_type VARCHAR(50) NOT NULL CHECK (display_type IN ('currency', 'percentage', 'status', 'number')),
    target_value NUMERIC,             -- Used for numeric targets
    target_status VARCHAR(50),         -- Used for qualitative targets (e.g. 'On Track')
    unit VARCHAR(50),                  -- e.g. 'Rp', '%', 'leads', 'assets'
    numerator_label VARCHAR(100),      -- e.g. 'Leads followed up'
    denominator_label VARCHAR(100),    -- e.g. 'Total active leads'
    checklist_items JSONB,             -- e.g. '["Item 1", "Item 2"]'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. KPI Entries Table
CREATE TABLE kpi_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_id VARCHAR(50) REFERENCES weeks(id) ON DELETE CASCADE,
    kpi_id VARCHAR(50) REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    actual_value NUMERIC,              -- Stored computed rate / actual numeric input
    actual_status VARCHAR(50),         -- Stored qualitative status ('On Track', etc.)
    numerator_value NUMERIC,           -- Numerator part if calculated_rate
    denominator_value NUMERIC,         -- Denominator part if calculated_rate
    checklist_values JSONB,            -- Array of booleans representing completed checklist items (e.g. '[true, false]')
    notes TEXT,
    blocker VARCHAR(100) DEFAULT 'No blocker',
    next_action TEXT,
    updated_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_week_kpi UNIQUE (week_id, kpi_id)
);

-- 5. Weekly Reviews Table
CREATE TABLE weekly_reviews (
    week_id VARCHAR(50) PRIMARY KEY REFERENCES weeks(id) ON DELETE CASCADE,
    revenue_total NUMERIC,
    leads_in INTEGER,
    follow_up_rate VARCHAR(50),
    conversion_notes TEXT,
    decisions_made TEXT,
    priorities_next_week TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Monthly Reviews Table
CREATE TABLE monthly_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    month_label VARCHAR(50) NOT NULL,
    what_worked TEXT,
    what_needs_improvement TEXT,
    focus_areas_next_month TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- INDEXING
-- ==========================================
CREATE INDEX idx_kpi_definitions_role ON kpi_definitions(role_id);
CREATE INDEX idx_kpi_entries_week_kpi ON kpi_entries(week_id, kpi_id);

-- ==========================================
-- INTEGRITY ENFORCEMENTS & TRIGGERS
-- ==========================================

-- Trigger: Prevent updates on locked weeks
CREATE OR REPLACE FUNCTION check_week_locked()
RETURNS TRIGGER AS $$
DECLARE
    v_week_status VARCHAR(20);
    v_week_id VARCHAR(50);
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_week_id := OLD.week_id;
    ELSE
        v_week_id := NEW.week_id;
    END IF;

    SELECT status INTO v_week_status FROM weeks WHERE id = v_week_id;

    IF v_week_status = 'locked' THEN
        RAISE EXCEPTION 'This week is locked as historical record and cannot be modified.';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER kpi_entries_lock_check
BEFORE INSERT OR UPDATE OR DELETE ON kpi_entries
FOR EACH ROW EXECUTE FUNCTION check_week_locked();

CREATE TRIGGER weekly_reviews_lock_check
BEFORE INSERT OR UPDATE OR DELETE ON weekly_reviews
FOR EACH ROW EXECUTE FUNCTION check_week_locked();


-- Trigger: Context check validation & actuals calculation
CREATE OR REPLACE FUNCTION validate_kpi_entry_context()
RETURNS TRIGGER AS $$
DECLARE
    v_input_type VARCHAR(50);
    v_target NUMERIC;
    v_actual_val NUMERIC;
    v_status VARCHAR(20); -- 'green', 'yellow', 'red', 'pending'
    v_checklist_items JSONB;
BEGIN
    -- Query metadata from the configuration definition
    SELECT input_type, target_value, checklist_items
    INTO v_input_type, v_target, v_checklist_items
    FROM kpi_definitions
    WHERE id = NEW.kpi_id;

    -- Calculate computed actual_value based on format type
    IF v_input_type = 'calculated_rate' THEN
        IF NEW.numerator_value IS NULL AND NEW.denominator_value IS NULL THEN
            v_actual_val := NULL;
        ELSIF NEW.denominator_value IS NULL OR NEW.denominator_value = 0 THEN
            v_actual_val := 0;
        ELSE
            v_actual_val := ROUND((NEW.numerator_value / NEW.denominator_value) * 100);
        END IF;
        NEW.actual_value := v_actual_val;
    ELSIF v_input_type = 'checklist' THEN
        IF NEW.checklist_values IS NULL THEN
            v_actual_val := NULL;
        ELSE
            DECLARE
                v_total INT;
                v_done INT := 0;
                v_item JSONB;
            BEGIN
                v_total := jsonb_array_length(v_checklist_items);
                IF v_total IS NULL OR v_total = 0 THEN
                    v_actual_val := 0;
                ELSE
                    FOR v_item IN SELECT jsonb_array_elements(NEW.checklist_values) LOOP
                        IF v_item::text = 'true' THEN
                            v_done := v_done + 1;
                        END IF;
                    END LOOP;
                    v_actual_val := ROUND((v_done::numeric / v_total::numeric) * 100);
                END IF;
            END;
        END IF;
        NEW.actual_value := v_actual_val;
    ELSE
        v_actual_val := NEW.actual_value;
    END IF;

    -- Compute the contextual status (Green, Yellow, Red, Pending)
    IF v_input_type = 'status' THEN
        IF NEW.actual_status IS NULL OR TRIM(NEW.actual_status) = '' THEN
            v_status := 'pending';
        ELSIF NEW.actual_status = 'On Track' THEN
            v_status := 'green';
        ELSIF NEW.actual_status = 'Needs Attention' THEN
            v_status := 'yellow';
        ELSE
            v_status := 'red';
        END IF;
    ELSIF v_actual_val IS NULL THEN
        v_status := 'pending';
    ELSIF v_input_type = 'number_direct_lower_is_better' THEN
        IF v_actual_val <= v_target THEN
            v_status := 'green';
        ELSIF v_actual_val <= v_target + 1 THEN
            v_status := 'yellow';
        ELSE
            v_status := 'red';
        END IF;
    ELSE
        -- Default Higher is better
        IF v_target IS NULL OR v_target = 0 THEN
            v_status := 'green';
        ELSE
            DECLARE
                v_ratio NUMERIC;
            BEGIN
                v_ratio := v_actual_val / v_target;
                IF v_ratio >= 1.0 THEN
                    v_status := 'green';
                ELSIF v_ratio >= 0.7 THEN
                    v_status := 'yellow';
                ELSE
                    v_status := 'red';
                END IF;
            END;
        END IF;
    END IF;

    -- Strict business check: Yellow/Red require blocker and next action
    IF v_status IN ('yellow', 'red') THEN
        IF NEW.blocker IS NULL OR NEW.blocker = 'No blocker' OR TRIM(NEW.blocker) = '' THEN
            RAISE EXCEPTION 'A valid blocker is required for Yellow or Red KPIs.';
        END IF;
        IF NEW.next_action IS NULL OR TRIM(NEW.next_action) = '' THEN
            RAISE EXCEPTION 'Next action description is required for Yellow or Red KPIs.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER kpi_entries_validation
BEFORE INSERT OR UPDATE ON kpi_entries
FOR EACH ROW EXECUTE FUNCTION validate_kpi_entry_context();


-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable security policies on all tables
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_reviews ENABLE ROW LEVEL SECURITY;

-- Shared/Public Select Access
CREATE POLICY "Allow public select on roles" ON roles FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Allow public select on weeks" ON weeks FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Allow public select on kpi_definitions" ON kpi_definitions FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Allow public select on kpi_entries" ON kpi_entries FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Allow public select on weekly_reviews" ON weekly_reviews FOR SELECT TO authenticated, anon USING (true);
CREATE POLICY "Allow public select on monthly_reviews" ON monthly_reviews FOR SELECT TO authenticated, anon USING (true);

-- Shared/Public Mutating Access (Governed strictly by trigger rules)
CREATE POLICY "Allow full access on roles" ON roles FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access on weeks" ON weeks FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access on kpi_definitions" ON kpi_definitions FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access on kpi_entries" ON kpi_entries FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access on weekly_reviews" ON weekly_reviews FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access on monthly_reviews" ON monthly_reviews FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);


-- ==========================================
-- SEED DATA (EXACT SEEDS FROM PROTOTYPE)
-- ==========================================

-- 1. Roles Seed
INSERT INTO roles (id, name, owner, mandate) VALUES
('growth', 'Growth Marketing', 'Dwi', 'Keep the B2C engine aligned, measurable, and connected to revenue.'),
('activation', 'Activation Specialist', 'Wina', 'Move leads, conversations, and community activation so the pipeline does not go stale.'),
('learning', 'Learning Operation', 'Fariz', 'Ensure Academy products are ready, delivered well, and continuously improved.'),
('creative', 'Graphic Designer & Editor', 'Annisa', 'Keep priority campaign assets ready, consistent, and delivered on time.');

-- 2. Weeks Seed
INSERT INTO weeks (id, label, status, quarter_week) VALUES
('w1', '3–7 June 2026', 'locked', 'Week 1 of 13'),
('w2', '10–14 June 2026', 'locked', 'Week 2 of 13'),
('w3', '17–21 June 2026', 'current', 'Week 3 of 13'),
('w4', '24–28 June 2026', 'planned', 'Week 4 of 13');

-- 3. KPI Definitions Seed
INSERT INTO kpi_definitions (id, role_id, name, description, input_type, display_type, target_value, target_status, unit, numerator_label, denominator_label, checklist_items) VALUES
('kpi-1', 'growth', 'Total B2C Revenue', 'Total revenue generated by B2C products this week.', 'currency_direct', 'currency', 25000000, NULL, 'Rp', NULL, NULL, NULL),
('kpi-2', 'growth', 'Revenue from Personal License + Assisted', 'Revenue contribution from recurring/assisted product group.', 'currency_direct', 'currency', 10000000, NULL, 'Rp', NULL, NULL, NULL),
('kpi-3', 'growth', 'Follow-up Rate', 'Calculated from total active leads and leads followed up within SLA.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Leads followed up', 'Total active leads', NULL),
('kpi-4', 'growth', 'Weekly Operating System Consistency', 'Weekly rhythm, review, and decision log consistency.', 'status', 'status', NULL, 'On Track', NULL, NULL, NULL, NULL),
('kpi-5', 'activation', 'Qualified Leads Generated', 'Qualified lead = clear product interest, valid contact, short need context, and logical next action.', 'number_direct', 'number', 12, NULL, 'leads', NULL, NULL, NULL),
('kpi-6', 'activation', 'First Response Time', 'Calculated from leads responded within SLA and total new inquiries.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Responded within SLA', 'Total new inquiries', NULL),
('kpi-7', 'activation', 'Follow-up Completion Rate', 'Calculated from leads with completed follow-up and total leads requiring follow-up.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Completed follow-up', 'Leads requiring follow-up', NULL),
('kpi-8', 'activation', 'WA / Community Activation Consistency', 'Number of meaningful WA/community activation activities this week.', 'number_direct', 'number', 2, NULL, 'activities', NULL, NULL, NULL),
('kpi-9', 'learning', 'On-time Program Readiness', 'Program assets, mentor, timeline, and operational preparation are ready on time.', 'status', 'status', NULL, 'On Track', NULL, NULL, NULL, NULL),
('kpi-10', 'learning', 'On-time Program Delivery', 'Class or program delivery follows planned schedule and standard.', 'status', 'status', NULL, 'On Track', NULL, NULL, NULL, NULL),
('kpi-11', 'learning', 'Learner Satisfaction / Attendance Health', 'Calculated from total attendees and total registered learners.', 'calculated_rate', 'percentage', 80, NULL, '%', 'Attended learners', 'Registered learners', NULL),
('kpi-12', 'learning', 'Feedback-to-Improvement Loop', 'Feedback is collected, summarized, and converted into concrete improvement.', 'checklist', 'percentage', 100, NULL, '%', NULL, NULL, '["Feedback collected", "Key issue summarized", "Improvement action defined", "Owner assigned"]'),
('kpi-13', 'creative', 'On-time Creative Delivery', 'Calculated from assets delivered on time and total assets due this week.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Assets delivered on time', 'Total assets due', NULL),
('kpi-14', 'creative', 'Asset Readiness for P0 Campaign', 'Readiness of priority campaign assets before campaign window.', 'status', 'status', NULL, 'On Track', NULL, NULL, NULL, NULL),
('kpi-15', 'creative', 'Weekly Production Consistency', 'Number of priority assets completed this week.', 'number_direct', 'number', 8, NULL, 'assets', NULL, NULL, NULL),
('kpi-16', 'creative', 'Revision Efficiency', 'Average revision cycle remains efficient and not repetitive. Lower is better.', 'number_direct_lower_is_better', 'number', 2, NULL, 'cycles', NULL, NULL, NULL);

-- 4. KPI Entries Seeds
-- Disable all triggers during seeding phase to load historical seeds without validation roadblocks
ALTER TABLE kpi_entries DISABLE TRIGGER USER;
ALTER TABLE weekly_reviews DISABLE TRIGGER USER;

-- Week 1 locked
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('w1', 'kpi-1', 21000000, NULL, NULL, NULL, NULL, 'Academy carried the week.', 'Low conversion', 'Retarget warm leads.', 'Dwi'),
('w1', 'kpi-2', 3800000, NULL, NULL, NULL, NULL, 'Assisted flow still unclear.', 'Waiting for decision', 'Clarify offer ladder.', 'Dwi'),
('w1', 'kpi-3', NULL, NULL, 29, 44, NULL, 'Follow-up slipped near end of week.', 'Overcapacity', 'Batch follow-up twice weekly.', 'Dwi'),
('w1', 'kpi-4', NULL, 'Needs Attention', NULL, NULL, NULL, 'Meeting happened, decision notes incomplete.', 'Timeline too tight', 'Use review page live.', 'Dwi'),
('w1', 'kpi-5', 8, NULL, NULL, NULL, NULL, 'Lead quality mixed.', 'Low inquiry quality', 'Improve CTA qualification.', 'Wina'),
('w1', 'kpi-6', NULL, NULL, 36, 42, NULL, 'Mostly under 24h.', 'No blocker', 'Maintain response window.', 'Wina'),
('w1', 'kpi-7', NULL, NULL, 24, 42, NULL, 'Some free class leads stale.', 'Overcapacity', 'Hot lead priority.', 'Wina'),
('w1', 'kpi-8', 1, NULL, NULL, NULL, NULL, 'Only one WA activation.', 'Waiting for asset/material', 'Prepare weekly WA kit.', 'Wina'),
('w1', 'kpi-9', NULL, 'On Track', NULL, NULL, NULL, 'Program ready.', 'No blocker', 'Maintain checklist.', 'Fariz'),
('w1', 'kpi-10', NULL, 'On Track', NULL, NULL, NULL, 'Delivery stable.', 'No blocker', 'Maintain.', 'Fariz'),
('w1', 'kpi-11', NULL, NULL, 32, 42, NULL, 'Attendance acceptable.', 'No blocker', 'Add reminder H-1.', 'Fariz'),
('w1', 'kpi-12', NULL, NULL, NULL, NULL, '[true, true, false, false]', 'Feedback collected but not converted.', 'Waiting for decision', 'Assign owner.', 'Fariz'),
('w1', 'kpi-13', NULL, NULL, 7, 9, NULL, 'Late brief affected output.', 'Unclear brief', 'Lock brief H-5.', 'Annisa'),
('w1', 'kpi-14', NULL, 'Needs Attention', NULL, NULL, NULL, 'P0 direction shifted.', 'Waiting for decision', 'Freeze direction before production.', 'Annisa'),
('w1', 'kpi-15', 7, NULL, NULL, NULL, NULL, 'One asset postponed.', 'Waiting for asset/material', 'Prioritize P0 queue.', 'Annisa'),
('w1', 'kpi-16', 3, NULL, NULL, NULL, NULL, 'Too many back-and-forth revisions.', 'Unclear brief', 'Improve first brief.', 'Annisa');

-- Week 2 locked
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('w2', 'kpi-1', 22950000, NULL, NULL, NULL, NULL, 'Revenue improved from last week.', 'Low conversion', 'Push Academy closing window.', 'Dwi'),
('w2', 'kpi-2', 5200000, NULL, NULL, NULL, NULL, 'Some Assisted interest converted.', 'Low conversion', 'Use proof asset in follow-up.', 'Dwi'),
('w2', 'kpi-3', NULL, NULL, 38, 50, NULL, 'Better completion but still below target.', 'Overcapacity', 'Reduce low-intent follow-up.', 'Dwi'),
('w2', 'kpi-4', NULL, 'On Track', NULL, NULL, NULL, 'Weekly review completed.', 'No blocker', 'Maintain review ritual.', 'Dwi'),
('w2', 'kpi-5', 10, NULL, NULL, NULL, NULL, 'Lead intake improved.', 'Low inquiry quality', 'Add qualifying question.', 'Wina'),
('w2', 'kpi-6', NULL, NULL, 41, 45, NULL, 'Response time healthy.', 'No blocker', 'Maintain.', 'Wina'),
('w2', 'kpi-7', NULL, NULL, 34, 48, NULL, 'Follow-up backlog reduced.', 'Overcapacity', 'Daily 30-min follow-up block.', 'Wina'),
('w2', 'kpi-8', 2, NULL, NULL, NULL, NULL, 'Two community touches done.', 'No blocker', 'Test testimonial angle.', 'Wina'),
('w2', 'kpi-9', NULL, 'On Track', NULL, NULL, NULL, 'Prep stable.', 'No blocker', 'Mentor brief.', 'Fariz'),
('w2', 'kpi-10', NULL, 'On Track', NULL, NULL, NULL, 'Class delivered well.', 'No blocker', 'Maintain.', 'Fariz'),
('w2', 'kpi-11', NULL, NULL, 34, 40, NULL, 'Attendance improved.', 'No blocker', 'Keep reminder flow.', 'Fariz'),
('w2', 'kpi-12', NULL, NULL, NULL, NULL, '[true, true, true, false]', 'Improvement action defined, owner not assigned yet.', 'Waiting for decision', 'Assign improvement owner.', 'Fariz'),
('w2', 'kpi-13', NULL, NULL, 8, 9, NULL, 'Almost on target.', 'Unclear brief', 'Brief checklist.', 'Annisa'),
('w2', 'kpi-14', NULL, 'Needs Attention', NULL, NULL, NULL, 'P0 campaign asset still needs earlier lock.', 'Waiting for decision', 'Confirm direction earlier.', 'Annisa'),
('w2', 'kpi-15', 8, NULL, NULL, NULL, NULL, 'Production met target.', 'No blocker', 'Maintain.', 'Annisa'),
('w2', 'kpi-16', 2, NULL, NULL, NULL, NULL, 'Revision cycle healthy.', 'No blocker', 'Maintain.', 'Annisa');

-- (All historical inputs are loaded consecutively)

-- Week 3 current (active, editable)
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('w3', 'kpi-1', 18750000, NULL, NULL, NULL, NULL, 'Academy moving, Personal License still below target.', 'Low conversion', 'Prioritize Personal License Business retargeting and assisted follow-up.', 'Dwi'),
('w3', 'kpi-2', 4200000, NULL, NULL, NULL, NULL, 'Assisted interest exists, but closing path is still not firm.', 'Waiting for decision', 'Lock Assisted offer flow and clarify follow-up ownership.', 'Dwi'),
('w3', 'kpi-3', NULL, NULL, 38, 50, NULL, 'Several leads from WA were followed up late.', 'Overcapacity', 'Focus only on hot leads and define follow-up batch time.', 'Dwi'),
('w3', 'kpi-4', NULL, 'Needs Attention', NULL, NULL, NULL, 'Weekly meeting happened, but decision log was incomplete.', 'Timeline too tight', 'Use Weekly Review page during meeting, not after meeting.', 'Dwi'),
('w3', 'kpi-5', 9, NULL, NULL, NULL, NULL, 'Most leads came from WA Community and Academy inquiries.', 'Low inquiry quality', 'Tighten CTA and ask one qualification question before routing.', 'Wina'),
('w3', 'kpi-6', NULL, NULL, 40, 43, NULL, 'Most inquiries were responded to within 24 hours.', 'No blocker', 'Maintain response block twice per day.', 'Wina'),
('w3', 'kpi-7', NULL, NULL, 31, 49, NULL, 'Some leads became stale after free class.', 'Overcapacity', 'Prioritize hot leads first and close stale leads with final CTA.', 'Wina'),
('w3', 'kpi-8', 2, NULL, NULL, NULL, NULL, 'One education post and one offer reminder sent.', 'No blocker', 'Add testimonial format next week.', 'Wina'),
('w3', 'kpi-9', NULL, 'On Track', NULL, NULL, NULL, 'Location Analytics prep is stable.', 'No blocker', 'Confirm mentor brief for next session.', 'Fariz'),
('w3', 'kpi-10', NULL, 'On Track', NULL, NULL, NULL, 'No delivery issue this week.', 'No blocker', 'Maintain class checklist.', 'Fariz'),
('w3', 'kpi-11', NULL, NULL, 34, 41, NULL, 'Attendance is healthy, but some participants requested clearer hands-on steps.', 'No blocker', 'Improve hands-on instruction clarity.', 'Fariz'),
('w3', 'kpi-12', NULL, NULL, NULL, NULL, '[true, true, false, false]', 'Feedback collected but not yet converted into implementation action.', 'Waiting for decision', 'Pick top 3 issues and assign improvement owner.', 'Fariz'),
('w3', 'kpi-13', NULL, NULL, 8, 9, NULL, 'One campaign asset was delayed due to late brief.', 'Unclear brief', 'Require H-5 locked brief for P0 assets.', 'Annisa'),
('w3', 'kpi-14', NULL, 'Needs Attention', NULL, NULL, NULL, 'Some visual direction was still changing near launch.', 'Waiting for decision', 'Confirm campaign direction before production starts.', 'Annisa'),
('w3', 'kpi-15', 8, NULL, NULL, NULL, NULL, 'Production volume met the weekly target.', 'No blocker', 'Keep production queue focused on P0 products.', 'Annisa'),
('w3', 'kpi-16', 2, NULL, NULL, NULL, NULL, 'Most assets completed within two revision cycles.', 'No blocker', 'Maintain clear first brief standard.', 'Annisa');


-- 5. Weekly Reviews Seeds
INSERT INTO weekly_reviews (week_id, revenue_total, leads_in, follow_up_rate, conversion_notes, decisions_made, priorities_next_week) VALUES
('w1', 21000000, 44, '66%', 'Academy carried the week. Assisted revenue still slow.', 'Clarify Assisted offer hierarchy.', 'Retarget warm leads.'),
('w2', 22950000, 50, '76%', 'Good progress on Academy conversions.', 'Lock Academy pricing tiers.', 'Push closing window on next cohort.'),
('w3', 18750000, 50, '76%', 'Revenue slightly flat this week.', 'Confirm campaign visual asset guidelines H-5.', 'Prioritize warm business inquiries first.');

-- Re-enable all triggers now that seed data loading has successfully completed
ALTER TABLE kpi_entries ENABLE TRIGGER USER;
ALTER TABLE weekly_reviews ENABLE TRIGGER USER;
