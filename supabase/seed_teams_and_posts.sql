-- =============================================================================
-- seed_teams_and_posts.sql — Comprehensive Seed Script for Teams, Rosters & Team Posts
-- =============================================================================
-- This script creates a rich ecosystem of cricket teams, diverse team rosters,
-- and extensive team-authored announcements, match updates, recruitment calls,
-- and photo posts for thorough local/staging UI testing.
-- =============================================================================

do $seed_teams_and_posts$
declare
  v_saran_uid uuid;

  -- Player User IDs
  v_babar    constant uuid := '00000000-0000-0000-0000-000000000010';
  v_shaheen  constant uuid := '00000000-0000-0000-0000-000000000011';
  v_rizwan   constant uuid := '00000000-0000-0000-0000-000000000012';
  v_shadab   constant uuid := '00000000-0000-0000-0000-000000000013';
  v_naseem   constant uuid := '00000000-0000-0000-0000-000000000014';
  v_fakhar   constant uuid := '00000000-0000-0000-0000-000000000015';
  v_haris    constant uuid := '00000000-0000-0000-0000-000000000016';
  v_iftikhar constant uuid := '00000000-0000-0000-0000-000000000017';
  v_bilal    constant uuid := '00000000-0000-0000-0000-000000000002';
  v_faraz    constant uuid := '00000000-0000-0000-0000-000000000003';
  v_hassan   constant uuid := '00000000-0000-0000-0000-000000000004';
  v_adeel    constant uuid := '00000000-0000-0000-0000-000000000005';
  v_karim    constant uuid := '00000000-0000-0000-0000-000000000006';
  v_saad     constant uuid := '00000000-0000-0000-0000-000000000007';
  v_zaid     constant uuid := '0000000a-0000-0000-0000-00000000000a';

  -- Team IDs (Pinned UUIDs)
  t_lahore_lions     constant uuid := '11111111-1111-1111-1111-111111111101';
  t_isb_united       constant uuid := '11111111-1111-1111-1111-111111111102';
  t_karachi_eagles   constant uuid := '11111111-1111-1111-1111-111111111103';
  t_karachi_knights  constant uuid := '11111111-1111-1111-1111-111111111104';
  t_multan_sultans   constant uuid := '11111111-1111-1111-1111-111111111105';
  t_quetta_gladiators constant uuid := '11111111-1111-1111-1111-111111111108';
  t_sialkot_stallions constant uuid := '11111111-1111-1111-1111-111111111109';
  t_peshawar_tigers  constant uuid := '1111111b-1111-1111-1111-11111111110b';
  t_rawalpindi_rams  constant uuid := '1111111d-1111-1111-1111-11111111110d';
  t_hyd_hawks        constant uuid := '1111111e-1111-1111-1111-11111111110e';

