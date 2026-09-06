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
--   • Scorer leases & concurrency guards (match_scorer_leases)
--   • Triggers for atomic state reduction, strike rotation, & lifecycle
--
-- 2026-09-06 schema consolidation. Every fact in this schema now has exactly
-- ONE column. The pairs that used to carry the same value under two names
-- (runs_off_bat/runs_scored, striker_id/batsman_id, format/rules_config,
-- completed_at/end_time, …) were written in lockstep by a single writer, so
-- they never disagreed — but nothing prevented it, and `total_runs` is
-- GENERATED from one side of two of those pairs. The alias columns are gone;
-- the canonical name is the one the Dart engine and record-ball already used.
-- match_batsman_stats / match_bowler_stats are gone too: nothing has written
-- them since the SQL scoring engine was removed, and scorecards are derived
-- client-side from the delivery ledger.
-- =============================================================================

-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.

-- -----------------------------------------------------------------------------
-- 1. Clean Drop of Legacy Objects (Clean Slate Initialization)
-- -----------------------------------------------------------------------------
drop view if exists public.balls cascade;
drop view if exists public.format_presets cascade;
drop table if exists public.match_result_history cascade;
drop table if exists public.match_scorer_leases cascade;
drop table if exists public.match_bowler_stats cascade;   -- removed 2026-09-06
drop table if exists public.match_batsman_stats cascade;  -- removed 2026-09-06
drop table if exists public.match_wickets cascade;
drop table if exists public.match_deliveries cascade;
drop table if exists public.match_innings_state cascade;
drop table if exists public.match_innings cascade;
drop table if exists public.match_players cascade;
drop table if exists public.match_teams cascade;
drop table if exists public.match_format_presets cascade;
drop table if exists public.matches cascade;

-- -----------------------------------------------------------------------------
-- 2. Format Catalog
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

create or replace view public.format_presets
  with (security_invoker = on) as
  select * from public.match_format_presets;

-- -----------------------------------------------------------------------------
-- 3. The canonical match-format shape
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
  -- reader and neither had a foreign key. One column, and it gets one below
  -- (as an ALTER, because match_players does not exist yet at this point).
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
  -- FKs added below as ALTERs: match_players is defined after this table.
  captain_player_id      uuid,
  keeper_player_id       uuid,
  created_at             timestamptz not null default now(),
  primary key (match_id, team_side)
);

-- -----------------------------------------------------------------------------
-- 5. Lineup Boundary (match_players)
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

  -- Exactly one of (user_id, unclaimed_id). Same shape as
  -- team_members.player_ref_xor so the two read identically.
  constraint chk_match_player_identity check (
    num_nonnulls(user_id, unclaimed_id) = 1
  ),
  unique(match_id, user_id),
  unique(match_id, unclaimed_id)
);

-- Deferred FK: the PoM is a participant in THIS match, so it points at
-- match_players (which is polymorphic over profiles/unclaimed_players) rather
-- than profiles. Declared here because match_players is defined after matches.
alter table public.matches
  add constraint matches_player_of_the_match_fkey
  foreign key (player_of_the_match_id)
  references public.match_players(match_player_id) on delete set null;

-- Same deferral for match_teams' two player slots. Both point at this match's
-- own lineup, so a player cannot be named captain or keeper of a match they
-- are not in.
alter table public.match_teams
  add constraint match_teams_captain_player_fkey
  foreign key (captain_player_id)
  references public.match_players(match_player_id) on delete set null;

alter table public.match_teams
  add constraint match_teams_keeper_player_fkey
  foreign key (keeper_player_id)
  references public.match_players(match_player_id) on delete set null;

-- -----------------------------------------------------------------------------
-- 6. Innings & Live Hot State
-- -----------------------------------------------------------------------------
create table public.match_innings (
  innings_id             uuid primary key default gen_random_uuid(),
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  innings_number         smallint not null check (innings_number between 1 and 4),
  batting_team_side      text not null check (batting_team_side in ('team_a', 'team_b')),
  bowling_team_side      text not null check (bowling_team_side in ('team_a', 'team_b')),
  
  overs_allocated        numeric(4,1) not null default 20.0,

  -- `match_innings` is the DEFINITION of an innings (who bats, how long, did
  -- it finish). Everything that changes ball to ball — target, is_declared,
  -- is_all_out, the on-field trio, the totals — lives on match_innings_state
  -- and ONLY there. Those three columns used to be restated here and written
  -- in the same statement as their state-row twins (start_innings wrote
  -- p_target into both), which is two rows that can disagree about whether an
  -- innings was declared.
  is_completed           boolean not null default false,

  start_time             timestamptz default now(),
  end_time               timestamptz,
  updated_at             timestamptz not null default now(),

  unique(match_id, innings_number),
  -- Redundant as a uniqueness claim (innings_id is already the PK), but it is
  -- the target match_innings_state's composite FK needs in order to pin its
  -- denormalized match_id / innings_number to this row's.
  unique(innings_id, match_id, innings_number)
);

