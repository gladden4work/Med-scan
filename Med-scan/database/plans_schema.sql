-- MediScan Tiered Pricing and User Entitlement System
-- This file contains the database schema for subscription plans and entitlements

-- =====================================================
-- 1. PLAN AND ENTITLEMENT TABLES
-- =====================================================

-- Create plans table to store subscription plan configurations
CREATE TABLE IF NOT EXISTS plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  price DECIMAL(10, 2) DEFAULT 0.00,
  billing_period TEXT DEFAULT 'monthly', -- monthly, yearly
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false,
  metadata JSONB, -- For future extensibility
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create plan_features table to store feature entitlements for each plan
CREATE TABLE IF NOT EXISTS plan_features (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL, -- scan_quota, followup_questions, history_access, medication_list, ads_enabled, 
                             -- scan_limit_daily, scan_limit_monthly, failed_scan_limit_daily, my_medication_limit, scan_history_limit
  value INTEGER, -- Numeric value for the feature limit
  refresh_period TEXT, -- daily, monthly, none (for unlimited)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(plan_id, feature_key) -- Each plan can only have one value per feature
);

-- Create user_plans table to track user subscriptions
CREATE TABLE IF NOT EXISTS user_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES plans(id),
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE, -- NULL for indefinite plans
  is_active BOOLEAN DEFAULT true,
  is_grandfathered BOOLEAN DEFAULT false, -- For legacy plans
  payment_provider TEXT, -- ios, google_play, other
  payment_reference TEXT, -- For tracking external payment IDs
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id) -- Each user can only have one active plan
);

-- Create user_usage table to track feature usage
CREATE TABLE IF NOT EXISTS user_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL, -- scan_quota, followup_questions, etc.
  usage_count INTEGER DEFAULT 0,
  last_reset TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, feature_key) -- One usage record per feature per user
);

-- Create admin_users table to track users with admin privileges
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

-- Plan indexes
CREATE INDEX IF NOT EXISTS idx_plans_is_active ON plans(is_active);
CREATE INDEX IF NOT EXISTS idx_plans_is_default ON plans(is_default);

-- Plan features indexes
CREATE INDEX IF NOT EXISTS idx_plan_features_plan_id ON plan_features(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_features_feature_key ON plan_features(feature_key);

-- User plans indexes
CREATE INDEX IF NOT EXISTS idx_user_plans_user_id ON user_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_user_plans_plan_id ON user_plans(plan_id);
CREATE INDEX IF NOT EXISTS idx_user_plans_is_active ON user_plans(is_active);
CREATE INDEX IF NOT EXISTS idx_user_plans_end_date ON user_plans(end_date);

-- User usage indexes
CREATE INDEX IF NOT EXISTS idx_user_usage_user_id ON user_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_user_usage_feature_key ON user_usage(feature_key);
CREATE INDEX IF NOT EXISTS idx_user_usage_last_reset ON user_usage(last_reset);

-- Admin users index
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON admin_users(user_id);

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) SETUP
-- =====================================================

-- Enable RLS on tables
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Plans policies (admin only for write, public for read)
DROP POLICY IF EXISTS "Anyone can view active plans" ON plans;
DROP POLICY IF EXISTS "Only admins can modify plans" ON plans;

CREATE POLICY "Anyone can view active plans" ON plans
  FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins can modify plans" ON plans
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- Plan features policies (admin only for write, public for read)
DROP POLICY IF EXISTS "Anyone can view plan features" ON plan_features;
DROP POLICY IF EXISTS "Only admins can modify plan features" ON plan_features;

CREATE POLICY "Anyone can view plan features" ON plan_features
  FOR SELECT USING (true);

CREATE POLICY "Only admins can modify plan features" ON plan_features
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- User plans policies (users can view their own, admins can modify)
DROP POLICY IF EXISTS "Users can view own plans" ON user_plans;
DROP POLICY IF EXISTS "Only admins can modify user plans" ON user_plans;

CREATE POLICY "Users can view own plans" ON user_plans
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "Only admins can modify user plans" ON user_plans
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- User usage policies (users can view their own, system can update)
DROP POLICY IF EXISTS "Users can view own usage" ON user_usage;
DROP POLICY IF EXISTS "System can update usage" ON user_usage;

CREATE POLICY "Users can view own usage" ON user_usage
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "System can update usage" ON user_usage
  FOR UPDATE USING (true);

-- Admin users policies (only admins can view and modify)
DROP POLICY IF EXISTS "Only admins can view admin users" ON admin_users;
DROP POLICY IF EXISTS "Only admins can modify admin users" ON admin_users;

CREATE POLICY "Only admins can view admin users" ON admin_users
  FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));

CREATE POLICY "Only admins can modify admin users" ON admin_users
  FOR ALL USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- =====================================================
