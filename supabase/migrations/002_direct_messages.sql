-- Direct messages table
CREATE TABLE direct_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  read_at TIMESTAMPTZ
);

ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read their own DMs
CREATE POLICY "Users can read own DMs" ON direct_messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

-- Authenticated users can send DMs
CREATE POLICY "Users can send DMs" ON direct_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Allow anon access for browse-without-account users
CREATE POLICY "Anon DM access" ON direct_messages
  FOR ALL USING (true);

-- Index for fast conversation lookups
CREATE INDEX idx_dm_sender ON direct_messages(sender_id, created_at DESC);
CREATE INDEX idx_dm_recipient ON direct_messages(recipient_id, created_at DESC);