-- The live hot row. Authoritative for every value that moves during play.
-- `match_id` and `innings_number` ARE duplicated from match_innings, and that
-- is deliberate: Supabase realtime filters on a column of the changed row, so
-- a client watching one match's score cannot join to get them. They are kept
-- honest by a COMPOSITE foreign key rather than by a trigger or by every
-- writer remembering to — the pair cannot drift from its parent because the
-- database will not accept a row where it has.
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
  ),

  -- match_id / innings_number must be THIS innings' match and number, not
  -- merely some valid match and some number in range.
  constraint match_innings_state_parent_fkey
    foreign key (innings_id, match_id, innings_number)
    references public.match_innings(innings_id, match_id, innings_number)
    on delete cascade
);

-- -----------------------------------------------------------------------------
-- 7. Deliveries & Dismissals Ledger
-- -----------------------------------------------------------------------------
create table public.match_deliveries (
  delivery_id            uuid primary key default gen_random_uuid(),
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  innings_number         integer not null default 1 check (innings_number between 1 and 4),

  seq                    integer not null check (seq >= 1),
  over_number            integer not null check (over_number >= 0),
  -- 0 is NOT a missing value here: the Dart engine encodes an illegal delivery
  -- as ball_in_over = 0 because a wide or no-ball does not advance the over
  -- (scoring_engine.dart: `isLegal ? (legalBallCount % ballsPerOver) + 1 : 0`,
  -- pinned by vectors.json). The old `between 0 and 6` failed to say that, and
  -- also hardcoded a six-ball over — wrong for The Hundred and for any custom
  -- balls_per_over. chk_delivery_ball_in_over below states the real rule.
  ball_in_over           smallint not null check (ball_in_over >= 0),
  is_legal_delivery      boolean not null,
  -- The enum, not the free-text twin. `ball_type` also meant something else
  -- entirely in matches.format ('leather' | 'tape' | 'tennis'), so the same
  -- name carried two vocabularies in one schema.
  delivery_type          public.delivery_kind not null default 'legal',

  -- total_runs is GENERATED from runs_off_bat + extra_runs. When the aliases
  -- runs_scored / extras existed, a writer populating the alias side left the
  -- generated total silently wrong with no constraint to catch it.
  runs_off_bat           smallint not null default 0 check (runs_off_bat between 0 and 7),
  extra_runs             smallint not null default 0 check (extra_runs between 0 and 10),
  total_runs             smallint not null generated always as (runs_off_bat + extra_runs) stored,
  
  is_boundary            boolean not null default false,
  is_four                boolean not null default false,
  is_six                 boolean not null default false,
  is_free_hit            boolean not null default false,
  is_wicket              boolean not null default false,
  wicket_type            public.wicket_kind,

  -- `batsman_id` was a third name for the striker and is gone.
  striker_id             uuid references public.match_players(match_player_id) on delete restrict,
  non_striker_id         uuid references public.match_players(match_player_id) on delete restrict,
  bowler_id              uuid references public.match_players(match_player_id) on delete restrict,
  fielder_id             uuid references public.match_players(match_player_id) on delete set null,

  pitch_x                numeric(5,2),
  pitch_y                numeric(5,2),
  shot_angle             numeric(5,2),
  shot_distance          numeric(5,2),
  shot_type              text,

  -- NO DEFAULT, deliberately. This is the whole point of the column: the
  -- offline scoring outbox generates the key once per delivery on-device and
  -- replays it until the server acknowledges. A server-side
  -- `default gen_random_uuid()::text` gave every retry a fresh key, so the
  -- unique index below could never fire and a retried ball was recorded twice.
  idempotency_key        text not null,
  is_undone              boolean not null default false,
  commentary             text,
  -- One actor, one timestamp. (Was also recorded as created_by / created_at,
  -- written with the identical values by the same statement.)
  recorded_by            uuid references public.profiles(user_id) on delete set null,
  recorded_at            timestamptz not null default now(),

  unique (innings_id, seq),
  unique (innings_id, idempotency_key),

  -- The invariant the old range check was reaching for: a legal delivery
  -- occupies a numbered slot in the over, an illegal one occupies none.
  constraint chk_delivery_ball_in_over check (
    (is_legal_delivery and ball_in_over >= 1)
    or (not is_legal_delivery and ball_in_over = 0)
  ),

  -- delivery_type and is_legal_delivery were free to contradict each other.
  -- Note this is NOT `delivery_type = 'legal'`: a bye and a leg-bye ARE legal
  -- deliveries that count towards the over (vectors.json, "bye 1: legal ball"),
  -- they just send their runs to extras. Only a wide or a no-ball is re-bowled.
  -- 'penalty' is left unconstrained — penalty runs are awarded between
  -- deliveries and the engine does not commit to a legality for them.
  constraint chk_delivery_type_legality check (
    case delivery_type
      when 'wide'    then is_legal_delivery = false
      when 'no_ball' then is_legal_delivery = false
      when 'legal'   then is_legal_delivery = true
      when 'bye'     then is_legal_delivery = true
      when 'leg_bye' then is_legal_delivery = true
      else true
    end
  )
);

