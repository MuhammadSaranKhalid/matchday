-- =============================================================================
-- seed_challenges_testing.sql — test data for the Challenges screen
-- =============================================================================
-- Seeds one team for the signed-in tester plus six opponents, and a spread of
-- match challenges that exercises EVERY state Challenges.dc.html renders:
--
--   Needs you
--     · urgent  (< 6h)   red timer, pulsing dot, 2px red top rule, message
--     · soon    (6–24h)  countered BY THEM → ledger, 24h clock
--     · calm    (> 24h)  plain muted timer
--     · calm    (> 24h)  a second one, so "1 more" collapse can be seen
--   Waiting on them
--     · soon    (6–24h)  awaiting their reply → Withdraw offered
--     · calm    (> 24h)  awaiting their reply
--     · countered BY ME  → NO Withdraw (the server would refuse; see below)
--
-- RUN THIS IN THE SUPABASE DASHBOARD SQL EDITOR against the linked project.
-- It is idempotent — safe to re-run; it deletes and re-creates only the rows it
-- owns (the fixed uuids below), never anything else.
--
-- PREREQUISITE: sign in on the emulator FIRST with muhammadsarankhalid@gmail.com.
-- The production database was reset on 2026-09-06, so auth.users was emptied;
-- this script deliberately does NOT create your account. Creating an auth row
-- for a real address would collide with the OTP / Google identity you actually
-- sign in with, so it looks yours up and stops with a clear message if absent.
-- =============================================================================

do $seed_challenges$
declare
  v_me            uuid;
  t_mine          constant uuid := 'cc000000-0000-4000-8000-000000000001';
  -- Opponent teams. Owners are synthetic accounts created below; they never
  -- sign in, they exist so teams.created_by has somewhere to point.
  t_shalimar      constant uuid := 'cc000000-0000-4000-8000-000000000002';
  t_gulberg       constant uuid := 'cc000000-0000-4000-8000-000000000003';
  t_modeltown     constant uuid := 'cc000000-0000-4000-8000-000000000004';
  t_johar         constant uuid := 'cc000000-0000-4000-8000-000000000005';
  t_ravi          constant uuid := 'cc000000-0000-4000-8000-000000000006';
  t_cavalry       constant uuid := 'cc000000-0000-4000-8000-000000000007';

  v_fmt           constant jsonb := jsonb_build_object(
                    'overs_per_innings', 20, 'players_per_team', 11,
                    'balls_per_over', 6, 'max_overs_per_bowler', 4,
                    'innings_per_side', 1, 'ball_type', 'tape');

  r record;
  v_owner uuid;
