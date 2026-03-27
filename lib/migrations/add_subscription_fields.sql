-- Migration: Add subscription fields to users table
-- Run this in Supabase SQL editor

-- Add subscription columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_starts_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_ends_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS user_number INTEGER;

-- Create sequence for user numbering (for first 100 tracking if needed)
CREATE SEQUENCE IF NOT EXISTS user_number_seq START 1;

-- Function to auto-assign user number on signup
CREATE OR REPLACE FUNCTION assign_user_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_number IS NULL THEN
    NEW.user_number := nextval('user_number_seq');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to assign user number
DROP TRIGGER IF EXISTS assign_user_number_trigger ON users;
CREATE TRIGGER assign_user_number_trigger
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION assign_user_number();

-- Function to initialize free trial for new users
CREATE OR REPLACE FUNCTION initialize_free_trial()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.subscription_tier IS NULL OR NEW.subscription_tier = 'free' THEN
    NEW.subscription_tier := 'trial';
    NEW.subscription_starts_at := NOW();
    NEW.subscription_ends_at := NOW() + INTERVAL '30 days';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-start trial on signup
DROP TRIGGER IF EXISTS initialize_trial_trigger ON users;
CREATE TRIGGER initialize_trial_trigger
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION initialize_free_trial();

-- Create subscription purchases table for tracking
CREATE TABLE IF NOT EXISTS subscription_purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL,
  platform TEXT NOT NULL, -- 'android' or 'ios'
  verified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscription_purchases_user_id 
ON subscription_purchases(user_id);

CREATE INDEX IF NOT EXISTS idx_subscription_purchases_active 
ON subscription_purchases(user_id, is_active) 
WHERE is_active = true;

-- Comments for documentation
COMMENT ON COLUMN users.subscription_tier IS 'Subscription tier: free, trial, or premium';
COMMENT ON COLUMN users.subscription_starts_at IS 'When the current subscription started';
COMMENT ON COLUMN users.subscription_ends_at IS 'When the current subscription ends (trial or paid)';
COMMENT ON COLUMN users.user_number IS 'Sequential user number (for first 100 tracking)';
COMMENT ON TABLE subscription_purchases IS 'Tracks verified subscription purchases from app stores';
