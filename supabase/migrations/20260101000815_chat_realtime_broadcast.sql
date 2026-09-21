-- =============================================================================
-- Migration: 20260101000815_chat_realtime_broadcast.sql
-- =============================================================================

-- 0815 · chat_realtime_broadcast — Ably real-time transport triggers

-- -----------------------------------------------------------------------------
-- Prerequisites
-- -----------------------------------------------------------------------------

create schema if not exists private;

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

create or replace function private.get_ably_auth_header()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_api_key text;
begin
  select
    decrypted_secret
  into v_api_key
  from vault.decrypted_secrets
  where name = 'ABLY_API_KEY'
  limit 1;
  if v_api_key is null then
    v_api_key := current_setting('app.settings.ably_api_key', true);
  end if;
  if v_api_key is null or v_api_key = '' then
    return null;
  end if;
  return 'Basic ' || encode(v_api_key::bytea, 'base64');
end;
$$;

revoke all on function private.get_ably_auth_header() from public, anon, authenticated;

grant execute on function private.get_ably_auth_header() to service_role;

-- 1. Broadcast Message Created
create or replace function public.broadcast_message_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_auth_header text;
  v_payload jsonb;
  v_sender_name text;
  v_sender_avatar text;
  v_sender_username text;
  v_member record;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;
  select
    display_name,
    profile_photo_url,
    username
  into v_sender_name, v_sender_avatar, v_sender_username
  from public.profiles
  where user_id = new.sender_id;
  v_payload := jsonb_build_object(
    'message_id',
    new.message_id,
    'channel_id',
    new.channel_id,
    'sender_id',
    new.sender_id,
    'sender_name',
    v_sender_name,
    'sender_avatar_url',
    v_sender_avatar,
    'sender_username',
    v_sender_username,
    'message_type',
    new.message_type,
    'body',
    new.body,
    'payload',
    new.payload,
    'reply_to_message_id',
    new.reply_to_message_id,
    'message_seq',
    new.message_seq,
    'version',
    new.version,
    'created_at',
    new.created_at
  );
  perform
    net.http_post(
      url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
      headers :=
        jsonb_build_object(
          'Authorization',
          v_auth_header,
          'Content-Type',
          'application/json'
        ),
      body := jsonb_build_object('name', 'message.created', 'data', v_payload::text)
    );
  for v_member in select
    user_id
  from public.channel_members
  where
    channel_id = new.channel_id
    and status = 'active'
    and user_id <> coalesce(
      new.sender_id,
      '00000000-0000-0000-0000-000000000000'::uuid
    ) loop
    perform
      net.http_post(
        url := 'https://rest.ably.io/channels/user:' || v_member.user_id || '/messages',
        headers :=
          jsonb_build_object(
            'Authorization',
            v_auth_header,
            'Content-Type',
            'application/json'
          ),
        body :=
          jsonb_build_object(
            'name',
            'channel.updated',
            'data',
            jsonb_build_object(
              'channel_id',
              new.channel_id,
              'last_message_seq',
              new.message_seq,
              'last_message_body',
              new.body,
              'last_message_at',
              new.created_at,
              'sender_id',
              new.sender_id,
              'sender_name',
              v_sender_name
            )::text
          )
      );
  end loop;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_broadcast_message_to_ably on public.messages;

create trigger trg_broadcast_message_to_ably
  after insert on public.messages
  for each row
  execute function public.broadcast_message_to_ably();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- 2. Broadcast Message Mutations (Edit / Delete)
