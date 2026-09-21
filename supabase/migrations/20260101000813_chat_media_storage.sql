-- =============================================================================
-- Migration: 20260101000813_chat_media_storage.sql
-- =============================================================================

-- 0813 · chat_media_storage — private chat media storage bucket & policies

-- -----------------------------------------------------------------------------
-- Integrations
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'chat-media',
    'chat-media',
    false,
    52428800, -- 50 MB
    array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'video/mp4',
      'video/quicktime',
      'audio/mpeg',
      'audio/mp4',
      'audio/wav',
      'audio/aac',
      'application/pdf'
    ]
  )
on conflict (id) do update
  set
    public = false,
    file_size_limit = 52428800,
    allowed_mime_types = array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'video/mp4',
      'video/quicktime',
      'audio/mpeg',
      'audio/mp4',
      'audio/wav',
      'audio/aac',
      'application/pdf'
    ];

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

-- Storage RLS: Channel members can read attachments in channels they belong to
create policy "chat_media_read_policy"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      (storage.foldername(name))[1] is not null
      and exists (
        select
          1
        from public.channel_members cm
        where
          cm.channel_id::text = (storage.foldername(name))[1]
          and cm.user_id = (
            select
              auth.uid()
          )
          and cm.status in ('active', 'pending')
      )
    )
  );

-- Storage RLS: Channel members with send_media capability can upload
create policy "chat_media_insert_policy"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'chat-media'
    and (
      (storage.foldername(name))[1] is not null
      and exists (
        select
          1
        from public.channel_members cm
        where
          cm.channel_id::text = (storage.foldername(name))[1]
          and cm.user_id = (
            select
              auth.uid()
          )
          and cm.status = 'active'
      )
    )
  );

-- Storage RLS: Senders or moderators can delete their uploads
create policy "chat_media_delete_policy"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'chat-media'
    and (
      (storage.foldername(name))[1] is not null
      and exists (
        select
          1
        from public.channel_members cm
        where
          cm.channel_id::text = (storage.foldername(name))[1]
          and cm.user_id = (
            select
              auth.uid()
          )
          and cm.status = 'active'
      )
    )
  );
