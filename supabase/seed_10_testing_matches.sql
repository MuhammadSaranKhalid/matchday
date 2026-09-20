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
-- 20260822150000 · seed_10_testing_matches.sql
-- =============================================================================
-- Creates 10 new matches between existing teams for testing Toss and
-- Player Selection / Openers setup flows.
-- =============================================================================

do $seed_10_matches$
declare
  v_saran_uid   uuid;
  v_muazam_uid  uuid;

  -- 10 Fixed Match UUIDs
  m_ids uuid[] := array[
    'aaaaaaaa-1111-4000-8000-000000000001'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000002'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000003'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000004'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000005'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000006'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000007'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000008'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000009'::uuid,
    'aaaaaaaa-1111-4000-8000-000000000010'::uuid
  ];

  -- Formats matching public.match_format enum
  v_formats public.match_format[] := array[
    't20'::public.match_format,
    't20'::public.match_format,
    'the_hundred'::public.match_format,
    'custom_limited'::public.match_format,
    't20'::public.match_format,
    't20'::public.match_format,
    'the_hundred'::public.match_format,
    't20'::public.match_format,
    'custom_limited'::public.match_format,
    't20'::public.match_format
  ];

  v_venues text[] := array[
    'Gaddafi Stadium, Lahore',
    'National Stadium, Karachi',
    'Rawalpindi Cricket Ground',
    'Multan Cricket Stadium',
    'Bugti Stadium, Quetta',
    'F-9 Diamond Cricket Ground, Islamabad',
    'Model Town Sports Complex, Lahore',
    'Niaz Stadium, Hyderabad',
    'Iqbal Stadium, Faisalabad',
    'Arbab Niaz Stadium, Peshawar'
  ];

  -- Variables for iteration
  v_all_teams uuid[];
  v_team_count int;
  v_idx int;
  v_match_id uuid;
  v_team_a_id uuid;
  v_team_b_id uuid;
  v_team_a_name text;
  v_team_b_name text;
  v_team_a_cap uuid;
  v_team_b_cap uuid;
  v_cnt int;
  v_new_unclaimed uuid;

