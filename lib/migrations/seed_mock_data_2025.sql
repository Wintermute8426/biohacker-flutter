-- Seed Mock Data for Last Year (2025)
-- This populates cycles, protocols, dose logs, side effects, weight logs, and lab results
-- for realistic demo of Reports and Calendar tabs

-- Get the authenticated user ID (replace with actual user UUID from auth.users)
-- For now, we'll use a placeholder - you'll need to update this with your actual user_id
-- SELECT id FROM auth.users LIMIT 1;

-- ============================================================
-- STEP 1: Add Cycles for Last Year
-- ============================================================

INSERT INTO cycles (id, user_id, peptide_name, dose, route, frequency, duration_weeks, start_date, end_date, is_active, created_at)
VALUES
  -- Q1 2025: Injury Recovery Focus
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'BPC-157 + TB-500', 250, 'subcutaneous', '1x daily + 2x weekly', 4, '2025-01-06', '2025-02-02', false, '2025-01-06'),
  
  -- Q1 2025: Hair & Skin
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'GHK-Cu + Semax', 200, 'topical + nasal', '1x daily', 6, '2025-02-10', '2025-03-23', false, '2025-02-10'),
  
  -- Q2 2025: Longevity Focus
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'Epitalon + Thymosin Alpha-1', 100, 'subcutaneous', '1x daily', 6, '2025-04-01', '2025-05-12', false, '2025-04-01'),
  
  -- Q2 2025: Preventative Health
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'Thymosin Alpha-1', 1, 'subcutaneous', '1x daily', 6, '2025-05-20', '2025-07-01', false, '2025-05-20'),
  
  -- Q3 2025: Recovery & Performance
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'CJC-1295 + peptide blend', 100, 'subcutaneous', '1x daily', 7, '2025-07-15', '2025-08-30', false, '2025-07-15'),
  
  -- Q3/Q4 2025: Skin Recovery
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), 'GHK-Cu + BPC-157', 200, 'subcutaneous + topical', '1x daily', 6, '2025-09-01', '2025-10-15', false, '2025-09-01');

-- Get cycle IDs for reference
CREATE TEMP TABLE temp_cycles AS
SELECT id, peptide_name as name FROM cycles WHERE user_id = (SELECT id FROM auth.users LIMIT 1);

-- ============================================================
-- STEP 2: Add Dose Logs Throughout the Year
-- ============================================================

-- Cycle 1: BPC-157 & TB-500 (Jan-Feb)
INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 250, d::timestamp with time zone, 'subcutaneous', 'abdomen', 'BPC-157 daily for injury'
FROM (
  SELECT generate_series('2025-01-06'::date, '2025-02-02'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500') c;

INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 5, d::timestamp with time zone, 'intramuscular', 'shoulder', 'TB-500 2x/week for recovery'
FROM (
  SELECT generate_series('2025-01-06'::date, '2025-02-02'::date, '3.5 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500') c;

-- Cycle 2: GHK-Cu & Semax (Feb-Mar)
INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 200, d::timestamp with time zone, 'topical', 'face', 'GHK-Cu topical for skin'
FROM (
  SELECT generate_series('2025-02-10'::date, '2025-03-23'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax') c;

INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 5, d::timestamp with time zone, 'nasal', 'intranasal', 'Semax nasal spray for cognition'
FROM (
  SELECT generate_series('2025-02-10'::date, '2025-03-23'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax') c;

-- Cycle 3: Epitalon & Thymosin (Apr-May)
INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 100, d::timestamp with time zone, 'subcutaneous', 'abdomen', 'Epitalon daily for longevity'
FROM (
  SELECT generate_series('2025-04-01'::date, '2025-05-12'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'Epitalon + Thymosin Alpha-1') c;

INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 1, d::timestamp with time zone, 'subcutaneous', 'abdomen', 'Thymosin Alpha-1 daily'
FROM (
  SELECT generate_series('2025-04-01'::date, '2025-05-12'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'Epitalon + Thymosin Alpha-1') c;

-- Additional cycles (abbreviated for brevity)
INSERT INTO dose_logs (id, user_id, cycle_id, dose_amount, logged_at, route, location, notes)
SELECT uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), id, 100, d::timestamp with time zone, 'subcutaneous', 'abdomen', 'CJC-1295 daily'
FROM (
  SELECT generate_series('2025-07-15'::date, '2025-08-30'::date, '1 day'::interval)::date as d
) dates, (SELECT id FROM temp_cycles WHERE name = 'CJC-1295 + peptide blend') c;

-- ============================================================
-- STEP 3: Add Side Effects Logs
-- ============================================================

INSERT INTO side_effects_log (id, user_id, cycle_id, symptom, severity, notes, logged_at)
VALUES
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500'), 'Mild injection site soreness', 2, 'BPC-157 injection site', '2025-01-10'::timestamp with time zone),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500'), 'Shoulder pain relief', 1, 'Improvement noticed', '2025-01-20'::timestamp with time zone),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax'), 'Increased hair shedding (normal)', 3, 'Semax effect', '2025-02-15'::timestamp with time zone),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax'), 'Skin clarity improved', 1, 'GHK-Cu working well', '2025-03-05'::timestamp with time zone),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'Epitalon + Thymosin Alpha-1'), 'Sleep quality improved', 1, 'Epitalon effect', '2025-04-15'::timestamp with time zone),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'CJC-1295 + peptide blend'), 'Increased energy', 1, 'CJC-1295 kicking in', '2025-07-25'::timestamp with time zone);

-- ============================================================
-- STEP 4: Add Weight Logs (Progressive improvement)
-- ============================================================

