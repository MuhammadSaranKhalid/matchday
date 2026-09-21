-- =============================================================================
-- Migration: 20260101000407_cricket_match_deliveries.sql
-- =============================================================================

-- 0407 · cricket_match_deliveries
-- The delivery ledger and its compatibility view.
-- Spec: docs/matches-schema-architecture.md
-- Deliveries & Dismissals Ledger

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.cricket_match_deliveries (
  delivery_id       uuid primary key default gen_random_uuid(),
  innings_id        uuid not null
    references public.cricket_match_innings (innings_id)
    on delete cascade,
  match_id          uuid not null
    references public.matches (match_id)
    on delete cascade,
  innings_number    integer not null default 1 check (innings_number between 1 and 4),
  seq               integer not null check (seq >= 1),
  over_number       integer not null check (over_number >= 0),
  -- 0 is NOT a missing value here: the Dart engine encodes an illegal delivery
  -- as ball_in_over = 0 because a wide or no-ball does not advance the over
  -- (scoring_engine.dart: `isLegal ? (legalBallCount % ballsPerOver) + 1 : 0`,
  -- pinned by vectors.json). The old `between 0 and 6` failed to say that, and
  -- also hardcoded a six-ball over — wrong for The Hundred and for any custom
  -- balls_per_over. chk_delivery_ball_in_over below states the real rule.
  ball_in_over      smallint not null check (ball_in_over >= 0),
  is_legal_delivery boolean not null,
  -- The enum, not the free-text twin. `ball_type` also meant something else
  -- entirely in matches.format ('leather' | 'tape' | 'tennis'), so the same
  -- name carried two vocabularies in one schema.
  delivery_type     public.cricket_delivery_kind not null default 'legal',
  -- total_runs is GENERATED from runs_off_bat + extra_runs. When the aliases
  -- runs_scored / extras existed, a writer populating the alias side left the
  -- generated total silently wrong with no constraint to catch it.
  runs_off_bat      smallint not null default 0 check (runs_off_bat between 0 and 7),
  extra_runs        smallint not null default 0 check (extra_runs between 0 and 10),
  total_runs        smallint not null generated always as (runs_off_bat + extra_runs) stored,
  is_boundary       boolean not null default false,
  is_four           boolean not null default false,
  is_six            boolean not null default false,
  is_free_hit       boolean not null default false,
  is_wicket         boolean not null default false,
  wicket_type       public.cricket_wicket_kind,
  -- `batsman_id` was a third name for the striker and is gone.
  striker_id        uuid
    references public.match_players (match_player_id)
    on delete restrict,
  non_striker_id    uuid
    references public.match_players (match_player_id)
    on delete restrict,
  bowler_id         uuid
    references public.match_players (match_player_id)
    on delete restrict,
  fielder_id        uuid
    references public.match_players (match_player_id)
    on delete set null,
  pitch_x           numeric(5, 2),
  pitch_y           numeric(5, 2),
  shot_angle        numeric(5, 2),
  shot_distance     numeric(5, 2),
  shot_type         text,
  -- NO DEFAULT, deliberately. This is the whole point of the column: the
  -- offline scoring outbox generates the key once per delivery on-device and
  -- replays it until the server acknowledges. A server-side
  -- `default gen_random_uuid()::text` gave every retry a fresh key, so the
  -- unique index below could never fire and a retried ball was recorded twice.
  idempotency_key   text not null,
  is_undone         boolean not null default false,
  commentary        text,
  -- One actor, one timestamp. (Was also recorded as created_by / created_at,
  -- written with the identical values by the same statement.)
  recorded_by       uuid
    references public.profiles (user_id)
    on delete set null,
  recorded_at       timestamptz not null default now(),
  unique (innings_id, seq),
  unique (innings_id, idempotency_key),
  -- The invariant the old range check was reaching for: a legal delivery
  -- occupies a numbered slot in the over, an illegal one occupies none.
  constraint chk_delivery_ball_in_over
    check (
      (is_legal_delivery and ball_in_over >= 1)
      or (not is_legal_delivery and ball_in_over = 0)
    ),
  -- delivery_type and is_legal_delivery were free to contradict each other.
  -- Note this is NOT `delivery_type = 'legal'`: a bye and a leg-bye ARE legal
  -- deliveries that count towards the over (vectors.json, "bye 1: legal ball"),
  -- they just send their runs to extras. Only a wide or a no-ball is re-bowled.
  -- 'penalty' is left unconstrained — penalty runs are awarded between
  -- deliveries and the engine does not commit to a legality for them.
  constraint chk_delivery_type_legality
    check (
      case delivery_type
        when 'wide' then is_legal_delivery = false
        when 'no_ball' then is_legal_delivery = false
        when 'legal' then is_legal_delivery = true
        when 'bye' then is_legal_delivery = true
        when 'leg_bye' then is_legal_delivery = true
        else true
      end
    )
);

-- -----------------------------------------------------------------------------
-- Views
-- -----------------------------------------------------------------------------

-- security_invoker: a view defaults to running with its OWNER's privileges,
-- which means it reads straight past the RLS on cricket_match_deliveries. It is a
-- compatibility alias for a table whose rows are public today, so nothing
-- leaks right now — but the day cricket_match_deliveries gets a narrower read policy,
-- this view would quietly serve every row anyway. (Supabase advisor 0010.)
create or replace view public.balls
with (security_invoker = on)
as
  select
    *
  from public.cricket_match_deliveries;

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.cricket_match_deliveries enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

drop policy if exists "cricket_match_deliveries_read_all" on public.cricket_match_deliveries;

create policy "cricket_match_deliveries_read_all"
  on public.cricket_match_deliveries
  for select
  to anon, authenticated
  using (true);

-- Scorer Write Policies
drop policy if exists "cricket_match_deliveries_write_scorer" on public.cricket_match_deliveries;

create policy "cricket_match_deliveries_write_scorer"
  on public.cricket_match_deliveries
  for all
  to authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- Every FK that gets followed on delete or joined on read. Postgres does not
-- index the referencing side of a foreign key for you, so without these a
-- `delete from matches` does a seq scan of the delivery ledger per row.
create index if not exists idx_deliveries_match
  on public.cricket_match_deliveries (
    match_id
  );

create index if not exists idx_deliveries_striker
  on public.cricket_match_deliveries (
    striker_id
  )
  where striker_id is not null;

create index if not exists idx_deliveries_bowler
  on public.cricket_match_deliveries (
    bowler_id
  )
  where bowler_id is not null;

-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.
create index if not exists idx_cricket_match_deliveries_fielder_id
  on public.cricket_match_deliveries (
    fielder_id
  );

create index if not exists idx_cricket_match_deliveries_non_striker_id
  on public.cricket_match_deliveries (
    non_striker_id
  );

create index if not exists idx_cricket_match_deliveries_recorded_by
  on public.cricket_match_deliveries (
    recorded_by
  );

-- The unique (innings_id, seq) constraint already provides the ledger-order
-- index, including backward scans. Do not add a duplicate index on that pair.
comment on table public.cricket_match_deliveries is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_deliveries.';
