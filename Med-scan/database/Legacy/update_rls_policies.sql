-- SQL script to update existing RLS policies for better performance
-- This script optimizes the auth.uid() calls by using subqueries

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can insert own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can delete own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can update own scan history" ON scan_history;

-- Create optimized RLS policies with subqueries
-- Users can only see their own scan history
CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

-- Users can insert their own scan records
CREATE POLICY "Users can insert own scan history" ON scan_history
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

-- Users can delete their own scan records
CREATE POLICY "Users can delete own scan history" ON scan_history
  FOR DELETE USING (user_id IN (SELECT auth.uid()));

-- Users can update their own scan records
CREATE POLICY "Users can update own scan history" ON scan_history
  FOR UPDATE USING (user_id IN (SELECT auth.uid()));

-- Analyze the table to update statistics for the query planner
ANALYZE scan_history; 