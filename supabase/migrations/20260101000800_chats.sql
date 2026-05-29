-- =============================================================================
-- 0800 · chats — group chat container, one per team
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- A chat is the addressable container for a conversation: the inbox row,
-- the channel name in realtime broadcasts, the unit of read receipts.
-- The members (chat_members, 0801) and the actual messages (messages,
-- 0802) hang off it.
--
-- v1 SCOPE
-- --------
-- Only team chats exist today. The `chat_type` enum has room for `dm`
-- and `tournament` later — the unique-index pattern below already
-- allows multiple non-team chats to coexist with the one-team-chat
-- constraint.
--
-- LIFECYCLE
-- ---------
-- Driven entirely off teams + team_members:
--   • teams INSERT          → create_team_chat trigger (declared below)
--                              creates the chat + adds the owner as admin.
--   • team_members INSERT   → add_team_member_to_chat (0801) adds the
--                              claimed user to the chat as a member.
--   • team_members UPDATE   → sync_team_member_chat (0801) flips chat
--                              membership when status changes or when
--                              an unclaimed-claimed cascade runs.
--   • messages INSERT       → bump_chat_last_message_at (0802) updates
--                              `last_message_at` for inbox sorting.
--
-- App code never has to remember to maintain any of this — the source-
-- of-truth tables drive the chat layer.
--
-- WHY THE RLS POLICIES ARE IN 0801, NOT HERE
-- ------------------------------------------
-- The chats SELECT and UPDATE policies need `is_chat_member()`, a helper
-- that queries chat_members. That table doesn't exist yet at this point
-- in the migration order, so the policies move to 0801 (which owns the
-- helper). RLS is still enabled here so that the table is denied-by-
-- default until 0801 wires the policies in.
-- =============================================================================

create type public.chat_type as enum ('team');

create table public.chats (
  chat_id          uuid primary key default gen_random_uuid(),
  type             public.chat_type not null,

  -- Cascade so deleting a team automatically tears down its chat. For
  -- non-team chats (future), this column is NULL and the partial unique
  -- index below permits as many as needed.
  team_id          uuid references public.teams(team_id) on delete cascade,

  -- Denormalised "last activity" timestamp. Bumped by the trigger in
  -- 0802 (messages). Lets the inbox sort by recency without an
  -- aggregate over messages on every read.
  last_message_at  timestamptz,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- Required-shape consistency: team chats must carry a team_id.
  constraint chats_team_team_id_required check (
    (type = 'team' and team_id is not null)
  )
);

-- One chat per team. Partial unique index — non-team chats (future) are
-- not subject to this constraint.
create unique index chats_team_unique
  on public.chats (team_id)
  where team_id is not null;

-- Inbox sort. Nulls last so brand-new chats with no messages settle at
-- the bottom of the list rather than the top.
create index chats_last_message_at on public.chats (last_message_at desc nulls last);

create trigger chats_set_updated_at
  before update on public.chats
  for each row execute function public.set_updated_at();

-- RLS is enabled now; the SELECT and UPDATE policies are declared in
-- 0801 alongside `is_chat_member()`.
alter table public.chats enable row level security;

-- =============================================================================
-- create_team_chat — bootstrap a team's chat the moment the team is created
-- =============================================================================
-- An AFTER INSERT trigger on `teams` that creates the corresponding chat
-- and inserts the owner as the first chat_member (with role 'admin').
--
-- Runs inside the team-creation transaction, so a failure here aborts
-- team creation. Acceptable: a team that can't get a chat is broken from
-- the user's perspective, so failing loudly at creation is the right
-- shape.
--
-- The chat_members INSERT happens here too, even though chat_members is
-- defined in 0801 — Postgres resolves the table reference at trigger
-- INVOCATION time, not at function-CREATE time, so the forward reference
-- is fine as long as 0801 runs before any team is created. Migrations
-- always run start to finish before the app accepts traffic, so this is
-- guaranteed.
-- =============================================================================
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
