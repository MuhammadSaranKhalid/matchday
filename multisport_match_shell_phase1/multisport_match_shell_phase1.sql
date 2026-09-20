-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 1
-- =============================================================================
--
-- PURPOSE
-- -------
-- Establish the sport-neutral match shell / Cricket-extension boundary without
-- breaking the existing Cricket Flutter application or existing Cricket RPCs.
--
-- This is an intentionally transitional DEVELOPMENT migration:
--
--   matches
--      shared match identity + scheduling + teams + lifecycle
--
--   cricket_matches
--      Cricket-only format/rules/toss/start/scoring/result state
--
--   match_players
--      existing table remains readable/writable for compatibility
--
--   cricket_match_players
--      new Cricket-only participant extension
--
--   match_teams
--      existing table remains readable/writable for compatibility
--
--   cricket_match_sides
--      new Cricket-only side metadata extension
--
--   match_innings / match_innings_state / match_deliveries / match_wickets
--      legacy names remain for now, but match_innings is constrained to a
--      cricket_matches parent. They are therefore Cricket-owned in the DB.
--
-- IMPORTANT
-- ---------
-- The old Cricket columns on matches/match_players/match_teams are NOT removed
-- in this phase. Existing writers remain the source during the transition and
-- database triggers mirror them into the new Cricket extension tables.
--
-- Phase 2 switches RPCs/Flutter to the extension tables.
-- Phase 3 removes the legacy Cricket columns and renames the Cricket engine
-- tables/types once no caller depends on the legacy shape.
--
-- This ordering gives a reset-clean, testable refactor rather than changing
-- schema + every caller in one unobservable jump.
-- =============================================================================


-- =============================================================================
-- 1. Match sport is identity and is immutable after creation
-- =============================================================================

drop trigger if exists matches_sport_immutable on public.matches;

-- Do NOT use `UPDATE OF sport_id` here. `matches_enforce_sport` may change
-- NEW.sport_id while the caller only updated team_id/tournament_id; an
-- UPDATE-OF trigger would not be scheduled in that case. PostgreSQL executes
-- same-timing triggers alphabetically, so `matches_enforce_sport` runs first
-- and this guard then rejects any resulting sport reassignment.
create trigger matches_sport_immutable
  before update
  on public.matches
  for each row
  execute function public.prevent_sport_reassignment();


comment on column public.matches.sport_id is
  'Immutable sport identity of this match. Related teams/tournament must '
  'agree with it. Sport-specific match rules/state live outside matches.';


-- =============================================================================
-- 2. Cricket match extension
-- =============================================================================

create table public.cricket_matches (
  match_id uuid primary key
    references public.matches(match_id)
    on delete cascade,

  -- Transitional typed preset label. The current enum is Cricket-specific and
  -- therefore belongs here rather than in the final shared match shell.
  format_code public.match_format not null default 't20',

  -- Snapshot of the rules used by THIS match.
  --
  -- Never make a played match dynamically depend on a mutable preset.
  rules_snapshot jsonb not null
    default public._normalize_match_format('{}'::jsonb),

  -- Cricket toss.
  toss_won_by uuid
    references public.teams(team_id)
    on delete set null,

  toss_decision public.toss_decision,

  toss_face char(1)
    check (
      toss_face is null
      or toss_face in ('H', 'T')
    ),

  toss_recorded_at timestamptz,

  -- Cricket pre-live/live phase. The existing enum is retained during the
  -- transition; it will be renamed to cricket_match_phase after callers move.
  phase public.match_start_phase not null default 'toss',

  openers_submitted_by uuid
    references public.profiles(user_id)
    on delete set null,

  openers_submitted_at timestamptz,

  scoring_mode public.scoring_mode
    not null
    default 'live_ball_by_ball',

  revised_conditions jsonb,

  -- Cricket result details. Generic tournament advancement continues to use
  -- matches.winner_id.
  result jsonb,
  result_summary jsonb,

  player_of_the_match_id uuid,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


comment on table public.cricket_matches is
  'Cricket-specific extension of matches. The parent matches row identifies '
  'the sporting event; this row contains only Cricket rules and state.';

comment on column public.cricket_matches.rules_snapshot is
  'Immutable-per-match Cricket rules snapshot derived from a preset/custom '
  'configuration when the match is created.';


create trigger cricket_matches_set_updated_at
  before update on public.cricket_matches
  for each row
  execute function public.set_updated_at();


-- Only a Cricket parent may own a cricket_matches row.

create or replace function public.enforce_cricket_match_parent()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from public.matches m
    where m.match_id = new.match_id
      and m.sport_id = 'cricket'
  ) then
    raise exception
      'cricket_matches requires a parent match whose sport_id is cricket'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all
  on function public.enforce_cricket_match_parent()
  from public, anon, authenticated;


