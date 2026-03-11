-- Create dose_logs table for tracking injections

CREATE TABLE IF NOT EXISTS dose_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  schedule_id UUID REFERENCES dose_schedules(id) ON DELETE SET NULL,
  dose_amount DECIMAL(10, 2) NOT NULL,  -- in mg
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
  route TEXT,  -- SC, IM, IV, etc.
  injection_site TEXT,  -- injection site (e.g., "left abdomen")
  status TEXT DEFAULT 'SCHEDULED',  -- SCHEDULED, COMPLETED, MISSED
  symptoms JSONB,  -- Optional symptoms JSON
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_dose_logs_user_id ON dose_logs(user_id);
CREATE INDEX idx_dose_logs_cycle_id ON dose_logs(cycle_id);
CREATE INDEX idx_dose_logs_schedule_id ON dose_logs(schedule_id);
CREATE INDEX idx_dose_logs_logged_at ON dose_logs(logged_at DESC);
CREATE INDEX idx_dose_logs_status ON dose_logs(status);

ALTER TABLE dose_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own dose logs"
  ON dose_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own dose logs"
  ON dose_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own dose logs"
  ON dose_logs FOR DELETE
  USING (auth.uid() = user_id);
