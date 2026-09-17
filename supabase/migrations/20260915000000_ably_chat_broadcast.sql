-- =============================================================================
-- 20260915000000_ably_chat_broadcast.sql
-- =============================================================================
-- Dispatches an asynchronous HTTP POST via pg_net to the Ably REST API
-- whenever a row is inserted into public.messages.
--
-- Uses the standardized Matchday Chat event envelope (§10.4):
--   Channel: chat:<channel_id>
--   Event:   message.created
--   Fan-out: user:<user_id>:chat (event: channel.updated)
-- =============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.broadcast_message_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net, vault, pg_temp
as $$
declare
  v_ably_api_key text;
  v_channel_id text;
  v_envelope jsonb;
  v_auth_header text;
  v_sender_name text;
begin
  -- 1. Look up ABLY_API_KEY from Supabase Vault (decrypted at query time)
  begin
    select decrypted_secret into v_ably_api_key
      from vault.decrypted_secrets
     where lower(name) in ('ably_api_key', 'ably_key', 'ably')
     order by (case when name = 'ABLY_API_KEY' then 1 else 2 end)
     limit 1;
  exception
    when others then
      v_ably_api_key := null;
  end;

  -- 2. Fallback to custom GUC setting if vault secret was not populated
  if v_ably_api_key is null or v_ably_api_key = '' then
    v_ably_api_key := current_setting('app.settings.ably_api_key', true);
  end if;

  -- If no key is configured in dev environment, exit cleanly without blocking the insert
  if v_ably_api_key is null or v_ably_api_key = '' then
    return new;
  end if;

  select display_name into v_sender_name
    from public.profiles
   where user_id = new.sender_id;

  v_channel_id := 'chat:' || new.channel_id::text;

  -- Standard event envelope (§10.4)
  v_envelope := jsonb_build_object(
    'name', 'message.created',
    'data', jsonb_build_object(
      'event_id', gen_random_uuid(),
      'event_seq', new.message_seq,
      'type', 'message.created',
      'channel_id', new.channel_id,
      'entity_id', new.message_id,
      'entity_version', new.version,
      'occurred_at', new.created_at,
      'data', jsonb_build_object(
        'message_id', new.message_id,
        'message_seq', new.message_seq,
        'channel_id', new.channel_id,
        'sender_id', new.sender_id,
        'sender_display_name', coalesce(v_sender_name, 'Teammate'),
        'body', new.body,
        'message_type', new.message_type,
        'payload', new.payload,
        'reply_to_message_id', new.reply_to_message_id,
        'version', new.version,
        'created_at', new.created_at
      )
    )
  );

  -- PostgreSQL encode(..., 'base64') appends newlines; strip them to form a valid HTTP Authorization header
  v_auth_header := 'Basic ' || replace(replace(encode(v_ably_api_key::bytea, 'base64'), E'\r', ''), E'\n', '');

  -- 1. Broadcast 'message.created' to the active channel via pg_net
  perform net.http_post(
    url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', v_auth_header
    ),
    body := v_envelope
  );

  -- 2. Fan-out 'channel.updated' to personal inbox notification channels of other participants
  declare
    r_member record;
    v_inbox_payload jsonb;
  begin
    v_inbox_payload := jsonb_build_object(
      'name', 'channel.updated',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'type', 'channel.updated',
        'channel_id', new.channel_id,
        'entity_id', new.message_id,
        'occurred_at', new.created_at,
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'last_message_seq', new.message_seq,
          'sender_id', new.sender_id,
          'sender_display_name', coalesce(v_sender_name, 'Teammate'),
          'body_preview', case when new.message_type = 'image' then '📷 Photo' else left(coalesce(new.body, ''), 120) end,
          'created_at', new.created_at
        )
      )
    );

    for r_member in (
      select user_id
        from public.channel_members
       where channel_id = new.channel_id
         and user_id <> coalesce(new.sender_id, '00000000-0000-0000-0000-000000000000'::uuid)
         and status = 'active'
    ) loop
      perform net.http_post(
        url := 'https://rest.ably.io/channels/user:' || r_member.user_id::text || ':chat/messages',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', v_auth_header
        ),
        body := v_inbox_payload
      );
    end loop;
  end;

  return new;
exception
  when others then
    -- Realtime broadcast failures must never roll back user message persistence
    return new;
end;
$$;

revoke all on function public.broadcast_message_to_ably() from public;
grant execute on function public.broadcast_message_to_ably() to authenticated, service_role;

drop trigger if exists trg_broadcast_message_to_ably on public.messages;
create trigger trg_broadcast_message_to_ably
  after insert on public.messages
  for each row
  execute function public.broadcast_message_to_ably();
