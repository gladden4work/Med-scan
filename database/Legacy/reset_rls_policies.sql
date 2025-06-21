-- Complete reset and setup of Row Level Security policies for MediScan tables
-- This will remove all existing policies and create new ones with proper permissions

-- Enable RLS on tables
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;

-- First, drop all existing policies to start clean
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can update own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can insert own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can delete own scan history" ON scan_history;

DROP POLICY IF EXISTS "Users can view own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can update own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can insert own medications" ON user_medications;
DROP POLICY IF EXISTS "Users can delete own medications" ON user_medications;

-- Create comprehensive policies for scan_history

-- Allow users to view their own scan history
CREATE POLICY "Users can view own scan history" 
ON scan_history FOR SELECT 
USING (auth.uid() = user_id AND is_deleted = false);

-- Allow users to insert their own scan history
CREATE POLICY "Users can insert own scan history"
ON scan_history FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own scan history
CREATE POLICY "Users can update own scan history"
ON scan_history FOR UPDATE
USING (auth.uid() = user_id);

-- Allow users to delete their own scan history (though we'll use soft delete)
CREATE POLICY "Users can delete own scan history"
ON scan_history FOR DELETE
USING (auth.uid() = user_id);

-- Create comprehensive policies for user_medications

-- Allow users to view their own medications
CREATE POLICY "Users can view own medications" 
ON user_medications FOR SELECT 
USING (auth.uid() = user_id AND is_deleted = false);

-- Allow users to insert their own medications
CREATE POLICY "Users can insert own medications"
ON user_medications FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own medications
CREATE POLICY "Users can update own medications"
ON user_medications FOR UPDATE
USING (auth.uid() = user_id);

-- Allow users to delete their own medications (though we'll use soft delete)
CREATE POLICY "Users can delete own medications"
ON user_medications FOR DELETE
USING (auth.uid() = user_id);

-- Ensure the is_deleted column exists on both tables
ALTER TABLE scan_history
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

ALTER TABLE user_medications
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- Create indexes for faster filtering of non-deleted records
DROP INDEX IF EXISTS idx_scan_history_not_deleted;
CREATE INDEX idx_scan_history_not_deleted 
ON scan_history(is_deleted) 
WHERE is_deleted = false;

DROP INDEX IF EXISTS idx_user_medications_not_deleted;
CREATE INDEX idx_user_medications_not_deleted 
ON user_medications(is_deleted) 
WHERE is_deleted = false; 