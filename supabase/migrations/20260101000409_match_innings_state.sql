-- =============================================================================
-- 0409 · match_innings_state
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- The hot row for live scoring. One row per (match_id, innings_number).
-- Holds the on-field trio (striker, non-striker, bowler) plus the running
-- totals (legal balls bowled, runs, wickets, extras) for that innings.
--
-- WHY IT IS A SEPARATE TABLE (and not columns on matches)
-- -------------------------------------------------------
-- The previous design kept current_innings, current_striker_id,
-- current_non_striker_id, current_bowler_id ON THE matches ROW. Every
-- delivery rewrote that row. The matches row is ALSO the row every
-- scoreboard, fixture list, profile page, and notification join reads
-- from. So every ball forced lock contention between a single scorer and
-- every passive reader of the match.
--
-- Splitting them gives the live state its own row to fight over and
-- leaves the matches metadata row alone. Add the two facts that the new
-- shape makes possible — per-innings persistence (innings 1's totals
-- survive when innings 2 starts) and a denormalised legal_ball_count
-- (kills the per-ball SELECT SUM scan over balls) — and the cost shape of
-- live scoring changes from "linear in ball count" to "constant".
--
-- POLYMORPHISM CHAIN
-- ------------------
-- striker_id / non_striker_id / bowler_id all reference
-- match_players.match_player_id, NOT profiles.user_id. That is the whole
-- point of match_players (0405) — it is the single place where the
-- polymorphic "profile or unclaimed" decision is resolved. Once a player
-- is a match_player_id, every downstream table (this one, balls) can hold
-- a single clean uuid and stop caring whether the player was claimed.
--
-- An unclaimed local-club player can therefore take strike, bowl, or be
-- the non-striker — something the old schema rejected at the FK layer.
--
-- OPTIMISTIC CONCURRENCY (`version`)
-- ----------------------------------
-- Two scorers may share a match (RLS allows it; the captain plus the
-- second-team scorer for tournament matches; co-scorers in club games).
-- Without serialisation they can both think the score is "120/4" and both
-- post the next delivery, double-counting it.
--
-- The `version` column on this table is an optimistic-lock counter.
-- record_ball (0410) takes the client's last-seen version and writes
--    UPDATE match_innings_state SET ... , version = version + 1
--    WHERE match_id = ? AND innings_number = ? AND version = $client
-- The second scorer's UPDATE matches zero rows and the RPC raises a
-- 40001 (serialization_failure); the client retries with a fresh read.
-- This is cheaper than serialising every reader through SELECT FOR UPDATE
-- and keeps spectators non-blocking.
--
-- The version is NEVER bumped by a trigger — that would defeat the
-- purpose. It is bumped only by the RPCs that own the writes
-- (start_innings here, record_ball + undo_last_ball in 0410,
-- submit_match_openers in 0623), each in the SET clause of their UPDATE.
--
-- BROADCAST CHANNEL
-- -----------------
-- Changes here publish to the SAME channel that matches metadata changes
-- (0400) use: `match:<id>:state`. Spectator clients subscribe once and
-- receive a unified feed of metadata + innings-state events. The event
-- type differentiates: 'match_state_updated' from matches,
-- 'innings_state_updated' from this table.
-- =============================================================================