begin
  -- Requires at least one real profile to attribute the fixtures to.
  if not exists (select 1 from public.profiles) then
    raise notice 'seed_10_testing_matches: no profiles — skipping.';
    return;
  end if;

  -- Resolve User IDs
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;
  if v_saran_uid is null then
    v_saran_uid := '892b4f62-38bb-4108-89a6-2689b2e08e97'::uuid;
  end if;

  select id into v_muazam_uid from auth.users where email = 'msarankhalid1@gmail.com' limit 1;
  if v_muazam_uid is null then
    v_muazam_uid := '321a18b5-409a-422c-b32c-252c0c299c9d'::uuid;
  end if;

  -- Collect available team IDs
  select array_agg(team_id) into v_all_teams from public.teams;
  v_team_count := coalesce(array_length(v_all_teams, 1), 0);

  if v_team_count < 2 then
    raise notice 'Not enough teams found to seed matches. Need at least 2 teams.';
    return;
  end if;

  -- Create 10 Matches
  for v_idx in 1..10 loop
    v_match_id := m_ids[v_idx];

    -- Pick team pair cycling through available teams
    v_team_a_id := v_all_teams[((v_idx - 1) % v_team_count) + 1];
    v_team_b_id := v_all_teams[(v_idx % v_team_count) + 1];

    if v_team_a_id = v_team_b_id then
      v_team_b_id := v_all_teams[((v_idx + 1) % v_team_count) + 1];
    end if;

    select team_name into v_team_a_name from public.teams where team_id = v_team_a_id;
    select team_name into v_team_b_name from public.teams where team_id = v_team_b_id;

    v_team_a_cap := public._team_current_captain(v_team_a_id);
    v_team_b_cap := public._team_current_captain(v_team_b_id);

    if v_team_a_cap is null then v_team_a_cap := v_saran_uid; end if;
    if v_team_b_cap is null then v_team_b_cap := v_muazam_uid; end if;

    -- Clean up if previously created
    delete from public.match_players where match_id = v_match_id;
    delete from public.match_teams where match_id = v_match_id;
    delete from public.matches where match_id = v_match_id;

    -- Insert Match
    insert into public.matches (
      match_id,
      match_type,
      match_format,
      venue,
      scheduled_start_time,
      status,
      start_phase,
      team_a_id,
      team_b_id,
      team_a_captain,
      team_b_captain,
      created_by
    ) values (
      v_match_id,
      'friendly',
      v_formats[v_idx],
      v_venues[v_idx],
      now() + (v_idx * interval '2 hours'),
      'scheduled',
      'toss',
      v_team_a_id,
      v_team_b_id,
      v_team_a_cap,
      v_team_b_cap,
      v_saran_uid
    );

    -- Insert Match Teams
    insert into public.match_teams (match_id, team_id, team_name, team_side)
    values
      (v_match_id, v_team_a_id, v_team_a_name, 'team_a'),
      (v_match_id, v_team_b_id, v_team_b_name, 'team_b');

    -- Insert Team A Players from Team Members
    insert into public.match_players (
      match_id, team_side, user_id, unclaimed_id, display_name,
      role, is_in_playing_xi, jersey_number
    )
    select v_match_id, 'team_a',
           tm.user_id, tm.unclaimed_id,
           coalesce(pr.display_name, up.display_name, 'Player'),
           case
             when tm.user_id = v_team_a_cap then 'captain'::public.match_role
             else 'player'::public.match_role
           end,
           true,
           tm.jersey_number
      from public.team_members tm
      left join public.profiles pr          on pr.user_id      = tm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
     where tm.team_id = v_team_a_id
       and tm.status  = 'active';

    -- Check how many players were added for Team A
    select count(*) into v_cnt from public.match_players where match_id = v_match_id and team_side = 'team_a';
    if v_cnt < 5 then
      for g in (v_cnt + 1)..7 loop
        insert into public.unclaimed_players (sport_id, display_name, added_by)
        values ('cricket', v_team_a_name || ' Player ' || g, v_saran_uid)
        returning unclaimed_id into v_new_unclaimed;

        insert into public.match_players (
          match_player_id, match_id, team_side, unclaimed_id, display_name, role, is_in_playing_xi, jersey_number
        ) values (
          gen_random_uuid(), v_match_id, 'team_a', v_new_unclaimed, v_team_a_name || ' Player ' || g, 'player'::public.match_role, true, g
        );
      end loop;
    end if;

    -- Insert Team B Players from Team Members
    insert into public.match_players (
      match_id, team_side, user_id, unclaimed_id, display_name,
      role, is_in_playing_xi, jersey_number
    )
    select v_match_id, 'team_b',
           tm.user_id, tm.unclaimed_id,
           coalesce(pr.display_name, up.display_name, 'Player'),
           case
             when tm.user_id = v_team_b_cap then 'captain'::public.match_role
             else 'player'::public.match_role
           end,
           true,
           tm.jersey_number
      from public.team_members tm
      left join public.profiles pr          on pr.user_id      = tm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
     where tm.team_id = v_team_b_id
       and tm.status  = 'active';

    -- Check how many players were added for Team B
    select count(*) into v_cnt from public.match_players where match_id = v_match_id and team_side = 'team_b';
    if v_cnt < 5 then
      for g in (v_cnt + 1)..7 loop
        insert into public.unclaimed_players (sport_id, display_name, added_by)
        values ('cricket', v_team_b_name || ' Player ' || g, v_muazam_uid)
        returning unclaimed_id into v_new_unclaimed;

        insert into public.match_players (
          match_player_id, match_id, team_side, unclaimed_id, display_name, role, is_in_playing_xi, jersey_number
        ) values (
          gen_random_uuid(), v_match_id, 'team_b', v_new_unclaimed, v_team_b_name || ' Player ' || g, 'player'::public.match_role, true, g
        );
      end loop;
    end if;

  end loop;

  raise notice 'Successfully created 10 testing matches!';
end $seed_10_matches$;
