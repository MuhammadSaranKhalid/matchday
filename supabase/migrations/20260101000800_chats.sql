-- =============================================================================
-- 0800 · chats — conversation container (teams, DMs, matches, groups)
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- A chat is the addressable container for a conversation: the inbox row,
-- the channel name in realtime broadcasts, the unit of read receipts.
-- The members (chat_members, 0801) and the actual messages (messages,
-- 0802) hang off it.
--
-- SUPPORTED CHAT TYPES
-- --------------------
--   • 'team'  — group chat bound to a team_id (one per team).
--   • 'dm'    — 1-on-1 direct message between two users (canonical uniqueness).
--   • 'match' — match room for captains, umpires, and match officials.
--   • 'group' — ad-hoc cricket group / tournament channel.
-- =============================================================================


create table public.chats (
  chat_id          uuid primary key default gen_random_uuid(),
  type             public.chat_type not null,

  -- For team chats: references public.teams. Null for DMs, matches, groups.
  team_id          uuid references public.teams(team_id) on delete cascade,
  -- The chat_type enum has always carried 'match', but there was no column to
  -- point a match chat at its match, so the value was unusable. (2026-09-06.)
  match_id         uuid references public.matches(match_id) on delete cascade,

  -- Denormalised "last activity" timestamp. Bumped by the trigger in 0802.
  last_message_at  timestamptz,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- Required-shape consistency
  constraint chats_team_team_id_required check (
    (type = 'team' and team_id is not null) or (type <> 'team')
  ),
  constraint chats_match_match_id_required check (
    (type = 'match' and match_id is not null) or (type <> 'match')
  )
);

-- One chat per team constraint
create unique index chats_team_unique
  on public.chats (team_id)
  where team_id is not null;

-- One match chat per match, same shape as the team rule above.
create unique index chats_match_unique
  on public.chats (match_id)
  where match_id is not null;

-- Inbox sort index: nulls last so brand-new chats settle at bottom
create index chats_last_message_at on public.chats (last_message_at desc nulls last);

create trigger chats_set_updated_at
  before update on public.chats
  for each row execute function public.set_updated_at();

alter table public.chats enable row level security;

-- =============================================================================
-- dm_channels — 1-on-1 Direct Messages canonical pairing
-- =============================================================================
-- Mathematically guarantees exactly 1 DM channel between any two users.
-- Canonical ordering: user_a < user_b
-- =============================================================================
create table public.dm_channels (
  chat_id    uuid primary key references public.chats(chat_id) on delete cascade,
  user_a     uuid not null references public.profiles(user_id) on delete cascade,
  user_b     uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),

  -- DM request acceptance. A DM from a non-follower lands as a request; these
  -- two are stamped by accept_dm_request (20260816000000) when the recipient
  -- accepts. Null = still pending.
  accepted_at timestamptz,
  accepted_by uuid references public.profiles(user_id) on delete set null,
  constraint dm_channels_users_order check (user_a < user_b),
  constraint dm_channels_unique_pair unique (user_a, user_b)
);

create index dm_channels_user_a on public.dm_channels (user_a);
create index dm_channels_user_b on public.dm_channels (user_b);

alter table public.dm_channels enable row level security;

-- =============================================================================
-- Lifecycle Triggers & RPCs
-- =============================================================================

-- ---- create_team_chat ----
create or replace function public.create_team_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  insert into public.chats (type, team_id)
  values ('team', new.team_id)
  returning chat_id into v_chat_id;

  insert into public.chat_members (chat_id, user_id, role)
  values (v_chat_id, new.owner_id, 'admin');

  return new;
end;
$$;

create trigger teams_after_insert_create_chat
  after insert on public.teams
  for each row execute function public.create_team_chat();

-- ---- get_or_create_dm_chat ----
create or replace function public.get_or_create_dm_chat(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_user_a uuid;
  v_user_b uuid;
  v_chat_id uuid;
begin
  if v_actor is null then
    raise exception 'Unauthenticated';
  end if;

  if p_target_user_id is null or p_target_user_id = v_actor then
    raise exception 'Cannot create DM with self or null target';
  end if;

  -- Canonical ordering
  if v_actor < p_target_user_id then
    v_user_a := v_actor;
    v_user_b := p_target_user_id;
  else
    v_user_a := p_target_user_id;
    v_user_b := v_actor;
  end if;

  -- Check if DM channel already exists
  select chat_id into v_chat_id
    from public.dm_channels
   where user_a = v_user_a
     and user_b = v_user_b;

  if v_chat_id is not null then
    return v_chat_id;
  end if;

  -- Create new chat container
  insert into public.chats (type)
  values ('dm')
  returning chat_id into v_chat_id;

  -- Insert pairing row
  insert into public.dm_channels (chat_id, user_a, user_b)
  values (v_chat_id, v_user_a, v_user_b);

  -- Insert both members into chat_members
  insert into public.chat_members (chat_id, user_id, role)
  values
    (v_chat_id, v_actor, 'member'),
    (v_chat_id, p_target_user_id, 'member')
  on conflict (chat_id, user_id) do nothing;

  return v_chat_id;
end;
$$;

revoke all on function public.get_or_create_dm_chat(uuid) from public;
grant execute on function public.get_or_create_dm_chat(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_dm_channels_accepted_by
  on public.dm_channels (accepted_by);
