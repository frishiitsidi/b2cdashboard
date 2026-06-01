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
('apr-w1', '30 Mar – 5 Apr 2026', 'current', 'April W1'),
('apr-w2', '6–12 Apr 2026', 'current', 'April W2'),
('apr-w3', '13–19 Apr 2026', 'current', 'April W3'),
('apr-w4', '20–26 Apr 2026', 'current', 'April W4'),
('may-w1', '27 Apr – 3 May 2026', 'current', 'May W1'),
('may-w2', '4–10 May 2026', 'current', 'May W2'),
('may-w3', '11–17 May 2026', 'current', 'May W3'),
('may-w4', '18–24 May 2026', 'current', 'May W4'),
('may-w5', '25–31 May 2026', 'current', 'May W5'),
('jun-w1', '1–7 Jun 2026', 'current', 'June W1'),
('jun-w2', '8–14 Jun 2026', 'planned', 'June W2'),
('jun-w3', '15–21 Jun 2026', 'planned', 'June W3'),
('jun-w4', '22–28 Jun 2026', 'planned', 'June W4');

-- 3. KPI Definitions Seed
INSERT INTO kpi_definitions (id, role_id, name, description, input_type, display_type, target_value, target_status, unit, numerator_label, denominator_label, checklist_items) VALUES
('kpi-1', 'growth', 'Total B2C Revenue', 'Total revenue generated by B2C products.', 'currency_direct', 'currency', 100000000, NULL, 'Rp', NULL, NULL, NULL),
('kpi-2', 'growth', 'Revenue from Personal License + Assisted', 'Revenue contribution from Personal License and Assisted product channels.', 'currency_direct', 'currency', 40000000, NULL, 'Rp', NULL, NULL, NULL),
('kpi-3', 'growth', 'Leads from growth-owned channels', 'Number of leads generated from growth-marketing owned acquisition channels.', 'number_direct', 'number', 500, NULL, 'leads', NULL, NULL, NULL),
('kpi-4', 'growth', 'Lead-to-Purchase: Conversion Rate', 'Conversion rate calculated from total purchases divided by total growth-owned leads.', 'calculated_rate', 'percentage', 50, NULL, '%', 'Total purchases', 'Growth-owned leads', NULL),
('kpi-5', 'growth', 'Weekly Operating System Consistency', 'Calculated from meeting consistency, review cadence, and action items closed.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Completed activities', 'Total planned activities', NULL),
('kpi-6', 'activation', 'Conversion / Revenue Contribution', 'Calculated from activation-contributed revenue and total B2C revenue.', 'calculated_rate', 'percentage', 30, NULL, '%', 'Activation revenue', 'Total B2C revenue', NULL),
('kpi-7', 'activation', 'Qualified Leads', 'Total number of qualified leads generated.', 'number_direct', 'number', 90, NULL, 'leads', NULL, NULL, NULL),
('kpi-8', 'activation', 'First Response Time SLA', 'Percentage of leads responded to within SLA window.', 'calculated_rate', 'percentage', 100, NULL, '%', 'Responded within SLA', 'Total inquiries', NULL),
('kpi-9', 'activation', 'Organic Funnel Contribution', 'Organic channel growth month-over-month.', 'number_direct', 'percentage', 100, NULL, '%', NULL, NULL, NULL),
('kpi-10', 'activation', 'Community Growth', 'Total new community members joined.', 'number_direct', 'number', 350, NULL, 'members', NULL, NULL, NULL),
('kpi-11', 'learning', 'On-time Program Delivery', 'Program batches or materials ready and delivered on schedule.', 'calculated_rate', 'percentage', 90, NULL, '%', 'On-time programs', 'Total programs due', NULL),
('kpi-12', 'learning', 'Attendance Rate / Completion Health', 'Calculated from attended learners and registered learners.', 'calculated_rate', 'percentage', 80, NULL, '%', 'Attended learners', 'Registered learners', NULL),
('kpi-13', 'learning', 'Learner Satisfaction Score', 'Learners giving a high rating out of total respondents.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Satisfied learners', 'Total respondents', NULL),
('kpi-14', 'learning', 'Feedback-to-Improvement Loop', 'Feedback loop actions completed.', 'checklist', 'percentage', 100, NULL, '%', NULL, NULL, '["Feedback collected", "Key issue summarized", "Improvement action defined", "Owner assigned"]'::jsonb),
('kpi-15', 'creative', 'On-time Creative Delivery', 'Percentage of creative assets completed and delivered on time.', 'calculated_rate', 'percentage', 90, NULL, '%', 'Delivered on time', 'Total assets requested', NULL),
('kpi-16', 'creative', 'Revision Efficiency', 'Average revision cycles per asset. Lower is better.', 'number_direct_lower_is_better', 'number', 2, NULL, 'cycles', NULL, NULL, NULL),
('kpi-17', 'creative', 'Priority Product Support Coverage', 'Products supported out of total priority products.', 'calculated_rate', 'percentage', 100, NULL, '%', 'Supported priority products', 'Total priority products', NULL);

