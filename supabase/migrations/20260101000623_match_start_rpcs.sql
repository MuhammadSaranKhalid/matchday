-- =============================================================================
-- 0623 · Match-start RPCs (toss → openers → start)
-- =============================================================================
-- Three SECURITY DEFINER RPCs that drive the MatchStart flow. Captains
-- don't get raw UPDATE rights on `matches` (RLS policy from 0400 still
-- limits writes to organizers / assigned scorers / friendly creators);
-- instead each RPC bakes in a captain-of-this-match check, then performs
-- the constrained write.
--
-- Decision (per chat3 iteration with the product owner):
--   • Captains record the toss themselves (deviates from spec §4.11 which
--     reserves toss recording for scorers). v1.0 trade-off; revisit when
--     the assigned-scorer model lands in v1.1+.
--   • Openers are locked by the BATTING captain only — the team about to
--     bat picks its own striker / non-striker. The bowling captain's
--     phone shows a waiting card.
--   • The BATTING captain (not the request sender) taps Start, becoming
--     the implicit scorer for innings 1. `start_match_now` adds them to
--     `assigned_scorers` so the existing scoring RLS lets them record balls.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- _is_match_captain — auth helper shared by all three RPCs.
-- Returns true when auth.uid() is the captain of either team in the match.
-- -----------------------------------------------------------------------------
create or replace function public._is_match_captain(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.matches m
     where m.match_id = p_match_id
       and (auth.uid() = m.team_a_captain
            or auth.uid() = m.team_b_captain)
  );
$$;

