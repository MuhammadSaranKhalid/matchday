-- =============================================================================
-- seed_scale_posts_comments.sql — Large scale accounts, posts, comments & likes
-- =============================================================================

do $seed_scale$
declare
  v_saran_uid uuid;
  
  -- Accounts
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


  -- Specific post UUIDs for comment threading
  p1 constant uuid := '20000000-0000-0000-0000-000000000001';
  p2 constant uuid := '20000000-0000-0000-0000-000000000002';
  p3 constant uuid := '20000000-0000-0000-0000-000000000003';
  p4 constant uuid := '20000000-0000-0000-0000-000000000004';
  p5 constant uuid := '20000000-0000-0000-0000-000000000005';
  p6 constant uuid := '20000000-0000-0000-0000-000000000006';
  p7 constant uuid := '20000000-0000-0000-0000-000000000007';
  p8 constant uuid := '20000000-0000-0000-0000-000000000008';
  p9 constant uuid := '20000000-0000-0000-0000-000000000009';
  p10 constant uuid := '20000000-0000-0000-0000-00000000000a';
  p11 constant uuid := '20000000-0000-0000-0000-00000000000b';
  p12 constant uuid := '20000000-0000-0000-0000-00000000000c';
  p13 constant uuid := '20000000-0000-0000-0000-00000000000d';
  p14 constant uuid := '20000000-0000-0000-0000-00000000000e';
  p15 constant uuid := '20000000-0000-0000-0000-00000000000f';

  -- Comment parent IDs
  c1_1 constant uuid := '30000000-0000-0000-0000-000000000001';
  c1_2 constant uuid := '30000000-0000-0000-0000-000000000002';
  c2_1 constant uuid := '30000000-0000-0000-0000-000000000003';
  c3_1 constant uuid := '30000000-0000-0000-0000-000000000004';
  c4_1 constant uuid := '30000000-0000-0000-0000-000000000005';
  c5_1 constant uuid := '30000000-0000-0000-0000-000000000006';

  u record;