-- 4. KPI Entries Seeds
-- Disable all triggers during seeding phase to load historical seeds without validation roadblocks
ALTER TABLE kpi_entries DISABLE TRIGGER USER;
ALTER TABLE weekly_reviews DISABLE TRIGGER USER;

-- Week 1 locked
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('jun-w1', 'kpi-1', 21000000, NULL, NULL, NULL, NULL, 'B2C engine moving.', 'No blocker', 'Retarget warm leads.', 'Dwi'),
('jun-w1', 'kpi-2', 8800000, NULL, NULL, NULL, NULL, 'Good personal license contribution.', 'No blocker', 'Clarify offer ladder.', 'Dwi'),
('jun-w1', 'kpi-3', 120, NULL, NULL, NULL, NULL, 'Stable lead volume.', 'No blocker', 'Boost acquisition budget.', 'Dwi'),
('jun-w1', 'kpi-4', NULL, NULL, 48, 120, NULL, 'Fair conversion rate.', 'Low conversion', 'Optimize landing page.', 'Dwi'),
('jun-w1', 'kpi-5', NULL, NULL, 8, 10, NULL, 'Rhythm is stable.', 'No blocker', 'Ensure all reviews completed.', 'Dwi'),
('jun-w1', 'kpi-6', NULL, NULL, 5500000, 21000000, NULL, 'Decent contribution.', 'No blocker', 'Refine activation paths.', 'Wina'),
('jun-w1', 'kpi-7', 20, NULL, NULL, NULL, NULL, 'Leads verified.', 'No blocker', 'Ensure SLA adherence.', 'Wina'),
('jun-w1', 'kpi-8', NULL, NULL, 36, 40, NULL, 'Response window mostly kept.', 'Waiting for asset/material', 'Improve templates.', 'Wina'),
('jun-w1', 'kpi-9', 95, NULL, NULL, NULL, NULL, 'Solid organic numbers.', 'No blocker', 'Maintain content rhythm.', 'Wina'),
('jun-w1', 'kpi-10', 60, NULL, NULL, NULL, NULL, 'Active growth.', 'No blocker', 'Promote new events.', 'Wina'),
('jun-w1', 'kpi-11', NULL, NULL, 8, 10, NULL, 'On track.', 'No blocker', 'Coordinate with mentors.', 'Fariz'),
('jun-w1', 'kpi-12', NULL, NULL, 32, 42, NULL, 'Completion health looks good.', 'No blocker', 'Monitor attendance closely.', 'Fariz'),
('jun-w1', 'kpi-13', NULL, NULL, 18, 20, NULL, 'Learners highly satisfied.', 'No blocker', 'Keep high standard.', 'Fariz'),
('jun-w1', 'kpi-14', NULL, NULL, NULL, NULL, '[true, true, false, false]'::jsonb, 'Initial feedback analyzed.', 'Waiting for decision', 'Assign top tasks.', 'Fariz'),
('jun-w1', 'kpi-15', NULL, NULL, 7, 9, NULL, 'Creative pipeline moving.', 'Unclear brief', 'Lock briefs H-5.', 'Annisa'),
('jun-w1', 'kpi-16', 3, NULL, NULL, NULL, NULL, 'A bit more revisions than usual.', 'Unclear brief', 'Clarify branding guidelines.', 'Annisa'),
('jun-w1', 'kpi-17', NULL, NULL, 4, 5, NULL, 'P0 campaigns well-supported.', 'Waiting for decision', 'Clarify prioritize list.', 'Annisa');

