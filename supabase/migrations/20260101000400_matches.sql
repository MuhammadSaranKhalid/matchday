-- =============================================================================
-- 0400 · matches
-- =============================================================================
-- Match fixtures, rules, scheduling, teams and result snapshots.
-- Spec: docs/matches-schema-architecture.md

drop table if exists public.matches cascade;

-- -----------------------------------------------------------------------------
-- The canonical match-format shape
-- -----------------------------------------------------------------------------
-- One place that decides what a format document looks like. Every key the
-- client's MatchDto and the Dart scoring engine read is guaranteed present with
-- a sane value, so no downstream reader has to guess what a missing key means.
--
-- `overs_per_innings` matters most: the engine treats 0 as "unlimited" (Test
-- cricket), so a format that merely omits it silently produces an innings that
-- never ends. `max_overs` is accepted as an alias because that is the key the
-- old `rules_config` column used before it was merged into `format`
-- (2026-09-06); competition RPCs that revise conditions write the canonical
-- key.
--
-- Moved here from 20260822110000 during the 2026-09-06 consolidation so that
-- `matches.format` can carry a playable DEFAULT from the moment the table
-- exists, rather than acquiring one two hundred migrations later.
create or replace function public._normalize_match_format(p_format jsonb)
returns jsonb
language sql
immutable
set search_path = public, pg_temp
as $$
  select jsonb_strip_nulls(
    jsonb_build_object(
      'overs_per_innings',   coalesce(
                               (f->>'overs_per_innings')::int,
                               (f->>'max_overs')::int,
                               20),
      'players_per_team',    coalesce((f->>'players_per_team')::int, 11),
      'balls_per_over',      coalesce((f->>'balls_per_over')::int, 6),
      'max_overs_per_bowler',coalesce((f->>'max_overs_per_bowler')::int, 4),
      'innings_per_side',    coalesce((f->>'innings_per_side')::int, 1),
      'ball_type',           coalesce(nullif(f->>'ball_type', ''), 'leather'),
      -- Competition switches. Absorbed from the former `rules_config` column
      -- (2026-09-06): tournament_trigger_super_over reads super_over_enabled,
      -- and dls_enabled is reserved for the rain-rule work.
      'super_over_enabled',  coalesce((f->>'super_over_enabled')::boolean, true),
      'dls_enabled',         coalesce((f->>'dls_enabled')::boolean, true),
      -- Optional. Null is meaningful for both: the engine derives
      -- wickets_to_all_out as (players_per_team - 1) when absent, and
      -- end_change_balls defaults to balls_per_over. jsonb_strip_nulls drops
      -- them rather than writing a null the reader must special-case.
      'wickets_to_all_out',  (f->>'wickets_to_all_out')::int,
      'end_change_balls',    (f->>'end_change_balls')::int
    )
  )
  from (select coalesce(p_format, '{}'::jsonb) as f) s;
$$;

revoke all on function public._normalize_match_format(jsonb) from public;

grant execute on function public._normalize_match_format(jsonb)
  to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- Matches
