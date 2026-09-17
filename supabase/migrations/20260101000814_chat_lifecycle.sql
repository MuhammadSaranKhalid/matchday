-- =============================================================================
-- 0814 · chat_lifecycle — permissions, RPC mutations, and RLS policies
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Central Predicates
-- -----------------------------------------------------------------------------
create or replace function public.is_chat_member(p_channel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from public.channel_members cm
     where cm.channel_id = p_channel_id
       and cm.user_id = (select auth.uid())
       and cm.status in ('active', 'pending')
  );
$$;

create or replace function private.has_channel_permission(
  p_user_id uuid,
  p_channel_id uuid,
  p_permission public.chat_permission
)
returns boolean
language plpgsql
stable
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_role public.chat_member_role;
  v_status public.chat_member_status;
  v_context public.chat_channel_context;
  v_team_id uuid;
  v_match_id uuid;
  v_posting_mode public.chat_posting_mode;
  v_has_role_perm boolean := false;
  v_is_restricted boolean := false;
begin
  if p_user_id is null or p_channel_id is null then
    return false;
  end if;

  select cm.role, cm.status, cc.context_type, cc.team_id, cc.match_id, cp.posting_mode
    into v_role, v_status, v_context, v_team_id, v_match_id, v_posting_mode
    from public.channel_members cm
    join public.chat_channels cc on cc.channel_id = cm.channel_id
    left join public.channel_policies cp on cp.channel_id = cc.channel_id
   where cm.channel_id = p_channel_id
     and cm.user_id = p_user_id;

  if v_status is null or v_status not in ('active', 'pending') then
    return false;
  end if;

  if v_status = 'pending' then
    return (p_permission = 'view_channel');
  end if;

  select exists (
    select 1 from public.channel_role_permissions crp
     where crp.role = v_role
       and crp.permission = p_permission
  ) into v_has_role_perm;

  if not v_has_role_perm and v_context = 'team' and v_team_id is not null then
    if exists (
      select 1 from public.team_members tm
       where tm.team_id = v_team_id
         and tm.user_id = p_user_id
         and tm.status = 'active'
    ) then
      if p_permission in (
        'view_channel', 'send_messages', 'send_media', 'add_reactions',
        'reply_to_messages', 'edit_own_messages', 'delete_own_messages', 'view_member_receipts'
      ) then
        v_has_role_perm := true;
      end if;
    end if;
  end if;

  if not v_has_role_perm then
    return false;
  end if;

  if p_permission in ('send_messages', 'send_media') and v_posting_mode is not null then
    if v_posting_mode = 'owner' and v_role <> 'owner' then
      return false;
    elsif v_posting_mode = 'admins' and v_role not in ('owner', 'admin') then
      return false;
    elsif v_posting_mode = 'moderators' and v_role not in ('owner', 'admin', 'moderator') then
      return false;
    end if;
  end if;

  select exists (
    select 1 from public.channel_member_restrictions cmr
     where cmr.channel_id = p_channel_id
       and cmr.user_id = p_user_id
       and cmr.permission = p_permission
       and cmr.starts_at <= now()
       and cmr.revoked_at is null
       and (cmr.expires_at is null or cmr.expires_at > now())
  ) into v_is_restricted;

  if v_is_restricted then
    return false;
  end if;

  return true;
end;
$$;

