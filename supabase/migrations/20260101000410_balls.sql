-- =============================================================================
-- 0410 · balls — the ball-by-ball delivery ledger
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- One row per delivery in every match in the system. Wides, no-balls,
-- byes, leg-byes, dot balls, boundaries, wickets — all of it. This is the
-- source-of-truth ledger; everything else (scoreboard, scorecard, end-of-
-- innings result jsonb, per-player stats once they ship) is computed
-- from this table.
--
-- PLAYER REFERENCES
-- -----------------
-- batsman_id, non_striker_id, bowler_id, fielder_id all reference
-- match_players(match_player_id) — NOT profiles. That is the whole point
-- of match_players (0405): the polymorphism (profile vs unclaimed) is
-- resolved once per match, and downstream tables hold a clean uuid.
--
-- The practical consequence is that an unclaimed player at a club match
-- can be on strike, can bowl, can take a catch. The old schema's FK to
-- profiles rejected those rows outright.
--
-- RELATIONSHIP TO match_innings_state (0409)
-- ------------------------------------------
-- balls is the LEDGER. match_innings_state is the RUNNING TOTAL.
--
-- record_ball below appends one row to balls AND updates a single row in
-- match_innings_state (incrementing legal_ball_count, total_runs,
-- total_wickets, total_extras and rotating striker/non-striker/bowler).
-- The two writes happen in the same transaction; the totals never drift
-- from the ledger they are summarising.
--
-- The previous design read legal_ball_count from balls via
--    SELECT SUM(is_legal_delivery::int) FROM balls
--    WHERE match_id = ? AND innings_number = ?
-- on EVERY ball insert, to compute over_number and ball_in_over. That
-- scan grew linearly through the innings (ball 239 of a T20 read 238
-- rows). The new shape reads the counter off match_innings_state in O(1),
-- and the SUM is gone.
--
-- SEQUENCE NUMBERING (`seq`)
-- --------------------------
-- Monotonic 1-indexed per (match_id, innings_number). The
-- _balls_assign_seq BEFORE-INSERT trigger picks max(seq)+1 so the client
-- never has to know the next value. Undo (DELETE the top seq row) frees
-- that number so the next insert reuses it cleanly — there is no gap.
--
-- ball_in_over
-- ------------
-- 1..6 for legal deliveries. 0 for wides and no-balls (those do not
-- advance the over). The match_innings_summary view (still present in
-- this file) uses is_legal_delivery to count overs cleanly.
--
-- FREE HIT (Laws 21.6 / 21.18)
-- ----------------------------
-- The delivery immediately following a no-ball is a free hit. Intervening
-- wides do NOT consume the free hit (the law specifically excludes them).
-- On a free hit only run-out, hit-wicket, obstructing-the-field, or
-- handled-the-ball can dismiss the batter; bowled / caught / lbw /
-- stumped are not valid. The balls_free_hit_dismissal_check constraint
-- enforces that server-side.
--
-- record_ball derives is_free_hit by looking up the most recent non-wide
-- ball in this innings; if it was a no-ball, the new delivery is a free
-- hit. The flag is persisted on the row so the spectator scoreboard can
-- render the FH chip without re-deriving on every read.
--
-- RESULT JSONB
-- ------------
-- The match result blob (§4.10) is built by the live scorer's "End match"
-- action on the client by reading this table via the
-- match_innings_summary view, then submitting via submit_match_result
-- (declared in 0420).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Ball-only enums.
-- -----------------------------------------------------------------------------
create type public.ball_kind as enum (
  'legal',
  'wide',
  'no_ball',
  'bye',
  'leg_bye'
);

create type public.wicket_kind as enum (
  'bowled',
  'caught',
  'lbw',
  'run_out',
  'stumped',
  'hit_wicket',
  'retired_hurt',
  'obstructing',
  'timed_out',
  'handled_ball'
);