-- security_invoker: a view defaults to running with its OWNER's privileges,
-- which means it reads straight past the RLS on match_deliveries. It is a
-- compatibility alias for a table whose rows are public today, so nothing
-- leaks right now — but the day match_deliveries gets a narrower read policy,
-- this view would quietly serve every row anyway. (Supabase advisor 0010.)
create or replace view public.balls
  with (security_invoker = on) as
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
-- 8. Scorer Leases
-- -----------------------------------------------------------------------------
-- match_batsman_stats and match_bowler_stats used to live here. Nothing has
-- written them since 20260822120000 removed the SQL scoring engine, and
-- nothing read them either: the Dart repository exposed getters that no
-- controller called. Scorecards are derived on the client from the delivery
-- ledger (scoring_rules.dart). Dropped 2026-09-06 rather than re-backed with
-- views, because a view would put cricket arithmetic back in SQL — which the
-- CLAUDE.md banner forbids: the rules live in the Dart engine only.

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
-- 9. Core Functions & Triggers
-- -----------------------------------------------------------------------------

-- Helper Predicates
create or replace function public._can_score_match(p_match_id uuid)
returns boolean
language sql
security definer
stable
-- SECURITY DEFINER without a pinned search_path is a privilege-escalation
-- vector: anything this body names unqualified could be resolved against a
-- schema the caller controls, and the function runs as the owner.
-- (Supabase advisor 0011.)
set search_path = public, pg_temp
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
-- That decision left match_batsman_stats and match_bowler_stats populated by
-- nothing. They were retained empty "pending a decision to drop them or back
-- them with views"; on 2026-09-06 the decision was made and they were dropped.
-- Scorecards are derived from the delivery ledger on the client
-- (see scoring_rules.dart), which is the only place the rules live.

-- -----------------------------------------------------------------------------
-- 10. Match Lifecycle RPCs
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
set search_path = public, pg_temp
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
set search_path = public, pg_temp
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
  -- The target lives on match_innings_state (below) and nowhere else.
  insert into public.match_innings (
    match_id, innings_number, batting_team_side, bowling_team_side
  ) values (
    p_match_id, p_innings_number, v_batting_side, v_bowling_side
  )
  on conflict (match_id, innings_number) do update set
    batting_team_side = excluded.batting_team_side,
    bowling_team_side = excluded.bowling_team_side
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
-- 11. RLS & Realtime Publication
-- -----------------------------------------------------------------------------
alter table public.matches enable row level security;
alter table public.match_teams enable row level security;
alter table public.match_players enable row level security;
alter table public.match_innings enable row level security;
alter table public.match_innings_state enable row level security;
alter table public.match_deliveries enable row level security;
alter table public.match_wickets enable row level security;
alter table public.match_scorer_leases enable row level security;
alter table public.match_result_history enable row level security;
alter table public.match_format_presets enable row level security;

-- Public Read Policies
drop policy if exists "matches_read_all" on public.matches;
create policy "matches_read_all" on public.matches for select
  to anon, authenticated
  using (true);

drop policy if exists "match_teams_read_all" on public.match_teams;
create policy "match_teams_read_all" on public.match_teams for select
  to anon, authenticated
  using (true);

drop policy if exists "match_players_read_all" on public.match_players;
create policy "match_players_read_all" on public.match_players for select
  to anon, authenticated
  using (true);

drop policy if exists "match_innings_read_all" on public.match_innings;
create policy "match_innings_read_all" on public.match_innings for select
  to anon, authenticated
  using (true);

drop policy if exists "match_innings_state_read_all" on public.match_innings_state;
create policy "match_innings_state_read_all" on public.match_innings_state for select
  to anon, authenticated
  using (true);

drop policy if exists "match_deliveries_read_all" on public.match_deliveries;
create policy "match_deliveries_read_all" on public.match_deliveries for select
  to anon, authenticated
  using (true);

drop policy if exists "match_wickets_read_all" on public.match_wickets;
create policy "match_wickets_read_all" on public.match_wickets for select
  to anon, authenticated
  using (true);

