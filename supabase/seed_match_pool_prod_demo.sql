-- =============================================================================
-- seed_match_pool_prod_demo.sql — the open match pool, on the hosted project
-- =============================================================================
-- The local seed (seed_match_pool_demo.sql) pins the team ids that
-- seed_teams_and_posts.sql creates. Those ids do not exist on the hosted
-- project, and the shape there is different in one way that matters:
--
--   the signed-in account owns 46 of the 47 teams.
--
-- The board hides your own teams by design, so on that data it can never show
-- more than one card. This seed therefore CREATES five opponent teams, owned
-- by demo profiles that already exist there, and hangs the board off those.
--
-- What it writes — all new rows, nothing existing is modified:
--
--   5 teams        owned by bilal / faraz / hassan / adeel / karim
--   55 players     placeholder (unclaimed) squads, 11 per team
--   5 challenges   open, from those teams          → the board (artboard 01)
--   5 challenges   yours: 2 live + 3 settled       → My challenges (12)
--   1 match        so the settled "Matched" row has something to point at
--   5 applications 4 pending + 1 declined          → artboards 15 / 16 / 17 / 18
--
-- Idempotent: every row has a fixed id and is deleted before being rebuilt.
--
--   supabase db query --linked --file supabase/seed_match_pool_prod_demo.sql
--
-- To remove it completely, see the rollback block at the foot of this file.
-- =============================================================================

do $seed_pool_prod$
declare
  v_saran   uuid;

  -- Opponent teams this seed owns outright. 'bbbb…' marks them as demo rows.
  o_eagles   constant uuid := 'bbbb0000-0000-4000-8000-000000000001';
  o_sultans  constant uuid := 'bbbb0000-0000-4000-8000-000000000002';
  o_knights  constant uuid := 'bbbb0000-0000-4000-8000-000000000003';
  o_quetta   constant uuid := 'bbbb0000-0000-4000-8000-000000000004';
  o_ravi     constant uuid := 'bbbb0000-0000-4000-8000-000000000005';

  r_pool_eagles   constant uuid := 'cccc0001-0000-4000-8000-000000000001';
  r_pool_sultans  constant uuid := 'cccc0001-0000-4000-8000-000000000002';
  r_pool_knights  constant uuid := 'cccc0001-0000-4000-8000-000000000003';
  r_pool_quetta   constant uuid := 'cccc0001-0000-4000-8000-000000000004';
  r_pool_ravi     constant uuid := 'cccc0001-0000-4000-8000-000000000005';

  r_mine_busy      constant uuid := 'cccc0002-0000-4000-8000-000000000001';
  r_mine_waiting   constant uuid := 'cccc0002-0000-4000-8000-000000000002';
  r_mine_matched   constant uuid := 'cccc0002-0000-4000-8000-000000000003';
  r_mine_expired   constant uuid := 'cccc0002-0000-4000-8000-000000000004';
  r_mine_withdrawn constant uuid := 'cccc0002-0000-4000-8000-000000000005';

  m_past           constant uuid := 'cccc0003-0000-4000-8000-000000000001';

  -- Your own teams host the "My challenges" rows. Resolved from whatever the
  -- account actually owns, oldest first, so the seed does not depend on names.
  h_busy    uuid;
  h_waiting uuid;
  h_past    uuid;

  v_today    timestamptz := date_trunc('hour', now()) + interval '3 hours';
  v_tomorrow timestamptz := date_trunc('day', now()) + interval '1 day 9 hours';

  v_team   uuid;
  v_owner  uuid;
  v_i      int;
  v_names  constant text[] := array[
    'Farhan Malik', 'Zeeshan Khalid', 'Tariq Aziz', 'Noman Shah',
    'Imran Bashir', 'Waqar Younis', 'Sohail Akhtar', 'Danish Raza',
    'Kamran Yousuf', 'Rehan Siddiqui', 'Asad Mehmood'
  ];
