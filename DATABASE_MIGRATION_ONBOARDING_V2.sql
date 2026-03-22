-- =====================================================
-- ONBOARDING V2 MIGRATION
-- Run this in the Supabase SQL Editor
-- Adds new columns for the redesigned onboarding flow
-- =====================================================

-- New columns on user_profiles for peptide history & status
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS used_peptides_before BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS previous_peptides JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS peptide_experience_duration TEXT,
  ADD COLUMN IF NOT EXISTS cycle_status TEXT DEFAULT 'not_on_cycle',
  ADD COLUMN IF NOT EXISTS training_level TEXT DEFAULT 'moderate',
  ADD COLUMN IF NOT EXISTS bloodwork_frequency TEXT DEFAULT 'never',
  ADD COLUMN IF NOT EXISTS last_lab_date TEXT;

-- New columns on notification_preferences for V2 notification types
ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS dose_reminder_time TEXT DEFAULT '08:00',
  ADD COLUMN IF NOT EXISTS lab_reminder_frequency TEXT DEFAULT 'every_3_months',
  ADD COLUMN IF NOT EXISTS cycle_milestones_enabled BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS research_updates_enabled BOOLEAN DEFAULT TRUE;

-- Update RLS policies if needed (these columns inherit existing row-level security)
-- No additional RLS changes required since they follow the same user_id pattern
