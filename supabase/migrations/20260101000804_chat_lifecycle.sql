-- =============================================================================
-- 0804 · chat_lifecycle — lifecycle triggers, authorization guards, and RPCs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Guard: Direct Channel Participant Limit (Max 2 Members)
-- -----------------------------------------------------------------------------
create or replace function public.guard_direct_channel_participants()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_kind public.chat_channel_kind;
  v_count integer;
begin
  select kind into v_kind
    from public.chat_channels
   where channel_id = new.channel_id;

  if v_kind = 'direct' then
    select count(*) into v_count
      from public.channel_members
     where channel_id = new.channel_id
       and user_id <> new.user_id;

    if v_count >= 2 then
      raise exception 'A direct message channel cannot have more than 2 participants'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_direct_channel_participants on public.channel_members;
create trigger trg_guard_direct_channel_participants
  before insert on public.channel_members
  for each row execute function public.guard_direct_channel_participants();

-- -----------------------------------------------------------------------------
-- 2. Guard: DM Request Limit (1 Message while Pending)
-- -----------------------------------------------------------------------------
create or replace function public.guard_dm_request_limit()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_kind public.chat_channel_kind;
  v_other_status public.chat_member_status;
  v_other_invited_at timestamptz;
  v_prior_count integer;
begin
  select kind into v_kind
    from public.chat_channels
   where channel_id = new.channel_id;

  if v_kind = 'direct' then
    select status, coalesce(invited_at, created_at)
      into v_other_status, v_other_invited_at
      from public.channel_members
     where channel_id = new.channel_id
       and user_id <> new.sender_id
     limit 1;

    if v_other_status = 'pending' then
      select count(*) into v_prior_count
        from public.messages
       where channel_id = new.channel_id
         and sender_id = new.sender_id
         and created_at >= v_other_invited_at
         and deleted_at is null;

      if v_prior_count >= 1 then
        raise exception 'Cannot send more messages until the recipient accepts your message request'
          using errcode = '42501';
      end if;
    elsif v_other_status in ('declined', 'banned', 'removed') then
      raise exception 'Cannot send messages to this recipient'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_dm_request_limit on public.messages;
create trigger trg_guard_dm_request_limit
  before insert on public.messages
  for each row execute function public.guard_dm_request_limit();

-- -----------------------------------------------------------------------------
-- 3. RPC: get_or_create_direct_channel
-- -----------------------------------------------------------------------------
create or replace function public.get_or_create_direct_channel(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_low uuid;
  v_high uuid;
  v_key text;
  v_channel_id uuid;
  v_target_follows_actor boolean := false;
  v_target_status public.chat_member_status;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  if p_target_user_id is null or p_target_user_id = v_actor then
    raise exception 'Invalid target user for direct message' using errcode = '22023';
  end if;

  -- Block check
  if exists (
    select 1 from public.user_blocks
     where (blocker_id = v_actor and blocked_id = p_target_user_id)
        or (blocker_id = p_target_user_id and blocked_id = v_actor)
  ) then
    raise exception 'Direct messaging is unavailable between these accounts' using errcode = '42501';
  end if;

  -- Canonical key: dm:<lower>:<higher>
  if v_actor < p_target_user_id then
    v_low := v_actor;
    v_high := p_target_user_id;
  else
    v_low := p_target_user_id;
    v_high := v_actor;
  end if;

  v_key := 'dm:' || v_low::text || ':' || v_high::text;

  -- Upsert canonical channel row
  insert into public.chat_channels (
    channel_key,
    kind,
    context_type,
    visibility,
    created_by
  )
  values (
    v_key,
    'direct',
    'none',
    'private',
    v_actor
  )
  on conflict (channel_key) do update
    set updated_at = now()
  returning channel_id into v_channel_id;

  -- Check if target follows actor (mutual/established relationship)
  select exists (
    select 1 from public.follows
     where follower_id = p_target_user_id
       and target_type = 'user'
       and target_id = v_actor
  ) into v_target_follows_actor;

  if v_target_follows_actor then
    v_target_status := 'active';
  else
    v_target_status := 'pending';
  end if;

  -- Insert/update actor membership
  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    joined_at
  )
  values (
    v_channel_id,
    v_actor,
    'member',
    'active',
    now()
  )
  on conflict (channel_id, user_id) do update
    set status = 'active',
        left_at = null,
        updated_at = now();

  -- Insert/update target membership
  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    invited_by,
    invited_at
  )
  values (
    v_channel_id,
    p_target_user_id,
    'member',
    v_target_status,
    v_actor,
    now()
  )
  on conflict (channel_id, user_id) do update
    set updated_at = now()
    where channel_members.status <> 'declined';

  -- Ensure channel policy exists
  insert into public.channel_policies (channel_id)
  values (v_channel_id)
  on conflict (channel_id) do nothing;

  return v_channel_id;