create table public.match_innings_state (
  -- Which match this innings row belongs to. Deletes cascade with the
  -- match — finishing or aborting a match removes its live state.
  match_id            uuid not null
                          references public.matches(match_id) on delete cascade,

  -- Which innings within the match. Tests have up to 4 (each side bats
  -- twice). T20 / ODI never exceed 2 outside a super-over (innings 3).
  innings_number      smallint not null
                          check (innings_number between 1 and 4),

  -- On-field trio. RESTRICT prevents losing a reference through a stray
  -- match_players delete — substitutions go via a future RPC that updates
  -- this row to the new player BEFORE the old one is removed.
  striker_id          uuid references public.match_players(match_player_id)
                          on delete restrict,
  non_striker_id      uuid references public.match_players(match_player_id)
                          on delete restrict,
  bowler_id           uuid references public.match_players(match_player_id)
                          on delete restrict,

  -- Denormalised running totals. Maintained by the scoring RPCs as deltas
  -- in the same UPDATE that rotates the trio — no scan of balls per call.
  -- The scoreboard reads these directly; the balls table remains the
  -- source-of-truth ledger.
  --
  -- legal_ball_count is the most important one: dividing by 6 gives the
  -- completed overs; modulo 6 gives the legal ball in the current over.
  -- record_ball derives over_number / ball_in_over from this counter
  -- instead of the per-call SUM scan the previous design used.
  legal_ball_count    integer  not null default 0 check (legal_ball_count >= 0),
  total_runs          integer  not null default 0 check (total_runs >= 0),
  total_wickets       smallint not null default 0
                          check (total_wickets between 0 and 10),
  total_extras        integer  not null default 0 check (total_extras >= 0),

  -- Innings termination flags. is_all_out is set when the 10th wicket
  -- falls (a future record_ball enhancement). is_declared is set by an
  -- explicit declare RPC (also future) for limited-overs / Test cricket.
  is_declared         boolean not null default false,
  is_all_out          boolean not null default false,

  -- Chase target for the second innings (and beyond, for Tests). NULL
  -- when the innings is the first or the chase target hasn't been
  -- computed yet.
  target              integer check (target is null or target > 0),

  updated_at          timestamptz not null default now(),

  -- See OPTIMISTIC CONCURRENCY in the header. Incremented in each
  -- write-path UPDATE; clients pass back the value they last read.
  version             bigint not null default 0,

  -- Striker and non-striker must be distinct when both are set. This
  -- mirrors the constraint that existed on matches before the column
  -- move.
  constraint different_batters check (
    striker_id is null
    or non_striker_id is null
    or striker_id <> non_striker_id
  ),

  primary key (match_id, innings_number)
);

create trigger match_innings_state_set_updated_at
  before update on public.match_innings_state
  for each row execute function public.set_updated_at();

-- "Which innings of this match is the active one?" — used by the
-- scoreboard render. Partial index over the (typically very small) set of
-- in-progress innings keeps the index tiny and selective.
create index match_innings_state_open
  on public.match_innings_state (match_id)
  where is_all_out = false and is_declared = false;

-- -----------------------------------------------------------------------------
-- ROW-LEVEL SECURITY
--
-- READ: public — the spectator scoreboard is public; if matches are
-- public, the innings state must be too.
--
-- WRITE: SECURITY DEFINER RPCs only. No INSERT / UPDATE / DELETE policy
-- is declared, so direct table writes are denied. Legitimate writers:
--   * start_innings (this file) — seeds the row at innings open.
--   * submit_match_openers (0623) — sets openers for innings 1.
--   * record_ball / undo_last_ball (0410) — increment / reverse deltas.
-- -----------------------------------------------------------------------------
alter table public.match_innings_state enable row level security;

create policy "match_innings_state_read_public"
  on public.match_innings_state for select
  using (true);

