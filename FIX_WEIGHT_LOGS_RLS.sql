-- Fix Weight Logs RLS Policy - Allow READ Access
-- This ensures users can read their own weight logs in the profile screen
-- Date: 2026-03-10
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. CHECK CURRENT RLS POLICIES
-- ============================================

-- View existing policies on weight_logs
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'weight_logs';

-- ============================================
-- 2. ENABLE RLS (if not already enabled)
-- ============================================

ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREATE/UPDATE RLS POLICIES
-- ============================================

-- Drop existing policies if they exist (to recreate them properly)
DROP POLICY IF EXISTS "Users can view their own weight logs" ON weight_logs;
DROP POLICY IF EXISTS "Users can insert their own weight logs" ON weight_logs;
DROP POLICY IF EXISTS "Users can update their own weight logs" ON weight_logs;
DROP POLICY IF EXISTS "Users can delete their own weight logs" ON weight_logs;

-- CREATE: Allow users to SELECT their own weight logs
CREATE POLICY "Users can view their own weight logs"
ON weight_logs
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- CREATE: Allow users to INSERT their own weight logs
CREATE POLICY "Users can insert their own weight logs"
ON weight_logs
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- CREATE: Allow users to UPDATE their own weight logs
CREATE POLICY "Users can update their own weight logs"
ON weight_logs
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- CREATE: Allow users to DELETE their own weight logs
CREATE POLICY "Users can delete their own weight logs"
ON weight_logs
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- ============================================
-- 4. VERIFY POLICIES ARE ACTIVE
-- ============================================

-- Check that policies are now active
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ READ access enabled'
        WHEN cmd = 'INSERT' THEN '✅ INSERT access enabled'
        WHEN cmd = 'UPDATE' THEN '✅ UPDATE access enabled'
        WHEN cmd = 'DELETE' THEN '✅ DELETE access enabled'
    END as status
FROM pg_policies
WHERE tablename = 'weight_logs'
ORDER BY cmd;

-- ============================================
-- 5. TEST QUERY (run this as authenticated user)
-- ============================================

-- This should now work without errors:
-- SELECT weight_kg, logged_at 
-- FROM weight_logs 
-- WHERE user_id = auth.uid() 
-- ORDER BY logged_at DESC 
-- LIMIT 1;

COMMENT ON TABLE weight_logs IS 'User weight tracking with RLS enabled - users can only access their own logs';