begin
  -- Resolve primary user
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;

  -- ---------------------------------------------------------------------------
  -- 1) Create / Upsert Auth Users
  -- ---------------------------------------------------------------------------
  for u in
    select * from (values
      (v_babar,    'babar',    'babar@cricket.pk',    'Babar Azam',       'Cover drive enthusiast · Batter · Lahore',       'Lahore'),
      (v_shaheen,  'shaheen',  'shaheen@cricket.pk',  'Shaheen Afridi',   'Eagle of Lahore · Left-arm Fast Bowler',         'Peshawar'),
      (v_rizwan,   'rizwan',   'rizwan@cricket.pk',   'Mohammad Rizwan',  'Hard work & faith · Wicket-keeper Batter',       'Peshawar'),
      (v_shadab,   'shadab',   'shadab@cricket.pk',   'Shadab Khan',      'Leg spin & fielding · All-Rounder',              'Islamabad'),
      (v_naseem,   'naseem',   'naseem@cricket.pk',   'Naseem Shah',      'Pace & swing · Right-arm Fast',                  'Lower Dir'),
      (v_fakhar,   'fakhar',   'fakhar@cricket.pk',   'Fakhar Zaman',     'Aggressive opening batter · Navy Veteran',       'Mardan'),
      (v_haris,    'haris',    'haris@cricket.pk',    'Haris Rauf',       '150kph Express · Tape ball to International',    'Rawalpindi'),
      (v_iftikhar, 'iftikhar', 'iftikhar@cricket.pk', 'Iftikhar Ahmed',   'Chacha · Power Hitter · Off Spin',               'Peshawar'),
      (v_bilal,    'bilal',    'bilal@local.test',    'Bilal Ahmed',      'Opening bat · Right-arm medium · Karachi CC',    'Karachi'),
      (v_faraz,    'faraz',    'faraz@local.test',    'Faraz Khan',       'All-rounder · Spin wizard · Lahore Lions',       'Lahore'),
      (v_hassan,   'hassan',   'hassan@local.test',   'Hassan Tariq',     'Wicket-keeper & finisher · Rawalpindi',          'Rawalpindi'),
      (v_adeel,    'adeel',    'adeel@local.test',    'Adeel Saeed',      'Middle-order · Right-arm off-spin',              'Faisalabad'),
      (v_karim,    'karim',    'karim@local.test',    'Karim Anwar',      'Left-arm fast bowler · Sialkot Strikers',        'Sialkot'),
      (v_saad,     'saad',     'saad@local.test',     'Saad Iqbal',       'All-rounder · Death overs specialist',           'Multan'),
      (v_zaid,     'zaid',     'zaid@local.test',     'Zaid Malik',       'Switch-hit specialist · Tape ball champion',     'Quetta')
    ) as t(id, username, email, display_name, bio, city)
  loop
    -- Auth User
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      created_at, updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      u.id,
      'authenticated',
      'authenticated',
      u.email,
      '$2a$10$vN0oJ2zD1mY1pY1pY1pYe.G5P2R5P2R5P2R5P2R5P2R5P2R5P2R5P', -- pass1234
      now(),
      jsonb_build_object('username', u.username, 'display_name', u.display_name),
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      '', '', '', '',
      now() - interval '30 days',
      now()
    )
    on conflict (id) do update set
      raw_user_meta_data = excluded.raw_user_meta_data,
      updated_at = now();


    -- Identity
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
    )
    values (
      gen_random_uuid(),
      u.id,
      jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
      'email',
      u.id::text,
      now(),
      now() - interval '30 days',
      now()
    )
    on conflict (provider, provider_id) do nothing;

    -- Profile
    insert into public.profiles (
      user_id, username, display_name, bio, location,
      is_verified, account_status, onboarded_at, created_at, updated_at
    )
    values (
      u.id,
      u.username,
      u.display_name,
      u.bio,
      jsonb_build_object('country', 'Pakistan', 'city', u.city),
      true,
      'active',
      now() - interval '30 days',
      now() - interval '30 days',
      now()
    )
    on conflict (user_id) do update set
      username = excluded.username,
      display_name = excluded.display_name,
      bio = excluded.bio,
      location = excluded.location,
      onboarded_at = excluded.onboarded_at,
      updated_at = now();

    -- Player Profile
    insert into public.player_profiles (
      user_id, batting_style, bowling_style, player_role, preferred_ball_types, years_playing
    )
    values (
      u.id,
      'right_hand',
      'right_arm_medium',
      'all_rounder',
      '{leather,tape}',
      6
    )
    on conflict (user_id) do nothing;
  end loop;

  -- ---------------------------------------------------------------------------
  -- 2) Create Diverse Posts across Accounts
  -- ---------------------------------------------------------------------------
  insert into public.posts (
    post_id, author_id, author_context, post_type, text, media_urls, media, created_at
  )
  values
    -- Post 1: Babar Azam - Match Celebration
    (
      p1, v_babar, 'personal', 'photo',
      'Great win tonight under the lights! Outstanding team effort and energy. Big shoutout to @shaheen for setting the tone early and @saran for the vital support in the middle overs. Onto the next match! 🏏🔥',
      '{https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L8BDi-00?w~qofoffQfQ00%M%Mj["}]'::jsonb,
      now() - interval '2 hours'
    ),
    -- Post 2: Shaheen Afridi - Fast bowling rhythm
    (
      p2, v_shaheen, 'personal', 'photo',
      'First over rhythm feeling crisp and fast. Always a blessing to play with this brotherhood. @naseem and @haris bowling fire at the other end! 🦅💨',
      '{https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LEHLk[WB2yk8pyoJadR*.7kCMdnj"}]'::jsonb,
      now() - interval '5 hours'
    ),
    -- Post 3: Mohammad Rizwan - Training & gratitude
    (
      p3, v_rizwan, 'personal', 'text',
      'Always focus on the process. Hard work in the nets never goes to waste. Alhamdulillah for every opportunity to step on the field! Reminding everyone: tape ball trials start this Friday. Reach out to @shadab or @bilal for registration.',
      '{}',
      '[]'::jsonb,
      now() - interval '9 hours'
    ),
    -- Post 4: Shadab Khan - Multi-photo all-round action
    (
      p4, v_shadab, 'personal', 'photo',
      'Matchday vibes! Leg spin feeling good in the middle. Special thanks to the home crowd for turning up in huge numbers! Check out some moments from the game 📸 @babar @fakhar',
      '{https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80,https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L6PZfS_2.8oJt7WBV@of00IUt7of"}, {"url": "https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LGF5]+Yk^6#M@-5c,1J5@[or[Q6."}]'::jsonb,
      now() - interval '14 hours'
    ),
    -- Post 5: Haris Rauf - 150kph Yorker session
    (
      p5, v_haris, 'personal', 'photo',
      'Pace is pace yaar! ⚡ Bowling yorkers under the lights never gets old. What a match against Lahore Lions. Kudos to @saran for holding the fort.',
      '{https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1512719994953-eabf50895df7?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LIAn^0~q%M%M~qofofof_3%M%M%M"}]'::jsonb,
      now() - interval '1 day'
    ),
    -- Post 6: Fakhar Zaman - Century celebration
    (
      p6, v_fakhar, 'personal', 'text',
      'Unbelievable atmosphere today! Going big from ball one is the only way to play. Congratulations to @iftikhar for that blistering finish in the death overs. 🚀',
      '{}',
      '[]'::jsonb,
      now() - interval '1 day 4 hours'
    ),
    -- Post 7: Naseem Shah - Youth energy & swing
    (
      p7, v_naseem, 'personal', 'photo',
      'New ball swinging both ways today! Grateful to learn every single day from @shaheen and @haris. See you all at the stadium on Sunday! 🇵🇰',
      '{https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L99~s0x^?woe?bofWBof00ay_3ay"}]'::jsonb,
      now() - interval '1 day 10 hours'
    ),
    -- Post 8: Iftikhar Ahmed - Power hitting
    (
      p8, v_iftikhar, 'personal', 'text',
      'When the captain says clear the ropes, you clear the ropes! Great team spirit today. @rizwan kept us calm during the chase. 💥',
      '{}',
      '[]'::jsonb,
      now() - interval '2 days'
    ),
    -- Post 9: Bilal Ahmed - Recruitment Announcement
    (
      p9, v_bilal, 'personal', 'photo',
      '📢 RECRUITMENT CALL: Karachi CC is looking for 2 top-order batsmen and 1 wicket-keeper for the upcoming Karachi Premier League! Open trials this Sunday 4 PM at Asghar Ali Stadium. Tag your friends below! @faraz @adeel @hassan',
      '{https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "L8BDi-00?w~qofoffQfQ00%M%Mj["}]'::jsonb,
      now() - interval '2 days 6 hours'
    ),
    -- Post 10: Faraz Khan - Tournament Update
    (
      p10, v_faraz, 'personal', 'text',
      'Semi-finals confirmed for Lahore Lions! Big clash coming up against Karachi Knights on Friday. @saran is leading the boys with full intensity. Let us bring the trophy home! 🏆',
      '{}',
      '[]'::jsonb,
      now() - interval '3 days'
    ),
    -- Post 11: Adeel Saeed - Tape Ball Derby
    (
      p11, v_adeel, 'personal', 'photo',
      'Tape ball cricket under floodlights hits different! 24 runs required in the last over and we got over the line. What a night! 🏏✨ @zaid @karim',
      '{https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80}',
      '[{"url": "https://images.unsplash.com/photo-1531415074868-036b1c5d53ec?auto=format&fit=crop&w=1200&q=80", "width": 1200, "height": 800, "blurhash": "LEHLk[WB2yk8pyoJadR*.7kCMdnj"}]'::jsonb,
      now() - interval '3 days 12 hours'
    ),
    -- Post 12: Zaid Malik - Match Analysis
    (
      p12, v_zaid, 'personal', 'text',
      'Pitch was gripping and turning from ball one. Credit to @faraz and @shadab for reading the surface quickly. Perfect bowling execution.',
      '{}',
      '[]'::jsonb,
      now() - interval '4 days'
    )
  on conflict (post_id) do update set
    text = excluded.text,
    media = excluded.media,
    media_urls = excluded.media_urls,
    created_at = excluded.created_at;

  -- ---------------------------------------------------------------------------
  -- 3) Create Threaded Comments & Replies with Mentions
  -- ---------------------------------------------------------------------------
  -- On Post 1 (Babar Azam's post)
  insert into public.comments (comment_id, post_id, author_id, parent_comment_id, text, mentioned_user_ids, created_at)
  values
    (c1_1, p1, v_shaheen, null, 'Top batting skipper! That partnership with @saran changed the game completely 🔥', array[v_saran_uid], now() - interval '1 hour 45 mins'),
    (c1_2, p1, v_rizwan, null, 'MashAllah brother! Always leading from the front. @babar @shaheen brilliant effort!', array[v_babar, v_shaheen], now() - interval '1 hour 30 mins'),
    -- Replies to c1_1
    (gen_random_uuid(), p1, v_babar, c1_1, '@shaheen You set the standard in that first spell brother! Keep roaring 🦅', array[v_shaheen], now() - interval '1 hour 20 mins'),
    (gen_random_uuid(), p1, v_shadab, c1_1, '@shaheen @babar Can not wait for the next derby match in Lahore! 😍', array[v_shaheen, v_babar], now() - interval '1 hour'),
    (gen_random_uuid(), p1, v_bilal, c1_1, 'Class act as always. Big inspiration for us club cricketers @babar 👏', array[v_babar], now() - interval '45 mins'),

    -- On Post 2 (Shaheen's post)
    (c2_1, p2, v_naseem, null, 'Eagle flying high! @shaheen best fast bowler in the world hands down! 🦅💨', array[v_shaheen], now() - interval '4 hours 30 mins'),
    (gen_random_uuid(), p2, v_haris, c2_1, '@naseem 150kph duo ready to strike again! Watch out batsmen 🔥', array[v_naseem], now() - interval '4 hours'),
    (gen_random_uuid(), p2, v_fakhar, null, 'Glad I only have to face you in the nets @shaheen 😂 Good luck to opponents!', array[v_shaheen], now() - interval '3 hours 30 mins'),

    -- On Post 3 (Rizwan's post)
    (c3_1, p3, v_iftikhar, null, 'Pure dedication @rizwan Bhai! Inspirational message for all the young players.', array[v_rizwan], now() - interval '8 hours'),
    (gen_random_uuid(), p3, v_shadab, c3_1, '@iftikhar Agree 100%! The energy Rizwan Bhai brings on the field is unmatched 🙌', array[v_iftikhar], now() - interval '7 hours 30 mins'),
    (gen_random_uuid(), p3, v_adeel, null, 'Where can we register for the trials? @shadab please share details!', array[v_shadab], now() - interval '6 hours'),

    -- On Post 4 (Shadab's post)
    (c4_1, p4, v_fakhar, null, 'Those googlies were unplayable today Shaddy! @shadab 🎯', array[v_shadab], now() - interval '13 hours'),
    (gen_random_uuid(), p4, v_shadab, c4_1, '@fakhar Thanks Lala! Saving a special one for your team next week 😉', array[v_fakhar], now() - interval '12 hours'),
    (gen_random_uuid(), p4, v_faraz, null, 'Great drift and flight in the middle overs. Top class!', array[]::uuid[], now() - interval '11 hours'),

    -- On Post 5 (Haris Rauf's post)
    (c5_1, p5, v_babar, null, 'Express pace Haris! That yorker in the 18th over was pure lethal @haris ⚡', array[v_haris], now() - interval '22 hours'),
    (gen_random_uuid(), p5, v_haris, c5_1, '@babar Thank you Kaptaan! Always ready to give 100% for the team.', array[v_babar], now() - interval '21 hours'),
    (gen_random_uuid(), p5, v_zaid, null, 'Tape ball roots showing in every yorker! Rawalpindi power 💥', array[]::uuid[], now() - interval '20 hours'),

    -- On Post 9 (Recruitment post)
    (gen_random_uuid(), p9, v_faraz, null, 'I know a couple of talented fast bowlers from Model Town CC. Sending them your way @bilal!', array[v_bilal], now() - interval '2 days 4 hours'),
    (gen_random_uuid(), p9, v_hassan, null, 'I will be there for trials! @bilal is leather ball experience mandatory?', array[v_bilal], now() - interval '2 days 2 hours'),
    (gen_random_uuid(), p9, v_bilal, null, '@hassan Open to both tape and leather ball players! Come showcase your skills.', array[v_hassan], now() - interval '2 days')
  on conflict (comment_id) do nothing;

  -- ---------------------------------------------------------------------------
  -- 4) Likes on Posts
  -- ---------------------------------------------------------------------------
  insert into public.post_likes (post_id, user_id, created_at)
  values
    (p1, v_shaheen, now() - interval '1 hour 50 mins'),
    (p1, v_rizwan, now() - interval '1 hour 40 mins'),
    (p1, v_shadab, now() - interval '1 hour 30 mins'),
    (p1, v_naseem, now() - interval '1 hour 20 mins'),
    (p1, v_haris, now() - interval '1 hour'),
    (p1, v_bilal, now() - interval '50 mins'),
    (p1, v_faraz, now() - interval '40 mins'),
    (p2, v_babar, now() - interval '4 hours 50 mins'),
    (p2, v_naseem, now() - interval '4 hours 40 mins'),
    (p2, v_haris, now() - interval '4 hours 30 mins'),
    (p2, v_shadab, now() - interval '4 hours'),
    (p3, v_babar, now() - interval '8 hours 30 mins'),
    (p3, v_iftikhar, now() - interval '8 hours'),
    (p3, v_fakhar, now() - interval '7 hours'),
    (p4, v_fakhar, now() - interval '13 hours 30 mins'),
    (p4, v_babar, now() - interval '13 hours'),
    (p4, v_shaheen, now() - interval '12 hours'),
    (p5, v_babar, now() - interval '23 hours'),
    (p5, v_shaheen, now() - interval '22 hours'),
    (p9, v_faraz, now() - interval '2 days 5 hours'),
    (p9, v_hassan, now() - interval '2 days 3 hours')
  on conflict (post_id, user_id) do nothing;

  -- ---------------------------------------------------------------------------
  -- 5) Likes on Comments
  -- ---------------------------------------------------------------------------
  insert into public.comment_likes (comment_id, user_id, created_at)
  values
    (c1_1, v_babar, now() - interval '1 hour 35 mins'),
    (c1_1, v_rizwan, now() - interval '1 hour 30 mins'),
    (c1_1, v_shadab, now() - interval '1 hour 25 mins'),
    (c1_2, v_babar, now() - interval '1 hour 20 mins'),
    (c1_2, v_shaheen, now() - interval '1 hour 15 mins'),
    (c2_1, v_shaheen, now() - interval '4 hours 20 mins'),
    (c2_1, v_haris, now() - interval '4 hours 10 mins'),
    (c3_1, v_rizwan, now() - interval '7 hours 50 mins'),
    (c4_1, v_shadab, now() - interval '12 hours 40 mins'),
    (c5_1, v_haris, now() - interval '21 hours 30 mins')
  on conflict (comment_id, user_id) do nothing;

  -- ---------------------------------------------------------------------------
  -- 6) Bookmarks on Posts
  -- ---------------------------------------------------------------------------
  if v_saran_uid is not null then
    insert into public.bookmarks (user_id, post_id, created_at)
    values
      (v_saran_uid, p1, now() - interval '1 hour'),
      (v_saran_uid, p4, now() - interval '12 hours'),
      (v_saran_uid, p9, now() - interval '2 days')
    on conflict (user_id, post_id) do nothing;
  end if;

  -- ---------------------------------------------------------------------------
  -- 7) Follows between Players
  -- ---------------------------------------------------------------------------
  insert into public.follows (follower_id, target_type, target_id, status, created_at)
  values
    (v_babar, 'user', v_shaheen, 'active', now() - interval '20 days'),
    (v_babar, 'user', v_rizwan, 'active', now() - interval '20 days'),
    (v_babar, 'user', v_shadab, 'active', now() - interval '20 days'),
    (v_shaheen, 'user', v_babar, 'active', now() - interval '20 days'),
    (v_shaheen, 'user', v_naseem, 'active', now() - interval '20 days'),
    (v_shaheen, 'user', v_haris, 'active', now() - interval '20 days'),
    (v_rizwan, 'user', v_babar, 'active', now() - interval '20 days'),
    (v_rizwan, 'user', v_shadab, 'active', now() - interval '20 days'),
    (v_shadab, 'user', v_babar, 'active', now() - interval '20 days'),
    (v_shadab, 'user', v_shaheen, 'active', now() - interval '20 days'),
    (v_naseem, 'user', v_shaheen, 'active', now() - interval '20 days'),
    (v_haris, 'user', v_shaheen, 'active', now() - interval '20 days'),
    (v_haris, 'user', v_babar, 'active', now() - interval '20 days'),
    (v_fakhar, 'user', v_babar, 'active', now() - interval '20 days'),
    (v_iftikhar, 'user', v_rizwan, 'active', now() - interval '20 days'),
    (v_bilal, 'user', v_faraz, 'active', now() - interval '20 days'),
    (v_faraz, 'user', v_bilal, 'active', now() - interval '20 days'),
    (v_adeel, 'user', v_hassan, 'active', now() - interval '20 days')
  on conflict (follower_id, target_type, target_id) do nothing;

  if v_saran_uid is not null then
    insert into public.follows (follower_id, target_type, target_id, status, created_at)
    values
      (v_saran_uid, 'user', v_babar, 'active', now() - interval '10 days'),
      (v_saran_uid, 'user', v_shaheen, 'active', now() - interval '10 days'),
      (v_saran_uid, 'user', v_rizwan, 'active', now() - interval '10 days'),
      (v_saran_uid, 'user', v_shadab, 'active', now() - interval '10 days'),
      (v_babar, 'user', v_saran_uid, 'active', now() - interval '10 days'),
      (v_shaheen, 'user', v_saran_uid, 'active', now() - interval '10 days'),
      (v_shadab, 'user', v_saran_uid, 'active', now() - interval '10 days')
    on conflict (follower_id, target_type, target_id) do nothing;
  end if;

  -- ---------------------------------------------------------------------------
  -- 8) Synchronize counter columns (comments_count & likes_count)
  -- ---------------------------------------------------------------------------
  update public.posts p
     set comments_count = (select count(*) from public.comments c where c.post_id = p.post_id and c.status = 'active'),
         likes_count = (select count(*) from public.post_likes pl where pl.post_id = p.post_id);

  update public.comments c
     set likes_count = (select count(*) from public.comment_likes cl where cl.comment_id = c.comment_id);

  raise notice 'Successfully seeded large-scale accounts, posts, comments, likes and follows!';
end $seed_scale$;
