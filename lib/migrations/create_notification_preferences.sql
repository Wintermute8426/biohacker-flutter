-- Phase 10A: Create notification_preferences table
-- Stores user notification settings configured during onboarding

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Dose reminders
  dose_reminders_enabled BOOLEAN DEFAULT TRUE,
  dose_reminder_minutes INTEGER DEFAULT 60, -- Remind X minutes before dose

  -- Quiet hours (no notifications during this time)
  quiet_hours_start TIME DEFAULT '22:00',
  quiet_hours_end TIME DEFAULT '08:00',

  -- Lab alerts (remind to get bloodwork every 3 months)
  lab_alerts_enabled BOOLEAN DEFAULT TRUE,
  lab_alert_interval_days INTEGER DEFAULT 90,

  -- Weekly progress summary
  weekly_progress_enabled BOOLEAN DEFAULT TRUE,
  weekly_progress_day INTEGER DEFAULT 0, -- 0 = Sunday, 6 = Saturday

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only manage their own notification preferences
CREATE POLICY "Users can manage their own notification preferences"
ON notification_preferences
FOR ALL
USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id
ON notification_preferences(user_id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notification_preferences_timestamp
BEFORE UPDATE ON notification_preferences
FOR EACH ROW
EXECUTE FUNCTION update_notification_preferences_updated_at();
