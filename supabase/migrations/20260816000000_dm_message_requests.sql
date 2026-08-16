-- =============================================================================
-- 20260816000000_dm_message_requests.sql — DM Message Requests Subsystem
-- =============================================================================
-- Rules:
-- 1. Mutual Followers: Standard direct messaging, always accepted.
-- 2. Non-Follower / One-Way:
--    - Sender can send an initial message (Message Request).
--    - Recipient sees it in Message Requests tab.
--    - Recipient can Accept or Decline.
--    - While pending, sender is limited to 1 message until accepted.
-- =============================================================================

-- 1) Add acceptance columns to dm_channels
alter table public.dm_channels
  add column if not exists accepted_at timestamptz,
  add column if not exists accepted_by uuid references public.profiles(user_id);

-- 2) RPC: accept_dm_request
create or replace function public.accept_dm_request(p_chat_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
begin
  if v_actor is null then
    raise exception 'Unauthenticated';
  end if;

  -- Ensure actor is a participant in this DM
  if not exists (
    select 1 from public.dm_channels
     where chat_id = p_chat_id
       and (user_a = v_actor or user_b = v_actor)
  ) then
    raise exception 'Not a participant in this DM chat';
  end if;

  -- Mark accepted in dm_channels
  update public.dm_channels
     set accepted_at = v_now,
         accepted_by = v_actor
   where chat_id = p_chat_id
     and accepted_at is null;

  -- Re-activate membership if previously left, and update last_read_at
  update public.chat_members
     set left_at = null,
         last_read_at = v_now
   where chat_id = p_chat_id
     and user_id = v_actor;

  return v_now;
end;
$$;

revoke all on function public.accept_dm_request(uuid) from public;
grant execute on function public.accept_dm_request(uuid) to authenticated;

-- 3) RPC: decline_dm_request
create or replace function public.decline_dm_request(p_chat_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'Unauthenticated';
  end if;

  -- Ensure actor is a participant in this DM
  if not exists (
    select 1 from public.dm_channels
     where chat_id = p_chat_id
       and (user_a = v_actor or user_b = v_actor)
  ) then
    raise exception 'Not a participant in this DM chat';
  end if;

  -- Soft remove from chat for recipient
  update public.chat_members
     set left_at = now()
   where chat_id = p_chat_id
     and user_id = v_actor;

  return true;
end;
$$;

revoke all on function public.decline_dm_request(uuid) from public;
grant execute on function public.decline_dm_request(uuid) to authenticated;

-- 4) Single-message restriction trigger for pending non-follower requests
create or replace function public.guard_dm_message_request_limit()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_type public.chat_type;
  v_other_user uuid;
  v_accepted_at timestamptz;
  v_they_follow boolean;
  v_prior_count int;
begin
  select type into v_chat_type from public.chats where chat_id = new.chat_id;
  if v_chat_type <> 'dm' then
    return new;
  end if;

  -- Find other participant in DM
  select
    case when user_a = new.sender_id then user_b else user_a end,
    accepted_at
  into v_other_user, v_accepted_at
  from public.dm_channels
  where chat_id = new.chat_id;

  if v_other_user is null then
    return new;
  end if;

  -- If already accepted, no restriction
  if v_accepted_at is not null then
    return new;
  end if;

  -- Check if other user follows sender
  select exists (
    select 1 from public.follows
     where follower_id = v_other_user
       and target_type = 'user'
       and target_id = new.sender_id
  ) into v_they_follow;

  -- If they follow the sender, auto-accepted / no restriction
  if v_they_follow then
    return new;
  end if;

  -- Count prior non-deleted messages from this sender in this chat
  select count(*) into v_prior_count
    from public.messages
   where chat_id = new.chat_id
     and sender_id = new.sender_id
     and deleted_at is null;

  if v_prior_count >= 1 then
    raise exception 'Cannot send more messages until the recipient accepts your message request';
  end if;

  return new;
end;
$$;

drop trigger if exists messages_before_insert_dm_request_guard on public.messages;
create trigger messages_before_insert_dm_request_guard
  before insert on public.messages
  for each row execute function public.guard_dm_message_request_limit();

-- 5) Update list_my_chats to return is_accepted
drop function if exists public.list_my_chats();

create or replace function public.list_my_chats()
returns table (
  chat_id                  uuid,
  type                     public.chat_type,
  team_id                  uuid,
  last_message_at          timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz,
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
  is_accepted              boolean
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
    c.chat_id,
    c.type,
    c.team_id,
    c.last_message_at,
    c.created_at,
    c.updated_at,
    t.team_name,
    t.logo_url as team_logo_url,
    t.logo_monogram as team_logo_monogram,
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
      select count(*)::int from (
        select 1 from public.messages m
         where m.chat_id = c.chat_id
           and m.created_at > coalesce(cm.last_read_at, 'epoch'::timestamptz)
           and m.sender_id is distinct from v_actor
           and m.deleted_at is null
         limit 100
      ) capped
    ) as unread_count,
    case
      when c.type <> 'dm' then true
      when dmc.accepted_at is not null then true
      when exists (
        select 1 from public.follows
         where follower_id = v_actor
           and target_type = 'user'
           and target_id = other_p.user_id
      ) then true
      else false
    end as is_accepted
  from public.chats c
  join public.chat_members cm
    on cm.chat_id = c.chat_id
   and cm.user_id = v_actor
   and cm.left_at is null
  left join public.dm_channels dmc on dmc.chat_id = c.chat_id
  left join public.teams t on t.team_id = c.team_id
  -- For DM chats, join the other participant's profile
  left join lateral (
    select p.user_id, p.display_name, p.username, p.profile_photo_url
      from public.chat_members other_cm
      join public.profiles p on p.user_id = other_cm.user_id
     where other_cm.chat_id = c.chat_id
       and other_cm.user_id <> v_actor
     limit 1
  ) other_p on c.type = 'dm'
  left join lateral (
    select m.body, m.sender_id
      from public.messages m
     where m.chat_id = c.chat_id
       and m.deleted_at is null
     order by m.created_at desc
     limit 1
  ) lm on true
  order by c.last_message_at desc nulls last;
end;
$$;

revoke all on function public.list_my_chats() from public;
grant execute on function public.list_my_chats() to authenticated;