begin
  -- ── 0. Who is testing ─────────────────────────────────────────────────────
  select id into v_me
    from auth.users
   where lower(email) = 'muhammadsarankhalid@gmail.com'
   limit 1;

  if v_me is null then
    raise exception
      'No auth user for muhammadsarankhalid@gmail.com. Sign in on the emulator first, then re-run this script.';
  end if;

  -- profiles is created by the handle_new_auth_user trigger on sign-up, but be
  -- defensive: the screen needs a username for its own profile reads.
  insert into public.profiles (user_id, username, display_name, account_status)
  values (v_me, 'saran', 'Muhammad Saran', 'active')
  on conflict (user_id) do update
    set username     = coalesce(public.profiles.username, 'saran'),
        display_name = coalesce(public.profiles.display_name, 'Muhammad Saran');

  -- ── 1. Clean up anything this script previously made ──────────────────────
  delete from public.match_challenges
   where from_team_id in (t_mine, t_shalimar, t_gulberg, t_modeltown,
                          t_johar, t_ravi, t_cavalry)
      or to_team_id  in (t_mine, t_shalimar, t_gulberg, t_modeltown,
                          t_johar, t_ravi, t_cavalry);
  delete from public.team_members
   where team_id in (t_mine, t_shalimar, t_gulberg, t_modeltown,
                     t_johar, t_ravi, t_cavalry);

  -- ── 2. Synthetic owners for the opponent teams ────────────────────────────
  -- One throwaway account per opponent so teams.created_by is valid and
  -- is_team_manager() answers correctly for the other side.
  for r in
    select * from (values
      ('dd000000-0000-4000-8000-000000000002'::uuid, 'rider.captain@matchday.test',   'Adnan Riaz'),
      ('dd000000-0000-4000-8000-000000000003'::uuid, 'giant.captain@matchday.test',   'Faisal Iqbal'),
      ('dd000000-0000-4000-8000-000000000004'::uuid, 'striker.captain@matchday.test', 'Kamran Shah'),
      ('dd000000-0000-4000-8000-000000000005'::uuid, 'warrior.captain@matchday.test', 'Zain Abbas'),
      ('dd000000-0000-4000-8000-000000000006'::uuid, 'ravi.captain@matchday.test',    'Hamza Tariq'),
      ('dd000000-0000-4000-8000-000000000007'::uuid, 'king.captain@matchday.test',    'Owais Malik')
    ) as v(uid, email, name)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      reauthentication_token, phone_change, phone_change_token,
      created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000',
      r.uid, 'authenticated', 'authenticated', r.email,
      crypt('pass1234', gen_salt('bf')), now(),
      jsonb_build_object('display_name', r.name),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '', '', '', '', now(), now()
    ) on conflict (id) do nothing;

    -- profiles.username is constrained to ^[a-z0-9_]{3,20}$ — the dot in the
    -- synthetic email local-part is not legal, so it is folded to underscore.
    insert into public.profiles (user_id, username, display_name, account_status)
    values (
      r.uid,
      replace(split_part(r.email, '@', 1), '.', '_'),
      r.name,
      'active'
    )
    on conflict (user_id) do nothing;
  end loop;

  -- ── 3. Teams ──────────────────────────────────────────────────────────────
  -- The crest square on every challenge card takes its colour from
  -- teams.team_colors->>'primary' (TeamDto maps that to Team.primaryColor), so
  -- each opponent gets a distinct one.
  for r in
    select * from (values
      (t_mine,      'Saran Strikers',      '#DC4D32', null::uuid),
      (t_shalimar,  'Shalimar Riders',     '#3A4A6B', 'dd000000-0000-4000-8000-000000000002'::uuid),
      (t_gulberg,   'Gulberg Giants',      '#2E5D57', 'dd000000-0000-4000-8000-000000000003'::uuid),
      (t_modeltown, 'Model Town Strikers', '#B7892E', 'dd000000-0000-4000-8000-000000000004'::uuid),
      (t_johar,     'Johar Warriors',      '#7A3E5C', 'dd000000-0000-4000-8000-000000000005'::uuid),
      (t_ravi,      'Ravi Cricket Club',   '#4A5A3A', 'dd000000-0000-4000-8000-000000000006'::uuid),
      (t_cavalry,   'Cavalry Kings',       '#6B4A2E', 'dd000000-0000-4000-8000-000000000007'::uuid)
    ) as v(tid, tname, colour, owner)
  loop
    v_owner := coalesce(r.owner, v_me);
    insert into public.teams (
      team_id, team_name, team_type, privacy, status,
      created_by, team_colors, location, created_at, updated_at
    ) values (
      r.tid, r.tname, 'club', 'public', 'active',
      v_owner,
      jsonb_build_object('primary', r.colour),
      jsonb_build_object('city', 'Lahore', 'country', 'Pakistan'),
      now() - interval '30 days', now()
    )
    on conflict (team_id) do update
      set team_name   = excluded.team_name,
          team_colors = excluded.team_colors,
          created_by  = excluded.created_by,
          status      = 'active';

    -- The owner's roster row is created by the create_owner_membership trigger
    -- (2026-09-10) with role='owner', which outranks 'captain' — inserting it
    -- here would now collide with team_members_unique_active_user. Just
    -- backdate the joined_at the trigger stamped with now().
    update public.team_members
       set joined_at = now() - interval '30 days'
     where team_id = r.tid and user_id = v_owner and role = 'owner';
  end loop;

  -- ── 4. The challenges ─────────────────────────────────────────────────────
  -- Every insert states the tab and tier it is there to prove.

  -- NEEDS YOU · urgent (<6h). Carries a message so the quote block renders,
  -- and it is the ONLY red on the screen.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format, message,
    proposal_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000001',
    t_shalimar, t_mine, 'dd000000-0000-4000-8000-000000000002', 'pending',
    now() + interval '3 days' + interval '16 hours', 'Gaddafi Ground B', v_fmt,
    'Openers back from Karachi — up for a proper game?',
    now() + interval '2 hours 10 minutes',
    now() - interval '46 hours', now() - interval '46 hours'
  );

  -- NEEDS YOU · soon (6–24h), COUNTERED BY THEM. I sent it, they proposed
  -- different terms, so it is back on my desk — the case "Received/Sent" would
  -- file wrongly. Renders the ledger: my terms struck through, theirs live.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    countered_start_time, countered_venue, countered_format,
    -- match_challenges_decision_consistency: a countered row must record WHO
    -- countered and when. Only the receiver can counter (v1 does not allow a
    -- counter to be re-countered), so decided_by is always the other side.
    decided_by, decided_at,
    proposal_expires_at, counter_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000002',
    t_mine, t_gulberg, v_me, 'countered',
    now() + interval '4 days' + interval '15 hours', 'Nishat Park', v_fmt,
    now() + interval '4 days' + interval '8 hours',  'Ravi Ground 2', v_fmt,
    'dd000000-0000-4000-8000-000000000003', now() - interval '9 hours',
    now() + interval '20 hours', now() + interval '9 hours',
    now() - interval '30 hours', now() - interval '9 hours'
  );

  -- NEEDS YOU · calm (>24h).
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    proposal_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000003',
    t_modeltown, t_mine, 'dd000000-0000-4000-8000-000000000004', 'pending',
    now() + interval '11 days' + interval '7 hours', 'Model Town Complex',
    v_fmt || jsonb_build_object('overs_per_innings', 16),
    now() + interval '26 hours',
    now() - interval '22 hours', now() - interval '22 hours'
  );

  -- NEEDS YOU · calm (>24h), the fourth row.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    proposal_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000004',
    t_johar, t_mine, 'dd000000-0000-4000-8000-000000000005', 'pending',
    now() + interval '13 days' + interval '9 hours', 'Johar Town Ground',
    v_fmt, now() + interval '41 hours',
    now() - interval '7 hours', now() - interval '7 hours'
  );

  -- WAITING ON THEM · soon (6–24h). I sent it → Withdraw IS offered.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    proposal_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000005',
    t_mine, t_ravi, v_me, 'pending',
    now() + interval '6 days' + interval '10 hours', 'Ravi Ground 2', v_fmt,
    now() + interval '20 hours',
    now() - interval '28 hours', now() - interval '28 hours'
  );

  -- WAITING ON THEM · calm (>24h). Also mine → Withdraw offered.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    proposal_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000006',
    t_mine, t_shalimar, v_me, 'pending',
    now() + interval '9 days' + interval '8 hours', 'Shadman Park',
    v_fmt || jsonb_build_object('overs_per_innings', 16),
    now() + interval '44 hours',
    now() - interval '4 hours', now() - interval '4 hours'
  );

  -- WAITING ON THEM · COUNTERED BY ME. They sent it, I proposed different
  -- terms, so it is with them. NOTE: no Withdraw button on this one —
  -- cancel_match_request enforces is_team_manager(from_team_id) and I am not
  -- the sender, so the design's Withdraw would raise. The card shows
  -- "THEIR MOVE — YOUR COUNTER IS WITH THEM" instead. This row exists to prove
  -- that divergence on a real device.
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by, status,
    proposed_start_time, proposed_venue, proposed_format,
    countered_start_time, countered_venue, countered_format,
    decided_by, decided_at,
    proposal_expires_at, counter_expires_at, created_at, updated_at
  ) values (
    'ee000000-0000-4000-8000-000000000007',
    t_cavalry, t_mine, 'dd000000-0000-4000-8000-000000000007', 'countered',
    now() + interval '5 days' + interval '17 hours', 'Cavalry Ground', v_fmt,
    now() + interval '5 days' + interval '9 hours',  'Gaddafi Ground B', v_fmt,
    v_me, now() - interval '12 hours',
    now() + interval '30 hours', now() + interval '12 hours',
    now() - interval '20 hours', now() - interval '12 hours'
  );

  raise notice 'Seeded: 1 own team, 6 opponents, 7 challenges (4 needs-you, 3 waiting) for %', v_me;
end
$seed_challenges$;

-- Sanity read — expect 4 / 3.
select
  count(*) filter (where to_team_id   = 'cc000000-0000-4000-8000-000000000001'
                     and status = 'pending')   as inbound_pending,
  count(*) filter (where from_team_id = 'cc000000-0000-4000-8000-000000000001'
                     and status = 'countered') as countered_back_to_me,
  count(*) filter (where from_team_id = 'cc000000-0000-4000-8000-000000000001'
                     and status = 'pending')   as awaiting_them,
  count(*) filter (where to_team_id   = 'cc000000-0000-4000-8000-000000000001'
                     and status = 'countered') as my_counter_with_them
from public.match_challenges;
