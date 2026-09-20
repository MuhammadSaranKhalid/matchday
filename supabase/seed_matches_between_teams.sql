-- =============================================================================
-- MOVED OUT OF supabase/migrations/ ON 2026-09-06
-- =============================================================================
-- This is demo data, not schema. It hardcodes two real accounts and their
-- teams, so on any database that does not already contain them every insert
-- fails on a foreign key — which is exactly how `supabase db reset` broke.
-- Migrations are now schema only (one table per migration); seed data lives
-- here and is opted into via [db.seed] sql_paths in config.toml.
--
-- The guard below makes the file a no-op when its subjects are absent, so it
-- is safe to add to sql_paths on any machine.
-- =============================================================================

-- =============================================================================
-- 20260822100000 · seed_matches_between_teams
-- =============================================================================
-- Seeds realistic matches between the two real registered accounts and their teams:
-- 1. Saran Strikers (Muhammad Saran: muhammadsarankhalid@gmail.com)
-- 2. Muazam Mavericks (Muazam Khalid: msarankhalid1@gmail.com)
--
-- Generates:
-- - Live Match: Saran Strikers vs Muazam Mavericks (Innings 1 in progress: 164/4)
-- - Completed Match: Saran Strikers vs Muazam Mavericks (Saran Strikers won by 18 runs)
-- - Scheduled Match: Muazam Mavericks vs Saran Strikers
-- - Toss Match: Saran Strikers vs Muazam Mavericks
-- =============================================================================

do $seed_matches$
declare
  -- Real User IDs
  v_saran_uid   constant uuid := '892b4f62-38bb-4108-89a6-2689b2e08e97';
  v_muazam_uid  constant uuid := '321a18b5-409a-422c-b32c-252c0c299c9d';

  -- Real Team IDs
  t_saran_strikers constant uuid := '4cdc49ef-fb17-4865-9b39-56a5ff85bb9d';
  t_muazam_mavs    constant uuid := '04821e6f-d948-4871-805d-5be7c1ee5a7f';

  -- Saran Strikers Unclaimed Players
  u_babar       constant uuid := 'a30cf379-4d67-4620-a0d8-a4c85a0b0575';
  u_ali         constant uuid := '276e12aa-9245-491c-8c8f-cca62dbbdd65';
  u_shaheen     constant uuid := 'aaaaaaaa-0000-4000-8000-000000000001';
  u_rizwan      constant uuid := 'aaaaaaaa-0000-4000-8000-000000000002';
  u_naseem      constant uuid := 'aaaaaaaa-0000-4000-8000-000000000003';

  -- Muazam Mavericks Unclaimed Players
  u_imad        constant uuid := 'bbbbbbbb-0000-4000-8000-000000000001';
  u_haris       constant uuid := 'bbbbbbbb-0000-4000-8000-000000000002';
  u_wasim       constant uuid := 'bbbbbbbb-0000-4000-8000-000000000003';
  u_amir        constant uuid := 'bbbbbbbb-0000-4000-8000-000000000004';
  u_shadab      constant uuid := 'bbbbbbbb-0000-4000-8000-000000000005';

  -- Match IDs
  m_live_1      constant uuid := '11111111-1111-1111-1111-111111111101';
  m_completed_2 constant uuid := '22222222-2222-2222-2222-222222222202';
  m_scheduled_3 constant uuid := '33333333-3333-3333-3333-333333333303';
  m_toss_4      constant uuid := '44444444-4444-4444-4444-444444444404';

  -- Match Players for Live Match (Fixed IDs)
  mp_live_saran   constant uuid := '11111111-4444-4444-4444-444444440001';
  mp_live_babar   constant uuid := '11111111-4444-4444-4444-444444440002';
  mp_live_rizwan  constant uuid := '11111111-4444-4444-4444-444444440003';
  mp_live_shaheen constant uuid := '11111111-4444-4444-4444-444444440004';
  mp_live_ali     constant uuid := '11111111-4444-4444-4444-444444440005';

  mp_live_muazam  constant uuid := '11111111-4444-4444-4444-444444440011';
  mp_live_imad    constant uuid := '11111111-4444-4444-4444-444444440012';
  mp_live_haris   constant uuid := '11111111-4444-4444-4444-444444440013';
  mp_live_wasim   constant uuid := '11111111-4444-4444-4444-444444440014';
  mp_live_amir    constant uuid := '11111111-4444-4444-4444-444444440015';
  mp_live_shadab  constant uuid := '11111111-4444-4444-4444-444444440016';

  -- Match Players for Completed Match
  mp_comp_saran   constant uuid := '22222222-4444-4444-4444-444444440001';
  mp_comp_babar   constant uuid := '22222222-4444-4444-4444-444444440002';
  mp_comp_rizwan  constant uuid := '22222222-4444-4444-4444-444444440003';
  mp_comp_ali     constant uuid := '22222222-4444-4444-4444-444444440004';
  mp_comp_muazam  constant uuid := '22222222-4444-4444-4444-444444440011';
  mp_comp_haris   constant uuid := '22222222-4444-4444-4444-444444440012';
  mp_comp_wasim   constant uuid := '22222222-4444-4444-4444-444444440013';

  -- Innings IDs
  inn_live_1_1  constant uuid := '11111111-0000-0000-0000-000000000001';
  inn_comp_2_1  constant uuid := '22222222-0000-0000-0000-000000000001';
  inn_comp_2_2  constant uuid := '22222222-0000-0000-0000-000000000002';