create trigger cricket_matches_parent_guard
  before insert or update of match_id
  on public.cricket_matches
  for each row
  execute function public.enforce_cricket_match_parent();


-- Public match reads remain public. Writes are domain-owned.
alter table public.cricket_matches enable row level security;

create policy "cricket_matches_read_all"
  on public.cricket_matches
  for select
  to anon, authenticated
  using (true);

revoke all
  on table public.cricket_matches
  from anon, authenticated;

grant select
  on table public.cricket_matches
  to anon, authenticated;

grant all
  on table public.cricket_matches
  to service_role;


create index cricket_matches_toss_won_by
  on public.cricket_matches (toss_won_by)
  where toss_won_by is not null;

create index cricket_matches_openers_submitted_by
  on public.cricket_matches (openers_submitted_by)
  where openers_submitted_by is not null;

create index cricket_matches_player_of_the_match
  on public.cricket_matches (player_of_the_match_id)
  where player_of_the_match_id is not null;


-- =============================================================================
-- 3. Transitional mirror from legacy matches columns -> cricket_matches
-- =============================================================================
--
-- Existing Flutter/RPC code still writes the legacy Cricket columns on
-- `matches`. During Phase 1 that is allowed. This trigger immediately mirrors
-- those values into the new canonical extension so we can verify the boundary
-- before changing all writers.
--
-- IMPORTANT: this is ONE-WAY. cricket_matches is not mirrored back to matches.
-- Phase 2 changes writers to cricket_matches; this trigger is then deleted.
-- =============================================================================

create or replace function public.sync_legacy_match_to_cricket_extension()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.sport_id <> 'cricket' then
    return new;
  end if;

  insert into public.cricket_matches (
    match_id,
    format_code,
    rules_snapshot,
    toss_won_by,
    toss_decision,
    toss_face,
    toss_recorded_at,
    phase,
    openers_submitted_by,
    openers_submitted_at,
    scoring_mode,
    revised_conditions,
    result,
    result_summary,
    player_of_the_match_id
  )
  values (
    new.match_id,
    new.match_format,
    public._normalize_match_format(new.format),
    new.toss_won_by,
    new.toss_decision,
    new.toss_face,
    new.toss_recorded_at,
    new.start_phase,
    new.openers_submitted_by,
    new.openers_submitted_at,
    new.scoring_mode,
    new.revised_conditions,
    new.result,
    new.result_summary,
    new.player_of_the_match_id
  )
  on conflict (match_id)
  do update set
    format_code              = excluded.format_code,
    rules_snapshot           = excluded.rules_snapshot,
    toss_won_by              = excluded.toss_won_by,
    toss_decision            = excluded.toss_decision,
    toss_face                = excluded.toss_face,
    toss_recorded_at         = excluded.toss_recorded_at,
    phase                    = excluded.phase,
    openers_submitted_by     = excluded.openers_submitted_by,
    openers_submitted_at     = excluded.openers_submitted_at,
    scoring_mode             = excluded.scoring_mode,
    revised_conditions       = excluded.revised_conditions,
    result                   = excluded.result,
    result_summary           = excluded.result_summary,
    player_of_the_match_id   = excluded.player_of_the_match_id,
    updated_at               = now();

  return new;
end;
$$;

revoke all
  on function public.sync_legacy_match_to_cricket_extension()
  from public, anon, authenticated;


drop trigger if exists matches_sync_cricket_extension on public.matches;

