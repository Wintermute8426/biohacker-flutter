-- Phase 10A: User Profiles & Onboarding
-- Production-grade schema for user onboarding

-- 1. User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  health_goals TEXT[], -- Array: ["muscle", "recovery", "longevity", "metabolic", "sleep", "immune"]
  baseline_weight FLOAT,
  baseline_body_fat FLOAT,
  baseline_labs JSONB, -- {"testosterone": 650, "igf1": 210, "cortisol": 15.2}
  timezone TEXT DEFAULT 'America/New_York',
  onboarding_completed BOOLEAN DEFAULT FALSE,
  onboarding_completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dose_reminders_enabled BOOLEAN DEFAULT TRUE,
  dose_reminder_minutes INTEGER DEFAULT 60, -- minutes before scheduled dose
  missed_dose_alerts BOOLEAN DEFAULT TRUE,
  lab_alerts BOOLEAN DEFAULT TRUE,
  protocol_review_reminders BOOLEAN DEFAULT TRUE,
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME DEFAULT '22:00', -- 10 PM
  quiet_hours_end TIME DEFAULT '08:00',   -- 8 AM
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Dose Schedules Table (for calendar + notifications)
CREATE TABLE IF NOT EXISTS dose_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  dose_amount FLOAT NOT NULL,
  route TEXT NOT NULL, -- IM, SC, IV
  scheduled_time TIME NOT NULL, -- 08:00 format (user's timezone)
  days_of_week INTEGER[] NOT NULL, -- [1,3,5] for Mon/Wed/Fri (0=Sunday, 6=Saturday)
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Dashboard Snapshots (for performance caching)
CREATE TABLE IF NOT EXISTS dashboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  compliance_rate FLOAT, -- 0-100
  doses_logged INTEGER,
  doses_scheduled INTEGER,
  top_peptide TEXT,
  top_peptide_rating FLOAT,
  side_effects_data JSONB,
  lab_correlations JSONB,
  cost_per_dose FLOAT,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '24 hours'
);

-- 5. Audit Log (for compliance + debugging)
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL, -- "dose_logged", "cycle_created", "profile_updated"
  entity_type TEXT, -- "dose", "cycle", "protocol"
  entity_id UUID,
  changes JSONB, -- {"field": "old_value", "field": "new_value"}
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dose_schedules_user_id ON dose_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_dose_schedules_user_date ON dose_schedules(user_id, start_date);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE dose_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only see their own data
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own notification preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own dose schedules"
  ON dose_schedules FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own dose schedules"
  ON dose_schedules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own dose schedules"
  ON dose_schedules FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own dashboard snapshots"
  ON dashboard_snapshots FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own audit log"
  ON audit_log FOR SELECT
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dose_schedules_updated_at
  BEFORE UPDATE ON dose_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
