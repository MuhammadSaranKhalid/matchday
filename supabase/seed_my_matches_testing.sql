-- =============================================================================
-- seed_my_matches_testing.sql — test data for the My Matches screen
-- =============================================================================
-- Every state My Matches.dc.html renders, for the signed-in tester.
--
--   CONFIRMED
--     · toss-ready   captain, starts in 20 min → red top rule, TOSS gutter,
--                    ink "Start match · toss" action
--     · live         status live → pulsing dot, LIVE, "Started HH:MM"
--     · innings break status innings_break → BREAK in the gutter
--     · calm today   later today, no escalation
--     · tomorrow     TOMORROW · <day> group
--     · future       plain date group, tournament fixture
--     · opponent TBC bracket fixture with no second team yet
--   PAST  (6 rows, so the windowed "SEE ALL 6 MATCHES" footer appears)
--     · won · lost · tied · no result · walkover · abandoned
--
-- Past scores are aggregated from cricket_match_deliveries by the client, so real
-- deliveries are generated for the four matches that were actually played.
-- striker/bowler are left NULL deliberately — those FKs are nullable, so no
-- lineup rows are needed just to make a scorecard total.
--
-- RUN IN THE SUPABASE DASHBOARD SQL EDITOR. Idempotent: it deletes and
-- recreates only the fixed uuids below.
--
-- PREREQUISITE: sign in on the emulator first. This looks your account up and
-- never creates it — an auth row for a real address would collide with the
-- OTP / Google identity you actually sign in with.
-- =============================================================================

do $seed_my_matches$
declare
  v_me         uuid;
  t_mine       constant uuid := 'cc000000-0000-4000-8000-000000000001';
  t_shalimar   constant uuid := 'cc000000-0000-4000-8000-000000000002';
  t_gulberg    constant uuid := 'cc000000-0000-4000-8000-000000000003';
  t_modeltown  constant uuid := 'cc000000-0000-4000-8000-000000000004';
  t_johar      constant uuid := 'cc000000-0000-4000-8000-000000000005';
  t_ravi       constant uuid := 'cc000000-0000-4000-8000-000000000006';
  t_cavalry    constant uuid := 'cc000000-0000-4000-8000-000000000007';
  v_tourn      constant uuid := 'aa000000-0000-4000-8000-000000000001';

  v_fmt        constant jsonb := jsonb_build_object(
                 'overs_per_innings', 16, 'players_per_team', 11,
                 'balls_per_over', 6, 'max_overs_per_bowler', 4,
                 'innings_per_side', 1, 'ball_type', 'tape');
  r record;
