-- Complete Biohacker Flutter Database Schema
-- All tables with RLS policies for multi-user support

-- 1. CYCLES TABLE (already exists, include for reference)
CREATE TABLE IF NOT EXISTS cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  dose DECIMAL NOT NULL,
  dose_unit TEXT DEFAULT 'mg', -- mg, mcg, IU, ml
  route TEXT NOT NULL, -- SC, IM, IV, Intranasal, Oral
  frequency TEXT NOT NULL, -- 1x/week, 2x/week, 3x/week, daily, 2x daily
  duration_weeks INTEGER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  advanced_schedule JSONB, -- for ramping/tapering
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. DOSE_LOGS TABLE - Track individual doses taken
CREATE TABLE IF NOT EXISTS dose_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  dose_amount DECIMAL NOT NULL,
  dose_unit TEXT DEFAULT 'mg',
  logged_at TIMESTAMPTZ NOT NULL,
  route TEXT, -- SC, IM, IV, Intranasal, Oral
  injection_site TEXT, -- Left shoulder, Right shoulder, Left quad, Right quad, Left glute, Right glute, Left abdomen, Right abdomen, Left arm, Right arm, Left leg, Right leg
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. SIDE_EFFECTS_LOG TABLE - Track side effects per cycle
CREATE TABLE IF NOT EXISTS side_effects_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  symptom TEXT NOT NULL, -- Fatigue, Acne, Headache, Nausea, Insomnia, Joint pain, Muscle soreness, Mood changes, Anxiety, Brain fog, Appetite change, Water retention, Irritability, Other
  severity INTEGER NOT NULL DEFAULT 5, -- 1-10 scale
  notes TEXT,
  logged_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. WEIGHT_LOGS TABLE - Daily weight tracking
CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_lbs DECIMAL NOT NULL,
  body_fat_percent DECIMAL,
  logged_at DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. PROTOCOL_TEMPLATES TABLE - Save cycles as reusable templates
CREATE TABLE IF NOT EXISTS protocol_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  peptide_name TEXT NOT NULL,
  dose DECIMAL NOT NULL,
  dose_unit TEXT DEFAULT 'mg',
  route TEXT NOT NULL,
  frequency TEXT NOT NULL,
  duration_weeks INTEGER NOT NULL,
  advanced_schedule JSONB,
  usage_count INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT false, -- Share with community
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. PEPTIDE_INVENTORY TABLE - Track vials on hand
CREATE TABLE IF NOT EXISTS peptide_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  vial_size_mg DECIMAL NOT NULL,
  vial_size_unit TEXT DEFAULT 'mg',
  quantity_vials INTEGER NOT NULL,
  cost_per_vial DECIMAL NOT NULL,
  purchased_date DATE NOT NULL,
  expiry_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. CYCLE_EXPENSES TABLE - Track spending per cycle
CREATE TABLE IF NOT EXISTS cycle_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  vials_used DECIMAL NOT NULL,
  cost_per_vial DECIMAL NOT NULL,
  total_cost DECIMAL GENERATED ALWAYS AS (vials_used * cost_per_vial) STORED,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. CYCLE_REVIEWS TABLE - Effectiveness & feedback
CREATE TABLE IF NOT EXISTS cycle_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  effectiveness_rating INTEGER NOT NULL, -- 1-10
  would_repeat BOOLEAN,
  results_summary TEXT,
  pros TEXT, -- What worked well
  cons TEXT, -- What didn't work
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. HEALTH_GOALS TABLE - Set targets per cycle
CREATE TABLE IF NOT EXISTS health_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL, -- weight_loss, muscle_gain, strength, recovery, energy, cognitive, other
  target_value DECIMAL,
  target_unit TEXT, -- lbs, kg, %, etc.
  start_value DECIMAL,
  start_date DATE NOT NULL,
  end_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS POLICIES

-- dose_logs RLS
ALTER TABLE dose_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own dose logs" ON dose_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own dose logs" ON dose_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own dose logs" ON dose_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own dose logs" ON dose_logs
  FOR DELETE USING (auth.uid() = user_id);

-- side_effects_log RLS
ALTER TABLE side_effects_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own side effects" ON side_effects_log
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own side effects" ON side_effects_log
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own side effects" ON side_effects_log
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own side effects" ON side_effects_log
  FOR DELETE USING (auth.uid() = user_id);

-- weight_logs RLS
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own weight logs" ON weight_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own weight logs" ON weight_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own weight logs" ON weight_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own weight logs" ON weight_logs
  FOR DELETE USING (auth.uid() = user_id);

-- protocol_templates RLS
ALTER TABLE protocol_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own templates and public templates" ON protocol_templates
  FOR SELECT USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "Users can insert own templates" ON protocol_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own templates" ON protocol_templates
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own templates" ON protocol_templates
  FOR DELETE USING (auth.uid() = user_id);

-- peptide_inventory RLS
ALTER TABLE peptide_inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own inventory" ON peptide_inventory
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own inventory" ON peptide_inventory
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own inventory" ON peptide_inventory
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own inventory" ON peptide_inventory
  FOR DELETE USING (auth.uid() = user_id);

-- cycle_expenses RLS
ALTER TABLE cycle_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own expenses" ON cycle_expenses
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expenses" ON cycle_expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own expenses" ON cycle_expenses
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own expenses" ON cycle_expenses
  FOR DELETE USING (auth.uid() = user_id);

-- cycle_reviews RLS
ALTER TABLE cycle_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own reviews" ON cycle_reviews
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reviews" ON cycle_reviews
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON cycle_reviews
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON cycle_reviews
  FOR DELETE USING (auth.uid() = user_id);

-- health_goals RLS
ALTER TABLE health_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own goals" ON health_goals
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON health_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON health_goals
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own goals" ON health_goals
  FOR DELETE USING (auth.uid() = user_id);

-- cycles RLS (update existing if needed)
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own cycles" ON cycles
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own cycles" ON cycles
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cycles" ON cycles
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own cycles" ON cycles
  FOR DELETE USING (auth.uid() = user_id);
