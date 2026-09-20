-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 3B
-- Generic lifecycle + Cricket-owned types
-- =============================================================================
--
-- REQUIRES:
--   Phase 2A
--   Phase 2B
--   Phase 3A
--
-- THIS PHASE DOES:
--
--   1. Replace the mixed global match_status with a true cross-sport lifecycle:
--
--        scheduled | live | completed | abandoned | cancelled
--
--   2. Replace match_start_phase with a Cricket-owned phase:
--
--        toss | lineup | ready | live | innings_break | super_over | complete
--
--   3. Rename Cricket-only enum types:
--
--        toss_decision  -> cricket_toss_decision
--        scoring_mode   -> cricket_scoring_mode
--        delivery_kind  -> cricket_delivery_kind
--        wicket_kind    -> cricket_wicket_kind
--
--   4. Remove now-unused global Cricket enums:
--
--        match_format
--        match_role
--
--   5. Remove the obsolete _normalize_match_format helper.
--
--   6. Rebuild active lifecycle/tournament RPCs so Cricket phase/outcome lives
--      in cricket_matches rather than matches.status.
--
-- IMPORTANT:
--   The Flutter product remains Cricket-only. cricket_match_details projects a
--   backwards-compatible Cricket-facing `status` text while also exposing:
--
--        lifecycle_status
--        cricket_phase
--
--   This keeps UI routing stable while the database model becomes multi-sport.
-- =============================================================================


-- =============================================================================
-- 0. Hard preflight
-- =============================================================================

do $$
declare
  v_count bigint;
begin
  -- Phase 3A physically removed these columns.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'matches'
      and column_name in (
        'format',
        'toss_won_by',
        'start_phase',
        'result',
        'team_a_captain'
      )
  ) then
    raise exception
      'Phase 3B requires Phase 3A. Legacy Cricket columns still exist on matches.';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'match_players'
      and column_name in (
        'role',
        'is_in_playing_xi',
        'batting_order'
      )
  ) then
    raise exception
      'Phase 3B requires Phase 3A. Legacy Cricket columns still exist on match_players.';
  end if;

  if to_regclass('public.cricket_matches') is null
     or to_regclass('public.cricket_match_players') is null
     or to_regclass('public.cricket_match_details') is null
     or to_regprocedure('public._sync_cricket_result_to_parent()') is null
  then
    raise exception
      'Phase 3B requires the canonical Phase 2/3A Cricket extensions.';
  end if;

  -- The migration is deliberately one-way.
  if to_regtype('public.cricket_match_phase') is not null
     or to_regtype('public.cricket_toss_decision') is not null
     or to_regtype('public.cricket_scoring_mode') is not null
     or to_regtype('public.cricket_delivery_kind') is not null
     or to_regtype('public.cricket_wicket_kind') is not null
  then
    raise exception
      'Phase 3B appears to be partially/already applied. Stop and reconcile instead of rerunning.';
  end if;

  -- Canonical parent/child completeness.
  select count(*)
    into v_count
    from public.matches m
    left join public.cricket_matches cm
      on cm.match_id = m.match_id
   where m.sport_id = 'cricket'
     and cm.match_id is null;

  if v_count <> 0 then
    raise exception
      'Cannot change lifecycle types: % Cricket matches lack cricket_matches rows.',
      v_count;
  end if;
end
$$;


-- =============================================================================
-- 1. Drop Cricket aggregate API temporarily
-- =============================================================================
--
-- Both the view and its SETOF function depend on columns whose enum types are
-- about to change. They are rebuilt at the end.
-- =============================================================================

drop function if exists public.list_my_cricket_matches();
drop view if exists public.cricket_match_details;



-- =============================================================================
-- 1.1 Remove Cricket scoring mode from the shared preset catalog
-- =============================================================================
--
-- match_format_presets is sport-scoped/shared. `live_ball_by_ball` is not a
-- generic multi-sport concept, so the shared table must not own a column typed
-- as a Cricket enum.
--
-- Preserve the Cricket picker value inside the sport-owned opaque config.
-- =============================================================================

drop view if exists public.format_presets;

