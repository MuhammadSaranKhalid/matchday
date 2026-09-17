-- Migration: 20260917000002_chat_media_storage.sql
-- Create private storage bucket for chat media with channel membership RLS (Spec §26)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-media',
  'chat-media',
  false,
  25 * 1024 * 1024,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 25 * 1024 * 1024,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- Storage path format: channels/<channelId>/<messageId>/<attachmentId>.<ext>

-- 1. SELECT: Active members of the channel can read attachments
create policy "chat_media_read_channel_members"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.channel_members cm
      where cm.channel_id = ((storage.foldername(name))[2])::uuid
        and cm.user_id = auth.uid()
        and cm.status = 'active'
    )
  );

-- 2. INSERT: Active members can upload to their channel's folder
create policy "chat_media_insert_channel_members"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.channel_members cm
      where cm.channel_id = ((storage.foldername(name))[2])::uuid
        and cm.user_id = auth.uid()
        and cm.status = 'active'
    )
  );

-- 3. DELETE: Sender or channel owner can delete
create policy "chat_media_delete_sender_or_owner"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.channel_members cm
      where cm.channel_id = ((storage.foldername(name))[2])::uuid
        and cm.user_id = auth.uid()
        and (cm.status = 'active' and (cm.role = 'owner' or owner = auth.uid()))
    )
  );
