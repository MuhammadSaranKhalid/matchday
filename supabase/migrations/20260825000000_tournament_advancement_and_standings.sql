-- =============================================================================
-- 20260825000000 · tournament_advancement_and_standings
-- =============================================================================
-- Comprehensive Tournament Engine:
--   1. Standings Recalculation Engine (Points + NRR + All-out adjustment)
--   2. Knockout Bracket Auto-Advancement Trigger
--   3. Awards Storage & Confirmation RPC
--   4. Tournament Notification Dispatchers
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Awards column on tournaments
-- -----------------------------------------------------------------------------
-- tournaments.awards is declared inline in 20260101000300_tournaments.sql
-- (folded there 2026-09-06). This migration owns the RPCs that write it.

-- -----------------------------------------------------------------------------
-- 2. Standings recalculation function
-- -----------------------------------------------------------------------------
create or replace function public.recalculate_tournament_standings(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament record;
  v_team record;
  v_matches_played int;
  v_wins int;
  v_losses int;
  v_ties int;
  v_no_results int;
  v_points int;
  v_runs_scored int;
  v_overs_faced numeric(6, 2);
  v_runs_conceded int;
  v_overs_bowled numeric(6, 2);
  v_nrr numeric(6, 3);
  v_bat_rr numeric;
  v_bowl_rr numeric;
  v_max_overs numeric;
begin
  select * into v_tournament
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    return;
  end if;

  -- Default max overs from format or default to 20
  v_max_overs := coalesce((v_tournament.format->>'max_overs')::numeric, 20.0);

  -- Loop through all registered approved teams in tournament
  for v_team in
    select team_id, group_id
      from public.tournament_teams
     where tournament_id = p_tournament_id
       and status = 'approved'
  loop
    v_matches_played := 0;
    v_wins := 0;
    v_losses := 0;
    v_ties := 0;
    v_no_results := 0;
    v_points := 0;
    v_runs_scored := 0;
    v_overs_faced := 0;
    v_runs_conceded := 0;
    v_overs_bowled := 0;
    v_nrr := 0.0;

    -- Aggregate match results where this team played
    select
      count(*) filter (where m.status in ('completed', 'tied', 'no_result', 'abandoned')),
      count(*) filter (where m.status = 'completed' and m.winner_id = v_team.team_id),
      count(*) filter (where m.status = 'completed' and m.winner_id is not null and m.winner_id <> v_team.team_id),
      count(*) filter (where m.status = 'tied'),
      count(*) filter (where m.status in ('no_result', 'abandoned'))
    into
      v_matches_played,
      v_wins,
      v_losses,
      v_ties,
      v_no_results
    from public.matches m
    where m.tournament_id = p_tournament_id
      and (m.team_a_id = v_team.team_id or m.team_b_id = v_team.team_id);

    -- Standard cricket points: Win = 2, Tie/NR = 1, Loss = 0
    v_points := (v_wins * 2) + (v_ties * 1) + (v_no_results * 1);

    -- Aggregate runs scored & overs faced (batting innings)
    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          -- If all out (10 wickets down), overs faced counts as full quota
          when mis.total_wickets >= 10 then v_max_overs
          else (floor(mis.legal_ball_count / 6) + (mis.legal_ball_count % 6) / 10.0)
        end
      ), 0)
    into v_runs_scored, v_overs_faced
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and mi.batting_team_id = v_team.team_id;

    -- Aggregate runs conceded & overs bowled (bowling innings)
    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          when mis.total_wickets >= 10 then v_max_overs
          else (floor(mis.legal_ball_count / 6) + (mis.legal_ball_count % 6) / 10.0)
        end
      ), 0)
    into v_runs_conceded, v_overs_bowled
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and mi.bowling_team_id = v_team.team_id;

    -- Convert balls to fractional overs for run rate arithmetic
    -- e.g. 19.3 overs = 19 + 3/6 = 19.5
    v_bat_rr := case
      when v_overs_faced > 0 then
        v_runs_scored / (floor(v_overs_faced) + ((v_overs_faced - floor(v_overs_faced)) * 10 / 6.0))
      else 0.0
    end;

    v_bowl_rr := case
      when v_overs_bowled > 0 then
        v_runs_conceded / (floor(v_overs_bowled) + ((v_overs_bowled - floor(v_overs_bowled)) * 10 / 6.0))
      else 0.0
    end;

    v_nrr := round((v_bat_rr - v_bowl_rr)::numeric, 3);

    -- Upsert row in tournament_standings
    insert into public.tournament_standings (
      tournament_id,
      team_id,
      group_id,
      matches_played,
      wins,
      losses,
      ties,
      no_results,
      points,
      runs_scored,
      overs_faced,
      runs_conceded,
      overs_bowled,
      net_run_rate,
      updated_at
    ) values (
      p_tournament_id,
      v_team.team_id,
      v_team.group_id,
      v_matches_played,
      v_wins,
      v_losses,
      v_ties,
      v_no_results,
      v_points,
      v_runs_scored,
      v_overs_faced,
      v_runs_conceded,
      v_overs_bowled,
      v_nrr,
      now()
    )
    on conflict (tournament_id, team_id) do update set
      group_id = excluded.group_id,
      matches_played = excluded.matches_played,
      wins = excluded.wins,
      losses = excluded.losses,
      ties = excluded.ties,
      no_results = excluded.no_results,
      points = excluded.points,
      runs_scored = excluded.runs_scored,
      overs_faced = excluded.overs_faced,
      runs_conceded = excluded.runs_conceded,
      overs_bowled = excluded.overs_bowled,
      net_run_rate = excluded.net_run_rate,
      updated_at = now();
  end loop;
end;
$$;

revoke all on function public.recalculate_tournament_standings(uuid) from public;
grant execute on function public.recalculate_tournament_standings(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Bracket advancement & match completion trigger
-- -----------------------------------------------------------------------------
create or replace function public.trg_advance_tournament_bracket()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_winner_id uuid;
begin
  if new.tournament_id is not null
     and new.status = 'completed'
     and new.winner_id is not null
     and (old.status is distinct from 'completed') then

    v_winner_id := new.winner_id;

    -- Advance winner to downstream feeder match slot A
    update public.matches
       set team_a_id = v_winner_id
     where tournament_id = new.tournament_id
       and prev_match_a_id = new.match_id
       and team_a_id is null;

    -- Advance winner to downstream feeder match slot B
    update public.matches
       set team_b_id = v_winner_id
     where tournament_id = new.tournament_id
       and prev_match_b_id = new.match_id
       and team_b_id is null;

    -- Recompute standings
    perform public.recalculate_tournament_standings(new.tournament_id);
  end if;

  return new;
end;
$$;

drop trigger if exists match_advance_tournament_bracket on public.matches;

create trigger match_advance_tournament_bracket
  after update on public.matches
  for each row execute function public.trg_advance_tournament_bracket();

-- -----------------------------------------------------------------------------
-- 4. Confirm Tournament Awards RPC
-- -----------------------------------------------------------------------------
create or replace function public.confirm_tournament_awards(
  p_tournament_id uuid,
  p_awards jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can confirm awards' using errcode = '42501';
  end if;

  update public.tournaments
     set awards = p_awards,
         status = 'completed',
         updated_at = now()
   where tournament_id = p_tournament_id;
end;
$$;

revoke all on function public.confirm_tournament_awards(uuid, jsonb) from public;
grant execute on function public.confirm_tournament_awards(uuid, jsonb) to authenticated;