create or replace function private.guard_dm_request_limit(
  p_channel_id uuid,
  p_sender_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_kind public.chat_channel_kind;
  v_recipient_status public.chat_member_status;
  v_msg_count int;
begin
  select kind into v_kind
    from public.chat_channels
   where channel_id = p_channel_id;

  if v_kind <> 'direct' then
    return;
  end if;

  select status into v_recipient_status
    from public.channel_members
   where channel_id = p_channel_id
     and user_id <> p_sender_id;

  if v_recipient_status = 'pending' then
    -- Count all attempted messages (including tombstones) to prevent delete-bypass
    select count(*) into v_msg_count
      from public.messages
     where channel_id = p_channel_id
       and sender_id = p_sender_id;

    if v_msg_count >= 1 then
      raise exception 'CHAT_DM_REQUEST_LIMIT: Cannot send more messages until recipient accepts the chat invite'
        using errcode = 'P0001';
    end if;
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Lifecycle RPCs
-- -----------------------------------------------------------------------------
create or replace function public.create_group_channel(
  p_title text,
  p_description text default null,
  p_avatar_url text default null,
  p_initial_member_ids uuid[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_channel_id uuid;
  v_member_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_title is null or length(trim(p_title)) < 1 then
    raise exception 'Channel title cannot be empty' using errcode = '22023';
  end if;

  insert into public.chat_channels (
    channel_key,
    kind,
    context_type,
    visibility,
    title,
    description,
    avatar_url,
    created_by
  ) values (
    'group:' || gen_random_uuid(),
    'group',
    'none',
    'private',
    trim(p_title),
    p_description,
    p_avatar_url,
    v_actor
  ) returning channel_id into v_channel_id;

  insert into public.channel_policies (channel_id) values (v_channel_id);

  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    joined_at
  ) values (
    v_channel_id,
    v_actor,
    'owner',
    'active',
    now()
  );

  insert into public.channel_membership_periods (channel_id, user_id, joined_at)
  values (v_channel_id, v_actor, now());

  if p_initial_member_ids is not null and array_length(p_initial_member_ids, 1) > 0 then
    foreach v_member_id in array p_initial_member_ids loop
      if v_member_id <> v_actor then
        insert into public.channel_members (
          channel_id,
          user_id,
          role,
          status,
          invited_by,
          invited_at
        ) values (
          v_channel_id,
          v_member_id,
          'member',
          'pending',
          v_actor,
          now()
        ) on conflict do nothing;
      end if;
    end loop;
  end if;

  return v_channel_id;
end;
$$;

create or replace function public.get_or_create_direct_channel(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_caller_id uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_channel_key text;
  v_channel_id uuid;
  v_caller_follows boolean;
  v_target_follows boolean;
  v_target_status public.chat_member_status;
begin
  if v_caller_id is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_target_user_id is null or p_target_user_id = v_caller_id then
    raise exception 'Invalid target user' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.user_blocks
     where (blocker_id = v_caller_id and blocked_id = p_target_user_id)
        or (blocker_id = p_target_user_id and blocked_id = v_caller_id)
  ) then
    raise exception 'Cannot message this user' using errcode = '42501';
  end if;

  if v_caller_id < p_target_user_id then
    v_low := v_caller_id;
    v_high := p_target_user_id;
  else
    v_low := p_target_user_id;
    v_high := v_caller_id;
  end if;
  v_channel_key := 'dm:' || v_low || ':' || v_high;

  select channel_id into v_channel_id
    from public.chat_channels
   where channel_key = v_channel_key;

  if v_channel_id is null then
    insert into public.chat_channels (
      channel_key,
      kind,
      context_type,
      visibility,
      created_by
    ) values (
      v_channel_key,
      'direct',
      'none',
      'private',
      v_caller_id
    )
    on conflict (channel_key) do nothing
    returning channel_id into v_channel_id;

    if v_channel_id is null then
      select channel_id into v_channel_id
        from public.chat_channels
       where channel_key = v_channel_key;
    end if;

    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;
  end if;

  select exists (
    select 1 from public.follows
     where follower_id = v_caller_id and following_id = p_target_user_id
  ) into v_caller_follows;

  select exists (
    select 1 from public.follows
     where follower_id = p_target_user_id and following_id = v_caller_id
  ) into v_target_follows;

  if v_caller_follows and v_target_follows then
    v_target_status := 'active';
  else
    v_target_status := 'pending';
  end if;

  -- Caller is active
  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    joined_at
  ) values (
    v_channel_id,
    v_caller_id,
    'member',
    'active',
    now()
  ) on conflict (channel_id, user_id) do nothing;

  -- Target user is active or pending
  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    invited_by,
    invited_at,
    joined_at
  ) values (
    v_channel_id,
    p_target_user_id,
    'member',
    v_target_status,
    v_caller_id,
    now(),
    case when v_target_status = 'active' then now() else null end
  ) on conflict (channel_id, user_id) do nothing;

  return v_channel_id;
end;
$$;

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

create or replace function public.edit_channel_message(
  p_message_id uuid,
  p_expected_version integer,
  p_new_body text,
  p_payload jsonb default null
)
returns public.messages
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_channel_id uuid;
  v_current_version integer;
  v_updated public.messages;
  v_now timestamptz := clock_timestamp();
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select channel_id, version into v_channel_id, v_current_version
    from public.messages
   where message_id = p_message_id
     and sender_id = v_actor
     and deleted_at is null;

  if v_channel_id is null then
    raise exception 'CHAT_MESSAGE_NOT_FOUND: Message not found or unauthorized'
      using errcode = 'P0001';
  end if;

  if not private.has_channel_permission(v_actor, v_channel_id, 'edit_own_messages') then
    raise exception 'CHAT_PERMISSION_DENIED: You do not have permission to edit messages in this channel'
      using errcode = '42501';
  end if;

  if v_current_version <> p_expected_version then
    raise exception 'CHAT_CONCURRENT_MODIFICATION: Message was modified concurrently'
      using errcode = 'P0001';
  end if;

  update public.messages
     set body = p_new_body,
         payload = coalesce(p_payload, payload),
         version = version + 1,
         edited_at = v_now,
         updated_at = v_now
   where message_id = p_message_id
   returning * into v_updated;

  insert into public.chat_changes (
    channel_id,
    entity_type,
    entity_id,
    operation,
    actor_id,
    payload
  ) values (
    v_channel_id,
    'message',
    p_message_id::text,
    'update',
    v_actor,
    jsonb_build_object(
      'message_id', p_message_id,
      'body', p_new_body,
      'version', v_updated.version,
      'edited_at', v_now
    )
  );

  return v_updated;