create or replace function public.broadcast_message_mutation_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_auth_header text;
  v_event_name text;
  v_payload jsonb;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;
  if old.deleted_at is null and new.deleted_at is not null then
    v_event_name := 'message.deleted';
    v_payload := jsonb_build_object('message_id', new.message_id, 'channel_id', new.channel_id, 'deleted_by', new.deleted_by, 'deleted_at', new.deleted_at, 'version', new.version);
  elsif (new.body is distinct from old.body
      or new.payload is distinct from old.payload)
      and new.deleted_at is null then
      v_event_name := 'message.edited';
    v_payload := jsonb_build_object('message_id', new.message_id, 'channel_id', new.channel_id, 'body', new.body, 'payload', new.payload, 'version', new.version, 'edited_at', new.edited_at);
  else
    return new;
  end if;
  perform
    net.http_post(url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages', headers := jsonb_build_object('Authorization', v_auth_header, 'Content-Type', 'application/json'), body := jsonb_build_object('name', v_event_name, 'data', v_payload::text));
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_broadcast_message_mutation_to_ably on public.messages;

create trigger trg_broadcast_message_mutation_to_ably
  after update on public.messages
  for each row
  execute function public.broadcast_message_mutation_to_ably();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- 3. Broadcast Reactions
create or replace function public.broadcast_reaction_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_auth_header text;
  v_channel_id uuid;
  v_payload jsonb;
  v_selected boolean;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return coalesce(new, old);
  end if;
  select
    channel_id
  into v_channel_id
  from public.messages
  where message_id = coalesce(new.message_id, old.message_id);
  if v_channel_id is null then
    return coalesce(new, old);
  end if;
  v_selected := (tg_op = 'INSERT' or (tg_op = 'UPDATE' and new.removed_at is null));
  v_payload := jsonb_build_object(
    'message_id',
    coalesce(new.message_id, old.message_id),
    'user_id',
    coalesce(new.user_id, old.user_id),
    'reaction',
    coalesce(new.reaction, old.reaction),
    'selected',
    v_selected,
    'updated_at',
    coalesce(new.updated_at, old.updated_at)
  );
  perform
    net.http_post(
      url := 'https://rest.ably.io/channels/chat:' || v_channel_id || '/messages',
      headers :=
        jsonb_build_object(
          'Authorization',
          v_auth_header,
          'Content-Type',
          'application/json'
        ),
      body := jsonb_build_object('name', 'reaction.updated', 'data', v_payload::text)
    );
  return coalesce(new, old);
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_broadcast_reaction_to_ably on public.message_reactions;

create trigger trg_broadcast_reaction_to_ably
  after insert or update on public.message_reactions
  for each row
  execute function public.broadcast_reaction_to_ably();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- 4. Broadcast Receipt Horizons
create or replace function public.broadcast_receipt_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_auth_header text;
  v_sender_id uuid;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;
  if
    (old.last_read_message_seq is distinct from new.last_read_message_seq)
    and new.last_read_message_seq is not null
  then
    perform
      net.http_post(
        url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
        headers :=
          jsonb_build_object(
            'Authorization',
            v_auth_header,
            'Content-Type',
            'application/json'
          ),
        body :=
          jsonb_build_object(
            'name',
            'receipt.read',
            'data',
            jsonb_build_object(
              'channel_id',
              new.channel_id,
              'user_id',
              new.user_id,
              'through_seq',
              new.last_read_message_seq,
              'read_at',
              new.last_read_at
            )::text
          )
      );
  end if;
  if
    (old.last_delivered_message_seq is distinct from new.last_delivered_message_seq)
    and new.last_delivered_message_seq is not null
  then
    perform
      net.http_post(
        url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
        headers :=
          jsonb_build_object(
            'Authorization',
            v_auth_header,
            'Content-Type',
            'application/json'
          ),
        body :=
          jsonb_build_object(
            'name',
            'receipt.delivered',
            'data',
            jsonb_build_object(
              'channel_id',
              new.channel_id,
              'user_id',
              new.user_id,
              'through_seq',
              new.last_delivered_message_seq,
              'delivered_at',
              new.last_delivered_at
            )::text
          )
      );
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_broadcast_receipt_to_ably on public.channel_members;

create trigger trg_broadcast_receipt_to_ably
  after update on public.channel_members
  for each row
  execute function public.broadcast_receipt_to_ably();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

create or replace function public.prepare_chat_push_jobs(
  p_message_id uuid
)
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
  select
    m.message_id,
    m.channel_id,
    m.sender_id,
    m.message_type,
    m.body,
    m.created_at,
    m.deleted_at
  into
    v_msg
  from
    public.messages m
  where
    m.message_id = p_message_id;
  if v_msg.message_id is null or v_msg.deleted_at is not null or v_msg.message_type = 'system' then
    return '[]'::jsonb;
  end if;
  -- 2. Load sender info
  select
    coalesce(p.display_name, 'Someone')
  into
    v_sender_name
  from
    public.profiles p
  where
    p.user_id = v_msg.sender_id;
  -- 3. Load channel info
  select
    c.kind,
    c.title
  into
    v_channel_kind,
    v_channel_title
  from
    public.chat_channels c
  where
    c.channel_id = v_msg.channel_id;
  if v_channel_kind is null then
    return '[]'::jsonb;
  end if;
  -- 4. Render preview snippet
  v_preview := case when v_msg.message_type = 'text' then
    case when length(v_msg.body) > 100 then
      substring(v_msg.body from 1 for 97) || '…'
    else
      coalesce(v_msg.body, '')
    end
  when v_msg.message_type = 'image' then
    '📷 Photo'
  when v_msg.message_type = 'video' then
    '🎥 Video'
  when v_msg.message_type = 'audio' then
    '🎤 Voice message'
  when v_msg.message_type = 'file' then
    '📎 Attachment'
  else
    'New message'
  end;
  -- 5. Determine recipients and notification copy
  if v_channel_kind = 'direct' then
    select
      cm.user_id,
      cm.status
    into
      v_direct_recipient_id,
      v_direct_recipient_status
    from
      public.channel_members cm
    where
      cm.channel_id = v_msg.channel_id
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
    select
      coalesce(array_agg(cm.user_id), '{}'::uuid[])
    into
      v_recipients
    from
      public.channel_members cm
    where
      cm.channel_id = v_msg.channel_id
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
      select
        1
      from
        public.user_blocks b
      where (b.blocker_id = v_recipient_id
        and b.blocked_id = v_msg.sender_id)
      or (b.blocker_id = v_msg.sender_id
        and b.blocked_id = v_recipient_id)) then
  continue;
  end if;
  -- Check chat channel mutes
  if exists (
    select
      1
    from
      public.notification_mutes m
    where
      m.user_id = v_recipient_id
      and m.scope = 'chat'
      and m.entity_id = v_msg.channel_id
      and (m.muted_until is null
        or m.muted_until > now())) then
  continue;
