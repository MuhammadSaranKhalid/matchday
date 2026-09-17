-- =============================================================================
-- 20260917230000 · Idempotent Send Message & Durable Receipt Changes Ledger
-- =============================================================================
-- 1. Makes send_channel_message() fully idempotent: if a message with the
--    supplied message_id already exists for the same sender and channel,
--    it returns the existing row successfully rather than throwing 23505 unique_violation.
-- 2. Records read and delivered receipts into public.chat_changes so that
--    counterparty receipt horizons are durable and catch-up recoverable
--    after offline disconnections.
-- =============================================================================

-- 1. Idempotent send_channel_message()
create or replace function public.send_channel_message(
  p_channel_id uuid,
  p_message_id uuid default gen_random_uuid(),
  p_message_type public.chat_message_type default 'text',
  p_body text default null,
  p_reply_to_message_id uuid default null,
  p_payload jsonb default '{}'::jsonb
)
returns public.messages
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_can_send boolean;
  v_media_enabled boolean;
  v_max_len integer;
  v_slow_mode integer;
  v_last_msg_at timestamptz;
  v_wait_seconds integer;
  v_new_msg public.messages;
  v_now timestamptz := clock_timestamp();
  v_att jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Check for existing message_id for idempotent retry
  if p_message_id is not null then
    select * into v_new_msg
      from public.messages
     where message_id = p_message_id;

    if v_new_msg.message_id is not null then
      if v_new_msg.sender_id = v_actor and v_new_msg.channel_id = p_channel_id then
        return v_new_msg;
      else
        raise exception 'CHAT_MESSAGE_ID_CONFLICT: Message ID already exists for different sender or channel'
          using errcode = '23505';
      end if;
    end if;
  end if;

  if p_message_type = 'system' then
    raise exception 'CHAT_SYSTEM_MESSAGES_FORBIDDEN: System messages cannot be sent by clients'
      using errcode = '42501';
  end if;

  v_can_send := private.has_channel_permission(v_actor, p_channel_id, 'send_messages');
  if not v_can_send then
    raise exception 'Permission denied: send_messages not permitted' using errcode = '42501';
  end if;

  select media_enabled, max_message_length, slow_mode_seconds
    into v_media_enabled, v_max_len, v_slow_mode
    from public.channel_policies
   where channel_id = p_channel_id;

  if p_message_type in ('image', 'video', 'audio', 'file') and not coalesce(v_media_enabled, true) then
    raise exception 'CHAT_MEDIA_DISABLED: Media messages are disabled in this channel'
      using errcode = '42501';
  end if;

  if p_body is not null and length(p_body) > coalesce(v_max_len, 4000) then
    raise exception 'Message exceeds max length of %', v_max_len using errcode = '22023';
  end if;

  if coalesce(v_slow_mode, 0) > 0 then
    select created_at into v_last_msg_at
      from public.messages
     where channel_id = p_channel_id
       and sender_id = v_actor
     order by created_at desc
     limit 1;

    if v_last_msg_at is not null and (v_now - v_last_msg_at) < (v_slow_mode * interval '1 second') then
      v_wait_seconds := v_slow_mode - floor(extract(epoch from (v_now - v_last_msg_at)))::integer;
      if v_wait_seconds < 1 then v_wait_seconds := 1; end if;
      raise exception 'CHAT_SLOW_MODE: Please wait % seconds before sending again', v_wait_seconds
        using errcode = 'P0001',
              detail = jsonb_build_object('code', 'CHAT_SLOW_MODE', 'retry_after_seconds', v_wait_seconds)::text;
    end if;
  end if;

  perform private.guard_dm_request_limit(p_channel_id, v_actor);

  begin
    insert into public.messages (
      message_id,
      channel_id,
      sender_id,
      message_type,
      body,
      payload,
      reply_to_message_id,
      created_at,
      updated_at
    ) values (
      p_message_id,
      p_channel_id,
      v_actor,
      p_message_type,
      p_body,
      coalesce(p_payload, '{}'::jsonb),
      p_reply_to_message_id,
      v_now,
      v_now
    ) returning * into v_new_msg;
  exception when unique_violation then
    -- Catch race conditions where another identical call committed concurrently
    select * into v_new_msg
      from public.messages
     where message_id = p_message_id;

    if v_new_msg.message_id is not null and v_new_msg.sender_id = v_actor and v_new_msg.channel_id = p_channel_id then
      return v_new_msg;
    else
      raise;
    end if;
  end;

  if p_payload ? 'attachment' then
    v_att := p_payload->'attachment';
    insert into public.message_attachments (
      attachment_id,
      message_id,
      storage_path,
      mime_type,
      file_name,
      size_bytes,
      width,
      height,
      duration_ms,
      created_at
    ) values (
      coalesce((v_att->>'attachment_id')::uuid, gen_random_uuid()),
      v_new_msg.message_id,
      v_att->>'storage_path',
      coalesce(v_att->>'mime_type', 'application/octet-stream'),
      v_att->>'file_name',
      (v_att->>'size_bytes')::bigint,
      (v_att->>'width')::integer,
      (v_att->>'height')::integer,
      (v_att->>'duration_ms')::bigint,
      v_now
    ) on conflict (attachment_id) do nothing;
  end if;

  update public.channel_members
     set last_read_message_seq = greatest(coalesce(last_read_message_seq, 0), v_new_msg.message_seq),
         last_read_at = v_now,
         last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), v_new_msg.message_seq),
         last_delivered_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  update public.chat_channels
     set last_message_seq = v_new_msg.message_seq,
         last_message_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id;

  return v_new_msg;