-- 4. TRIGGERS AND FUNCTIONS
-- =====================================================

-- Create updated_at trigger function (if not already exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_plans_updated_at ON plans;
CREATE TRIGGER update_plans_updated_at 
  BEFORE UPDATE ON plans 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_plan_features_updated_at ON plan_features;
CREATE TRIGGER update_plan_features_updated_at 
  BEFORE UPDATE ON plan_features 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_plans_updated_at ON user_plans;
CREATE TRIGGER update_user_plans_updated_at 
  BEFORE UPDATE ON user_plans 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_usage_updated_at ON user_usage;
CREATE TRIGGER update_user_usage_updated_at 
  BEFORE UPDATE ON user_usage 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. ENTITLEMENT CHECK FUNCTIONS
-- =====================================================

-- Function to check if a user has entitlement for a feature
CREATE OR REPLACE FUNCTION check_user_entitlement(
  p_user_id UUID,
  p_feature_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_entitled BOOLEAN;
  v_limit INTEGER;
  v_usage INTEGER;
  v_refresh_period TEXT;
  v_last_reset TIMESTAMP WITH TIME ZONE;
  v_now TIMESTAMP WITH TIME ZONE := NOW();
BEGIN
  -- Handle anonymous users (not logged in)
  IF p_user_id IS NULL THEN
    -- Get entitlement from the default anonymous plan
    SELECT pf.value INTO v_limit
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Not Logged In)' 
      AND pf.feature_key = p_feature_key;
    
    -- For anonymous users, we track usage by session or IP (not implemented here)
    -- For now, just return whether they have any entitlement
    RETURN v_limit > 0;
  END IF;

  -- For logged in users, get their plan and entitlement
  SELECT 
    pf.value, 
    pf.refresh_period
  INTO 
    v_limit, 
    v_refresh_period
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  JOIN plan_features pf ON p.id = pf.plan_id
  WHERE up.user_id = p_user_id
    AND up.is_active = true
    AND pf.feature_key = p_feature_key;
  
  -- If no plan found, use the default logged-in free plan
  IF v_limit IS NULL THEN
    SELECT 
      pf.value, 
      pf.refresh_period
    INTO 
      v_limit, 
      v_refresh_period
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Logged In)'
      AND pf.feature_key = p_feature_key;
  END IF;
  
  -- If limit is NULL or 0, user has no entitlement
  IF v_limit IS NULL OR v_limit = 0 THEN
    RETURN FALSE;
  END IF;
  
  -- If limit is -1, user has unlimited entitlement
  IF v_limit = -1 THEN
    RETURN TRUE;
  END IF;
  
  -- Get current usage
  SELECT 
    usage_count, 
    last_reset 
  INTO 
    v_usage, 
    v_last_reset
  FROM user_usage
  WHERE user_id = p_user_id
    AND feature_key = p_feature_key;
  
  -- If no usage record, create one
  IF v_usage IS NULL THEN
    INSERT INTO user_usage (user_id, feature_key, usage_count, last_reset)
    VALUES (p_user_id, p_feature_key, 0, v_now);
    
    v_usage := 0;
    v_last_reset := v_now;
  END IF;
  
  -- Check if usage needs to be reset based on refresh period
  IF v_refresh_period = 'daily' AND v_last_reset::date < v_now::date THEN
    -- Reset daily quota at midnight
    UPDATE user_usage 
    SET usage_count = 0, last_reset = v_now
    WHERE user_id = p_user_id AND feature_key = p_feature_key;
    
    v_usage := 0;
  ELSIF v_refresh_period = 'monthly' AND 
        (EXTRACT(MONTH FROM v_last_reset) != EXTRACT(MONTH FROM v_now) OR
         EXTRACT(YEAR FROM v_last_reset) != EXTRACT(YEAR FROM v_now)) THEN
    -- Reset monthly quota at the start of the month
    UPDATE user_usage 
    SET usage_count = 0, last_reset = v_now
    WHERE user_id = p_user_id AND feature_key = p_feature_key;
    
    v_usage := 0;
  END IF;
  
  -- Check if user has remaining quota
  RETURN v_usage < v_limit;
END;
$$;

