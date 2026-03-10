-- Profile Screen Database Migration (Imperial Height Edition)
-- Adds Tier 1 user data fields + Imperial height (feet/inches)
-- Version: 2.0
-- Date: 2026-03-10
-- Changes from v1.0:
--   - Replaced height_cm with height_feet + height_inches
--   - Added conversion helper function

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

-- Add height in IMPERIAL (feet + inches)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS height_feet INTEGER;

ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS height_inches INTEGER;

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
DROP CONSTRAINT IF EXISTS username_length;
ALTER TABLE user_profiles 
ADD CONSTRAINT username_length CHECK (char_length(username) >= 1 AND char_length(username) <= 50);

ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS username_format;
ALTER TABLE user_profiles 
ADD CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$');

-- Age constraints
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS age_range;
ALTER TABLE user_profiles 
ADD CONSTRAINT age_range CHECK (age >= 10 AND age <= 120);

-- Gender constraints (enum-like)
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS gender_values;
ALTER TABLE user_profiles 
ADD CONSTRAINT gender_values CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'));

-- Height constraints (IMPERIAL)
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS height_feet_range;
ALTER TABLE user_profiles 
ADD CONSTRAINT height_feet_range CHECK (height_feet >= 0 AND height_feet <= 9);

ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS height_inches_range;
ALTER TABLE user_profiles 
ADD CONSTRAINT height_inches_range CHECK (height_inches >= 0 AND height_inches <= 11);

-- Allergies max length
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS allergies_length;
ALTER TABLE user_profiles 
ADD CONSTRAINT allergies_length CHECK (char_length(allergies) <= 500);

-- ============================================
-- 3. CREATE INDEX FOR USERNAME LOOKUPS
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);

-- ============================================
-- 4. HELPER FUNCTION: Convert Height to CM
-- ============================================

CREATE OR REPLACE FUNCTION height_to_cm(feet INTEGER, inches INTEGER)
RETURNS FLOAT AS $$
BEGIN
  RETURN ((feet * 12) + inches) * 2.54;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 5. HELPER FUNCTION: Convert CM to Feet/Inches
-- ============================================

CREATE OR REPLACE FUNCTION cm_to_height(cm FLOAT)
RETURNS TABLE(feet INTEGER, inches INTEGER) AS $$
DECLARE
  total_inches INTEGER;
BEGIN
  total_inches := ROUND(cm / 2.54)::INTEGER;
  feet := total_inches / 12;
  inches := total_inches % 12;
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 6. MIGRATE EXISTING height_cm DATA (IF EXISTS)
-- ============================================

-- Convert any existing height_cm values to feet/inches
DO $$
DECLARE
  rec RECORD;
  converted RECORD;
BEGIN
  -- Check if height_cm column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_profiles' AND column_name = 'height_cm'
  ) THEN
    -- Convert existing data
    FOR rec IN 
      SELECT id, height_cm 
      FROM user_profiles 
      WHERE height_cm IS NOT NULL
    LOOP
      SELECT * INTO converted FROM cm_to_height(rec.height_cm::FLOAT);
      UPDATE user_profiles 
      SET height_feet = converted.feet, 
          height_inches = converted.inches
      WHERE id = rec.id;
    END LOOP;
    
    -- Drop old column
    ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_cm CASCADE;
    RAISE NOTICE 'Migrated height_cm to imperial (feet/inches)';
  END IF;
END $$;

-- ============================================
-- 7. ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN user_profiles.username IS 'Unique username (1-50 chars, alphanumeric + underscore)';
COMMENT ON COLUMN user_profiles.age IS 'User age in years (10-120)';
COMMENT ON COLUMN user_profiles.gender IS 'Gender: male, female, other, prefer_not_to_say';
COMMENT ON COLUMN user_profiles.height_feet IS 'Height feet component (0-9)';
COMMENT ON COLUMN user_profiles.height_inches IS 'Height inches component (0-11)';
COMMENT ON COLUMN user_profiles.allergies IS 'Allergies (max 500 chars)';
COMMENT ON COLUMN user_profiles.medical_conditions IS 'JSON array of medical conditions (e.g., ["diabetes", "hypertension"])';
COMMENT ON FUNCTION height_to_cm IS 'Convert imperial height (feet, inches) to centimeters';
COMMENT ON FUNCTION cm_to_height IS 'Convert centimeters to imperial height (feet, inches)';

-- ============================================
-- 8. MIGRATION VERIFICATION QUERY
-- ============================================

-- Run this to verify migration:
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
  AND column_name IN ('username', 'age', 'gender', 'height_feet', 'height_inches', 'allergies', 'medical_conditions')
ORDER BY ordinal_position;

-- Test conversion functions:
-- SELECT height_to_cm(5, 11);  -- Should return ~180.34 cm
-- SELECT * FROM cm_to_height(180.34);  -- Should return (5, 11)

-- ============================================
-- 9. ROLLBACK SCRIPT (IF NEEDED)
-- ============================================

-- CAUTION: This will delete all new data!
/*
ALTER TABLE user_profiles DROP COLUMN IF EXISTS username CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS age CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS gender CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_feet CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_inches CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS allergies CASCADE;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS medical_conditions CASCADE;
DROP INDEX IF EXISTS idx_user_profiles_username;
DROP FUNCTION IF EXISTS height_to_cm(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS cm_to_height(FLOAT) CASCADE;
*/

-- ============================================
-- END OF MIGRATION
-- ============================================

-- Production checklist:
-- ✅ Test migration on staging database
-- ✅ Backup production database before running
-- ✅ Verify constraints work with test data
-- ✅ Update RLS policies if needed (existing policies cover new columns)
-- ✅ Run verification query to confirm schema changes
-- ✅ Test conversion functions with sample data
