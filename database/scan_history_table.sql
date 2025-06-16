-- Create scan_history table for storing user scan records
-- This table is designed to be compatible with Cloudflare Workers and mobile apps

CREATE TABLE IF NOT EXISTS scan_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  manufacturer TEXT,
  image_url TEXT,
  medicine_data JSONB, -- Store full medicine analysis data
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_history_created_at ON scan_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_history_user_created ON scan_history(user_id, created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own scan history
CREATE POLICY "Users can view own scan history" ON scan_history
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own scan records
CREATE POLICY "Users can insert own scan history" ON scan_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own scan records
CREATE POLICY "Users can delete own scan history" ON scan_history
  FOR DELETE USING (auth.uid() = user_id);

-- Users can update their own scan records
CREATE POLICY "Users can update own scan history" ON scan_history
  FOR UPDATE USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_scan_history_updated_at 
  BEFORE UPDATE ON scan_history 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL ON scan_history TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
