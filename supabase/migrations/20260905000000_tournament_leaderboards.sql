-- =============================================================================
-- 20260905000000 · tournament_leaderboards
-- =============================================================================
-- Backs section D of the Tournaments canvas — the read surface:
--
--   10  Overview · live      "Leading the cup" — most runs / most wickets.
--   11  Overview · completed the honours board's orange and purple caps.
--   15  Stats tab           the two five-deep leaderboards + best bowling.
--
-- Until now `tournaments.awards` was the only source of a cap holder, and it
-- is *organiser-published* — nobody is named until the cup ends and the
-- organiser presses confirm. The canvas shows the caps while the cup is still
-- being played, so they have to be aggregated from what has actually been
-- scored.
--
-- ⚠️  This aggregates ALREADY-RECORDED delivery facts. It does not decide what
-- a delivery is worth, and it must never start to — that is the Dart engine's
-- job alone (see the scoring banner in CLAUDE.md). The precedent it follows is
-- `recalculate_tournament_standings`, which has summed innings in SQL since
-- 20260825000000.
--
-- The one convention encoded here is which dismissals are credited to the
-- bowler. That is scorekeeping, not delivery arithmetic — the same class of
-- rule as "a walkover contributes no NRR", which already lives in SQL. It is
-- pinned in one place, `_bowler_credited_wickets`, so it cannot drift.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Which dismissals go on the bowler's figures.
-- -----------------------------------------------------------------------------
-- Run-outs, retirements, obstruction, timed-out and handled-the-ball are the
-- batter's or the fielding side's, never the bowler's.
create or replace function public._bowler_credited_wickets()
returns text[]
language sql
immutable
set search_path = public, pg_temp
as $$
  -- Returns the dismissal kinds that count against the bowler's figures.
  -- Returning text[] avoids Postgres's eager enum-body validation; the caller
  -- uses = any() which implicitly casts text to wicket_kind.
  select array[
    'bowled', 'caught', 'caught_and_bowled', 'lbw', 'stumped', 'hit_wicket'
  ]::text[];
$$;

