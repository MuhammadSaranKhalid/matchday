-- =============================================================================
-- Migration: 20260101000402_match_teams.sql
-- =============================================================================

-- 0402 · match_teams
-- Canonical per-side details and identity for a match.
-- Spec: docs/matches-schema-architecture.md

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

drop table if exists public.match_teams cascade;

create table public.match_teams (
  match_id   uuid not null
    references public.matches (match_id)
    on delete cascade,
  team_id    uuid
    references public.teams (team_id)
    on delete set null,
  team_name  text,
  team_side  text not null check (team_side in ('team_a', 'team_b')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (match_id, team_side),
  unique (match_id, team_id),
  constraint match_teams_team_snapshot_check
    check (
      team_id is null
      or nullif(btrim(team_name), '') is not null
    )
);

comment on table public.match_teams is
  'Sport-neutral per-match team-side snapshot. This table is the canonical source of truth for team identity on matches.';

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

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
-- Foreign Keys
-- -----------------------------------------------------------------------------

-- Winner side of a match references its canonical match_teams slot
alter table public.matches
  add constraint matches_winner_side_fkey
  foreign key (match_id, winner_side)
  references public.match_teams (match_id, team_side)
  on delete set null;

-- Match players must reference an existing match_teams slot
alter table public.match_players
  add constraint match_players_match_side_fkey
  foreign key (match_id, team_side)
  references public.match_teams (match_id, team_side)
  on delete restrict;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists idx_match_teams_team_id
  on public.match_teams (team_id)
  where team_id is not null;

create index if not exists idx_matches_tournament_winner_side
  on public.matches (tournament_id, winner_side)
  where tournament_id is not null
    and winner_side is not null;

-- -----------------------------------------------------------------------------
-- Integrity Trigger
-- -----------------------------------------------------------------------------

create or replace function public.enforce_match_team_integrity()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_match_sport text;
  v_match_status public.match_status;
  v_team_sport text;
  v_catalog_name text;
begin
  select m.sport_id, m.status
    into v_match_sport, v_match_status
  from public.matches m
  where m.match_id = new.match_id;

  if v_match_sport is null then
    raise exception 'Match % does not exist', new.match_id
      using errcode = '23503';
  end if;

  if tg_op = 'UPDATE'
     and new.team_side is distinct from old.team_side
  then
    raise exception 'A match side identity is immutable'
      using errcode = '23514';
  end if;

  if tg_op = 'UPDATE'
     and new.team_id is distinct from old.team_id
     and v_match_status <> 'scheduled'
  then
    raise exception
      'A match team cannot change after the match has started'
      using errcode = '23514';
  end if;

  if new.team_id is not null then
    select t.sport_id, t.team_name
      into v_team_sport, v_catalog_name
    from public.teams t
    where t.team_id = new.team_id;

    if v_team_sport is null then
      raise exception 'Team % does not exist', new.team_id
        using errcode = '23503';
    end if;

    if v_team_sport is distinct from v_match_sport then
      raise exception
        'Team sport (%) does not match match sport (%)',
        v_team_sport,
        v_match_sport
        using errcode = '23514';
    end if;

    -- Snapshot the catalogue name at assignment time. A later team rename does
    -- not rewrite historical fixtures.
    if tg_op = 'INSERT'
       or new.team_id is distinct from old.team_id
       or new.team_name is null
    then
      new.team_name := v_catalog_name;
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

revoke all
  on function public.enforce_match_team_integrity()
  from public, anon, authenticated;

create trigger match_teams_enforce_integrity
before insert or update
on public.match_teams
for each row
execute function public.enforce_match_team_integrity();

-- -----------------------------------------------------------------------------
-- Auto-create Match Team Slots
-- -----------------------------------------------------------------------------

-- Every match gets the two stable side identities immediately. Team resolution
-- happens by UPDATE, never by creating/deleting side identity rows later.
create or replace function public.create_match_team_slots()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  insert into public.match_teams (
    match_id,
    team_side,
    team_id,
    team_name
  )
  values
    (new.match_id, 'team_a', null, null),
    (new.match_id, 'team_b', null, null)
  on conflict (match_id, team_side) do nothing;

  return new;
end;
$$;

revoke all
  on function public.create_match_team_slots()
  from public, anon, authenticated;

create trigger matches_create_team_slots
after insert
on public.matches
for each row
execute function public.create_match_team_slots();