-- -----------------------------------------------------------------------------
create table public.matches (
  match_id               uuid primary key default gen_random_uuid(),
  tournament_id          uuid references public.tournaments(tournament_id) on delete set null,
  match_type             public.match_type not null default 'friendly',
  match_format           public.match_format not null default 't20',
  stage                  public.match_stage,
  
  -- Tournament Bracket & Feeder Linkage
  round                  text,
  bracket_round_number   integer check (bracket_round_number is null or bracket_round_number >= 1),
  bracket_match_number   integer check (bracket_match_number is null or bracket_match_number >= 1),
  prev_match_a_id        uuid references public.matches(match_id) on delete set null,
  prev_match_b_id        uuid references public.matches(match_id) on delete set null,
  group_id               text,

  -- Scheduling & Venue
  -- `venue` is free text for a fixture with no `grounds` row yet. It is
  -- nullable: the old NOT NULL DEFAULT 'Ground 1' meant every venue-less
  -- match claimed to be played somewhere specific.
  venue                  text,
  ground_id              uuid references public.grounds(ground_id)
                           on delete set null,
  scheduled_start_time   timestamptz not null default now(),
  actual_start_time      timestamptz,
  completed_at           timestamptz,

  -- Format & Rules Contract. ONE document, normalized on the way in.
  -- (Was `format` + `rules_config`, two jsonb blobs holding overs and ball
  -- rules under different key names. Merged 2026-09-06.)
  format                 jsonb not null
                           default public._normalize_match_format('{}'::jsonb),

  -- Toss Information
  toss_won_by            uuid references public.teams(team_id) on delete set null,
  toss_decision          public.toss_decision,
  toss_face              char(1) check (toss_face is null or toss_face in ('H', 'T')),
  toss_recorded_at       timestamptz,

  -- Stepper Phase & Scoring Mode
  start_phase            public.match_start_phase not null default 'toss',
  openers_submitted_by   uuid references public.profiles(user_id) on delete set null,
  openers_submitted_at   timestamptz,
  scoring_mode           public.scoring_mode not null default 'live_ball_by_ball',

  -- Match Lifecycle Status
  status                 public.match_status not null default 'scheduled',
  
  -- Result Snapshot. `result` is authoritative; winner_id is derived from it
  -- by match_sync_winner_id on every write (20260830000000) so tournament
  -- queries can index and join on a plain uuid.
  result                 jsonb,
  result_summary         jsonb,
  winner_id              uuid references public.teams(team_id) on delete set null,

  -- Audit trail for a rain-revised match (artboards 27m / 28b): the original
  -- and revised overs, the target the organiser applied, and which method
  -- produced it. Computed in the Dart engine, never in SQL.
  revised_conditions     jsonb,
  -- Was also duplicated as `man_of_the_match`; both were unreferenced by any
  -- reader and neither had a foreign key. One column, with its FK declared
  -- (in 20260101000409_match_helpers.sql: match_players also references matches).
  player_of_the_match_id uuid,

  -- Team References
  team_a_id             uuid references public.teams(team_id) on delete set null,
  team_b_id             uuid references public.teams(team_id) on delete set null,
  team_a_captain        uuid references public.profiles(user_id) on delete set null,
  team_b_captain        uuid references public.profiles(user_id) on delete set null,

  created_by             uuid references public.profiles(user_id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------
alter table public.matches enable row level security;

-- Public Read Policies
drop policy if exists "matches_read_all" on public.matches;

create policy "matches_read_all" on public.matches for select
  to anon, authenticated
  using (true);

-- Performance Indexes
create index if not exists idx_matches_status_time on public.matches(status, scheduled_start_time desc);

create index if not exists idx_matches_tournament on public.matches(tournament_id) where tournament_id is not null;

create index if not exists idx_matches_team_a on public.matches(team_a_id) where team_a_id is not null;

create index if not exists idx_matches_team_b on public.matches(team_b_id) where team_b_id is not null;

-- The scheduler's lookup: "what else is on this ground around this time".
comment on column public.matches.venue is
  'Free-text ground name, NULL when unknown. Retained for casual matches with '
  'no registered ground. Tournament fixtures should set ground_id and mirror '
  'the name here for display.';

create index if not exists matches_ground_time
  on public.matches (ground_id, scheduled_start_time)
  where ground_id is not null;

create index if not exists idx_matches_tournament_winner
  on public.matches (tournament_id, winner_id)
  where tournament_id is not null;

create index if not exists idx_matches_created_by
  on public.matches (created_by);

create index if not exists idx_matches_openers_submitted_by
  on public.matches (openers_submitted_by);

create index if not exists idx_matches_player_of_the_match_id
  on public.matches (player_of_the_match_id);

create index if not exists idx_matches_prev_match_a_id
  on public.matches (prev_match_a_id);

create index if not exists idx_matches_prev_match_b_id
  on public.matches (prev_match_b_id);

create index if not exists idx_matches_team_a_captain
  on public.matches (team_a_captain);

create index if not exists idx_matches_team_b_captain
  on public.matches (team_b_captain);

create index if not exists idx_matches_toss_won_by
  on public.matches (toss_won_by);

create index if not exists idx_matches_winner_id
  on public.matches (winner_id);
