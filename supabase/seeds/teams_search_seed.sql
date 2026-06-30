-- =============================================================================
-- DEV SEED · teams_search
-- =============================================================================
-- ~57 active+public teams across 13 Pakistan cities. Used to exercise the
-- Search tab end-to-end:
--
--   • name search       — distinct, trigram-friendly names ("Lions", "Eagles",
--                          "Tigers", "Kings", "Warriors", …)
--   • city facets       — every city has ≥1 team so `team-place-facets` returns
--                          a multi-row chip set; Lahore dominates (12) → first chip
--   • near-me / blend   — every team has lat/lng + country_code='PK' so
--                          ST_DWithin + distance-decay scoring work
--   • verified ticks    — ~30% are is_verified=true so the red check renders
--   • crest colors      — every team has a primary hex in team_colors so the
--                          monogram tile renders in brand colour
--
-- HOW TO RUN
--   Either:
--     a) Supabase Studio SQL editor → paste this file → Run (uses service role,
--        bypasses RLS).
--     b) Supabase CLI:  supabase db execute --file supabase/seeds/teams_search_seed.sql
--
-- IDEMPOTENT — uses fixed UUIDs (`00000000-0000-0000-0000-0000000000xx`) with
-- `ON CONFLICT (team_id) DO NOTHING`. Re-running is a safe no-op.
--
-- CLEANUP — single DELETE drops the entire seed (curated + procedural):
--     delete from public.teams
--      where team_id >= '00000000-0000-0000-0000-000000000001'::uuid
--        and team_id <= '00000000-0000-0000-0000-000000000fff'::uuid;
--
-- NOT a migration. Lives outside supabase/migrations/ so production schema
-- pushes never include it. Test data only — do NOT run against prod.
--
-- OWNER — every team needs an owner_id because the create_team_chat trigger
-- (0240) seeds a chat_members row keyed by owner_id, and chat_members.user_id
-- is NOT NULL. The DO block below auto-picks the oldest profile (your account
-- if you're the only user). To target a specific profile, paste their user_id
-- into v_override_owner below.
-- =============================================================================

do $$
declare
  -- Optional override: paste a specific profiles.user_id here (else the
  -- oldest profile is used).
  v_override_owner uuid := null;
  v_owner uuid;
begin
  v_owner := coalesce(
    v_override_owner,
    (select user_id from public.profiles order by created_at asc limit 1)
  );
  if v_owner is null then
    raise exception
      'No profile found. Sign in to the app once (so a profile row exists), then re-run this seed.';
  end if;

insert into public.teams
  (team_id, team_name, team_type, tagline, logo_monogram, team_colors,
   description, home_ground, location, founded_year, owner_id, managers,
   is_verified, privacy, status, max_squad_size)
values
  -- ─── Lahore (12) ─────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000001', 'Lahore Lions', 'club',
   'Roar of the Ravi', 'LL',
   '{"primary":"#DC4D32","secondary":"#29251E"}'::jsonb,
   'Top-flight Lahore side. Trains at Bagh-e-Jinnah nets.',
   'Bagh-e-Jinnah Ground',
   '{"city":"Lahore","lat":31.5204,"lng":74.3587,"country_code":"PK"}'::jsonb,
   2014, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000002', 'DHA United', 'club',
   'Defence Phase 5 regulars', 'DU',
   '{"primary":"#2F7D54","secondary":"#FBFAF6"}'::jsonb,
   'DHA-based weekend club, T20 specialists.',
   'DHA Sports Complex',
   '{"city":"Lahore","lat":31.4760,"lng":74.4180,"country_code":"PK"}'::jsonb,
   2018, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000003', 'Model Town XI', 'village',
   'Block C ground regulars', 'MX',
   '{"primary":"#5B4A3A","secondary":"#F4ECDD"}'::jsonb,
   null, 'Model Town Park',
   '{"city":"Lahore","lat":31.4828,"lng":74.3258,"country_code":"PK"}'::jsonb,
   2009, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000004', 'Mohalla Kings', 'casual',
   'Tape ball every Friday', 'MK',
   '{"primary":"#A8552E","secondary":"#FBFAF6"}'::jsonb,
   null, 'Walton Park',
   '{"city":"Lahore","lat":31.5025,"lng":74.3935,"country_code":"PK"}'::jsonb,
   2020, v_owner, '{}', false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000005', 'Gulberg Defenders', 'club',
   'Hard-ball club', 'GD',
   '{"primary":"#2F7D54","secondary":"#29251E"}'::jsonb,
   null, 'Gulberg Stadium',
   '{"city":"Lahore","lat":31.5172,"lng":74.3454,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',true, 'public', 'active', 30),

  ('00000000-0000-0000-0000-000000000006', 'Johar Town XI', 'village',
   null, 'JT',
   '{"primary":"#6A6F2A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Johar Town Ground',
   '{"city":"Lahore","lat":31.4711,"lng":74.2830,"country_code":"PK"}'::jsonb,
   2012, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000007', 'Walled City Warriors', 'casual',
   'Old city stars', 'WW',
   '{"primary":"#8C2218","secondary":"#F4ECDD"}'::jsonb,
   null, 'Minar-e-Pakistan Ground',
   '{"city":"Lahore","lat":31.5921,"lng":74.3079,"country_code":"PK"}'::jsonb,
   2008, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000008', 'Cantt Royals', 'corporate',
   null, 'CR',
   '{"primary":"#6E2A22","secondary":"#FBFAF6"}'::jsonb,
   null, 'Lahore Cantt Sports',
   '{"city":"Lahore","lat":31.5450,"lng":74.4000,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000009', 'Old Boys XI', 'casual',
   'Reunion side', 'OB',
   '{"primary":"#4A4337","secondary":"#FBFAF6"}'::jsonb,
   null, 'Aitchison Ground',
   '{"city":"Lahore","lat":31.5497,"lng":74.3275,"country_code":"PK"}'::jsonb,
   2005, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000000a', 'Iqbal Town Strikers', 'village',
   null, 'IS',
   '{"primary":"#3A8F8F","secondary":"#29251E"}'::jsonb,
   null, 'Iqbal Town Park',
   '{"city":"Lahore","lat":31.4945,"lng":74.2890,"country_code":"PK"}'::jsonb,
   2019, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000000b', 'Shadman Tigers', 'club',
   null, 'ST',
   '{"primary":"#C98A2B","secondary":"#29251E"}'::jsonb,
   null, 'Shadman Ground',
   '{"city":"Lahore","lat":31.5380,"lng":74.3120,"country_code":"PK"}'::jsonb,
   2015, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000000c', 'Punjab University Stars', 'university',
   'Hostel block champs', 'PU',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   null, 'PU Stadium',
   '{"city":"Lahore","lat":31.4910,"lng":74.3060,"country_code":"PK"}'::jsonb,
   2011, v_owner, '{}',true, 'public', 'active', 30),

  -- ─── Karachi (9) ─────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-00000000000d', 'Karachi Eagles', 'club',
   'Coastal flyers', 'KE',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   'Hard-ball T20 specialists, registered with KCCA.',
   'National Stadium Karachi',
   '{"city":"Karachi","lat":24.8930,"lng":67.0824,"country_code":"PK"}'::jsonb,
   2010, v_owner, '{}',true, 'public', 'active', 30),

  ('00000000-0000-0000-0000-00000000000e', 'Karachi Cobras', 'club',
   null, 'KC',
   '{"primary":"#2E3E63","secondary":"#FBFAF6"}'::jsonb,
   null, 'UBL Sports Complex',
   '{"city":"Karachi","lat":24.8607,"lng":67.0011,"country_code":"PK"}'::jsonb,
   2013, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000000f', 'Defence Sharks', 'club',
   'DHA Karachi side', 'DS',
   '{"primary":"#1E5A2C","secondary":"#FBFAF6"}'::jsonb,
   null, 'DHA Cricket Stadium',
   '{"city":"Karachi","lat":24.8000,"lng":67.0500,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000010', 'Korangi XI', 'village',
   null, 'KX',
   '{"primary":"#A8552E","secondary":"#29251E"}'::jsonb,
   null, 'Korangi Ground',
   '{"city":"Karachi","lat":24.8385,"lng":67.1390,"country_code":"PK"}'::jsonb,
   2007, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000011', 'Malir Magicians', 'casual',
   null, 'MM',
   '{"primary":"#6A6F2A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Malir Cantt Ground',
   '{"city":"Karachi","lat":24.8980,"lng":67.2030,"country_code":"PK"}'::jsonb,
   2020, v_owner, '{}', false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000012', 'Saddar Sultans', 'club',
   null, 'SS',
   '{"primary":"#6A6F2A","secondary":"#29251E"}'::jsonb,
   null, 'Aga Khan Gymkhana',
   '{"city":"Karachi","lat":24.8540,"lng":67.0240,"country_code":"PK"}'::jsonb,
   2014, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000013', 'Clifton Cricketers', 'club',
   null, 'CC',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'Clifton Cricket Ground',
   '{"city":"Karachi","lat":24.8170,"lng":67.0290,"country_code":"PK"}'::jsonb,
   2018, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000014', 'Gulshan Gladiators', 'village',
   null, 'GG',
   '{"primary":"#DC4D32","secondary":"#FBFAF6"}'::jsonb,
   null, 'Gulshan Ground',
   '{"city":"Karachi","lat":24.9180,"lng":67.0980,"country_code":"PK"}'::jsonb,
   2011, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000015', 'NED Engineers XI', 'university',
   'NED University side', 'NE',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   null, 'NED Sports Ground',
   '{"city":"Karachi","lat":24.9320,"lng":67.1100,"country_code":"PK"}'::jsonb,
   2009, v_owner, '{}',true, 'public', 'active', 30),

  -- ─── Multan (6) ──────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000016', 'Multan Tigers', 'club',
   'Sultans of South Punjab', 'MT',
   '{"primary":"#C98A2B","secondary":"#29251E"}'::jsonb,
   null, 'Multan Cricket Stadium',
   '{"city":"Multan","lat":30.1575,"lng":71.5249,"country_code":"PK"}'::jsonb,
   2012, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000017', 'Bosan Boys', 'village',
   null, 'BB',
   '{"primary":"#5B4A3A","secondary":"#F4ECDD"}'::jsonb,
   null, 'Bosan Road Ground',
   '{"city":"Multan","lat":30.2080,"lng":71.4720,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000018', 'Cantonment Pride', 'corporate',
   null, 'CP',
   '{"primary":"#6E2A22","secondary":"#FBFAF6"}'::jsonb,
   null, 'Multan Cantt Ground',
   '{"city":"Multan","lat":30.1820,"lng":71.5180,"country_code":"PK"}'::jsonb,
   2015, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000019', 'Shah Rukn-e-Alam XI', 'casual',
   null, 'SR',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'Rukn-e-Alam Ground',
   '{"city":"Multan","lat":30.1980,"lng":71.4920,"country_code":"PK"}'::jsonb,
   2019, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000001a', 'New Multan Royals', 'club',
   null, 'NM',
   '{"primary":"#2F7D54","secondary":"#29251E"}'::jsonb,
   null, 'New Multan Sports Complex',
   '{"city":"Multan","lat":30.2050,"lng":71.4530,"country_code":"PK"}'::jsonb,
   2013, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000001b', 'Khanewal Express', 'village',
   null, 'KX',
   '{"primary":"#A8552E","secondary":"#FBFAF6"}'::jsonb,
   null, 'Khanewal Stadium',
   '{"city":"Multan","lat":30.3000,"lng":71.9320,"country_code":"PK"}'::jsonb,
   2010, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Gujranwala (5) ──────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-00000000001c', 'Gujranwala Sultans', 'club',
   'City of wrestlers, side of bowlers', 'GS',
   '{"primary":"#6A6F2A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Jinnah Stadium',
   '{"city":"Gujranwala","lat":32.1877,"lng":74.1945,"country_code":"PK"}'::jsonb,
   2011, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000001d', 'GIK Strikers', 'university',
   null, 'GI',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   null, 'GIK Ground',
   '{"city":"Gujranwala","lat":32.1500,"lng":74.1880,"country_code":"PK"}'::jsonb,
   2014, v_owner, '{}',false, 'public', 'active', 30),

  ('00000000-0000-0000-0000-00000000001e', 'Wazirabad XI', 'village',
   null, 'WX',
   '{"primary":"#5B4A3A","secondary":"#F4ECDD"}'::jsonb,
   null, 'Wazirabad Ground',
   '{"city":"Gujranwala","lat":32.4435,"lng":74.1200,"country_code":"PK"}'::jsonb,
   2008, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000001f', 'Civil Lines Lions', 'corporate',
   null, 'CL',
   '{"primary":"#DC4D32","secondary":"#FBFAF6"}'::jsonb,
   null, 'Civil Lines Park',
   '{"city":"Gujranwala","lat":32.1700,"lng":74.2100,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000020', 'Model Town Falcons', 'club',
   null, 'MF',
   '{"primary":"#2E3E63","secondary":"#FBFAF6"}'::jsonb,
   null, 'Model Town Sports',
   '{"city":"Gujranwala","lat":32.2050,"lng":74.1850,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',true, 'public', 'active', 25),

  -- ─── Faisalabad (4) ──────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000021', 'Faisalabad Wolves', 'club',
   'Iqbal Stadium regulars', 'FW',
   '{"primary":"#5B4A3A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Iqbal Stadium',
   '{"city":"Faisalabad","lat":31.4504,"lng":73.1350,"country_code":"PK"}'::jsonb,
   2010, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000022', 'Lyallpur XI', 'village',
   null, 'LP',
   '{"primary":"#C98A2B","secondary":"#29251E"}'::jsonb,
   null, 'Lyallpur Ground',
   '{"city":"Faisalabad","lat":31.4250,"lng":73.0700,"country_code":"PK"}'::jsonb,
   2013, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000023', 'Samanabad Stars', 'casual',
   null, 'SS',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'Samanabad Park',
   '{"city":"Faisalabad","lat":31.4380,"lng":73.0610,"country_code":"PK"}'::jsonb,
   2018, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000024', 'Jaranwala Tigers', 'village',
   null, 'JT',
   '{"primary":"#DC4D32","secondary":"#29251E"}'::jsonb,
   null, 'Jaranwala Stadium',
   '{"city":"Faisalabad","lat":31.3360,"lng":73.4290,"country_code":"PK"}'::jsonb,
   2009, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Rawalpindi (4) ──────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000025', 'Pindi Falcons', 'club',
   'Pindi Stadium side', 'PF',
   '{"primary":"#2E3E63","secondary":"#FBFAF6"}'::jsonb,
   null, 'Rawalpindi Cricket Stadium',
   '{"city":"Rawalpindi","lat":33.5651,"lng":73.0169,"country_code":"PK"}'::jsonb,
   2012, v_owner, '{}',true, 'public', 'active', 30),

  ('00000000-0000-0000-0000-000000000026', 'Saddar Cricketers', 'casual',
   null, 'SC',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'Saddar Bazaar Ground',
   '{"city":"Rawalpindi","lat":33.5980,"lng":73.0480,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000027', 'Westridge XI', 'village',
   null, 'WR',
   '{"primary":"#6A6F2A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Westridge Ground',
   '{"city":"Rawalpindi","lat":33.5860,"lng":72.9920,"country_code":"PK"}'::jsonb,
   2015, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000028', 'Tench Bhata Boys', 'casual',
   null, 'TB',
   '{"primary":"#A8552E","secondary":"#FBFAF6"}'::jsonb,
   null, 'Tench Bhata Park',
   '{"city":"Rawalpindi","lat":33.5990,"lng":73.0240,"country_code":"PK"}'::jsonb,
   2019, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Islamabad (4) ───────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000029', 'Islamabad Capitals', 'club',
   'Capital territory champs', 'IC',
   '{"primary":"#2F7D54","secondary":"#29251E"}'::jsonb,
   null, 'Diamond Club Ground',
   '{"city":"Islamabad","lat":33.6844,"lng":73.0479,"country_code":"PK"}'::jsonb,
   2014, v_owner, '{}',true, 'public', 'active', 30),

  ('00000000-0000-0000-0000-00000000002a', 'F-7 XI', 'casual',
   null, 'F7',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   null, 'F-7 Markaz Ground',
   '{"city":"Islamabad","lat":33.7090,"lng":73.0510,"country_code":"PK"}'::jsonb,
   2018, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000002b', 'G-10 Gladiators', 'village',
   null, 'GG',
   '{"primary":"#6E2A22","secondary":"#F4ECDD"}'::jsonb,
   null, 'G-10 Ground',
   '{"city":"Islamabad","lat":33.6790,"lng":72.9930,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000002c', 'Bahria Town Bashers', 'corporate',
   null, 'BT',
   '{"primary":"#C98A2B","secondary":"#29251E"}'::jsonb,
   null, 'Bahria Sports Complex',
   '{"city":"Islamabad","lat":33.5290,"lng":73.0850,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Sialkot (3) ─────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-00000000002d', 'Sialkot Stallions', 'club',
   'City of iqbal, side of class', 'SS',
   '{"primary":"#1E5A2C","secondary":"#FBFAF6"}'::jsonb,
   null, 'Jinnah Stadium Sialkot',
   '{"city":"Sialkot","lat":32.4945,"lng":74.5229,"country_code":"PK"}'::jsonb,
   2008, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000002e', 'Cantt Cricketers', 'casual',
   null, 'CC',
   '{"primary":"#5B4A3A","secondary":"#F4ECDD"}'::jsonb,
   null, 'Sialkot Cantt Ground',
   '{"city":"Sialkot","lat":32.5210,"lng":74.5400,"country_code":"PK"}'::jsonb,
   2015, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-00000000002f', 'Daska XI', 'village',
   null, 'DX',
   '{"primary":"#A8552E","secondary":"#29251E"}'::jsonb,
   null, 'Daska Ground',
   '{"city":"Sialkot","lat":32.3290,"lng":74.3530,"country_code":"PK"}'::jsonb,
   2011, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Peshawar (3) ────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000030', 'Peshawar Zalmi XI', 'club',
   'Frontier youth', 'PZ',
   '{"primary":"#6E2A22","secondary":"#FBFAF6"}'::jsonb,
   null, 'Arbab Niaz Stadium',
   '{"city":"Peshawar","lat":34.0151,"lng":71.5249,"country_code":"PK"}'::jsonb,
   2013, v_owner, '{}',true, 'public', 'active', 30),

  ('00000000-0000-0000-0000-000000000031', 'University Town XI', 'university',
   null, 'UT',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'UoP Ground',
   '{"city":"Peshawar","lat":34.0100,"lng":71.4970,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',false, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000032', 'Hayatabad Hawks', 'village',
   null, 'HH',
   '{"primary":"#3563B6","secondary":"#FBFAF6"}'::jsonb,
   null, 'Hayatabad Sports Complex',
   '{"city":"Peshawar","lat":33.9970,"lng":71.4440,"country_code":"PK"}'::jsonb,
   2018, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Hyderabad (2) ───────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000033', 'Hyderabad Hawks', 'club',
   null, 'HH',
   '{"primary":"#5B4A3A","secondary":"#FBFAF6"}'::jsonb,
   null, 'Niaz Stadium',
   '{"city":"Hyderabad","lat":25.3960,"lng":68.3578,"country_code":"PK"}'::jsonb,
   2012, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000034', 'Latifabad XI', 'village',
   null, 'LX',
   '{"primary":"#6A6F2A","secondary":"#29251E"}'::jsonb,
   null, 'Latifabad Ground',
   '{"city":"Hyderabad","lat":25.3870,"lng":68.3760,"country_code":"PK"}'::jsonb,
   2015, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Quetta (2) ──────────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000035', 'Quetta Gladiators XI', 'club',
   'Bugti Stadium regulars', 'QG',
   '{"primary":"#6E2A22","secondary":"#F4ECDD"}'::jsonb,
   null, 'Bugti Stadium',
   '{"city":"Quetta","lat":30.1798,"lng":66.9750,"country_code":"PK"}'::jsonb,
   2014, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000036', 'Cantt Bashers', 'casual',
   null, 'CB',
   '{"primary":"#3A8F8F","secondary":"#FBFAF6"}'::jsonb,
   null, 'Quetta Cantt Ground',
   '{"city":"Quetta","lat":30.2010,"lng":67.0050,"country_code":"PK"}'::jsonb,
   2017, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Bahawalpur (2) ──────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000037', 'Bahawalpur Stags', 'club',
   null, 'BS',
   '{"primary":"#C98A2B","secondary":"#29251E"}'::jsonb,
   null, 'Bahawal Stadium',
   '{"city":"Bahawalpur","lat":29.3956,"lng":71.6836,"country_code":"PK"}'::jsonb,
   2011, v_owner, '{}',true, 'public', 'active', 25),

  ('00000000-0000-0000-0000-000000000038', 'Sadiqabad XI', 'village',
   null, 'SX',
   '{"primary":"#5B4A3A","secondary":"#F4ECDD"}'::jsonb,
   null, 'Sadiqabad Ground',
   '{"city":"Bahawalpur","lat":28.3060,"lng":70.1290,"country_code":"PK"}'::jsonb,
   2016, v_owner, '{}',false, 'public', 'active', 25),

  -- ─── Munjirwali (1) ──────────────────────────────────────────────────────
  ('00000000-0000-0000-0000-000000000039', 'Munjirwali Heroes', 'village',
   'Gully tape ball legends', 'MH',
   '{"primary":"#A8552E","secondary":"#F4ECDD"}'::jsonb,
   null, 'Munjirwali Village Ground',
   '{"city":"Munjirwali","lat":28.2100,"lng":71.9200,"country_code":"PK"}'::jsonb,
   2020, v_owner, '{}',false, 'public', 'active', 25)