create trigger matches_sync_cricket_extension
  after insert
      or update of
        match_format,
        format,
        toss_won_by,
        toss_decision,
        toss_face,
        toss_recorded_at,
        start_phase,
        openers_submitted_by,
        openers_submitted_at,
        scoring_mode,
        revised_conditions,
        result,
        result_summary,
        player_of_the_match_id
  on public.matches
  for each row
  execute function public.sync_legacy_match_to_cricket_extension();


-- =============================================================================
-- 4. Cricket participant extension
-- =============================================================================

-- Composite identity allows sport-specific extensions to prove that their
-- match_id matches the parent match_player row.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.match_players'::regclass
      and conname = 'match_players_id_match_unique'
  ) then
    alter table public.match_players
      add constraint match_players_id_match_unique
      unique (match_player_id, match_id);
  end if;
end
$$;


create table public.cricket_match_players (
  match_player_id uuid primary key,
  match_id uuid not null,

  is_playing_xi boolean not null default true,

  batting_order smallint
    check (
      batting_order is null
      or batting_order between 1 and 15
    ),

  -- Deliberately independent booleans. A Cricket player may simultaneously
  -- be captain + wicket-keeper; the legacy single match_role enum cannot
  -- represent that combination.
  is_captain boolean not null default false,
  is_vice_captain boolean not null default false,
  is_wicket_keeper boolean not null default false,
  is_substitute boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint cricket_match_players_parent_player_fkey
    foreign key (match_player_id, match_id)
    references public.match_players(match_player_id, match_id)
    on delete cascade,

  constraint cricket_match_players_cricket_match_fkey
    foreign key (match_id)
    references public.cricket_matches(match_id)
    on delete cascade
);


comment on table public.cricket_match_players is
  'Cricket-only per-match player state. Shared identity remains in '
  'match_players. Captain, wicket-keeper and substitute are independent '
  'facts rather than mutually-exclusive roles.';


create trigger cricket_match_players_set_updated_at
  before update on public.cricket_match_players
  for each row
  execute function public.set_updated_at();


alter table public.cricket_match_players enable row level security;

create policy "cricket_match_players_read_all"
  on public.cricket_match_players
  for select
  to anon, authenticated
  using (true);

revoke all
  on table public.cricket_match_players
  from anon, authenticated;

grant select
  on table public.cricket_match_players
  to anon, authenticated;

grant all
  on table public.cricket_match_players
  to service_role;

create index cricket_match_players_match
  on public.cricket_match_players (match_id);


-- Existing writers still write role/is_in_playing_xi/batting_order on
-- match_players. Mirror those fields until Phase 2 moves the writers.

create or replace function public.sync_legacy_match_player_to_cricket_extension()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from public.matches m
    where m.match_id = new.match_id
      and m.sport_id = 'cricket'
  ) then
    return new;
  end if;

  -- The match INSERT trigger creates cricket_matches before match_players are
  -- materialised. This guard makes the dependency explicit.
  if not exists (
    select 1
    from public.cricket_matches cm
    where cm.match_id = new.match_id
  ) then
    raise exception
      'Cricket match extension is missing for match %',
      new.match_id
      using errcode = '23503';
  end if;

  insert into public.cricket_match_players (
    match_player_id,
    match_id,
    is_playing_xi,
    batting_order,
    is_captain,
    is_vice_captain,
    is_wicket_keeper,
    is_substitute
  )
  values (
    new.match_player_id,
    new.match_id,
    new.is_in_playing_xi,
    new.batting_order,
    new.role = 'captain',
    new.role = 'vice_captain',
    new.role = 'wicket_keeper',
    new.role = 'substitute'
  )
  on conflict (match_player_id)
  do update set
    match_id          = excluded.match_id,
    is_playing_xi     = excluded.is_playing_xi,
    batting_order     = excluded.batting_order,
    is_captain        = excluded.is_captain,
    is_vice_captain   = excluded.is_vice_captain,
    is_wicket_keeper  = excluded.is_wicket_keeper,
    is_substitute     = excluded.is_substitute,
    updated_at        = now();

  return new;
