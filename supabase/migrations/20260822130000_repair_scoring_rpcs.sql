-- =============================================================================
-- 0822c · Repair two RPCs that fail at runtime
-- =============================================================================
-- Both shipped in migrations that are already applied, so correcting them at
-- source only helps a database built from scratch. This carries the fixes
-- forward. Both are the same mistake — a type that does not typecheck inside a
-- plpgsql body, which Postgres does not validate at CREATE time and only
-- reports when the function is actually called.
--
-- 1. undo_last_ball (0820) used
--        coalesce(delivery_type, ball_type) = 'wide'
--    `delivery_type` is the `delivery_kind` ENUM and `ball_type` is `text`, so
--    Postgres cannot resolve a common type:
--        COALESCE types delivery_kind and text cannot be matched
--    Every undo failed. The coalesces were pointless as well as wrong — all
--    four columns are NOT NULL and the legacy duplicates are never written —
--    so the aggregate now reads the real columns and matches the one
--    `record-ball` uses, so the two agree about what an innings totals to.
--
-- 2. start_innings (20260822110000) declared the batting side as `text` and
--    assigned a uuid into it, then compared it back against a uuid column:
--        operator does not exist: text = uuid
--    Every call failed — which is "Start the chase" at the innings break, and
--    every bowler change and incoming batter, since both route through it.
--    Team IDs and side labels are now separate variables of the right types.
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
  v_innings_id uuid;
  v_row public.match_deliveries;
  v_status public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting team can score this innings'
      using errcode = '42501';
  end if;

  select innings_id into v_innings_id
  from public.match_innings_state
  where match_id = p_match_id and innings_number = p_innings_number
  for update;

  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

  -- Delete latest delivery from match_deliveries
  delete from public.match_deliveries
  where delivery_id = (
    select delivery_id from public.match_deliveries
    where match_id = p_match_id and innings_number = p_innings_number
    order by seq desc
    limit 1
  )
  returning * into v_row;

  if v_row.delivery_id is null then
    return false;
  end if;

  -- Delete corresponding wicket row if delivery was a wicket
  if v_row.is_wicket then
    delete from public.match_wickets
    where delivery_id = v_row.delivery_id;
  end if;

  -- Re-derive totals from ledger
  update public.match_innings_state s set
    total_runs       = agg.runs,
    total_wickets    = agg.wickets,
    legal_ball_count = agg.legal,
    total_wides      = agg.wides,
    total_no_balls   = agg.no_balls,
    total_byes       = agg.byes,
    total_leg_byes   = agg.leg_byes,
    total_penalties  = agg.penalties,
    striker_id       = coalesce(v_row.striker_id, s.striker_id),
    non_striker_id   = coalesce(v_row.non_striker_id, s.non_striker_id),
    bowler_id        = coalesce(v_row.bowler_id, s.bowler_id),
    is_all_out       = false,
    version          = s.version + 1,
    updated_at       = now()
  from (
    select
      -- Matches the aggregate record-ball uses, deliberately: the two must
      -- agree about what an innings totals to. (The vestigial duplicate
      -- columns this once had to coalesce over — runs_scored, extras,
      -- ball_type, batsman_id — were dropped on 2026-09-06.)
      coalesce(sum(runs_off_bat + extra_runs), 0)::int                           as runs,
      (count(*) filter (where is_wicket))::int                                   as wickets,
      (count(*) filter (where is_legal_delivery))::int                           as legal,
      coalesce(sum(extra_runs) filter (where delivery_type = 'wide'), 0)::int    as wides,
      coalesce(sum(extra_runs) filter (where delivery_type = 'no_ball'), 0)::int as no_balls,
      coalesce(sum(extra_runs) filter (where delivery_type = 'bye'), 0)::int     as byes,
      coalesce(sum(extra_runs) filter (where delivery_type = 'leg_bye'), 0)::int as leg_byes,
      coalesce(sum(extra_runs) filter (where delivery_type = 'penalty'), 0)::int as penalties
    from public.match_deliveries
    where match_id = p_match_id and innings_number = p_innings_number and is_undone = false
  ) agg
  where s.match_id = p_match_id and s.innings_number = p_innings_number;

  -- Reverse the transition that delivery caused, if it caused one.
  --
  -- record-ball flips the match to 'innings_break' or 'completed' when the
  -- device reports the innings ended. Undoing that delivery has to put the
  -- match back, or the score says the innings is live while the match row says
  -- it is over — and everyone lands on the result screen with a scorecard that
  -- no longer supports it.
  --
  -- 🟥 This is the one path that can un-declare a result. Design doc §19.4 says
  -- a result must never be RENDERED from local computation, and it is not — the
  -- server declared it. But a scorer who mis-taps the winning run has to be
  -- able to take it back, and the alternative is a permanently wrong match.
  select status into v_status from public.matches where match_id = p_match_id;

  if v_status in ('innings_break', 'completed', 'tied', 'no_result') then
    update public.matches
       set status       = 'live',
           result       = null,
           completed_at = null,
           updated_at   = now()
     where match_id = p_match_id;
  end if;

  return true;
