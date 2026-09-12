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

-- Policies and team-chat creation depend on chat_members; see
-- 20260101000804_chat_lifecycle.sql.
