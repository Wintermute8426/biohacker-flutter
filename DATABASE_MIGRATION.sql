-- Profile Screen Database Migration
-- Adds Tier 1 + Tier 2 user data fields to user_profiles table
-- Version: 1.0
-- Date: 2026-03-10

-- ============================================
-- 1. ADD NEW COLUMNS TO user_profiles
-- ============================================

-- Add username (unique identifier)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Add age
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add gender (enum-like constraint)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS gender TEXT;

-- Add height in centimeters
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS height_cm INTEGER;

-- Add allergies (nullable text field)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS allergies TEXT;

-- Add medical_conditions (JSON array of strings)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS medical_conditions JSONB DEFAULT '[]'::jsonb;

-- ============================================
-- 2. ADD CONSTRAINTS
-- ============================================

-- Username constraints
ALTER TABLE user_profiles 
ADD CONSTRAINT username_length CHECK (char_length(username) >= 1 AND char_length(username) <= 50);

ALTER TABLE user_profiles 
ADD CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$');

-- Age constraints
ALTER TABLE user_profiles 
ADD CONSTRAINT age_range CHECK (age >= 10 AND age <= 120);

-- Gender constraints (enum-like)
ALTER TABLE user_profiles 
ADD CONSTRAINT gender_values CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'));

-- Height constraints
ALTER TABLE user_profiles 
ADD CONSTRAINT height_range CHECK (height_cm >= 50 AND height_cm <= 300);

-- Allergies max length
ALTER TABLE user_profiles 
ADD CONSTRAINT allergies_length CHECK (char_length(allergies) <= 500);

-- ============================================
-- 3. CREATE INDEX FOR USERNAME LOOKUPS
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);

-- ============================================
-- 4. ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN user_profiles.username IS 'Unique username (1-50 chars, alphanumeric + underscore)';
COMMENT ON COLUMN user_profiles.age IS 'User age in years (10-120)';
COMMENT ON COLUMN user_profiles.gender IS 'Gender: male, female, other, prefer_not_to_say';
COMMENT ON COLUMN user_profiles.height_cm IS 'Height in centimeters (50-300)';
COMMENT ON COLUMN user_profiles.allergies IS 'Allergies (max 500 chars)';
COMMENT ON COLUMN user_profiles.medical_conditions IS 'JSON array of medical conditions (e.g., ["diabetes", "hypertension"])';

-- ============================================
-- 5. SAMPLE MEDICAL CONDITIONS VALUES
-- ============================================

-- Valid medical_conditions examples:
-- '[]'::jsonb (none)
-- '["diabetes"]'::jsonb
-- '["diabetes", "hypertension", "heart_disease"]'::jsonb
-- '["thyroid_issues", "other: Asthma"]'::jsonb

-- ============================================
-- 6. MIGRATION VERIFICATION QUERY
-- ============================================

-- Run this to verify migration:
/*
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
  AND column_name IN ('username', 'age', 'gender', 'height_cm', 'allergies', 'medical_conditions')
ORDER BY ordinal_position;
*/

-- ============================================
-- 7. ROLLBACK SCRIPT (IF NEEDED)
-- ============================================

-- CAUTION: This will delete all new data!
/*
ALTER TABLE user_profiles DROP COLUMN IF EXISTS username CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS age CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS gender CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_cm CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS allergies CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS medical_conditions CASCADE;
DROP INDEX IF EXISTS idx_user_profiles_username;
*/

-- ============================================
-- 8. DATA MIGRATION (OPTIONAL)
-- ============================================

-- If migrating from old baseline_weight to new structure:
/*
UPDATE user_profiles
SET age = 30  -- placeholder age for existing users
WHERE age IS NULL;
*/

-- ============================================
-- END OF MIGRATION
-- ============================================

-- Run this migration in Supabase SQL Editor or via Supabase CLI:
-- supabase db push

-- Production checklist:
-- ✅ Test migration on staging database
-- ✅ Backup production database before running
-- ✅ Verify constraints work with test data
-- ✅ Update RLS policies if needed (existing policies cover new columns)
-- ✅ Run verification query to confirm schema changes
