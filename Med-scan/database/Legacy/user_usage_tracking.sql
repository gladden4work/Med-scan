-- MediScan User Usage Tracking
-- This file contains additional functions for tracking and managing user feature usage

-- =====================================================
-- 1. USAGE TRACKING FUNCTIONS
-- =====================================================

-- Function to reset usage for a specific feature for all users
CREATE OR REPLACE FUNCTION reset_all_users_feature_usage(
  p_feature_key TEXT,
  p_reset_type TEXT -- 'daily', 'monthly', 'all'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Reset usage based on reset type
  IF p_reset_type = 'all' THEN
    -- Reset all usage for the feature
    UPDATE user_usage
    SET usage_count = 0, last_reset = NOW()
    WHERE feature_key = p_feature_key;
  ELSIF p_reset_type = 'daily' THEN
    -- Reset only if last reset was before today
    UPDATE user_usage
    SET usage_count = 0, last_reset = NOW()
    WHERE feature_key = p_feature_key
      AND last_reset::date < NOW()::date;
  ELSIF p_reset_type = 'monthly' THEN
    -- Reset only if last reset was in a previous month
    UPDATE user_usage
    SET usage_count = 0, last_reset = NOW()
    WHERE feature_key = p_feature_key
      AND (EXTRACT(MONTH FROM last_reset) != EXTRACT(MONTH FROM NOW())
           OR EXTRACT(YEAR FROM last_reset) != EXTRACT(YEAR FROM NOW()));
  END IF;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- =====================================================
-- NEW: FAILED SCAN TRACKING FUNCTIONS
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
-- NEW: MY MEDICATION LIMIT FUNCTIONS
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

-- Function to get usage statistics for a specific feature
CREATE OR REPLACE FUNCTION get_feature_usage_stats(
  p_feature_key TEXT
)
RETURNS TABLE (
  total_users INTEGER,
  avg_usage NUMERIC(10,2),
  max_usage INTEGER,
  users_at_limit INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH feature_limits AS (
    SELECT 
      up.user_id,
      pf.value AS limit_value
    FROM user_plans up
    JOIN plans p ON up.plan_id = p.id
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE pf.feature_key = p_feature_key
      AND up.is_active = true
    UNION ALL
    SELECT 
      u.id AS user_id,
      pf.value AS limit_value
    FROM auth.users u
    CROSS JOIN plans p
    JOIN plan_features pf ON p.id = pf.plan_id
    WHERE p.name = 'Free (Logged In)'
      AND pf.feature_key = p_feature_key
      AND NOT EXISTS (
        SELECT 1 FROM user_plans up 
        WHERE up.user_id = u.id AND up.is_active = true
      )
  )
  SELECT
    COUNT(DISTINCT uu.user_id)::INTEGER AS total_users,
    AVG(uu.usage_count)::NUMERIC(10,2) AS avg_usage,
    MAX(uu.usage_count)::INTEGER AS max_usage,
    COUNT(DISTINCT uu.user_id) FILTER (
      WHERE uu.usage_count >= fl.limit_value
    )::INTEGER AS users_at_limit
  FROM user_usage uu
  JOIN feature_limits fl ON uu.user_id = fl.user_id
  WHERE uu.feature_key = p_feature_key;
END;
$$;

-- =====================================================
-- 2. SUBSCRIPTION MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to subscribe a user to a plan
CREATE OR REPLACE FUNCTION subscribe_user_to_plan(
  p_user_id UUID,
  p_plan_name TEXT,
  p_payment_provider TEXT DEFAULT NULL,
  p_payment_reference TEXT DEFAULT NULL,
  p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan_id UUID;
  v_subscription_id UUID;
BEGIN
  -- Get the plan ID
  SELECT id INTO v_plan_id
  FROM plans
  WHERE name = p_plan_name AND is_active = true;
  
  IF v_plan_id IS NULL THEN
    RAISE EXCEPTION 'Plan "%" not found or not active', p_plan_name;
  END IF;
  
  -- Deactivate any existing subscription
  UPDATE user_plans
  SET is_active = FALSE, updated_at = NOW()
  WHERE user_id = p_user_id AND is_active = TRUE;
  
  -- Create new subscription
  INSERT INTO user_plans (
    user_id, 
    plan_id, 
    start_date, 
    end_date, 
    is_active, 
    payment_provider, 
    payment_reference
  )
  VALUES (
    p_user_id, 
    v_plan_id, 
    NOW(), 
    p_end_date, 
    TRUE, 
    p_payment_provider, 
    p_payment_reference
  )
  RETURNING id INTO v_subscription_id;
  
  RETURN v_subscription_id;
END;
$$;

-- Function to cancel a user's subscription
CREATE OR REPLACE FUNCTION cancel_user_subscription(
  p_user_id UUID,
  p_immediate BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_subscription_exists BOOLEAN;
BEGIN
  -- Check if subscription exists
  SELECT EXISTS(
    SELECT 1 FROM user_plans 
    WHERE user_id = p_user_id AND is_active = TRUE
  ) INTO v_subscription_exists;
  
  IF NOT v_subscription_exists THEN
    RETURN FALSE;
  END IF;
  
  IF p_immediate THEN
    -- Immediate cancellation
    UPDATE user_plans
    SET is_active = FALSE, updated_at = NOW()
    WHERE user_id = p_user_id AND is_active = TRUE;
  ELSE
    -- End-of-period cancellation (subscription remains active until end_date)
    -- If end_date is NULL, set it to the end of the current billing period
    UPDATE user_plans
    SET 
      end_date = COALESCE(
        end_date, 
        CASE 
          WHEN (SELECT billing_period FROM plans p WHERE p.id = plan_id) = 'monthly' 
            THEN date_trunc('month', NOW()) + interval '1 month'
          WHEN (SELECT billing_period FROM plans p WHERE p.id = plan_id) = 'yearly'
            THEN date_trunc('year', NOW()) + interval '1 year'
          ELSE NOW() + interval '30 days'
        END
      ),
      updated_at = NOW()
    WHERE user_id = p_user_id AND is_active = TRUE;
  END IF;
  
  RETURN TRUE;
END;
$$;

-- Function to check if a subscription is about to expire
CREATE OR REPLACE FUNCTION get_expiring_subscriptions(
  p_days_threshold INTEGER DEFAULT 7
)
RETURNS TABLE (
  subscription_id UUID,
  user_id UUID,
  plan_name TEXT,
  end_date TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id AS subscription_id,
    up.user_id,
    p.name AS plan_name,
    up.end_date,
    EXTRACT(DAY FROM (up.end_date - NOW()))::INTEGER AS days_remaining
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  WHERE up.is_active = TRUE
    AND up.end_date IS NOT NULL
    AND up.end_date > NOW()
    AND up.end_date <= NOW() + (p_days_threshold || ' days')::INTERVAL;
END;
$$;

-- =====================================================
-- 3. ADMIN FUNCTIONS
-- =====================================================

-- Function to get user plan information
CREATE OR REPLACE FUNCTION get_user_plan_info(
  p_user_id UUID
)
RETURNS TABLE (
  user_id UUID,
  plan_name TEXT,
  plan_description TEXT,
  price DECIMAL(10,2),
  billing_period TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN,
  is_grandfathered BOOLEAN,
  payment_provider TEXT,
  payment_reference TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- First try to get the user's active subscription
  RETURN QUERY
  SELECT 
    up.user_id,
    p.name,
    p.description,
    p.price,
    p.billing_period,
    up.start_date,
    up.end_date,
    up.is_active,
    up.is_grandfathered,
    up.payment_provider,
    up.payment_reference
  FROM user_plans up
  JOIN plans p ON up.plan_id = p.id
  WHERE up.user_id = p_user_id AND up.is_active = TRUE;
  
  -- If no active subscription, return the default free plan
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      p_user_id AS user_id,
      p.name,
      p.description,
      p.price,
      p.billing_period,
      NOW() AS start_date,
      NULL::TIMESTAMP WITH TIME ZONE AS end_date,
      TRUE AS is_active,
      FALSE AS is_grandfathered,
      NULL AS payment_provider,
      NULL AS payment_reference
    FROM plans p
    WHERE p.name = 'Free (Logged In)';
  END IF;
END;
$$;

-- Function to get all available plans with their features
CREATE OR REPLACE FUNCTION get_available_plans()
RETURNS TABLE (
  plan_id UUID,
  plan_name TEXT,
  plan_description TEXT,
  price DECIMAL(10,2),
  billing_period TEXT,
  features JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS plan_id,
    p.name AS plan_name,
    p.description AS plan_description,
    p.price,
    p.billing_period,
    jsonb_object_agg(
      pf.feature_key, 
      jsonb_build_object(
        'value', pf.value,
        'refresh_period', pf.refresh_period
      )
    ) AS features
  FROM plans p
  JOIN plan_features pf ON p.id = pf.plan_id
  WHERE p.is_active = TRUE
  GROUP BY p.id, p.name, p.description, p.price, p.billing_period;
END;
$$;

-- =====================================================
-- 4. PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION reset_all_users_feature_usage(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_feature_usage_stats(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION subscribe_user_to_plan(UUID, TEXT, TEXT, TEXT, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_user_subscription(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION get_expiring_subscriptions(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_plan_info(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_plans() TO authenticated; 