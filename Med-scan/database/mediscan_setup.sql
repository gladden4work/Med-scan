-- MediScan Consolidated Database Setup
-- This single file contains all necessary database setup for the MediScan application
-- Including table creation, indexes, RLS policies, and soft delete functionality

-- =====================================================
-- 1. TABLE CREATION
-- =====================================================

-- Create scan_history table for storing user scan records
CREATE TABLE IF NOT EXISTS scan_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  manufacturer TEXT,
  image_url TEXT,
  medicine_data JSONB, -- Store full medicine analysis data
  is_deleted BOOLEAN DEFAULT false,
  is_visible BOOLEAN DEFAULT true, -- Controls visibility based on plan limits
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_medications table for storing user's saved medications
CREATE TABLE IF NOT EXISTS user_medications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  manufacturer TEXT,
  image_url TEXT,
  medicine_data JSONB, -- Store full medicine analysis data
  frequency TEXT DEFAULT 'daily', -- daily, weekly, monthly, as_needed, no_longer_taking
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create follow_up_questions table for storing user questions about medications
CREATE TABLE IF NOT EXISTS follow_up_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scan_id UUID REFERENCES scan_history(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
                             -- failed_scan_limit_daily, my_medication_limit, scan_history_limit
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

-- Scan history indexes
CREATE INDEX IF NOT EXISTS idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_history_created_at ON scan_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_user_created ON scan_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_not_deleted ON scan_history(is_deleted) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_scan_history_visibility ON scan_history(user_id, is_visible, created_at DESC);

-- User medications indexes
CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON user_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_created_at ON user_medications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_medications_user_created ON user_medications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_medications_not_deleted ON user_medications(is_deleted) WHERE is_deleted = false;

-- Follow-up questions indexes
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_scan_id ON follow_up_questions(scan_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_user_id ON follow_up_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_created_at ON follow_up_questions(created_at DESC);

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
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE follow_up_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Scan history policies
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can insert own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can update own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can delete own scan history" ON scan_history;

CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id IN (SELECT auth.uid()) AND is_visible = true);

CREATE POLICY "Users can insert own scan history" ON scan_history
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can update own scan history" ON scan_history
  FOR UPDATE USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can delete own scan history" ON scan_history
  FOR DELETE USING (user_id IN (SELECT auth.uid()));

-- User medications policies
DROP POLICY IF EXISTS "Users can view own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can insert own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can update own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can delete own medications" ON user_medications;

CREATE POLICY "Users can view own medications" ON user_medications
  FOR SELECT USING (user_id IN (SELECT auth.uid()) AND NOT is_deleted);

CREATE POLICY "Users can insert own medications" ON user_medications
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can update own medications" ON user_medications
  FOR UPDATE USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can delete own medications" ON user_medications
  FOR DELETE USING (user_id IN (SELECT auth.uid()));

-- Follow-up questions policies
DROP POLICY IF EXISTS "Users can view own follow-up questions" ON follow_up_questions;
DROP POLICY IF EXISTS "Users can insert own follow-up questions" ON follow_up_questions;

CREATE POLICY "Users can view own follow-up questions" ON follow_up_questions
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can insert own follow-up questions" ON follow_up_questions
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

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

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_scan_history_updated_at ON scan_history;
CREATE TRIGGER update_scan_history_updated_at 
  BEFORE UPDATE ON scan_history 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_medications_updated_at ON user_medications;
CREATE TRIGGER update_user_medications_updated_at 
  BEFORE UPDATE ON user_medications 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_follow_up_questions_updated_at ON follow_up_questions;
CREATE TRIGGER update_follow_up_questions_updated_at 
  BEFORE UPDATE ON follow_up_questions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

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
-- 5. SOFT DELETE FUNCTIONS
-- =====================================================

-- Function to soft delete a medication
CREATE OR REPLACE FUNCTION soft_delete_medication(medication_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- This is important - it runs with the privileges of the creator
SET search_path = public
AS $$
DECLARE
  belongs_to_user BOOLEAN;
BEGIN
  -- First check if the medication belongs to the calling user
  SELECT EXISTS(
    SELECT 1 FROM user_medications 
    WHERE id = medication_id 
    AND user_id = auth.uid()
  ) INTO belongs_to_user;
  
  -- Only proceed if the medication belongs to the user
  IF belongs_to_user THEN
    UPDATE user_medications
    SET is_deleted = TRUE
    WHERE id = medication_id;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;

-- Function to soft delete scan history
CREATE OR REPLACE FUNCTION soft_delete_scan_history(scan_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- This is important - it runs with the privileges of the creator
SET search_path = public
AS $$
DECLARE
  belongs_to_user BOOLEAN;
BEGIN
  -- First check if the scan belongs to the calling user
  SELECT EXISTS(
    SELECT 1 FROM scan_history 
    WHERE id = scan_id 
    AND user_id = auth.uid()
  ) INTO belongs_to_user;
  
  -- Only proceed if the scan belongs to the user
  IF belongs_to_user THEN
    UPDATE scan_history
    SET is_deleted = TRUE
    WHERE id = scan_id;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;

-- =====================================================
-- 6. ENTITLEMENT CHECK FUNCTIONS
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
  
  -- If unlimited (value = -1), return true
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
  
  -- If no usage record, create one and return true (first use)
  IF v_usage IS NULL THEN
    INSERT INTO user_usage (user_id, feature_key, usage_count, last_reset)
    VALUES (p_user_id, p_feature_key, 0, v_now);
    
    RETURN TRUE;
  END IF;
  
  -- Check if usage needs to be reset based on refresh period
  IF v_refresh_period = 'daily' AND v_last_reset::date < v_now::date THEN
    -- Reset daily usage at midnight
    UPDATE user_usage
    SET usage_count = 0, last_reset = v_now
    WHERE user_id = p_user_id AND feature_key = p_feature_key;
    
    v_usage := 0;
  ELSIF v_refresh_period = 'monthly' AND (
    EXTRACT(MONTH FROM v_last_reset) != EXTRACT(MONTH FROM v_now)
    OR EXTRACT(YEAR FROM v_last_reset) != EXTRACT(YEAR FROM v_now)
  ) THEN
    -- Reset monthly usage at start of month
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
  -- First check if user has entitlement (this also handles resets)
  v_has_entitlement := check_user_entitlement(p_user_id, p_feature_key);
  
  IF NOT v_has_entitlement THEN
    RETURN FALSE;
  END IF;
  
  -- Increment usage count
  INSERT INTO user_usage (user_id, feature_key, usage_count, last_reset)
  VALUES (p_user_id, p_feature_key, 1, NOW())
  ON CONFLICT (user_id, feature_key) DO UPDATE
  SET usage_count = user_usage.usage_count + 1,
      updated_at = NOW();
  
  RETURN TRUE;
END;
$$;

-- Function to get all quotas for a user
CREATE OR REPLACE FUNCTION get_user_quotas(
  p_user_id UUID
)
RETURNS TABLE (
  feature_key TEXT,
  quota_limit INTEGER,
  usage_count INTEGER,
  remaining INTEGER,
  refresh_period TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Reset any quotas that need resetting
  PERFORM check_user_entitlement(p_user_id, feature_key)
  FROM plan_features
  WHERE feature_key IN ('scan_quota', 'followup_questions', 'history_access', 'medication_list');
  
  -- Return quota information
  RETURN QUERY
  WITH user_plan AS (
    -- Get the user's current plan
    SELECT p.id AS plan_id
    FROM user_plans up
    JOIN plans p ON up.plan_id = p.id
    WHERE up.user_id = p_user_id
      AND up.is_active = true
    UNION ALL
    -- If no plan, use the default free plan
    SELECT p.id AS plan_id
    FROM plans p
    WHERE p.name = 'Free (Logged In)'
      AND NOT EXISTS (
        SELECT 1 FROM user_plans up
        WHERE up.user_id = p_user_id AND up.is_active = true
      )
    LIMIT 1
  )
  SELECT 
    pf.feature_key,
    pf.value AS quota_limit,
    COALESCE(uu.usage_count, 0) AS usage_count,
    CASE
      WHEN pf.value = -1 THEN -1 -- Unlimited
      ELSE pf.value - COALESCE(uu.usage_count, 0)
    END AS remaining,
    pf.refresh_period
  FROM user_plan up
  JOIN plan_features pf ON up.plan_id = pf.plan_id
  LEFT JOIN user_usage uu ON uu.user_id = p_user_id AND uu.feature_key = pf.feature_key;
END;
$$;

-- =====================================================
-- 7. SCAN HISTORY VISIBILITY FUNCTIONS
-- =====================================================

-- Function to update scan history visibility based on user's plan limit
CREATE OR REPLACE FUNCTION update_scan_history_visibility(
  p_user_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_history_limit INTEGER;
  v_updated_count INTEGER;
BEGIN
  -- Get user's scan history limit from their plan
  SELECT 
    COALESCE(pf.value, 3) -- Default to 3 if no specific limit is set
  INTO 
    v_history_limit
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  JOIN plan_features pf ON p.id = pf.plan_id
  WHERE up.user_id = p_user_id
    AND up.is_active = true
    AND pf.feature_key = 'scan_history_limit';
  
  -- If no active plan found, use the default free plan limit
  IF v_history_limit IS NULL THEN
    SELECT 
      COALESCE(pf.value, 3) -- Default to 3 if no specific limit is set
    INTO 
      v_history_limit
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Logged In)' 
      AND pf.feature_key = 'scan_history_limit';
  END IF;
  
  -- Set all scan history entries to visible first
  UPDATE scan_history
  SET is_visible = true
  WHERE user_id = p_user_id;
  
  -- Then hide entries beyond the limit
  UPDATE scan_history
  SET is_visible = false
  WHERE id IN (
    SELECT id
    FROM scan_history
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    OFFSET v_history_limit
  );
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

-- Function to be called when a new scan is added
CREATE OR REPLACE FUNCTION handle_new_scan_history()
RETURNS TRIGGER AS $$
BEGIN
  -- Update visibility for the user who added the scan
  PERFORM update_scan_history_visibility(NEW.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run after inserting new scan history
DROP TRIGGER IF EXISTS trigger_new_scan_history ON scan_history;
CREATE TRIGGER trigger_new_scan_history
  AFTER INSERT ON scan_history
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_scan_history();

-- Function to be called when a scan is deleted
CREATE OR REPLACE FUNCTION handle_deleted_scan_history()
RETURNS TRIGGER AS $$
BEGIN
  -- Update visibility for the user who deleted the scan
  PERFORM update_scan_history_visibility(OLD.user_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run after deleting scan history
DROP TRIGGER IF EXISTS trigger_deleted_scan_history ON scan_history;
CREATE TRIGGER trigger_deleted_scan_history
  AFTER DELETE ON scan_history
  FOR EACH ROW
  EXECUTE FUNCTION handle_deleted_scan_history();

-- Function to run once to update all users' scan history visibility
CREATE OR REPLACE FUNCTION update_all_users_scan_history_visibility()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_user record;
  v_count INTEGER := 0;
BEGIN
  FOR v_user IN SELECT DISTINCT user_id FROM scan_history LOOP
    PERFORM update_scan_history_visibility(v_user.user_id);
    v_count := v_count + 1;
  END LOOP;
  
  RETURN v_count;
END;
$$;

-- =====================================================
-- 8. USAGE TRACKING FUNCTIONS
-- =====================================================

-- Function to track failed scan (when AI returns "Not available" or "More than one medication")
CREATE OR REPLACE FUNCTION increment_failed_scan_usage(
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INTEGER;
  v_usage INTEGER;
  v_refresh_period TEXT;
  v_last_reset TIMESTAMP WITH TIME ZONE;
  v_now TIMESTAMP WITH TIME ZONE := NOW();
BEGIN
  -- Handle anonymous users (not logged in)
  IF p_user_id IS NULL THEN
    -- Anonymous users don't have failed scan tracking
    RETURN TRUE;
  END IF;

  -- Get user's failed scan limit from their plan
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
    AND pf.feature_key = 'failed_scan_limit_daily';
  
  -- If no plan found, use the default free plan
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
      AND pf.feature_key = 'failed_scan_limit_daily';
  END IF;
  
  -- Default values if still null
  v_limit := COALESCE(v_limit, 3);
  v_refresh_period := COALESCE(v_refresh_period, 'daily');
  
  -- Get current usage
  SELECT 
    usage_count, 
    last_reset
  INTO 
    v_usage, 
    v_last_reset
  FROM user_usage
  WHERE user_id = p_user_id
    AND feature_key = 'failed_scan_limit_daily';
  
  -- If no usage record exists, create one
  IF v_usage IS NULL THEN
    INSERT INTO user_usage (
      user_id, 
      feature_key, 
      usage_count, 
      last_reset
    )
    VALUES (
      p_user_id, 
      'failed_scan_limit_daily', 
      0, 
      v_now
    );
    
    v_usage := 0;
    v_last_reset := v_now;
  END IF;
  
  -- Check if usage should be reset based on refresh period
  IF v_refresh_period = 'daily' AND v_last_reset::date < v_now::date THEN
    -- Reset daily usage
    UPDATE user_usage
    SET usage_count = 0, last_reset = v_now
    WHERE user_id = p_user_id
      AND feature_key = 'failed_scan_limit_daily';
    
    v_usage := 0;
  ELSIF v_refresh_period = 'monthly' AND 
        (EXTRACT(MONTH FROM v_last_reset) != EXTRACT(MONTH FROM v_now)
         OR EXTRACT(YEAR FROM v_last_reset) != EXTRACT(YEAR FROM v_now)) THEN
    -- Reset monthly usage
    UPDATE user_usage
    SET usage_count = 0, last_reset = v_now
    WHERE user_id = p_user_id
      AND feature_key = 'failed_scan_limit_daily';
    
    v_usage := 0;
  END IF;
  
  -- Check if user has reached their limit
  IF v_usage >= v_limit THEN
    RETURN FALSE;
  END IF;
  
  -- Increment usage
  UPDATE user_usage
  SET usage_count = usage_count + 1, updated_at = v_now
  WHERE user_id = p_user_id
    AND feature_key = 'failed_scan_limit_daily';
  
  RETURN TRUE;
END;
$$;

-- Function to check if user can add more medications to their list
CREATE OR REPLACE FUNCTION check_medication_limit(
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INTEGER;
  v_count INTEGER;
BEGIN
  -- Handle anonymous users (not logged in)
  IF p_user_id IS NULL THEN
    -- Anonymous users can't save medications
    RETURN FALSE;
  END IF;

  -- Get user's medication limit from their plan
  SELECT 
    pf.value
  INTO 
    v_limit
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  JOIN plan_features pf ON p.id = pf.plan_id
  WHERE up.user_id = p_user_id
    AND up.is_active = true
    AND pf.feature_key = 'my_medication_limit';
  
  -- If no plan found, use the default free plan
  IF v_limit IS NULL THEN
    SELECT 
      pf.value
    INTO 
      v_limit
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Logged In)'
      AND pf.feature_key = 'my_medication_limit';
  END IF;
  
  -- Default value if still null
  v_limit := COALESCE(v_limit, 3);
  
  -- Count user's current medications
  SELECT 
    COUNT(*)
  INTO 
    v_count
  FROM user_medications
  WHERE user_id = p_user_id;
  
  -- Check if user has reached their limit
  RETURN v_count < v_limit;
END;
$$;

-- Function to get user's medication count and limit
CREATE OR REPLACE FUNCTION get_medication_count_and_limit(
  p_user_id UUID
)
RETURNS TABLE (
  current_count INTEGER,
  limit_value INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit INTEGER;
  v_count INTEGER;
BEGIN
  -- Handle anonymous users (not logged in)
  IF p_user_id IS NULL THEN
    -- Anonymous users can't save medications
    RETURN QUERY SELECT 0::INTEGER, 0::INTEGER;
    RETURN;
  END IF;

  -- Get user's medication limit from their plan
  SELECT 
    pf.value
  INTO 
    v_limit
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  JOIN plan_features pf ON p.id = pf.plan_id
  WHERE up.user_id = p_user_id
    AND up.is_active = true
    AND pf.feature_key = 'my_medication_limit';
  
  -- If no plan found, use the default free plan
  IF v_limit IS NULL THEN
    SELECT 
      pf.value
    INTO 
      v_limit
    FROM plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Logged In)'
      AND pf.feature_key = 'my_medication_limit';
  END IF;
  
  -- Default value if still null
  v_limit := COALESCE(v_limit, 3);
  
  -- Count user's current medications
  SELECT 
    COUNT(*)
  INTO 
    v_count
  FROM user_medications
  WHERE user_id = p_user_id;
  
  RETURN QUERY SELECT v_count::INTEGER, v_limit::INTEGER;
END;
$$;

-- =====================================================
-- 8. DEFAULT DATA SETUP
-- =====================================================

-- Insert default plans if they don't exist
INSERT INTO plans (name, description, price, billing_period, is_active, is_default)
VALUES 
  ('Free (Not Logged In)', 'Limited access for users who are not logged in', 0.00, 'monthly', true, true),
  ('Free (Logged In)', 'Basic access for registered users', 0.00, 'monthly', true, false),
  ('Premium', 'Premium access with unlimited features', 9.99, 'monthly', true, false)
ON CONFLICT (name) DO NOTHING;

-- Insert default plan features
WITH plan_ids AS (
  SELECT id, name FROM plans WHERE name IN ('Free (Not Logged In)', 'Free (Logged In)', 'Premium')
)
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT 
  p.id,
  feature_key,
  CASE 
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'scan_quota' THEN 3
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'followup_questions' THEN 1
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'history_access' THEN 0
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'medication_list' THEN 0
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'failed_scan_limit_daily' THEN 2
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'scan_history_limit' THEN 0
    WHEN p.name = 'Free (Not Logged In)' AND feature_key = 'my_medication_limit' THEN 0
    
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'scan_quota' THEN 10
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'followup_questions' THEN 5
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'history_access' THEN 30
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'medication_list' THEN 5
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'failed_scan_limit_daily' THEN 3
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'scan_history_limit' THEN 3
    WHEN p.name = 'Free (Logged In)' AND feature_key = 'my_medication_limit' THEN 3
    
    WHEN p.name = 'Premium' AND feature_key = 'scan_quota' THEN -1
    WHEN p.name = 'Premium' AND feature_key = 'followup_questions' THEN -1
    WHEN p.name = 'Premium' AND feature_key = 'history_access' THEN -1
    WHEN p.name = 'Premium' AND feature_key = 'medication_list' THEN -1
    WHEN p.name = 'Premium' AND feature_key = 'failed_scan_limit_daily' THEN 10
    WHEN p.name = 'Premium' AND feature_key = 'scan_history_limit' THEN 100
    WHEN p.name = 'Premium' AND feature_key = 'my_medication_limit' THEN 50
  END,
  CASE 
    WHEN feature_key IN ('scan_quota', 'followup_questions', 'failed_scan_limit_daily') THEN 'daily'
    WHEN feature_key IN ('history_access', 'medication_list', 'scan_history_limit', 'my_medication_limit') THEN 'none'
  END
FROM plan_ids p
CROSS JOIN (
  VALUES 
    ('scan_quota'),
    ('followup_questions'),
    ('history_access'),
    ('medication_list'),
    ('failed_scan_limit_daily'),
    ('scan_history_limit'),
    ('my_medication_limit')
) AS features(feature_key)
ON CONFLICT (plan_id, feature_key) DO UPDATE
SET value = EXCLUDED.value, refresh_period = EXCLUDED.refresh_period;

-- =====================================================
-- 9. PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT ALL ON scan_history TO authenticated;
GRANT ALL ON user_medications TO authenticated;
GRANT ALL ON follow_up_questions TO authenticated;
GRANT SELECT ON plans TO authenticated;
GRANT SELECT ON plan_features TO authenticated;
GRANT SELECT ON user_plans TO authenticated;
GRANT SELECT ON user_usage TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION soft_delete_medication(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION soft_delete_scan_history(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_entitlement(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_feature_usage(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_quotas(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_scan_history_visibility(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_failed_scan_usage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_medication_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_medication_count_and_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_all_users_scan_history_visibility() TO authenticated;

-- =====================================================
-- 10. ANALYZE TABLES FOR QUERY OPTIMIZATION
-- =====================================================

ANALYZE scan_history;
ANALYZE user_medications;
ANALYZE follow_up_questions;
ANALYZE plans;
ANALYZE plan_features;
ANALYZE user_plans;
ANALYZE user_usage;
ANALYZE admin_users; 