end;
$$;

revoke all on function public.get_or_create_direct_channel(uuid) from public;
grant execute on function public.get_or_create_direct_channel(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. RPC: create_group_channel
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
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'Group title is required' using errcode = '22023';
  end if;

  v_channel_id := gen_random_uuid();

  insert into public.chat_channels (
    channel_id,
    channel_key,
    kind,
    context_type,
    visibility,
    title,
    description,
    avatar_url,
    created_by
  )
  values (
    v_channel_id,
    'group:' || v_channel_id::text,
    'group',
    'none',
    'private',
    trim(p_title),
    p_description,
    p_avatar_url,
    v_actor
  );

  -- Creator is owner
  insert into public.channel_members (
    channel_id,
    user_id,
    role,
    status,
    joined_at
  )
  values (
    v_channel_id,
    v_actor,
    'owner',
    'active',
    now()
  );

  -- Add initial members
  if p_initial_member_ids is not null then
    foreach v_member_id in array p_initial_member_ids loop
      if v_member_id <> v_actor then
        insert into public.channel_members (
          channel_id,
          user_id,
          role,
          status,
          invited_by,
          invited_at,
          joined_at
        )
        values (
          v_channel_id,
          v_member_id,
          'member',
          'active',
          v_actor,
          now(),
          now()
        )
        on conflict (channel_id, user_id) do nothing;
      end if;
    end loop;
  end if;

  -- Default policy
  insert into public.channel_policies (channel_id)
  values (v_channel_id)
  on conflict (channel_id) do nothing;

  return v_channel_id;
end;
$$;

revoke all on function public.create_group_channel(text, text, text, uuid[]) from public;
grant execute on function public.create_group_channel(text, text, text, uuid[]) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. RPC: send_channel_message (Idempotent by client message_id)
-- -----------------------------------------------------------------------------
create or replace function public.send_channel_message(
  p_message_id uuid,
  p_channel_id uuid,
  p_message_type public.chat_message_type default 'text',
  p_body text default null,
  p_reply_to_message_id uuid default null,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_existing record;
  v_new_msg record;
  v_slow_mode integer;
  v_last_sent timestamptz;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  if p_message_id is null or p_channel_id is null then
    raise exception 'message_id and channel_id are required' using errcode = '22023';
  end if;

  -- 1. Idempotent retry check: if message_id exists
  select m.* into v_existing
    from public.messages m
   where m.message_id = p_message_id;

  if v_existing.message_id is not null then
    if v_existing.sender_id = v_actor and v_existing.channel_id = p_channel_id then
      return to_jsonb(v_existing);
    else
      raise exception 'Message ID collision with different sender or channel' using errcode = '23505';
    end if;
  end if;

  -- 2. Authorization check
  if not private.has_channel_permission(v_actor, p_channel_id, 'send_messages') then
    raise exception 'Permission denied: send_messages not permitted in this channel' using errcode = '42501';
  end if;

  -- 3. Slow mode enforcement
  select slow_mode_seconds into v_slow_mode
    from public.channel_policies
   where channel_id = p_channel_id;

  if v_slow_mode is not null and v_slow_mode > 0 then
    select created_at into v_last_sent
      from public.messages
     where channel_id = p_channel_id
       and sender_id = v_actor
     order by created_at desc
     limit 1;

    if v_last_sent is not null and (now() - v_last_sent) < (v_slow_mode * interval '1 second') then
      raise exception 'Slow mode active. Please wait % seconds before sending again',
        ceil(extract(epoch from (v_last_sent + (v_slow_mode * interval '1 second') - now())))
        using errcode = '42501';
    end if;
  end if;

  -- 4. Message content validation
  if p_message_type = 'text' and (p_body is null or length(trim(p_body)) = 0) then
    raise exception 'Text message must have a non-empty body' using errcode = '22023';
  end if;

  -- 5. Insert authoritative message
  insert into public.messages (
    message_id,
    channel_id,
    sender_id,
    message_type,
    body,
    payload,
    reply_to_message_id,
    version,
    counts_as_unread,
    created_at,
    updated_at
  )
  values (
    p_message_id,
    p_channel_id,
    v_actor,
    p_message_type,
    p_body,
    coalesce(p_payload, '{}'::jsonb),
    p_reply_to_message_id,
    1,
    true,
    now(),
    now()
  )
  returning * into v_new_msg;

  -- 6. Atomically update channel latest message metadata
  update public.chat_channels
     set last_message_seq = v_new_msg.message_seq,
         last_message_at  = v_new_msg.created_at,
         updated_at       = now()
   where channel_id = p_channel_id;

  -- 7. Atomically advance sender's own horizons
  update public.channel_members
     set last_read_message_seq      = greatest(coalesce(last_read_message_seq, 0), v_new_msg.message_seq),
         last_read_at               = v_new_msg.created_at,
         last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), v_new_msg.message_seq),
         last_delivered_at          = v_new_msg.created_at,
         updated_at                 = now()
   where channel_id = p_channel_id
     and user_id = v_actor;

  return to_jsonb(v_new_msg);
