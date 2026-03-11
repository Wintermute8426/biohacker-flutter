-- Phase 10D: Dashboard Insights - Create dashboard_snapshots table
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS dashboard_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Compliance metrics
  compliance_rate FLOAT, -- 0-100 percentage
  total_doses_logged INTEGER DEFAULT 0,
  total_doses_scheduled INTEGER DEFAULT 0,

  -- Top peptide
  top_peptide TEXT,
  top_peptide_rating FLOAT,

  -- Side effects data (JSONB for flexibility)
  side_effects_data JSONB, -- {"peptide_name": {"severity_1": count, "severity_2": count, ...}}

  -- Lab correlations (JSONB)
  lab_correlations JSONB, -- [{"biomarker": "Testosterone", "change": 8.5, "peptides": ["BPC-157", "TB-500"]}]

  -- Cost efficiency
  cost_per_dose FLOAT,
  monthly_cost FLOAT,
  best_value_peptide TEXT,
  least_cost_effective_peptide TEXT,

  -- 30-day timeline data (array of dates when doses were logged)
  logged_dates TEXT[], -- ["2026-03-01", "2026-03-02", ...]

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE dashboard_snapshots ENABLE ROW LEVEL SECURITY;

-- Users can only see their own snapshots
CREATE POLICY "Users can view own dashboard snapshots"
  ON dashboard_snapshots
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own snapshots
CREATE POLICY "Users can insert own dashboard snapshots"
  ON dashboard_snapshots
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own snapshots
CREATE POLICY "Users can update own dashboard snapshots"
  ON dashboard_snapshots
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own snapshots
CREATE POLICY "Users can delete own dashboard snapshots"
  ON dashboard_snapshots
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_user_id ON dashboard_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_snapshots_expires_at ON dashboard_snapshots(expires_at);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_dashboard_snapshots_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dashboard_snapshots_updated_at
  BEFORE UPDATE ON dashboard_snapshots
  FOR EACH ROW
  EXECUTE FUNCTION update_dashboard_snapshots_updated_at();
