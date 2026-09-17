-- =============================================================================
-- 20260917213000 · Fix Channel Membership Period Single Writer
-- =============================================================================
-- Establishes trg_sync_channel_membership_period as the single authoritative
-- writer for public.channel_membership_periods.
-- Removes redundant manual inserts and updates in accept_channel_invite(),
-- create_group_channel(), and leave_channel() to prevent unique constraint
-- violations (idx_channel_membership_period_active).
-- =============================================================================

-- 1. accept_channel_invite
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

  -- Note: trg_sync_channel_membership_period automatically inserts
  -- into public.channel_membership_periods upon transitioning to 'active'.
end;
$$;

revoke all on function public.accept_channel_invite(uuid) from public;
grant execute on function public.accept_channel_invite(uuid) to authenticated;

-- 2. create_group_channel
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

  -- Note: trg_sync_channel_membership_period automatically inserts
  -- into public.channel_membership_periods for the active owner.

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
        ) on conflict (channel_id, user_id) do nothing;
      end if;
    end loop;
  end if;

  return v_channel_id;
end;
$$;

revoke all on function public.create_group_channel(text, text, text, uuid[]) from public;
grant execute on function public.create_group_channel(text, text, text, uuid[]) to authenticated;

-- 3. leave_channel
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

  -- Note: trg_sync_channel_membership_period automatically closes the active
  -- period in public.channel_membership_periods upon transitioning to 'left'.
end;
$$;

revoke all on function public.leave_channel(uuid) from public;
grant execute on function public.leave_channel(uuid) to authenticated;
