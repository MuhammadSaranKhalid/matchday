-- =============================================================================
-- 20260917220000 · Fix Ably Auth Header Newline & Enhance Message Broadcasts
-- =============================================================================
-- 1. Strips newline (\n) and carriage return (\r) characters produced by
--    Postgres's encode(..., 'base64') in private.get_ably_auth_header().
--    Those characters caused HTTP header splitting in libcurl / pg_net,
--    resulting in Ably 400 Bad Request ("invalid request: invalid body").
-- 2. Adds idempotency ID to the Ably channel publish payload.
-- 3. Provides complete metadata aliases in user inbox broadcast events.
-- =============================================================================

-- 1. Fix private.get_ably_auth_header()
create or replace function private.get_ably_auth_header()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_api_key text;
begin
  select decrypted_secret into v_api_key
    from vault.decrypted_secrets
   where name = 'ABLY_API_KEY'
   limit 1;

  if v_api_key is null then
    v_api_key := current_setting('app.settings.ably_api_key', true);
  end if;

  if v_api_key is null or trim(v_api_key) = '' then
    return null;
  end if;

  -- Postgres encode(bytea, 'base64') appends \n by default (RFC 2045 MIME).
  -- In HTTP headers, newlines cause header splitting / body corruption.
  return 'Basic ' || translate(encode(trim(v_api_key)::bytea, 'base64'), E'\r\n', '');
end;
$$;

revoke all on function private.get_ably_auth_header() from public, anon, authenticated;
grant execute on function private.get_ably_auth_header() to service_role;

-- 2. Enhanced broadcast_message_to_ably()
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

  select display_name, profile_photo_url, username
    into v_sender_name, v_sender_avatar, v_sender_username
    from public.profiles
   where user_id = new.sender_id;

  v_payload := jsonb_build_object(
    'message_id', new.message_id,
    'channel_id', new.channel_id,
    'sender_id', new.sender_id,
    'sender_name', v_sender_name,
    'sender_avatar_url', v_sender_avatar,
    'sender_username', v_sender_username,
    'message_type', new.message_type,
    'body', new.body,
    'payload', new.payload,
    'reply_to_message_id', new.reply_to_message_id,
    'message_seq', new.message_seq,
    'version', new.version,
    'created_at', new.created_at
  );

  -- 1. Broadcast hot message to the channel with idempotency key
  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
    headers := jsonb_build_object(
      'Authorization', v_auth_header,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'name', 'message.created',
      'id', new.message_id::text,
      'data', v_payload::text
    )
  );

  -- 2. Broadcast inbox summary update to all other members (active and pending)
  for v_member in
    select user_id
      from public.channel_members
     where channel_id = new.channel_id
       and status in ('active', 'pending')
       and user_id <> coalesce(new.sender_id, '00000000-0000-0000-0000-000000000000'::uuid)
  loop
    perform net.http_post(
      url := 'https://rest.ably.io/channels/user:' || v_member.user_id || ':chat/messages',
      headers := jsonb_build_object(
        'Authorization', v_auth_header,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'name', 'channel.updated',
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'last_message_seq', new.message_seq,
          'last_message_body', new.body,
          'body', new.body,
          'body_preview', new.body,
          'last_message_at', new.created_at,
          'created_at', new.created_at,
          'sender_id', new.sender_id,
          'sender_name', v_sender_name,
          'sender_display_name', v_sender_name
        )::text
      )
    );
  end loop;

  return new;
end;
$$;