on conflict (team_id) do nothing;

end $$;

-- =============================================================================
-- PART 2 · procedural fill for proximity testing (~230 teams, UUIDs 0x100+)
-- =============================================================================
-- The 57 curated rows above are recognizable but too few to exercise the
-- ST_DWithin / distance-decay paths properly. This block generates more rows
-- per city with banded jitter so distances vary from ~0.5 km to ~33 km from
-- each city centre:
--
--   • 50% of teams: ±5 km   — well inside the default 25 km radius
--   • 30% of teams: ±15 km  — at / near the default radius edge
--   • 20% of teams: ±30 km  — only reachable after "Expand to 50 km"
--
-- Names come from a prefix × suffix combinatorial pool (~30 × ~30 → 900
-- combos), so 230 rows have few duplicates. UUIDs start at 0x100 to avoid
-- colliding with PART 1.
--
-- The selection formulas (mod-based) are deterministic — re-running produces
-- the same team in the same place. Combined with ON CONFLICT DO NOTHING this
-- is idempotent.
-- =============================================================================
do $$
declare
  -- Same override slot as PART 1.
  v_override_owner uuid := null;
  v_owner uuid;

  -- Parallel city arrays. Counts target ~230 procedural rows.
  v_city_names text[] := array[
    'Lahore','Karachi','Multan','Faisalabad','Gujranwala','Rawalpindi',
    'Islamabad','Sialkot','Peshawar','Sargodha','Sahiwal','Hyderabad',
    'Quetta','Bahawalpur','Abbottabad','Mirpur','Mailsi','Pakpattan','Sheikhupura'
  ];
  v_city_lats float[] := array[
    31.5204, 24.8607, 30.1575, 31.4504, 32.1877, 33.5651,
    33.6844, 32.4945, 34.0151, 32.0836, 30.6700, 25.3960,
    30.1798, 29.3956, 34.1463, 33.1478, 29.7990, 30.3457, 31.7167
  ];
  v_city_lngs float[] := array[
    74.3587, 67.0011, 71.5249, 73.1350, 74.1945, 73.0169,
    73.0479, 74.5229, 71.5249, 72.6711, 73.1010, 68.3578,
    66.9750, 71.6836, 73.2117, 73.7517, 72.1750, 73.3833, 73.9783
  ];
  v_city_counts int[] := array[
    35, 25, 18, 16, 13, 14,
    14, 12, 12, 10, 10, 10,
     8,  8,  8,  7,  5,  5,  10
  ];

  -- Name pools (Pakistan-flavoured cricket club patterns).
  v_prefixes text[] := array[
    'DHA','Cantt','Model Town','Walled City','Saddar','Civil Lines',
    'Bahria Town','Gulberg','Johar Town','Iqbal Town','Shadman','Gulshan',
    'Korangi','Bosan','Malir','Defence','Cantonment','Old Boys','Royal',
    'United','National','Frontier','Speed','Power','Premier','Mohalla',
    'Hayatabad','Westridge','New','Nishtar'
  ];
  v_suffixes text[] := array[
    'Lions','Eagles','Tigers','Falcons','Wolves','Cobras','Sharks','Hawks',
    'Bears','Stallions','Bulls','Kings','Sultans','Royals','Pride',
    'Warriors','Strikers','Defenders','Bashers','Hitters','Express',
    'Gladiators','Heroes','Stars','XI','Sports','Cricket Club','United',
    'Magicians','Cricketers'
  ];

  -- Colour pairs (primary, secondary) drawn from the brand palette.
  v_primaries text[] := array[
    '#DC4D32','#2F7D54','#3563B6','#C98A2B','#5B4A3A','#6A6F2A',
    '#A8552E','#3A8F8F','#6E2A22','#2E3E63','#1E5A2C','#8C2218'
  ];
  v_secondaries text[] := array[
    '#29251E','#FBFAF6','#FBFAF6','#29251E','#F4ECDD','#FBFAF6',
    '#FBFAF6','#FBFAF6','#F4ECDD','#FBFAF6','#FBFAF6','#F4ECDD'
  ];

  v_types text[] := array['club','village','casual','corporate','school','university'];

  -- Loop state.
  v_idx int := 256;  -- 0x100 → first procedural UUID byte
  v_city_idx int;
  v_i int;
  v_count_inserted int := 0;

  v_city_name text;
  v_city_lat float;
  v_city_lng float;
  v_city_count int;

  v_prefix text;
  v_suffix text;
  v_name text;
  v_type text;
  v_primary text;
  v_secondary text;
  v_monogram text;
  v_verified bool;
  v_band int;
  v_scale float;
  v_dir1 int;
  v_dir2 int;
  v_lat float;
  v_lng float;
  v_team_id uuid;
