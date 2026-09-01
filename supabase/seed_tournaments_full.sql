-- ============================================================================
-- MATCHDAY TOURNAMENT SEED SCRIPT
-- Populates 4 comprehensive tournaments (League, Knockout, Round Robin, Completed)
-- For user: muhammadsarankhalid@gmail.com (892b4f62-38bb-4108-89a6-2689b2e08e97)
-- With 45+ registered teams, standings, fixtures, brackets, and awards.
-- ============================================================================

DO $$
DECLARE
  v_user_id uuid := '892b4f62-38bb-4108-89a6-2689b2e08e97';
  
  -- Tournament IDs
  v_t1_id uuid := '11111111-1111-1111-1111-111111111111'; -- League (Live)
  v_t2_id uuid := '22222222-2222-2222-2222-222222222222'; -- Knockout (Live)
  v_t3_id uuid := '33333333-3333-3333-3333-333333333333'; -- Round Robin (Registration)
  v_t4_id uuid := '44444444-4444-4444-4444-444444444444'; -- Knockout (Completed)

  -- Team IDs array (45 teams)
  v_team_ids uuid[] := ARRAY[
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000002'::uuid,
    'a0000000-0000-0000-0000-000000000003'::uuid,
    'a0000000-0000-0000-0000-000000000004'::uuid,
    'a0000000-0000-0000-0000-000000000005'::uuid,
    'a0000000-0000-0000-0000-000000000006'::uuid,
    'a0000000-0000-0000-0000-000000000007'::uuid,
    'a0000000-0000-0000-0000-000000000008'::uuid,
    'a0000000-0000-0000-0000-000000000009'::uuid,
    'a0000000-0000-0000-0000-000000000010'::uuid,
    'a0000000-0000-0000-0000-000000000011'::uuid,
    'a0000000-0000-0000-0000-000000000012'::uuid,
    'a0000000-0000-0000-0000-000000000013'::uuid,
    'a0000000-0000-0000-0000-000000000014'::uuid,
    'a0000000-0000-0000-0000-000000000015'::uuid,
    'a0000000-0000-0000-0000-000000000016'::uuid,
    'a0000000-0000-0000-0000-000000000017'::uuid,
    'a0000000-0000-0000-0000-000000000018'::uuid,
    'a0000000-0000-0000-0000-000000000019'::uuid,
    'a0000000-0000-0000-0000-000000000020'::uuid,
    'a0000000-0000-0000-0000-000000000021'::uuid,
    'a0000000-0000-0000-0000-000000000022'::uuid,
    'a0000000-0000-0000-0000-000000000023'::uuid,
    'a0000000-0000-0000-0000-000000000024'::uuid,
    'a0000000-0000-0000-0000-000000000025'::uuid,
    'a0000000-0000-0000-0000-000000000026'::uuid,
    'a0000000-0000-0000-0000-000000000027'::uuid,
    'a0000000-0000-0000-0000-000000000028'::uuid,
    'a0000000-0000-0000-0000-000000000029'::uuid,
    'a0000000-0000-0000-0000-000000000030'::uuid,
    'a0000000-0000-0000-0000-000000000031'::uuid,
    'a0000000-0000-0000-0000-000000000032'::uuid,
    'a0000000-0000-0000-0000-000000000033'::uuid,
    'a0000000-0000-0000-0000-000000000034'::uuid,
    'a0000000-0000-0000-0000-000000000035'::uuid,
    'a0000000-0000-0000-0000-000000000036'::uuid,
    'a0000000-0000-0000-0000-000000000037'::uuid,
    'a0000000-0000-0000-0000-000000000038'::uuid,
    'a0000000-0000-0000-0000-000000000039'::uuid,
    'a0000000-0000-0000-0000-000000000040'::uuid,
    'a0000000-0000-0000-0000-000000000041'::uuid,
    'a0000000-0000-0000-0000-000000000042'::uuid,
    'a0000000-0000-0000-0000-000000000043'::uuid,
    'a0000000-0000-0000-0000-000000000044'::uuid,
    'a0000000-0000-0000-0000-000000000045'::uuid
  ];

  v_team_names text[] := ARRAY[
    'Lahore Lions', 'Karachi Kingsmen', 'Islamabad United XI', 'Rawalpindi Royals',
    'Peshawar Panthers', 'Quetta Qalandars', 'Multan Mavericks', 'Faisalabad Falcons',
    'Sialkot Stallions', 'Gujranwala Gladiators', 'Hyderabad Hawks', 'Abbottabad Aces',
    'Bahawalpur Blazers', 'Sargodha Strikers', 'Sheikhupura Stars', 'Mirpur Monarchs',
    'Sukkur Scorpions', 'Larkana Legends', 'Gwadar Guardians', 'Gilgit Giants',
    'Muzaffarabad Mustangs', 'Kasur Knights', 'Jhang Jaguars', 'Okara Outlaws',
    'Sahiwal Smashers', 'Mardan Meteors', 'Swat Storm', 'Dera Ismail Dynamos',
    'Bannu Blasters', 'Kohat Kings', 'Vehari Vipers', 'Attock Avengers',
    'Chakwal Cobras', 'Jhelum Jets', 'Gujrat Griffins', 'Mandi Bulls',
    'Hafizabad Hitters', 'Chiniot Crusaders', 'Khanewal Kings', 'Rahim Yar Riders',
    'Turbat Titans', 'Zhob Zebras', 'Chitral Cheetahs', 'Hunza Hunters', 'Skardu Spartans'
  ];

  v_monograms text[] := ARRAY[
    'LL', 'KK', 'IU', 'RR', 'PP', 'QQ', 'MM', 'FF',
    'SS', 'GG', 'HH', 'AA', 'BB', 'SR', 'SH', 'MM',
    'SC', 'LL', 'GG', 'GI', 'MU', 'KK', 'JJ', 'OO',
    'SM', 'ME', 'SW', 'DI', 'BB', 'KK', 'VV', 'AV',
    'CC', 'JJ', 'GR', 'MB', 'HH', 'CR', 'KW', 'RY',
    'TT', 'ZZ', 'CH', 'HU', 'SK'
  ];

  v_cities text[] := ARRAY[
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi', 'Peshawar', 'Quetta', 'Multan', 'Faisalabad',
    'Sialkot', 'Gujranwala', 'Hyderabad', 'Abbottabad', 'Bahawalpur', 'Sargodha', 'Sheikhupura', 'Mirpur',
    'Sukkur', 'Larkana', 'Gwadar', 'Gilgit', 'Muzaffarabad', 'Kasur', 'Jhang', 'Okara',
    'Sahiwal', 'Mardan', 'Swat', 'Dera Ismail Khan', 'Bannu', 'Kohat', 'Vehari', 'Attock',
    'Chakwal', 'Jhelum', 'Gujrat', 'Mandi Bahauddin', 'Hafizabad', 'Chiniot', 'Khanewal', 'Rahim Yar Khan',
    'Turbat', 'Zhob', 'Chitral', 'Hunza', 'Skardu'
  ];

  i int;
  t_id uuid;
  v_played int;
  v_wins int;
  v_losses int;
  v_pts int;
  v_nrr numeric;