end;
$$;

create or replace function public.delete_channel_message(p_message_id uuid)
returns public.messages
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_sender_id uuid;
  v_channel_id uuid;
  v_updated public.messages;
  v_now timestamptz := clock_timestamp();
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select sender_id, channel_id into v_sender_id, v_channel_id
    from public.messages
   where message_id = p_message_id;

  if v_channel_id is null then
    raise exception 'Message not found' using errcode = 'P0002';
  end if;

  if v_sender_id = v_actor then
    if not private.has_channel_permission(v_actor, v_channel_id, 'delete_own_messages') then
      raise exception 'CHAT_PERMISSION_DENIED: You do not have permission to delete your own messages'
        using errcode = '42501';
    end if;
  else
    if not private.has_channel_permission(v_actor, v_channel_id, 'delete_any_message') then
      raise exception 'CHAT_PERMISSION_DENIED: Moderation permission required to delete messages'
        using errcode = '42501';
    end if;
  end if;

  update public.messages
     set deleted_at = v_now,
         deleted_by = v_actor,
         version = version + 1,
         updated_at = v_now
   where message_id = p_message_id
   returning * into v_updated;

  insert into public.chat_changes (
    channel_id,
    entity_type,
    entity_id,
    operation,
    actor_id,
    payload
  ) values (
    v_channel_id,
    'message',
    p_message_id::text,
    'delete',
    v_actor,
    jsonb_build_object(
      'message_id', p_message_id,
      'version', v_updated.version,
      'deleted_at', v_now
    )
  );

  return v_updated;
end;
$$;

