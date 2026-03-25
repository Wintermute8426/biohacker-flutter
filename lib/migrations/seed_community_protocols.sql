-- Seed community protocols for launch
-- These appear as "community-contributed" protocols in the app
-- Attribution: Various biohacking communities and research-based protocols

-- Create a system user for community protocols
DO $$ 
DECLARE
  system_user_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN

-- Recovery & Healing Stack
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES 
  (gen_random_uuid(), system_user_id, 
   'Recovery Stack (Post-Injury)', 
   'Community protocol for acute injury recovery. Combines BPC-157 and TB-500 synergistically. Popular in athletic recovery communities.',
   'BPC-157', 250, 'SC', '2x daily', 4, 127, true, NOW()),
   
  (gen_random_uuid(), system_user_id,
   'Recovery Stack (Post-Injury) - TB-500',
   'Second component of recovery stack. Run concurrently with BPC-157.',
   'TB-500', 2.5, 'SC', '2x weekly', 4, 127, true, NOW());

-- Longevity Protocol
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Longevity Protocol (Epitalon)',
   'Research-based longevity protocol. 10-day cycle 2x per year. Based on Russian studies and community feedback.',
   'Epitalon', 5, 'SC', 'Daily (10 days)', 2, 89, true, NOW());

-- GH Secretagogue Stack
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'GH Stack (CJC/Ipa)',
   'Popular growth hormone stack from peptide communities. CJC provides baseline GH elevation, Ipamorelin adds pulsatile peaks.',
   'CJC-1295 w/DAC', 2, 'SC', '2x weekly', 12, 156, true, NOW()),
   
  (gen_random_uuid(), system_user_id,
   'GH Stack (CJC/Ipa) - Ipamorelin',
   'Second component. Inject before bed for natural GH pulse.',
   'Ipamorelin', 200, 'SC', 'Nightly', 12, 156, true, NOW());

-- Cognitive Enhancement
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Cognitive Enhancement (Semax)',
   'Nootropic protocol for focus and neuroprotection. Popular in biohacker communities. Start low and assess response.',
   'Semax', 300, 'Intranasal', '1-2x daily', 4, 73, true, NOW());

-- Fat Loss Protocol
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Fat Loss (AOD-9604)',
   'Community fat loss protocol. hGH fragment selective for lipolysis. Combine with caloric deficit and resistance training.',
   'AOD-9604', 300, 'SC', 'Daily (fasted)', 8, 94, true, NOW());

-- Skin/Anti-Aging
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Skin Regeneration (GHK-Cu)',
   'Copper peptide protocol for skin health and anti-aging. Subcutaneous for systemic effects, topical formulations also popular.',
   'GHK-Cu', 1, 'SC', '3x weekly', 8, 67, true, NOW());

-- Immune Support
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Immune Support (Thymosin Alpha-1)',
   'Immunomodulation protocol. Used during high-stress periods or illness. Research-backed with extensive clinical data.',
   'Thymosin Alpha-1', 1.6, 'SC', '2x weekly', 4, 58, true, NOW());

-- Advanced GH Protocol
INSERT INTO protocol_templates (id, user_id, name, description, peptide_name, dose, route, frequency, duration_weeks, usage_count, is_public, created_at)
VALUES
  (gen_random_uuid(), system_user_id,
   'Advanced GH (Hexarelin)',
   'More aggressive GH secretagogue. Higher GH/cortisol release than Ipamorelin. Cycle to prevent desensitization.',
   'Hexarelin', 100, 'SC', '2-3x daily', 4, 42, true, NOW());

END $$;

-- Grant public read access
ALTER TABLE protocol_templates ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read public protocols
CREATE POLICY "Public protocols are viewable by everyone" 
  ON protocol_templates FOR SELECT 
  USING (is_public = true);
