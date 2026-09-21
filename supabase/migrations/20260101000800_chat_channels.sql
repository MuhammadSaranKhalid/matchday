-- =============================================================================
-- Migration: 20260101000800_chat_channels.sql
-- =============================================================================

-- 0800 · chat_channels — universal conversation root
-- In Match Day Chat Architecture, every conversation is a channel in chat_channels:
--   • direct message: kind = 'direct', context_type = 'none', key = 'dm:<low>:<high>'
--   • team chat: kind = 'group', context_type = 'team', purpose = 'main', key = 'team:<team_id>:main'
--   • match chat: kind = 'group', context_type = 'match', purpose = 'main', key = 'match:<match_id>:main'
--   • tournament chat: kind = 'group', context_type = 'tournament', purpose = 'main'
--   • standalone group: kind = 'group', context_type = 'none', key = 'group:<channel_id>'
--   • broadcast channel: kind = 'broadcast'

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.chat_channels (
  channel_id       uuid primary key default gen_random_uuid(),
  channel_key      text not null unique,
  kind             public.chat_channel_kind not null,
  context_type     public.chat_channel_context not null default 'none',
  visibility       public.chat_channel_visibility not null default 'private',
  purpose          text not null default 'main',
  title            text,
  description      text,
  avatar_url       text,
  created_by       uuid
    references public.profiles (user_id)
    on delete set null,
  team_id          uuid
    references public.teams (team_id)
    on delete cascade,
  match_id         uuid
    references public.matches (match_id)
    on delete cascade,
  tournament_id    uuid
    references public.tournaments (tournament_id)
    on delete cascade,
  club_id          uuid, -- reserved for future clubs table
  last_message_seq bigint,
  last_message_at  timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  archived_at      timestamptz,
  constraint chat_channels_context_shape
    check (
      (
        context_type = 'none'
        and team_id is null
        and match_id is null
        and tournament_id is null
        and club_id is null
      )
      or (
        context_type = 'team'
        and team_id is not null
        and match_id is null
        and tournament_id is null
        and club_id is null
      )
      or (
        context_type = 'match'
        and match_id is not null
        and team_id is null
        and tournament_id is null
        and club_id is null
      )
      or (
        context_type = 'tournament'
        and tournament_id is not null
        and team_id is null
        and match_id is null
        and club_id is null
      )
      or (
        context_type = 'club'
        and club_id is not null
        and team_id is null
        and match_id is null
        and tournament_id is null
      )
    ),
  constraint direct_channel_shape
    check (kind <> 'direct' or (context_type = 'none' and visibility = 'private'))
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create unique index chat_channels_team_purpose_unique
  on public.chat_channels (
    team_id,
    purpose
  )
  where team_id is not null and archived_at is null;

create unique index chat_channels_match_purpose_unique
  on public.chat_channels (
    match_id,
    purpose
  )
  where match_id is not null and archived_at is null;

create unique index chat_channels_tournament_purpose_unique
  on public.chat_channels (
    tournament_id,
    purpose
  )
  where tournament_id is not null and archived_at is null;

create unique index chat_channels_club_purpose_unique
  on public.chat_channels (
    club_id,
    purpose
  )
  where club_id is not null and archived_at is null;

create index chat_channels_last_message_idx
  on public.chat_channels (
    last_message_at desc nulls last
  );

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger chat_channels_set_updated_at
  before update on public.chat_channels
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.chat_channels enable row level security;