drop policy if exists "match_scorer_leases_read_all" on public.match_scorer_leases;
create policy "match_scorer_leases_read_all" on public.match_scorer_leases for select
  to anon, authenticated
  using (true);

-- match_result_history is the audit trail for result overrides, so it is
-- append-only from the app's point of view: readable by anyone who can read the
-- match it belongs to (scores are public), never writable through PostgREST.
-- The three tournament_* RPCs that append to it are SECURITY DEFINER and run
-- as the owner, so they bypass RLS and are unaffected by the absence of an
-- INSERT policy. RLS was simply never enabled on this table before 2026-09-06,
-- which left the entire override trail world-writable with the anon key.
drop policy if exists "match_result_history_read_all" on public.match_result_history;
create policy "match_result_history_read_all"
  on public.match_result_history for select
  to anon, authenticated
  using (true);

drop policy if exists "match_format_presets_read_all" on public.match_format_presets;
create policy "match_format_presets_read_all" on public.match_format_presets for select
  to anon, authenticated
  using (true);

-- Scorer Write Policies
drop policy if exists "match_deliveries_write_scorer" on public.match_deliveries;
create policy "match_deliveries_write_scorer" on public.match_deliveries for all to authenticated using (true);

drop policy if exists "match_wickets_write_scorer" on public.match_wickets;
create policy "match_wickets_write_scorer" on public.match_wickets for all to authenticated using (true);

drop policy if exists "match_innings_state_write_scorer" on public.match_innings_state;
create policy "match_innings_state_write_scorer" on public.match_innings_state for all to authenticated using (true);

-- Performance Indexes
create index if not exists idx_matches_status_time on public.matches(status, scheduled_start_time desc);
-- NOT indexed separately: the `unique (innings_id, seq)` constraint on
-- match_deliveries already provides a btree on exactly (innings_id, seq), and
-- Postgres scans an index backwards for `order by seq desc` at the same cost.
-- A second index on the same columns is pure write amplification on the
-- highest-volume table in the schema (Supabase advisor 0009_duplicate_index).
create index if not exists idx_match_players_user on public.match_players(user_id) where user_id is not null;
create index if not exists idx_match_players_unclaimed on public.match_players(unclaimed_id) where unclaimed_id is not null;
create index if not exists idx_match_players_match on public.match_players(match_id);

-- Every FK that gets followed on delete or joined on read. Postgres does not
-- index the referencing side of a foreign key for you, so without these a
-- `delete from matches` does a seq scan of the delivery ledger per row.
create index if not exists idx_deliveries_match on public.match_deliveries(match_id);
create index if not exists idx_deliveries_striker on public.match_deliveries(striker_id) where striker_id is not null;
create index if not exists idx_deliveries_bowler on public.match_deliveries(bowler_id) where bowler_id is not null;
create index if not exists idx_innings_match on public.match_innings(match_id);
create index if not exists idx_innings_state_match on public.match_innings_state(match_id);
create index if not exists idx_wickets_innings on public.match_wickets(innings_id);
create index if not exists idx_result_history_match on public.match_result_history(match_id, recorded_at desc);
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

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_match_deliveries_fielder_id
  on public.match_deliveries (fielder_id);
create index if not exists idx_match_deliveries_non_striker_id
  on public.match_deliveries (non_striker_id);
create index if not exists idx_match_deliveries_recorded_by
  on public.match_deliveries (recorded_by);
create index if not exists idx_match_innings_state_bowler_id
  on public.match_innings_state (bowler_id);
create index if not exists idx_match_innings_state_non_striker_id
  on public.match_innings_state (non_striker_id);
create index if not exists idx_match_innings_state_striker_id
  on public.match_innings_state (striker_id);
create index if not exists idx_match_result_history_recorded_by
  on public.match_result_history (recorded_by);
create index if not exists idx_match_scorer_leases_active_scorer_id
  on public.match_scorer_leases (active_scorer_id);
create index if not exists idx_match_teams_captain_player_id
  on public.match_teams (captain_player_id);
create index if not exists idx_match_teams_keeper_player_id
  on public.match_teams (keeper_player_id);
create index if not exists idx_match_teams_team_id
  on public.match_teams (team_id);
create index if not exists idx_match_wickets_assisted_fielder_id
  on public.match_wickets (assisted_fielder_id);
create index if not exists idx_match_wickets_credited_bowler_id
  on public.match_wickets (credited_bowler_id);
create index if not exists idx_match_wickets_player_out_id
  on public.match_wickets (player_out_id);
create index if not exists idx_match_wickets_primary_fielder_id
  on public.match_wickets (primary_fielder_id);
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