INSERT INTO weight_logs (id, user_id, logged_at, weight_lbs, body_fat_percent, notes)
VALUES
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-01-01'::date, 185.0, 18.5, 'Baseline weight'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-01-15'::date, 183.5, 17.8, 'During injury recovery'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-02-01'::date, 182.0, 17.2, 'End of recovery cycle'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-03-01'::date, 180.5, 16.5, 'Hair & skin cycle'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-04-01'::date, 179.0, 15.8, 'Longevity cycle start'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-05-01'::date, 177.5, 15.0, 'Lean gains'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-06-01'::date, 176.0, 14.5, 'Continued progress'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-07-01'::date, 175.5, 14.2, 'Pre-performance cycle'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-08-01'::date, 176.5, 14.0, 'Muscle gain during cycle'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-09-01'::date, 178.0, 14.5, 'Maintenance phase'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-10-01'::date, 177.0, 14.1, 'End of year'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), '2025-12-31'::date, 176.0, 13.8, 'Year end - best condition');

-- ============================================================
-- STEP 5: Add Lab Results Throughout Year
-- ============================================================

INSERT INTO labs_results (id, user_id, cycle_id, pdf_file_path, extracted_data, upload_date, processed_date, notes)
VALUES
  ('lab-2025-01-'||gen_random_uuid()::text, (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500'), '/labs/jan-2025.pdf',
   '{"testosterone": {"value": 650, "status": "OPTIMAL", "percentile": 75}, "cortisol": {"value": 12, "status": "NORMAL"}, "glucose": {"value": 95, "status": "NORMAL"}, "cholesterol": {"hdl": 50, "ldl": 110, "total": 185, "triglycerides": 90}}'::jsonb,
   '2025-02-03'::timestamp with time zone, '2025-02-03'::timestamp with time zone, 'Post-injury, testosterone stable'),
   
  ('lab-2025-02-'||gen_random_uuid()::text, (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax'), '/labs/mar-2025.pdf',
   '{"testosterone": {"value": 670, "status": "OPTIMAL", "percentile": 78}, "cortisol": {"value": 10, "status": "NORMAL"}, "glucose": {"value": 92, "status": "NORMAL"}, "cholesterol": {"hdl": 55, "ldl": 105, "total": 180, "triglycerides": 85}}'::jsonb,
   '2025-03-25'::timestamp with time zone, '2025-03-25'::timestamp with time zone, 'Improved lipids, better cortisol control'),
   
  ('lab-2025-03-'||gen_random_uuid()::text, (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'Epitalon + Thymosin Alpha-1'), '/labs/may-2025.pdf',
   '{"testosterone": {"value": 680, "status": "OPTIMAL", "percentile": 80}, "cortisol": {"value": 9, "status": "NORMAL"}, "glucose": {"value": 90, "status": "NORMAL"}, "cholesterol": {"hdl": 60, "ldl": 100, "total": 175, "triglycerides": 78}}'::jsonb,
   '2025-05-15'::timestamp with time zone, '2025-05-15'::timestamp with time zone, 'Excellent metrics post-longevity cycle'),
   
  ('lab-2025-04-'||gen_random_uuid()::text, (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'CJC-1295 + peptide blend'), '/labs/sep-2025.pdf',
   '{"testosterone": {"value": 700, "status": "OPTIMAL", "percentile": 85}, "cortisol": {"value": 8, "status": "NORMAL"}, "glucose": {"value": 88, "status": "NORMAL"}, "cholesterol": {"hdl": 65, "ldl": 95, "total": 170, "triglycerides": 70}}'::jsonb,
   '2025-09-10'::timestamp with time zone, '2025-09-10'::timestamp with time zone, 'Peak performance metrics');

-- ============================================================
-- STEP 6: Add Cycle Reviews (Effectiveness Ratings)
-- ============================================================

INSERT INTO cycle_reviews (id, user_id, cycle_id, effectiveness_rating, notes)
VALUES
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'BPC-157 + TB-500'), 9, 'Excellent recovery. Shoulder pain reduced 80%. BPC-157 + TB-500 highly effective.'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + Semax'), 8, 'Good results. Hair thickness improved, skin clarity exceptional. Some shedding early on.'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'Epitalon + Thymosin Alpha-1'), 9, 'Sleep quality improved significantly. Energy levels sustained. Recommend repeat.'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'Thymosin Alpha-1'), 7, 'Steady immune support. Subtle effects but stable health throughout cycle.'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'CJC-1295 + peptide blend'), 10, 'Outstanding. Strength gains, rapid recovery. Best cycle of the year.'),
  (uuid_generate_v4(), (SELECT id FROM auth.users LIMIT 1), (SELECT id FROM temp_cycles WHERE name = 'GHK-Cu + BPC-157'), 8, 'Good skin recovery. Fine lines reduced. Collagen support evident.');

-- ============================================================
-- CLEANUP
-- ============================================================
DROP TABLE temp_cycles;

-- ============================================================
-- VERIFICATION QUERIES (Run these to verify data loaded)
-- ============================================================
-- SELECT COUNT(*) as cycle_count FROM cycles WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- SELECT COUNT(*) as dose_log_count FROM dose_logs WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- SELECT COUNT(*) as side_effects_count FROM side_effects_log WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- SELECT COUNT(*) as weight_log_count FROM weight_logs WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- SELECT COUNT(*) as lab_result_count FROM labs_results WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
-- SELECT COUNT(*) as cycle_review_count FROM cycle_reviews WHERE user_id = (SELECT id FROM auth.users LIMIT 1);
