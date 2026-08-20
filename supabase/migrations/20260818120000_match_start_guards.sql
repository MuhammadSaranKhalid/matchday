-- =============================================================================
-- Match-start guards — close the two paths that can corrupt a scorecard
-- =============================================================================
-- Both fix holes in the 0623 RPCs. Neither changes any table.
--
-- GUARD 1 (task 1.6) — the toss becomes immutable once the innings is under
-- way. `record_match_toss` only checked `status`, which is still 'toss' after
-- the first recording, so a second call succeeded. Because the batting side is
-- derived from the toss, flipping it after openers were locked left
-- match_innings_state holding the OTHER team's players — and the match could
-- then be started with the wrong openers on the scoreboard.
--
-- This is reachable without malice: a phone that missed the phase-change
-- broadcast is still showing the toss screen, and its captain taps Continue.
--
-- GUARD 2 (task 1.7) — `start_match_now` verified only that the openers were
-- non-null, not that they belong to the batting side. `submit_match_openers`
-- does check this, so the two functions disagreed about what "valid openers"
-- means. Defence in depth for anything that wrote the row another way.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- _assert_toss_mutable — raises once innings 1 has left setup.
--
-- Keyed on match_innings_state rather than matches.start_phase because the
-- innings row is the persisted commitment; start_phase is a UI hint. Openers
-- existing IS the thing that makes the toss load-bearing, so that is what is
-- checked.
-- -----------------------------------------------------------------------------
create or replace function public._assert_toss_mutable(p_match_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1
      from public.match_innings_state
     where match_id = p_match_id
       and innings_number = 1
       and (striker_id is not null or non_striker_id is not null)
  ) then
    raise exception
      'The toss cannot be changed once the openers are locked'
      using errcode = '23000';
  end if;
end;
$$;

revoke all on function public._assert_toss_mutable(uuid) from public;
grant execute on function public._assert_toss_mutable(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- _assert_opener_side — both openers must be match_players on p_side.
-- Mirrors the check submit_match_openers already performs.
-- -----------------------------------------------------------------------------
create or replace function public._assert_opener_side(
  p_match_id uuid,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_side char(1)
)
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_striker_id
       and match_id  = p_match_id
       and team_side = p_side
  ) or not exists (
    select 1 from public.match_players
     where match_player_id = p_non_striker_id
       and match_id  = p_match_id
       and team_side = p_side
  ) then
    raise exception
      'The locked openers are not in the batting XI — re-pick them'
      using errcode = '23514';
  end if;
end;
$$;

revoke all on function public._assert_opener_side(uuid, uuid, uuid, char) from public;
grant execute on function public._assert_opener_side(uuid, uuid, uuid, char)
  to authenticated;

-- =============================================================================
-- record_match_toss — unchanged except for the mutability guard.
-- Full body restated because CREATE OR REPLACE has no partial form.
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

  -- NEW (1.6): inside the row lock, so a concurrent submit_match_openers
  -- cannot slip between the check and the update.
  perform public._assert_toss_mutable(p_match_id);

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
-- start_match_now — unchanged except for the opener-side check.
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
  v_side        char(1);
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

  select striker_id, non_striker_id
    into v_striker, v_non_striker
    from public.match_innings_state
   where match_id = p_match_id and innings_number = 1;
  if v_striker is null or v_non_striker is null then
    raise exception 'Openers must be locked before starting'
      using errcode = '23000';
  end if;

  -- NEW (1.7): the openers must belong to the side that is actually batting.
  v_side := case when v_batting = v_team_a then 'a' else 'b' end;
  perform public._assert_opener_side(
    p_match_id, v_striker, v_non_striker, v_side
  );

  if v_status not in ('scheduled', 'rescheduled', 'toss') then
    raise exception 'Match has already started or finalised (status %)', v_status
      using errcode = '23000';
  end if;

  update public.matches
     set status            = 'live',
         start_phase       = 'live',
         actual_start_time = coalesce(actual_start_time, now())
   where match_id = p_match_id;

  insert into public.match_officials (match_id, user_id, role, assigned_by)
  values (p_match_id, v_uid, 'scorer', v_uid)
  on conflict (match_id, role, user_id) do nothing;
end;
$$;

revoke all on function public.start_match_now(uuid) from public;
grant execute on function public.start_match_now(uuid) to authenticated;