end;
$$;

revoke all
  on function public.sync_legacy_match_player_to_cricket_extension()
  from public, anon, authenticated;


drop trigger if exists match_players_sync_cricket_extension
  on public.match_players;

create trigger match_players_sync_cricket_extension
  after insert
      or update of
        match_id,
        role,
        is_in_playing_xi,
        batting_order
  on public.match_players
  for each row
  execute function public.sync_legacy_match_player_to_cricket_extension();


-- =============================================================================
-- 5. Cricket side extension
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


create or replace function public.sync_legacy_match_side_to_cricket_extension()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from public.matches m
    where m.match_id = new.match_id
      and m.sport_id = 'cricket'
  ) then
    return new;
  end if;

  insert into public.cricket_match_sides (
    match_id,
    team_side,
    is_batting_first,
    captain_player_id,
    keeper_player_id
  )
  values (
    new.match_id,
    new.team_side,
    new.is_batting_first,
    new.captain_player_id,
    new.keeper_player_id
  )
  on conflict (match_id, team_side)
  do update set
    is_batting_first   = excluded.is_batting_first,
    captain_player_id  = excluded.captain_player_id,
    keeper_player_id   = excluded.keeper_player_id,
    updated_at         = now();

  return new;
end;
$$;

revoke all
  on function public.sync_legacy_match_side_to_cricket_extension()
  from public, anon, authenticated;


drop trigger if exists match_teams_sync_cricket_extension
  on public.match_teams;

create trigger match_teams_sync_cricket_extension
  after insert
      or update of
        is_batting_first,
        captain_player_id,
        keeper_player_id
  on public.match_teams
  for each row
  execute function public.sync_legacy_match_side_to_cricket_extension();



-- =============================================================================
-- 5.1 Safe transition population
-- =============================================================================
--
-- On a fresh `supabase db reset` these statements normally touch zero rows.
-- They are included so the migration is also safe to apply once to an existing
-- development database before resetting. This is NOT the historical
-- player_sports backfill discussed separately.
-- =============================================================================

insert into public.cricket_matches (
  match_id,
  format_code,
  rules_snapshot,
  toss_won_by,
  toss_decision,
  toss_face,
  toss_recorded_at,
  phase,
  openers_submitted_by,
  openers_submitted_at,
  scoring_mode,
  revised_conditions,
  result,
  result_summary,
  player_of_the_match_id
)
select
  m.match_id,
  m.match_format,
  public._normalize_match_format(m.format),
  m.toss_won_by,
  m.toss_decision,
  m.toss_face,
  m.toss_recorded_at,
  m.start_phase,
  m.openers_submitted_by,
  m.openers_submitted_at,
  m.scoring_mode,
  m.revised_conditions,
  m.result,
  m.result_summary,
  m.player_of_the_match_id
from public.matches m
where m.sport_id = 'cricket'
on conflict (match_id) do nothing;


insert into public.cricket_match_players (
  match_player_id,
  match_id,
  is_playing_xi,
  batting_order,
  is_captain,
  is_vice_captain,
  is_wicket_keeper,
  is_substitute
)
select
  mp.match_player_id,
  mp.match_id,
  mp.is_in_playing_xi,
  mp.batting_order,
  mp.role = 'captain',
  mp.role = 'vice_captain',
  mp.role = 'wicket_keeper',
  mp.role = 'substitute'
from public.match_players mp
join public.matches m
  on m.match_id = mp.match_id
where m.sport_id = 'cricket'
on conflict (match_player_id) do nothing;


insert into public.cricket_match_sides (
  match_id,
  team_side,
  is_batting_first,
  captain_player_id,
  keeper_player_id
)
select
  mt.match_id,
  mt.team_side,
  mt.is_batting_first,
  mt.captain_player_id,
  mt.keeper_player_id
from public.match_teams mt
join public.matches m
  on m.match_id = mt.match_id
where m.sport_id = 'cricket'
on conflict (match_id, team_side) do nothing;