-- -----------------------------------------------------------------------------
-- balls table.
-- -----------------------------------------------------------------------------
create table public.balls (
  ball_id            uuid primary key default gen_random_uuid(),
  match_id           uuid not null
                       references public.matches(match_id) on delete cascade,
  innings_number     integer not null check (innings_number between 1 and 4),
  -- Filled by the BEFORE-INSERT trigger if the client didn't supply one.
  seq                integer not null check (seq >= 1),
  over_number        integer not null check (over_number >= 0),
  -- 1..6 for legal deliveries; 0 for wides/no-balls (do not advance over).
  ball_in_over       integer not null check (ball_in_over between 0 and 6),
  is_legal_delivery  boolean not null,
  ball_type          public.ball_kind not null default 'legal',
  -- Runs charged to the batter for this delivery (boundary 4/6, or 1..3,
  -- etc.). Excludes extras (tracked separately).
  runs_scored        integer not null default 0
                       check (runs_scored between 0 and 7),
  -- Extras runs added for this delivery (wide/nb overrun, byes, leg-byes).
  -- Team total += runs_scored + extras.
  extras             integer not null default 0
                       check (extras >= 0 and extras <= 10),
  is_wicket          boolean not null default false,
  wicket_type        public.wicket_kind,
  is_free_hit        boolean not null default false,
  -- Player FKs reference match_players, so unclaimed players can bat/bowl/
  -- field. RESTRICT preserves the per-ball history — match_players promotion
  -- (delete_user RPC) must run before any rows can be removed.
  batsman_id         uuid references public.match_players(match_player_id) on delete restrict,
  non_striker_id     uuid references public.match_players(match_player_id) on delete restrict,
  bowler_id          uuid references public.match_players(match_player_id) on delete restrict,
  fielder_id         uuid references public.match_players(match_player_id) on delete restrict,
  commentary         text,
  -- created_by is the authoring user (the scorer) — always a real profile.
  -- ON DELETE SET NULL so self-service account deletion (delete_user RPC
  -- in 0700) can anonymise the scorer without orphaning the ledger.
  created_by         uuid
                       references public.profiles(user_id) on delete set null,
  created_at         timestamptz not null default now(),

  unique (match_id, innings_number, seq),
  -- A wicket needs a wicket_type; a non-wicket ball must not have one.
  constraint balls_wicket_type_consistency check (
    (is_wicket and wicket_type is not null)
    or (not is_wicket and wicket_type is null)
  ),
  -- On a free-hit only run-out, hit-wicket, obstructing, or handled-ball
  -- are valid dismissals (Laws of Cricket 21.18).
  constraint balls_free_hit_dismissal_check check (
    not is_free_hit
    or not is_wicket
    or wicket_type in ('run_out', 'hit_wicket', 'obstructing', 'handled_ball')
  )
);

create index balls_match    on public.balls (match_id);
create index balls_innings  on public.balls (match_id, innings_number);
-- Hot path: record_ball / undo_last_ball / spectator scoreboard all query
-- "balls in this match's current over". Composite covers the natural sort.
create index balls_match_innings_over
  on public.balls (match_id, innings_number, over_number, seq);

-- -----------------------------------------------------------------------------
-- _balls_assign_seq — auto-assigns the next sequence in (match, innings).
-- -----------------------------------------------------------------------------
create or replace function public._balls_assign_seq()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_max int;
begin
  if new.seq is null or new.seq = 0 then
    select coalesce(max(seq), 0) + 1
      into v_max
      from public.balls
     where match_id = new.match_id
       and innings_number = new.innings_number;
    new.seq := v_max;
  end if;
  return new;
end;
$$;

create trigger balls_assign_seq
  before insert on public.balls
  for each row execute function public._balls_assign_seq();

