-- =============================================================================
-- 0822b · Carry the 0400 scoring changes forward onto an existing database
-- =============================================================================
-- 20260101000400 was rewritten in place on 2026-08-22 (total_extras, dropping
-- the scoring trigger, adding _can_score_innings). Supabase records migrations
-- by VERSION, not by content, so that file is already marked applied and will
-- never re-run — and re-running it is not an option either: it opens with
-- `drop table ... cascade` on every match table.
--
-- This migration is that same set of changes expressed forward-only, so a
-- database built from the old 0400 arrives at the same place as one built fresh
-- from the new one. It is idempotent; running it twice changes nothing.
--
-- See docs/offline-scoring-design.md D10/D11/D13 for why the SQL engine goes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. total_extras — a derived aggregate, not a maintained counter
-- -----------------------------------------------------------------------------
-- record-ball reads this into the engine's InningsState and the Flutter DTO
-- reads it back off `returning *`. Without it the edge function's SELECT fails
-- outright ("column total_extras does not exist") and no delivery can be
-- recorded at all.
-- match_innings_state.total_extras is declared inline in
-- 20260101000400_matches.sql (folded there 2026-09-06).

-- -----------------------------------------------------------------------------
-- 2. Remove the SQL scoring engine
-- -----------------------------------------------------------------------------
-- fn_process_delivery reduced each inserted delivery into match_innings_state —
-- running totals, strike rotation, over completion, free-hit derivation — and
-- upserted the materialised batting/bowling cards. It was a second (third,
-- counting the edge function's) implementation of the rules of cricket, and it
-- disagreed with the others: it rotated strike on `runs_off_bat % 2` so runs run
-- off a no-ball never changed ends, hardcoded a six-ball over, never
-- incremented total_wickets, and never cleared bowler_id at the end of an over.
-- It also bumped `version` alongside record-ball's own bump, advancing the row
-- by 2 per delivery while the client projected 1 — which refused the second of
-- any two quick taps.
--
-- 🟥 DO NOT reintroduce scoring arithmetic in SQL. The rules live in the Dart
-- engine, specified by _shared/scoring/vectors.json.
--
-- Consequence: match_batsman_stats and match_bowler_stats are no longer
-- populated by anything. Scorecards are derived from the delivery ledger on the
-- client. Both tables are retained but will stop growing.
drop trigger if exists trg_delivery_insert on public.match_deliveries;
drop function if exists public.fn_process_delivery();

-- -----------------------------------------------------------------------------
-- 3. Who may score which innings  (design doc D12)
-- -----------------------------------------------------------------------------
-- Called by record-ball and undo_last_ball, and referenced by start_innings.
-- It has never existed on this database: the edge function called it and got
-- "function does not exist", which surfaced as a 500 on every delivery.
--
-- The BATTING side scores its own innings; control passes at the innings break.
-- Odd innings belong to whoever batted first (derived from the toss), even
-- innings to the other side.
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
      (b.match_type = 'practice' and b.created_by = auth.uid())
      or (b.batting_team_id = b.team_a_id and b.team_a_captain = auth.uid())
      or (b.batting_team_id = b.team_b_id and b.team_b_captain = auth.uid())
      -- Rewritten 2026-09-11 (docs/team-roles-design.md). Scoring is no longer
      -- a special case: BOTH branches are the same engine, asked about two
      -- different entities. That is exactly why `match.score` is registered in
      -- permission_scopes at 'team' AND 'match'.
      --
      --   team scope  → you hold match.score through a role on the batting side
      --   match scope → you were handed it for THIS match (a nominated scorer,
      --                 mirrored in from match_officials)
      or public.can('team',  b.batting_team_id, 'match.score')
      or public.can('match', b.match_id,        'match.score')
  );
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;
grant execute on function public._can_score_innings(uuid, integer) to authenticated, service_role;

-- The client-facing gate MUST delegate to the same predicate the write path
-- enforces. It previously ignored p_innings_number entirely and answered the
-- weaker "may you score this match", so both captains could write to either
-- innings — the single-writer property the local-first design rests on.
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
