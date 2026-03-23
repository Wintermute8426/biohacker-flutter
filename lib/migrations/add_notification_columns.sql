-- Phase 10B: Add missing notification preference columns
-- Run this after create_notification_preferences.sql

ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS dose_reminder_time TEXT DEFAULT '08:00',
  ADD COLUMN IF NOT EXISTS lab_reminder_frequency TEXT DEFAULT 'every_3_months',
  ADD COLUMN IF NOT EXISTS cycle_milestones_enabled BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS research_updates_enabled BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS side_effects_enabled BOOLEAN DEFAULT TRUE;

-- Add comment documenting the lab_reminder_frequency values
COMMENT ON COLUMN notification_preferences.lab_reminder_frequency IS
  'One of: never, monthly, every_3_months, every_6_months';

-- Add comment documenting the dose_reminder_time format
COMMENT ON COLUMN notification_preferences.dose_reminder_time IS
  'HH:MM format, e.g. 08:00. This is the time the dose reminder fires.';
