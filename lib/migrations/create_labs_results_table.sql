-- Create labs_results table for BloodworkAI integration
CREATE TABLE IF NOT EXISTS labs_results (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id TEXT REFERENCES cycles(id) ON DELETE SET NULL,
  pdf_file_path TEXT NOT NULL,
  extracted_data JSONB NOT NULL DEFAULT '{}',
  upload_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  processed_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index for faster queries by user
CREATE INDEX IF NOT EXISTS idx_labs_results_user_id ON labs_results(user_id);
CREATE INDEX IF NOT EXISTS idx_labs_results_cycle_id ON labs_results(cycle_id);
CREATE INDEX IF NOT EXISTS idx_labs_results_upload_date ON labs_results(upload_date DESC);

-- Enable RLS
ALTER TABLE labs_results ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own lab results
CREATE POLICY "Users can view own labs results"
ON labs_results FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can only insert their own lab results
CREATE POLICY "Users can insert own labs results"
ON labs_results FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own lab results
CREATE POLICY "Users can update own labs results"
ON labs_results FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only delete their own lab results
CREATE POLICY "Users can delete own labs results"
ON labs_results FOR DELETE
USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON labs_results TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON labs_results TO anon;