begin
  if not exists (select 1 from public.teams where team_id = t_saran_strikers)
     or not exists (select 1 from public.teams where team_id = t_muazam_mavs) then
    raise notice 'seed_matches_between_teams: target teams absent — skipping.';
    return;
  end if;

  -- 0. Clean up prior matches and dummy test users
  delete from public.matches;
  delete from auth.users where email like '%@local.test';

  -- ===========================================================================
  -- 1. LIVE MATCH: Saran Strikers vs Muazam Mavericks
  -- ===========================================================================
  insert into public.matches (
    match_id, match_type, match_format, venue, scheduled_start_time,
    actual_start_time, status, start_phase, toss_won_by, toss_decision,
    toss_recorded_at, team_a_id, team_b_id, team_a_captain, team_b_captain,
    created_by
  ) values (
    m_live_1, 'friendly', 't20', 'Model Town Sports Complex, Lahore',
    now() - interval '2 hours', now() - interval '1 hour 45 minutes',
    'live', 'live', t_saran_strikers, 'bat',
    now() - interval '1 hour 50 minutes',
    t_saran_strikers, t_muazam_mavs, v_saran_uid, v_muazam_uid,
    v_saran_uid
  ) on conflict (match_id) do update set
    status = 'live',
    start_phase = 'live',
    updated_at = now();

  insert into public.match_teams (match_id, team_id, team_name, team_side, is_batting_first)
  values
    (m_live_1, t_saran_strikers, 'Saran Strikers', 'team_a', true),
    (m_live_1, t_muazam_mavs, 'Muazam Mavericks', 'team_b', false)
  on conflict (match_id, team_side) do nothing;

  -- Match Players for Live Match
  insert into public.match_players (
    match_player_id, match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi, batting_order
  ) values
    (mp_live_saran,   m_live_1, 'team_a', v_saran_uid,  null,      'Muhammad Saran', 'captain',       true, 1),
    (mp_live_babar,   m_live_1, 'team_a', null,         u_babar,   'Babar',          'player',        true, 2),
    (mp_live_rizwan,  m_live_1, 'team_a', null,         u_rizwan,  'Rizwan',         'wicket_keeper', true, 3),
    (mp_live_shaheen, m_live_1, 'team_a', null,         u_shaheen, 'Shaheen',        'player',        true, 4),
    (mp_live_ali,     m_live_1, 'team_a', null,         u_ali,     'Ali',            'player',        true, 5),
    (mp_live_muazam,  m_live_1, 'team_b', v_muazam_uid, null,      'Muazam Khalid',  'captain',       true, 1),
    (mp_live_imad,    m_live_1, 'team_b', null,         u_imad,    'Imad',           'player',        true, 2),
    (mp_live_haris,   m_live_1, 'team_b', null,         u_haris,   'Haris',          'wicket_keeper', true, 3),
    (mp_live_wasim,   m_live_1, 'team_b', null,         u_wasim,   'Wasim',          'player',        true, 4),
    (mp_live_amir,    m_live_1, 'team_b', null,         u_amir,    'Amir',           'player',        true, 5),
    (mp_live_shadab,  m_live_1, 'team_b', null,         u_shadab,  'Shadab',         'player',        true, 6)
  on conflict (match_player_id) do nothing;

  -- 1st Innings
  insert into public.cricket_match_innings (
    innings_id, match_id, innings_number, batting_team_side, bowling_team_side,
    overs_allocated, is_completed, start_time
  ) values (
    inn_live_1_1, m_live_1, 1, 'team_a', 'team_b',
    20.0, false, now() - interval '1 hour 45 minutes'
  ) on conflict (innings_id) do nothing;

  -- Live Innings State (164/4 at 18.4 overs)
  insert into public.cricket_match_innings_state (
    innings_id, match_id, innings_number,
    striker_id, non_striker_id, bowler_id,
    total_runs, total_wickets, legal_ball_count,
    is_free_hit_next, version
  ) values (
    inn_live_1_1, m_live_1, 1,
    mp_live_saran, mp_live_shaheen, mp_live_muazam,
    164, 4, 112,
    false, 113
  ) on conflict (innings_id) do update set
    total_runs = 164, total_wickets = 4, legal_ball_count = 112,
    striker_id = mp_live_saran, non_striker_id = mp_live_shaheen, bowler_id = mp_live_muazam,
    updated_at = now();

  -- Pre-materialized Batsman Stats for Live Match
  insert into public.match_batsman_stats (
    innings_id, player_id, batting_position, runs, balls_faced, dots, fours, sixes, is_out, dismissal_text
  ) values
    (inn_live_1_1, mp_live_saran,   1, 48, 34, 8, 5, 2, false, null),
    (inn_live_1_1, mp_live_babar,   2, 54, 38, 10, 6, 1, true, 'c Imad b Amir'),
    (inn_live_1_1, mp_live_rizwan,  3, 28, 19, 4, 3, 1, true, 'b Wasim'),
    (inn_live_1_1, mp_live_ali,     4, 12, 9, 2, 1, 0, true, 'lbw b Muazam Khalid'),
    (inn_live_1_1, mp_live_shaheen, 5, 18, 12, 3, 2, 1, false, null)
  on conflict (innings_id, player_id) do update set runs = excluded.runs, balls_faced = excluded.balls_faced;

  -- Pre-materialized Bowler Stats for Live Match
  insert into public.match_bowler_stats (
    innings_id, player_id, bowling_position, legal_balls_bowled, maidens, runs_conceded, wickets, dot_balls_bowled
  ) values
    (inn_live_1_1, mp_live_muazam, 1, 22, 0, 36, 1, 7),
    (inn_live_1_1, mp_live_amir,   2, 24, 0, 32, 1, 10),
    (inn_live_1_1, mp_live_wasim,  3, 24, 0, 38, 1, 8),
    (inn_live_1_1, mp_live_shadab, 4, 24, 0, 42, 1, 6)
  on conflict (innings_id, player_id) do update set legal_balls_bowled = excluded.legal_balls_bowled, runs_conceded = excluded.runs_conceded;

  -- ===========================================================================
  -- 2. COMPLETED MATCH: Saran Strikers vs Muazam Mavericks
  -- ===========================================================================
  insert into public.matches (
    match_id, match_type, match_format, venue, scheduled_start_time,
    actual_start_time, completed_at, status, start_phase, toss_won_by,
    toss_decision, toss_recorded_at, team_a_id, team_b_id,
    team_a_captain, team_b_captain, result_summary, created_by
  ) values (
    m_completed_2, 'friendly', 't20', 'Gaddafi Stadium, Lahore',
    now() - interval '2 days', now() - interval '2 days',
    now() - interval '2 days' + interval '3 hours 20 minutes',
    'completed', 'live', t_saran_strikers, 'bat',
    now() - interval '2 days' - interval '15 minutes',
    t_saran_strikers, t_muazam_mavs, v_saran_uid, v_muazam_uid,
    '{"winner": "team_a", "margin": "18 runs", "text": "Saran Strikers won by 18 runs"}'::jsonb,
    v_saran_uid
  ) on conflict (match_id) do update set
    status = 'completed',
    result_summary = '{"winner": "team_a", "margin": "18 runs", "text": "Saran Strikers won by 18 runs"}'::jsonb,
    updated_at = now();

  insert into public.match_teams (match_id, team_id, team_name, team_side, is_batting_first)
  values
    (m_completed_2, t_saran_strikers, 'Saran Strikers', 'team_a', true),
    (m_completed_2, t_muazam_mavs, 'Muazam Mavericks', 'team_b', false)
  on conflict (match_id, team_side) do nothing;

  -- Match Players for Completed Match
  insert into public.match_players (
    match_player_id, match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi, batting_order
  ) values
    (mp_comp_saran,  m_completed_2, 'team_a', v_saran_uid,  null,     'Muhammad Saran', 'captain',       true, 1),
    (mp_comp_babar,  m_completed_2, 'team_a', null,         u_babar,  'Babar',          'player',        true, 2),
    (mp_comp_rizwan, m_completed_2, 'team_a', null,         u_rizwan, 'Rizwan',         'wicket_keeper', true, 3),
    (mp_comp_ali,    m_completed_2, 'team_a', null,         u_ali,    'Ali',            'player',        true, 4),
    (mp_comp_muazam, m_completed_2, 'team_b', v_muazam_uid, null,     'Muazam Khalid',  'captain',       true, 1),
    (mp_comp_haris,  m_completed_2, 'team_b', null,         u_haris,  'Haris',          'wicket_keeper', true, 2),
    (mp_comp_wasim,  m_completed_2, 'team_b', null,         u_wasim,  'Wasim',          'player',        true, 3)
  on conflict (match_player_id) do nothing;

  -- 1st Innings (Saran Strikers: 186/6)
  insert into public.cricket_match_innings (
    innings_id, match_id, innings_number, batting_team_side, bowling_team_side,
    overs_allocated, is_completed, start_time, end_time
  ) values (
    inn_comp_2_1, m_completed_2, 1, 'team_a', 'team_b',
    20.0, true, now() - interval '2 days', now() - interval '2 days' + interval '1 hour 35 minutes'
  ) on conflict (innings_id) do nothing;

  -- 1st Innings State
  insert into public.cricket_match_innings_state (
    innings_id, match_id, innings_number,
    striker_id, non_striker_id, bowler_id,
    total_runs, total_wickets, legal_ball_count,
    version
  ) values (
    inn_comp_2_1, m_completed_2, 1,
    null, null, null,
    186, 6, 120,
    120
  ) on conflict (innings_id) do update set total_runs = 186, total_wickets = 6, legal_ball_count = 120;

  -- 2nd Innings (Muazam Mavericks: 168/8, Target: 187)
  insert into public.cricket_match_innings (
    innings_id, match_id, innings_number, batting_team_side, bowling_team_side,
    overs_allocated, is_completed, start_time, end_time
  ) values (
    inn_comp_2_2, m_completed_2, 2, 'team_b', 'team_a',
    20.0, true, now() - interval '2 days' + interval '1 hour 50 minutes', now() - interval '2 days' + interval '3 hours 20 minutes'
  ) on conflict (innings_id) do nothing;

  -- 2nd Innings State
  insert into public.cricket_match_innings_state (
    innings_id, match_id, innings_number,
    striker_id, non_striker_id, bowler_id,
    total_runs, total_wickets, legal_ball_count,
    target, version
  ) values (
    inn_comp_2_2, m_completed_2, 2,
    null, null, null,
    168, 8, 120,
    187, 120
  ) on conflict (innings_id) do update set total_runs = 168, total_wickets = 8, legal_ball_count = 120, target = 187;

  -- Innings 1 Batsman Stats
  insert into public.match_batsman_stats (
    innings_id, player_id, batting_position, runs, balls_faced, dots, fours, sixes, is_out, dismissal_text
  ) values
    (inn_comp_2_1, mp_comp_saran,  1, 72, 44, 10, 8, 3, true, 'c Haris b Wasim'),
    (inn_comp_2_1, mp_comp_babar,  2, 45, 30, 8,  5, 1, true, 'b Muazam Khalid'),
    (inn_comp_2_1, mp_comp_rizwan, 3, 34, 22, 5,  3, 1, true, 'c Wasim b Shadab'),
    (inn_comp_2_1, mp_comp_ali,    4, 18, 14, 4,  2, 0, false, null)
  on conflict (innings_id, player_id) do update set runs = excluded.runs, balls_faced = excluded.balls_faced;

  -- Innings 2 Batsman Stats
  insert into public.match_batsman_stats (
    innings_id, player_id, batting_position, runs, balls_faced, dots, fours, sixes, is_out, dismissal_text
  ) values
    (inn_comp_2_2, mp_comp_muazam, 1, 64, 40, 9, 7, 2, true, 'c Babar b Shaheen'),
    (inn_comp_2_2, mp_comp_haris,  2, 38, 26, 6, 4, 1, true, 'run out (Muhammad Saran)'),
    (inn_comp_2_2, mp_comp_wasim,  3, 24, 18, 4, 2, 1, true, 'b Ali')
  on conflict (innings_id, player_id) do update set runs = excluded.runs, balls_faced = excluded.balls_faced;

  -- ===========================================================================
  -- 3. SCHEDULED MATCH: Muazam Mavericks vs Saran Strikers
  -- ===========================================================================
  insert into public.matches (
    match_id, match_type, match_format, venue, scheduled_start_time,
    status, start_phase, team_a_id, team_b_id, team_a_captain, team_b_captain,
    created_by
  ) values (
    m_scheduled_3, 'friendly', 't20', 'Rawalpindi Cricket Stadium',
    now() + interval '1 day' + interval '4 hours',
    'scheduled', 'toss', t_muazam_mavs, t_saran_strikers,
    v_muazam_uid, v_saran_uid, v_muazam_uid
  ) on conflict (match_id) do update set
    status = 'scheduled',
    team_a_id = t_muazam_mavs,
    team_b_id = t_saran_strikers,
    updated_at = now();

  insert into public.match_teams (match_id, team_id, team_name, team_side)
  values
    (m_scheduled_3, t_muazam_mavs, 'Muazam Mavericks', 'team_a'),
    (m_scheduled_3, t_saran_strikers, 'Saran Strikers', 'team_b')
  on conflict (match_id, team_side) do nothing;

  -- ===========================================================================
  -- 4. TOSS PHASE MATCH: Saran Strikers vs Muazam Mavericks
  -- ===========================================================================
  insert into public.matches (
    match_id, match_type, match_format, venue, scheduled_start_time,
    status, start_phase, toss_won_by, toss_decision, toss_recorded_at,
    team_a_id, team_b_id, team_a_captain, team_b_captain, created_by
  ) values (
    m_toss_4, 'friendly', 't20', 'Bugti Stadium, Quetta',
    now() + interval '30 minutes',
    'toss', 'lineup', t_saran_strikers, 'bat', now() - interval '5 minutes',
    t_saran_strikers, t_muazam_mavs, v_saran_uid, v_muazam_uid, v_saran_uid
  ) on conflict (match_id) do update set
    status = 'toss',
    start_phase = 'lineup',
    team_a_id = t_saran_strikers,
    team_b_id = t_muazam_mavs,
    updated_at = now();

  insert into public.match_teams (match_id, team_id, team_name, team_side, is_batting_first)
  values
    (m_toss_4, t_saran_strikers, 'Saran Strikers', 'team_a', true),
    (m_toss_4, t_muazam_mavs, 'Muazam Mavericks', 'team_b', false)
  on conflict (match_id, team_side) do nothing;

end $seed_matches$;
