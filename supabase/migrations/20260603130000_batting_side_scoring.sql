-- =============================================================================
-- Batting-side scoring authorization.
--
-- WHY
--   Product decision: live scoring is controlled by whichever team is CURRENTLY
--   BATTING — control passes to the other side at the innings break. The
--   previous rule (`_can_score_match`) let a friendly's CREATOR score the whole
--   match regardless of which side was batting, and the client showed the
--   scorer controls to everyone. Both are wrong for the batting-side model.
--
--   `_can_score_match` is left UNTOUCHED — it still governs match SETUP (pre-live
--   RLS edits, toss, openers, start_innings, submit_match_result). Only the
--   per-delivery write path (record_ball / undo_last_ball, and the record-ball
--   edge orchestrator) moves to the batting-side rule.
--
-- WHAT
--   1. `_match_batting_team(match, innings)` — the team_id batting in a given
--      innings, derived from toss + innings parity. Mirrors the client's
--      `_battingTeamId` (scoring_screen.dart) EXACTLY so server and UI agree:
--        bats_first = (toss_decision='bat' ? toss_won_by : the other team)
--        innings 1  → bats_first ; innings 2+ → the other team
--        (no toss yet → team_a, same fallback as the client)
--   2. `_can_score_innings(match, innings)` — true when the caller is the
--      tournament organiser, an assigned `scorer` official, the creator of a
--      single-team `practice` match, OR a manager/owner of the batting team.
--      Friendlies therefore resolve to "managers of the side currently batting".
--   3. record_ball / undo_last_ball re-created from the deployed definitions
--      with ONLY the authorization check (and its message) changed. Both are
--      SECURITY DEFINER + granted to `authenticated`, so the check has to move
--      here too — not just in the edge function — or a direct RPC call would
--      bypass the batting-side rule.
--
-- ROLLBACK
--   Re-point record_ball / undo_last_ball back at `_can_score_match` and drop
--   the two helpers below.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. _match_batting_team — batting team_id for an innings, from toss parity.
-- -----------------------------------------------------------------------------
create or replace function public._match_batting_team(
  p_match_id       uuid,
  p_innings_number integer
)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with bf as (
    select
      m.team_a_id,
      m.team_b_id,
      case
        when m.toss_won_by is null or m.toss_decision is null then null
        when m.toss_decision = 'bat'        then m.toss_won_by
        when m.toss_won_by   = m.team_a_id  then m.team_b_id
        else m.team_a_id
      end as bats_first
    from public.matches m
    where m.match_id = p_match_id
  )
  select case
    when bf.bats_first is null               then bf.team_a_id   -- no toss → fallback
    when p_innings_number = 1                then bf.bats_first
    when bf.bats_first = bf.team_a_id        then bf.team_b_id
    else bf.team_a_id
  end
  from bf;
$$;

revoke all on function public._match_batting_team(uuid, integer) from public;
grant execute on function public._match_batting_team(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. _can_score_innings — batting-side scoring rule for the live write path.
-- -----------------------------------------------------------------------------
create or replace function public._can_score_innings(
  p_match_id       uuid,
  p_innings_number integer
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.matches m
     where m.match_id = p_match_id
       and (
         -- Tournament organiser — neutral scorer, always allowed.
         (m.tournament_id is not null
           and public.is_tournament_organizer(m.tournament_id))

         -- Explicitly assigned scorer — neutral scorer, always allowed.
         or exists (
           select 1 from public.match_officials mo
            where mo.match_id = m.match_id
              and mo.user_id  = (select auth.uid())
              and mo.role     = 'scorer'
         )

         -- Practice match has a single team / no opponent — creator scores.
         or (m.match_type = 'practice'
             and m.created_by = (select auth.uid()))

         -- The batting side controls scoring (friendlies + the default path).
         or public.is_team_manager(
              public._match_batting_team(p_match_id, p_innings_number))
       )
  );
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;
grant execute on function public._can_score_innings(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 3a. record_ball — re-created verbatim from the deployed definition; ONLY the
--     authorization check is swapped to the batting-side rule.
-- -----------------------------------------------------------------------------
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
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting team can score this innings'
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

  select * into v_state
    from public.match_innings_state
   where match_id = p_match_id and innings_number = p_innings_number
   for update;
  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

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

  select ball_type into v_prev_kind
    from public.balls
   where match_id = p_match_id
     and innings_number = p_innings_number
     and ball_type <> 'wide'
   order by seq desc
   limit 1;
  v_is_free_hit := coalesce(v_prev_kind = 'no_ball', false);

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

  v_swap := (v_runs % 2 = 1)
            <> (p_is_legal_delivery and v_extras % 2 = 1);
  v_over_ended := p_is_legal_delivery and (v_state.legal_ball_count + 1) % 6 = 0;
  if v_over_ended then
    v_swap := not v_swap;
  end if;

  update public.match_innings_state mis
     set legal_ball_count = mis.legal_ball_count + (p_is_legal_delivery)::int,
         total_runs       = mis.total_runs + v_runs + v_extras,
         total_wickets    = mis.total_wickets + (p_is_wicket)::int::smallint,
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

-- -----------------------------------------------------------------------------
-- 3b. undo_last_ball — re-created verbatim from the deployed definition; ONLY
--     the authorization check is swapped to the batting-side rule.
-- -----------------------------------------------------------------------------
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
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting team can score this innings'
      using errcode = '42501';
  end if;

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

  update public.match_innings_state mis
     set legal_ball_count = greatest(0, mis.legal_ball_count
                                       - (v_row.is_legal_delivery)::int),
         total_runs       = greatest(0, mis.total_runs
                                       - v_row.runs_scored - v_row.extras),
         total_wickets    = greatest(0::smallint,
                              mis.total_wickets - (v_row.is_wicket)::int::smallint),
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