-- -----------------------------------------------------------------------------
-- match_innings_summary — per-innings rollup view, computed on read.
-- balls stays the source of truth; consumer screens read from this view.
-- -----------------------------------------------------------------------------
create or replace view public.match_innings_summary as
  select
    b.match_id,
    b.innings_number,
    coalesce(sum(b.runs_scored), 0)::int + coalesce(sum(b.extras), 0)::int as runs,
    coalesce(sum(b.extras), 0)::int                                         as extras,
    coalesce(sum((b.is_wicket)::int), 0)::int                               as wickets,
    coalesce(sum((b.is_legal_delivery)::int), 0)::int                       as legal_balls,
    -- Cricket overs notation: 19.4 = 19 complete overs + 4 legal balls.
    (coalesce(sum((b.is_legal_delivery)::int), 0) / 6) || '.'
      || (coalesce(sum((b.is_legal_delivery)::int), 0) % 6)                 as overs_text,
    -- Decimal overs for NRR: 19 + 4/6 ≈ 19.67.
    round(coalesce(sum((b.is_legal_delivery)::int), 0) / 6.0, 2)            as overs_decimal,
    max(b.created_at)                                                       as last_ball_at,
    count(*)::int                                                           as ball_count
    from public.balls b
   group by b.match_id, b.innings_number;

