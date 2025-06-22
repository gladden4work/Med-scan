-- MediScan Quota Rules Migration
-- This file contains SQL to migrate the database to support the new quota rules

-- =====================================================
-- 1. ADD NEW FEATURE KEYS TO DEFAULT PLANS
-- =====================================================

-- Add failed scan limit to Free (Not Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'failed_scan_limit_daily', 2, 'daily'
FROM plans p
WHERE p.name = 'Free (Not Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'failed_scan_limit_daily'
);

-- Add scan history limit to Free (Not Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'scan_history_limit', 0, 'none'
FROM plans p
WHERE p.name = 'Free (Not Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'scan_history_limit'
);

-- Add my medication limit to Free (Not Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'my_medication_limit', 0, 'none'
FROM plans p
WHERE p.name = 'Free (Not Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'my_medication_limit'
);

-- Add failed scan limit to Free (Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'failed_scan_limit_daily', 3, 'daily'
FROM plans p
WHERE p.name = 'Free (Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'failed_scan_limit_daily'
);

-- Add scan history limit to Free (Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'scan_history_limit', 3, 'none'
FROM plans p
WHERE p.name = 'Free (Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'scan_history_limit'
);

-- Add my medication limit to Free (Logged In) plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'my_medication_limit', 3, 'none'
FROM plans p
WHERE p.name = 'Free (Logged In)'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'my_medication_limit'
);

-- Add failed scan limit to Premium plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'failed_scan_limit_daily', 10, 'daily'
FROM plans p
WHERE p.name = 'Premium'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'failed_scan_limit_daily'
);

-- Add scan history limit to Premium plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'scan_history_limit', 100, 'none'
FROM plans p
WHERE p.name = 'Premium'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'scan_history_limit'
);

-- Add my medication limit to Premium plan
INSERT INTO plan_features (plan_id, feature_key, value, refresh_period)
SELECT p.id, 'my_medication_limit', 50, 'none'
FROM plans p
WHERE p.name = 'Premium'
AND NOT EXISTS (
  SELECT 1 FROM plan_features pf 
  WHERE pf.plan_id = p.id AND pf.feature_key = 'my_medication_limit'
);

-- =====================================================
-- 2. ADD VISIBILITY FLAG TO SCAN HISTORY TABLE
-- =====================================================

-- Add visibility flag to scan_history table
ALTER TABLE scan_history ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT true;

-- Add index for faster visibility filtering
CREATE INDEX IF NOT EXISTS idx_scan_history_visibility ON scan_history(user_id, is_visible, created_at DESC);

-- =====================================================
-- 3. RUN INITIAL VISIBILITY UPDATE FOR ALL USERS
-- =====================================================

-- Create temporary function to update all users' scan history visibility
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

-- Run the update for all users
SELECT update_all_users_scan_history_visibility();

-- Drop the temporary function
DROP FUNCTION update_all_users_scan_history_visibility();

-- =====================================================
-- 4. APPLY SCAN HISTORY VISIBILITY SQL
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

-- Drop existing select policy
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;

-- Create new policy that respects visibility flag
CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id = auth.uid() AND is_visible = true);

-- =====================================================
-- 5. APPLY FAILED SCAN TRACKING FUNCTIONS
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

-- =====================================================
-- 6. APPLY MY MEDICATION LIMIT FUNCTIONS
-- =====================================================

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