-- Week 2 locked
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('jun-w2', 'kpi-1', 22950000, NULL, NULL, NULL, NULL, 'B2C revenue improved.', 'No blocker', 'Maintain.', 'Dwi'),
('jun-w2', 'kpi-2', 9200000, NULL, NULL, NULL, NULL, 'Consistently converting.', 'No blocker', 'Maintain.', 'Dwi'),
('jun-w2', 'kpi-3', 135, NULL, NULL, NULL, NULL, 'Steady stream of traffic.', 'No blocker', 'Maintain.', 'Dwi'),
('jun-w2', 'kpi-4', NULL, NULL, 61, 135, NULL, 'Conversion conversion rate is stable.', 'Low conversion', 'Enhance product benefits.', 'Dwi'),
('jun-w2', 'kpi-5', NULL, NULL, 9, 10, NULL, 'Highly consistent.', 'No blocker', 'Maintain.', 'Dwi'),
('jun-w2', 'kpi-6', NULL, NULL, 6800000, 22950000, NULL, 'Good month progress.', 'No blocker', 'Optimize.', 'Wina'),
('jun-w2', 'kpi-7', 25, NULL, NULL, NULL, NULL, 'Target pacing well.', 'No blocker', 'Keep high lead validation.', 'Wina'),
('jun-w2', 'kpi-8', NULL, NULL, 45, 45, NULL, '100% response time SLA.', 'No blocker', 'Maintain.', 'Wina'),
('jun-w2', 'kpi-9', 105, NULL, NULL, NULL, NULL, 'Organic search conversion active.', 'No blocker', 'Boost SEO content.', 'Wina'),
('jun-w2', 'kpi-10', 80, NULL, NULL, NULL, NULL, 'Active onboarding.', 'No blocker', 'Prepare event kit.', 'Wina'),
('jun-w2', 'kpi-11', NULL, NULL, 9, 10, NULL, 'Prepared.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w2', 'kpi-12', NULL, NULL, 34, 40, NULL, 'Attendance is healthy.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w2', 'kpi-13', NULL, NULL, 22, 24, NULL, 'Amazing reviews.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w2', 'kpi-14', NULL, NULL, NULL, NULL, '[true, true, true, false]'::jsonb, 'Feedback actions drafted.', 'Waiting for decision', 'Assign owners.', 'Fariz'),
('jun-w2', 'kpi-15', NULL, NULL, 8, 9, NULL, 'Assets are ready.', 'No blocker', 'Maintain.', 'Annisa'),
('jun-w2', 'kpi-16', 2, NULL, NULL, NULL, NULL, 'Revision efficiency hit.', 'No blocker', 'Maintain.', 'Annisa'),
('jun-w2', 'kpi-17', NULL, NULL, 5, 5, NULL, 'Full coverage of priority products.', 'No blocker', 'Maintain.', 'Annisa');

