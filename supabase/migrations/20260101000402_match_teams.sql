-- =============================================================================
-- 0402 · match_teams
-- =============================================================================
-- Per-side details for a match, including lineup captain and keeper.
-- Spec: docs/matches-schema-architecture.md

drop table if exists public.match_teams cascade;

-- Per-side slot detail that does NOT fit on `matches`: which side bats first,
-- and who keeps wicket. The team ids and captains themselves live on `matches`
-- (team_a_id/team_b_id, team_a_captain/team_b_captain) — this table does not
-- restate them, it hangs the per-side extras off the side label that
-- match_players.team_side also uses.
create table public.match_teams (
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  team_id                uuid references public.teams(team_id) on delete set null,
  team_name              text not null,
  team_side              text not null check (team_side in ('team_a', 'team_b')),
  is_batting_first       boolean,
  -- Lineup FKs declared below; match_players is defined in the preceding file.
  captain_player_id      uuid,
  keeper_player_id       uuid,
  created_at             timestamptz not null default now(),
  primary key (match_id, team_side)
);

-- Both player slots reference the lineup table created in the preceding file.
alter table public.match_teams
  add constraint match_teams_captain_player_fkey
  foreign key (captain_player_id)
  references public.match_players(match_player_id) on delete set null;

alter table public.match_teams
  add constraint match_teams_keeper_player_fkey
  foreign key (keeper_player_id)
  references public.match_players(match_player_id) on delete set null;

alter table public.match_teams enable row level security;

drop policy if exists "match_teams_read_all" on public.match_teams;

create policy "match_teams_read_all" on public.match_teams for select
  to anon, authenticated
  using (true);

create index if not exists idx_match_teams_captain_player_id
  on public.match_teams (captain_player_id);

create index if not exists idx_match_teams_keeper_player_id
  on public.match_teams (keeper_player_id);

create index if not exists idx_match_teams_team_id
  on public.match_teams (team_id);
