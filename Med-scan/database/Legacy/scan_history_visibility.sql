-- MediScan Scan History Visibility Management
-- This file contains SQL for managing scan history visibility based on user plan limits

-- =====================================================
-- 1. ALTER SCAN HISTORY TABLE TO ADD VISIBILITY FLAG
-- =====================================================

-- Add visibility flag to scan_history table
ALTER TABLE scan_history ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT true;

-- Add index for faster visibility filtering
CREATE INDEX IF NOT EXISTS idx_scan_history_visibility ON scan_history(user_id, is_visible, created_at DESC);

-- =====================================================
-- 2. FUNCTIONS FOR MANAGING SCAN HISTORY VISIBILITY
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

-- =====================================================
-- 3. MODIFY RLS POLICIES FOR VISIBILITY
-- =====================================================

-- Drop existing select policy
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;

-- Create new policy that respects visibility flag
CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id = auth.uid() AND is_visible = true); 