begin
  v_owner := coalesce(
    v_override_owner,
    (select user_id from public.profiles order by created_at asc limit 1)
  );
  if v_owner is null then
    raise exception
      'No profile found. Sign in to the app once (so a profile row exists), then re-run this seed.';
  end if;

  for v_city_idx in 1 .. array_length(v_city_names, 1) loop
    v_city_name  := v_city_names[v_city_idx];
    v_city_lat   := v_city_lats[v_city_idx];
    v_city_lng   := v_city_lngs[v_city_idx];
    v_city_count := v_city_counts[v_city_idx];

    for v_i in 1 .. v_city_count loop
      -- Name = {prefix} {suffix}. Coprime multipliers spread the (p, s)
      -- combination through the cross-product reasonably uniformly.
      v_prefix := v_prefixes[1 + ((v_idx * 7  + v_i * 3) % array_length(v_prefixes, 1))];
      v_suffix := v_suffixes[1 + ((v_idx * 11 + v_i * 5) % array_length(v_suffixes, 1))];
      v_name   := v_prefix || ' ' || v_suffix;
      if length(v_name) > 50 then
        v_name := substring(v_name from 1 for 50);
      end if;
      if length(v_name) < 3 then
        v_name := v_name || ' XI';
      end if;

      -- Type, colour pair, monogram, founded year.
      v_type      := v_types[1 + ((v_idx * 3 + v_i) % array_length(v_types, 1))];
      v_primary   := v_primaries[1   + ((v_idx * 13) % array_length(v_primaries, 1))];
      v_secondary := v_secondaries[1 + ((v_idx * 13) % array_length(v_secondaries, 1))];
      v_monogram  := upper(substring(v_prefix from 1 for 1) || substring(v_suffix from 1 for 1));

      -- ~30% verified.
      v_verified := ((v_idx + v_i * 3) % 10) < 3;

      -- Banded jitter: 50% inner / 30% middle / 20% outer.
      v_band := (v_idx * 7 + v_i * 11) % 100;
      v_scale := case
        when v_band < 50 then 0.005   -- ±5 km
        when v_band < 80 then 0.015   -- ±15 km
        else                  0.030   -- ±30 km
      end;
      -- Two independent direction values in -10 .. +9.
      v_dir1 := ((v_idx * 13 + v_i)     % 20) - 10;
      v_dir2 := ((v_idx * 19 + v_i * 3) % 20) - 10;
      v_lat  := v_city_lat + v_dir1 * v_scale;
      v_lng  := v_city_lng + v_dir2 * v_scale;

      v_team_id := ('00000000-0000-0000-0000-' || lpad(to_hex(v_idx), 12, '0'))::uuid;

      insert into public.teams
        (team_id, team_name, team_type, logo_monogram, team_colors,
         location, founded_year, owner_id, managers,
         is_verified, privacy, status, max_squad_size)
      values
        (v_team_id,
         v_name,
         v_type::public.team_type,
         v_monogram,
         jsonb_build_object('primary', v_primary, 'secondary', v_secondary),
         jsonb_build_object('city', v_city_name, 'lat', v_lat, 'lng', v_lng, 'country_code', 'PK'),
         2000 + ((v_idx * 3) % 25),
         v_owner,
         '{}'::uuid[],
         v_verified, 'public', 'active', 25)
      on conflict (team_id) do nothing;

      v_count_inserted := v_count_inserted + 1;
      v_idx := v_idx + 1;
    end loop;
  end loop;

  raise notice 'Procedural fill: attempted % rows (UUIDs 0x100..0x%)',
    v_count_inserted, lpad(to_hex(v_idx - 1), 3, '0');
