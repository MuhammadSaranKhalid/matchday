-- =============================================================================
-- 0400 · matches — Canonical Match Domain & Robust Scoring Engine Schema
-- =============================================================================
-- Spec: docs/matches-schema-architecture.md
--
-- This is the single, canonical schema for:
--   • Fixtures & tournament containers (matches, match_teams)
--   • Polymorphic lineups (match_players)
--   • Innings & live hot state (match_innings, match_innings_state)
--   • Event ledger & dismissals (match_deliveries, match_wickets)
--   • Materialized scorecards (match_batsman_stats, match_bowler_stats)
--   • Scorer leases & concurrency guards (match_scorer_leases)
--   • Triggers for atomic state reduction, strike rotation, & lifecycle
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Domain Enums & Types
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.match_format as enum (
    't20', 'odi', 'test', 'the_hundred', 'custom_limited', 'pairs'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_type as enum (
    'friendly', 'tournament', 'practice', 'league'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_status as enum (
    'scheduled', 'toss', 'live', 'innings_break', 'super_over', 
    'completed', 'abandoned', 'tied', 'no_result', 'walkover'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.toss_decision as enum ('bat', 'bowl');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_stage as enum (
    'group', 'quarter_final', 'semi_final', 'final', 'playoff'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_start_phase as enum (
    'toss', 'lineup', 'ready', 'live'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.scoring_mode as enum (
    'live_ball_by_ball', 'post_match_scorecard'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.delivery_kind as enum (
    'legal', 'wide', 'no_ball', 'bye', 'leg_bye', 'penalty'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.wicket_kind as enum (
    'bowled', 'caught', 'caught_and_bowled', 'lbw', 'run_out', 
    'stumped', 'hit_wicket', 'retired_hurt', 'retired_out', 
    'obstructing_the_field', 'timed_out', 'handled_the_ball'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_role as enum (
    'captain', 'vice_captain', 'wicket_keeper', 'player', 'substitute'
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Clean Drop of Legacy Objects (Clean Slate Initialization)
-- -----------------------------------------------------------------------------
drop view if exists public.balls cascade;
drop view if exists public.format_presets cascade;
drop table if exists public.match_result_history cascade;
drop table if exists public.match_scorer_leases cascade;
drop table if exists public.match_bowler_stats cascade;
drop table if exists public.match_batsman_stats cascade;
drop table if exists public.match_wickets cascade;
drop table if exists public.match_deliveries cascade;
drop table if exists public.match_innings_state cascade;
drop table if exists public.match_innings cascade;
drop table if exists public.match_players cascade;
drop table if exists public.match_teams cascade;
drop table if exists public.match_format_presets cascade;
drop table if exists public.matches cascade;

-- -----------------------------------------------------------------------------
-- 3. Format Catalog
-- -----------------------------------------------------------------------------
create table public.match_format_presets (
  preset_id             uuid primary key default gen_random_uuid(),
  name                  text not null unique,
  match_format          public.match_format not null default 't20',
  description           text,
  rules_config          jsonb not null default '{}'::jsonb,
  is_active             boolean not null default true,
  created_at            timestamptz not null default now()
);

create or replace view public.format_presets as
  select * from public.match_format_presets;

-- -----------------------------------------------------------------------------
-- 4. Matches & Team Slots
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

  -- Scheduling, Geo & Venue
  venue                  text not null default 'Ground 1',
  ground_coordinates     point,
  scheduled_start_time   timestamptz not null default now(),
  actual_start_time      timestamptz,
  completed_at           timestamptz,
  end_time               timestamptz,

  -- Format & Rules Contract
  rules_config           jsonb not null default '{
    "max_overs": 20,
    "max_overs_per_bowler": 4,
    "balls_per_over": 6,
    "wide_runs": 1,
    "noball_runs": 1,
    "free_hit": true,
    "super_over_enabled": true,
    "dls_enabled": true
  }'::jsonb,
  format                 jsonb not null default '{}'::jsonb, -- alias for rules_config

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
  
  -- Result Snapshot
  result                 jsonb,
  result_summary         jsonb,
  player_of_the_match_id uuid,
  man_of_the_match       uuid,

  -- Team References
  team_a_id             uuid references public.teams(team_id) on delete set null,
  team_b_id             uuid references public.teams(team_id) on delete set null,
  team_a_captain        uuid references public.profiles(user_id) on delete set null,
  team_b_captain        uuid references public.profiles(user_id) on delete set null,

  created_by             uuid references public.profiles(user_id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create table public.match_teams (
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  team_id                uuid references public.teams(team_id) on delete set null,
  team_name              text not null,
  team_side              text not null check (team_side in ('team_a', 'team_b')),
  is_batting_first       boolean,
  captain_player_id      uuid,
  keeper_player_id       uuid,
  created_at             timestamptz not null default now(),
  primary key (match_id, team_side)
);

-- -----------------------------------------------------------------------------
-- 4. Lineup Boundary (match_players)
-- -----------------------------------------------------------------------------
create table public.match_players (
  match_player_id        uuid primary key default gen_random_uuid(),
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  team_side              text not null check (team_side in ('team_a', 'team_b')),
  
  user_id                uuid references public.profiles(user_id) on delete set null,
  unclaimed_id           uuid references public.unclaimed_players(unclaimed_id) on delete set null,
  
  display_name           text not null,
  jersey_number          smallint check (jersey_number is null or (jersey_number between 0 and 99)),
  role                   public.match_role not null default 'player',
  is_in_playing_xi       boolean not null default true,
  batting_order          smallint check (batting_order is null or (batting_order between 1 and 15)),

  created_at             timestamptz not null default now(),

  constraint chk_match_player_identity check (
    (user_id is not null and unclaimed_id is null) or 
    (user_id is null and unclaimed_id is not null)
  ),
  unique(match_id, user_id),
  unique(match_id, unclaimed_id)
);

-- -----------------------------------------------------------------------------
-- 5. Innings & Live Hot State
-- -----------------------------------------------------------------------------
create table public.match_innings (
  innings_id             uuid primary key default gen_random_uuid(),
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  innings_number         smallint not null check (innings_number between 1 and 4),
  batting_team_side      text not null check (batting_team_side in ('team_a', 'team_b')),
  bowling_team_side      text not null check (bowling_team_side in ('team_a', 'team_b')),
  
  overs_allocated        numeric(4,1) not null default 20.0,
  target_runs            integer check (target_runs is null or target_runs > 0),
  
  is_declared            boolean not null default false,
  is_all_out             boolean not null default false,
  is_completed           boolean not null default false,
  
  start_time             timestamptz default now(),
  end_time               timestamptz,
  updated_at             timestamptz not null default now(),

  unique(match_id, innings_number)
);

create table public.match_innings_state (
  innings_id             uuid primary key references public.match_innings(innings_id) on delete cascade,
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  innings_number         smallint not null default 1 check (innings_number between 1 and 4),
  
  striker_id             uuid references public.match_players(match_player_id) on delete restrict,
  non_striker_id         uuid references public.match_players(match_player_id) on delete restrict,
  bowler_id              uuid references public.match_players(match_player_id) on delete restrict,
  
  total_runs             integer not null default 0 check (total_runs >= 0),
  total_wickets          smallint not null default 0 check (total_wickets between 0 and 11),
  legal_ball_count       integer not null default 0 check (legal_ball_count >= 0),
  
  total_wides            integer not null default 0 check (total_wides >= 0),
  total_no_balls         integer not null default 0 check (total_no_balls >= 0),
  total_byes             integer not null default 0 check (total_byes >= 0),
  total_leg_byes         integer not null default 0 check (total_leg_byes >= 0),
  total_penalties        integer not null default 0 check (total_penalties >= 0),

  -- Aggregate of the five breakdown columns above. Generated rather than
  -- maintained separately so it can never drift from its parts. record-ball
  -- reads it into the engine's InningsState, and MatchInningsStateDto reads it
  -- off `returning *` — without it the client's extras column is always 0 and
  -- the parity oracle diverges on every extra.
  total_extras           integer not null generated always as (
                           total_wides + total_no_balls + total_byes
                           + total_leg_byes + total_penalties
                         ) stored,

  is_declared            boolean not null default false,
  is_all_out             boolean not null default false,
  target                 integer check (target is null or target > 0),

  is_free_hit_next       boolean not null default false,
  version                bigint not null default 0,
  updated_at             timestamptz not null default now(),

  constraint chk_state_distinct_batters check (
    striker_id is null or non_striker_id is null or striker_id <> non_striker_id
  )
);

-- -----------------------------------------------------------------------------
-- 6. Deliveries & Dismissals Ledger
-- -----------------------------------------------------------------------------
create table public.match_deliveries (
  delivery_id            uuid primary key default gen_random_uuid(),
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  innings_number         integer not null default 1 check (innings_number between 1 and 4),

  seq                    integer not null check (seq >= 1),
  over_number            integer not null check (over_number >= 0),
  ball_in_over           smallint not null check (ball_in_over between 0 and 6),
  is_legal_delivery      boolean not null,
  delivery_type          public.delivery_kind not null default 'legal',
  ball_type              text not null default 'legal',

  runs_off_bat           smallint not null default 0 check (runs_off_bat between 0 and 7),
  runs_scored            smallint not null default 0 check (runs_scored between 0 and 7),
  extra_runs             smallint not null default 0 check (extra_runs between 0 and 10),
  extras                 smallint not null default 0 check (extras between 0 and 10),
  total_runs             smallint not null generated always as (runs_off_bat + extra_runs) stored,
  
  is_boundary            boolean not null default false,
  is_four                boolean not null default false,
  is_six                 boolean not null default false,
  is_free_hit            boolean not null default false,
  is_wicket              boolean not null default false,
  wicket_type            public.wicket_kind,

  striker_id             uuid references public.match_players(match_player_id) on delete restrict,
  non_striker_id         uuid references public.match_players(match_player_id) on delete restrict,
  bowler_id              uuid references public.match_players(match_player_id) on delete restrict,
  batsman_id             uuid references public.match_players(match_player_id) on delete restrict,
  fielder_id             uuid references public.match_players(match_player_id) on delete set null,

  pitch_x                numeric(5,2),
  pitch_y                numeric(5,2),
  shot_angle             numeric(5,2),
  shot_distance          numeric(5,2),
  shot_type              text,

  idempotency_key        text not null default gen_random_uuid()::text,
  is_undone              boolean not null default false,
  commentary             text,
  recorded_by            uuid references public.profiles(user_id) on delete set null,
  created_by             uuid references public.profiles(user_id) on delete set null,
  recorded_at            timestamptz not null default now(),
  created_at             timestamptz not null default now(),

  unique (innings_id, seq),
  unique (innings_id, idempotency_key)
);

create or replace view public.balls as
  select * from public.match_deliveries;

create table public.match_wickets (
  wicket_id              uuid primary key default gen_random_uuid(),
  delivery_id            uuid not null unique references public.match_deliveries(delivery_id) on delete cascade,
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  
  player_out_id          uuid not null references public.match_players(match_player_id) on delete restrict,
  dismissal_kind         public.wicket_kind not null,
  
  is_bowler_credited     boolean not null default true,
  credited_bowler_id     uuid references public.match_players(match_player_id) on delete restrict,
  
  primary_fielder_id     uuid references public.match_players(match_player_id) on delete set null,
  assisted_fielder_id    uuid references public.match_players(match_player_id) on delete set null,
  
  fall_of_wicket_score   integer not null,
  fall_of_wicket_number  smallint not null check (fall_of_wicket_number between 1 and 11),
  fall_of_wicket_overs   numeric(4,1) not null,

  created_at             timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 7. Materialized Scorecards & Scorer Leases
-- -----------------------------------------------------------------------------
create table public.match_batsman_stats (
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  player_id              uuid not null references public.match_players(match_player_id) on delete cascade,
  batting_position       smallint,
  
  runs                   integer not null default 0 check (runs >= 0),
  balls_faced            integer not null default 0 check (balls_faced >= 0),
  dots                   integer not null default 0 check (dots >= 0),
  fours                  integer not null default 0 check (fours >= 0),
  sixes                  integer not null default 0 check (sixes >= 0),
  singles                integer not null default 0 check (singles >= 0),
  doubles                integer not null default 0 check (doubles >= 0),
  triples                integer not null default 0 check (triples >= 0),
  
  is_out                 boolean not null default false,
  dismissal_text         text,
  minutes_batted         integer,

  primary key (innings_id, player_id)
);

create table public.match_bowler_stats (
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  player_id              uuid not null references public.match_players(match_player_id) on delete cascade,
  bowling_position       smallint,
  
  legal_balls_bowled     integer not null default 0 check (legal_balls_bowled >= 0),
  maidens                smallint not null default 0 check (maidens >= 0),
  runs_conceded          integer not null default 0 check (runs_conceded >= 0),
  wickets                smallint not null default 0 check (wickets >= 0),
  wides_conceded         integer not null default 0 check (wides_conceded >= 0),
  no_balls_conceded      integer not null default 0 check (no_balls_conceded >= 0),
  dot_balls_bowled       integer not null default 0 check (dot_balls_bowled >= 0),

  primary key (innings_id, player_id)
);

create table public.match_scorer_leases (
  match_id               uuid primary key references public.matches(match_id) on delete cascade,
  active_scorer_id       uuid not null references public.profiles(user_id) on delete cascade,
  device_id              text not null,
  lease_acquired_at      timestamptz not null default now(),
  lease_expires_at       timestamptz not null default (now() + interval '5 minutes'),
  heartbeat_at           timestamptz not null default now()
);

create table public.match_result_history (
  history_id             uuid primary key default gen_random_uuid(),
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  previous_status        public.match_status not null,
  new_status             public.match_status not null,
  result_payload         jsonb not null,
  reason                 text,
  recorded_by            uuid references public.profiles(user_id) on delete set null,
  recorded_at            timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 8. Core Functions & Triggers
-- -----------------------------------------------------------------------------

-- Helper Predicates
create or replace function public._can_score_match(p_match_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.matches m
    where m.match_id = p_match_id
      and (
        m.created_by = auth.uid()
        or m.team_a_captain = auth.uid()
        or m.team_b_captain = auth.uid()
        or exists (
          select 1 from public.teams t
          where (t.team_id = m.team_a_id or t.team_id = m.team_b_id)
            and t.owner_id = auth.uid()
        )
        or exists (
          select 1 from public.team_members tm
          where tm.user_id = auth.uid()
            and tm.role in ('captain', 'vice_captain')
            and tm.status = 'active'
            and (tm.team_id = m.team_a_id or tm.team_id = m.team_b_id)
        )
      )
  );
$$;

create or replace function public._is_match_captain(p_match_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.matches m
    where m.match_id = p_match_id
      and (
        m.created_by = auth.uid()
        or m.team_a_captain = auth.uid()
        or m.team_b_captain = auth.uid()
      )
  );
$$;

-- -----------------------------------------------------------------------------
-- 8b. Who may score which innings  (design doc D12)
-- -----------------------------------------------------------------------------
-- The BATTING side scores its own innings; control passes at the innings break.
-- Odd innings belong to whoever batted first (derived from the toss), even
-- innings to the other side. Tournament organisers and the creator of a
-- practice match may score either side.
--
-- record-ball calls this as its writer check. It takes the innings number
-- precisely so it can answer "may you score THIS innings" rather than the
-- weaker "may you score this match" — that distinction is the whole of the
-- single-writer property the local-first design rests on.
create or replace function public._can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with m as (
    select * from public.matches where match_id = p_match_id
  ),
  sides as (
    select
      m.*,
      -- The team batting first: the toss winner if they chose to bat,
      -- otherwise the other team. Falls back to team_a before the toss.
      case
        when m.toss_won_by is null or m.toss_decision is null then m.team_a_id
        when m.toss_decision = 'bat' then m.toss_won_by
        when m.toss_won_by = m.team_a_id then m.team_b_id
        else m.team_a_id
      end as bats_first
    from m
  ),
  batting as (
    select
      sides.*,
      case
        when p_innings_number % 2 = 1 then sides.bats_first
        when sides.bats_first = sides.team_a_id then sides.team_b_id
        else sides.team_a_id
      end as batting_team_id
    from sides
  )
  select exists (
    select 1 from batting b
    where
      -- Practice matches have no opposition to hand over to.
      (b.match_type = 'practice' and b.created_by = auth.uid())
      -- The captain of the batting side.
      or (b.batting_team_id = b.team_a_id and b.team_a_captain = auth.uid())
      or (b.batting_team_id = b.team_b_id and b.team_b_captain = auth.uid())
      -- Whoever owns the batting team.
      or exists (
        select 1 from public.teams t
        where t.team_id = b.batting_team_id
          and t.owner_id = auth.uid()
      )
      -- A captain / vice-captain on the batting team's roster.
      or exists (
        select 1 from public.team_members tm
        where tm.team_id = b.batting_team_id
          and tm.user_id = auth.uid()
          and tm.role in ('captain', 'vice_captain')
          and tm.status = 'active'
      )
  );
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;
grant execute on function public._can_score_innings(uuid, integer) to authenticated, service_role;

-- can_score_innings is the client-facing gate. It MUST delegate to the same
-- predicate record-ball enforces — two definitions of "may you score" is how
-- the UI and the write path drifted apart last time.
create or replace function public.can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select public._can_score_innings(p_match_id, p_innings_number);
$$;

-- -----------------------------------------------------------------------------
-- 8c. NO SCORING TRIGGER.  (design doc D10 · CLAUDE.md exemption 2)
-- -----------------------------------------------------------------------------
-- `fn_process_delivery` used to live here: it reduced each inserted delivery
-- into match_innings_state — running totals, strike rotation, over completion,
-- free-hit derivation — and upserted the materialised batting/bowling cards.
--
-- It is GONE, deliberately. The rules of cricket now live in exactly one place,
-- the Dart engine on the scoring device, because that device has to compute an
-- innings unaided while it has no signal. A second implementation here could
-- only ever agree or silently disagree, and it did the latter: it rotated
-- strike on `runs_off_bat % 2` (so runs run off a no-ball never changed ends),
-- hardcoded a six-ball over, never incremented `total_wickets`, and never
-- cleared `bowler_id` at the end of an over.
--
-- record-ball now writes match_innings_state itself: aggregate columns are
-- SUMMED from match_deliveries (D13 — derive, never accumulate, which is what
-- makes undo "delete the last row and re-total"), and the on-field trio comes
-- from the engine that computed the delivery.
--
-- 🟥 DO NOT reintroduce scoring arithmetic in SQL. If a scorecard number looks
-- wrong, the fix belongs in the Dart engine and its vectors.
--
-- Consequence to be aware of: match_batsman_stats and match_bowler_stats are no
-- longer populated by anything. Scorecards are derived from the delivery ledger
-- on the client (see scoring_rules.dart). Those two tables are retained but
-- empty pending a decision to drop them or to back them with views.

-- -----------------------------------------------------------------------------
-- 9. Match Lifecycle RPCs
-- -----------------------------------------------------------------------------

create or replace function public.record_match_toss(
  p_match_id uuid,
  p_won_by uuid,
  p_decision public.toss_decision,
  p_face char default null
)
returns void
language plpgsql
security definer
as $$
begin
  if not public._is_match_captain(p_match_id) then
    raise exception 'Only team captains can record the toss' using errcode = '42501';
  end if;

  update public.matches
  set
    toss_won_by = p_won_by,
    toss_decision = p_decision,
    toss_face = p_face,
    toss_recorded_at = now(),
    start_phase = 'lineup',
    status = 'toss',
    updated_at = now()
  where match_id = p_match_id;
end;
$$;

create or replace function public.submit_match_openers(
  p_match_id uuid,
  p_striker_id uuid,
  p_non_striker_id uuid
)
returns void
language plpgsql
security definer
as $$
declare
  v_innings_id uuid;
begin
  if not public._is_match_captain(p_match_id) then
    raise exception 'Only team captains can submit openers' using errcode = '42501';
  end if;

  update public.matches
  set
    start_phase = 'ready',
    openers_submitted_by = auth.uid(),
    openers_submitted_at = now(),
    updated_at = now()
  where match_id = p_match_id;

  -- Ensure match_innings row exists
  insert into public.match_innings (
    match_id, innings_number, batting_team_side, bowling_team_side
  ) values (
    p_match_id, 1, 'team_a', 'team_b'
  )
  on conflict (match_id, innings_number) do update set updated_at = now()
  returning innings_id into v_innings_id;

  -- Ensure match_innings_state has openers
  insert into public.match_innings_state (
    innings_id, match_id, innings_number, striker_id, non_striker_id
  ) values (
    v_innings_id, p_match_id, 1, p_striker_id, p_non_striker_id
  )
  on conflict (innings_id) do update set
    striker_id = p_striker_id,
    non_striker_id = p_non_striker_id,
    version = match_innings_state.version + 1,
    updated_at = now();
end;
$$;

create or replace function public.start_match_now(p_match_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  if not public._is_match_captain(p_match_id) then
    raise exception 'Only team captains can start the match' using errcode = '42501';
  end if;

  update public.matches
  set
    status = 'live',
    start_phase = 'live',
    actual_start_time = now(),
    updated_at = now()
  where match_id = p_match_id;
end;
$$;

create or replace function public.start_innings(
  p_match_id uuid,
  p_innings_number integer,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_bowler_id uuid,
  p_target integer default null
)
returns void
language plpgsql
security definer
as $$
declare
  v_innings_id uuid;
  v_batting_side text := case when p_innings_number % 2 = 1 then 'team_a' else 'team_b' end;
  v_bowling_side text := case when p_innings_number % 2 = 1 then 'team_b' else 'team_a' end;
begin
  insert into public.match_innings (
    match_id, innings_number, batting_team_side, bowling_team_side, target_runs
  ) values (
    p_match_id, p_innings_number, v_batting_side, v_bowling_side, p_target
  )
  on conflict (match_id, innings_number) do update set
    target_runs = coalesce(excluded.target_runs, match_innings.target_runs)
  returning innings_id into v_innings_id;

  insert into public.match_innings_state (
    innings_id, match_id, innings_number, striker_id, non_striker_id, bowler_id, target
  ) values (
    v_innings_id, p_match_id, p_innings_number, p_striker_id, p_non_striker_id, p_bowler_id, p_target
  )
  on conflict (innings_id) do update set
    striker_id = p_striker_id,
    non_striker_id = p_non_striker_id,
    bowler_id = p_bowler_id,
    target = coalesce(excluded.target, match_innings_state.target),
    version = match_innings_state.version + 1,
    updated_at = now();

  update public.matches
  set status = 'live', updated_at = now()
  where match_id = p_match_id;
end;
$$;

create or replace function public.list_my_matches()
returns setof public.matches
language sql
security definer
stable
as $$
  select * from public.matches m
  where m.created_by = auth.uid()
     or m.team_a_captain = auth.uid()
     or m.team_b_captain = auth.uid()
     or exists (
       select 1 from public.team_members tm
       where tm.user_id = auth.uid()
         and (tm.team_id = m.team_a_id or tm.team_id = m.team_b_id)
     )
  order by m.scheduled_start_time desc;
$$;

-- -----------------------------------------------------------------------------
-- 10. RLS & Realtime Publication
-- -----------------------------------------------------------------------------
alter table public.matches enable row level security;
alter table public.match_teams enable row level security;
alter table public.match_players enable row level security;
alter table public.match_innings enable row level security;
alter table public.match_innings_state enable row level security;
alter table public.match_deliveries enable row level security;
alter table public.match_wickets enable row level security;
alter table public.match_batsman_stats enable row level security;
alter table public.match_bowler_stats enable row level security;
alter table public.match_scorer_leases enable row level security;
alter table public.match_format_presets enable row level security;

-- Public Read Policies
drop policy if exists "matches_read_all" on public.matches;
create policy "matches_read_all" on public.matches for select using (true);

drop policy if exists "match_teams_read_all" on public.match_teams;
create policy "match_teams_read_all" on public.match_teams for select using (true);

drop policy if exists "match_players_read_all" on public.match_players;
create policy "match_players_read_all" on public.match_players for select using (true);

drop policy if exists "match_innings_read_all" on public.match_innings;
create policy "match_innings_read_all" on public.match_innings for select using (true);

drop policy if exists "match_innings_state_read_all" on public.match_innings_state;
create policy "match_innings_state_read_all" on public.match_innings_state for select using (true);

drop policy if exists "match_deliveries_read_all" on public.match_deliveries;
create policy "match_deliveries_read_all" on public.match_deliveries for select using (true);

drop policy if exists "match_wickets_read_all" on public.match_wickets;
create policy "match_wickets_read_all" on public.match_wickets for select using (true);

drop policy if exists "match_batsman_stats_read_all" on public.match_batsman_stats;
create policy "match_batsman_stats_read_all" on public.match_batsman_stats for select using (true);

drop policy if exists "match_bowler_stats_read_all" on public.match_bowler_stats;
create policy "match_bowler_stats_read_all" on public.match_bowler_stats for select using (true);

drop policy if exists "match_scorer_leases_read_all" on public.match_scorer_leases;
create policy "match_scorer_leases_read_all" on public.match_scorer_leases for select using (true);

drop policy if exists "match_format_presets_read_all" on public.match_format_presets;
create policy "match_format_presets_read_all" on public.match_format_presets for select using (true);

-- Scorer Write Policies
drop policy if exists "match_deliveries_write_scorer" on public.match_deliveries;
create policy "match_deliveries_write_scorer" on public.match_deliveries for all to authenticated using (true);

drop policy if exists "match_wickets_write_scorer" on public.match_wickets;
create policy "match_wickets_write_scorer" on public.match_wickets for all to authenticated using (true);

drop policy if exists "match_innings_state_write_scorer" on public.match_innings_state;
create policy "match_innings_state_write_scorer" on public.match_innings_state for all to authenticated using (true);

-- Performance Indexes
create index if not exists idx_matches_status_time on public.matches(status, scheduled_start_time desc);
create index if not exists idx_deliveries_innings_seq on public.match_deliveries(innings_id, seq desc);
create index if not exists idx_match_players_user on public.match_players(user_id) where user_id is not null;
create index if not exists idx_match_players_unclaimed on public.match_players(unclaimed_id) where unclaimed_id is not null;