-- =============================================================================
-- start_innings — open or reopen an innings on the live scoring screen.
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
--   * At toss completion, by the live-scoring screen, for innings 1.
--   * At the innings break (or after a super-over decision), for
--     innings ≥ 2.
--   * Repeatedly, by the same scorer correcting a wrong opener pick,
--     until the match is past `start_phase = 'ready'`. The function is
--     idempotent on re-call with the same innings_number.
--
-- INPUTS
-- ------
-- p_match_id          The match.
-- p_innings_number    Which innings to open (1..4).
-- p_striker_id        The opening striker, as a match_player_id (NOT a
-- p_non_striker_id    profile uuid). The Lineup screen surfaces
-- p_bowler_id         match_players rows; the client passes the chosen
--                     match_player_id directly.
--
-- BEHAVIOUR
-- ---------
-- Validates auth (signed in, can_score_match), validates the inputs are
-- distinct and from this match's lineup, then upserts the
-- match_innings_state row for this innings and flips matches.status to
-- 'live'.
--
-- The re-call case (same innings, new trio) is the "scorer corrected an
-- opener" flow — the row updates in place and `version` is bumped so any
-- co-scorer notices.
--
-- FAILURE MODES (and their error codes)
-- -------------------------------------
--   28000  not signed in
--   42501  signed in but lacks scorer authority for this match
--   23514  invalid innings number, or striker == non-striker
--   23502  any of striker / non-striker / bowler is null
--   23000  match is already finalised (completed / abandoned / walkover)
--   23503  one of the supplied ids is not a match_player on this match
-- =============================================================================
create or replace function public.start_innings(
  p_match_id uuid,
  p_innings_number integer,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_bowler_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid    uuid := auth.uid();
  v_status public.match_status;
begin
  -- Auth gate
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
      using errcode = '42501';
  end if;

  -- Input shape
  if p_innings_number not between 1 and 4 then
    raise exception 'innings_number must be between 1 and 4' using errcode = '23514';
  end if;
  if p_striker_id is null or p_non_striker_id is null or p_bowler_id is null then
    raise exception 'Striker, non-striker and bowler are all required'
      using errcode = '23502';
  end if;
  if p_striker_id = p_non_striker_id then
    raise exception 'Striker and non-striker must be different players'
      using errcode = '23514';
  end if;

  -- Lock + status guard. The match row is locked so a concurrent
  -- submit_match_result / start_innings serialises.
  select status into v_status from public.matches
   where match_id = p_match_id for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'Cannot start innings on a finalised match (status %)', v_status
      using errcode = '23000';
  end if;

  -- Lineup membership. All three must belong to this match. We don't
  -- enforce that the bowler is on the OPPOSING side because in scratch /
  -- charity matches it occasionally happens that one team's player bowls
  -- for the other; the RPC stays permissive and the UI guards the common
  -- case.
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_striker_id and match_id = p_match_id
  ) then
    raise exception 'Striker is not in this match''s lineup'
      using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_non_striker_id and match_id = p_match_id
  ) then
    raise exception 'Non-striker is not in this match''s lineup'
      using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_bowler_id and match_id = p_match_id
  ) then
    raise exception 'Bowler is not in this match''s lineup'
      using errcode = '23503';
  end if;

  -- Upsert the innings row. ON CONFLICT covers the re-call case (scorer
  -- correcting an opener). Totals are left untouched on re-call so a
  -- mid-innings on-field swap (future feature) does not reset the score.
  insert into public.match_innings_state (
    match_id, innings_number, striker_id, non_striker_id, bowler_id
  )
  values (
    p_match_id, p_innings_number::smallint,
    p_striker_id, p_non_striker_id, p_bowler_id
  )
  on conflict (match_id, innings_number) do update
     set striker_id     = excluded.striker_id,
         non_striker_id = excluded.non_striker_id,
         bowler_id      = excluded.bowler_id,
         version        = match_innings_state.version + 1;

  -- Flip the match to live (idempotent if already live; actual_start_time
  -- is only stamped the first time).
  update public.matches
     set status            = 'live',
         actual_start_time = coalesce(actual_start_time, now())
   where match_id = p_match_id;
end;
$$;

revoke all on function public.start_innings(uuid, integer, uuid, uuid, uuid)
  from public;
grant execute on function public.start_innings(uuid, integer, uuid, uuid, uuid)
  to authenticated;

-- =============================================================================
-- broadcast_innings_state — realtime fan-out for live-scoring spectators
-- =============================================================================
-- WHAT THIS DOES
-- --------------
-- An AFTER INSERT OR UPDATE trigger on match_innings_state. Publishes the
-- new row as a JSONB payload to a Supabase Realtime broadcast channel.
--
-- CHANNEL
-- -------
--   topic:  match:<match_id>:state
--   event:  innings_state_updated
--
-- The channel is shared with the matches-metadata broadcast (0400), which
-- emits `match_state_updated` on the same topic. A spectator subscribes
-- once and receives both event types into the same handler — the event
-- field tells them which slice of state to merge.
--
-- WHY BROADCAST AND NOT POSTGRES_CHANGES
-- --------------------------------------
-- The native postgres_changes feature evaluates RLS per subscriber per
-- row. With 1,000 spectators on a tournament final, that's 1,000 RLS
-- evaluations per ball — every wide, every dot. Broadcasts send a single
-- message to the topic; the client filters its own subscription. Per the
-- realtime authorisation policies (0810), joining a `match:<id>:*` topic
-- requires only authentication, so any signed-in user can spectate any
-- match without paying the per-row cost.
--
-- ON UPDATE: only the new row is sent. Receivers infer deltas by
-- comparing against their local copy (typically just "replace the
-- previous version field-for-field"). The version column makes
-- out-of-order delivery safe to detect (a lower version is dropped).
--
-- ON INSERT: this fires once per innings start, so the scoreboard
-- transitions cleanly from "innings not yet open" to "0/0 (0.0)".
-- =============================================================================
create or replace function public.broadcast_innings_state()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(new),
    'innings_state_updated',
    'match:' || new.match_id::text || ':state',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_innings_state() from public;

create trigger match_innings_state_after_change_broadcast
  after insert or update on public.match_innings_state
  for each row execute function public.broadcast_innings_state();

-- The cascade_unclaimed_claim trigger function (originally declared in
-- 0210_team_members.sql) is extended by 0411_cascade_unclaimed_claim_extension.sql
-- so that an unclaimed player claiming a profile also rewrites their
-- historical match_players rows. That file owns the function's final
-- shape; this file is not involved in identity reconciliation.
