-- Create user_medications table for storing user's saved medications
-- This table is designed to be compatible with Cloudflare Workers and mobile apps

CREATE TABLE IF NOT EXISTS user_medications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  manufacturer TEXT,
  image_url TEXT,
  medicine_data JSONB, -- Store full medicine analysis data
  frequency TEXT DEFAULT 'daily', -- daily, weekly, monthly, as_needed, no_longer_taking
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_medications_user_id ON user_medications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_medications_created_at ON user_medications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_medications_user_created ON user_medications(user_id, created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE user_medications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies with optimized subqueries for better performance
-- Users can only see their own medications
CREATE POLICY "Users can view own medications" ON user_medications
  FOR SELECT USING (user_id IN (SELECT auth.uid()));

-- Users can insert their own medications
CREATE POLICY "Users can insert own medications" ON user_medications
  FOR INSERT WITH CHECK (user_id IN (SELECT auth.uid()));

-- Users can delete their own medications
CREATE POLICY "Users can delete own medications" ON user_medications
  FOR DELETE USING (user_id IN (SELECT auth.uid()));

-- Users can update their own medications
CREATE POLICY "Users can update own medications" ON user_medications
  FOR UPDATE USING (user_id IN (SELECT auth.uid()));

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Only create the trigger if it doesn't already exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_medications_updated_at'
  ) THEN
    CREATE TRIGGER update_user_medications_updated_at 
      BEFORE UPDATE ON user_medications 
      FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END
$$;

-- Grant necessary permissions
GRANT ALL ON user_medications TO authenticated; 