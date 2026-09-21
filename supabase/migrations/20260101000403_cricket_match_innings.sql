-- Migration file: 20260101000403_cricket_match_innings.sql

-- 0403 · cricket_match_innings
-- Innings definitions and their allocation/completion state.
-- Spec: docs/matches-schema-architecture.md
-- Innings & Live Hot State

-- Section: Tables and constraints

create table public.cricket_match_innings(
  innings_id        uuid primary key default gen_random_uuid(),
  match_id          uuid not null references public.matches(match_id) on delete cascade,
  innings_number    smallint not null check (innings_number between 1 and 4),
  batting_team_side text not null check (batting_team_side in ('team_a', 'team_b')),
  bowling_team_side text not null check (bowling_team_side in ('team_a', 'team_b')),
  overs_allocated   numeric(4, 1) not null default 20.0,
  -- `cricket_match_innings` is the DEFINITION of an innings (who bats, how long, did
  -- it finish). Everything that changes ball to ball — target, is_declared,
  -- is_all_out, the on-field trio, the totals — lives on cricket_match_innings_state
  -- and ONLY there. Those three columns used to be restated here and written
  -- in the same statement as their state-row twins (start_innings wrote
  -- p_target into both), which is two rows that can disagree about whether an
  -- innings was declared.
  is_completed      boolean not null default false,
  start_time        timestamptz default now(),
  end_time          timestamptz,
  updated_at        timestamptz not null default now(),
  unique (match_id, innings_number),
  -- Redundant as a uniqueness claim (innings_id is already the PK), but it is
  -- the target cricket_match_innings_state's composite FK needs in order to pin its
  -- denormalized match_id / innings_number to this row's.
  unique (innings_id, match_id, innings_number)
);

-- Section: Enable row-level security

alter table public.cricket_match_innings enable row level security;

-- Section: Policies

drop policy if exists "cricket_match_innings_read_all" on public.cricket_match_innings;

create policy "cricket_match_innings_read_all" on public.cricket_match_innings
  for select to anon, authenticated
  using (true);

-- Section: Indexes

create index if not exists idx_innings_match on public.cricket_match_innings(match_id);

-- Section: Tables and constraints (continued)

-- Make the innings engine structurally Cricket-only
--
-- We intentionally keep the current public table names in Phase 1 so no
-- scoring caller breaks. This additional FK means an innings cannot belong to
-- Football or another sport even though the table still has a legacy generic
-- name.
alter table public.cricket_match_innings
  add constraint cricket_match_innings_cricket_match_fkey foreign key (match_id) references public.cricket_matches(match_id) on delete cascade;

comment on table public.cricket_match_innings is 'CRICKET ENGINE TABLE (legacy generic name). Every row is constrained to '
  'a cricket_matches parent. Planned rename: cricket_match_innings.';
