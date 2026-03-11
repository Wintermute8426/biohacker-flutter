-- Add missing columns to dose_logs table for calendar functionality

-- Add schedule_id (link to recurring schedules)
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS schedule_id UUID REFERENCES dose_schedules(id) ON DELETE SET NULL;

-- Add status (SCHEDULED/COMPLETED/MISSED)
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'SCHEDULED';

-- Add injection_site (where dose was given)
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS injection_site TEXT;

-- Add symptoms (for side effects tracking)
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS symptoms JSONB;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_dose_logs_schedule_id ON dose_logs(schedule_id);
CREATE INDEX IF NOT EXISTS idx_dose_logs_status ON dose_logs(status);

-- Update RLS policy if needed (should already exist)
-- No changes needed to existing policies
