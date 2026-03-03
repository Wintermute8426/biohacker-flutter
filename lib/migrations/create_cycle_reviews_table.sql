-- Create cycle_reviews table
CREATE TABLE IF NOT EXISTS cycle_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  effectiveness_rating INTEGER NOT NULL CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 10),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_cycle_reviews_user_id ON cycle_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_cycle_reviews_cycle_id ON cycle_reviews(cycle_id);

-- Enable Row Level Security
ALTER TABLE cycle_reviews ENABLE ROW LEVEL SECURITY;

-- Create RLS policy: Users can only see their own cycle reviews
CREATE POLICY "Users can view their own cycle reviews"
  ON cycle_reviews
  FOR SELECT
  USING (auth.uid() = user_id);

-- Create RLS policy: Users can insert their own cycle reviews
CREATE POLICY "Users can insert their own cycle reviews"
  ON cycle_reviews
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policy: Users can update their own cycle reviews
CREATE POLICY "Users can update their own cycle reviews"
  ON cycle_reviews
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create RLS policy: Users can delete their own cycle reviews
CREATE POLICY "Users can delete their own cycle reviews"
  ON cycle_reviews
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_cycle_reviews_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cycle_reviews_updated_at
  BEFORE UPDATE ON cycle_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_cycle_reviews_updated_at();