revoke all on function public._is_match_captain(uuid) from public;
grant execute on function public._is_match_captain(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- _batting_first_team — given the toss outcome, which side bats innings 1?
-- Returns null if the toss hasn't been recorded yet.
-- -----------------------------------------------------------------------------
create or replace function public._batting_first_team(p_match_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
           when m.toss_decision is null then null
           when m.toss_decision = 'bat'  then m.toss_won_by
           when m.toss_decision = 'bowl' then case
               when m.toss_won_by = m.team_a_id then m.team_b_id
               when m.toss_won_by = m.team_b_id then m.team_a_id
             end
         end
    from public.matches m
   where m.match_id = p_match_id;
$$;

revoke all on function public._batting_first_team(uuid) from public;
grant execute on function public._batting_first_team(uuid) to authenticated;

-- =============================================================================
-- record_match_toss — host phone records the toss outcome.
--
-- Sets toss_won_by + toss_decision + (optional) toss_face. Idempotent:
-- re-calling with the same values is a no-op. Flips status: scheduled |
-- rescheduled → toss (mid-flight 'toss' stays). Advances start_phase:
-- toss → lineup so the other captain's phone moves to its waiting state.
--
-- Allowed in status: scheduled, rescheduled, toss. Blocks anything past
-- toss (live, completed, …) — toss can't be re-rolled mid-match.
-- =============================================================================
create or replace function public.record_match_toss(
  p_match_id uuid,
  p_won_by uuid,
  p_decision public.toss_decision,
  p_face char default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_team_a   uuid;
  v_team_b   uuid;
  v_status   public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._is_match_captain(p_match_id) then
    raise exception 'Only the team captains can record the toss'
      using errcode = '42501';
  end if;
  if p_face is not null and p_face not in ('H', 'T') then
    raise exception 'toss face must be H or T' using errcode = '23514';
  end if;

  select team_a_id, team_b_id, status
    into v_team_a, v_team_b, v_status
    from public.matches
   where match_id = p_match_id
     for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if v_status not in ('scheduled', 'rescheduled', 'toss') then
    raise exception 'Cannot record toss on a match in status %', v_status
      using errcode = '23000';
  end if;
  if p_won_by <> v_team_a and p_won_by <> v_team_b then
    raise exception 'Toss winner must be one of the two teams'
      using errcode = '23514';
  end if;

  update public.matches
     set toss_won_by   = p_won_by,
         toss_decision = p_decision,
         toss_face     = coalesce(p_face, toss_face),
         status        = case
                           when status in ('scheduled', 'rescheduled')
                             then 'toss'::public.match_status
                           else status
                         end,
         start_phase   = case
                           when start_phase = 'toss'
                             then 'lineup'::public.match_start_phase
                           else start_phase
                         end
   where match_id = p_match_id;
end;
$$;

revoke all on function public.record_match_toss(
  uuid, uuid, public.toss_decision, char
) from public;
grant execute on function public.record_match_toss(
  uuid, uuid, public.toss_decision, char
) to authenticated;

-- =============================================================================
-- submit_match_openers — batting captain locks the opening pair
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
-- After the toss has been recorded (record_match_toss) and the batting
-- captain's phone has moved to the Lineup screen, this RPC is called
-- when they pick their two openers and tap Confirm.
--
-- WHO CAN CALL IT
-- ---------------
-- Only the captain of the batting team for the first innings. The
-- batting team is derived from the toss outcome via _batting_first_team;
-- the captain check compares auth.uid() against that team's captain
-- column on matches. The bowling captain's phone is passive at this
-- stage — no companion RPC.
--
-- INPUTS
-- ------
-- p_match_id       The match.
-- p_striker_id     The opening striker — a match_player_id (NOT a
-- p_non_striker_id The non-striker — a match_player_id.
--
-- The Lineup screen surfaces match_players rows for the batting side, so
-- the client always has match_player_id values handy. Passing a profile
-- uuid here is a client bug and will be rejected by the lineup
-- membership check below.
--
-- WHAT IT DOES
-- ------------
-- 1. Authn check (28000).
-- 2. Input shape: both non-null and distinct (23502 / 23514).
-- 3. Determine batting side from the toss; raise 23000 if the toss
--    hasn't been recorded yet.
-- 4. Lock the matches row and verify the caller IS the batting
--    captain (42501 otherwise).
-- 5. Both supplied ids must be match_players rows for THIS match on
--    the batting side (23514 otherwise).
-- 6. Upsert the (match, innings=1) row in match_innings_state with the
--    opening pair. The bowler is left null — it gets picked on the
--    Live screen before the first ball, by record_ball's normal flow.
-- 7. Stamp matches.openers_submitted_by / openers_submitted_at and
--    advance start_phase: lineup → ready (if it was 'lineup').
--
-- IDEMPOTENCY
-- -----------
-- Re-calling with the same or different opener ids before the match
-- starts updates the match_innings_state row in place. The version
-- counter is bumped so any co-scorer's UI re-fetches. start_phase only
-- advances on the first call; subsequent calls are pure edits.
-- =============================================================================
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
  v_uid          uuid := auth.uid();
  v_batting      uuid;
  v_team_a       uuid;
  v_team_b       uuid;
  v_team_a_cap   uuid;
  v_team_b_cap   uuid;
  v_batting_side char(1);
  v_phase        public.match_start_phase;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_striker_id is null or p_non_striker_id is null then
    raise exception 'Striker and non-striker are both required'
      using errcode = '23502';
  end if;
  if p_striker_id = p_non_striker_id then
    raise exception 'Striker and non-striker must be different players'
      using errcode = '23514';
  end if;

  v_batting := public._batting_first_team(p_match_id);
  if v_batting is null then
    raise exception 'Toss must be recorded before openers' using errcode = '23000';
  end if;

  select team_a_id, team_b_id, team_a_captain, team_b_captain, start_phase
    into v_team_a, v_team_b, v_team_a_cap, v_team_b_cap, v_phase
    from public.matches
   where match_id = p_match_id
     for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if (v_batting = v_team_a and v_uid is distinct from v_team_a_cap)
     or (v_batting = v_team_b and v_uid is distinct from v_team_b_cap) then
    raise exception 'Only the batting captain can lock openers'
      using errcode = '42501';
  end if;

  v_batting_side := case when v_batting = v_team_a then 'a' else 'b' end;

  -- Both ids must be match_players rows for this match on the batting side.
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_striker_id
       and match_id   = p_match_id
       and team_side  = v_batting_side
  ) then
    raise exception 'Striker must be in the batting XI for this match'
      using errcode = '23514';
  end if;
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_non_striker_id
       and match_id   = p_match_id
       and team_side  = v_batting_side
  ) then
    raise exception 'Non-striker must be in the batting XI for this match'
      using errcode = '23514';
  end if;

  -- Persist openers in match_innings_state. Idempotent — re-call updates
  -- the trio without resetting innings totals or version drift.
  insert into public.match_innings_state (
    match_id, innings_number, striker_id, non_striker_id
  )
  values (p_match_id, 1::smallint, p_striker_id, p_non_striker_id)
  on conflict (match_id, innings_number) do update
     set striker_id     = excluded.striker_id,
         non_striker_id = excluded.non_striker_id,
         version        = match_innings_state.version + 1;

  update public.matches
     set openers_submitted_by = v_uid,
         openers_submitted_at = now(),
         start_phase          = case
                                  when start_phase = 'lineup'
                                    then 'ready'::public.match_start_phase
                                  else start_phase
                                end
   where match_id = p_match_id;
end;
$$;

revoke all on function public.submit_match_openers(uuid, uuid, uuid) from public;
grant execute on function public.submit_match_openers(uuid, uuid, uuid)
  to authenticated;

-- =============================================================================
-- start_match_now — batting captain tips the match into Live
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
-- After submit_match_openers has locked the openers (start_phase has
-- advanced to 'ready'), the batting captain's screen shows a "Start
-- match" CTA. Tapping it calls this RPC.
--
-- WHY THE BATTING CAPTAIN (and not any scorer)
-- --------------------------------------------
-- v1 product decision: the batting captain is the implicit scorer for
-- innings 1, because they're the one with the openers in hand and the
-- match-ready phone. Once Live, anyone in match_officials with role
-- 'scorer' can take over.
--
-- INPUTS
-- ------
-- p_match_id  The match.
--
-- WHAT IT DOES
-- ------------
-- 1. Authn check (28000).
-- 2. Determine the batting side from the toss; raise 23000 if the toss
--    hasn't been recorded.
-- 3. Lock the matches row and verify caller IS the batting captain
--    (42501 otherwise).
-- 4. Read the openers from match_innings_state (innings = 1). If
--    striker or non-striker is null, openers were not locked — raise
--    23000 with the "Openers must be locked" message.
-- 5. Re-entry guard: only allow a Live transition from scheduled /
--    rescheduled / toss. A double-tap on the CTA after the match has
--    already started raises 23000 so the client can recover from the
--    network retry without corrupting state.
-- 6. UPDATE matches: status='live', start_phase='live',
--    actual_start_time=now() (only if not already set).
-- 7. Register the caller as a match_official with role='scorer'. ON
--    CONFLICT DO NOTHING makes the call idempotent if they were
--    already a scorer (e.g. previously assigned by an organiser).
--
-- WHY THE OPENER CHECK COMES FROM match_innings_state
-- ---------------------------------------------------
-- match_innings_state is the source of truth for "the openers have been
-- locked" — submit_match_openers writes them there. We could instead
-- check start_phase == 'ready', but that is the UI hint, not the
-- persisted commitment. Reading the actual ids gives defence in depth:
-- if anything ever moved start_phase to 'ready' without writing
-- match_innings_state (a bug, a manual fix), we still refuse to start
-- a match whose scoreboard would be blank.
--
-- WHAT IT DOES NOT DO
-- -------------------
-- It does not set the opening bowler. That's deferred to ball 1 —
-- LiveScoringScreen sees match_innings_state.bowler_id is null on
-- first paint and prompts the captain to pick one. This is cheaper
-- UX-wise than asking for the bowler before the toss is even verified.
-- =============================================================================
create or replace function public.start_match_now(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid         uuid := auth.uid();
  v_batting     uuid;
  v_team_a      uuid;
  v_team_b      uuid;
  v_team_a_cap  uuid;
  v_team_b_cap  uuid;
  v_striker     uuid;
  v_non_striker uuid;
  v_status      public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  v_batting := public._batting_first_team(p_match_id);
  if v_batting is null then
    raise exception 'Toss must be recorded before starting'
      using errcode = '23000';
  end if;

  select team_a_id, team_b_id, team_a_captain, team_b_captain, status
    into v_team_a, v_team_b, v_team_a_cap, v_team_b_cap, v_status
    from public.matches
   where match_id = p_match_id
     for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if (v_batting = v_team_a and v_uid is distinct from v_team_a_cap)
     or (v_batting = v_team_b and v_uid is distinct from v_team_b_cap) then
    raise exception 'Only the batting captain can start the match'
      using errcode = '42501';
  end if;

  -- Openers must be in match_innings_state for innings 1.
  select striker_id, non_striker_id
    into v_striker, v_non_striker
    from public.match_innings_state
   where match_id = p_match_id and innings_number = 1;
  if v_striker is null or v_non_striker is null then
    raise exception 'Openers must be locked before starting'
      using errcode = '23000';
  end if;

  -- Re-entry guard: only callable from a pre-Live status.
  if v_status not in ('scheduled', 'rescheduled', 'toss') then
    raise exception 'Match has already started or finalised (status %)', v_status
      using errcode = '23000';
  end if;

  update public.matches
     set status            = 'live',
         start_phase       = 'live',
         actual_start_time = coalesce(actual_start_time, now())
   where match_id = p_match_id;

  -- Register the caller as a scorer. Idempotent if they're already on.
  insert into public.match_officials (match_id, user_id, role, assigned_by)
  values (p_match_id, v_uid, 'scorer', v_uid)
  on conflict (match_id, role, user_id) do nothing;
end;
$$;

revoke all on function public.start_match_now(uuid) from public;
grant execute on function public.start_match_now(uuid) to authenticated;