end;
$$;

revoke all on function public.send_channel_message(uuid, uuid, public.chat_message_type, text, uuid, jsonb) from public;
grant execute on function public.send_channel_message(uuid, uuid, public.chat_message_type, text, uuid, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. RPC: edit_channel_message (Optimistic Concurrency)
-- -----------------------------------------------------------------------------
create or replace function public.edit_channel_message(
  p_message_id uuid,
  p_expected_version integer,
  p_body text,
  p_payload jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_msg record;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  select * into v_msg
    from public.messages
   where message_id = p_message_id;

  if v_msg.message_id is null then
    raise exception 'Message not found' using errcode = 'P0002';
  end if;

  if v_msg.sender_id <> v_actor then
    raise exception 'Only the message author can edit this message' using errcode = '42501';
  end if;

  if v_msg.deleted_at is not null then
    raise exception 'Cannot edit a deleted message' using errcode = '22023';
  end if;

  if v_msg.version <> p_expected_version then
    raise exception 'Version conflict: message was modified elsewhere' using errcode = '40001';
  end if;

  update public.messages
     set body       = coalesce(p_body, body),
         payload    = coalesce(p_payload, payload),
         version    = version + 1,
         edited_at  = now(),
         updated_at = now()
   where message_id = p_message_id
  returning * into v_msg;

  return to_jsonb(v_msg);
end;
$$;

revoke all on function public.edit_channel_message(uuid, integer, text, jsonb) from public;
grant execute on function public.edit_channel_message(uuid, integer, text, jsonb) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. RPC: delete_channel_message (Soft Tombstone)
-- -----------------------------------------------------------------------------
create or replace function public.delete_channel_message(p_message_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_msg record;
  v_can_delete boolean := false;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  select * into v_msg
    from public.messages
   where message_id = p_message_id;

  if v_msg.message_id is null then
    return true; -- Idempotent
  end if;

  if v_msg.sender_id = v_actor then
    v_can_delete := true;
  else
    v_can_delete := private.has_channel_permission(v_actor, v_msg.channel_id, 'delete_any_message');
  end if;

  if not v_can_delete then
    raise exception 'Permission denied to delete message' using errcode = '42501';
  end if;

  update public.messages
     set deleted_at = now(),
         deleted_by = v_actor,
         updated_at = now()
   where message_id = p_message_id;

  return true;
end;
$$;

revoke all on function public.delete_channel_message(uuid) from public;
grant execute on function public.delete_channel_message(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. RPC: set_message_reaction (Idempotent Desired-State)
-- -----------------------------------------------------------------------------
create or replace function public.set_message_reaction(
  p_message_id uuid,
  p_reaction text,
  p_selected boolean
)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_channel_id uuid;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  select channel_id into v_channel_id
    from public.messages
   where message_id = p_message_id;

  if v_channel_id is null then
    raise exception 'Message not found' using errcode = 'P0002';
  end if;

  if not private.has_channel_permission(v_actor, v_channel_id, 'add_reactions') then
    raise exception 'Permission denied: add_reactions not allowed' using errcode = '42501';
  end if;

  if p_selected then
    insert into public.message_reactions (
      message_id,
      user_id,
      reaction,
      created_at,
      updated_at,
      removed_at
    )
    values (
      p_message_id,
      v_actor,
      p_reaction,
      now(),
      now(),
      null
    )
    on conflict (message_id, user_id, reaction) do update
      set removed_at = null,
          updated_at = now();
  else
    update public.message_reactions
       set removed_at = now(),
           updated_at = now()
     where message_id = p_message_id
       and user_id = v_actor
       and reaction = p_reaction;
  end if;

  return true;
end;
$$;

revoke all on function public.set_message_reaction(uuid, text, boolean) from public;
grant execute on function public.set_message_reaction(uuid, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. RPC: mark_channel_read (Monotonic GREATEST)
-- -----------------------------------------------------------------------------
create or replace function public.mark_channel_read(
  p_channel_id uuid,
  p_through_message_seq bigint
)
returns bigint
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_new_seq bigint;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  update public.channel_members
     set last_read_message_seq = greatest(coalesce(last_read_message_seq, 0), p_through_message_seq),
         last_read_at          = now(),
         updated_at            = now()
   where channel_id = p_channel_id
     and user_id = v_actor
  returning last_read_message_seq into v_new_seq;

  return coalesce(v_new_seq, p_through_message_seq);
end;
$$;

revoke all on function public.mark_channel_read(uuid, bigint) from public;
grant execute on function public.mark_channel_read(uuid, bigint) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. RPC: mark_channel_delivered (Monotonic GREATEST)
-- -----------------------------------------------------------------------------
create or replace function public.mark_channel_delivered(
  p_channel_id uuid,
  p_through_message_seq bigint
)
returns bigint
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_new_seq bigint;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  update public.channel_members
     set last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), p_through_message_seq),
         last_delivered_at          = now(),
         updated_at                 = now()
   where channel_id = p_channel_id
     and user_id = v_actor
  returning last_delivered_message_seq into v_new_seq;

  return coalesce(v_new_seq, p_through_message_seq);
end;
$$;

revoke all on function public.mark_channel_delivered(uuid, bigint) from public;
grant execute on function public.mark_channel_delivered(uuid, bigint) to authenticated;

-- -----------------------------------------------------------------------------
-- 11. RPC: accept_channel_invite & decline_channel_invite
-- -----------------------------------------------------------------------------
create or replace function public.accept_channel_invite(p_channel_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  update public.channel_members
     set status       = 'active',
         responded_at = now(),
         joined_at    = coalesce(joined_at, now()),
         left_at      = null,
         updated_at   = now()
   where channel_id = p_channel_id
     and user_id = v_actor;

  return true;
end;
$$;

revoke all on function public.accept_channel_invite(uuid) from public;
grant execute on function public.accept_channel_invite(uuid) to authenticated;

create or replace function public.decline_channel_invite(p_channel_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  update public.channel_members
     set status       = 'declined',
         responded_at = now(),
         updated_at   = now()
   where channel_id = p_channel_id
     and user_id = v_actor;

  return true;
end;
$$;

revoke all on function public.decline_channel_invite(uuid) from public;
grant execute on function public.decline_channel_invite(uuid) to authenticated;

create or replace function public.leave_channel(p_channel_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  update public.channel_members
     set status     = 'left',
         left_at    = now(),
         updated_at = now()
   where channel_id = p_channel_id
     and user_id = v_actor;

  return true;
end;
$$;

revoke all on function public.leave_channel(uuid) from public;
grant execute on function public.leave_channel(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 12. RPC: list_my_chats (Universal Polymorphic Channel Projection)
-- -----------------------------------------------------------------------------
create or replace function public.list_my_chats()
returns table (
  chat_id                  uuid,
  channel_key              text,
  kind                     public.chat_channel_kind,
  context_type             public.chat_channel_context,
  team_id                  uuid,
  match_id                 uuid,
  last_message_seq         bigint,
  last_message_at          timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz,
  title                    text,
  team_name                text,
  team_logo_url            text,
  team_logo_monogram       text,
  team_primary_color       text,
  dm_other_user_id         uuid,
  dm_other_user_name       text,
  dm_other_user_username   text,
  dm_other_user_avatar_url text,
  you_follow               boolean,
  they_follow_you          boolean,
  last_message_body        text,
  last_message_sender_id   uuid,
  last_message_from_me     boolean,
  unread_count             int,
  is_accepted              boolean,
  is_pinned                boolean,
  is_archived              boolean,
  is_muted                 boolean
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    return;
  end if;

  return query
  select
    cc.channel_id as chat_id,
    cc.channel_key,
    cc.kind,
    cc.context_type,
    cc.team_id,
    cc.match_id,
    cc.last_message_seq,
    cc.last_message_at,
    cc.created_at,
    cc.updated_at,
    -- Title resolution
    case
      when cc.kind = 'direct' then other_p.display_name
      when cc.context_type = 'team' then t.team_name
      when cc.context_type = 'match' then coalesce(mt_a.team_name, 'Team A') || ' vs ' || coalesce(mt_b.team_name, 'Team B')
      else cc.title
    end as title,
    t.team_name,
    t.logo_url as team_logo_url,
    case
      when cc.context_type = 'team' then t.logo_monogram
      when cc.context_type = 'match' then 'VS'
      else null
    end as team_logo_monogram,
    (t.team_colors->>'primary') as team_primary_color,
    other_p.user_id as dm_other_user_id,
    other_p.display_name as dm_other_user_name,
    other_p.username as dm_other_user_username,
    other_p.profile_photo_url as dm_other_user_avatar_url,
    case
      when other_p.user_id is not null then
        exists (
          select 1 from public.follows
           where follower_id = v_actor
             and target_type = 'user'
             and target_id = other_p.user_id
        )
      else false
    end as you_follow,
    case
      when other_p.user_id is not null then
        exists (
          select 1 from public.follows
           where follower_id = other_p.user_id
             and target_type = 'user'
             and target_id = v_actor
        )
      else false
    end as they_follow_you,
    lm.body as last_message_body,
    lm.sender_id as last_message_sender_id,
    (lm.sender_id is not distinct from v_actor)::boolean as last_message_from_me,
    (
      select count(*)::int
        from public.messages m
       where m.channel_id = cc.channel_id
         and m.message_seq > coalesce(cm.last_read_message_seq, 0)
         and m.sender_id is distinct from v_actor
         and m.deleted_at is null
         and m.counts_as_unread = true
    ) as unread_count,
    (cm.status = 'active') as is_accepted,
    (cm.pinned_at is not null) as is_pinned,
    (cm.archived_at is not null) as is_archived,
    (cm.notifications_muted_until is not null and cm.notifications_muted_until > now()) as is_muted
  from public.chat_channels cc
  join public.channel_members cm
    on cm.channel_id = cc.channel_id
   and cm.user_id = v_actor
   and cm.status in ('active', 'pending')
  left join public.teams t on t.team_id = cc.team_id
  left join public.matches m on m.match_id = cc.match_id and cc.context_type = 'match'
  left join public.match_teams mt_a on mt_a.match_id = m.match_id and mt_a.team_side = 'team_a'
  left join public.match_teams mt_b on mt_b.match_id = m.match_id and mt_b.team_side = 'team_b'
  -- Direct message other participant lookup
  left join lateral (
    select p.user_id, p.display_name, p.username, p.profile_photo_url
      from public.channel_members other_cm
      join public.profiles p on p.user_id = other_cm.user_id
     where other_cm.channel_id = cc.channel_id
       and other_cm.user_id <> v_actor
     limit 1
  ) other_p on cc.kind = 'direct'
  -- Latest message lookup
  left join lateral (
    select m2.body, m2.sender_id
      from public.messages m2
     where m2.channel_id = cc.channel_id
       and m2.deleted_at is null
     order by m2.message_seq desc
     limit 1
  ) lm on true
  order by
    (cm.pinned_at is not null) desc,
    cc.last_message_at desc nulls last,
    cc.created_at desc;
end;
$$;

revoke all on function public.list_my_chats() from public;
grant execute on function public.list_my_chats() to authenticated;

-- -----------------------------------------------------------------------------
-- 13. Lifecycle Triggers: Teams and Matches
-- -----------------------------------------------------------------------------
create or replace function public.create_team_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_key text;
begin
  v_key := 'team:' || new.team_id::text || ':main';

  insert into public.chat_channels (
    channel_key,
    kind,
    context_type,
    visibility,
    purpose,
    team_id,
    created_by
  )
  values (
    v_key,
    'group',
    'team',
    'private',
    'main',
    new.team_id,
    new.created_by
  )
  on conflict (team_id, purpose) where team_id is not null and archived_at is null
  do nothing
  returning channel_id into v_channel_id;

  if v_channel_id is null then
    select channel_id into v_channel_id
      from public.chat_channels
     where team_id = new.team_id and purpose = 'main';
  end if;

  if v_channel_id is not null and new.created_by is not null then
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    )
    values (
      v_channel_id,
      new.created_by,
      'admin',
      'active',
      now()
    )
    on conflict (channel_id, user_id) do nothing;

    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists teams_after_insert_create_chat on public.teams;
create trigger teams_after_insert_create_chat
  after insert on public.teams
  for each row execute function public.create_team_chat();

-- Team member chat sync
create or replace function public.sync_team_member_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
begin
  if new.user_id is null then return new; end if;

  select channel_id into v_channel_id
    from public.chat_channels
   where team_id = new.team_id and purpose = 'main';

  if v_channel_id is null then return new; end if;

  if new.status = 'active' then
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    )
    values (
      v_channel_id,
      new.user_id,
      'member',
      'active',
      now()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = now();
  elsif new.status <> 'active' then
    update public.channel_members
       set status     = 'left',
           left_at    = now(),
           updated_at = now()
     where channel_id = v_channel_id
       and user_id = new.user_id;
  end if;

  return new;
end;
$$;

drop trigger if exists team_members_after_insert_add_to_chat on public.team_members;
create trigger team_members_after_insert_add_to_chat
  after insert on public.team_members
  for each row execute function public.sync_team_member_chat();

drop trigger if exists team_members_after_update_sync_chat on public.team_members;
create trigger team_members_after_update_sync_chat
  after update on public.team_members
  for each row execute function public.sync_team_member_chat();

-- Match Chat creation
create or replace function public.create_match_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_key text;
begin
  v_key := 'match:' || new.match_id::text || ':main';

  insert into public.chat_channels (
    channel_key,
    kind,
    context_type,
    visibility,
    purpose,
    match_id,
    created_by
  )
  values (
    v_key,
    'group',
    'match',
    'private',
    'main',
    new.match_id,
    new.created_by
  )
  on conflict (match_id, purpose) where match_id is not null and archived_at is null
  do nothing
  returning channel_id into v_channel_id;

  if v_channel_id is not null then
    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists matches_after_insert_create_chat on public.matches;
create trigger matches_after_insert_create_chat
  after insert on public.matches
  for each row execute function public.create_match_chat();

-- Match player chat sync
create or replace function public.add_match_player_to_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
begin
  if new.user_id is null then return new; end if;

  select channel_id into v_channel_id
    from public.chat_channels
   where match_id = new.match_id and purpose = 'main'
   limit 1;

  if v_channel_id is not null then
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    )
    values (
      v_channel_id,
      new.user_id,
      'member',
      'active',
      now()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = now();
  end if;

  return new;
end;
$$;

drop trigger if exists match_players_after_insert_add_to_chat on public.match_players;
create trigger match_players_after_insert_add_to_chat
  after insert on public.match_players
  for each row execute function public.add_match_player_to_chat();
