-- =============================================================================
-- Migration: 20260101000101_player_sports.sql
-- =============================================================================

-- 0101 · player_sports
--
-- Canonical registered-player identity per sport.
--
-- profiles
--    = one global Matchday account
--
-- player_sports
--    = sports in which that account has established a player identity
--
-- Example:
--
--   user A | cricket
--   user A | football
--
-- This table does NOT mean:
--   - current team membership
--   - team authority
--   - following/interests
--   - sport-specific skills
--
-- A player-sport identity is durable. Leaving a team does not remove it.
--
-- Current activation paths:
--
--   1. Active team_members row with in_squad = true
--   2. Registered match_players row
--   3. Claiming an unclaimed player
--
-- Future sport-specific onboarding may add another backend activation path.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.player_sports (
  user_id    uuid not null
    references public.profiles (user_id)
    on delete cascade,
  sport_id   text not null
    references public.sports (sport_id)
    on update restrict
    on delete restrict,
  created_at timestamptz not null default now(),
  primary key (user_id, sport_id)
);

comment on table public.player_sports is
  'Canonical registered-player identity per sport. '
  'A row means this Matchday account has established a player identity '
  'in that sport. Team membership and sport-specific attributes are stored '
  'elsewhere.';

comment on column public.player_sports.user_id is 'Global Matchday account identity.';

comment on column public.player_sports.sport_id is
  'Sport in which this account has established a player identity.';

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- PK is (user_id, sport_id), which is ideal for:
--
--   "which sports does this player play?"
--
-- This inverse index supports:
--
--   "find Cricket players"
--   "find Football players"
create index player_sports_sport_user
  on public.player_sports (sport_id, user_id);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- RLS / Data API
alter table public.player_sports enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

-- Player sport identity is public, just like the public player/profile model.
create policy "player_sports_read_public"
  on public.player_sports
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

-- Domain ownership
--
-- player_sports is NOT directly writable through Flutter.
--
-- It is maintained by backend domain transitions:
--
--   team_members
--   match_players
--   unclaimed-player claiming
--
-- This prevents clients from:
--
--   * claiming to play arbitrary sports
--   * deleting an identity while match/team history still depends on it
--
-- Account deletion naturally removes rows through profiles ON DELETE CASCADE.
revoke all on table public.player_sports from anon, authenticated;

grant select on table public.player_sports to anon, authenticated;

grant all on table public.player_sports to service_role;
