-- Migration file: 20260101000406_cricket_match_innings_state.sql

-- 0406 · cricket_match_innings_state
-- Live innings totals and the on-field players.
-- Spec: docs/matches-schema-architecture.md

-- Section: Tables and constraints

drop table if exists public.cricket_match_innings_state cascade;

-- The live hot row. Authoritative for every value that moves during play.
-- `match_id` and `innings_number` ARE duplicated from cricket_match_innings, and that
-- is deliberate: Supabase realtime filters on a column of the changed row, so
-- a client watching one match's score cannot join to get them. They are kept
-- honest by a COMPOSITE foreign key rather than by a trigger or by every
-- writer remembering to — the pair cannot drift from its parent because the
-- database will not accept a row where it has.
create table public.cricket_match_innings_state(
  innings_id       uuid primary key references public.cricket_match_innings(innings_id) on delete cascade,
  match_id         uuid not null references public.matches(match_id) on delete cascade,
  innings_number   smallint not null default 1 check (innings_number between 1 and 4),
  striker_id       uuid references public.match_players(match_player_id) on delete restrict,
  non_striker_id   uuid references public.match_players(match_player_id) on delete restrict,
  bowler_id        uuid references public.match_players(match_player_id) on delete restrict,
  total_runs       integer not null default 0 check (total_runs >= 0),
  total_wickets    smallint not null default 0 check (total_wickets between 0 and 11),
  legal_ball_count integer not null default 0 check (legal_ball_count >= 0),
  total_wides      integer not null default 0 check (total_wides >= 0),
  total_no_balls   integer not null default 0 check (total_no_balls >= 0),
  total_byes       integer not null default 0 check (total_byes >= 0),
  total_leg_byes   integer not null default 0 check (total_leg_byes >= 0),
  total_penalties  integer not null default 0 check (total_penalties >= 0),
  -- Aggregate of the five breakdown columns above. Generated rather than
  -- maintained separately so it can never drift from its parts. record-ball
  -- reads it into the engine's InningsState, and MatchInningsStateDto reads it
  -- off `returning *` — without it the client's extras column is always 0 and
  -- the parity oracle diverges on every extra.
  total_extras     integer not null generated always as (total_wides + total_no_balls + total_byes + total_leg_byes + total_penalties) stored,
  is_declared      boolean not null default false,
  is_all_out       boolean not null default false,
  target           integer check (target is null or target > 0),
  is_free_hit_next boolean not null default false,
  version          bigint not null default 0,
  updated_at       timestamptz not null default now(),
  constraint chk_state_distinct_batters check (striker_id is null or non_striker_id is null or striker_id <> non_striker_id),
  -- match_id / innings_number must be THIS innings' match and number, not
  -- merely some valid match and some number in range.
  constraint cricket_match_innings_state_parent_fkey foreign key (innings_id, match_id, innings_number) references public.cricket_match_innings(innings_id, match_id, innings_number) on delete cascade
);

-- Section: Enable row-level security

alter table public.cricket_match_innings_state enable row level security;

-- Section: Policies

drop policy if exists "cricket_match_innings_state_read_all" on public.cricket_match_innings_state;

create policy "cricket_match_innings_state_read_all" on public.cricket_match_innings_state
  for select to anon, authenticated
  using (true);

drop policy if exists "cricket_match_innings_state_write_scorer" on public.cricket_match_innings_state;

create policy "cricket_match_innings_state_write_scorer" on public.cricket_match_innings_state
  for all to authenticated
  using (true);

-- Section: Indexes

create index if not exists idx_innings_state_match on public.cricket_match_innings_state(match_id);

create index if not exists idx_cricket_match_innings_state_bowler_id on public.cricket_match_innings_state(bowler_id);

create index if not exists idx_cricket_match_innings_state_non_striker_id on public.cricket_match_innings_state(non_striker_id);

create index if not exists idx_cricket_match_innings_state_striker_id on public.cricket_match_innings_state(striker_id);

comment on table public.cricket_match_innings_state is 'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_innings_state.';
