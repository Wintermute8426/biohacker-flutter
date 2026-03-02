-- Create side_effects_log table for tracking symptoms

CREATE TABLE IF NOT EXISTS side_effects_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  symptom TEXT NOT NULL,  -- fatigue, acne, headache, etc.
  severity INTEGER DEFAULT 5,  -- 1-10 scale
  notes TEXT,
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_side_effects_user_id ON side_effects_log(user_id);
CREATE INDEX idx_side_effects_cycle_id ON side_effects_log(cycle_id);
CREATE INDEX idx_side_effects_logged_at ON side_effects_log(logged_at DESC);

ALTER TABLE side_effects_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own side effects"
  ON side_effects_log FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own side effects"
  ON side_effects_log FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own side effects"
  ON side_effects_log FOR DELETE
  USING (auth.uid() = user_id);