update public.match_format_presets
   set config =
         jsonb_set(
           coalesce(config, '{}'::jsonb),
           '{default_scoring_mode}',
           to_jsonb(default_scoring_mode::text),
           true
         )
 where sport_id = 'cricket'
   and default_scoring_mode is not null;

alter table public.match_format_presets
  drop column default_scoring_mode;

create view public.format_presets
with (security_invoker = true)
as
select *
from public.match_format_presets;

grant select
  on public.format_presets
  to anon, authenticated;


-- =============================================================================
-- 2. Rename Cricket-only enum types whose VALUE SET is already correct
-- =============================================================================
--
-- ALTER TYPE ... RENAME preserves the type OID, so existing columns and
-- function signatures follow the rename without data conversion.
-- =============================================================================

alter type public.toss_decision
  rename to cricket_toss_decision;

alter type public.scoring_mode
  rename to cricket_scoring_mode;

alter type public.delivery_kind
  rename to cricket_delivery_kind;

alter type public.wicket_kind
  rename to cricket_wicket_kind;


-- =============================================================================
-- 3. Replace match_start_phase with cricket_match_phase
-- =============================================================================
--
-- We create a new enum rather than ALTER TYPE ... ADD VALUE because newly-added
-- enum values are awkward to use safely inside the same migration transaction.
-- =============================================================================

create type public.cricket_match_phase_v2 as enum (
  'toss',
  'lineup',
  'ready',
  'live',
  'innings_break',
  'super_over',
  'complete'
);


alter table public.cricket_matches
  alter column phase drop default;

alter table public.cricket_matches
  alter column phase
  type public.cricket_match_phase_v2
  using phase::text::public.cricket_match_phase_v2;

alter table public.cricket_matches
  alter column phase
  set default 'toss'::public.cricket_match_phase_v2;


-- Preserve Cricket phase that previously leaked into matches.status.
update public.cricket_matches cm
   set phase =
       case m.status::text
         when 'innings_break'
           then 'innings_break'::public.cricket_match_phase_v2
         when 'super_over'
           then 'super_over'::public.cricket_match_phase_v2
         when 'completed'
           then 'complete'::public.cricket_match_phase_v2
         when 'tied'
           then 'complete'::public.cricket_match_phase_v2
         when 'no_result'
           then 'complete'::public.cricket_match_phase_v2
         when 'walkover'
           then 'complete'::public.cricket_match_phase_v2
         when 'abandoned'
           then 'complete'::public.cricket_match_phase_v2
         else cm.phase
       end,
       updated_at = now()
  from public.matches m
 where m.match_id = cm.match_id;


alter type public.match_start_phase
  rename to _legacy_match_start_phase;

alter type public.cricket_match_phase_v2
  rename to cricket_match_phase;


-- =============================================================================
-- 4. Replace match_status with a true sport-neutral lifecycle
-- =============================================================================

create type public.match_status_v2 as enum (
  'scheduled',
  'live',
  'completed',
  'abandoned',
  'cancelled'
);


alter table public.matches
  alter column status drop default;

alter table public.matches
  alter column status
  type public.match_status_v2
  using (
    case status::text
      when 'scheduled'      then 'scheduled'
      when 'rescheduled'    then 'scheduled'
      when 'toss'           then 'scheduled'

      when 'live'           then 'live'
      when 'innings_break'  then 'live'
      when 'super_over'     then 'live'

      when 'completed'      then 'completed'
      when 'tied'           then 'completed'
      when 'walkover'       then 'completed'

      when 'no_result'      then 'abandoned'
      when 'abandoned'      then 'abandoned'

      else 'scheduled'
    end
  )::public.match_status_v2;

alter table public.matches
  alter column status
  set default 'scheduled'::public.match_status_v2;


-- Result-history status columns now audit GENERIC lifecycle transitions.
alter table public.match_result_history
  alter column previous_status
  type public.match_status_v2
  using (
    case previous_status::text
      when 'scheduled'      then 'scheduled'
      when 'rescheduled'    then 'scheduled'
      when 'toss'           then 'scheduled'

      when 'live'           then 'live'
      when 'innings_break'  then 'live'
      when 'super_over'     then 'live'

      when 'completed'      then 'completed'
      when 'tied'           then 'completed'
      when 'walkover'       then 'completed'

      when 'no_result'      then 'abandoned'
      when 'abandoned'      then 'abandoned'

      else 'scheduled'
    end
  )::public.match_status_v2;