end if;
  -- Check push notification preferences for 'chat' category (defaults to enabled)
  if not coalesce((
    select
      p.enabled
    from public.notification_preferences p
    where
      p.user_id = v_recipient_id and p.category = 'chat' and p.channel = 'push'), true) then
    continue;
  end if;
  v_eligible_recipients := array_append(v_eligible_recipients, v_recipient_id);
end loop;
  if cardinality(v_eligible_recipients) = 0 then
    return '[]'::jsonb;
  end if;
  -- 7. Query active device tokens for eligible recipients directly
  -- (EPHEMERAL: NO insertion into public.notifications)
  select
    coalesce(jsonb_agg(jsonb_build_object('token_id', d.token_id, 'fcm_token', d.fcm_token, 'platform', d.platform, 'recipient_id', d.user_id, 'title', v_title, 'body', v_body, 'route', v_route, 'type_key', v_type_key, 'importance', v_importance, 'chat_id', v_msg.channel_id::text, 'message_id', v_msg.message_id::text, 'sender_id', v_msg.sender_id::text)), '[]'::jsonb)
  into
    v_jobs
  from
    public.device_tokens d
  where
    d.user_id = any (v_eligible_recipients);
  return v_jobs;
end;
$$;

revoke all
on function public.prepare_chat_push_jobs(uuid)
from public, anon, authenticated;

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
  select
    decrypted_secret
  into v_url
  from vault.decrypted_secrets
  where name = 'supabase_url'
  limit 1;
  if v_url is null then
    v_url := current_setting('app.settings.supabase_url', true);
  end if;
  select
    decrypted_secret
  into v_key
  from vault.decrypted_secrets
  where name = 'notification_worker_secret'
  limit 1;
  if v_key is null then
    v_key := current_setting('app.settings.notification_worker_secret', true);
  end if;
  if v_url is null or v_key is null then
    return new;
  end if;
  -- Asynchronous HTTP POST via pg_net (non-blocking)
  perform
    net.http_post(
      url := rtrim(v_url, '/') || '/functions/v1/send-chat-push',
      headers :=
        jsonb_build_object(
          'content-type',
          'application/json',
          'x-worker-secret',
          v_key
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

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists trg_dispatch_chat_push on public.messages;

create trigger trg_dispatch_chat_push
  after insert on public.messages
  for each row
  execute function public.dispatch_chat_push();
