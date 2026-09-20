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


-- =============================================================================
-- Cricket side extension
-- =============================================================================

create table public.cricket_match_sides (
  match_id uuid not null,
  team_side text not null
    check (team_side in ('team_a', 'team_b')),

  is_batting_first boolean,

  captain_player_id uuid,
  keeper_player_id uuid,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (match_id, team_side),

  constraint cricket_match_sides_shared_side_fkey
    foreign key (match_id, team_side)
    references public.match_teams(match_id, team_side)
    on delete cascade,

  constraint cricket_match_sides_cricket_match_fkey
    foreign key (match_id)
    references public.cricket_matches(match_id)
    on delete cascade,

  -- Captain/keeper must belong to THIS match, not merely be any
  -- match_player row from another fixture.
  constraint cricket_match_sides_captain_match_fkey
    foreign key (captain_player_id, match_id)
    references public.match_players(match_player_id, match_id)
    on delete restrict,

  constraint cricket_match_sides_keeper_match_fkey
    foreign key (keeper_player_id, match_id)
    references public.match_players(match_player_id, match_id)
    on delete restrict
);


comment on table public.cricket_match_sides is
  'Cricket-only metadata for a shared match side. Shared team identity/name '
  'remain in match_teams.';


create trigger cricket_match_sides_set_updated_at
  before update on public.cricket_match_sides
  for each row
  execute function public.set_updated_at();


alter table public.cricket_match_sides enable row level security;

create policy "cricket_match_sides_read_all"
  on public.cricket_match_sides
  for select
  to anon, authenticated
  using (true);

revoke all
  on table public.cricket_match_sides
  from anon, authenticated;

grant select
  on table public.cricket_match_sides
  to anon, authenticated;

grant all
  on table public.cricket_match_sides
  to service_role;


-- Transitional mirror trigger removed (development: writers populate
-- cricket_match_sides directly in each RPC).




-- =============================================================================
-- Transitional legacy column comments
-- =============================================================================

comment on column public.match_teams.is_batting_first is
  'DEPRECATED CRICKET FIELD. Canonical value lives in cricket_match_sides.';

comment on column public.match_teams.captain_player_id is
  'DEPRECATED CRICKET FIELD. Canonical value lives in cricket_match_sides.';

comment on column public.match_teams.keeper_player_id is
  'DEPRECATED CRICKET FIELD. Canonical value lives in cricket_match_sides.';
