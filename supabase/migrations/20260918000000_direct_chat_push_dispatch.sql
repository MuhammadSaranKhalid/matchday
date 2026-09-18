-- =============================================================================
-- Direct Chat Push Notification Dispatch & Preparation
-- =============================================================================
-- Fast-path chat notification delivery:
-- 1. trg_dispatch_chat_push triggers on messages INSERT.
-- 2. Asynchronously wakes send-chat-push Edge Function via pg_net.
-- 3. send-chat-push calls prepare_chat_push_jobs(message_id) to evaluate
--    authoritative recipient state (blocks, mutes, preferences, pending DMs).
-- 4. EPHEMERAL: Chat pushes are strictly device alerts; they DO NOT write to
--    public.notifications to keep the in-app notification center clean.
-- 5. FCM V1 message is sent directly without cron / PGMQ queue delay.
-- =============================================================================

-- 1. Prepare chat push jobs RPC (ephemeral device delivery, NO public.notifications row)
create or replace function public.prepare_chat_push_jobs(p_message_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_msg record;
  v_sender_name text;
  v_channel_kind public.chat_channel_kind;
  v_channel_title text;
  v_preview text;
  v_type_key text;
  v_title text;
  v_body text;
  v_route text;
  v_importance text;
  v_direct_recipient_id uuid;
  v_direct_recipient_status public.chat_member_status;
  v_recipients uuid[] := '{}';
  v_eligible_recipients uuid[] := '{}';
  v_recipient_id uuid;
  v_jobs jsonb;
begin
  -- 1. Load message
  select m.message_id, m.channel_id, m.sender_id, m.message_type, m.body, m.created_at, m.deleted_at
    into v_msg
    from public.messages m
   where m.message_id = p_message_id;

  if v_msg.message_id is null or v_msg.deleted_at is not null or v_msg.message_type = 'system' then
    return '[]'::jsonb;
  end if;

  -- 2. Load sender info
  select coalesce(p.display_name, 'Someone')
    into v_sender_name
    from public.profiles p
   where p.user_id = v_msg.sender_id;

  -- 3. Load channel info
  select c.kind, c.title
    into v_channel_kind, v_channel_title
    from public.chat_channels c
   where c.channel_id = v_msg.channel_id;

  if v_channel_kind is null then
    return '[]'::jsonb;
  end if;

  -- 4. Render preview snippet
  v_preview := case
    when v_msg.message_type = 'text' then
      case when length(v_msg.body) > 100 then substring(v_msg.body from 1 for 97) || '…' else coalesce(v_msg.body, '') end
    when v_msg.message_type = 'image' then '📷 Photo'
    when v_msg.message_type = 'video' then '🎥 Video'
    when v_msg.message_type = 'audio' then '🎤 Voice message'
    when v_msg.message_type = 'file' then '📎 Attachment'
    else 'New message'
  end;

  -- 5. Determine recipients and notification copy
  if v_channel_kind = 'direct' then
    select cm.user_id, cm.status
      into v_direct_recipient_id, v_direct_recipient_status
      from public.channel_members cm
     where cm.channel_id = v_msg.channel_id
       and cm.user_id <> v_msg.sender_id;

    if v_direct_recipient_id is null then
      return '[]'::jsonb;
    end if;

    if v_direct_recipient_status = 'pending' then
      -- First message of an unaccepted DM request
      v_type_key := 'chat.request.received';
      v_title := 'Message request';
      v_body := v_sender_name || ' wants to message you';
      v_route := '/messages';
      v_importance := 'normal';
    elsif v_direct_recipient_status = 'active' then
      -- Standard active DM
      v_type_key := 'chat.message.received';
      v_title := v_sender_name;
      v_body := v_sender_name || ': ' || v_preview;
      v_route := '/messages/' || v_msg.channel_id::text;
      v_importance := 'high';
    else
      -- Recipient declined, left, or was removed
      return '[]'::jsonb;
    end if;

    v_recipients := array[v_direct_recipient_id];
  else
    -- Group / team / match / tournament / broadcast channel
    v_type_key := 'chat.message.received';
    v_title := coalesce(nullif(trim(v_channel_title), ''), 'Group Chat');
    v_body := v_sender_name || ': ' || v_preview;
    v_route := '/messages/' || v_msg.channel_id::text;
    v_importance := 'high';

    select coalesce(array_agg(cm.user_id), '{}'::uuid[])
      into v_recipients
      from public.channel_members cm
     where cm.channel_id = v_msg.channel_id
       and cm.user_id <> v_msg.sender_id
       and cm.status = 'active';

    if cardinality(v_recipients) = 0 then
      return '[]'::jsonb;
    end if;
  end if;

  -- 6. Filter by blocks, mutes, and push preferences
  foreach v_recipient_id in array v_recipients loop
    -- Check user blocks in either direction
    if exists (
      select 1 from public.user_blocks b
       where (b.blocker_id = v_recipient_id and b.blocked_id = v_msg.sender_id)
          or (b.blocker_id = v_msg.sender_id and b.blocked_id = v_recipient_id)
    ) then
      continue;
    end if;

    -- Check chat channel mutes
    if exists (
      select 1 from public.notification_mutes m
       where m.user_id = v_recipient_id
         and m.scope = 'chat'
         and m.entity_id = v_msg.channel_id
         and (m.muted_until is null or m.muted_until > now())
    ) then
      continue;
    end if;

    -- Check push notification preferences for 'chat' category (defaults to enabled)
    if not coalesce(
      (select p.enabled from public.notification_preferences p
        where p.user_id = v_recipient_id
          and p.category = 'chat'
          and p.channel = 'push'),
      true
    ) then
      continue;
    end if;

    v_eligible_recipients := array_append(v_eligible_recipients, v_recipient_id);
  end loop;

  if cardinality(v_eligible_recipients) = 0 then
    return '[]'::jsonb;
  end if;

  -- 7. Query active device tokens for eligible recipients directly
  -- (EPHEMERAL: NO insertion into public.notifications)
  select coalesce(jsonb_agg(jsonb_build_object(
    'token_id', d.token_id,
    'fcm_token', d.fcm_token,
    'platform', d.platform,
    'recipient_id', d.user_id,
    'title', v_title,
    'body', v_body,
    'route', v_route,
    'type_key', v_type_key,
    'importance', v_importance,
    'chat_id', v_msg.channel_id::text,
    'message_id', v_msg.message_id::text,
    'sender_id', v_msg.sender_id::text
  )), '[]'::jsonb)
  into v_jobs
  from public.device_tokens d
  where d.user_id = any(v_eligible_recipients);

  return v_jobs;
end;
$$;

revoke all on function public.prepare_chat_push_jobs(uuid) from public, anon, authenticated;
grant execute on function public.prepare_chat_push_jobs(uuid) to service_role;

-- 2. Trigger function to asynchronously dispatch push via pg_net
create or replace function public.dispatch_chat_push()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_url text;
  v_key text;
begin
  -- Never notify on system messages or tombstones
  if new.message_type = 'system' or new.deleted_at is not null then
    return new;
  end if;

  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'supabase_url' limit 1;
  if v_url is null then
    v_url := current_setting('app.settings.supabase_url', true);
  end if;

  select decrypted_secret into v_key from vault.decrypted_secrets where name = 'notification_worker_secret' limit 1;
  if v_key is null then
    v_key := current_setting('app.settings.notification_worker_secret', true);
  end if;

  if v_url is null or v_key is null then
    return new;
  end if;

  -- Asynchronous HTTP POST via pg_net (non-blocking)
  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/send-chat-push',
    headers := jsonb_build_object(
      'content-type', 'application/json',
      'x-worker-secret', v_key
    ),
    body := jsonb_build_object('message_id', new.message_id),
    timeout_milliseconds := 15000
  );

  return new;
exception when others then
  -- Failures in push dispatch must never abort the message commit
  return new;
end;
$$;

drop trigger if exists trg_dispatch_chat_push on public.messages;
create trigger trg_dispatch_chat_push
  after insert on public.messages
  for each row execute function public.dispatch_chat_push();