begin
  select user_id into v_saran from public.profiles where username = 'saran' limit 1;
  if v_saran is null then
    raise notice 'seed_match_pool_prod_demo: no profile "saran" — nothing seeded.';
    return;
  end if;

  select team_id into h_busy    from public.teams where created_by = v_saran
    order by created_at, team_id offset 0 limit 1;
  select team_id into h_waiting from public.teams where created_by = v_saran
    order by created_at, team_id offset 1 limit 1;
  select team_id into h_past    from public.teams where created_by = v_saran
    order by created_at, team_id offset 2 limit 1;

  if h_busy is null or h_waiting is null then
    raise notice 'seed_match_pool_prod_demo: you need at least two teams of your own — nothing seeded.';
    return;
  end if;
  h_past := coalesce(h_past, h_busy);

  -- ---------------------------------------------------------------------------
  -- 1) Clear the previous run, innermost first.
  -- ---------------------------------------------------------------------------
  delete from public.match_challenges
   where request_id in (
     r_pool_eagles, r_pool_sultans, r_pool_knights, r_pool_quetta, r_pool_ravi,
     r_mine_busy, r_mine_waiting, r_mine_matched, r_mine_expired, r_mine_withdrawn
   );
  delete from public.matches where match_id = m_past;
  delete from public.team_members
   where team_id in (o_eagles, o_sultans, o_knights, o_quetta, o_ravi);
  delete from public.teams
   where team_id in (o_eagles, o_sultans, o_knights, o_quetta, o_ravi);

  -- ---------------------------------------------------------------------------
  -- 2) The opponent teams.
  -- ---------------------------------------------------------------------------
  -- Owned by demo profiles rather than by you, which is the whole point: the
  -- board only shows challenges from teams you are not attached to.
  insert into public.teams (
    team_id, created_by, team_name, team_type, privacy, tagline,
    team_colors, logo_monogram, location, home_ground, founded_year
  )
  select v.team_id, p.user_id, v.team_name, 'club', 'public', v.tagline,
         v.colors, v.monogram,
         jsonb_build_object('city', v.city, 'country', 'Pakistan'),
         v.ground, v.founded
  from (values
    (o_eagles,  'bilal',  'Karachi Eagles',    'Sea breeze and swing',
     '{"primary":"#2E5D57","secondary":"#F4ECDD"}'::jsonb, 'KE', 'Karachi', 'Gaddafi B Ground',     2017),
    (o_sultans, 'faraz',  'Multan Sultans',    'Southern punch',
     '{"primary":"#B7892E","secondary":"#29251E"}'::jsonb, 'MS', 'Multan',  'Model Town Greens',    2019),
    (o_knights, 'hassan', 'Karachi Knights',   'Night games, tape ball',
     '{"primary":"#3C4A57","secondary":"#FBFAF6"}'::jsonb, 'KK', 'Karachi', 'Korangi Sports Club',  2021),
    (o_quetta,  'adeel',  'Quetta Gladiators', 'Highland pace',
     '{"primary":"#7A2E2E","secondary":"#F4ECDD"}'::jsonb, 'QG', 'Quetta',  'LCCA Ground',          2016),
    (o_ravi,    'karim',  'Ravi Riders',       'River-side cricket since forever',
     '{"primary":"#4A4339","secondary":"#DED0AC"}'::jsonb, 'RR', 'Lahore',  'Ravi Sports Ground',   2015)
  ) as v(team_id, owner_username, team_name, tagline, colors, monogram, city, ground, founded)
  join public.profiles p on p.username = v.owner_username;

  -- ---------------------------------------------------------------------------
  -- 3) Give each an 11-man squad.
  -- ---------------------------------------------------------------------------
  -- Artboard 16 lists the applicant's XI by name, so an applying team needs a
  -- roster to name one from. These are unclaimed players — the same
  -- placeholder rows a captain creates by hand — with ids derived from the
  -- team and shirt number, so a re-run replaces rather than duplicates.
  foreach v_team in array array[o_eagles, o_sultans, o_knights, o_quetta, o_ravi]
  loop
    select created_by into v_owner from public.teams where team_id = v_team;
    continue when v_owner is null;

    for v_i in 1 .. array_length(v_names, 1) loop
      insert into public.unclaimed_players (unclaimed_id, sport_id, display_name, added_by)
      values (
        md5('pool-prod:' || v_team::text || ':' || v_i)::uuid,
        'cricket',
        v_names[v_i],
        v_owner
      )
      on conflict (unclaimed_id) do update set display_name = excluded.display_name;

      -- No role column: these are UNCLAIMED placeholders, and 'player' (what
      -- assign_initial_role attaches by default) is the only role flagged
      -- allows_unclaimed. The keeper is a per-match fact (match_players.role),
      -- never a team-level one.
      insert into public.team_members (team_id, unclaimed_id, jersey_number, added_by)
      values (
        v_team,
        md5('pool-prod:' || v_team::text || ':' || v_i)::uuid,
        20 + v_i,
        v_owner
      );
    end loop;
  end loop;

  -- ---------------------------------------------------------------------------
  -- 4) The board — five open challenges, spread so every facet bites.
  -- ---------------------------------------------------------------------------
  --   All 5 · Tape-ball 3 · Leather 2 · Today 2
  -- Karachi Knights carries no time, ground or expiry, which is artboard 01's
  -- short third card. Expiries are relative to now(), so 41h reads amber and
  -- 50h reads grey whenever this runs.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format, message,
    status, share_code, code_expires_at, proposal_expires_at, created_at
  )
  select v.request_id, v.from_team_id, null, t.created_by,
         v.start_time, v.venue, v.format, v.message,
         'pending', v.code,
         case when v.code is null then null else now() + interval '24 hours' end,
         v.expires_at, v.created_at
  from (values
    (r_pool_eagles, o_eagles, v_today, 'Gaddafi B Ground',
     jsonb_build_object('overs_per_innings', 12, 'players_per_team', 11,
                        'ball_type', 'tape', 'max_overs_per_bowler', 3,
                        'balls_per_over', 6, 'innings_per_side', 1),
     'Short format, quick game. We can bring stumps and a spare bat.',
     '4K7P2M'::text, now() + interval '41 hours', now() - interval '7 hours'),

    (r_pool_sultans, o_sultans, v_tomorrow, 'Model Town Greens',
     jsonb_build_object('overs_per_innings', 16, 'players_per_team', 11,
                        'ball_type', 'leather', 'max_overs_per_bowler', 4,
                        'balls_per_over', 6, 'innings_per_side', 1),
     'Leather ball, proper game. Umpire arranged.',
     'M8X3QL'::text, now() + interval '50 hours', now() - interval '11 hours'),

    (r_pool_knights, o_knights, null::timestamptz, null::text,
     jsonb_build_object('overs_per_innings', 10, 'players_per_team', 8,
                        'ball_type', 'tape', 'max_overs_per_bowler', 2,
                        'balls_per_over', 6, 'innings_per_side', 1),
     null::text,
     'T5R9WD'::text, null::timestamptz, now() - interval '2 hours'),

    (r_pool_quetta, o_quetta, v_today + interval '3 hours', 'LCCA Ground',
     jsonb_build_object('overs_per_innings', 20, 'players_per_team', 11,
                        'ball_type', 'leather', 'max_overs_per_bowler', 4,
                        'balls_per_over', 6, 'innings_per_side', 1),
     'Evening game under lights. Ground fee split.',
     'Q2L6VN'::text, now() + interval '20 hours', now() - interval '3 hours'),

    (r_pool_ravi, o_ravi, date_trunc('day', now()) + interval '3 days 15 hours',
     'Ravi Sports Ground',
     jsonb_build_object('overs_per_innings', 15, 'players_per_team', 11,
                        'ball_type', 'tape', 'max_overs_per_bowler', 3,
                        'balls_per_over', 6, 'innings_per_side', 1),
     'Weekend fixture, travelling side welcome.',
     'S7B4HK'::text, now() + interval '47 hours', now() - interval '20 hours')
  ) as v(request_id, from_team_id, start_time, venue, format, message,
         code, expires_at, created_at)
  join public.teams t on t.team_id = v.from_team_id;

  -- ---------------------------------------------------------------------------
  -- 5) My challenges — yours, live.
  -- ---------------------------------------------------------------------------
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format, message,
    status, share_code, code_expires_at, proposal_expires_at, created_at
  )
  values
    -- Artboard 15 — the one with applicants.
    (r_mine_busy, h_busy, null, v_saran,
     v_today, 'Gaddafi B Ground',
     jsonb_build_object('overs_per_innings', 12, 'players_per_team', 11,
                        'ball_type', 'tape', 'max_overs_per_bowler', 3,
                        'balls_per_over', 6, 'innings_per_side', 1),
     'Looking for a 12-over game this evening.',
     'pending', '7K2M9Q', now() + interval '24 hours',
     now() + interval '41 hours', now() - interval '9 hours'),

    -- Artboard 14 — waiting, so the code panel is the whole point.
    (r_mine_waiting, h_waiting, null, v_saran,
     date_trunc('day', now()) + interval '5 days 15 hours', 'Model Town Ground',
     jsonb_build_object('overs_per_innings', 20, 'players_per_team', 11,
                        'ball_type', 'leather', 'max_overs_per_bowler', 4,
                        'balls_per_over', 6, 'innings_per_side', 1),
     null,
     'pending', 'P3F8XZ', now() + interval '24 hours',
     now() + interval '44 hours', now() - interval '1 hour');

  -- ---------------------------------------------------------------------------
  -- 6) The settled ledger — "Past · closed".
  -- ---------------------------------------------------------------------------
  -- An accepted request must point at a real match (the decision-consistency
  -- constraint), so the Matched row gets one.
  insert into public.matches (
    match_id, match_type, status, team_a_id, team_b_id,
    venue, scheduled_start_time, created_by, format
  )
  values (
    m_past, 'friendly', 'completed', h_past, o_ravi,
    'Gaddafi B Ground', now() - interval '15 days', v_saran,
    jsonb_build_object('overs_per_innings', 12, 'players_per_team', 11,
                       'ball_type', 'tape', 'max_overs_per_bowler', 3,
                       'balls_per_over', 6, 'innings_per_side', 1)
  );

  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format,
    status, decided_by, decided_at, match_id, created_at
  )
  values (
    r_mine_matched, h_past, o_ravi, v_saran,
    now() - interval '15 days', 'Gaddafi B Ground',
    jsonb_build_object('overs_per_innings', 12, 'players_per_team', 11,
                       'ball_type', 'tape', 'max_overs_per_bowler', 3,
                       'balls_per_over', 6, 'innings_per_side', 1),
    'accepted', v_saran, now() - interval '15 days', m_past,
    now() - interval '17 days'
  );

  -- Expired carries a decided_at but no decider — nobody closed it, the clock did.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format,
    status, decided_at, created_at
  )
  values (
    r_mine_expired, h_waiting, null, v_saran,
    now() - interval '22 days', 'Hyderabad Gymkhana',
    jsonb_build_object('overs_per_innings', 16, 'players_per_team', 11,
                       'ball_type', 'tape', 'max_overs_per_bowler', 4,
                       'balls_per_over', 6, 'innings_per_side', 1),
    'expired', now() - interval '20 days', now() - interval '24 days'
  );

  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format,
    status, decided_by, decided_at, decision_note, created_at
  )
  values (
    r_mine_withdrawn, h_busy, null, v_saran,
    now() - interval '30 days', 'Model Town Ground',
    jsonb_build_object('overs_per_innings', 20, 'players_per_team', 11,
                       'ball_type', 'leather', 'max_overs_per_bowler', 4,
                       'balls_per_over', 6, 'innings_per_side', 1),
    'cancelled', v_saran, now() - interval '28 days',
    'Ground double-booked.', now() - interval '31 days'
  );

  -- ---------------------------------------------------------------------------
  -- 7) Applicants for the busy challenge.
  -- ---------------------------------------------------------------------------
  -- 4 pending + 1 already declined, so artboard 15 shows both card shapes and
  -- artboard 17 has three other teams to name in its auto-decline warning.
  -- Each XI is that team's own eleven in roster order, captain and keeper
  -- first, which is what artboard 16 renders with its C / WK marks.
  insert into public.match_pool_applications (
    application_id, request_id, applicant_team_id, applicant_user_id,
    applicant_xi, applicant_keeper_id, message, status,
    decision_note, decided_at, created_at, updated_at
  )
  select
    md5('pool-prod-app:' || a.team_id::text)::uuid,
    r_mine_busy, a.team_id, t.created_by,
    xi.ids, xi.keeper, a.message, a.status, a.note,
    case when a.status = 'pending' then null else now() - interval '4 hours' end,
    now() - a.age, now() - a.age
  from (values
    (o_eagles,  interval '2 hours',
     'Keen for a 12-over game, we can bring an umpire and cover half the ground fee. Been wanting to play you all season.',
     'pending'::text, null::text),
    (o_sultans, interval '5 hours', null::text, 'pending'::text, null::text),
    (o_quetta,  interval '6 hours',
     'We can travel. Happy to start earlier if that suits.', 'pending'::text, null::text),
    (o_ravi,    interval '8 hours',
     'Full squad available, we play tape-ball every week.', 'pending'::text, null::text),
    (o_knights, interval '26 hours',
     'Can we make it 16 overs?', 'rejected'::text, 'Slot filled — going with a 12-over side.')
  ) as a(team_id, age, message, status, note)
  join public.teams t on t.team_id = a.team_id
  cross join lateral (
    select
      array_agg(m.player_id order by m.rn) as ids,
      -- 2026-09-10: team_members no longer carries 'wicket_keeper' — keeping is
      -- a per-match job (match_players.role), not a standing team role. The
      -- demo just nominates the second name in the XI.
      (array_agg(m.player_id order by m.rn))[2] as keeper
    from (
      select coalesce(tm.user_id, tm.unclaimed_id) as player_id,
             tm.role,
             row_number() over (
               order by (tm.role <> 'captain'), tm.created_at
             ) as rn
      from public.team_members tm
      where tm.team_id = a.team_id and tm.status = 'active' and tm.in_squad
      limit 11
    ) m
  ) xi
  where xi.ids is not null;

  raise notice 'seed_match_pool_prod_demo: 5 opponent teams, 5 on the board, 2 live + 3 settled of yours, 5 applicants.';
end
$seed_pool_prod$;

-- =============================================================================
-- Rollback — removes every row this seed created, and nothing else.
-- =============================================================================
-- delete from public.match_challenges where request_id::text like 'cccc000%';
-- delete from public.matches         where match_id::text  like 'cccc0003%';
-- delete from public.team_members    where team_id::text   like 'bbbb0000%';
-- delete from public.teams           where team_id::text   like 'bbbb0000%';
-- delete from public.unclaimed_players u
--  where not exists (select 1 from public.team_members m where m.unclaimed_id = u.unclaimed_id)
--    and u.display_name in ('Farhan Malik','Zeeshan Khalid','Tariq Aziz','Noman Shah',
--                           'Imran Bashir','Waqar Younis','Sohail Akhtar','Danish Raza',
--                           'Kamran Yousuf','Rehan Siddiqui','Asad Mehmood');
