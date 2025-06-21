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

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

-- Scan history indexes
CREATE INDEX IF NOT EXISTS idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_history_created_at ON scan_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_user_created ON scan_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_not_deleted ON scan_history(is_deleted) WHERE is_deleted = false;

-- User medications indexes
CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON user_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_created_at ON user_medications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_medications_user_created ON user_medications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_medications_not_deleted ON user_medications(is_deleted) WHERE is_deleted = false;

-- Follow-up questions indexes
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_scan_id ON follow_up_questions(scan_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_user_id ON follow_up_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_created_at ON follow_up_questions(created_at DESC);

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) SETUP
-- =====================================================

-- Enable RLS on tables
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE follow_up_questions ENABLE ROW LEVEL SECURITY;

-- Scan history policies
DROP POLICY IF EXISTS "Users can view own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can insert own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can update own scan history" ON scan_history;
DROP POLICY IF EXISTS "Users can delete own scan history" ON scan_history;

CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (user_id IN (SELECT auth.uid()) AND NOT is_deleted);

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
-- 6. PERMISSIONS
-- =====================================================

-- Grant necessary permissions
GRANT ALL ON scan_history TO authenticated;
GRANT ALL ON user_medications TO authenticated;
GRANT ALL ON follow_up_questions TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION soft_delete_medication(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION soft_delete_scan_history(UUID) TO authenticated;

-- =====================================================
-- 7. ANALYZE TABLES FOR QUERY OPTIMIZATION
-- =====================================================

ANALYZE scan_history;
ANALYZE user_medications;
ANALYZE follow_up_questions; 