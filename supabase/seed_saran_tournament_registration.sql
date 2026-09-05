-- =============================================================================
-- seed_saran_tournament_registration.sql
-- =============================================================================
-- Populates an active tournament in `registration` status for:
--   User: muhammadsarankhalid@gmail.com (saran / 892b4f62-38bb-4108-89a6-2689b2e08e97)
--
-- Contents:
--   • Tournament: Model Town Super Cup 2026 (registration open, closes in 3 days)
--   • 6 Approved teams (some marked paid, some unpaid)
--   • 2 Pending registration requests (with realistic applicant messages & squads)
--   • 1 Waitlisted registration request (exceeds 8-team capacity)
-- =============================================================================

DO $$
DECLARE
  v_user_id uuid := '892b4f62-38bb-4108-89a6-2689b2e08e97';
  v_tourn_id uuid := 'dddddddd-0000-4000-8000-000000000001';
BEGIN

  -- 1. Remove previous matches / tournament data for this demo tournament
  DELETE FROM public.matches WHERE tournament_id = v_tourn_id;
  DELETE FROM public.tournament_standings WHERE tournament_id = v_tourn_id;
  DELETE FROM public.tournament_teams WHERE tournament_id = v_tourn_id;
  DELETE FROM public.tournaments WHERE tournament_id = v_tourn_id;

  -- 2. Create the tournament in 'registration' status
  INSERT INTO public.tournaments (
    tournament_id,
    tournament_name,
    tournament_type,
    status,
    privacy,
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
    awards,
    created_at,
    updated_at
  ) VALUES (
    v_tourn_id,
    'Model Town Super Cup 2026',
    'knockout'::public.tournament_type,
    'registration'::public.tournament_status,
    'public'::public.tournament_privacy,
    'Eight clubs, two grounds, one weekend. Floodlit finals at Model Town Ground.',
    jsonb_build_object(
      'max_overs', 20,
      'max_overs_per_bowler', 4,
      'format_preset', 'T20',
      'ball_type', 'Leather (Red)'
    ),
    jsonb_build_object(
      'min_squad', 11,
      'max_squad', 16,
      'third_place_match', true,
      'prizes', jsonb_build_array(
        jsonb_build_object('label', 'Winner', 'amount', '1000000'),
        jsonb_build_object('label', 'Runner up', 'amount', '500000'),
        jsonb_build_object('label', 'MVP', 'amount', '100000')
      )
    ),
    (current_date + 7),
    (current_date + 9),
    (current_date + 3), -- "Closes in 3 days"
    jsonb_build_object('city', 'Lahore', 'lat', 31.5204, 'lng', 74.3587),
    jsonb_build_array(
      jsonb_build_object('name', 'Model Town Ground', 'city', 'Lahore'),
      jsonb_build_object('name', 'LCCA Ground', 'city', 'Lahore')
    ),
    'Winner PKR 1,000,000 · Runner up PKR 500,000 · MVP PKR 100,000',
    15000,
    4,
    8,
    v_user_id,
    ARRAY[v_user_id],
    '{}'::jsonb,
    now(),
    now()
  );

  -- 3. Insert Approved Teams (6 teams)
  -- 4 paid, 2 unpaid, realistic squads
  INSERT INTO public.tournament_teams (
    tournament_id, team_id, registered_by, registered_at, status, squad,
    seed_number, payment_status, decided_by, decided_at, message
  ) VALUES
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000001', -- Lahore Lions
    v_user_id,
    now() - interval '6 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 15)),
    1,
    'paid',
    v_user_id,
    now() - interval '5 days',
    'Defending champions ready for the title defense.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000002', -- Karachi Kingsmen
    v_user_id,
    now() - interval '5 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 14)),
    2,
    'paid',
    v_user_id,
    now() - interval '4 days',
    'Travelling squad confirmed with 14 players.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000003', -- Islamabad United XI
    v_user_id,
    now() - interval '4 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 13)),
    3,
    'paid',
    v_user_id,
    now() - interval '3 days',
    'Registration fee paid via bank transfer.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000004', -- Rawalpindi Royals
    v_user_id,
    now() - interval '4 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 14)),
    4,
    'paid',
    v_user_id,
    now() - interval '3 days',
    'Paid online. Squad list locked.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000005', -- Peshawar Panthers
    v_user_id,
    now() - interval '3 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 12)),
    5,
    'unpaid',
    v_user_id,
    now() - interval '2 days',
    'Approved. Cash fee to be collected at the ground.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000006', -- Quetta Qalandars
    v_user_id,
    now() - interval '3 days',
    'approved'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 13)),
    6,
    'unpaid',
    v_user_id,
    now() - interval '2 days',
    'Squad verified. Fee payment pending before opening match.'
  );

  -- 4. Insert Pending Registration Requests (Applications)
  INSERT INTO public.tournament_teams (
    tournament_id, team_id, registered_by, registered_at, status, squad,
    seed_number, payment_status, decided_by, decided_at, message
  ) VALUES
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000007', -- Multan Mavericks
    v_user_id,
    now() - interval '1 day',
    'pending'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 14)),
    null,
    null,
    null,
    null,
    'Squad of 14, all from Mughalpura. Can pay the PKR 15,000 cash on Friday.'
  ),
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000008', -- Faisalabad Falcons
    v_user_id,
    now() - interval '18 hours',
    'pending'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 13)),
    null,
    'paid',
    null,
    null,
    'Fee transferred in advance via Meezan Bank, ref #8841. Ready to play.'
  );

  -- 5. Insert Waitlisted Team (Exceeds capacity of 8 teams)
  INSERT INTO public.tournament_teams (
    tournament_id, team_id, registered_by, registered_at, status, squad,
    seed_number, payment_status, decided_by, decided_at, message
  ) VALUES
  (
    v_tourn_id,
    'a0000000-0000-0000-0000-000000000009', -- Sialkot Stallions
    v_user_id,
    now() - interval '6 hours',
    'pending'::public.tournament_registration_status,
    ARRAY(SELECT gen_random_uuid() FROM generate_series(1, 15)),
    null,
    null,
    null,
    null,
    'Happy to be first reserve on the waitlist if any team withdraws.'
  );

END $$;