end $$;

-- =============================================================================
-- PART 3 · satellite-town fill for radius-band testing (~205 teams, UUIDs 0x200+)
-- =============================================================================
-- 16 satellite / secondary cities deliberately positioned 30-100 km from major
-- metros. This batch is what exercises the "Expand to 50 km / 100 km" CTAs
-- and the cross-city proximity bleed (e.g. Murree teams surfacing when "Near
-- me" is set at Islamabad). Without these, every city is an isolated island
-- and radius-expansion is untested.
--
-- Jitter is tighter than PART 2 — smaller towns hold density closer in:
--   • 50% within ±3 km   (town core)
--   • 30% within ±10 km  (peri-urban)
--   • 20% within ±20 km  (outer villages)
--
-- Distance from parent metro (rough):
--   Kasur          ~50 km S  of Lahore       — exercises 50 km expand
--   Gujrat         ~50 km N  of Gujranwala
--   Hafizabad      ~60 km W  of Gujranwala
--   Chiniot        ~45 km N  of Faisalabad
--   Toba Tek Singh ~60 km S  of Faisalabad
--   Okara          ~110 km   between Lahore + Multan
--   Khanewal       ~50 km NE of Multan
--   Lodhran        ~50 km SE of Multan
--   Jhelum         ~100 km E of Rawalpindi
--   Mardan         ~60 km NE of Peshawar
--   Sukkur         standalone N Sindh
--   Larkana        standalone N Sindh
--   Mingora (Swat) standalone N KP
--   Mansehra       standalone N KP
--   Murree         ~30 km NE of Islamabad     — exercises bleed at 50 km
--   Wah Cantt      ~35 km W  of Islamabad     — exercises bleed at 50 km
--
-- UUIDs start at 0x200 (512) so PART 2's 0x100..0x1EF range is safe.
-- =============================================================================
do $$
declare
  v_override_owner uuid := null;
  v_owner uuid;

  v_city_names text[] := array[
    'Kasur','Gujrat','Hafizabad','Chiniot','Toba Tek Singh','Okara',
    'Khanewal','Lodhran','Jhelum','Mardan','Sukkur','Larkana',
    'Mingora','Mansehra','Murree','Wah Cantt'
  ];
  v_city_lats float[] := array[
    31.1156, 32.5740, 32.0712, 31.7204, 30.9709, 30.8108,
    30.3017, 29.5454, 32.9425, 34.1986, 27.6995, 27.5586,
    34.7795, 34.3309, 33.9070, 33.7917
  ];
  v_city_lngs float[] := array[
    74.4467, 74.0776, 73.6884, 72.9783, 72.4827, 73.4534,
    71.9320, 71.6325, 73.7257, 72.0404, 68.8674, 68.2127,
    72.3617, 73.1968, 73.3943, 72.7104
  ];
  v_city_counts int[] := array[
    18, 18, 12, 12, 12, 10,
    18, 10, 15, 12, 20, 10,
    10, 10, 10,  8
  ];

  -- Same prefix / suffix / colour pools as PART 2; scope-isolated.
  v_prefixes text[] := array[
    'DHA','Cantt','Model Town','Walled City','Saddar','Civil Lines',
    'Bahria Town','Gulberg','Johar Town','Iqbal Town','Shadman','Gulshan',
    'Korangi','Bosan','Malir','Defence','Cantonment','Old Boys','Royal',
    'United','National','Frontier','Speed','Power','Premier','Mohalla',
    'Hayatabad','Westridge','New','Nishtar'
  ];
  v_suffixes text[] := array[
    'Lions','Eagles','Tigers','Falcons','Wolves','Cobras','Sharks','Hawks',
    'Bears','Stallions','Bulls','Kings','Sultans','Royals','Pride',
    'Warriors','Strikers','Defenders','Bashers','Hitters','Express',
    'Gladiators','Heroes','Stars','XI','Sports','Cricket Club','United',
    'Magicians','Cricketers'
  ];
  v_primaries text[] := array[
    '#DC4D32','#2F7D54','#3563B6','#C98A2B','#5B4A3A','#6A6F2A',
    '#A8552E','#3A8F8F','#6E2A22','#2E3E63','#1E5A2C','#8C2218'
  ];
  v_secondaries text[] := array[
    '#29251E','#FBFAF6','#FBFAF6','#29251E','#F4ECDD','#FBFAF6',
    '#FBFAF6','#FBFAF6','#F4ECDD','#FBFAF6','#FBFAF6','#F4ECDD'
  ];
  v_types text[] := array['club','village','casual','corporate','school','university'];

  v_idx int := 512;  -- 0x200 — past PART 2's last UUID (0x1EF).
  v_city_idx int;
  v_i int;
  v_count_inserted int := 0;

  v_city_name text;
  v_city_lat float;
  v_city_lng float;
  v_city_count int;

  v_prefix text;
  v_suffix text;
  v_name text;
  v_type text;
  v_primary text;
  v_secondary text;
  v_monogram text;
  v_verified bool;
  v_band int;
  v_scale float;
  v_dir1 int;
  v_dir2 int;
  v_lat float;
  v_lng float;
  v_team_id uuid;
begin
  v_owner := coalesce(
    v_override_owner,
    (select user_id from public.profiles order by created_at asc limit 1)
  );
  if v_owner is null then
    raise exception
      'No profile found. Sign in to the app once (so a profile row exists), then re-run this seed.';
  end if;

  for v_city_idx in 1 .. array_length(v_city_names, 1) loop
    v_city_name  := v_city_names[v_city_idx];
    v_city_lat   := v_city_lats[v_city_idx];
    v_city_lng   := v_city_lngs[v_city_idx];
    v_city_count := v_city_counts[v_city_idx];

    for v_i in 1 .. v_city_count loop
      v_prefix := v_prefixes[1 + ((v_idx * 7  + v_i * 3) % array_length(v_prefixes, 1))];
      v_suffix := v_suffixes[1 + ((v_idx * 11 + v_i * 5) % array_length(v_suffixes, 1))];
      v_name   := v_prefix || ' ' || v_suffix;
      if length(v_name) > 50 then
        v_name := substring(v_name from 1 for 50);
      end if;
      if length(v_name) < 3 then
        v_name := v_name || ' XI';
      end if;

      v_type      := v_types[1 + ((v_idx * 3 + v_i) % array_length(v_types, 1))];
      v_primary   := v_primaries[1   + ((v_idx * 13) % array_length(v_primaries, 1))];
      v_secondary := v_secondaries[1 + ((v_idx * 13) % array_length(v_secondaries, 1))];
      v_monogram  := upper(substring(v_prefix from 1 for 1) || substring(v_suffix from 1 for 1));

      v_verified := ((v_idx + v_i * 3) % 10) < 3;

      -- Tighter jitter band scheme than PART 2.
      v_band := (v_idx * 7 + v_i * 11) % 100;
      v_scale := case
        when v_band < 50 then 0.003   -- ±3 km
        when v_band < 80 then 0.010   -- ±10 km
        else                  0.020   -- ±20 km
      end;
      v_dir1 := ((v_idx * 13 + v_i)     % 20) - 10;
      v_dir2 := ((v_idx * 19 + v_i * 3) % 20) - 10;
      v_lat  := v_city_lat + v_dir1 * v_scale;
      v_lng  := v_city_lng + v_dir2 * v_scale;

      v_team_id := ('00000000-0000-0000-0000-' || lpad(to_hex(v_idx), 12, '0'))::uuid;

      insert into public.teams
        (team_id, team_name, team_type, logo_monogram, team_colors,
         location, founded_year, owner_id, managers,
         is_verified, privacy, status, max_squad_size)
      values
        (v_team_id,
         v_name,
         v_type::public.team_type,
         v_monogram,
         jsonb_build_object('primary', v_primary, 'secondary', v_secondary),
         jsonb_build_object('city', v_city_name, 'lat', v_lat, 'lng', v_lng, 'country_code', 'PK'),
         2000 + ((v_idx * 3) % 25),
         v_owner,
         '{}'::uuid[],
         v_verified, 'public', 'active', 25)
      on conflict (team_id) do nothing;

      v_count_inserted := v_count_inserted + 1;
      v_idx := v_idx + 1;
    end loop;
  end loop;

  raise notice 'PART 3 satellite fill: % rows attempted (UUIDs 0x200..0x%)',
    v_count_inserted, lpad(to_hex(v_idx - 1), 3, '0');
end $$;

-- Confirm distribution + distance bands. Bucket each team by its great-circle
-- distance from its own city centre so you can see the banded jitter played
-- out per city. City centres come from a CTE (same coordinates as the
-- procedural block) so this is a real distance, not 0.
with centres(city, centre) as (
  values
    ('Lahore',      st_setsrid(st_makepoint(74.3587, 31.5204), 4326)::geography),
    ('Karachi',     st_setsrid(st_makepoint(67.0011, 24.8607), 4326)::geography),
    ('Multan',      st_setsrid(st_makepoint(71.5249, 30.1575), 4326)::geography),
    ('Faisalabad',  st_setsrid(st_makepoint(73.1350, 31.4504), 4326)::geography),
    ('Gujranwala',  st_setsrid(st_makepoint(74.1945, 32.1877), 4326)::geography),
    ('Rawalpindi',  st_setsrid(st_makepoint(73.0169, 33.5651), 4326)::geography),
    ('Islamabad',   st_setsrid(st_makepoint(73.0479, 33.6844), 4326)::geography),
    ('Sialkot',     st_setsrid(st_makepoint(74.5229, 32.4945), 4326)::geography),
    ('Peshawar',    st_setsrid(st_makepoint(71.5249, 34.0151), 4326)::geography),
    ('Sargodha',    st_setsrid(st_makepoint(72.6711, 32.0836), 4326)::geography),
    ('Sahiwal',     st_setsrid(st_makepoint(73.1010, 30.6700), 4326)::geography),
    ('Hyderabad',   st_setsrid(st_makepoint(68.3578, 25.3960), 4326)::geography),
    ('Quetta',      st_setsrid(st_makepoint(66.9750, 30.1798), 4326)::geography),
    ('Bahawalpur',  st_setsrid(st_makepoint(71.6836, 29.3956), 4326)::geography),
    ('Abbottabad',  st_setsrid(st_makepoint(73.2117, 34.1463), 4326)::geography),
    ('Mirpur',      st_setsrid(st_makepoint(73.7517, 33.1478), 4326)::geography),
    ('Mailsi',      st_setsrid(st_makepoint(72.1750, 29.7990), 4326)::geography),
    ('Pakpattan',   st_setsrid(st_makepoint(73.3833, 30.3457), 4326)::geography),
    ('Sheikhupura', st_setsrid(st_makepoint(73.9783, 31.7167), 4326)::geography),
    ('Munjirwali',  st_setsrid(st_makepoint(71.9200, 28.2100), 4326)::geography),
    -- PART 3 satellite towns
    ('Kasur',          st_setsrid(st_makepoint(74.4467, 31.1156), 4326)::geography),
    ('Gujrat',         st_setsrid(st_makepoint(74.0776, 32.5740), 4326)::geography),
    ('Hafizabad',      st_setsrid(st_makepoint(73.6884, 32.0712), 4326)::geography),
    ('Chiniot',        st_setsrid(st_makepoint(72.9783, 31.7204), 4326)::geography),
    ('Toba Tek Singh', st_setsrid(st_makepoint(72.4827, 30.9709), 4326)::geography),
    ('Okara',          st_setsrid(st_makepoint(73.4534, 30.8108), 4326)::geography),
    ('Khanewal',       st_setsrid(st_makepoint(71.9320, 30.3017), 4326)::geography),
    ('Lodhran',        st_setsrid(st_makepoint(71.6325, 29.5454), 4326)::geography),
    ('Jhelum',         st_setsrid(st_makepoint(73.7257, 32.9425), 4326)::geography),
    ('Mardan',         st_setsrid(st_makepoint(72.0404, 34.1986), 4326)::geography),
    ('Sukkur',         st_setsrid(st_makepoint(68.8674, 27.6995), 4326)::geography),
    ('Larkana',        st_setsrid(st_makepoint(68.2127, 27.5586), 4326)::geography),
    ('Mingora',        st_setsrid(st_makepoint(72.3617, 34.7795), 4326)::geography),
    ('Mansehra',       st_setsrid(st_makepoint(73.1968, 34.3309), 4326)::geography),
    ('Murree',         st_setsrid(st_makepoint(73.3943, 33.9070), 4326)::geography),
    ('Wah Cantt',      st_setsrid(st_makepoint(72.7104, 33.7917), 4326)::geography)
)
select
  t.location->>'city'                                                   as city,
  count(*)                                                              as teams,
  sum(case when t.is_verified then 1 else 0 end)                        as verified,
  count(*) filter (where st_distance(t.location_point, c.centre) < 5000) as within_5km,
  count(*) filter (where st_distance(t.location_point, c.centre)
                          between 5000 and 15000)                       as r_5_15km,
  count(*) filter (where st_distance(t.location_point, c.centre) > 15000) as outside_15km
  from public.teams t
  left join centres c on c.city = t.location->>'city'
 where t.team_id >= '00000000-0000-0000-0000-000000000001'::uuid
   and t.team_id <= '00000000-0000-0000-0000-000000000fff'::uuid
 group by t.location->>'city'
 order by teams desc, city;