BEGIN

  -- 1. CLEAN UP EXISTING TEST DATA
  DELETE FROM matches WHERE tournament_id IN (v_t1_id, v_t2_id, v_t3_id, v_t4_id);
  DELETE FROM tournament_standings WHERE tournament_id IN (v_t1_id, v_t2_id, v_t3_id, v_t4_id);
  DELETE FROM tournament_teams WHERE tournament_id IN (v_t1_id, v_t2_id, v_t3_id, v_t4_id);
  DELETE FROM tournaments WHERE tournament_id IN (v_t1_id, v_t2_id, v_t3_id, v_t4_id);
  DELETE FROM teams WHERE team_id = ANY(v_team_ids);

  -- 2. INSERT 45 TEAMS
  FOR i IN 1..45 LOOP
    INSERT INTO teams (
      team_id,
      team_name,
      team_type,
      tagline,
      logo_monogram,
      home_ground,
      location,
      owner_id,
      managers,
      is_verified,
      privacy,
      status,
      max_squad_size,
      created_at,
      updated_at
    ) VALUES (
      v_team_ids[i],
      v_team_names[i],
      'club',
      'Pride of ' || v_cities[i],
      v_monograms[i],
      v_cities[i] || ' Cricket Stadium',
      jsonb_build_object('city', v_cities[i], 'country', 'Pakistan'),
      v_user_id,
      ARRAY[v_user_id],
      true,
      'public',
      'active',
      18,
      now(),
      now()
    );
  END LOOP;

  -- 3. INSERT 4 RICH TOURNAMENTS

  -- T1: Lahore Premier League 2026 (League · Live)
  INSERT INTO tournaments (
    tournament_id,
    tournament_name,
    tournament_type,
    description,
    format,
    rules,
    start_date,
    end_date,
    registration_deadline,
    location,
    venues,
    prize_details,
    entry_fee,
    min_teams,
    max_teams,
    created_by,
    organizers,
    status,
    privacy,
    created_at,
    updated_at
  ) VALUES (
    v_t1_id,
    'Lahore Premier League 2026',
    'league',
    'Official 20-Over Premier League with 42 participating clubs across Punjab. Top 8 advance to playoffs.',
    jsonb_build_object('max_overs', 20, 'ball_type', 'Leather (White)', 'max_overs_per_bowler', 4),
    jsonb_build_object('min_squad', 11, 'max_squad', 16),
    current_date - 5,
    current_date + 25,
    current_date - 8,
    jsonb_build_object('city', 'Lahore', 'country', 'Pakistan'),
    jsonb_build_array(
      jsonb_build_object('name', 'Gaddafi Stadium', 'city', 'Lahore'),
      jsonb_build_object('name', 'LCCA Ground', 'city', 'Lahore'),
      jsonb_build_object('name', 'Model Town Ground', 'city', 'Lahore')
    ),
    'Winner: PKR 1,000,000 + Trophy · Runner Up: PKR 500,000 · MVP: PKR 100,000',
    25000,
    16,
    48,
    v_user_id,
    ARRAY[v_user_id],
    'live',
    'public',
    now(),
    now()
  );

  -- T2: All Pakistan Super Knockout Cup (Knockout · Live)
  INSERT INTO tournaments (
    tournament_id,
    tournament_name,
    tournament_type,
    description,
    format,
    rules,
    start_date,
    end_date,
    registration_deadline,
    location,
    venues,
    prize_details,
    entry_fee,
    min_teams,
    max_teams,
    created_by,
    organizers,
    status,
    privacy,
    created_at,
    updated_at
  ) VALUES (
    v_t2_id,
    'All Pakistan Super Knockout Cup',
    'knockout',
    'High-intensity single-elimination tournament featuring 42 seeded champions. Every match is do or die.',
    jsonb_build_object('max_overs', 15, 'ball_type', 'Leather (Red)', 'max_overs_per_bowler', 3),
    jsonb_build_object('min_squad', 11, 'max_squad', 15),
    current_date - 2,
    current_date + 10,
    current_date - 4,
    jsonb_build_object('city', 'Rawalpindi', 'country', 'Pakistan'),
    jsonb_build_array(
      jsonb_build_object('name', 'Rawalpindi Cricket Stadium', 'city', 'Rawalpindi'),
      jsonb_build_object('name', 'KRL Stadium', 'city', 'Rawalpindi')
    ),
    'Winner: PKR 500,000 · Runner Up: PKR 200,000',
    15000,
    16,
    64,
    v_user_id,
    ARRAY[v_user_id],
    'live',
    'public',
    now(),
    now()
  );

  -- T3: Punjab Champions Trophy (Round Robin · Registration)
  INSERT INTO tournaments (
    tournament_id,
    tournament_name,
    tournament_type,
    description,
    format,
    rules,
    start_date,
    end_date,
    registration_deadline,
    location,
    venues,
    prize_details,
    entry_fee,
    min_teams,
    max_teams,
    created_by,
    organizers,
    status,
    privacy,
    created_at,
    updated_at
  ) VALUES (
    v_t3_id,
    'Punjab Champions Trophy',
    'round_robin',
    'Open registration round robin tournament with live seeding and team management.',
    jsonb_build_object('max_overs', 10, 'ball_type', 'Tape Ball', 'max_overs_per_bowler', 2),
    jsonb_build_object('min_squad', 11, 'max_squad', 16),
    current_date + 7,
    current_date + 21,
    current_date + 5,
    jsonb_build_object('city', 'Faisalabad', 'country', 'Pakistan'),
    jsonb_build_array(
      jsonb_build_object('name', 'Iqbal Stadium', 'city', 'Faisalabad')
    ),
    'Winner: PKR 300,000 · Runner Up: PKR 150,000',
    10000,
    8,
    48,
    v_user_id,
    ARRAY[v_user_id],
    'registration',
    'public',
    now(),
    now()
  );

  -- T4: National Tape Ball Championship (Knockout · Completed)
  INSERT INTO tournaments (
    tournament_id,
    tournament_name,
    tournament_type,
    description,
    format,
    rules,
    start_date,
    end_date,
    registration_deadline,
    location,
    venues,
    prize_details,
    entry_fee,
    min_teams,
    max_teams,
    created_by,
    organizers,
    status,
    privacy,
    created_at,
    updated_at,
    awards
  ) VALUES (
    v_t4_id,
    'National Tape Ball Championship',
    'knockout',
    'Concluded championship tournament with official awards and champion coronation.',
    jsonb_build_object('max_overs', 8, 'ball_type', 'Tape Ball', 'max_overs_per_bowler', 2),
    jsonb_build_object('min_squad', 8, 'max_squad', 12),
    current_date - 20,
    current_date - 12,
    current_date - 22,
    jsonb_build_object('city', 'Karachi', 'country', 'Pakistan'),
    jsonb_build_array(
      jsonb_build_object('name', 'National Stadium', 'city', 'Karachi')
    ),
    'Winner: PKR 750,000 · Runner Up: PKR 300,000',
    20000,
    16,
    48,
    v_user_id,
    ARRAY[v_user_id],
    'completed',
    'public',
    now(),
    now(),
    jsonb_build_object(
      'confirmed_at', (now() - interval '10 days'),
      'confirmed_by', v_user_id,
      'champion_team_id', v_team_ids[1],
      'runner_up_team_id', v_team_ids[2],
      'player_of_tournament', jsonb_build_object(
        'player_id', v_user_id,
        'player_name', 'Babar Azam',
        'team_id', v_team_ids[1],
        'team_name', 'Lahore Lions',
        'metric_value', '342 Runs · 12 Wickets'
      ),
      'best_batter', jsonb_build_object(
        'player_id', v_user_id,
        'player_name', 'Mohammad Rizwan',
        'team_id', v_team_ids[2],
        'team_name', 'Karachi Kingsmen',
        'metric_value', '310 Runs (Avg 77.5)'
      ),
      'best_bowler', jsonb_build_object(
        'player_id', v_user_id,
        'player_name', 'Shaheen Shah Afridi',
        'team_id', v_team_ids[1],
        'team_name', 'Lahore Lions',
        'metric_value', '18 Wickets (Econ 5.8)'
      ),
      'best_fielder', jsonb_build_object(
        'player_id', v_user_id,
        'player_name', 'Shadab Khan',
        'team_id', v_team_ids[3],
        'team_name', 'Islamabad United XI',
        'metric_value', '9 Catches · 4 Run Outs'
      )
    )
  );

  -- 4. REGISTER 42+ TEAMS INTO EACH TOURNAMENT
  FOR i IN 1..42 LOOP
    t_id := v_team_ids[i];

    -- T1 (League) Registrations (All Approved)
    INSERT INTO tournament_teams (
      registration_id,
      tournament_id,
      team_id,
      registered_by,
      registered_at,
      status,
      squad,
      seed_number,
      payment_status,
      decided_by,
      decided_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t1_id,
      t_id,
      v_user_id,
      now() - interval '10 days',
      'approved',
      ARRAY[v_user_id],
      i,
      'paid',
      v_user_id,
      now() - interval '9 days',
      now(),
      now()
    );

    -- T2 (Knockout) Registrations (All Approved & Seeded)
    INSERT INTO tournament_teams (
      registration_id,
      tournament_id,
      team_id,
      registered_by,
      registered_at,
      status,
      squad,
      seed_number,
      payment_status,
      decided_by,
      decided_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t2_id,
      t_id,
      v_user_id,
      now() - interval '6 days',
      'approved',
      ARRAY[v_user_id],
      i,
      'paid',
      v_user_id,
      now() - interval '5 days',
      now(),
      now()
    );

    -- T3 (Round Robin) Registrations (Mix of Approved & Pending for Inbox testing)
    INSERT INTO tournament_teams (
      registration_id,
      tournament_id,
      team_id,
      registered_by,
      registered_at,
      status,
      squad,
      seed_number,
      payment_status,
      message,
      decided_by,
      decided_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t3_id,
      t_id,
      v_user_id,
      now() - (i || ' hours')::interval,
      CASE 
        WHEN i <= 30 THEN 'approved'::tournament_registration_status
        ELSE 'pending'::tournament_registration_status
      END,
      ARRAY[v_user_id],
      i,
      CASE WHEN (i % 3) = 0 THEN 'pending' ELSE 'paid' END,
      'Looking forward to competing in the trophy!',
      CASE WHEN i <= 30 THEN v_user_id ELSE NULL END,
      CASE WHEN i <= 30 THEN (now() - (i || ' hours')::interval) ELSE NULL END,
      now(),
      now()
    );

    -- T4 (Completed Knockout) Registrations
    INSERT INTO tournament_teams (
      registration_id,
      tournament_id,
      team_id,
      registered_by,
      registered_at,
      status,
      squad,
      seed_number,
      payment_status,
      decided_by,
      decided_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t4_id,
      t_id,
      v_user_id,
      now() - interval '25 days',
      'approved',
      ARRAY[v_user_id],
      i,
      'paid',
      v_user_id,
      now() - interval '24 days',
      now(),
      now()
    );

    -- 5. POPULATE STANDINGS FOR T1 (League)
    -- Realistic points table with wins, losses, runs, overs, and net run rates
    v_played := 5 + (i % 3);
    v_wins := (v_played * (43 - i) / 44)::int;
    v_losses := v_played - v_wins;
    v_pts := v_wins * 2;
    v_nrr := round(((43 - i)::numeric - 21.5) / 10.0, 3);

    INSERT INTO tournament_standings (
      tournament_id,
      team_id,
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
    ) VALUES (
      v_t1_id,
      t_id,
      v_played,
      v_wins,
      v_losses,
      0,
      0,
      v_pts,
      v_played * 165 + (43 - i) * 8,
      v_played * 20.0,
      v_played * 165 - (43 - i) * 8 + 50,
      v_played * 20.0,
      v_nrr,
      now()
    );

  END LOOP;

  -- 6. POPULATE MATCH FIXTURES FOR T1 (League) & T2 (Knockout)
  -- T1 Matches (Live League Fixtures)
  FOR i IN 1..10 LOOP
    INSERT INTO matches (
      match_id,
      tournament_id,
      match_type,
      match_format,
      round,
      bracket_round_number,
      bracket_match_number,
      venue,
      scheduled_start_time,
      actual_start_time,
      status,
      start_phase,
      scoring_mode,
      rules_config,
      format,
      team_a_id,
      team_b_id,
      team_a_captain,
      team_b_captain,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t1_id,
      'tournament',
      't20',
      'Round ' || ((i % 4) + 1),
      1,
      i,
      'Gaddafi Stadium, Lahore',
      now() + ((i * 4) || ' hours')::interval,
      CASE WHEN i <= 2 THEN now() - interval '1 hour' ELSE NULL END,
      CASE 
        WHEN i <= 2 THEN 'live'::match_status
        WHEN i <= 5 THEN 'completed'::match_status
        ELSE 'scheduled'::match_status
      END,
      CASE WHEN i <= 2 THEN 'live'::match_start_phase ELSE 'toss'::match_start_phase END,
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 20, 'players_per_team', 11),
      jsonb_build_object('max_overs', 20, 'ball_type', 'leather', 'max_overs_per_bowler', 4),
      v_team_ids[i * 2 - 1],
      v_team_ids[i * 2],
      v_user_id,
      v_user_id,
      v_user_id,
      now(),
      now()
    );
  END LOOP;

  -- T2 Matches (Knockout Bracket Tree: Round of 16, Quarterfinals, Semifinals, Final)
  -- Round of 16 (8 matches)
  FOR i IN 1..8 LOOP
    INSERT INTO matches (
      match_id,
      tournament_id,
      match_type,
      match_format,
      round,
      bracket_round_number,
      bracket_match_number,
      venue,
      scheduled_start_time,
      actual_start_time,
      status,
      start_phase,
      scoring_mode,
      rules_config,
      format,
      team_a_id,
      team_b_id,
      team_a_captain,
      team_b_captain,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t2_id,
      'tournament',
      't20',
      'Round of 16',
      1,
      i,
      'Rawalpindi Cricket Stadium',
      now() - interval '1 day' + (i * 2 || ' hours')::interval,
      now() - interval '1 day',
      'completed',
      'live',
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 15, 'players_per_team', 11),
      jsonb_build_object('max_overs', 15, 'ball_type', 'leather', 'max_overs_per_bowler', 3),
      v_team_ids[i * 2 - 1],
      v_team_ids[i * 2],
      v_user_id,
      v_user_id,
      v_user_id,
      now(),
      now()
    );
  END LOOP;

  -- Quarterfinals (4 matches)
  FOR i IN 1..4 LOOP
    INSERT INTO matches (
      match_id,
      tournament_id,
      match_type,
      match_format,
      round,
      bracket_round_number,
      bracket_match_number,
      venue,
      scheduled_start_time,
      actual_start_time,
      status,
      start_phase,
      scoring_mode,
      rules_config,
      format,
      team_a_id,
      team_b_id,
      team_a_captain,
      team_b_captain,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t2_id,
      'tournament',
      't20',
      'Quarter Final ' || i,
      2,
      i,
      'Rawalpindi Cricket Stadium',
      now() + (i * 3 || ' hours')::interval,
      CASE WHEN i = 1 THEN now() - interval '30 minutes' ELSE NULL END,
      CASE WHEN i = 1 THEN 'live'::match_status ELSE 'scheduled'::match_status END,
      CASE WHEN i = 1 THEN 'live'::match_start_phase ELSE 'toss'::match_start_phase END,
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 15, 'players_per_team', 11),
      jsonb_build_object('max_overs', 15, 'ball_type', 'leather', 'max_overs_per_bowler', 3),
      v_team_ids[i * 4 - 3],
      v_team_ids[i * 4 - 1],
      v_user_id,
      v_user_id,
      v_user_id,
      now(),
      now()
    );
  END LOOP;

  -- Semifinals (2 matches)
  FOR i IN 1..2 LOOP
    INSERT INTO matches (
      match_id,
      tournament_id,
      match_type,
      match_format,
      round,
      bracket_round_number,
      bracket_match_number,
      venue,
      scheduled_start_time,
      status,
      start_phase,
      scoring_mode,
      rules_config,
      format,
      team_a_id,
      team_b_id,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t2_id,
      'tournament',
      't20',
      'Semi Final ' || i,
      3,
      i,
      'Rawalpindi Cricket Stadium',
      now() + interval '2 days' + (i * 4 || ' hours')::interval,
      'scheduled',
      'toss',
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 15, 'players_per_team', 11),
      jsonb_build_object('max_overs', 15, 'ball_type', 'leather', 'max_overs_per_bowler', 3),
      v_team_ids[i * 8 - 7],
      v_team_ids[i * 8 - 3],
      v_user_id,
      now(),
      now()
    );
  END LOOP;

  -- Grand Final (1 match)
  INSERT INTO matches (
    match_id,
    tournament_id,
    match_type,
    match_format,
    round,
    bracket_round_number,
    bracket_match_number,
    venue,
    scheduled_start_time,
    status,
    start_phase,
    scoring_mode,
    rules_config,
    format,
    team_a_id,
    team_b_id,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_t2_id,
    'tournament',
    't20',
    'Grand Final',
    4,
    1,
    'Rawalpindi Cricket Stadium',
    now() + interval '4 days',
    'scheduled',
    'toss',
    'live_ball_by_ball',
    jsonb_build_object('max_overs', 15, 'players_per_team', 11),
    jsonb_build_object('max_overs', 15, 'ball_type', 'leather', 'max_overs_per_bowler', 3),
    v_team_ids[1],
    v_team_ids[9],
    v_user_id,
    now(),
    now()
  );

END $$;
