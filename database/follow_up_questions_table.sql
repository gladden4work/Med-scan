-- Follow-up Questions Table for MediScan
-- This table stores follow-up questions asked by users about medications

-- Create follow_up_questions table
CREATE TABLE IF NOT EXISTS follow_up_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scan_id UUID REFERENCES scan_history(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_scan_id ON follow_up_questions(scan_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_user_id ON follow_up_questions(user_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_questions_created_at ON follow_up_questions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE follow_up_questions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own follow-up questions" ON follow_up_questions
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

CREATE POLICY "Users can insert own follow-up questions" ON follow_up_questions
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_follow_up_questions_updated_at ON follow_up_questions;
CREATE TRIGGER update_follow_up_questions_updated_at 
  BEFORE UPDATE ON follow_up_questions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON follow_up_questions TO authenticated;

-- Analyze table for query optimization
ANALYZE follow_up_questions; 