-- Week 3 current (active, editable)
INSERT INTO kpi_entries (week_id, kpi_id, actual_value, actual_status, numerator_value, denominator_value, checklist_values, notes, blocker, next_action, updated_by) VALUES
('jun-w3', 'kpi-1', 18750000, NULL, NULL, NULL, NULL, 'Academy moving, Personal License still below target.', 'No blocker', 'Prioritize Personal License Business retargeting.', 'Dwi'),
('jun-w3', 'kpi-2', 7500000, NULL, NULL, NULL, NULL, 'Assisted conversion rate is steady.', 'No blocker', 'Refine Assisted conversion path.', 'Dwi'),
('jun-w3', 'kpi-3', 110, NULL, NULL, NULL, NULL, 'A bit lower this week.', 'No blocker', 'Improve growth channel optimization.', 'Dwi'),
('jun-w3', 'kpi-4', NULL, NULL, 44, 110, NULL, 'Conversion rate holds stable.', 'Low conversion', 'Optimize retargeting.', 'Dwi'),
('jun-w3', 'kpi-5', NULL, NULL, 9, 10, NULL, 'Rhythms are extremely stable.', 'No blocker', 'Maintain.', 'Dwi'),
('jun-w3', 'kpi-6', NULL, NULL, 5200000, 18750000, NULL, 'Activation channel did good work.', 'No blocker', 'Refine landing copy.', 'Wina'),
('jun-w3', 'kpi-7', 22, NULL, NULL, NULL, NULL, 'Qualified leads verified.', 'No blocker', 'Maintain standard.', 'Wina'),
('jun-w3', 'kpi-8', NULL, NULL, 42, 43, NULL, 'Responded within SLA window.', 'No blocker', 'Maintain.', 'Wina'),
('jun-w3', 'kpi-9', 100, NULL, NULL, NULL, NULL, 'Hit organic targets exactly.', 'No blocker', 'Maintain.', 'Wina'),
('jun-w3', 'kpi-10', 75, NULL, NULL, NULL, NULL, 'Solid community numbers.', 'No blocker', 'Maintain.', 'Wina'),
('jun-w3', 'kpi-11', NULL, NULL, 9, 10, NULL, 'Program ready on time.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w3', 'kpi-12', NULL, NULL, 34, 41, NULL, 'Completion health holds stable.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w3', 'kpi-13', NULL, NULL, 19, 21, NULL, 'Excellent feedback.', 'No blocker', 'Maintain.', 'Fariz'),
('jun-w3', 'kpi-14', NULL, NULL, NULL, NULL, '[true, true, false, false]'::jsonb, 'Analyzing feedback loops.', 'Waiting for decision', 'Assign owners.', 'Fariz'),
('jun-w3', 'kpi-15', NULL, NULL, 8, 9, NULL, 'Assets completed.', 'Unclear brief', 'Require briefs H-5.', 'Annisa'),
('jun-w3', 'kpi-16', 2, NULL, NULL, NULL, NULL, 'Revisions within bounds.', 'No blocker', 'Maintain.', 'Annisa'),
('jun-w3', 'kpi-17', NULL, NULL, 5, 5, NULL, 'Supported priority campaigns.', 'No blocker', 'Maintain.', 'Annisa');


-- 5. Weekly Reviews Seeds
INSERT INTO weekly_reviews (week_id, revenue_total, leads_in, follow_up_rate, conversion_notes, decisions_made, priorities_next_week) VALUES
('jun-w1', 21000000, 120, '40%', 'B2C engine moving.', 'Clarify Assisted offer hierarchy.', 'Boost acquisition budget.'),
('jun-w2', 22950000, 135, '45%', 'Good progress on B2C revenue.', 'Lock Academy pricing tiers.', 'Enhance product benefits.'),
('jun-w3', 18750000, 110, '40%', 'Revenue slightly flat this week.', 'Prioritize warm business inquiries first.', 'Optimize retargeting.');

-- Re-enable all triggers now that seed data loading has successfully completed
ALTER TABLE kpi_entries ENABLE TRIGGER USER;
ALTER TABLE weekly_reviews ENABLE TRIGGER USER;

