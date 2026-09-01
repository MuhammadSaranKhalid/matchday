-- =============================================================================
-- seed_tournament_registration_demo
-- =============================================================================
-- One tournament in `registration`, populated so every branch of the console's
-- Registrations tab (artboard 24) has something to show:
--
--   6 approved  → "Approved teams (6 / 8)", some paid and some not
--   2 pending   → the queue, with messages, approve / decline / mark-paid
--   1 waitlisted→ capacity is 8, so the ninth application waits
--
-- Idempotent: re-running deletes the demo cup by its fixed id and rebuilds it.
-- Not a migration — this is data, run with `supabase db query`.
-- =============================================================================

-- Fixed id so the seed can be re-run without accumulating cups.
delete from public.tournaments
 where tournament_id = 'dddddddd-0000-4000-8000-000000000001';

insert into public.tournaments (
  tournament_id, tournament_name, tournament_type, status, privacy,
  description, format, rules, start_date, end_date, registration_deadline,
  location, venues, prize_details, entry_fee, min_teams, max_teams,
  created_by, organizers
)
select
  'dddddddd-0000-4000-8000-000000000001',
  'Model Town Super Cup 2026',
  'knockout',
  'registration',
  'public',
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
      jsonb_build_object('label', 'Winner',    'amount', '1000000'),
      jsonb_build_object('label', 'Runner up', 'amount', '500000'),
      jsonb_build_object('label', 'MVP',       'amount', '100000')
    )
  ),
  (current_date + 7),
  (current_date + 9),
  (current_date + 2),                       -- "Closes in 2 days"
  jsonb_build_object('city', 'Lahore', 'lat', 31.5204, 'lng', 74.3587),
  jsonb_build_array(
    jsonb_build_object('name', 'Model Town Ground', 'city', 'Lahore'),
    jsonb_build_object('name', 'LCCA Ground',       'city', 'Lahore')
  ),
  'Winner PKR 1,000,000 · Runner up PKR 500,000 · MVP PKR 100,000',
  15000,
  4,
  8,
  p.user_id,
  array[p.user_id]
from public.profiles p
where p.username = 'saran';

-- -----------------------------------------------------------------------------
-- Registrations.
-- -----------------------------------------------------------------------------
-- Teams are picked deterministically by name so the seed reads the same on
-- every run. `squad` has no FK, so synthetic player ids are fine — the console
-- only renders the count.
with organiser as (
  select user_id from public.profiles where username = 'saran'
),
picked as (
  select
    t.team_id,
    t.team_name,
    row_number() over (order by t.team_name) as rn
  from public.teams t
  where t.team_name in (
    'Karachi Kingsmen', 'Rawalpindi Royals', 'Islamabad United XI',
    'Peshawar Panthers', 'Quetta Qalandars', 'Multan Mavericks',
    'Sialkot Stallions', 'Faisalabad Falcons', 'Gujranwala Gladiators'
  )
)
insert into public.tournament_teams (
  tournament_id, team_id, registered_by, registered_at, status, squad,
  seed_number, payment_status, decided_by, decided_at, message
)
select
  'dddddddd-0000-4000-8000-000000000001',
  picked.team_id,
  organiser.user_id,
  now() - (picked.rn || ' days')::interval,
  case when picked.rn <= 6 then 'approved'::public.tournament_registration_status
       else 'pending'::public.tournament_registration_status
  end,
  -- 11–14 players, varying by row so the counts are not all identical.
  (select array_agg(gen_random_uuid())
     from generate_series(1, 11 + (picked.rn % 4))),
  case when picked.rn <= 6 then picked.rn::int else null end,
  case
    when picked.rn <= 4 then 'paid'          -- 4 of the 6 approved have paid
    when picked.rn <= 6 then 'unpaid'
    when picked.rn = 8  then 'paid'          -- one applicant paid up front
    else null
  end,
  case when picked.rn <= 6 then organiser.user_id else null end,
  -- The CHECK requires decided_at whenever the status is approved/rejected.
  case when picked.rn <= 6 then now() - (picked.rn || ' hours')::interval
       else null
  end,
  case picked.rn
    when 7 then 'Squad of 14, all from Mughalpura. Can pay Friday.'
    when 8 then 'Fee transferred, Meezan ref 8841.'
    when 9 then 'Happy to be first reserve if the draw is full.'
    else null
  end
from picked
cross join organiser;
