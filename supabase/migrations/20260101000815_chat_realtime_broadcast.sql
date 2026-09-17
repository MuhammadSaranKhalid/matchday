-- =============================================================================
-- 0815 · chat_realtime_broadcast — Ably real-time transport triggers
-- =============================================================================

create schema if not exists private;

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

  select full_name, avatar_url, username
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

  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
    headers := jsonb_build_object(
      'Authorization', v_auth_header,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'name', 'message.created',
      'data', v_payload::text
    )
  );

  for v_member in
    select user_id
      from public.channel_members
     where channel_id = new.channel_id
       and status = 'active'
       and user_id <> coalesce(new.sender_id, '00000000-0000-0000-0000-000000000000'::uuid)
  loop
    perform net.http_post(
      url := 'https://rest.ably.io/channels/user:' || v_member.user_id || '/messages',
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
          'last_message_at', new.created_at,
          'sender_id', new.sender_id,
          'sender_name', v_sender_name
        )::text
      )
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_broadcast_message_to_ably on public.messages;
create trigger trg_broadcast_message_to_ably
  after insert on public.messages
  for each row execute function public.broadcast_message_to_ably();

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
    v_payload := jsonb_build_object(
      'message_id', new.message_id,
      'channel_id', new.channel_id,
      'deleted_by', new.deleted_by,
      'deleted_at', new.deleted_at,
      'version', new.version
    );
  elsif (new.body is distinct from old.body or new.payload is distinct from old.payload) and new.deleted_at is null then
    v_event_name := 'message.edited';
    v_payload := jsonb_build_object(
      'message_id', new.message_id,
      'channel_id', new.channel_id,
      'body', new.body,
      'payload', new.payload,
      'version', new.version,
      'edited_at', new.edited_at
    );
  else
    return new;
  end if;

  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
    headers := jsonb_build_object(
      'Authorization', v_auth_header,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'name', v_event_name,
      'data', v_payload::text
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_broadcast_message_mutation_to_ably on public.messages;
create trigger trg_broadcast_message_mutation_to_ably
  after update on public.messages
  for each row execute function public.broadcast_message_mutation_to_ably();

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

  select channel_id into v_channel_id
    from public.messages
   where message_id = coalesce(new.message_id, old.message_id);

  if v_channel_id is null then
    return coalesce(new, old);
  end if;

  v_selected := (tg_op = 'INSERT' or (tg_op = 'UPDATE' and new.removed_at is null));

  v_payload := jsonb_build_object(
    'message_id', coalesce(new.message_id, old.message_id),
    'user_id', coalesce(new.user_id, old.user_id),
    'reaction', coalesce(new.reaction, old.reaction),
    'selected', v_selected,
    'updated_at', coalesce(new.updated_at, old.updated_at)
  );

  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || v_channel_id || '/messages',
    headers := jsonb_build_object(
      'Authorization', v_auth_header,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'name', 'reaction.updated',
      'data', v_payload::text
    )
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_broadcast_reaction_to_ably on public.message_reactions;
create trigger trg_broadcast_reaction_to_ably
  after insert or update on public.message_reactions
  for each row execute function public.broadcast_reaction_to_ably();

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

  if (old.last_read_message_seq is distinct from new.last_read_message_seq) and new.last_read_message_seq is not null then
    perform net.http_post(
      url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
      headers := jsonb_build_object(
        'Authorization', v_auth_header,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'name', 'receipt.read',
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'user_id', new.user_id,
          'through_seq', new.last_read_message_seq,
          'read_at', new.last_read_at
        )::text
      )
    );
  end if;

  if (old.last_delivered_message_seq is distinct from new.last_delivered_message_seq) and new.last_delivered_message_seq is not null then
    perform net.http_post(
      url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
      headers := jsonb_build_object(
        'Authorization', v_auth_header,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'name', 'receipt.delivered',
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'user_id', new.user_id,
          'through_seq', new.last_delivered_message_seq,
          'delivered_at', new.last_delivered_at
        )::text
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_broadcast_receipt_to_ably on public.channel_members;
create trigger trg_broadcast_receipt_to_ably
  after update on public.channel_members
  for each row execute function public.broadcast_receipt_to_ably();