alter table public.match_result_history
  alter column new_status
  type public.match_status_v2
  using (
    case new_status::text
      when 'scheduled'      then 'scheduled'
      when 'rescheduled'    then 'scheduled'
      when 'toss'           then 'scheduled'

      when 'live'           then 'live'
      when 'innings_break'  then 'live'
      when 'super_over'     then 'live'

      when 'completed'      then 'completed'
      when 'tied'           then 'completed'
      when 'walkover'       then 'completed'

      when 'no_result'      then 'abandoned'
      when 'abandoned'      then 'abandoned'

      else 'scheduled'
    end
  )::public.match_status_v2;


alter type public.match_status
  rename to _legacy_match_status;

alter type public.match_status_v2
  rename to match_status;


comment on type public.match_status is
  'Sport-neutral match lifecycle only. Cricket phase and result outcome live '
  'in cricket_matches.';


-- =============================================================================
-- 5. Cricket match-start lifecycle commands
-- =============================================================================
-- The 7 match command RPCs (record_toss_winner, record_toss_decision,
-- submit_match_openers, start_match_now, start_innings, undo_last_ball,
-- complete_cricket_match) have been moved to TypeScript Edge Functions
-- (cricket-match-action) executing direct SQL in single transactions.


-- =============================================================================
-- 7. Stale scheduled-match cleanup
-- =============================================================================

create or replace function public.abandon_stale_matches()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  with stale as materialized (
    select m.match_id
    from public.matches m
    where m.status = 'scheduled'
      and m.scheduled_start_time
            < now() - interval '7 days'
      and m.actual_start_time is null
      and not exists (
        select 1
        from public.match_deliveries d
        where d.match_id = m.match_id
          and d.is_undone = false
      )
    for update
  ),
  updated_parent as (
    update public.matches m
       set status = 'abandoned',
           completed_at = now(),
           updated_at = now()
      from stale s
     where m.match_id = s.match_id
    returning m.match_id
  ),
  updated_cricket as (
    update public.cricket_matches cm
       set phase = 'complete',
           updated_at = now()
      from updated_parent u
     where cm.match_id = u.match_id
    returning cm.match_id
  )
  select count(*)
    into v_count
    from updated_parent;

  return v_count;
end;
$$;

revoke all
  on function public.abandon_stale_matches()
  from public, anon, authenticated;


-- =============================================================================
-- 8. Tournament standings derive outcome from cricket_matches.result
-- =============================================================================

