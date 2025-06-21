-- Create Supabase functions for safe soft-delete operations
-- These functions handle the permission checks internally

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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION soft_delete_medication(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION soft_delete_scan_history(UUID) TO authenticated; 