-- Function to increment usage for a feature
CREATE OR REPLACE FUNCTION increment_feature_usage(
  p_user_id UUID,
  p_feature_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_has_entitlement BOOLEAN;
BEGIN
  -- First check if user has entitlement
  v_has_entitlement := check_user_entitlement(p_user_id, p_feature_key);
  
  -- If user has entitlement, increment usage
  IF v_has_entitlement AND p_user_id IS NOT NULL THEN
    -- Increment usage count
    INSERT INTO user_usage (user_id, feature_key, usage_count, last_reset)
    VALUES (p_user_id, p_feature_key, 1, NOW())
    ON CONFLICT (user_id, feature_key) DO UPDATE
    SET usage_count = user_usage.usage_count + 1;
    
    RETURN TRUE;
  END IF;
  
  RETURN v_has_entitlement;
END;
$$;

-- Function to get user's current usage and limits
CREATE OR REPLACE FUNCTION get_user_quotas(
  p_user_id UUID
)
RETURNS TABLE (
  feature_key TEXT,
  current_usage INTEGER,
  limit_value INTEGER,
  refresh_period TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Handle anonymous users
  IF p_user_id IS NULL THEN
    RETURN QUERY
    SELECT 
      pf.feature_key,
      0::INTEGER AS current_usage,
      pf.value AS limit_value,
      pf.refresh_period
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Not Logged In)';
    
    RETURN;
  END IF;

  -- For logged in users
  RETURN QUERY
  WITH user_plan AS (
    SELECT p.id AS plan_id
    FROM user_plans up
    JOIN plans p ON up.plan_id = p.id
    WHERE up.user_id = p_user_id
      AND up.is_active = true
    UNION ALL
    SELECT p.id
    FROM plans p
    WHERE p.name = 'Free (Logged In)'
    LIMIT 1
  )
  SELECT 
    pf.feature_key,
    COALESCE(uu.usage_count, 0) AS current_usage,
    pf.value AS limit_value,
    pf.refresh_period
  FROM user_plan up
  JOIN plan_features pf ON up.plan_id = pf.plan_id
  LEFT JOIN user_usage uu ON uu.user_id = p_user_id AND uu.feature_key = pf.feature_key;
END;
$$;

-- =====================================================
-- 6. DEFAULT PLAN SETUP
-- =====================================================

-- Create default plans
INSERT INTO plans (name, description, price, is_active, is_default)
VALUES 
  ('Free (Not Logged In)', 'Default plan for users who are not logged in', 0, true, true),
  ('Free (Logged In)', 'Default plan for logged in users', 0, true, false),
  ('Premium', 'Premium subscription with higher limits and no ads', 9.99, true, false)
ON CONFLICT (name) DO NOTHING;

-- Set up feature entitlements for Free (Not Logged In) plan
WITH plan AS (SELECT id FROM plans WHERE name = 'Free (Not Logged In)' LIMIT 1)
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
VALUES
  ((SELECT id FROM plan), 'scan_quota', 3, 'daily'),
  ((SELECT id FROM plan), 'followup_questions', 0, 'daily'),
  ((SELECT id FROM plan), 'history_access', 0, NULL),
  ((SELECT id FROM plan), 'medication_list', 0, NULL),
  ((SELECT id FROM plan), 'ads_enabled', 1, NULL)
ON CONFLICT (plan_id, feature_key) DO UPDATE
SET value = EXCLUDED.value, refresh_period = EXCLUDED.refresh_period;

-- Set up feature entitlements for Free (Logged In) plan
WITH plan AS (SELECT id FROM plans WHERE name = 'Free (Logged In)' LIMIT 1)
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
VALUES
  ((SELECT id FROM plan), 'scan_quota', 5, 'daily'),
  ((SELECT id FROM plan), 'followup_questions', 3, 'daily'),
  ((SELECT id FROM plan), 'history_access', 3, NULL),
  ((SELECT id FROM plan), 'medication_list', 3, NULL),
  ((SELECT id FROM plan), 'ads_enabled', 1, NULL)
ON CONFLICT (plan_id, feature_key) DO UPDATE
SET value = EXCLUDED.value, refresh_period = EXCLUDED.refresh_period;

-- Set up feature entitlements for Premium plan
WITH plan AS (SELECT id FROM plans WHERE name = 'Premium' LIMIT 1)
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
VALUES
  ((SELECT id FROM plan), 'scan_quota', 50, 'monthly'),
  ((SELECT id FROM plan), 'followup_questions', 10, 'daily'),
  ((SELECT id FROM plan), 'history_access', 100, NULL),
  ((SELECT id FROM plan), 'medication_list', 50, NULL),
  ((SELECT id FROM plan), 'ads_enabled', 0, NULL)
ON CONFLICT (plan_id, feature_key) DO UPDATE
SET value = EXCLUDED.value, refresh_period = EXCLUDED.refresh_period;

-- =====================================================
-- 7. PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT ALL ON plans TO authenticated;
GRANT ALL ON plan_features TO authenticated;
GRANT ALL ON user_plans TO authenticated;
GRANT ALL ON user_usage TO authenticated;
GRANT ALL ON admin_users TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_entitlement(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_feature_usage(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_quotas(UUID) TO authenticated;

-- =====================================================
-- 8. ANALYZE TABLES FOR QUERY OPTIMIZATION
-- =====================================================

ANALYZE plans;
ANALYZE plan_features;
ANALYZE user_plans;
ANALYZE user_usage;
ANALYZE admin_users; 