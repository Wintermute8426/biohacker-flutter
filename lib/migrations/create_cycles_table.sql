-- Create cycles table for Biohacker app

CREATE TABLE IF NOT EXISTS cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  dose DECIMAL(10, 2) NOT NULL,  -- in mg
  route TEXT NOT NULL,  -- SC, IM, IV, Intranasal, Oral
  frequency TEXT NOT NULL,  -- 1x weekly, 2x weekly, etc.
  duration_weeks INTEGER NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  advanced_schedule JSONB,  -- For ramping/tapering schedules
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_cycles_user_id ON cycles(user_id);
CREATE INDEX idx_cycles_is_active ON cycles(is_active);
CREATE INDEX idx_cycles_created_at ON cycles(created_at DESC);

-- Enable RLS
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only view their own cycles
CREATE POLICY "Users can view their own cycles"
  ON cycles
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own cycles
CREATE POLICY "Users can insert their own cycles"
  ON cycles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own cycles
CREATE POLICY "Users can update their own cycles"
  ON cycles
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can delete their own cycles
CREATE POLICY "Users can delete their own cycles"
  ON cycles
  FOR DELETE
  USING (auth.uid() = user_id);
