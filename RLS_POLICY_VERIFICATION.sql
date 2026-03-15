-- ============================================
-- RLS POLICY VERIFICATION SCRIPT
-- ============================================
-- Run this in Supabase SQL Editor to verify all RLS policies are properly configured
-- Date: 2026-03-15

-- ============================================
-- 1. CHECK ALL TABLES HAVE RLS ENABLED
-- ============================================

SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'cycles', 'dose_logs', 'side_effects_log', 'weight_logs',
    'protocol_templates', 'peptide_inventory', 'cycle_expenses',
    'cycle_reviews', 'health_goals', 'user_profiles',
    'notification_preferences', 'dose_schedules', 'dashboard_snapshots',
    'labs_results', 'audit_log'
  )
ORDER BY tablename;

-- ============================================
-- 2. CHECK ALL POLICIES BY TABLE
-- ============================================

SELECT
    tablename,
    policyname,
    cmd,
    CASE
        WHEN cmd = 'SELECT' THEN '📖 READ'
        WHEN cmd = 'INSERT' THEN '➕ CREATE'
        WHEN cmd = 'UPDATE' THEN '✏️ UPDATE'
        WHEN cmd = 'DELETE' THEN '🗑️ DELETE'
        ELSE cmd
    END as operation,
    permissive,
    roles
FROM pg_policies
WHERE tablename IN (
    'cycles', 'dose_logs', 'side_effects_log', 'weight_logs',
    'protocol_templates', 'peptide_inventory', 'cycle_expenses',
    'cycle_reviews', 'health_goals', 'user_profiles',
    'notification_preferences', 'dose_schedules', 'dashboard_snapshots',
    'labs_results', 'audit_log'
)
ORDER BY tablename, cmd;

-- ============================================
-- 3. FIND TABLES MISSING POLICIES
-- ============================================

-- Check for tables with RLS enabled but missing standard CRUD policies
WITH table_policies AS (
  SELECT
    tablename,
    BOOL_OR(cmd = 'SELECT') as has_select,
    BOOL_OR(cmd = 'INSERT') as has_insert,
    BOOL_OR(cmd = 'UPDATE') as has_update,
    BOOL_OR(cmd = 'DELETE') as has_delete
  FROM pg_policies
  WHERE tablename IN (
    'cycles', 'dose_logs', 'side_effects_log', 'weight_logs',
    'protocol_templates', 'peptide_inventory', 'cycle_expenses',
    'cycle_reviews', 'health_goals', 'user_profiles',
    'notification_preferences', 'dose_schedules', 'dashboard_snapshots',
    'labs_results', 'audit_log'
  )
  GROUP BY tablename
)
SELECT
  tablename,
  CASE WHEN NOT has_select THEN '❌ Missing SELECT' ELSE '✅ Has SELECT' END as select_policy,
  CASE WHEN NOT has_insert THEN '❌ Missing INSERT' ELSE '✅ Has INSERT' END as insert_policy,
  CASE WHEN NOT has_update THEN '❌ Missing UPDATE' ELSE '✅ Has UPDATE' END as update_policy,
  CASE WHEN NOT has_delete THEN '❌ Missing DELETE' ELSE '✅ Has DELETE' END as delete_policy
FROM table_policies
ORDER BY tablename;

-- ============================================
-- 4. CHECK AUDIT_LOG SPECIAL CASE
-- ============================================
-- audit_log should have SELECT and INSERT but not UPDATE/DELETE

SELECT
    tablename,
    policyname,
    cmd,
    CASE
        WHEN cmd IN ('SELECT', 'INSERT') THEN '✅ Correct for audit log'
        WHEN cmd IN ('UPDATE', 'DELETE') THEN '⚠️ Unexpected for audit log'
        ELSE '❓ Unknown operation'
    END as status
FROM pg_policies
WHERE tablename = 'audit_log';

-- ============================================
-- 5. VERIFY POLICY LOGIC
-- ============================================
-- Check that all policies properly check auth.uid() = user_id

SELECT
    tablename,
    policyname,
    cmd,
    qual as using_clause,
    with_check,
    CASE
        WHEN qual::text LIKE '%auth.uid()%user_id%' OR with_check::text LIKE '%auth.uid()%user_id%'
        THEN '✅ Properly checks user_id'
        ELSE '⚠️ May not check user_id properly'
    END as security_check
FROM pg_policies
WHERE tablename IN (
    'cycles', 'dose_logs', 'side_effects_log', 'weight_logs',
    'protocol_templates', 'peptide_inventory', 'cycle_expenses',
    'cycle_reviews', 'health_goals', 'user_profiles',
    'notification_preferences', 'dose_schedules', 'dashboard_snapshots',
    'labs_results', 'audit_log'
)
ORDER BY tablename, cmd;

-- ============================================
-- 6. RECOMMENDED FIXES
-- ============================================

-- If audit_log is missing INSERT policy, add it:
-- CREATE POLICY "Allow insert into audit_log" ON audit_log
--   FOR INSERT
--   TO authenticated
--   WITH CHECK (auth.uid() = user_id);

-- If any table is missing policies, follow this template:
-- CREATE POLICY "Users can [operation] their own [table]" ON [table]
--   FOR [SELECT/INSERT/UPDATE/DELETE]
--   TO authenticated
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 7. TEST RLS POLICIES
-- ============================================
-- Run these as an authenticated user to ensure policies work

-- Test SELECT (should only return your own data):
-- SELECT COUNT(*) FROM cycles WHERE user_id = auth.uid();

-- Test INSERT (should succeed):
-- INSERT INTO cycles (user_id, peptide_name, dose, route, start_date, end_date)
-- VALUES (auth.uid(), 'Test', 1.0, 'IM', CURRENT_DATE, CURRENT_DATE + interval '30 days');

-- Test UPDATE (should succeed on your own data):
-- UPDATE cycles SET notes = 'Test update' WHERE user_id = auth.uid() LIMIT 1;

-- Test DELETE (should succeed on your own data):
-- DELETE FROM cycles WHERE user_id = auth.uid() AND peptide_name = 'Test';

-- ============================================
-- END OF VERIFICATION SCRIPT
-- ============================================