-- =============================================================================
-- record_ball — append a delivery and advance the live innings state
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
-- Every time a scorer taps a scoring chip on the LiveScoringScreen. A
-- dot ball, a single, a four, a wide, a wicket — each is one call. The
-- screen pre-fills (batsman, non-striker, bowler) from the live trio so
-- the scorer only chooses outcome details.
--
-- WHO CAN CALL IT
-- ---------------
-- Anyone for whom _can_score_match (0407) returns true: tournament
-- organisers, anyone with a 'scorer' role in match_officials, and the
-- creator of a friendly / practice match.
--
-- INPUTS
-- ------
-- p_match_id          The match.
-- p_innings_number    Which innings this delivery belongs to (1..4).
-- p_is_legal_delivery Whether this delivery advances the over (false for
--                     wides and no-balls).
-- p_ball_type         enum: legal | wide | no_ball | bye | leg_bye.
-- p_runs_scored       Runs charged to the batter (0..7 — six plus an
--                     overthrow). Excludes extras.
-- p_extras            Penalty / overthrown runs added to the team total
--                     (0..10). Side-charged to the bowling team.
-- p_is_wicket         True if a wicket fell on this delivery.
-- p_wicket_type       Required when is_wicket is true; null otherwise.
-- p_batsman_id        match_player_id of the batter on strike.
-- p_non_striker_id    match_player_id of the non-striker.
-- p_bowler_id         match_player_id of the bowler.
-- p_fielder_id        match_player_id of the relevant fielder (catch /
--                     run-out), if any.
-- p_commentary        Free-form text the scorer attached to the
--                     delivery (optional).
-- p_expected_version  The version of match_innings_state the client
--                     last read. NULL opts out of optimistic locking
--                     (single-scorer mode). Non-null triggers a
--                     "stale state" rejection if the server has since
--                     advanced.
--
-- WHAT IT DOES, IN ORDER
-- ----------------------
-- 1. Authn / authz checks (28000 / 42501 on failure).
-- 2. Input shape validation (23502 / 23514 on failure).
-- 3. Lock match_innings_state(match, innings) FOR UPDATE. This
--    serialises concurrent record_ball / undo_last_ball calls on the
--    same innings without locking the whole matches row (and therefore
--    without blocking spectators reading match metadata).
-- 4. Optimistic-lock guard. If p_expected_version is provided and does
--    not match the current version, abort with 40001 — the client
--    re-fetches and retries.
-- 5. Compute over_number = legal_ball_count / 6 and ball_in_over from
--    the same counter. NO scan of balls.
-- 6. Look up the most recent non-wide ball this innings to decide
--    is_free_hit. Indexed lookup; bounded to one row.
-- 7. INSERT the row into balls. The BEFORE-INSERT trigger
--    _balls_assign_seq stamps `seq`.
-- 8. UPDATE match_innings_state with the deltas (legal_ball_count,
--    totals) and the rotated on-field trio. Bump `version`.
--
-- STRIKE / BOWLER ROTATION
-- ------------------------
-- Mirrors the live-scoring widget logic in the Flutter app:
--   swap if runs_scored is odd
--   swap if is_legal_delivery AND extras is odd   (byes / leg-byes)
--   swap if this ball completes the 6th legal delivery of the over
--          (and NULL bowler_id so the scorer picks the next bowler)
--   if is_wicket → NULL striker_id (forces the next pick)
-- The three swap conditions XOR-combine; the wicket override applies
-- last.
--
-- WHAT IT DOES NOT DO
-- -------------------
-- It does not touch the matches row at all (other than the implicit
-- match_innings_state cascade). Live scoring contention is entirely
-- isolated from the metadata row that scoreboards / fixture lists /
-- profile pages all read from.
--
-- RETURN VALUE
-- ------------
-- The freshly-inserted balls row. The Flutter client uses it to render
-- the over-summary chip and to make the undo button's "undo this exact
-- ball" affordance unambiguous.
-- =============================================================================
create or replace function public.record_ball(
  p_match_id          uuid,
  p_innings_number    integer,
  p_is_legal_delivery boolean,
  p_ball_type         public.ball_kind,
  p_runs_scored       integer default 0,
  p_extras            integer default 0,
  p_is_wicket         boolean default false,
  p_wicket_type       public.wicket_kind default null,
  p_batsman_id        uuid default null,
  p_non_striker_id    uuid default null,
  p_bowler_id         uuid default null,
  p_fielder_id        uuid default null,
  p_commentary        text default null,
  p_expected_version  bigint default null
)
returns public.balls
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid          uuid := auth.uid();
  v_state        public.match_innings_state;
  v_over_number  integer;
  v_ball_in_over integer;
  v_prev_kind    public.ball_kind;
  v_is_free_hit  boolean;
  v_swap         boolean;
  v_over_ended   boolean;
  v_runs         integer := coalesce(p_runs_scored, 0);
  v_extras       integer := coalesce(p_extras, 0);
  v_row          public.balls;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
      using errcode = '42501';
  end if;
  if p_innings_number not between 1 and 4 then
    raise exception 'innings_number must be between 1 and 4' using errcode = '23514';
  end if;
  if p_is_wicket and p_wicket_type is null then
    raise exception 'wicket_type is required when is_wicket=true' using errcode = '23514';
  end if;
  if not p_is_wicket and p_wicket_type is not null then
    raise exception 'wicket_type must be null when is_wicket=false' using errcode = '23514';
  end if;

  -- Lock the live innings row. Concurrent record_ball / undo_last_ball in
  -- the same (match, innings) serialise here.
  select * into v_state
    from public.match_innings_state
   where match_id = p_match_id and innings_number = p_innings_number
   for update;
  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

  -- Optimistic-lock guard. Client may pass the version it last read; if
  -- it's stale, the call is rejected and the client retries with fresh
  -- state. NULL means the client opts out (single-scorer mode).
  if p_expected_version is not null
     and v_state.version <> p_expected_version then
    raise exception 'Innings state changed under us (expected v%, got v%)',
      p_expected_version, v_state.version
      using errcode = '40001';
  end if;

  v_over_number := v_state.legal_ball_count / 6;
  if p_is_legal_delivery then
    v_ball_in_over := (v_state.legal_ball_count % 6) + 1;
  else
    v_ball_in_over := 0;
  end if;

  -- Free-hit lookup — most recent non-wide ball in this innings.
  select ball_type into v_prev_kind
    from public.balls
   where match_id = p_match_id
     and innings_number = p_innings_number
     and ball_type <> 'wide'
   order by seq desc
   limit 1;
  v_is_free_hit := (v_prev_kind = 'no_ball');

  insert into public.balls (
    match_id, innings_number, over_number, ball_in_over,
    is_legal_delivery, ball_type, runs_scored, extras,
    is_wicket, wicket_type, is_free_hit,
    batsman_id, non_striker_id, bowler_id, fielder_id,
    commentary, created_by
  )
  values (
    p_match_id, p_innings_number, v_over_number, v_ball_in_over,
    p_is_legal_delivery, p_ball_type, v_runs, v_extras,
    p_is_wicket, p_wicket_type, v_is_free_hit,
    p_batsman_id, p_non_striker_id, p_bowler_id, p_fielder_id,
    p_commentary, v_uid
  )
  returning * into v_row;

  -- Strike + bowler rotation.
  v_swap := (v_runs % 2 = 1)
            <> (p_is_legal_delivery and v_extras % 2 = 1);
  v_over_ended := p_is_legal_delivery and (v_state.legal_ball_count + 1) % 6 = 0;
  if v_over_ended then
    v_swap := not v_swap;
  end if;

  update public.match_innings_state mis
     set legal_ball_count = mis.legal_ball_count + (p_is_legal_delivery)::int,
         total_runs       = mis.total_runs + v_runs + v_extras,
         total_wickets    = mis.total_wickets + (p_is_wicket)::smallint,
         total_extras     = mis.total_extras + v_extras,
         striker_id       = case
           when p_is_wicket then null
           when v_swap then mis.non_striker_id
           else mis.striker_id
         end,
         non_striker_id   = case
           when v_swap and not p_is_wicket then mis.striker_id
           else mis.non_striker_id
         end,
         bowler_id        = case
           when v_over_ended then null
           else mis.bowler_id
         end,
         version          = mis.version + 1
   where mis.match_id       = p_match_id
     and mis.innings_number = p_innings_number;

  return v_row;
