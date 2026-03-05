-- Create dose_schedules table for recurring dose schedules
CREATE TABLE IF NOT EXISTS dose_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id TEXT NOT NULL,
  peptide_name TEXT NOT NULL,
  dose_amount DECIMAL(10, 2) NOT NULL,
  route TEXT NOT NULL DEFAULT 'IM', -- IM, SC, IV, PO, Intranasal
  scheduled_time TEXT NOT NULL, -- HH:MM format
  days_of_week INT[] NOT NULL DEFAULT '{}', -- [0-6] representing days
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_dose_schedules_user_id ON dose_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_dose_schedules_cycle_id ON dose_schedules(cycle_id);
CREATE INDEX IF NOT EXISTS idx_dose_schedules_is_active ON dose_schedules(is_active);

-- Enable RLS
ALTER TABLE dose_schedules ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only view their own dose schedules
CREATE POLICY "Users can view their own dose_schedules" ON dose_schedules
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own dose schedules
CREATE POLICY "Users can create dose_schedules" ON dose_schedules
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own dose schedules
CREATE POLICY "Users can update their own dose_schedules" ON dose_schedules
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own dose schedules
CREATE POLICY "Users can delete their own dose_schedules" ON dose_schedules
  FOR DELETE
  USING (auth.uid() = user_id);
