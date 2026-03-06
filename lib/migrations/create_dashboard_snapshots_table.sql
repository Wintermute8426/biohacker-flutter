-- Create dashboard_snapshots table for analytics & insights
CREATE TABLE IF NOT EXISTS dashboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id TEXT NOT NULL,
  
  -- Adherence tracking
  adherence_percent DECIMAL(5, 2),
  total_doses_logged INT DEFAULT 0,
  total_doses_scheduled INT DEFAULT 0,
  
  -- Side effects
  side_effects_count INT DEFAULT 0,
  side_effects_avg_severity DECIMAL(3, 1),
  
  -- Body composition
  weight_change_lbs DECIMAL(5, 2),
  body_fat_change_percent DECIMAL(5, 2),
  
  -- Cost analysis
  cost_total DECIMAL(10, 2) DEFAULT 0,
  cost_per_dose DECIMAL(8, 2),
  
  -- Effectiveness ratings (jsonb)
  effectiveness_scores JSONB, -- {testosterone: 8.5, energy: 7.2, recovery: 7.8, ...}
  
  -- Logged dates for heatmap (array of ISO date strings)
  logged_dates TEXT[] DEFAULT '{}',
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_user_id ON dashboard_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_cycle_id ON dashboard_snapshots(cycle_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_created_at ON dashboard_snapshots(created_at DESC);

-- Enable RLS
ALTER TABLE dashboard_snapshots ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own snapshots" ON dashboard_snapshots
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create snapshots" ON dashboard_snapshots
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own snapshots" ON dashboard_snapshots
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own snapshots" ON dashboard_snapshots
  FOR DELETE
  USING (auth.uid() = user_id);
