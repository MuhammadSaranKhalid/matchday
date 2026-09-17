-- =============================================================================
-- 20260916000000_ably_chat_events_broadcast.sql
-- =============================================================================
-- Dispatches asynchronous HTTP POSTs via pg_net to Ably REST API for:
--   1. Message mutations (message.edited, message.deleted)
--   2. Member receipts (receipt.read, receipt.delivered)
--   3. Message reactions (reaction.updated)
--
-- Follows Matchday Chat Architecture Specification §10.2 & §10.4.
-- =============================================================================

create extension if not exists pg_net with schema extensions;

-- Helper to retrieve decrypted Ably API key and format Authorization header
create or replace function private.get_ably_auth_header()
returns text
language plpgsql
security definer
set search_path = public, extensions, vault, pg_temp
as $$
declare
  v_ably_api_key text;
begin
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

  if v_ably_api_key is null or v_ably_api_key = '' then
    v_ably_api_key := current_setting('app.settings.ably_api_key', true);
  end if;

  if v_ably_api_key is null or v_ably_api_key = '' then
    return null;
  end if;

  return 'Basic ' || replace(replace(encode(v_ably_api_key::bytea, 'base64'), E'\r', ''), E'\n', '');
end;
$$;

revoke all on function private.get_ably_auth_header() from public;
grant execute on function private.get_ably_auth_header() to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 1. Broadcast Message Mutations (edit, soft-delete)
-- -----------------------------------------------------------------------------
create or replace function public.broadcast_message_mutation_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net, pg_temp
as $$
declare
  v_auth_header text;
  v_channel_id text;
  v_envelope jsonb;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;

  v_channel_id := 'chat:' || new.channel_id::text;

  -- 1. Soft-delete event
  if new.deleted_at is not null and (old.deleted_at is null) then
    v_envelope := jsonb_build_object(
      'name', 'message.deleted',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'type', 'message.deleted',
        'channel_id', new.channel_id,
        'entity_id', new.message_id,
        'occurred_at', new.deleted_at,
        'data', jsonb_build_object(
          'message_id', new.message_id,
          'channel_id', new.channel_id,
          'deleted_by', new.deleted_by,
          'deleted_at', new.deleted_at
        )
      )
    );

    perform net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
    return new;
  end if;

  -- 2. Edit event
  if new.edited_at is not null and (old.edited_at is null or new.edited_at > old.edited_at) then
    v_envelope := jsonb_build_object(
      'name', 'message.edited',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'event_seq', new.message_seq,
        'type', 'message.edited',
        'channel_id', new.channel_id,
        'entity_id', new.message_id,
        'entity_version', new.version,
        'occurred_at', new.edited_at,
        'data', jsonb_build_object(
          'message_id', new.message_id,
          'message_seq', new.message_seq,
          'channel_id', new.channel_id,
          'sender_id', new.sender_id,
          'body', new.body,
          'payload', new.payload,
          'version', new.version,
          'edited_at', new.edited_at
        )
      )
    );

    perform net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
  end if;

  return new;
exception
  when others then
    return new;
end;
$$;

revoke all on function public.broadcast_message_mutation_to_ably() from public;
grant execute on function public.broadcast_message_mutation_to_ably() to authenticated, service_role;

drop trigger if exists trg_broadcast_message_mutation_to_ably on public.messages;
create trigger trg_broadcast_message_mutation_to_ably
  after update on public.messages
  for each row
  when (old.edited_at is distinct from new.edited_at or old.deleted_at is distinct from new.deleted_at)
  execute function public.broadcast_message_mutation_to_ably();

-- -----------------------------------------------------------------------------
-- 2. Broadcast Member Horizons (receipt.read, receipt.delivered)
-- -----------------------------------------------------------------------------
create or replace function public.broadcast_receipt_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net, pg_temp
as $$
declare
  v_auth_header text;
  v_channel_id text;
  v_envelope jsonb;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;

  v_channel_id := 'chat:' || new.channel_id::text;

  -- Read receipt
  if new.last_read_message_seq is not null and (old.last_read_message_seq is null or new.last_read_message_seq > old.last_read_message_seq) then
    v_envelope := jsonb_build_object(
      'name', 'receipt.read',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'type', 'receipt.read',
        'channel_id', new.channel_id,
        'entity_id', new.user_id,
        'occurred_at', coalesce(new.last_read_at, now()),
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'user_id', new.user_id,
          'through_message_seq', new.last_read_message_seq,
          'read_at', coalesce(new.last_read_at, now())
        )
      )
    );

    perform net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
  end if;

  -- Delivered receipt
  if new.last_delivered_message_seq is not null and (old.last_delivered_message_seq is null or new.last_delivered_message_seq > old.last_delivered_message_seq) then
    v_envelope := jsonb_build_object(
      'name', 'receipt.delivered',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'type', 'receipt.delivered',
        'channel_id', new.channel_id,
        'entity_id', new.user_id,
        'occurred_at', coalesce(new.last_delivered_at, now()),
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'user_id', new.user_id,
          'through_message_seq', new.last_delivered_message_seq,
          'delivered_at', coalesce(new.last_delivered_at, now())
        )
      )
    );

    perform net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
  end if;

  return new;
exception
  when others then
    return new;
end;
$$;

revoke all on function public.broadcast_receipt_to_ably() from public;
grant execute on function public.broadcast_receipt_to_ably() to authenticated, service_role;

drop trigger if exists trg_broadcast_receipt_to_ably on public.channel_members;
create trigger trg_broadcast_receipt_to_ably
  after update on public.channel_members
  for each row
  when (
    old.last_read_message_seq is distinct from new.last_read_message_seq
    or old.last_delivered_message_seq is distinct from new.last_delivered_message_seq
  )
  execute function public.broadcast_receipt_to_ably();

-- -----------------------------------------------------------------------------
-- 3. Broadcast Message Reactions (reaction.updated)
-- -----------------------------------------------------------------------------
create or replace function public.broadcast_reaction_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net, pg_temp
as $$
declare
  v_auth_header text;
  v_channel_id uuid;
  v_envelope jsonb;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;

  select channel_id into v_channel_id
    from public.messages
   where message_id = new.message_id;

  if v_channel_id is null then
    return new;
  end if;

  v_envelope := jsonb_build_object(
    'name', 'reaction.updated',
    'data', jsonb_build_object(
      'event_id', gen_random_uuid(),
      'type', 'reaction.updated',
      'channel_id', v_channel_id,
      'entity_id', new.message_id,
      'occurred_at', coalesce(new.updated_at, new.created_at),
      'data', jsonb_build_object(
        'message_id', new.message_id,
        'channel_id', v_channel_id,
        'user_id', new.user_id,
        'reaction', new.reaction,
        'created_at', new.created_at,
        'is_removed', (new.removed_at is not null)
      )
    )
  );

  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || v_channel_id::text || '/messages',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', v_auth_header
    ),
    body := v_envelope
  );

  return new;
exception
  when others then
    return new;
end;
$$;

revoke all on function public.broadcast_reaction_to_ably() from public;
grant execute on function public.broadcast_reaction_to_ably() to authenticated, service_role;

drop trigger if exists trg_broadcast_reaction_to_ably on public.message_reactions;
create trigger trg_broadcast_reaction_to_ably
  after insert or update on public.message_reactions
  for each row
  execute function public.broadcast_reaction_to_ably();