begin
  -- 1) Resolve Primary User ("me")
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;
  if v_saran_uid is null then
    v_saran_uid := '00000000-0000-0000-0000-000000000001'::uuid;
  end if;

  -- 2) Upsert Teams
  insert into public.teams (
    team_id, owner_id, team_name, team_type, privacy, tagline, team_colors,
    logo_monogram, logo_url, location, home_ground, founded_year, created_at
  )
  values
    (
      t_lahore_lions, v_saran_uid, 'Lahore Lions', 'club', 'public',
      'Roar of Lahore · Champions of the Super League',
      '{"primary":"#DC4D32","secondary":"#26221B"}'::jsonb,
      'LL',
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=400&q=80',
      '{"city":"Lahore","country":"Pakistan"}'::jsonb,
      'Model Town Sports Complex', 2018, now() - interval '180 days'
    ),
    (
      t_isb_united, v_saran_uid, 'Islamabad United', 'club', 'public',
      'Red Hot · Two-time Premier Cup Winners',
      '{"primary":"#1E40AF","secondary":"#FFFFFF"}'::jsonb,
      'IU',
      'https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=400&q=80',
      '{"city":"Islamabad","country":"Pakistan"}'::jsonb,
      'F-9 Diamond Cricket Ground', 2020, now() - interval '150 days'
    ),
    (
      t_hyd_hawks, v_saran_uid, 'Hyderabad Hawks', 'casual', 'public',
      'Soaring High in Sindh Cricket League',
      '{"primary":"#0EA5E9","secondary":"#F0F9FF"}'::jsonb,
      'HH',
      'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=400&q=80',
      '{"city":"Hyderabad","country":"Pakistan"}'::jsonb,
      'Niaz Stadium Hyderabad', 2023, now() - interval '90 days'
    ),
    (
      t_karachi_eagles, v_bilal, 'Karachi Eagles', 'club', 'public',
      'Defenders of the Coastal Fortress',
      '{"primary":"#15803D","secondary":"#FAF8E8"}'::jsonb,
      'KE',
      'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=400&q=80',
      '{"city":"Karachi","country":"Pakistan"}'::jsonb,
      'KGA Ground', 2017, now() - interval '210 days'
    ),
    (
      t_karachi_knights, v_bilal, 'Karachi Knights', 'casual', 'public',
      'Night Cricket Specialists of Defence',
      '{"primary":"#7C2D12","secondary":"#FED7AA"}'::jsonb,
      'KK',
      'https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=400&q=80',
      '{"city":"Karachi","country":"Pakistan"}'::jsonb,
      'Defence Cricket Stadium', 2021, now() - interval '120 days'
    ),
    (
      t_multan_sultans, v_faraz, 'Multan Sultans', 'club', 'public',
      'Pride of Southern Punjab',
      '{"primary":"#B45309","secondary":"#FFFFFF"}'::jsonb,
      'MS',
      'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=400&q=80',
      '{"city":"Multan","country":"Pakistan"}'::jsonb,
      'Multan Cricket Stadium', 2019, now() - interval '200 days'
    ),
    (
      t_quetta_gladiators, v_hassan, 'Quetta Gladiators', 'corporate', 'public',
      'Shaan e Pakistan · Valour & Honor',
      '{"primary":"#0F766E","secondary":"#F0FDFA"}'::jsonb,
      'QG',
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=400&q=80',
      '{"city":"Quetta","country":"Pakistan"}'::jsonb,
      'Ayub Stadium Quetta', 2016, now() - interval '240 days'
    ),
    (
      t_sialkot_stallions, v_adeel, 'Sialkot Stallions', 'club', 'public',
      'Unstoppable T20 Legacy & Power',
      '{"primary":"#E11D48","secondary":"#FFE4E6"}'::jsonb,
      'SS',
      'https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=400&q=80',
      '{"city":"Sialkot","country":"Pakistan"}'::jsonb,
      'Jinnah Stadium Sialkot', 2019, now() - interval '190 days'
    ),
    (
      t_peshawar_tigers, v_karim, 'Peshawar Tigers', 'club', 'public',
      'Fierce & Fearless · Khyber Warriors',
      '{"primary":"#F59E0B","secondary":"#26221B"}'::jsonb,
      'PT',
      'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=400&q=80',
      '{"city":"Peshawar","country":"Pakistan"}'::jsonb,
      'Arbab Niaz Stadium', 2018, now() - interval '220 days'
    ),
    (
      t_rawalpindi_rams, v_saad, 'Rawalpindi Rams', 'corporate', 'public',
      'Speed, Power & Precision from Pindi',
      '{"primary":"#7C3AED","secondary":"#FAFAF9"}'::jsonb,
      'RR',
      'https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=400&q=80',
      '{"city":"Rawalpindi","country":"Pakistan"}'::jsonb,
      'Rawalpindi Cricket Stadium', 2017, now() - interval '230 days'
    )
  on conflict (team_id) do update set
    team_name     = excluded.team_name,
    tagline       = excluded.tagline,
    team_colors   = excluded.team_colors,
    logo_monogram = excluded.logo_monogram,
    logo_url      = excluded.logo_url,
    location      = excluded.location,
    home_ground   = excluded.home_ground,
    updated_at    = now();

  -- 3) Clean up existing memberships for these teams and re-insert
  delete from public.team_members
  where team_id in (t_lahore_lions, t_isb_united, t_karachi_eagles, t_hyd_hawks, t_multan_sultans, t_quetta_gladiators, t_sialkot_stallions, t_peshawar_tigers, t_rawalpindi_rams);

  -- Lahore Lions Squad
  insert into public.team_members (team_id, user_id, role, jersey_number, added_by)
  values
    (t_lahore_lions, v_saran_uid, 'captain', 7, v_saran_uid),
    (t_lahore_lions, v_babar,      'vice_captain', 56, v_saran_uid),
    (t_lahore_lions, v_shaheen,    'player', 10, v_saran_uid),
    (t_lahore_lions, v_haris,      'player', 99, v_saran_uid),
    (t_lahore_lions, v_faraz,      'player', 21, v_saran_uid);

  -- Islamabad United Squad
  insert into public.team_members (team_id, user_id, role, jersey_number, added_by)
  values
    (t_isb_united, v_saran_uid, 'captain', 7, v_saran_uid),
    (t_isb_united, v_shadab,    'vice_captain', 77, v_saran_uid),
    (t_isb_united, v_naseem,    'player', 71, v_saran_uid),
    (t_isb_united, v_hassan,    'wicket_keeper', 9, v_saran_uid);

  -- Karachi Eagles Squad
  insert into public.team_members (team_id, user_id, role, jersey_number, added_by)
  values
    (t_karachi_eagles, v_bilal,   'captain', 1, v_bilal),
    (t_karachi_eagles, v_rizwan,  'vice_captain', 16, v_bilal),
    (t_karachi_eagles, v_fakhar,  'player', 39, v_bilal),
    (t_karachi_eagles, v_adeel,   'player', 18, v_bilal);

  -- 4) Clear & Re-seed Rich Team-Authored Posts & Announcements
  delete from public.posts where author_context = 'team_manager' or linked_team_id is not null;

  insert into public.posts (
    post_id, author_id, author_context, context_entity_id, linked_team_id,
    post_type, text, media_urls, media, likes_count, comments_count, created_at
  )
  values
    -- ── Lahore Lions Posts ──────────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-000000000001',
      v_saran_uid, 'team_manager', t_lahore_lions, t_lahore_lions,
      'match_announcement',
      '🚨 MATCHDAY ANNOUNCEMENT: Lahore Lions vs Karachi Eagles! 🦁 vs 🦅\n\nSemi-Final 1 of the Super City Cup will take place this Saturday at 4:00 PM at Model Town Sports Complex. Full playing XI locked in. Free entry for all supporters!',
      '{https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L8BDi-00?w~qofoffQfQ00%M%Mj["}]'::jsonb,
      38, 12, now() - interval '2 hours'
    ),
    (
      '21000000-0000-0000-0000-000000000002',
      v_saran_uid, 'team_manager', t_lahore_lions, t_lahore_lions,
      'photo',
      'Hard training session under the lights ahead of the big weekend clash! The fast bowling battery (@shaheen & @haris) is firing at 100% intensity. Swipe through the gallery 📸⚡',
      '{https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80,https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LEHLk[WB2yk8pyoJadR*.7kCMdnj"}, {"url": "https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L6PZfS_2.8oJt7WBV@of00IUt7of"}]'::jsonb,
      54, 9, now() - interval '1 day'
    ),
    (
      '21000000-0000-0000-0000-000000000003',
      v_saran_uid, 'team_manager', t_lahore_lions, t_lahore_lions,
      'recruitment',
      '📢 SQUAD TRIALS & RECRUITMENT:\nLahore Lions is conducting open trials for Top-Order Batsmen and Left-Arm Orthodox Spinners for the upcoming T20 League season.\n\nDate: Next Tuesday, 3:30 PM\nVenue: Model Town Net 3\nBring your own white kit & spikes.',
      '{}', '[]'::jsonb,
      27, 15, now() - interval '2 days'
    ),
    (
      '21000000-0000-0000-0000-000000000004',
      v_saran_uid, 'team_manager', t_lahore_lions, t_lahore_lions,
      'text',
      'Victorious in the quarter-finals against Multan Sultans! Special congratulations to @babar for his commanding 74* and @faraz for 3 vital wickets in the middle phase. Semi-finals next!',
      '{}', '[]'::jsonb,
      42, 6, now() - interval '3 days'
    ),

    -- ── Islamabad United Posts ──────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-000000000005',
      v_saran_uid, 'team_manager', t_isb_united, t_isb_united,
      'match_announcement',
      '🔥 DERBY CLASH: Islamabad United vs Rawalpindi Rams!\nThe Twin-Cities Derby is set for Sunday night at Islamabad Sports Complex. Both teams are undefeated this season. Expect fireworks! 🚀',
      '{https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LGF5]+Yk^6#M@-5c,1J5@[or[Q6."}]'::jsonb,
      61, 18, now() - interval '5 hours'
    ),
    (
      '21000000-0000-0000-0000-000000000006',
      v_saran_uid, 'team_manager', t_isb_united, t_isb_united,
      'photo',
      'Team fielding drills at Diamond Ground. High catches, direct hits, and boundary-stopping practice. Commitment level is unmatched! @shadab leading the charge 🔴⚪',
      '{https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L99~s0x^?woe?bofWBof00ay_3ay"}]'::jsonb,
      33, 4, now() - interval '2 days'
    ),

    -- ── Karachi Eagles Posts ────────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-000000000007',
      v_bilal, 'team_manager', t_karachi_eagles, t_karachi_eagles,
      'match_announcement',
      '🦅 Eagles Take Flight! Karachi Eagles have qualified for the Grand Finals of the Coastal Premier League after a thrilling 3-run victory over Karachi Knights! Full scorecard on matchday app.',
      '{https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LIAn^0~q%M%M~qofofof_3%M%M%M"}]'::jsonb,
      89, 24, now() - interval '4 hours'
    ),
    (
      '21000000-0000-0000-0000-000000000008',
      v_bilal, 'team_manager', t_karachi_eagles, t_karachi_eagles,
      'recruitment',
      'Looking for 1 Fast-Bowling All-rounder for the upcoming National Tape-Ball Championship in Karachi. Contact manager @bilal or DM us on Matchday.',
      '{}', '[]'::jsonb,
      19, 7, now() - interval '3 days'
    ),

    -- ── Quetta Gladiators Posts ─────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-000000000009',
      v_hassan, 'team_manager', t_quetta_gladiators, t_quetta_gladiators,
      'tournament_update',
      'Quetta Gladiators are proud to announce the 2026 Ayub Stadium Invitational Tournament! 16 registered corporate and club sides will battle across 2 weeks in Quetta.',
      '{https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L8BDi-00?w~qofoffQfQ00%M%Mj["}]'::jsonb,
      45, 11, now() - interval '1 day 6 hours'
    ),

    -- ── Multan Sultans Posts ────────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-00000000000a',
      v_faraz, 'team_manager', t_multan_sultans, t_multan_sultans,
      'photo',
      'Victory celebration in the dressing room after chasing down 185! Pure team commitment and resilience. Multan, this win is for you! 🏆💛',
      '{https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L6PZfS_2.8oJt7WBV@of00IUt7of"}]'::jsonb,
      72, 19, now() - interval '18 hours'
    ),

    -- ── Sialkot Stallions Posts ─────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-00000000000b',
      v_adeel, 'team_manager', t_sialkot_stallions, t_sialkot_stallions,
      'text',
      'Official practice matches schedule released for Sialkot Stallions. First game on Friday against Faisalabad Falcons. Spectators welcome at Jinnah Stadium.',
      '{}', '[]'::jsonb,
      28, 5, now() - interval '2 days 12 hours'
    ),

    -- ── Peshawar Tigers Posts ───────────────────────────────────────────────
    (
      '21000000-0000-0000-0000-00000000000c',
      v_karim, 'team_manager', t_peshawar_tigers, t_peshawar_tigers,
      'photo',
      'The speed machine in full flow at Arbab Niaz Stadium nets! Getting ready for the weekend double-header. 🐅⚡',
      '{https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LEHLk[WB2yk8pyoJadR*.7kCMdnj"}]'::jsonb,
      39, 8, now() - interval '1 day 18 hours'
    );

end $seed_teams_and_posts$;
