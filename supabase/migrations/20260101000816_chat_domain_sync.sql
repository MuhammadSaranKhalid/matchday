-- =============================================================================
-- 0816 · chat_domain_sync — domain entity lifecycle synchronization with chat
-- =============================================================================

-- 1. Sync Channel Membership Periods with Member Lifecycle
create or replace function public.sync_channel_membership_period()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if (tg_op = 'INSERT' and new.status = 'active') or
     (tg_op = 'UPDATE' and old.status <> 'active' and new.status = 'active') then
    insert into public.channel_membership_periods (
      channel_id,
      user_id,
      joined_at
    ) values (
      new.channel_id,
      new.user_id,
      coalesce(new.joined_at, clock_timestamp())
    ) on conflict (channel_id, user_id) where left_at is null do nothing;

  elsif tg_op = 'UPDATE' and old.status = 'active' and new.status <> 'active' then
    update public.channel_membership_periods
       set left_at = coalesce(new.left_at, clock_timestamp()),
           end_reason = 'status_' || new.status
     where channel_id = new.channel_id
       and user_id = new.user_id
       and left_at is null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_channel_membership_period on public.channel_members;
create trigger trg_sync_channel_membership_period
  after insert or update on public.channel_members
  for each row execute function public.sync_channel_membership_period();

-- 2. Sync Chat Channel last_message_seq on Message Insertion
create or replace function public.sync_channel_last_message()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  update public.chat_channels
     set last_message_seq = new.message_seq,
         last_message_at = new.created_at,
         updated_at = clock_timestamp()
   where channel_id = new.channel_id;
  return new;
end;
$$;

drop trigger if exists trg_sync_channel_last_message on public.messages;
create trigger trg_sync_channel_last_message
  after insert on public.messages
  for each row execute function public.sync_channel_last_message();

-- 3. Match Players Lifecycle Sync
create or replace function public.sync_match_player_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_match_id uuid;
  v_user_id uuid;
  v_channel_id uuid;
  v_is_active boolean;
begin
  if tg_op = 'DELETE' then
    v_match_id := old.match_id;
    v_user_id := old.user_id;
    v_is_active := false;
  else
    v_match_id := new.match_id;
    v_user_id := new.user_id;
    v_is_active := (new.status = 'confirmed' or new.status = 'active');
  end if;

  if v_user_id is null or v_match_id is null then
    return coalesce(new, old);
  end if;

  select channel_id into v_channel_id
    from public.chat_channels
   where match_id = v_match_id
     and context_type = 'match'
     and purpose = 'main'
   limit 1;

  if v_channel_id is null then
    return coalesce(new, old);
  end if;

  if v_is_active then
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    ) values (
      v_channel_id,
      v_user_id,
      'member',
      'active',
      clock_timestamp()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = clock_timestamp();
  else
    update public.channel_members
       set status = 'left',
           left_at = clock_timestamp(),
           updated_at = clock_timestamp()
     where channel_id = v_channel_id
       and user_id = v_user_id
       and status = 'active';
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists match_players_after_insert_add_to_chat on public.match_players;
drop trigger if exists trg_sync_match_player_chat on public.match_players;
create trigger trg_sync_match_player_chat
  after insert or update or delete on public.match_players
  for each row execute function public.sync_match_player_chat();

-- 4. Team Members Lifecycle Sync
create or replace function public.sync_team_member_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_user_id uuid;
  v_is_active boolean;
begin
  v_user_id := coalesce(new.user_id, old.user_id);
  if v_user_id is null then
    return coalesce(new, old);
  end if;

  if tg_op = 'DELETE' then
    v_is_active := false;
  else
    v_is_active := (new.status = 'active');
  end if;

  select channel_id into v_channel_id
    from public.chat_channels
   where team_id = coalesce(new.team_id, old.team_id)
     and context_type = 'team'
     and purpose = 'main'
   limit 1;

  if v_channel_id is null then
    return coalesce(new, old);
  end if;

  if v_is_active then
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    ) values (
      v_channel_id,
      v_user_id,
      'member',
      'active',
      clock_timestamp()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = clock_timestamp();
  else
    update public.channel_members
       set status = 'left',
           left_at = clock_timestamp(),
           updated_at = clock_timestamp()
     where channel_id = v_channel_id
       and user_id = v_user_id
       and status = 'active';
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_team_member_chat on public.team_members;
create trigger trg_sync_team_member_chat
  after insert or update on public.team_members
  for each row execute function public.sync_team_member_chat();

-- 5. Tournament Teams Lifecycle Sync
create or replace function public.sync_tournament_team_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_member record;
begin
  if new.status <> 'registered' and new.status <> 'confirmed' and new.status <> 'active' then
    return new;
  end if;

  select channel_id into v_channel_id
    from public.chat_channels
   where tournament_id = new.tournament_id
     and context_type = 'tournament'
     and purpose = 'main'
   limit 1;

  if v_channel_id is null then
    return new;
  end if;

  for v_member in
    select user_id
      from public.team_members
     where team_id = new.team_id
       and status = 'active'
       and user_id is not null
  loop
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    ) values (
      v_channel_id,
      v_member.user_id,
      'member',
      'active',
      clock_timestamp()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = clock_timestamp();
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_sync_tournament_team_chat on public.tournament_teams;
create trigger trg_sync_tournament_team_chat
  after insert or update on public.tournament_teams
  for each row execute function public.sync_tournament_team_chat();

-- 6. Team Chat Channel Creation on Team Insertion
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

  if v_channel_id is not null then
    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;

    if new.created_by is not null then
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
        'owner',
        'active',
        clock_timestamp()
      )
      on conflict (channel_id, user_id) do nothing;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists teams_after_insert_create_chat on public.teams;
