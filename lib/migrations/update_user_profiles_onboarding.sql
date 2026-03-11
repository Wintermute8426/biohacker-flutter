-- Phase 10A: Add onboarding fields to user_profiles table
-- This migration adds fields for the new onboarding flow

-- Add experience_level (beginner, intermediate, advanced)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS experience_level TEXT
CHECK (experience_level IN ('beginner', 'intermediate', 'advanced'))
DEFAULT 'beginner';

-- Add health_goals (array of goal slugs)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS health_goals TEXT[] DEFAULT '{}';

-- Add baseline_weight (in lbs or kg based on user preference)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS baseline_weight FLOAT;

-- Add baseline_body_fat (percentage)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS baseline_body_fat FLOAT
CHECK (baseline_body_fat >= 0 AND baseline_body_fat <= 50);

-- Add baseline_labs (JSONB for lab values like testosterone, IGF-1, etc.)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS baseline_labs JSONB;

-- Add onboarding_completed flag
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;

-- Add onboarding_completed_at timestamp
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP;

-- Create index for faster onboarding status checks
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding
ON user_profiles(onboarding_completed);

-- Update existing profiles to mark as completed (so they don't see onboarding)
UPDATE user_profiles
SET onboarding_completed = TRUE,
    onboarding_completed_at = NOW()
WHERE onboarding_completed IS NULL OR onboarding_completed = FALSE;