end;
$$;

revoke all on function public.send_channel_message(uuid, uuid, public.chat_message_type, text, uuid, jsonb) from public, anon;
grant execute on function public.send_channel_message(uuid, uuid, public.chat_message_type, text, uuid, jsonb) to authenticated;

-- 2. Durable mark_channel_read() with chat_changes ledger recording
create or replace function public.mark_channel_read(
  p_channel_id uuid,
  p_through_seq bigint
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_current_horizon bigint;
  v_read_receipts_enabled boolean;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select coalesce(last_read_message_seq, 0) into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor
     and status in ('active', 'pending');

  if not found then
    raise exception 'User is not a member of channel' using errcode = '42501';
  end if;

  -- Monotonic true-crossing guard
  if p_through_seq <= v_current_horizon then
    return;
  end if;

  select read_receipts_enabled into v_read_receipts_enabled
    from public.channel_policies
   where channel_id = p_channel_id;

  update public.channel_members
     set last_read_message_seq = p_through_seq,
         last_read_at = v_now,
         last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), p_through_seq),
         last_delivered_at = case
           when coalesce(last_delivered_message_seq, 0) < p_through_seq then v_now
           else last_delivered_at
         end,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  if coalesce(v_read_receipts_enabled, true) then
    insert into public.channel_receipt_events (
      channel_id, user_id, receipt_type, through_message_seq, created_at
    ) values (
      p_channel_id, v_actor, 'read', p_through_seq, v_now
    );

    insert into public.chat_changes (
      channel_id, entity_type, entity_id, operation, actor_id, payload, created_at
    ) values (
      p_channel_id, 'receipt', v_actor::text, 'insert', v_actor,
      jsonb_build_object(
        'type', 'read',
        'user_id', v_actor,
        'through_message_seq', p_through_seq,
        'through_seq', p_through_seq
      ),
      v_now
    );
  end if;
end;
$$;

revoke all on function public.mark_channel_read(uuid, bigint) from public, anon;
grant execute on function public.mark_channel_read(uuid, bigint) to authenticated;

-- 3. Durable mark_channel_delivered() with chat_changes ledger recording
create or replace function public.mark_channel_delivered(
  p_channel_id uuid,
  p_through_seq bigint
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_current_horizon bigint;
  v_delivery_receipts_enabled boolean;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select coalesce(last_delivered_message_seq, 0) into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor
     and status in ('active', 'pending');

  if not found then
    raise exception 'User is not a member of channel' using errcode = '42501';
  end if;

  -- Monotonic true-crossing guard
  if p_through_seq <= v_current_horizon then
    return;
  end if;

  select delivery_receipts_enabled into v_delivery_receipts_enabled
    from public.channel_policies
   where channel_id = p_channel_id;

  update public.channel_members
     set last_delivered_message_seq = p_through_seq,
         last_delivered_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  if coalesce(v_delivery_receipts_enabled, true) then
    insert into public.channel_receipt_events (
      channel_id, user_id, receipt_type, through_message_seq, created_at
    ) values (
      p_channel_id, v_actor, 'delivered', p_through_seq, v_now
    );

    insert into public.chat_changes (
      channel_id, entity_type, entity_id, operation, actor_id, payload, created_at
    ) values (
      p_channel_id, 'receipt', v_actor::text, 'insert', v_actor,
      jsonb_build_object(
        'type', 'delivered',
        'user_id', v_actor,
        'through_message_seq', p_through_seq,
        'through_seq', p_through_seq
      ),
      v_now
    );
  end if;
end;
$$;

revoke all on function public.mark_channel_delivered(uuid, bigint) from public, anon;
grant execute on function public.mark_channel_delivered(uuid, bigint) to authenticated;