-- =============================================================================
-- 6. Make the innings engine structurally Cricket-only
-- =============================================================================
--
-- We intentionally keep the current public table names in Phase 1 so no
-- scoring caller breaks. This additional FK means an innings cannot belong to
-- Football or another sport even though the table still has a legacy generic
-- name.
-- =============================================================================

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.match_innings'::regclass
      and conname = 'match_innings_cricket_match_fkey'
  ) then
    alter table public.match_innings
      add constraint match_innings_cricket_match_fkey
      foreign key (match_id)
      references public.cricket_matches(match_id)
      on delete cascade;
  end if;
end
$$;


comment on table public.match_innings is
  'CRICKET ENGINE TABLE (legacy generic name). Every row is constrained to '
  'a cricket_matches parent. Planned rename: cricket_match_innings.';

comment on table public.match_innings_state is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_innings_state.';

comment on table public.match_deliveries is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_deliveries.';

comment on table public.match_wickets is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_wickets.';


-- =============================================================================
-- 7. Cricket aggregate compatibility view
-- =============================================================================
--
-- This view demonstrates the final Flutter read boundary. It is not used by
-- Flutter yet in Phase 1; switching reads belongs to Phase 2.
--
-- It deliberately exposes the existing wire names (`format`, `start_phase`,
-- etc.) while sourcing them from cricket_matches.
-- =============================================================================

create or replace view public.cricket_match_details
with (security_invoker = true)
as
select
  -- Shared match shell
  m.match_id,
  m.tournament_id,
  m.match_type,
  m.stage,
  m.round,
  m.bracket_round_number,
  m.bracket_match_number,
  m.prev_match_a_id,
  m.prev_match_b_id,
  m.group_id,
  m.venue,
  m.ground_id,
  m.sport_id,
  m.scheduled_start_time,
  m.actual_start_time,
  m.completed_at,
  m.status,
  m.winner_id,
  m.team_a_id,
  m.team_b_id,
  m.created_by,
  m.created_at,
  m.updated_at,

  -- Cricket extension exposed under the current Flutter wire names
  cm.format_code as match_format,
  cm.rules_snapshot as format,
  cm.toss_won_by,
  cm.toss_decision,
  cm.toss_face,
  cm.toss_recorded_at,
  cm.phase as start_phase,
  cm.openers_submitted_by,
  cm.openers_submitted_at,
  cm.scoring_mode,
  cm.result,
  cm.result_summary,
  cm.revised_conditions,
  cm.player_of_the_match_id,

  -- These are Cricket match-day authority snapshots and remain legacy on
  -- matches until Phase 2. They are selected here so the current Flutter DTO
  -- shape can be switched to this view without an unrelated authority rewrite.
  m.team_a_captain,
  m.team_b_captain

from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket';


grant select
  on public.cricket_match_details
  to anon, authenticated, service_role;


comment on view public.cricket_match_details is
  'Cricket read aggregate: sport-neutral matches shell joined to '
  'cricket_matches. Phase 2 Flutter reads should target this view while '
  'domain writes remain RPC-owned.';


-- =============================================================================
-- 8. Mark transitional legacy columns clearly
-- =============================================================================

comment on column public.matches.match_format is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_matches.format_code. Remove after Phase 2 callers move.';

comment on column public.matches.format is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_matches.rules_snapshot. Remove after Phase 2 callers move.';

comment on column public.matches.toss_won_by is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.toss_decision is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.toss_face is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.start_phase is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.phase.';

comment on column public.matches.openers_submitted_by is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.openers_submitted_at is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.scoring_mode is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.revised_conditions is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.result is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Cricket result detail belongs in '
  'cricket_matches; matches.winner_id remains shared.';

comment on column public.matches.result_summary is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.matches.player_of_the_match_id is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_matches.';

comment on column public.match_players.role is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored into independent flags on '
  'cricket_match_players.';

comment on column public.match_players.is_in_playing_xi is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_match_players.is_playing_xi.';

comment on column public.match_players.batting_order is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_match_players.batting_order.';

comment on column public.match_teams.is_batting_first is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_match_sides.';

comment on column public.match_teams.captain_player_id is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_match_sides.';

comment on column public.match_teams.keeper_player_id is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to cricket_match_sides.';
