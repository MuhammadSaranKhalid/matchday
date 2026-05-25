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
-- submit_match_openers — batting captain locks striker + non-striker.
--
-- Both ids must be in the batting team's locked XI (`team_*_squad`).
-- Sets matches.current_striker_id / current_non_striker_id directly so
-- LiveScoringScreen has the on-field trio populated on first paint.
-- Advances start_phase: lineup → ready. Bowling captain's phone is
-- entirely passive in this stage (no companion RPC).
--
-- Idempotent: editing picks before the match starts (chat3 EDIT PICKS
-- affordance) re-submits with the new ids; openers_submitted_at gets
-- bumped on each call.
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
  v_uid         uuid := auth.uid();
  v_batting     uuid;
  v_team_a      uuid;
  v_team_b      uuid;
  v_team_a_cap  uuid;
  v_team_b_cap  uuid;
  v_team_a_xi   uuid[];
  v_team_b_xi   uuid[];
  v_batting_xi  uuid[];
  v_phase       public.match_start_phase;
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

  select team_a_id, team_b_id, team_a_captain, team_b_captain,
         team_a_squad, team_b_squad, start_phase
    into v_team_a, v_team_b, v_team_a_cap, v_team_b_cap,
         v_team_a_xi, v_team_b_xi, v_phase
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

  v_batting_xi := case
    when v_batting = v_team_a then v_team_a_xi
    else v_team_b_xi
  end;
  if not (p_striker_id = any(v_batting_xi)) then
    raise exception 'Striker must be in the batting XI' using errcode = '23514';
  end if;
  if not (p_non_striker_id = any(v_batting_xi)) then
    raise exception 'Non-striker must be in the batting XI'
      using errcode = '23514';
  end if;

  update public.matches
     set current_striker_id     = p_striker_id,
         current_non_striker_id = p_non_striker_id,
         openers_submitted_by   = v_uid,
         openers_submitted_at   = now(),
         start_phase            = case
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
-- start_match_now — batting captain tips the match into Live.
--
-- Promotes status → 'live', start_phase → 'live', stamps actual_start_time,
-- and adds the caller to `assigned_scorers` so the existing scoring RPC
-- RLS (record_ball / undo_last_ball) lets them record the first delivery.
-- Opening bowler is deferred to ball 1 — LiveScoringScreen prompts for
-- them when current_bowler_id is null on first paint.
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

  select team_a_id, team_b_id, team_a_captain, team_b_captain,
         current_striker_id, current_non_striker_id, status
    into v_team_a, v_team_b, v_team_a_cap, v_team_b_cap,
         v_striker, v_non_striker, v_status
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
  if v_striker is null or v_non_striker is null then
    raise exception 'Openers must be locked before starting'
      using errcode = '23000';
  end if;
  -- Re-entry guard: only callable from a pre-Live status. Calling on a
  -- match already 'live' or beyond silently re-added the caller to
  -- assigned_scorers and bumped actual_start_time — now it raises so the
  -- caller can recover (e.g. retry policy after a flaky network) without
  -- corrupting state.
  if v_status not in ('scheduled', 'rescheduled', 'toss') then
    raise exception 'Match has already started or finalised (status %)', v_status
      using errcode = '23000';
  end if;

  update public.matches
     set status            = 'live',
         start_phase       = 'live',
         current_innings   = 1,
         actual_start_time = coalesce(actual_start_time, now()),
         assigned_scorers  = case
           when v_uid = any(coalesce(assigned_scorers, '{}'::uuid[]))
             then assigned_scorers
           else coalesce(assigned_scorers, '{}'::uuid[]) || v_uid
         end
   where match_id = p_match_id;
end;
$$;

revoke all on function public.start_match_now(uuid) from public;
grant execute on function public.start_match_now(uuid) to authenticated;