create or replace function public.recalculate_tournament_standings(
  p_tournament_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament     record;
  v_team           record;
  v_matches_played int;
  v_wins           int;
  v_losses         int;
  v_ties           int;
  v_no_results     int;
  v_points         int;
  v_runs_scored    int;
  v_overs_faced    numeric(6,2);
  v_runs_conceded  int;
  v_overs_bowled   numeric(6,2);
  v_nrr            numeric(6,3);
  v_bat_rr         numeric;
  v_bowl_rr        numeric;
  v_max_overs      numeric;
begin
  select *
    into v_tournament
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    return;
  end if;

  v_max_overs :=
    coalesce(
      (v_tournament.format->>'max_overs')::numeric,
      (v_tournament.format->>'overs_per_innings')::numeric,
      20.0
    );

  for v_team in
    select
      team_id,
      group_id
    from public.tournament_teams
    where tournament_id = p_tournament_id
      and status = 'approved'
  loop

    select
      count(*) filter (
        where m.status in (
          'completed',
          'abandoned'
        )
      ),

      count(*) filter (
        where m.status = 'completed'
          and m.winner_id = v_team.team_id
      ),

      count(*) filter (
        where m.status = 'completed'
          and m.winner_id is not null
          and m.winner_id <> v_team.team_id
      ),

      count(*) filter (
        where m.status = 'completed'
          and cm.result->>'win_type'
                in ('tie', 'draw')
      ),

      count(*) filter (
        where m.status = 'abandoned'
          or cm.result->>'win_type' = 'no_result'
      )

    into
      v_matches_played,
      v_wins,
      v_losses,
      v_ties,
      v_no_results

    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
    where m.tournament_id = p_tournament_id
      and (
        m.team_a_id = v_team.team_id
        or m.team_b_id = v_team.team_id
      );

    v_points :=
      (v_wins * 2)
      + v_ties
      + v_no_results;

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(
        sum(
          case
            when mis.total_wickets >= 10
              then v_max_overs
            else (
              floor(mis.legal_ball_count / 6)
              + (mis.legal_ball_count % 6) / 10.0
            )
          end
        ),
        0
      )
    into
      v_runs_scored,
      v_overs_faced
    from public.matches m
    join public.match_innings mi
      on mi.match_id = m.match_id
    join public.match_innings_state mis
      on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and case mi.batting_team_side
            when 'team_a' then m.team_a_id
            else m.team_b_id
          end = v_team.team_id;

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(
        sum(
          case
            when mis.total_wickets >= 10
              then v_max_overs
            else (
              floor(mis.legal_ball_count / 6)
              + (mis.legal_ball_count % 6) / 10.0
            )
          end
        ),
        0
      )
    into
      v_runs_conceded,
      v_overs_bowled
    from public.matches m
    join public.match_innings mi
      on mi.match_id = m.match_id
    join public.match_innings_state mis
      on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and case mi.bowling_team_side
            when 'team_a' then m.team_a_id
            else m.team_b_id
          end = v_team.team_id;

    v_bat_rr :=
      case
        when v_overs_faced > 0 then
          v_runs_scored
          / (
              floor(v_overs_faced)
              + (
                  (v_overs_faced - floor(v_overs_faced))
                  * 10 / 6.0
                )
            )
        else 0.0
      end;

    v_bowl_rr :=
      case
        when v_overs_bowled > 0 then
          v_runs_conceded
          / (
              floor(v_overs_bowled)
              + (
                  (v_overs_bowled - floor(v_overs_bowled))
                  * 10 / 6.0
                )
            )
        else 0.0
      end;

    v_nrr :=
      round((v_bat_rr - v_bowl_rr)::numeric, 3);

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
    )
    values (
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
    on conflict (tournament_id, team_id)
    do update set
      group_id       = excluded.group_id,
      matches_played = excluded.matches_played,
      wins           = excluded.wins,
      losses         = excluded.losses,
      ties           = excluded.ties,
      no_results     = excluded.no_results,
      points         = excluded.points,
      runs_scored    = excluded.runs_scored,
      overs_faced    = excluded.overs_faced,
      runs_conceded  = excluded.runs_conceded,
      overs_bowled   = excluded.overs_bowled,
      net_run_rate   = excluded.net_run_rate,
      updated_at     = now();
  end loop;
end;
$$;

revoke all
  on function public.recalculate_tournament_standings(uuid)
  from public, anon, authenticated;

grant execute
  on function public.recalculate_tournament_standings(uuid)
  to service_role;


create or replace function public.trg_advance_tournament_bracket()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.tournament_id is null then
    return new;
  end if;

  if new.status = 'completed'
     and new.winner_id is not null
     and (
       old.status is distinct from new.status
       or old.winner_id is distinct from new.winner_id
     ) then

    update public.matches
       set team_a_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_a_id = new.match_id
       and team_a_id is null;

    update public.matches
       set team_b_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_b_id = new.match_id
       and team_b_id is null;
  end if;

  if old.status is distinct from new.status
     or old.winner_id is distinct from new.winner_id then
    perform public.recalculate_tournament_standings(
      new.tournament_id
    );
  end if;

  return new;
end;
$$;

revoke all
  on function public.trg_advance_tournament_bracket()
  from public, anon, authenticated;


-- =============================================================================
-- 9. Tournament match operations
-- =============================================================================
-- The 6 tournament ops RPCs (tournament_reschedule_match,
-- tournament_abandon_match, tournament_declare_walkover,
-- tournament_override_result, tournament_revise_match_conditions,
-- tournament_trigger_super_over) have been moved to TypeScript Edge Functions
-- (cricket-match-action) executing direct SQL in single transactions.


-- =============================================================================
-- 10. Rebuild Cricket read aggregate with dual status surfaces
-- =============================================================================
--
-- lifecycle_status = generic backend truth
-- cricket_phase    = raw Cricket phase
-- status           = existing Cricket UI compatibility projection
-- start_phase      = existing pre-match UI compatibility projection
-- =============================================================================

create view public.cricket_match_details
with (security_invoker = true)
as
select
  m.match_id,
  m.tournament_id,
  m.match_type,
  m.stage,
  m.round,
  m.bracket_round_number,
  m.bracket_match_number,
  m.prev_match_a_id,
  m.prev_match_b_id,
  m.group_id,
  m.venue,
  m.ground_id,
  m.sport_id,
  m.scheduled_start_time,
  m.actual_start_time,
  m.completed_at,

  -- Canonical generic lifecycle for future backend/frontend consumers.
  m.status as lifecycle_status,

  -- Canonical Cricket phase.
  cm.phase as cricket_phase,

  -- Compatibility status for the existing Cricket-only Flutter app.
  case
    when m.status = 'scheduled'
         and cm.toss_recorded_at is not null
      then 'toss'

    when m.status = 'live'
         and cm.phase = 'innings_break'
      then 'innings_break'

    when m.status = 'live'
         and cm.phase = 'super_over'
      then 'super_over'

    when m.status = 'completed'
         and cm.result->>'win_type' = 'tie'
      then 'tied'

    when m.status = 'completed'
         and cm.result->>'win_type' = 'walkover'
      then 'walkover'

    when cm.result->>'win_type' = 'no_result'
      then 'no_result'

    else m.status::text
  end as status,

  m.winner_id,
  m.team_a_id,
  m.team_b_id,
  m.created_by,
  m.created_at,
  m.updated_at,

  cm.format_code as match_format,
  cm.rules_snapshot as format,
  cm.toss_won_by,
  cm.toss_decision,
  cm.toss_face,
  cm.toss_recorded_at,

  -- Existing MatchStartPhase has only the pre-live values. Once Cricket moves
  -- into innings-break/super-over/complete, expose `live` on the compatibility
  -- field while `cricket_phase` carries the exact phase.
  case cm.phase
    when 'toss'   then 'toss'
    when 'lineup' then 'lineup'
    when 'ready'  then 'ready'
    else 'live'
  end as start_phase,

  cm.openers_submitted_by,
  cm.openers_submitted_at,
  cm.scoring_mode,
  cm.result,
  cm.result_summary,
  cm.revised_conditions,
  cm.player_of_the_match_id,

  (
    select mp.user_id
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
    where mp.match_id = m.match_id
      and mp.team_side = 'team_a'
      and cmp.is_captain = true
      and mp.user_id is not null
    order by
      cmp.updated_at desc,
      mp.created_at asc
    limit 1
  ) as team_a_captain,

  (
    select mp.user_id
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
    where mp.match_id = m.match_id
      and mp.team_side = 'team_b'
      and cmp.is_captain = true
      and mp.user_id is not null
    order by
      cmp.updated_at desc,
      mp.created_at asc
    limit 1
  ) as team_b_captain

from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket';


grant select
  on public.cricket_match_details
  to anon, authenticated, service_role;


comment on view public.cricket_match_details is
  'Canonical Cricket aggregate. lifecycle_status is the generic parent '
  'lifecycle; cricket_phase is the exact Cricket phase; status/start_phase are '
  'compatibility projections for the current Cricket Flutter UI.';


create function public.list_my_cricket_matches()
returns setof public.cricket_match_details
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.*
  from public.cricket_match_details d
  where
    d.created_by = (select auth.uid())

    or public._is_match_captain(d.match_id)

    or exists (
      select 1
      from public.team_members tm
      where tm.team_id in (
        d.team_a_id,
        d.team_b_id
      )
        and tm.user_id = (select auth.uid())
        and tm.status = 'active'
    )

    or exists (
      select 1
      from public.match_players mp
      where mp.match_id = d.match_id
        and mp.user_id = (select auth.uid())
    )

    or exists (
      select 1
      from public.match_officials mo
      where mo.match_id = d.match_id
        and mo.user_id = (select auth.uid())
    )

  order by
    coalesce(
      d.scheduled_start_time,
      d.created_at
    ) desc;
$$;

revoke all
  on function public.list_my_cricket_matches()
  from public, anon;

grant execute
  on function public.list_my_cricket_matches()
  to authenticated;


-- =============================================================================
-- 11. Tournament live board returns Cricket-facing compatibility status
-- =============================================================================

create or replace function public.tournament_live_board(
  p_tournament_id uuid
)
returns table (
  match_id             uuid,
  venue                text,
  status               text,
  scheduled_start_time timestamptz,
  round                text,
  team_a_id            uuid,
  team_a_name          text,
  team_b_id            uuid,
  team_b_name          text,
  winner_id            uuid,
  result               jsonb,
  scorer_id            uuid,
  scorer_name          text,
  last_ball_at         timestamptz,
  innings_lines        jsonb
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    d.match_id,
    d.venue,
    d.status,
    d.scheduled_start_time,
    d.round,
    d.team_a_id,
    ta.team_name,
    d.team_b_id,
    tb.team_name,
    d.winner_id,
    d.result,
    mo.user_id,
    pr.display_name,

    (
      select max(md.recorded_at)
      from public.match_deliveries md
      where md.match_id = d.match_id
        and md.is_undone = false
    ),

    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'innings_number',
              mi.innings_number,
            'batting_team_id',
              case mi.batting_team_side
                when 'team_a' then d.team_a_id
                else d.team_b_id
              end,
            'total_runs',
              mis.total_runs,
            'total_wickets',
              mis.total_wickets,
            'legal_ball_count',
              mis.legal_ball_count
          )
          order by mi.innings_number
        )
        from public.match_innings mi
        join public.match_innings_state mis
          on mis.innings_id = mi.innings_id
        where mi.match_id = d.match_id
      ),
      '[]'::jsonb
    )

  from public.cricket_match_details d
  left join public.teams ta
    on ta.team_id = d.team_a_id
  left join public.teams tb
    on tb.team_id = d.team_b_id
  left join public.match_officials mo
    on mo.match_id = d.match_id
   and mo.role = 'scorer'
  left join public.profiles pr
    on pr.user_id = mo.user_id

  where d.tournament_id = p_tournament_id
    and exists (
      select 1
      from public.tournaments t
      where t.tournament_id = p_tournament_id
        and (
          (
            t.privacy = 'public'
            and t.status <> 'draft'
          )
          or public.is_tournament_organizer(
               p_tournament_id
             )
          or exists (
            select 1
            from public.tournament_teams tt
            where tt.tournament_id = p_tournament_id
              and (
                public.is_team_manager(tt.team_id)
                or (select auth.uid()) = any(tt.squad)
              )
          )
        )
    )

  order by d.scheduled_start_time asc;
