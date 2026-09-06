-- =============================================================================
-- seed_tournament_liveops_demo
-- =============================================================================
-- Puts the locked draw onto matchday so the Live Ops board (artboard 27) has
-- something to draw: two grounds live with scores mid-chase, one still to
-- start with nobody assigned to score it.
--
-- Run AFTER the draw is locked (seed_tournament_registration_demo + Lock &
-- Publish), which is what creates the fixtures this updates.
--
-- Idempotent: clears any innings it previously made before rebuilding.
-- =============================================================================

do $$
declare
  v_t        uuid;
  v_m1       uuid;
  v_m2       uuid;
  v_m3       uuid;
  v_organiser uuid;
  v_innings  uuid;
begin
  select tournament_id into v_t from public.tournaments order by created_at limit 1;
  if v_t is null then
    raise notice 'No tournament found — run the registration seed and lock the draw first.';
    return;
  end if;

  select user_id into v_organiser from public.profiles where username = 'saran';

  -- Fixtures in the order the console generated them.
  select match_id into v_m1 from public.matches
   where tournament_id = v_t order by bracket_match_number limit 1 offset 0;
  select match_id into v_m2 from public.matches
   where tournament_id = v_t order by bracket_match_number limit 1 offset 1;
  select match_id into v_m3 from public.matches
   where tournament_id = v_t order by bracket_match_number limit 1 offset 2;

  if v_m1 is null then
    raise notice 'No fixtures — lock the draw first.';
    return;
  end if;

  -- Start clean so the seed can be re-run.
  delete from public.match_innings where match_id in (v_m1, v_m2, v_m3);
  update public.matches
     set status = 'scheduled', actual_start_time = null
   where match_id in (v_m1, v_m2, v_m3);

  -- ── Ground 1: second innings, chase under way ───────────────────────────
  update public.matches
     set status = 'live',
         actual_start_time = now() - interval '2 hours',
         scheduled_start_time = now() - interval '2 hours'
   where match_id = v_m1;

  -- First innings closed at 161/7 off 20.
  insert into public.match_innings
    (match_id, innings_number, batting_team_side, bowling_team_side,
     overs_allocated, is_completed)
  values (v_m1, 1, 'team_a', 'team_b', 20.0, true)
  returning innings_id into v_innings;
  insert into public.match_innings_state
    (innings_id, match_id, innings_number, total_runs, total_wickets,
     legal_ball_count)
  values (v_innings, v_m1, 1, 161, 7, 120);

  -- Second innings live at 142/3 off 16.2 (98 legal balls).
  -- The target lives on match_innings_state only (match_innings.target_runs was
  -- a duplicate, dropped 2026-09-06).
  insert into public.match_innings
    (match_id, innings_number, batting_team_side, bowling_team_side,
     overs_allocated)
  values (v_m1, 2, 'team_b', 'team_a', 20.0)
  returning innings_id into v_innings;
  insert into public.match_innings_state
    (innings_id, match_id, innings_number, total_runs, total_wickets,
     legal_ball_count, target)
  values (v_innings, v_m1, 2, 142, 3, 98, 162);

  -- ── Ground 2: first innings still in progress ───────────────────────────
  update public.matches
     set status = 'live',
         actual_start_time = now() - interval '45 minutes',
         scheduled_start_time = now() - interval '45 minutes'
   where match_id = v_m2;

  insert into public.match_innings
    (match_id, innings_number, batting_team_side, bowling_team_side,
     overs_allocated)
  values (v_m2, 1, 'team_a', 'team_b', 20.0)
  returning innings_id into v_innings;
  insert into public.match_innings_state
    (innings_id, match_id, innings_number, total_runs, total_wickets,
     legal_ball_count)
  values (v_innings, v_m2, 1, 88, 2, 58);

  -- ── Ground 3: later today, still unassigned ─────────────────────────────
  update public.matches
     set status = 'scheduled',
         scheduled_start_time = now() + interval '4 hours'
   where match_id = v_m3;

  -- Both live grounds have a scorer; the third deliberately does not, so the
  -- cream "needs action" row has something to point at.
  delete from public.match_officials
   where match_id in (v_m1, v_m2, v_m3) and role = 'scorer';
  insert into public.match_officials (match_id, user_id, role, assigned_by)
  values (v_m1, v_organiser, 'scorer', v_organiser),
         (v_m2, v_organiser, 'scorer', v_organiser);

  -- "Last ball 40s ago" reads off match_deliveries, so give the live grounds
  -- a most-recent ball each. One legal delivery is enough for the staleness
  -- line; the scores above are the authority on the totals.
  insert into public.match_deliveries
    (innings_id, match_id, innings_number, seq, over_number, ball_in_over,
     is_legal_delivery, delivery_type, runs_off_bat, recorded_at, recorded_by)
  select mi.innings_id, mi.match_id, mi.innings_number, 9999, 16, 2,
         true, 'legal', 1,
         now() - interval '40 seconds', v_organiser
    from public.match_innings mi
   where mi.match_id = v_m1 and mi.innings_number = 2;

  insert into public.match_deliveries
    (innings_id, match_id, innings_number, seq, over_number, ball_in_over,
     is_legal_delivery, delivery_type, runs_off_bat, recorded_at, recorded_by)
  select mi.innings_id, mi.match_id, mi.innings_number, 9999, 9, 4,
         true, 'legal', 2,
         now() - interval '12 seconds', v_organiser
    from public.match_innings mi
   where mi.match_id = v_m2 and mi.innings_number = 1;

  update public.tournaments set status = 'live' where tournament_id = v_t;

  raise notice 'Live Ops demo ready.';
end $$;
