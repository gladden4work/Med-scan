-- SQL migration to add soft delete functionality to existing tables
-- This adds an is_deleted column to both scan_history and user_medications tables
-- and updates queries to filter by this column

-- Add is_deleted column to scan_history table
ALTER TABLE scan_history
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- Add is_deleted column to user_medications table
ALTER TABLE user_medications
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- Create index for faster filtering of non-deleted records
CREATE INDEX IF NOT EXISTS idx_scan_history_not_deleted 
ON scan_history(is_deleted) 
WHERE is_deleted = false;

CREATE INDEX IF NOT EXISTS idx_user_medications_not_deleted 
ON user_medications(is_deleted) 
WHERE is_deleted = false;

-- Update existing RLS policies to include is_deleted filter
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;
CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id IN (SELECT auth.uid()) AND NOT is_deleted);

-- Update user_medications policies
DROP POLICY IF EXISTS "Users can view own medications" ON user_medications;
CREATE POLICY "Users can view own medications" ON user_medications
  FOR SELECT USING (user_id IN (SELECT auth.uid()) AND NOT is_deleted);

-- Admin policy for soft-deleted records (optional, uncomment if admin access is needed)
-- CREATE POLICY "Admins can see all records including deleted" ON scan_history
--   FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));
-- 
-- CREATE POLICY "Admins can see all records including deleted" ON user_medications
--   FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users)); 