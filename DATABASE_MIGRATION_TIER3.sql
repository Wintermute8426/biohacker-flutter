-- Profile Screen Database Migration - Tier 3 Features
-- Adds notification preferences, health goals, units, contact method, and bio
-- Version: 3.0
-- Date: 2026-03-10
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. ADD NEW COLUMNS TO user_profiles
-- ============================================

-- Notification preferences (JSONB)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"email": true, "push": false, "sms": false}'::jsonb;

-- Health goals (JSONB array)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS health_goals_list JSONB DEFAULT '[]'::jsonb;

-- Units preference (text: 'metric' or 'imperial')
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS units_preference TEXT DEFAULT 'imperial';

-- Preferred contact method (text: 'email', 'phone', 'push')
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS contact_method TEXT DEFAULT 'email';

-- Bio (optional text, max 200 chars)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- ============================================
-- 2. ADD CONSTRAINTS
-- ============================================

-- Units preference constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS units_preference_values;
ALTER TABLE user_profiles 
ADD CONSTRAINT units_preference_values CHECK (units_preference IN ('metric', 'imperial'));

-- Contact method constraint
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS contact_method_values;
ALTER TABLE user_profiles 
ADD CONSTRAINT contact_method_values CHECK (contact_method IN ('email', 'phone', 'push'));

-- Bio max length
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS bio_length;
ALTER TABLE user_profiles 
ADD CONSTRAINT bio_length CHECK (char_length(bio) <= 200);

-- ============================================
-- 3. ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN user_profiles.notification_preferences IS 'JSONB object: {email: bool, push: bool, sms: bool}';
COMMENT ON COLUMN user_profiles.health_goals_list IS 'JSONB array: ["longevity", "recovery", "hormone_optimization", "athletic_performance", "weight_loss", "other"]';
COMMENT ON COLUMN user_profiles.units_preference IS 'Preferred unit system: metric or imperial';
COMMENT ON COLUMN user_profiles.contact_method IS 'Preferred contact method: email, phone, or push';
COMMENT ON COLUMN user_profiles.bio IS 'Optional user bio (max 200 characters)';

-- ============================================
-- 4. VERIFY COLUMNS EXIST
-- ============================================

-- Query to verify new columns
SELECT 
    column_name, 
    data_type, 
    column_default, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name IN (
    'notification_preferences', 
    'health_goals_list', 
    'units_preference', 
    'contact_method', 
    'bio'
)
ORDER BY column_name;

-- ============================================
-- ROLLBACK SCRIPT (run if you need to undo)
-- ============================================

-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS notification_preferences;
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS health_goals_list;
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS units_preference;
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS contact_method;
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS bio;
