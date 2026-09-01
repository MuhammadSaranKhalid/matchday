-- ============================================================================
-- FIXTURES & STANDINGS ENRICHMENT PATCH
-- ============================================================================

DO $$
DECLARE
  v_user_id uuid := '892b4f62-38bb-4108-89a6-2689b2e08e97';
  v_t3_id uuid := '33333333-3333-3333-3333-333333333333'; -- Round Robin
  v_t4_id uuid := '44444444-4444-4444-4444-444444444444'; -- Completed Knockout
  
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
    'a0000000-0000-0000-0000-000000000016'::uuid
  ];

  i int;
BEGIN

  -- 1. Populating completed matches for T4 (National Tape Ball Championship)
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
      completed_at,
      status,
      start_phase,
      scoring_mode,
      rules_config,
      format,
      team_a_id,
      team_b_id,
      result_summary,
      created_by,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_t4_id,
      'tournament',
      't20',
      'Quarter Final ' || i,
      1,
      i,
      'National Stadium, Karachi',
      now() - interval '18 days' + (i * 2 || ' hours')::interval,
      now() - interval '18 days',
      now() - interval '18 days' + interval '2 hours',
      'completed',
      'live',
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 8, 'players_per_team', 10),
      jsonb_build_object('max_overs', 8, 'ball_type', 'tape_ball', 'max_overs_per_bowler', 2),
      v_team_ids[i],
      v_team_ids[i + 8],
      jsonb_build_object('winner_team_id', v_team_ids[i], 'win_margin', '18 runs', 'summary', 'Won by 18 runs'),
      v_user_id,
      now() - interval '20 days',
      now() - interval '18 days'
    );
  END LOOP;

  -- Grand Final for T4
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
    completed_at,
    status,
    start_phase,
    scoring_mode,
    rules_config,
    format,
    team_a_id,
    team_b_id,
    result_summary,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_t4_id,
    'tournament',
    't20',
    'Grand Final',
    3,
    1,
    'National Stadium, Karachi',
    now() - interval '12 days',
    now() - interval '12 days',
    now() - interval '12 days' + interval '2 hours',
    'completed',
    'live',
    'live_ball_by_ball',
    jsonb_build_object('max_overs', 8, 'players_per_team', 10),
    jsonb_build_object('max_overs', 8, 'ball_type', 'tape_ball', 'max_overs_per_bowler', 2),
    v_team_ids[1],
    v_team_ids[2],
    jsonb_build_object('winner_team_id', v_team_ids[1], 'win_margin', '5 wickets', 'summary', 'Lahore Lions won by 5 wickets'),
    v_user_id,
    now() - interval '20 days',
    now() - interval '12 days'
  );

  -- 2. Populating scheduled fixtures for T3 (Punjab Champions Trophy)
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
      v_t3_id,
      'tournament',
      't20',
      'League Fixture ' || i,
      1,
      i,
      'Iqbal Stadium, Faisalabad',
      now() + interval '8 days' + (i * 3 || ' hours')::interval,
      'scheduled',
      'toss',
      'live_ball_by_ball',
      jsonb_build_object('max_overs', 10, 'players_per_team', 11),
      jsonb_build_object('max_overs', 10, 'ball_type', 'tape_ball', 'max_overs_per_bowler', 2),
      v_team_ids[i],
      v_team_ids[17 - i],
      v_user_id,
      now(),
      now()
    );
  END LOOP;

END $$;
