-- Fix Missing RLS Policies
-- Date: 2026-03-12
-- This adds missing DELETE and INSERT policies found in code review

-- ============================================
-- 1. DOSE_SCHEDULES - Add DELETE policy
-- ============================================

-- Check existing policies
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'dose_schedules';

-- Add missing DELETE policy
CREATE POLICY IF NOT EXISTS "Users can delete their own dose_schedules"
ON dose_schedules
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================
-- 2. AUDIT_LOG - Add INSERT policy
-- ============================================

-- Check existing policies
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'audit_log';

-- Add missing INSERT policy (needed to actually create audit logs)
CREATE POLICY IF NOT EXISTS "Users can insert their own audit_log entries"
ON audit_log
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 3. NOTIFICATION_PREFERENCES - Add DELETE policy
-- ============================================

-- Check existing policies
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'notification_preferences';

-- Add missing DELETE policy (in case user wants to reset preferences)
CREATE POLICY IF NOT EXISTS "Users can delete their own notification_preferences"
ON notification_preferences
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================
-- 4. USER_PROFILES - Add DELETE policy
-- ============================================

-- Note: Generally users shouldn't delete their profiles (cascade delete from auth.users)
-- But adding for completeness
CREATE POLICY IF NOT EXISTS "Users can delete their own profile"
ON user_profiles
FOR DELETE
TO authenticated
USING (auth.uid() = id);

-- ============================================
-- 5. DASHBOARD_SNAPSHOTS - Add UPDATE policy
-- ============================================

-- Snapshots need to be updatable for cache refresh
CREATE POLICY IF NOT EXISTS "Users can update their own dashboard_snapshots"
ON dashboard_snapshots
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================
-- VERIFY ALL POLICIES
-- ============================================

-- Show all policies for key tables
SELECT
    tablename,
    policyname,
    cmd,
    CASE
        WHEN cmd = 'SELECT' THEN '✅ READ'
        WHEN cmd = 'INSERT' THEN '✅ CREATE'
        WHEN cmd = 'UPDATE' THEN '✅ UPDATE'
        WHEN cmd = 'DELETE' THEN '✅ DELETE'
    END as permission
FROM pg_policies
WHERE tablename IN (
    'dose_schedules',
    'audit_log',
    'notification_preferences',
    'user_profiles',
    'dashboard_snapshots'
)
ORDER BY tablename, cmd;

-- Check for tables missing any CRUD operation
SELECT
    tablename,
    array_agg(cmd ORDER BY cmd) as available_operations
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
HAVING array_agg(cmd ORDER BY cmd) != ARRAY['DELETE', 'INSERT', 'SELECT', 'UPDATE']
ORDER BY tablename;

COMMENT ON POLICY "Users can delete their own dose_schedules" ON dose_schedules
IS 'Fixed 2026-03-12: Missing DELETE policy added';

COMMENT ON POLICY "Users can insert their own audit_log entries" ON audit_log
IS 'Fixed 2026-03-12: Missing INSERT policy added';