create or replace function public.set_message_reaction(
  p_message_id uuid,
  p_reaction text,
  p_selected boolean
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_channel_id uuid;
  v_reactions_enabled boolean;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select channel_id into v_channel_id
    from public.messages
   where message_id = p_message_id;

  if v_channel_id is null then
    raise exception 'Message not found' using errcode = 'P0002';
  end if;

  select reactions_enabled into v_reactions_enabled
    from public.channel_policies
   where channel_id = v_channel_id;

  if not coalesce(v_reactions_enabled, true) then
    raise exception 'CHAT_REACTIONS_DISABLED: Reactions are disabled in this channel'
      using errcode = '42501';
  end if;

  if not private.has_channel_permission(v_actor, v_channel_id, 'add_reactions') then
    raise exception 'Permission denied: add_reactions not permitted' using errcode = '42501';
  end if;

  if p_selected then
    insert into public.message_reactions (message_id, user_id, reaction, updated_at, removed_at)
    values (p_message_id, v_actor, p_reaction, now(), null)
    on conflict (message_id, user_id, reaction)
    do update set removed_at = null, updated_at = now();

    insert into public.chat_changes (
      channel_id, entity_type, entity_id, operation, actor_id, payload
    ) values (
      v_channel_id, 'reaction', p_message_id::text, 'insert', v_actor,
      jsonb_build_object('message_id', p_message_id, 'reaction', p_reaction, 'user_id', v_actor)
    );
  else
    update public.message_reactions
       set removed_at = now(), updated_at = now()
     where message_id = p_message_id
       and user_id = v_actor
       and reaction = p_reaction
       and removed_at is null;

    insert into public.chat_changes (
      channel_id, entity_type, entity_id, operation, actor_id, payload
    ) values (
      v_channel_id, 'reaction', p_message_id::text, 'delete', v_actor,
      jsonb_build_object('message_id', p_message_id, 'reaction', p_reaction, 'user_id', v_actor)
    );
  end if;
end;
$$;

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

  select last_read_message_seq into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor;

  if v_current_horizon is null then
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
  end if;
end;
$$;

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

  select last_delivered_message_seq into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor;

  if v_current_horizon is null then
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
  end if;
end;
$$;

create or replace function public.accept_channel_invite(p_channel_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_current_status public.chat_member_status;
  v_now timestamptz := clock_timestamp();
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select status into v_current_status
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor;

  if v_current_status is null then
    raise exception 'CHAT_NOT_MEMBER: No invite exists for this user' using errcode = 'P0001';
  end if;

  if v_current_status <> 'pending' then
    raise exception 'CHAT_INVITE_NOT_PENDING: Membership is already %', v_current_status
      using errcode = 'P0001';
  end if;

  update public.channel_members
     set status = 'active',
         responded_at = v_now,
         joined_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  insert into public.channel_membership_periods (channel_id, user_id, joined_at)
  values (p_channel_id, v_actor, v_now);
end;
$$;

create or replace function public.decline_channel_invite(p_channel_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_current_status public.chat_member_status;
  v_now timestamptz := clock_timestamp();
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select status into v_current_status
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor;

  if v_current_status is null then
    raise exception 'CHAT_NOT_MEMBER: No invite exists for this user' using errcode = 'P0001';
  end if;

  if v_current_status <> 'pending' then
    raise exception 'CHAT_INVITE_NOT_PENDING: Membership is already %', v_current_status
      using errcode = 'P0001';
  end if;

  update public.channel_members
     set status = 'declined',
         responded_at = v_now,
         left_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;
end;
$$;

create or replace function public.leave_channel(p_channel_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_context_type public.chat_channel_context;
  v_now timestamptz := clock_timestamp();
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select context_type into v_context_type
    from public.chat_channels
   where channel_id = p_channel_id;

  if v_context_type in ('team', 'match', 'tournament') then
    raise exception 'CHAT_CANNOT_LEAVE_ENTITY_CHANNEL: Cannot leave % chat directly. Manage notification preferences or entity membership instead.', v_context_type
      using errcode = 'P0001';
  end if;

  update public.channel_members
     set status = 'left',
         left_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  update public.channel_membership_periods
     set left_at = v_now,
         end_reason = 'user_left'
   where channel_id = p_channel_id
     and user_id = v_actor
     and left_at is null;
end;
$$;

create or replace function public.list_my_chats()
returns table (
  channel_id                 uuid,
  channel_key                text,
  kind                       public.chat_channel_kind,
  context_type               public.chat_channel_context,
  title                      text,
  avatar_url                 text,
  team_id                    uuid,
  match_id                   uuid,
  tournament_id              uuid,
  team_name                  text,
  team_logo_url              text,
  team_logo_monogram         text,
  team_primary_color         text,
  is_accepted                boolean,
  unread_count               bigint,
  last_message_seq           bigint,
  last_message_body          text,
  last_message_at            timestamptz,
  last_message_sender_id     uuid,
  last_message_from_me       boolean,
  last_read_message_seq      bigint,
  last_read_at               timestamptz,
  last_delivered_message_seq bigint,
  last_delivered_at          timestamptz,
  is_pinned                  boolean,
  pinned_at                  timestamptz,
  is_archived                boolean,
  archived_at                timestamptz,
  is_muted                   boolean,
  notifications_muted_until  timestamptz,
  dm_other_user_id           uuid,
  dm_other_user_name         text,
  dm_other_user_username     text,
  dm_other_user_avatar_url   text,
  they_follow_you            boolean,
  you_follow                 boolean,
  created_at                 timestamptz,
  updated_at                 timestamptz
)
language sql
security definer
stable
set search_path = public, auth, pg_temp
as $$
  select
    c.channel_id,
    c.channel_key,
    c.kind,
    c.context_type,
    case
      when c.kind = 'direct' then dm_user.full_name
      when c.context_type = 'team' then t.team_name
      when c.context_type = 'tournament' then tourn.title
      else c.title
    end as title,
    case
      when c.kind = 'direct' then dm_user.avatar_url
      when c.context_type = 'team' then t.logo_url
      when c.context_type = 'tournament' then tourn.logo_url
      else c.avatar_url
    end as avatar_url,
    c.team_id,
    c.match_id,
    c.tournament_id,
    t.team_name,
    t.logo_url as team_logo_url,
    t.logo_monogram as team_logo_monogram,
    t.primary_color as team_primary_color,
    (m.status = 'active') as is_accepted,
    coalesce((
      select count(*)
      from public.messages msg
      where msg.channel_id = c.channel_id
        and msg.message_seq > coalesce(m.last_read_message_seq, 0)
        and msg.sender_id <> (select auth.uid())
        and msg.counts_as_unread = true
        and msg.deleted_at is null
    ), 0) as unread_count,
    c.last_message_seq,
    last_msg.body as last_message_body,
    c.last_message_at,
    last_msg.sender_id as last_message_sender_id,
    (last_msg.sender_id = (select auth.uid())) as last_message_from_me,
    m.last_read_message_seq,
    m.last_read_at,
    m.last_delivered_message_seq,
    m.last_delivered_at,
    (m.pinned_at is not null) as is_pinned,
    m.pinned_at,
    (m.archived_at is not null) as is_archived,
    m.archived_at,
    (m.notifications_muted_until is not null and m.notifications_muted_until > now()) as is_muted,
    m.notifications_muted_until,
    dm_user.user_id as dm_other_user_id,
    dm_user.full_name as dm_other_user_name,
    dm_user.username as dm_other_user_username,
    dm_user.avatar_url as dm_other_user_avatar_url,
    coalesce(tf.they_follow, false) as they_follow_you,
    coalesce(yf.you_follow, false) as you_follow,
    c.created_at,
    c.updated_at
  from public.channel_members m
  join public.chat_channels c on c.channel_id = m.channel_id
  left join public.teams t on t.team_id = c.team_id
  left join public.tournaments tourn on tourn.tournament_id = c.tournament_id
  left join lateral (
    select cm_other.user_id
    from public.channel_members cm_other
    where cm_other.channel_id = c.channel_id
      and cm_other.user_id <> (select auth.uid())
      and c.kind = 'direct'
    limit 1
  ) dm_other on true
  left join public.profiles dm_user on dm_user.user_id = dm_other.user_id
  left join lateral (
    select exists (
      select 1 from public.follows f
      where f.follower_id = dm_other.user_id
        and f.following_id = (select auth.uid())
    ) as they_follow
  ) tf on true
  left join lateral (
    select exists (
      select 1 from public.follows f
      where f.follower_id = (select auth.uid())
        and f.following_id = dm_other.user_id
    ) as you_follow
  ) yf on true
  left join lateral (
    select msg.body, msg.sender_id
    from public.messages msg
    where msg.channel_id = c.channel_id
      and msg.deleted_at is null
    order by msg.message_seq desc
    limit 1
  ) last_msg on true
  where m.user_id = (select auth.uid())
    and m.status in ('active', 'pending')
  order by
    (m.pinned_at is not null) desc,
    coalesce(c.last_message_at, c.created_at) desc;
$$;

-- -----------------------------------------------------------------------------
-- 3. RLS Policies
-- -----------------------------------------------------------------------------
create policy "chat_channels_read_members_or_public"
  on public.chat_channels for select
  to authenticated
  using (visibility = 'public' or public.is_chat_member(channel_id));

create policy "channel_members_read_self_or_channel"
  on public.channel_members for select
  to authenticated
  using (user_id = (select auth.uid()) or public.is_chat_member(channel_id));

create policy "channel_policies_read_members"
  on public.channel_policies for select
  to authenticated
  using (
    public.is_chat_member(channel_id)
    or exists (
      select 1 from public.chat_channels cc
       where cc.channel_id = channel_policies.channel_id
         and cc.visibility = 'public'
    )
  );

create policy "channel_role_permissions_read_all"
  on public.channel_role_permissions for select
  to authenticated
  using (true);

create policy "channel_member_restrictions_read_members"
  on public.channel_member_restrictions for select
  to authenticated
  using (user_id = (select auth.uid()) or public.is_chat_member(channel_id));

create policy "channel_membership_periods_read_members"
  on public.channel_membership_periods for select
  to authenticated
  using (user_id = (select auth.uid()) or public.is_chat_member(channel_id));

create policy "messages_read_for_members"
  on public.messages for select
  to authenticated
  using (public.is_chat_member(channel_id));

create policy "message_attachments_read_for_members"
  on public.message_attachments for select
  to authenticated
  using (
    exists (
      select 1 from public.messages m
       where m.message_id = message_attachments.message_id
         and public.is_chat_member(m.channel_id)
    )
  );

create policy "message_reactions_read_for_members"
  on public.message_reactions for select
  to authenticated
  using (
    exists (
      select 1 from public.messages m
       where m.message_id = message_reactions.message_id
         and public.is_chat_member(m.channel_id)
    )
  );

create policy "message_user_state_read_self"
  on public.message_user_state for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "message_user_state_write_self"
  on public.message_user_state for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "channel_receipt_events_read_members"
  on public.channel_receipt_events for select
  to authenticated
  using (public.is_chat_member(channel_id));

create policy "chat_changes_read_members"
  on public.chat_changes for select
  to authenticated
  using (public.is_chat_member(channel_id));
