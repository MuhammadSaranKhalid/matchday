-- =============================================================================
-- Migration: 20260101000402_match_teams.sql
-- =============================================================================

-- 0402 · match_teams
-- Per-side details for a match, including lineup captain and keeper.
-- Spec: docs/matches-schema-architecture.md

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

drop table if exists public.match_teams cascade;

-- Per-side slot detail that does NOT fit on `matches`: which side bats first,
-- and who keeps wicket. The team ids and captains themselves live on `matches`
-- (team_a_id/team_b_id, team_a_captain/team_b_captain) — this table does not
-- restate them, it hangs the per-side extras off the side label that
-- match_players.team_side also uses.
create table public.match_teams (
  match_id   uuid not null
    references public.matches (match_id)
    on delete cascade,
  team_id    uuid
    references public.teams (team_id)
    on delete set null,
  team_name  text not null,
  team_side  text not null check (team_side in ('team_a', 'team_b')),
  created_at timestamptz not null default now(),
  primary key (match_id, team_side)
);

comment on table public.match_teams is
  'Sport-neutral per-match team-side snapshot. Cricket captain/keeper state lives in cricket_match_players; batting order of sides is derived from Cricket match state.';

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- Both player slots reference the lineup table created in the preceding file.

alter table public.match_teams enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

drop policy if exists "match_teams_read_all" on public.match_teams;

create policy "match_teams_read_all"
  on public.match_teams
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists idx_match_teams_team_id
  on public.match_teams (team_id);

-- Cricket side extension
-- Transitional legacy column comments
