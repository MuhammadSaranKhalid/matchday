-- =============================================================================
-- Migration: 20260101000404_cricket_match_players.sql
-- =============================================================================

-- 20260101000412 · cricket_match_players
-- Cricket-specific per-match player state (role flags, batting order).
-- Depends on: 20260101000401_match_players.sql, 20260101000411_cricket_matches.sql

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.cricket_match_players (
  match_player_id  uuid primary key,
  match_id         uuid not null,
  is_playing_xi    boolean not null default true,
  batting_order    smallint check (
    batting_order is null
    or batting_order between 1 and 15
  ),
  -- Deliberately independent booleans. A Cricket player may simultaneously
  -- be captain + wicket-keeper; the legacy single match_role enum cannot
  -- represent that combination.
  is_captain       boolean not null default false,
  is_vice_captain  boolean not null default false,
  is_wicket_keeper boolean not null default false,
  is_substitute    boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint cricket_match_players_parent_player_fkey
    foreign key (match_player_id, match_id)
    references public.match_players (match_player_id, match_id)
    on delete cascade,
  constraint cricket_match_players_cricket_match_fkey
    foreign key (match_id)
    references public.cricket_matches (match_id)
    on delete cascade
);

comment on table public.cricket_match_players is
  'Cricket-only per-match player state. Shared identity remains in '
  'match_players. Captain, wicket-keeper and substitute are independent '
  'facts rather than mutually-exclusive roles.';

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger cricket_match_players_set_updated_at
  before update on public.cricket_match_players
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.cricket_match_players enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "cricket_match_players_read_all"
  on public.cricket_match_players
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on table public.cricket_match_players from anon, authenticated;

grant select on table public.cricket_match_players to anon, authenticated;

grant all on table public.cricket_match_players to service_role;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index cricket_match_players_match
  on public.cricket_match_players (match_id);

-- Transitional mirror trigger removed (development: writers populate
-- cricket_match_players directly in each RPC).
