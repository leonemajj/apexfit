-- Storage: avatars bucket (create in Dashboard UI first)
-- Then apply policies for private-per-user folders.

-- NOTE: If policy already exists, Supabase may show 42710 "already exists".
-- In that case, you can safely skip or DROP then CREATE.

-- Allow users to upload to their own folder: {userId}/...
drop policy if exists "avatars_upload_own_folder" on storage.objects;
create policy "avatars_upload_own_folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_read_public" on storage.objects;
create policy "avatars_read_public"
on storage.objects for select
to public
using (bucket_id = 'avatars');