create trigger teams_after_insert_create_chat
  after insert on public.teams
  for each row execute function public.create_team_chat();

-- 7. Match Chat Channel Creation on Match Insertion
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

  if v_channel_id is null then
    select channel_id into v_channel_id
      from public.chat_channels
     where match_id = new.match_id and purpose = 'main';
  end if;

  if v_channel_id is not null then
    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;

    if new.created_by is not null then
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
        'owner',
        'active',
        clock_timestamp()
      )
      on conflict (channel_id, user_id) do nothing;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists matches_after_insert_create_chat on public.matches;
create trigger matches_after_insert_create_chat
  after insert on public.matches
  for each row execute function public.create_match_chat();

-- 8. Tournament Chat Channel Creation on Tournament Insertion
create or replace function public.create_tournament_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_key text;
begin
  v_key := 'tournament:' || new.tournament_id::text || ':main';

  insert into public.chat_channels (
    channel_key,
    kind,
    context_type,
    visibility,
    purpose,
    tournament_id,
    created_by
  )
  values (
    v_key,
    'group',
    'tournament',
    'private',
    'main',
    new.tournament_id,
    new.created_by
  )
  on conflict (tournament_id, purpose) where tournament_id is not null and archived_at is null
  do nothing
  returning channel_id into v_channel_id;

  if v_channel_id is null then
    select channel_id into v_channel_id
      from public.chat_channels
     where tournament_id = new.tournament_id and purpose = 'main';
  end if;

  if v_channel_id is not null then
    insert into public.channel_policies (channel_id)
    values (v_channel_id)
    on conflict (channel_id) do nothing;

    if new.created_by is not null then
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
        'owner',
        'active',
        clock_timestamp()
      )
      on conflict (channel_id, user_id) do nothing;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tournaments_after_insert_create_chat on public.tournaments;
create trigger tournaments_after_insert_create_chat
  after insert on public.tournaments
  for each row execute function public.create_tournament_chat();

-- 9. Idempotent Backfill for Existing Domain Entities
insert into public.chat_channels (
  channel_key, kind, context_type, visibility, purpose, team_id, created_by
)
select
  'team:' || t.team_id::text || ':main',
  'group',
  'team',
  'private',
  'main',
  t.team_id,
  t.created_by
from public.teams t
where not exists (
  select 1 from public.chat_channels c
  where c.team_id = t.team_id and c.purpose = 'main' and c.archived_at is null
)
on conflict do nothing;

insert into public.channel_policies (channel_id)
select c.channel_id
from public.chat_channels c
where c.purpose = 'main'
  and not exists (
    select 1 from public.channel_policies p where p.channel_id = c.channel_id
  )
on conflict do nothing;