$$;

revoke all
  on function public.tournament_live_board(uuid)
  from public, anon;

grant execute
  on function public.tournament_live_board(uuid)
  to authenticated;


-- =============================================================================
-- 12. Remove obsolete types/helpers
-- =============================================================================
--
-- NO CASCADE: an unexpected dependency must stop this destructive cleanup.
-- =============================================================================

drop type public.match_format;
drop type public.match_role;

drop function public._normalize_match_format(jsonb);

drop type public._legacy_match_start_phase;
drop type public._legacy_match_status;


-- =============================================================================
-- 13. Documentation
-- =============================================================================

comment on type public.cricket_match_phase is
  'Cricket-only match phase. Parent matches.status stores only generic lifecycle.';

comment on type public.cricket_toss_decision is
  'Cricket toss decision: bat or bowl.';

comment on type public.cricket_scoring_mode is
  'Cricket match scoring mode. The shared format-preset catalog stores its '
  'default scoring preference inside the Cricket config JSON instead of using '
  'this type directly.';

comment on type public.cricket_delivery_kind is
  'Cricket delivery/extras classification.';

comment on type public.cricket_wicket_kind is
  'Cricket dismissal classification.';

comment on column public.cricket_matches.phase is
  'Exact Cricket phase. innings_break/super_over are not parent lifecycle states.';

comment on column public.matches.status is
  'Cross-sport lifecycle only: scheduled, live, completed, abandoned, cancelled.';