begin
  select id into v_me from auth.users
   where lower(email) = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_me is null then
    raise exception
      'No auth user for muhammadsarankhalid@gmail.com. Sign in on the emulator first.';
  end if;

  -- Teams must exist. seed_challenges_testing.sql creates them; create the two
  -- this file needs if it has not been run.
  if not exists (select 1 from public.teams where team_id = t_mine) then
    raise exception
      'Run seed_challenges_testing.sql first — it creates Saran Strikers and the opponents.';
  end if;

  -- ── Clean up ──────────────────────────────────────────────────────────────
  delete from public.cricket_match_deliveries where match_id in (
    select match_id from public.matches
     where match_id::text like 'ff000000-0000-4000-8000-%');
  delete from public.cricket_match_innings_state where match_id in (
    select match_id from public.matches
     where match_id::text like 'ff000000-0000-4000-8000-%');
  delete from public.cricket_match_innings where match_id in (
    select match_id from public.matches
     where match_id::text like 'ff000000-0000-4000-8000-%');
  delete from public.matches where match_id::text like 'ff000000-0000-4000-8000-%';
  delete from public.tournaments where tournament_id = v_tourn;

  -- A competition, so a tournament fixture has something to belong to.
  insert into public.tournaments (
    tournament_id, tournament_name, tournament_type, privacy, status,
    location, created_by, created_at, updated_at
  ) values (
    v_tourn, 'Ravi Cup T20', 'knockout', 'public', 'live',
    jsonb_build_object('city', 'Lahore'), v_me, now() - interval '20 days', now()
  );

  -- ── CONFIRMED ─────────────────────────────────────────────────────────────
  -- team_a_captain = me on every row, so the role strip prints CAPTAIN · PICK XI
  -- (a duty, with the trailing arrow) and the toss window can open.
  for r in
    select * from (values
      -- id, opponent, start, status, tournament, actual_start
      ('ff000000-0000-4000-8000-000000000001'::uuid, t_shalimar,
       now() + interval '20 minutes', 'scheduled', null::uuid, null::timestamptz),
      ('ff000000-0000-4000-8000-000000000002'::uuid, t_gulberg,
       now() - interval '40 minutes', 'live', null::uuid, now() - interval '40 minutes'),
      ('ff000000-0000-4000-8000-000000000003'::uuid, t_modeltown,
       now() - interval '75 minutes', 'innings_break', null::uuid, now() - interval '75 minutes'),
      ('ff000000-0000-4000-8000-000000000004'::uuid, t_johar,
       now() + interval '9 hours', 'scheduled', null::uuid, null::timestamptz),
      ('ff000000-0000-4000-8000-000000000005'::uuid, t_ravi,
       now() + interval '1 day' + interval '3 hours', 'scheduled', null::uuid, null::timestamptz),
      ('ff000000-0000-4000-8000-000000000006'::uuid, t_cavalry,
       now() + interval '6 days', 'scheduled', v_tourn, null::timestamptz)
    ) as v(mid, opp, starts, st, tid, actual)
  loop
    insert into public.matches (
      match_id, match_type, match_format, tournament_id,
      team_a_id, team_b_id, team_a_captain, team_b_captain,
      format, venue, scheduled_start_time, actual_start_time,
      toss_won_by, toss_decision, start_phase, status, created_by,
      created_at, updated_at
    ) values (
      r.mid,
      case when r.tid is null then 'friendly'::public.match_type
           else 'tournament'::public.match_type end,
      't20', r.tid,
      t_mine, r.opp, v_me, null,
      v_fmt, 'Gaddafi Ground B', r.starts, r.actual,
      case when r.st in ('live','innings_break') then t_mine else null end,
      case when r.st in ('live','innings_break') then 'bat'::public.toss_decision else null end,
      case when r.st in ('live','innings_break') then 'live'::public.match_start_phase
           else 'toss'::public.match_start_phase end,
      r.st::public.match_status, v_me,
      now() - interval '5 days', now()
    );
  end loop;

  -- Opponent TBC — a bracket fixture whose second side is not yet decided.
  insert into public.matches (
    match_id, match_type, match_format, tournament_id, stage, round,
    team_a_id, team_b_id, team_a_captain,
    format, venue, scheduled_start_time, start_phase, status, created_by,
    created_at, updated_at
  ) values (
    'ff000000-0000-4000-8000-000000000007',
    'tournament', 't20', v_tourn, 'final', 'Final',
    t_mine, null, v_me,
    v_fmt, 'Gaddafi Ground B', now() + interval '11 days',
    'toss', 'scheduled', v_me, now() - interval '5 days', now()
  );

  -- ── PAST ──────────────────────────────────────────────────────────────────
  -- toss_won_by = my team + 'bat' so innings 1 is mine; the client derives the
  -- batting side from the toss when bucketing deliveries.
  for r in
    select * from (values
      ('ff000000-0000-4000-8000-000000000011'::uuid, t_shalimar, 3,
       'completed', 'Strikers won by 16 runs', true, true),
      ('ff000000-0000-4000-8000-000000000012'::uuid, t_gulberg, 9,
       'completed', 'Giants won by 16 runs', true, false),
      ('ff000000-0000-4000-8000-000000000013'::uuid, t_modeltown, 16,
       'tied', 'Match tied · scores level', true, true),
      ('ff000000-0000-4000-8000-000000000014'::uuid, t_johar, 23,
       'no_result', 'No result · rain after 9 overs', true, true),
      ('ff000000-0000-4000-8000-000000000015'::uuid, t_ravi, 30,
       'walkover', 'Awarded to Saran Strikers', false, true),
      ('ff000000-0000-4000-8000-000000000016'::uuid, t_cavalry, 37,
       'abandoned', 'Abandoned before the toss', false, true)
    ) as v(mid, opp, days_ago, st, descr, played, home_wins)
  loop
    insert into public.matches (
      match_id, match_type, match_format,
      team_a_id, team_b_id, team_a_captain,
      format, venue, scheduled_start_time, actual_start_time, completed_at,
      toss_won_by, toss_decision, start_phase, status, result, created_by,
      created_at, updated_at
    ) values (
      r.mid, 'friendly', 't20',
      t_mine, r.opp, v_me,
      v_fmt, 'Nishat Park',
      now() - (r.days_ago || ' days')::interval,
      case when r.played then now() - (r.days_ago || ' days')::interval end,
      now() - (r.days_ago || ' days')::interval + interval '3 hours',
      t_mine, 'bat', 'live', r.st::public.match_status,
      jsonb_build_object('description', r.descr),
      v_me,
      now() - (r.days_ago || ' days')::interval,
      now() - (r.days_ago || ' days')::interval
    );

    -- Only the matches that were actually bowled get innings and deliveries.
    -- A walkover and an abandonment must show no score line at all.
    if r.played then
      insert into public.cricket_match_innings (
        innings_id, match_id, innings_number,
        batting_team_side, bowling_team_side, overs_allocated, is_completed
      ) values
        (('fa000000-0000-4000-8000-' || right(r.mid::text, 12))::uuid,
         r.mid, 1, 'team_a', 'team_b', 16.0, true),
        (('fb000000-0000-4000-8000-' || right(r.mid::text, 12))::uuid,
         r.mid, 2, 'team_b', 'team_a', 16.0, true);

      -- 96 legal deliveries per innings. The run pattern is fixed so the two
      -- totals differ predictably and the winner is unambiguous; innings 2 of
      -- the tied match is nudged to level the scores.
      insert into public.cricket_match_deliveries (
        innings_id, match_id, innings_number, seq, over_number, ball_in_over,
        is_legal_delivery, delivery_type, runs_off_bat, is_wicket, wicket_type,
        idempotency_key
      )
      select
        case when inn = 1
          then ('fa000000-0000-4000-8000-' || right(r.mid::text, 12))::uuid
          else ('fb000000-0000-4000-8000-' || right(r.mid::text, 12))::uuid end,
        r.mid, inn, i, (i - 1) / 6, ((i - 1) % 6) + 1,
        true, 'legal',
        -- 8 runs per over vs 7: whichever side is meant to win gets the
        -- higher pattern, so the aggregated score agrees with the sentence.
        -- A tie gives both innings the same one.
        case
          when r.st = 'tied' then (array[1,0,2,1,0,4])[((i - 1) % 6) + 1]
          when (inn = 1) = r.home_wins then (array[1,0,2,1,0,4])[((i - 1) % 6) + 1]
          else (array[1,0,1,2,0,3])[((i - 1) % 6) + 1]
        end,
        (i % 13 = 0), case when i % 13 = 0 then 'bowled'::public.wicket_kind end,
        r.mid::text || '-' || inn || '-' || i
      from generate_series(1, 96) as i, generate_series(1, 2) as inn;
    end if;
  end loop;

  raise notice 'Seeded 7 confirmed + 6 past matches for %', v_me;
end
$seed_my_matches$;

-- Sanity read — expect 7 confirmed, 6 past, and two innings totals per played match.
select
  m.status::text,
  m.result->>'description' as sentence,
  sum(case when d.innings_number = 1 then d.runs_off_bat + d.extra_runs end) as mine,
  sum(case when d.innings_number = 2 then d.runs_off_bat + d.extra_runs end) as theirs
from public.matches m
left join public.cricket_match_deliveries d on d.match_id = m.match_id
where m.match_id::text like 'ff000000-0000-4000-8000-0000000000%'
  and m.status in ('completed','tied','no_result','walkover','abandoned')
group by m.match_id, m.status, m.result, m.scheduled_start_time
order by m.scheduled_start_time desc;