end;
$$;

revoke all on function public.record_ball(
  uuid, integer, boolean, public.ball_kind, integer, integer, boolean,
  public.wicket_kind, uuid, uuid, uuid, uuid, text, bigint
) from public;
grant execute on function public.record_ball(
  uuid, integer, boolean, public.ball_kind, integer, integer, boolean,
  public.wicket_kind, uuid, uuid, uuid, uuid, text, bigint
) to authenticated;

-- =============================================================================
-- undo_last_ball — reverse the most recent delivery in an innings
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
-- When a scorer realises the last delivery was recorded incorrectly. The
-- LiveScoringScreen has an undo button that pops the most recent ball
-- off the over chip and reverts the scoreboard. This is the RPC behind
-- that button.
--
-- INPUTS
-- ------
-- p_match_id        The match.
-- p_innings_number  Which innings to undo from. (You cannot undo across
--                   an innings break — call this for innings 1 to fix
--                   innings 1; the scorer would not be allowed to undo
--                   their way back into a closed innings.)
--
-- WHAT IT DOES
-- ------------
-- 1. Authn / authz (28000 / 42501 on failure).
-- 2. Locks the (match, innings) match_innings_state row FOR UPDATE —
--    same serialisation point as record_ball, so an undo and a record
--    cannot interleave.
-- 3. Finds the highest-seq ball in this innings via index on
--    (match_id, innings_number, seq) and DELETEs it. The deleted row's
--    full record is captured for the rollback.
-- 4. If no row was found (innings was empty), returns false and exits.
-- 5. UPDATEs match_innings_state to reverse the deltas the original
--    record_ball applied:
--      legal_ball_count -= is_legal_delivery::int
--      total_runs       -= runs_scored + extras
--      total_wickets    -= is_wicket::int
--      total_extras     -= extras
--    All reads use greatest(0, ...) to defend against counter drift —
--    if a backfill or manual correction left the counter inconsistent,
--    undo never drives a column negative. This is purely defensive; the
--    write path keeps the counters consistent on its own.
-- 6. Restores striker_id / non_striker_id / bowler_id to the values the
--    deleted ball was stamped with — which by construction are the
--    PRE-ball on-field trio. Undo therefore "rewinds" the over.
-- 7. Bumps `version` so any co-scorer sees the change on next read.
--
-- WHAT IT DOES NOT DO
-- -------------------
-- It does not touch the matches row, the same as record_ball. The match
-- metadata is unaffected by scorer corrections.
--
-- RETURN VALUE
-- ------------
-- true if a row was actually removed; false if the innings ledger was
-- already empty (idempotent re-call on an empty over).
-- =============================================================================
create or replace function public.undo_last_ball(
  p_match_id uuid,
  p_innings_number integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.balls;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
      using errcode = '42501';
  end if;

  -- Lock the live innings row so we serialise against concurrent record_ball.
  perform 1 from public.match_innings_state
   where match_id = p_match_id and innings_number = p_innings_number
   for update;
  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

  delete from public.balls
   where ball_id = (
     select ball_id from public.balls
      where match_id = p_match_id and innings_number = p_innings_number
      order by seq desc
      limit 1
   )
  returning * into v_row;

  if v_row.ball_id is null then
    return false;
  end if;

  -- Reverse deltas + restore the on-field trio captured on the deleted row.
  -- greatest(0, ...) defends against drift if a backfill produced an
  -- inconsistent counter — never go negative.
  update public.match_innings_state mis
     set legal_ball_count = greatest(0, mis.legal_ball_count
                                       - (v_row.is_legal_delivery)::int),
         total_runs       = greatest(0, mis.total_runs
                                       - v_row.runs_scored - v_row.extras),
         total_wickets    = greatest(0::smallint,
                              mis.total_wickets - (v_row.is_wicket)::smallint),
         total_extras     = greatest(0, mis.total_extras - v_row.extras),
         striker_id       = v_row.batsman_id,
         non_striker_id   = v_row.non_striker_id,
         bowler_id        = v_row.bowler_id,
         version          = mis.version + 1
   where mis.match_id       = p_match_id
     and mis.innings_number = p_innings_number;

  return true;
end;
$$;

revoke all on function public.undo_last_ball(uuid, integer) from public;
grant execute on function public.undo_last_ball(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS — public read; organizers / scorers / friendly-creators write.
-- -----------------------------------------------------------------------------
alter table public.balls enable row level security;

create policy "balls_read_public"
  on public.balls for select
  using (true);

-- Note: the live scoring screen routes through record_ball / undo_last_ball
-- (SECURITY DEFINER, so they bypass these policies). These policies still
-- gate any direct table access — admin tooling, manual corrections via the
-- Supabase dashboard, etc. — so they must keep matching the RPCs' auth
-- predicate. Both share `_can_score_match` so they can't drift.
create policy "balls_insert_organizer_or_scorer"
  on public.balls for insert
  to authenticated
  with check (
    public._can_score_match(match_id)
    and (select auth.uid()) = created_by
  );

-- Updates are rare (commentary tweak, etc.) — same authorization.
create policy "balls_update_organizer_or_scorer"
  on public.balls for update
  to authenticated
  using (public._can_score_match(match_id))
  with check (true);

-- Delete = undo last ball (covered by undo_last_ball RPC; this policy is
-- the manual-correction fallback).
create policy "balls_delete_organizer_or_scorer"
  on public.balls for delete
  to authenticated
  using (public._can_score_match(match_id));

-- =============================================================================
-- Realtime — Broadcast every recorded delivery and every undo.
-- =============================================================================
-- Topic:  match:<match_id>:balls
-- Events: 'ball_recorded' (INSERT) | 'ball_deleted' (DELETE)
--
-- Spectators subscribe on the match screen; one publish reaches every
-- subscriber regardless of count. Replaces the postgres_changes pattern
-- that fanned RLS evaluation across every spectator on every row.
-- =============================================================================
create or replace function public.broadcast_new_ball()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(new),
    'ball_recorded',
    'match:' || new.match_id::text || ':balls',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_new_ball() from public;

drop trigger if exists balls_after_insert_broadcast on public.balls;

create trigger balls_after_insert_broadcast
  after insert on public.balls
  for each row execute function public.broadcast_new_ball();

-- Undo (DELETE) — spectators need to roll the ball back out of their list.
create or replace function public.broadcast_ball_deleted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(old),
    'ball_deleted',
    'match:' || old.match_id::text || ':balls',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_ball_deleted() from public;

drop trigger if exists balls_after_delete_broadcast on public.balls;

create trigger balls_after_delete_broadcast
  after delete on public.balls
  for each row execute function public.broadcast_ball_deleted();
