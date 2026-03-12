-- Add photo_url column to user_profiles table
-- Run this in Supabase SQL Editor

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS photo_url TEXT;

COMMENT ON COLUMN user_profiles.photo_url IS 'URL to profile photo stored in Supabase storage';

-- Create storage bucket for profile photos if it doesn't exist
-- Note: This needs to be run manually in Supabase Storage UI or via SQL
-- Storage bucket: 'profiles'
-- Public access: true
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp

-- You may need to create the bucket manually in Supabase Dashboard:
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create a new bucket named 'profiles'
-- 3. Make it public
-- 4. Set file size limit to 5MB
-- 5. Add RLS policies as needed

-- RLS Policy for profile photos (users can manage their own photos)
CREATE POLICY "Users can upload their own profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = 'profile-photos'
  AND auth.uid()::text = (storage.foldername(name))[2]
);

CREATE POLICY "Users can update their own profile photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = 'profile-photos'
  AND auth.uid()::text = (storage.foldername(name))[2]
);

CREATE POLICY "Users can delete their own profile photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = 'profile-photos'
  AND auth.uid()::text = (storage.foldername(name))[2]
);

CREATE POLICY "Profile photos are publicly readable"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'profiles'
  AND (storage.foldername(name))[1] = 'profile-photos'
);