-- -----------------------------------------------------------------------------
-- 2. Batting leaderboard — the orange cap (artboards 10, 11, 15).
-- -----------------------------------------------------------------------------
create or replace function public.tournament_batting_leaderboard(
  p_tournament_id uuid,
  p_limit         integer default 5
)
returns table (
  player_key    text,
  display_name  text,
  team_name     text,
  team_monogram text,
  is_unclaimed  boolean,
  runs          integer,
  balls_faced   integer,
  fours         integer,
  sixes         integer,
  strike_rate   numeric,
  innings       integer,
  high_score    integer
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with deliveries as (
    select d.*, mp.display_name, mp.user_id, mp.unclaimed_id, mp.team_side,
           m.team_a_id, m.team_b_id
      from public.match_deliveries d
      join public.matches m       on m.match_id = d.match_id
      join public.match_players mp on mp.match_player_id = d.striker_id
     where m.tournament_id = p_tournament_id
       and d.is_undone = false
       -- Only matches that actually counted.
       and m.status in ('live', 'innings_break', 'super_over', 'completed', 'tied')
  ),
  per_player_match as (
    select
      -- A claimed player is one person across the cup; an unclaimed guest is
      -- scoped to their roster row, so two "Uncle Asif"s never merge.
      coalesce('u:' || dv.user_id::text, 'x:' || dv.unclaimed_id::text) as player_key,
      dv.match_id,
      max(dv.display_name)                                        as display_name,
      bool_or(dv.user_id is null)                                 as is_unclaimed,
      (array_agg(case dv.team_side when 'team_a' then dv.team_a_id
                                   else dv.team_b_id end))[1]     as team_id,
      sum(dv.runs_off_bat)::integer                               as runs,
      count(*) filter (where dv.is_legal_delivery)::integer       as balls,
      count(*) filter (where dv.is_four)::integer                 as fours,
      count(*) filter (where dv.is_six)::integer                  as sixes
    from deliveries dv
    where coalesce(dv.user_id::text, dv.unclaimed_id::text) is not null
    group by 1, 2
  ),
  totals as (
    select
      p.player_key,
      max(p.display_name)          as display_name,
      bool_or(p.is_unclaimed)      as is_unclaimed,
      (array_agg(p.team_id order by p.match_id desc))[1] as team_id,
      sum(p.runs)::integer         as runs,
      sum(p.balls)::integer        as balls_faced,
      sum(p.fours)::integer        as fours,
      sum(p.sixes)::integer        as sixes,
      count(*)::integer            as innings,
      max(p.runs)::integer         as high_score
    from per_player_match p
    group by p.player_key
  )
  select
    t.player_key,
    t.display_name,
    tm.team_name,
    tm.logo_monogram,
    t.is_unclaimed,
    t.runs,
    t.balls_faced,
    t.fours,
    t.sixes,
    case when t.balls_faced = 0 then 0
         else round((t.runs::numeric * 100) / t.balls_faced, 1) end,
    t.innings,
    t.high_score
  from totals t
  left join public.teams tm on tm.team_id = t.team_id
  where t.runs > 0
  order by t.runs desc, t.balls_faced asc, t.display_name
  limit greatest(coalesce(p_limit, 5), 1);
$$;

revoke all on function public.tournament_batting_leaderboard(uuid, integer) from public;
grant execute on function public.tournament_batting_leaderboard(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Bowling leaderboard — the purple cap (artboards 10, 11, 15).
-- -----------------------------------------------------------------------------
create or replace function public.tournament_bowling_leaderboard(
  p_tournament_id uuid,
  p_limit         integer default 5
)
returns table (
  player_key    text,
  display_name  text,
  team_name     text,
  team_monogram text,
  is_unclaimed  boolean,
  wickets       integer,
  runs_conceded integer,
  legal_balls   integer,
  economy       numeric,
  innings       integer,
  best_wickets  integer,
  best_runs     integer
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with deliveries as (
    select d.*, mp.display_name, mp.user_id, mp.unclaimed_id, mp.team_side,
           m.team_a_id, m.team_b_id
      from public.match_deliveries d
      join public.matches m        on m.match_id = d.match_id
      join public.match_players mp on mp.match_player_id = d.bowler_id
     where m.tournament_id = p_tournament_id
       and d.is_undone = false
       and m.status in ('live', 'innings_break', 'super_over', 'completed', 'tied')
  ),
  per_player_match as (
    select
      coalesce('u:' || dv.user_id::text, 'x:' || dv.unclaimed_id::text) as player_key,
      dv.match_id,
      max(dv.display_name)                                    as display_name,
      bool_or(dv.user_id is null)                             as is_unclaimed,
      (array_agg(case dv.team_side when 'team_a' then dv.team_a_id
                                   else dv.team_b_id end))[1] as team_id,
      count(*) filter (
        where dv.is_wicket
          and dv.wicket_type::text = any(public._bowler_credited_wickets())
      )::integer                                              as wickets,
      -- Byes and leg-byes are not charged to the bowler; a penalty is nobody's.
      sum(
        case when dv.delivery_type in ('bye', 'leg_bye', 'penalty')
             then dv.runs_off_bat
             else dv.runs_off_bat + dv.extra_runs end
      )::integer                                              as runs_conceded,
      count(*) filter (where dv.is_legal_delivery)::integer   as legal_balls
    from deliveries dv
    where coalesce(dv.user_id::text, dv.unclaimed_id::text) is not null
    group by 1, 2
  ),
  totals as (
    select
      p.player_key,
      max(p.display_name)      as display_name,
      bool_or(p.is_unclaimed)  as is_unclaimed,
      (array_agg(p.team_id order by p.match_id desc))[1] as team_id,
      sum(p.wickets)::integer  as wickets,
      sum(p.runs_conceded)::integer as runs_conceded,
      sum(p.legal_balls)::integer   as legal_balls,
      count(*)::integer        as innings,
      -- Best figures: most wickets, then fewest runs for that haul.
      (array_agg(p.wickets order by p.wickets desc, p.runs_conceded asc))[1]
                               as best_wickets,
      (array_agg(p.runs_conceded order by p.wickets desc, p.runs_conceded asc))[1]
                               as best_runs
    from per_player_match p
    group by p.player_key
  )
  select
    t.player_key,
    t.display_name,
    tm.team_name,
    tm.logo_monogram,
    t.is_unclaimed,
    t.wickets,
    t.runs_conceded,
    t.legal_balls,
    case when t.legal_balls = 0 then 0
         else round((t.runs_conceded::numeric * 6) / t.legal_balls, 2) end,
    t.innings,
    t.best_wickets,
    t.best_runs
  from totals t
  left join public.teams tm on tm.team_id = t.team_id
  where t.legal_balls > 0
  order by t.wickets desc, t.runs_conceded asc, t.display_name
  limit greatest(coalesce(p_limit, 5), 1);
$$;

revoke all on function public.tournament_bowling_leaderboard(uuid, integer) from public;
grant execute on function public.tournament_bowling_leaderboard(uuid, integer) to authenticated;

-- -- -----------------------------------------------------------------------------
-- -- 4. Organiser credibility (artboard 09).
-- -- -----------------------------------------------------------------------------
-- -- The Overview tab for a cup taking registrations is built around the three
-- -- things a manager actually decides on: *is this organiser trustworthy*, is
-- -- there room, and is it worth the fee. The first of those had no data behind
-- -- it — a name was all the client could show. This answers it with the only
-- -- evidence that means anything: how many cups this person has actually run,
-- -- and since when.
-- create or replace function public.tournament_organizer_profile(
--   p_tournament_id uuid
-- )
-- returns table (
--   user_id       uuid,
--   display_name  text,
--   username      text,
--   avatar_url    text,
--   city          text,
--   cups_run      integer,
--   first_cup_year integer,
--   completed_cups integer
-- )
-- language sql
-- security definer
-- stable
-- set search_path = public, pg_temp
-- as $$
--   with organiser as (
--     -- tournaments.location is jsonb, same shape as profiles.location; there
--     -- is no flat `city` column (see the tournaments_city index).
--     select t.created_by as uid, t.location->>'city' as city
--       from public.tournaments t
--      where t.tournament_id = p_tournament_id
--   ),
--   history as (
--     select
--       count(*)::integer                                as cups_run,
--       min(extract(year from t2.created_at))::integer   as first_year,
--       count(*) filter (where t2.status = 'completed')::integer as completed
--     from public.tournaments t2, organiser o
--     where t2.created_by = o.uid
--       -- A draft nobody ever published is not a cup they ran.
--       and t2.status <> 'draft'
--   )
--   select
--     pr.user_id,
--     pr.display_name,
--     pr.username,
--     pr.profile_photo_url,
--     -- profiles.location is jsonb; the city lives under its 'city' key.
--     coalesce(o.city, pr.location->>'city'),
--     h.cups_run,
--     h.first_year,
--     h.completed
--   from organiser o
--   join public.profiles pr on pr.user_id = o.uid
--   cross join history h;
-- $$;

-- revoke all on function public.tournament_organizer_profile(uuid) from public;
-- grant execute on function public.tournament_organizer_profile(uuid) to authenticated;
