-- Create protocol_templates table
CREATE TABLE IF NOT EXISTS protocol_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  peptide_name TEXT NOT NULL,
  dose DECIMAL NOT NULL,
  route TEXT NOT NULL,
  frequency TEXT NOT NULL,
  duration_weeks INTEGER NOT NULL,
  usage_count INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE protocol_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own protocols and public protocols" ON protocol_templates
  FOR SELECT USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can insert own protocols" ON protocol_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own protocols" ON protocol_templates
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own protocols" ON protocol_templates
  FOR DELETE USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS protocol_templates_user_usage 
  ON protocol_templates(user_id, usage_count DESC);