end;
$$;

create or replace function public.start_innings(
  p_match_id uuid,
  p_innings_number integer,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_bowler_id uuid,
  p_target integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_innings_id   uuid;
  v_status       public.match_status;
  v_team_a       uuid;
  v_team_b       uuid;
  v_toss_won     uuid;
  v_toss_dec     public.toss_decision;
  -- Team IDS are uuid and side LABELS are text. Keeping them in one variable
  -- is what broke this: a uuid was assigned into a text variable and then
  -- compared back against a uuid column, which is `text = uuid` and has no
  -- operator, so every call failed at runtime.
  v_batting_team uuid;
  v_batting_side text;
  v_bowling_side text;
begin
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting side can start this innings'
      using errcode = '42501';
  end if;

  select team_a_id, team_b_id, toss_won_by, toss_decision, status
    into v_team_a, v_team_b, v_toss_won, v_toss_dec, v_status
    from public.matches
   where match_id = p_match_id;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'This match is already finished' using errcode = '22023';
  end if;

  -- Which side bats is decided by the toss, not by the innings number being
  -- odd. The previous version hardcoded odd = team_a, so every match where
  -- team B batted first recorded both innings against the wrong side.
  v_batting_team := case
    when v_toss_won is null or v_toss_dec is null then v_team_a
    when v_toss_dec = 'bat' then v_toss_won
    when v_toss_won = v_team_a then v_team_b
    else v_team_a
  end;

  if p_innings_number % 2 = 0 then
    v_batting_team := case
      when v_batting_team = v_team_a then v_team_b else v_team_a
    end;
  end if;

  v_batting_side := case when v_batting_team = v_team_a then 'team_a' else 'team_b' end;
  v_bowling_side := case when v_batting_team = v_team_a then 'team_b' else 'team_a' end;

  -- The target goes to match_innings_state only. match_innings.target_runs was
  -- a second copy written by this same statement and was dropped 2026-09-06.
  insert into public.match_innings (
    match_id, innings_number, batting_team_side, bowling_team_side
  ) values (
    p_match_id, p_innings_number, v_batting_side, v_bowling_side
  )
  on conflict (match_id, innings_number) do update set
    batting_team_side = excluded.batting_team_side,
    bowling_team_side = excluded.bowling_team_side
  returning innings_id into v_innings_id;

  insert into public.match_innings_state (
    innings_id, match_id, innings_number, striker_id, non_striker_id, bowler_id, target
  ) values (
    v_innings_id, p_match_id, p_innings_number, p_striker_id, p_non_striker_id, p_bowler_id, p_target
  )
  on conflict (innings_id) do update set
    striker_id = p_striker_id,
    non_striker_id = p_non_striker_id,
    bowler_id = p_bowler_id,
    target = coalesce(excluded.target, match_innings_state.target),
    version = match_innings_state.version + 1,
    updated_at = now();

  update public.matches
  set status = 'live', updated_at = now()
  where match_id = p_match_id;
end;
$$;
