-- =============================================================================
-- 0410 · balls (live ball-by-ball ledger)
-- =============================================================================
-- Spec §4.5, §4.6. The source-of-truth ledger for every delivery in a match.
-- The scoring screen, scoreboard, and the "build result jsonb" step all
-- aggregate from this table.
--
-- Permissive batter/bowler refs (nullable) — squad selection ships in
-- phase 2b. Recording a delivery only requires runs/wicket/extras data.
--
-- Sequence numbering:
--   `seq` is monotonic 1-indexed per (match_id, innings_number). The
--   _balls_assign_seq BEFORE-INSERT trigger picks max(seq)+1 so the client
--   never has to know the next value. Undo (delete) frees the highest seq
--   so the next insert reuses it cleanly.
--
-- ball_in_over:
--   1..6 for legal deliveries. 0 for wides/no-balls (which don't advance
--   the over). is_legal_delivery is the single boolean used by the rollup
--   view to count overs cleanly.
--
-- Free-hit (§4.6):
--   `is_free_hit` is true for the next legal delivery after a no-ball
--   (intervening wides do not consume the free-hit). On a free-hit only
--   run-out, hit-wicket, obstructing-the-field, or handled-ball can dismiss
--   the batter — the CHECK below is the server-side guard. The flag is
--   computed by the client / record_ball RPC (Phase 2) by walking back
--   through the same (match, innings); persisting it lets the spectator
--   scoreboard render the FH chip without re-deriving on every read.
--
-- Result jsonb construction:
--   The match result blob (§4.10) is built by the live scorer's "End match"
--   action on the client by reading this table via the
--   match_innings_summary view, then submitting via submit_match_result
--   (declared in 0420).
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
  batsman_id         uuid references public.profiles(user_id) on delete set null,
  non_striker_id     uuid references public.profiles(user_id) on delete set null,
  bowler_id          uuid references public.profiles(user_id) on delete set null,
  fielder_id         uuid references public.profiles(user_id) on delete set null,
  commentary         text,
  created_by         uuid not null
                       references public.profiles(user_id) on delete restrict,
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
-- record_ball — server-owned ball insert + on-field state mutation.
--
-- Why an RPC instead of a direct insert:
--   1. seq, over_number, ball_in_over, and is_free_hit can all be derived
--      from prior balls — making the client compute them invites races when
--      two scorers share a match (RLS allows it).
--   2. Strike rotation (odd-runs swap, end-of-over rotation, wicket nulls
--      striker) and bowler clearing at over end need to mutate matches —
--      doing it in the same transaction as the insert keeps the persisted
--      `current_*_id` columns coherent with the ball ledger.
--
-- Free-hit: this delivery is a free-hit when the most recent prior ball that
-- was not a wide was a no-ball (intervening wides do not consume the
-- free-hit, per Laws 21.6/21.18).
--
-- Strike rotation, mirrored from the live-scoring widget logic:
--   swap if runs_scored is odd
--   swap if is_legal_delivery and extras is odd  (byes / leg-byes)
--   swap if this ball completes the 6th legal delivery of the over
--          (and clear current_bowler_id)
--   if is_wicket → null current_striker_id (forces the next pick)
-- All three swap conditions XOR-combine, then wicket override applies last.
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
  p_commentary        text default null
)
returns public.balls
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid          uuid := auth.uid();
  v_legal_count  integer;
  v_over_number  integer;
  v_ball_in_over integer;
  v_prev_kind    public.ball_kind;
  v_is_free_hit  boolean;
  v_swap         boolean;
  v_over_ended   boolean;
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

  -- Lock the match row so concurrent record_ball / undo_last_ball calls in
  -- the same (match, innings) serialise on the on-field state update.
  perform 1 from public.matches where match_id = p_match_id for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;

  -- Compute over_number / ball_in_over from prior legal deliveries.
  select coalesce(sum((is_legal_delivery)::int), 0)::int
    into v_legal_count
    from public.balls
   where match_id = p_match_id and innings_number = p_innings_number;

  v_over_number := v_legal_count / 6;
  if p_is_legal_delivery then
    v_ball_in_over := (v_legal_count % 6) + 1;
  else
    v_ball_in_over := 0;
  end if;

  -- Free-hit if the most recent non-wide prior ball was a no-ball.
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
    p_is_legal_delivery, p_ball_type, coalesce(p_runs_scored, 0), coalesce(p_extras, 0),
    p_is_wicket, p_wicket_type, v_is_free_hit,
    p_batsman_id, p_non_striker_id, p_bowler_id, p_fielder_id,
    p_commentary, v_uid
  )
  returning * into v_row;

  -- Strike + bowler rotation on the matches row.
  v_swap := (coalesce(p_runs_scored, 0) % 2 = 1)
            <> (p_is_legal_delivery and coalesce(p_extras, 0) % 2 = 1);
  v_over_ended := p_is_legal_delivery and (v_legal_count + 1) % 6 = 0;
  if v_over_ended then
    v_swap := not v_swap;
  end if;

  update public.matches m
     set current_striker_id = case
           when p_is_wicket then null
           when v_swap then m.current_non_striker_id
           else m.current_striker_id
         end,
         current_non_striker_id = case
           when v_swap and not p_is_wicket then m.current_striker_id
           else m.current_non_striker_id
         end,
         current_bowler_id = case
           when v_over_ended then null
           else m.current_bowler_id
         end
   where m.match_id = p_match_id;

  return v_row;
end;
$$;

revoke all on function public.record_ball(
  uuid, integer, boolean, public.ball_kind, integer, integer, boolean,
  public.wicket_kind, uuid, uuid, uuid, uuid, text
) from public;
grant execute on function public.record_ball(
  uuid, integer, boolean, public.ball_kind, integer, integer, boolean,
  public.wicket_kind, uuid, uuid, uuid, uuid, text
) to authenticated;

-- =============================================================================
-- undo_last_ball — drop the highest-seq ball in (match, innings) and
-- restore matches.current_striker_id / current_non_striker_id / current_bowler_id
-- to the values stamped on that deleted row (which captured the pre-ball
-- on-field state). Returns true if a row was removed, false if the innings
-- was already empty.
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

  perform 1 from public.matches where match_id = p_match_id for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
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

  update public.matches
     set current_striker_id     = v_row.batsman_id,
         current_non_striker_id = v_row.non_striker_id,
         current_bowler_id      = v_row.bowler_id
   where match_id = p_match_id;

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
