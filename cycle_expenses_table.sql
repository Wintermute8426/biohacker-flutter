-- Optional: Create cycle_expenses table if not exists
-- (For Phase 10D cost tracking feature)

CREATE TABLE IF NOT EXISTS cycle_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL,
  description TEXT,
  expense_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE cycle_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cycle expenses"
  ON cycle_expenses
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycle expenses"
  ON cycle_expenses
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cycle expenses"
  ON cycle_expenses
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cycle expenses"
  ON cycle_expenses
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create index
CREATE INDEX IF NOT EXISTS idx_cycle_expenses_user_id ON cycle_expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_cycle_expenses_cycle_id ON cycle_expenses(cycle_id);
