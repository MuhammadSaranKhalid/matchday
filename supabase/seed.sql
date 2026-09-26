-- =============================================================================
-- seed.sql — chats/messages test data anchored to YOUR existing account
-- =============================================================================
-- YOUR account (`muhammadsarankhalid@gmail.com`) is resolved at runtime and
-- becomes the "me" user — owner of some teams, member of many chats, sender
-- of some messages. The other 9 users are seeded as cricket-themed
-- teammates so you have someone to chat with.
--
-- Safe to run against:
--   • Your production Supabase project — your account already exists.
--   • Local Supabase (after you sign up muhammadsarankhalid@gmail.com locally
--     first; this file does NOT create your account).
--
-- The seed FAILS LOUDLY if your account is not found, so it can't silently
-- run against the wrong project.
--
-- What you get:
--   • 9 fake teammates: Bilal Ahmed, Faraz Khan, Hassan Tariq, Adeel Saeed,
--     Karim Anwar, Saad Iqbal, Usman Ali, Yousaf Khan, Zaid Malik.
--     Credentials: `<firstname>@local.test` / `pass1234`.
--   • 15 teams: you own 3 (Lahore Lions, Islamabad United, Hyderabad Hawks);
--     teammates own 12.
--   • You're a member of 5 other team chats → 8 chats total in your inbox.
--   • Lahore Lions: a hand-curated 30-message coordination thread where YOU
--     are the captain doing the coordinating. Your own messages are
--     attributed to you (sender_id = your uid).
--   • Karachi Eagles: 250-message pagination/perf stress thread.
--   • Hyderabad Hawks: zero messages (empty-thread state, owner-only chat).
--   • Other chats you're in: 30–100 randomised messages each.
--
-- Cleanup later (production safety): everything seeded here is tagged via
-- emails ending in `@local.test`. To remove:
--   delete from auth.users where email like '%@local.test';
--   -- cascade deletes profiles + team_members → triggers clean up chats
--   delete from public.teams where team_id in (
--     '11111111-1111-1111-1111-111111111101', ...  -- all 15 pinned ids
--   );
-- (See full delete script at the bottom of this file.)
-- =============================================================================

SET search_path = public, extensions;

-- =============================================================================
-- 0) Resolve "me" — fail loudly if your account isn't here
-- =============================================================================

do $$
declare
  v_me uuid;
begin
  select id into v_me
    from auth.users
   where email = 'muhammadsarankhalid@gmail.com';
  if v_me is null then
    v_me := '00000000-0000-0000-0000-000000000001'::uuid;
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      reauthentication_token, phone_change, phone_change_token,
      created_at, updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      v_me, 'authenticated', 'authenticated', 'muhammadsarankhalid@gmail.com',
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', 'Muhammad Saran'),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '',
      '', '', '',
      now(), now()
    )
    on conflict (id) do nothing;

    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    )
    values (
      gen_random_uuid(),
      v_me,
      jsonb_build_object(
        'sub', v_me::text,
        'email', 'muhammadsarankhalid@gmail.com',
        'email_verified', true
      ),
      'email',
      v_me::text,
      now(), now(), now()
    )
    on conflict do nothing;

    insert into public.profiles (
      user_id, username, display_name, bio,
      created_at, updated_at, onboarded_at, last_active_at
    )
    values (
      v_me, 'saran', 'Muhammad Saran', 'Cricket enthusiast & captain.',
      now(), now(), now(), now()
    )
    on conflict (user_id) do update set
      username = excluded.username,
      display_name = excluded.display_name;

  end if;
  raise notice 'Seeding for user: %', v_me;
end $$;


-- Note: the dashboard SQL editor and `psql` autocommit each statement, which
-- would drop a `temp table … on commit drop` between blocks. Instead, every
-- subsequent block that needs your uid resolves it inline via the same
-- SELECT. If you ever change the seed account, find-and-replace
-- `muhammadsarankhalid@gmail.com` in all four blocks below.

-- =============================================================================
-- 1) Teammates — 9 fake users (auth.users + auth.identities + profiles)
-- =============================================================================
-- Direct INSERT into auth.users bypasses the signup flow. Acceptable here
-- because every seeded teammate has an `@local.test` email — easy to filter
-- out and delete later.
-- =============================================================================

do $seed_teammates$
declare
  v record;
begin
  for v in
    select * from (values
      ('00000000-0000-0000-0000-000000000002'::uuid, 'bilal',  'bilal@local.test',  'Bilal Ahmed',   'Opening bat. Right-arm medium.'),
      ('00000000-0000-0000-0000-000000000003'::uuid, 'faraz',  'faraz@local.test',  'Faraz Khan',    'All-rounder. Loves spin.'),
      ('00000000-0000-0000-0000-000000000004'::uuid, 'hassan', 'hassan@local.test', 'Hassan Tariq',  'Wicket-keeper.'),
      ('00000000-0000-0000-0000-000000000005'::uuid, 'adeel',  'adeel@local.test',  'Adeel Saeed',   'Middle-order. Right-arm off-spin.'),
      ('00000000-0000-0000-0000-000000000006'::uuid, 'karim',  'karim@local.test',  'Karim Anwar',   'Left-arm fast.'),
      ('00000000-0000-0000-0000-000000000007'::uuid, 'saad',   'saad@local.test',   'Saad Iqbal',    'All-rounder.'),
      ('00000000-0000-0000-0000-000000000008'::uuid, 'usman',  'usman@local.test',  'Usman Ali',     'Right-arm medium-fast.'),
      ('00000000-0000-0000-0000-000000000009'::uuid, 'yousaf', 'yousaf@local.test', 'Yousaf Khan',   'Lower-order. Left-arm spin.'),
      ('0000000a-0000-0000-0000-00000000000a'::uuid, 'zaid',   'zaid@local.test',   'Zaid Malik',    'All-rounder. Switch-hit specialist.')
    ) as t(id, username, email, display_name, bio)
  loop
    -- ON CONFLICT DO NOTHING — if this teammate uid already exists from a
    -- prior seed run, leave their credentials alone.
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      reauthentication_token, phone_change, phone_change_token,
      created_at, updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      v.id, 'authenticated', 'authenticated', v.email,
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', v.display_name),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '',
      '', '', '',
      now(), now()
    )
    on conflict (id) do nothing;

    -- ON CONFLICT on (provider, provider_id) — the unique index Supabase
    -- maintains on identity lookups. Skip if the email identity already
    -- exists for this user.
    insert into auth.identities (
      id, user_id, identity_data, provider, provider_id,
      last_sign_in_at, created_at, updated_at
    )
    values (
      gen_random_uuid(),
      v.id,
      jsonb_build_object(
        'sub', v.id::text,
        'email', v.email,
        'email_verified', true
      ),
      'email',
      v.id::text,
      now(), now(), now()
    )
    on conflict (provider, provider_id) do nothing;

    -- ON CONFLICT DO UPDATE — Supabase apps commonly install a trigger on
    -- auth.users INSERT that auto-creates a profile row with defaults from
    -- raw_user_meta_data. Our explicit profile row overrides those
    -- defaults with the seed values (notably `username` and `bio`).
    insert into public.profiles (
      user_id, username, display_name, bio,
      created_at, updated_at, onboarded_at, last_active_at
    )
    values (
      v.id, v.username, v.display_name, v.bio,
      now(), now(), now(), now()
    )
    on conflict (user_id) do update set
      username       = excluded.username,
      display_name   = excluded.display_name,
      bio            = excluded.bio,
      onboarded_at   = excluded.onboarded_at,
      last_active_at = excluded.last_active_at,
      updated_at     = now();
  end loop;
end $seed_teammates$;

-- =============================================================================
-- 2) Teams
-- =============================================================================
-- You own 3 teams (your own team chats appear in your inbox as owner).
-- Teammates own the other 12. Inserting a team fires `create_team_chat`
-- which creates the chat row and adds the owner to chat_members as admin.
-- =============================================================================

-- Your teams (3). Resolved at runtime so created_by is YOUR uid.
-- Inserting a team fires create_owner_membership, which makes that user the
-- team's member holding the `owner` role — so no membership rows here.
do $seed_my_teams$
declare
  v_me uuid;
begin
  select id into v_me from auth.users
    where email = 'muhammadsarankhalid@gmail.com';

  insert into public.teams (team_id, created_by, team_name, team_type, team_colors, logo_monogram, home_ground, founded_year)
  values
    ('11111111-1111-1111-1111-111111111101', v_me, 'Lahore Lions',     'club',    '{"primary":"#DC4D32","secondary":"#26221B"}'::jsonb, 'LL', 'Model Town Sports Complex',  2018),
    ('11111111-1111-1111-1111-111111111102', v_me, 'Islamabad United', 'club',    '{"primary":"#1E40AF","secondary":"#FFFFFF"}'::jsonb, 'IU', 'Islamabad Sports Complex',   2020),
    ('1111111e-1111-1111-1111-11111111110e', v_me, 'Hyderabad Hawks',  'casual',  '{"primary":"#0EA5E9","secondary":"#F0F9FF"}'::jsonb, 'HH', 'Niaz Stadium Hyderabad',     2023);
end $seed_my_teams$;

-- Teammates' teams (12). Owners are pinned-uuid teammates from §1.
insert into public.teams (team_id, created_by, team_name, team_type, team_colors, logo_monogram, home_ground, founded_year)
values
  ('11111111-1111-1111-1111-111111111103', '00000000-0000-0000-0000-000000000002', 'Karachi Eagles',    'club',     '{"primary":"#15803D","secondary":"#FAF8E8"}'::jsonb, 'KE', 'KGA Ground',                 2017),
  ('11111111-1111-1111-1111-111111111104', '00000000-0000-0000-0000-000000000002', 'Karachi Knights',   'casual',   '{"primary":"#7C2D12","secondary":"#FED7AA"}'::jsonb, 'KK', 'Defence Cricket Club',       2021),
  ('11111111-1111-1111-1111-111111111105', '00000000-0000-0000-0000-000000000003', 'Multan Sultans',    'club',     '{"primary":"#B45309","secondary":"#FFFFFF"}'::jsonb, 'MS', 'Multan Cricket Stadium',     2019),
  ('11111111-1111-1111-1111-111111111106', '00000000-0000-0000-0000-000000000003', 'Multan Mavericks',  'casual',   '{"primary":"#A21CAF","secondary":"#FDF4FF"}'::jsonb, 'MM', 'Town Hall Ground',           2022),
  ('11111111-1111-1111-1111-111111111107', '00000000-0000-0000-0000-000000000004', 'Quetta Cobras',     'club',     '{"primary":"#7E22CE","secondary":"#FAFAF9"}'::jsonb, 'QC', 'Ayub Stadium',               2018),
  ('11111111-1111-1111-1111-111111111108', '00000000-0000-0000-0000-000000000004', 'Quetta Gladiators', 'corporate','{"primary":"#0F766E","secondary":"#F0FDFA"}'::jsonb, 'QG', 'Sariab Road Ground',         2016),
  ('11111111-1111-1111-1111-111111111109', '00000000-0000-0000-0000-000000000005', 'Sialkot Stallions', 'club',     '{"primary":"#E11D48","secondary":"#FFE4E6"}'::jsonb, 'SS', 'Jinnah Stadium Sialkot',     2019),
  ('1111111a-1111-1111-1111-11111111110a', '00000000-0000-0000-0000-000000000005', 'Sialkot Strikers',  'casual',   '{"primary":"#0369A1","secondary":"#E0F2FE"}'::jsonb, 'SK', 'PNS Sangar Ground',          2021),
  ('1111111b-1111-1111-1111-11111111110b', '00000000-0000-0000-0000-000000000006', 'Peshawar Tigers',   'club',     '{"primary":"#F59E0B","secondary":"#26221B"}'::jsonb, 'PT', 'Arbab Niaz Stadium',         2018),
  ('1111111c-1111-1111-1111-11111111110c', '00000000-0000-0000-0000-000000000007', 'Faisalabad Falcons','casual',   '{"primary":"#16A34A","secondary":"#FFFFFF"}'::jsonb, 'FF', 'Iqbal Stadium',              2020),
  ('1111111d-1111-1111-1111-11111111110d', '00000000-0000-0000-0000-000000000008', 'Rawalpindi Rams',   'corporate','{"primary":"#7C3AED","secondary":"#FAFAF9"}'::jsonb, 'RR', 'Rawalpindi Cricket Stadium', 2017),
  ('1111111f-1111-1111-1111-11111111110f', '0000000a-0000-0000-0000-00000000000a', 'Bahawalpur Bears',  'village',  '{"primary":"#65A30D","secondary":"#FFFFFF"}'::jsonb, 'BB', 'Bahawalpur Stadium',         2023);

-- =============================================================================
-- 3) Team membership
-- =============================================================================
-- Inserting a team_members row fires `add_team_member_to_chat`, which adds
-- the user to that team's chat. Owners are already added to chat_members by
-- the create_team_chat trigger, so we don't re-add them here.
--
-- YOU as member of 5 teammate-owned teams (so your inbox shows 8 chats:
-- the 3 you own + these 5). Hyderabad Hawks stays owner-only (empty-thread
-- test surface).
-- =============================================================================

-- YOU joining 5 teammate teams.
do $seed_my_memberships$
declare
  v_me uuid;
begin
  select id into v_me from auth.users
    where email = 'muhammadsarankhalid@gmail.com';

  insert into public.team_members (team_id, user_id, added_by, status, joined_at)
  select t.team_id, v_me, t.created_by, 'active', j.joined_at
  from (values
    ('11111111-1111-1111-1111-111111111103'::uuid, now() - interval '60 days'),  -- Karachi Eagles
    ('11111111-1111-1111-1111-111111111105'::uuid, now() - interval '70 days'),  -- Multan Sultans
    ('11111111-1111-1111-1111-111111111107'::uuid, now() - interval '55 days'),  -- Quetta Cobras
    ('11111111-1111-1111-1111-111111111109'::uuid, now() - interval '50 days'),  -- Sialkot Stallions
    ('1111111b-1111-1111-1111-11111111110b'::uuid, now() - interval '45 days')   -- Peshawar Tigers
  ) as j(team_id, joined_at)
  join public.teams t on t.team_id = j.team_id;
end $seed_my_memberships$;

-- Teammates joining each other's teams + your teams (so messages have
-- varied senders in every active chat).
-- The `role` column is gone (2026-09-11). Every seeded member is a plain
-- player, which is what assign_initial_role() attaches by default.
insert into public.team_members (team_id, user_id, added_by, status, joined_at)
select r.team_id, r.user_id, t.created_by, r.status::public.member_status, r.joined_at
from (values

  -- Lahore Lions (yours) — rich roster for the curated thread
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'player', 'active', now() - interval '120 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'player', 'active', now() - interval '110 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000004'::uuid, 'player', 'active', now() - interval '100 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000005'::uuid, 'player', 'active', now() - interval '95 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000006'::uuid, 'player', 'active', now() - interval '90 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000007'::uuid, 'player', 'active', now() - interval '85 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000008'::uuid, 'player', 'active', now() - interval '80 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '00000000-0000-0000-0000-000000000009'::uuid, 'player', 'active', now() - interval '75 days'),
  ('11111111-1111-1111-1111-111111111101'::uuid, '0000000a-0000-0000-0000-00000000000a'::uuid, 'player', 'active', now() - interval '70 days'),
  -- Islamabad United (yours) — moderate activity
  ('11111111-1111-1111-1111-111111111102'::uuid, '00000000-0000-0000-0000-000000000006'::uuid, 'player', 'active', now() - interval '50 days'),
  ('11111111-1111-1111-1111-111111111102'::uuid, '00000000-0000-0000-0000-000000000007'::uuid, 'player', 'active', now() - interval '45 days'),
  ('11111111-1111-1111-1111-111111111102'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'player', 'active', now() - interval '40 days'),
  -- Hyderabad Hawks (yours, empty) — intentionally no extra members
  -- Karachi Eagles (Bilal owns) — pagination stress; multiple senders
  ('11111111-1111-1111-1111-111111111103'::uuid, '00000000-0000-0000-0000-000000000004'::uuid, 'player', 'active', now() - interval '55 days'),
  ('11111111-1111-1111-1111-111111111103'::uuid, '00000000-0000-0000-0000-000000000005'::uuid, 'player', 'active', now() - interval '50 days'),
  ('11111111-1111-1111-1111-111111111103'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'player', 'active', now() - interval '45 days'),
  ('11111111-1111-1111-1111-111111111103'::uuid, '00000000-0000-0000-0000-000000000007'::uuid, 'player', 'active', now() - interval '40 days'),
  ('11111111-1111-1111-1111-111111111103'::uuid, '00000000-0000-0000-0000-000000000008'::uuid, 'player', 'active', now() - interval '35 days'),
  -- Karachi Knights (Bilal)
  ('11111111-1111-1111-1111-111111111104'::uuid, '00000000-0000-0000-0000-000000000008'::uuid, 'player', 'active', now() - interval '40 days'),
  ('11111111-1111-1111-1111-111111111104'::uuid, '00000000-0000-0000-0000-000000000009'::uuid, 'player', 'active', now() - interval '35 days'),
  -- Multan Sultans (Faraz)
  ('11111111-1111-1111-1111-111111111105'::uuid, '00000000-0000-0000-0000-000000000006'::uuid, 'player', 'active', now() - interval '65 days'),
  ('11111111-1111-1111-1111-111111111105'::uuid, '00000000-0000-0000-0000-000000000009'::uuid, 'player', 'active', now() - interval '60 days'),
  ('11111111-1111-1111-1111-111111111105'::uuid, '00000000-0000-0000-0000-000000000005'::uuid, 'player', 'active', now() - interval '55 days'),
  -- Multan Mavericks (Faraz)
  ('11111111-1111-1111-1111-111111111106'::uuid, '00000000-0000-0000-0000-000000000004'::uuid, 'player', 'active', now() - interval '30 days'),
  -- Quetta Cobras (Hassan)
  ('11111111-1111-1111-1111-111111111107'::uuid, '00000000-0000-0000-0000-000000000009'::uuid, 'player', 'active', now() - interval '55 days'),
  ('11111111-1111-1111-1111-111111111107'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'player', 'active', now() - interval '50 days'),
  ('11111111-1111-1111-1111-111111111107'::uuid, '00000000-0000-0000-0000-000000000007'::uuid, 'player', 'active', now() - interval '45 days'),
  -- Quetta Gladiators (Hassan)
  ('11111111-1111-1111-1111-111111111108'::uuid, '0000000a-0000-0000-0000-00000000000a'::uuid, 'player', 'active', now() - interval '25 days'),
  -- Sialkot Stallions (Adeel)
  ('11111111-1111-1111-1111-111111111109'::uuid, '0000000a-0000-0000-0000-00000000000a'::uuid, 'player', 'active', now() - interval '50 days'),
  ('11111111-1111-1111-1111-111111111109'::uuid, '00000000-0000-0000-0000-000000000008'::uuid, 'player', 'active', now() - interval '45 days'),
  -- Sialkot Strikers (Adeel)
  ('1111111a-1111-1111-1111-11111111110a'::uuid, '00000000-0000-0000-0000-000000000009'::uuid, 'player', 'active', now() - interval '30 days'),
  ('1111111a-1111-1111-1111-11111111110a'::uuid, '00000000-0000-0000-0000-000000000006'::uuid, 'player', 'active', now() - interval '25 days'),
  -- Peshawar Tigers (Karim)
  ('1111111b-1111-1111-1111-11111111110b'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'player', 'active', now() - interval '40 days'),
  -- Faisalabad Falcons (Saad)
  ('1111111c-1111-1111-1111-11111111110c'::uuid, '00000000-0000-0000-0000-000000000002'::uuid, 'player', 'active', now() - interval '40 days'),
  ('1111111c-1111-1111-1111-11111111110c'::uuid, '00000000-0000-0000-0000-000000000004'::uuid, 'player', 'active', now() - interval '35 days'),
  -- Rawalpindi Rams (Usman)
  ('1111111d-1111-1111-1111-11111111110d'::uuid, '00000000-0000-0000-0000-000000000003'::uuid, 'player', 'active', now() - interval '40 days'),
  ('1111111d-1111-1111-1111-11111111110d'::uuid, '00000000-0000-0000-0000-000000000005'::uuid, 'player', 'active', now() - interval '35 days')
) as r(team_id, user_id, role, status, joined_at)
join public.teams t on t.team_id = r.team_id;


-- =============================================================================
-- 4) Lahore Lions — curated 30-message coordination thread
-- =============================================================================
-- YOU are the captain doing the coordinating. The thread reads as a
-- realistic match-day flow over 4 days. Messages where the captain speaks
-- are attributed to your account; others are from teammates.
--
-- Note: in the rendered thread your display_name is whatever's on your
-- profile (likely your real name). The conversation reads as you organising
-- a friendly with the Eagles.
-- =============================================================================

do $seed_lions$
declare
  v_chat   uuid;
  v_me     uuid;
  v_bilal  uuid := '00000000-0000-0000-0000-000000000002';
  v_faraz  uuid := '00000000-0000-0000-0000-000000000003';
  v_hassan uuid := '00000000-0000-0000-0000-000000000004';
  v_adeel  uuid := '00000000-0000-0000-0000-000000000005';
  v_karim  uuid := '00000000-0000-0000-0000-000000000006';
  v_saad   uuid := '00000000-0000-0000-0000-000000000007';
  v_usman  uuid := '00000000-0000-0000-0000-000000000008';
  v_yousaf uuid := '00000000-0000-0000-0000-000000000009';
begin
  select id into v_me from auth.users
    where email = 'muhammadsarankhalid@gmail.com';
  select channel_id into v_chat
    from public.chat_channels
   where team_id = '11111111-1111-1111-1111-111111111101' and purpose = 'main';

  insert into public.messages (channel_id, sender_id, body, created_at) values
    -- Day -3 (you announce the friendly)
    (v_chat, v_me,     'Alright everyone, we''ve locked in a friendly with Karachi Eagles for Saturday. Toss at 3:45pm, match starts 4pm sharp.', now() - interval '3 days' + interval '10 hours'),
    (v_chat, v_bilal,  'Ground?',                                                                                                                  now() - interval '3 days' + interval '10 hours' + interval '2 minutes'),
    (v_chat, v_me,     'Model Town Sports Complex, Pitch 2.',                                                                                       now() - interval '3 days' + interval '10 hours' + interval '3 minutes'),
    (v_chat, v_faraz,  'I can do Saturday. Will bring two extra balls.',                                                                            now() - interval '3 days' + interval '10 hours' + interval '15 minutes'),
    (v_chat, v_karim,  'Count me in.',                                                                                                              now() - interval '3 days' + interval '10 hours' + interval '32 minutes'),
    (v_chat, v_me,     'Need confirmations from everyone by tomorrow EOD. We need at least 13 for a proper XI + 2 subs.',                           now() - interval '3 days' + interval '11 hours'),
    (v_chat, v_bilal,  'I''ll spread the word in WhatsApp too.',                                                                                    now() - interval '3 days' + interval '11 hours' + interval '5 minutes'),
    -- Day -2 (roster fills up)
    (v_chat, v_me,     'RSVP count so far: Bilal, Faraz, Karim, me. Need at least 9 more.',                                                         now() - interval '2 days' + interval '9 hours'),
    (v_chat, v_bilal,  'What about Adeel? He was asking yesterday.',                                                                                now() - interval '2 days' + interval '9 hours' + interval '15 minutes'),
    (v_chat, v_adeel,  'Yeah I''m in. Just confirming.',                                                                                            now() - interval '2 days' + interval '9 hours' + interval '30 minutes'),
    (v_chat, v_faraz,  'Hassan said he''s flying in Saturday morning, will play.',                                                                  now() - interval '2 days' + interval '10 hours'),
    (v_chat, v_hassan, 'Confirmed.',                                                                                                                now() - interval '2 days' + interval '10 hours' + interval '5 minutes'),
    (v_chat, v_me,     'Great, 6 so far. Yousaf you in?',                                                                                           now() - interval '2 days' + interval '11 hours'),
    (v_chat, v_yousaf, 'In.',                                                                                                                       now() - interval '2 days' + interval '11 hours' + interval '30 minutes'),
    (v_chat, v_saad,   'I''ll be there. Can someone send the ground location?',                                                                     now() - interval '2 days' + interval '12 hours'),
    (v_chat, v_me,     'Pinned the ground location above.',                                                                                         now() - interval '2 days' + interval '12 hours' + interval '5 minutes'),
    (v_chat, v_saad,   'Got it. Thanks.',                                                                                                           now() - interval '2 days' + interval '12 hours' + interval '6 minutes'),
    (v_chat, v_bilal,  'Faisal Khan is in town this weekend, maybe pull him in as a sub?',                                                          now() - interval '2 days' + interval '14 hours'),
    (v_chat, v_me,     'Faisal as sub, noted.',                                                                                                     now() - interval '2 days' + interval '14 hours' + interval '5 minutes'),
    (v_chat, v_karim,  'How about Usman?',                                                                                                          now() - interval '2 days' + interval '15 hours'),
    (v_chat, v_usman,  'I''m in.',                                                                                                                  now() - interval '2 days' + interval '15 hours' + interval '30 minutes'),
    (v_chat, v_me,     '9 confirmed so far. Need 2 more for XI + 2 subs.',                                                                          now() - interval '2 days' + interval '16 hours'),
    -- Day -1 (final XI locked)
    (v_chat, v_me,     'Final XI locked. Bilal opens with me. Faraz 3, Hassan 4, Yousaf 5, Karim 6, Adeel 7, Saad 8, Zaid 9, Usman 10, me 11. Captain me.', now() - interval '1 day' + interval '8 hours'),
    (v_chat, v_bilal,  'What about subs?',                                                                                                           now() - interval '1 day' + interval '8 hours' + interval '15 minutes'),
    (v_chat, v_me,     'Subs: Faisal and one TBD.',                                                                                                  now() - interval '1 day' + interval '8 hours' + interval '20 minutes'),
    (v_chat, v_me,     'Toss at 3:45 sharp. Be at the ground 3:15 latest.',                                                                          now() - interval '1 day' + interval '8 hours' + interval '30 minutes'),
    (v_chat, v_faraz,  'On it.',                                                                                                                     now() - interval '1 day' + interval '8 hours' + interval '35 minutes'),
    -- Day 0 (today — match in progress)
    (v_chat, v_me,     'Won the toss. Bowling first.',                                                                                              now() - interval '3 hours'),
    (v_chat, v_faraz,  'Crushing it 👍',                                                                                                             now() - interval '2 hours' - interval '30 minutes'),
    (v_chat, v_bilal,  '85-2 in 11 overs. They''re cooked.',                                                                                         now() - interval '1 hour' - interval '45 minutes');
end $seed_lions$;

-- =============================================================================
-- 5) Karachi Eagles — 250-message pagination/perf stress
-- =============================================================================
-- You're a member here (joined in §3), so your inbox shows this chat with
-- whatever the latest message + unread count is. Senders rotate through all
-- active members INCLUDING you, so some messages will show as "from me."
-- =============================================================================

do $seed_eagles$
declare
  v_chat uuid;
  v_members uuid[];
  v_sender uuid;
  v_bodies text[] := array[
    'Practice tomorrow?',
    'Anyone got a spare pair of pads?',
    'GG everyone.',
    'What time is the match?',
    'Bringing extra balls.',
    'Net session at 6pm Wed.',
    'Need 4 to win.',
    'Toss won.',
    'Lost the toss, bowling first.',
    'Ground confirmed.',
    'Lineup posted.',
    'Adeel out, sub needed.',
    'Be there by 3.',
    'Anyone driving to the ground?',
    'Bringing the cooler.',
    'Photos uploaded to the group.',
    'WhatsApp message about the schedule, check it.',
    'Will be late — traffic.',
    'What a catch by Karim 🏏',
    'Match cancelled — rain.',
    'Reschedule to Sunday?',
    'Score: 142/3 in 16 overs.',
    'Karachi 156/8, all out.',
    'Won by 12 runs!',
    'Captain announced: Bilal.',
    'RSVP by tonight please.',
    'Anyone seen the umpire?',
    'Boundary is short on the southern side.',
    'Pitch is dry.',
    'Power play strategy?'
  ];
  v_count int := 250;
  i int;
begin
  select channel_id into v_chat
    from public.chat_channels
   where team_id = '11111111-1111-1111-1111-111111111103' and purpose = 'main';

  select array_agg(user_id) into v_members
    from public.channel_members
   where channel_id = v_chat
     and user_id is not null
     and left_at is null;

  for i in 1..v_count loop
    v_sender := v_members[1 + floor(random() * array_length(v_members, 1))::int];
    insert into public.messages (channel_id, sender_id, body, created_at)
    values (
      v_chat,
      v_sender,
      v_bodies[1 + floor(random() * array_length(v_bodies, 1))::int],
      now() - (random() * interval '60 days')
    );
  end loop;
end $seed_eagles$;

-- =============================================================================
-- 6) Randomised messages — remaining active chats
-- =============================================================================
-- Skips:
--   • Lahore Lions       (curated above)
--   • Karachi Eagles     (pagination stress above)
--   • Hyderabad Hawks    (yours, intentionally empty)
--   • Bahawalpur Bears   (Zaid's, only-owner → no varied senders)
--
-- Other chats: 30–100 messages each, varied senders, spread over 30 days.
-- =============================================================================

do $seed_random$
declare
  v_chat record;
  v_members uuid[];
  v_sender uuid;
  v_bodies text[] := array[
    'Practice tomorrow?',
    'Anyone got a spare pair of pads?',
    'GG everyone.',
    'What time is the match?',
    'Bringing extra balls.',
    'Net session at 6pm Wed.',
    'Need 4 to win.',
    'Toss won.',
    'Ground confirmed.',
    'Lineup posted.',
    'Adeel out, sub needed.',
    'Be there by 3.',
    'Anyone driving?',
    'Bringing the cooler.',
    'Match this weekend confirmed.',
    'Won by 12 runs!',
    'Captain announced.',
    'RSVP by tonight please.',
    'Pitch looks great.',
    'Power play strategy?',
    'Need a wicket-keeper for Sunday.',
    'Bilal MOM 🎉',
    'Anyone got the scorecard?',
    'Tournament fixture out.',
    'Practice cancelled — rain.',
    'Net booked for Tuesday.',
    'New jerseys in.',
    'Anyone want to bowl in the nets?'
  ];
  v_count int;
  i int;
begin
  for v_chat in
    select c.channel_id, t.team_name
      from public.chat_channels c
      join public.teams t on t.team_id = c.team_id
     where t.team_name not in (
       'Lahore Lions', 'Karachi Eagles', 'Hyderabad Hawks', 'Bahawalpur Bears'
     )
     and c.purpose = 'main'
  loop
    select array_agg(user_id) into v_members
      from public.channel_members
     where channel_id = v_chat.channel_id
       and user_id is not null
       and left_at is null;

    if v_members is null or array_length(v_members, 1) < 1 then
      continue;
    end if;

    v_count := 30 + (random() * 70)::int;
    for i in 1..v_count loop
      v_sender := v_members[1 + floor(random() * array_length(v_members, 1))::int];
      insert into public.messages (channel_id, sender_id, body, created_at)
      values (
        v_chat.channel_id,
        v_sender,
        v_bodies[1 + floor(random() * array_length(v_bodies, 1))::int],
        now() - (random() * interval '30 days')
      );
    end loop;
  end loop;
end $seed_random$;

-- =============================================================================
-- Posts & Comments Seed
-- =============================================================================
do $seed_posts$
declare
  v_owner uuid := '00000000-0000-0000-0000-000000000001';
  v_bilal uuid := '00000000-0000-0000-0000-000000000002';
  v_faraz uuid := '00000000-0000-0000-0000-000000000003';
  v_hassan uuid := '00000000-0000-0000-0000-000000000004';
  v_adeel uuid := '00000000-0000-0000-0000-000000000005';
  v_karim uuid := '00000000-0000-0000-0000-000000000006';
  v_saad uuid := '00000000-0000-0000-0000-000000000007';
  v_usman uuid := '00000000-0000-0000-0000-000000000008';
  v_yousaf uuid := '00000000-0000-0000-0000-000000000009';
  v_zaid uuid := '0000000a-0000-0000-0000-00000000000a';

  v_lahore_team uuid := '11111111-1111-1111-1111-111111111101';
  v_karachi_team uuid := '11111111-1111-1111-1111-111111111103';
  v_isb_team uuid := '11111111-1111-1111-1111-111111111102';

  v_tp1 uuid := '20000000-0000-0000-0000-000000000001';
  v_tp2 uuid := '20000000-0000-0000-0000-000000000002';
  v_tp3 uuid := '20000000-0000-0000-0000-000000000003';
  v_tp4 uuid := '20000000-0000-0000-0000-000000000004';
  v_tp5 uuid := '20000000-0000-0000-0000-000000000005';

  -- Pinned comment IDs for threaded discussions
  v_c_tp1_1 uuid := '30000000-0000-0000-0000-000000000001';
  v_c_tp1_2 uuid := '30000000-0000-0000-0000-000000000002';
  v_c_tp1_3 uuid := '30000000-0000-0000-0000-000000000003';
  v_c_tp1_4 uuid := '30000000-0000-0000-0000-000000000004';
  v_c_tp1_5 uuid := '30000000-0000-0000-0000-000000000005';
  v_c_tp1_6 uuid := '30000000-0000-0000-0000-000000000006';
  v_c_tp1_7 uuid := '30000000-0000-0000-0000-000000000007';
  v_c_tp1_8 uuid := '30000000-0000-0000-0000-000000000008';
  v_c_tp1_9 uuid := '30000000-0000-0000-0000-000000000009';
  v_c_tp1_10 uuid := '30000000-0000-0000-0000-000000000010';
  v_c_tp1_11 uuid := '30000000-0000-0000-0000-000000000011';
  v_c_tp1_12 uuid := '30000000-0000-0000-0000-000000000012';
  v_c_tp1_13 uuid := '30000000-0000-0000-0000-000000000013';

  v_c_tp2_1 uuid := '30000000-0000-0000-0000-000000000021';
  v_c_tp2_2 uuid := '30000000-0000-0000-0000-000000000022';
  v_c_tp4_1 uuid := '30000000-0000-0000-0000-000000000041';
begin
  -- 1. Lahore Lions official photo post
  insert into public.posts (
    post_id, created_by_user_id, author_id, author_context, context_entity_id,
    publisher_type, publisher_id, post_kind, post_type, text, expected_media_count,
    status, published_at, created_at
  )
  values (
    v_tp1,
    v_owner,
    v_owner,
    'team_manager',
    v_lahore_team,
    'team',
    v_lahore_team,
    'standard',
    'photo',
    '🦁 Official squad training ahead of the Super Weekend derby! The boys are looking sharp and ready.',
    2,
    'active',
    now() - interval '2 hours',
    now() - interval '2 hours'
  ) on conflict (post_id) do nothing;

  insert into public.post_media (
    media_id, post_id, position, media_type, status,
    staging_path, final_prefix,
    source_width, source_height, display_width, display_height, variants
  )
  values
    (gen_random_uuid(), v_tp1, 0, 'image', 'feed_ready', 'seed/tp1/0/source.jpg', 'posts/tp1/0/v1/', 1080, 720, 1080, 720, '{"feed": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1080&q=80"}'::jsonb),
    (gen_random_uuid(), v_tp1, 1, 'image', 'feed_ready', 'seed/tp1/1/source.jpg', 'posts/tp1/1/v1/', 1080, 720, 1080, 720, '{"feed": "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=1080&q=80"}'::jsonb)
  on conflict do nothing;

  -- 2. Lahore Lions Matchday Announcement
  insert into public.posts (
    post_id, created_by_user_id, author_id, author_context, context_entity_id,
    publisher_type, publisher_id, post_kind, post_type, text, expected_media_count,
    status, published_at, created_at
  )
  values (
    v_tp2,
    v_owner,
    v_owner,
    'team_manager',
    v_lahore_team,
    'team',
    v_lahore_team,
    'match_announcement',
    'photo',
    '⚡ MATCHDAY ANNOUNCEMENT: Lahore Lions vs Karachi Eagles this Sunday at Gaddafi Stadium Ground 2. Toss at 4:30 PM!',
    1,
    'active',
    now() - interval '1 day',
    now() - interval '1 day'
  ) on conflict (post_id) do nothing;

  insert into public.post_media (
    media_id, post_id, position, media_type, status,
    staging_path, final_prefix,
    source_width, source_height, display_width, display_height, variants
  )
  values
    (gen_random_uuid(), v_tp2, 0, 'image', 'feed_ready', 'seed/tp2/0/source.jpg', 'posts/tp2/0/v1/', 1080, 720, 1080, 720, '{"feed": "https://images.unsplash.com/photo-1589801258579-18e091f4ca26?w=1080&q=80"}'::jsonb)
  on conflict do nothing;

  -- 3. Karachi Eagles Team Post
  insert into public.posts (
    post_id, created_by_user_id, author_id, author_context, context_entity_id,
    publisher_type, publisher_id, post_kind, post_type, text, expected_media_count,
    status, published_at, created_at
  )
  values (
    v_tp3,
    v_bilal,
    v_bilal,
    'team_manager',
    v_karachi_team,
    'team',
    v_karachi_team,
    'recruitment',
    'photo',
    '🦅 Karachi Eagles are recruiting 2 opening batsmen and an express pacer for the upcoming T20 tournament. DM or drop a comment to try out!',
    1,
    'active',
    now() - interval '3 days',
    now() - interval '3 days'
  ) on conflict (post_id) do nothing;

  insert into public.post_media (
    media_id, post_id, position, media_type, status,
    staging_path, final_prefix,
    source_width, source_height, display_width, display_height, variants
  )
  values
    (gen_random_uuid(), v_tp3, 0, 'image', 'feed_ready', 'seed/tp3/0/source.jpg', 'posts/tp3/0/v1/', 1080, 720, 1080, 720, '{"feed": "https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=1080&q=80"}'::jsonb)
  on conflict do nothing;

  -- 4. Player Personal Posts
  insert into public.posts (
    post_id, created_by_user_id, author_id, author_context, context_entity_id,
    publisher_type, publisher_id, post_kind, post_type, text, expected_media_count,
    status, published_at, created_at
  )
  values
    (
      v_tp4,
      v_faraz,
      v_faraz,
      'personal',
      null,
      'user',
      v_faraz,
      'standard',
      'photo',
      'Solid net session today with the squad. Batting rhythm feeling crisp and timing is right on point!',
      1,
      'active',
      now() - interval '4 hours',
      now() - interval '4 hours'
    ),
    (
      v_tp5,
      v_hassan,
      v_hassan,
      'personal',
      null,
      'user',
      v_hassan,
      'standard',
      'text',
      'Tape ball under the lights hits different in Lahore 🔥 Great match against Gulberg Strikers tonight!',
      0,
      'active',
      now() - interval '6 hours',
      now() - interval '6 hours'
    )
  on conflict (post_id) do nothing;

  insert into public.post_media (
    media_id, post_id, position, media_type, status,
    staging_path, final_prefix,
    source_width, source_height, display_width, display_height, variants
  )
  values
    (gen_random_uuid(), v_tp4, 0, 'image', 'feed_ready', 'seed/tp4/0/source.jpg', 'posts/tp4/0/v1/', 1080, 720, 1080, 720, '{"feed": "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=1080&q=80"}'::jsonb)
  on conflict do nothing;

  -- 5. Threaded Comments on Posts
  -- 5a. Top-level Comments
  insert into public.comments (comment_id, post_id, author_id, parent_comment_id, text, mentioned_user_ids, created_at)
  values
    -- v_tp1 (Lahore Lions photo post - Saran is author)
    (v_c_tp1_1, v_tp1, v_bilal, null, 'Looking sharp boys! Looking forward to the derby 🏆', '{}', now() - interval '110 minutes'),
    (v_c_tp1_2, v_tp1, v_faraz, null, 'Pace attack is fully locked in 🔥', '{}', now() - interval '80 minutes'),
    (v_c_tp1_3, v_tp1, v_owner, null, 'Captain''s message: Ground 2 pitch has good carry. We want intensity in every drill!', '{}', now() - interval '65 minutes'),
    (v_c_tp1_4, v_tp1, v_hassan, null, 'Wicket-keeping gloves strapped and ready! Catching drills were spotless 🧤', '{}', now() - interval '50 minutes'),
    (v_c_tp1_5, v_tp1, v_karim, null, 'Left-arm swing coming your way Karachi Eagles 🎯', '{}', now() - interval '45 minutes'),
    (v_c_tp1_6, v_tp1, v_saad, null, 'Middle order is prepared for any chase scenario. Let''s go Lions!', '{}', now() - interval '35 minutes'),
    (v_c_tp1_7, v_tp1, v_adeel, null, 'Pitch looks dry, spin could be decisive in middle overs. @saran what''s the toss call?', array[v_owner], now() - interval '25 minutes'),
    (v_c_tp1_8, v_tp1, v_usman, null, 'Kit looks clean! Proud to wear the Lahore Lions badge 🦁', '{}', now() - interval '20 minutes'),
    (v_c_tp1_9, v_tp1, v_zaid, null, 'Switch hits practiced, ready to accelerate whenever needed 💥', '{}', now() - interval '15 minutes'),
    (v_c_tp1_10, v_tp1, v_yousaf, null, 'Weather forecast is crystal clear for Sunday. Match on!', '{}', now() - interval '12 minutes'),
    (v_c_tp1_11, v_tp1, v_bilal, null, 'Team dinner tonight after final gym session? @saran', array[v_owner], now() - interval '10 minutes'),
    (v_c_tp1_12, v_tp1, v_faraz, null, 'Anyone got an extra pair of batting gloves for Sunday?', '{}', now() - interval '8 minutes'),
    (v_c_tp1_13, v_tp1, v_karim, null, 'Matchday adrenaline is already kicking in!', '{}', now() - interval '5 minutes'),

    -- v_tp2 (Lahore Lions match announcement - Saran is author)
    (v_c_tp2_1, v_tp2, v_adeel, null, 'InshaAllah big win coming this weekend! Can''t wait to see the crowd.', '{}', now() - interval '12 hours'),
    (v_c_tp2_2, v_tp2, v_faraz, null, 'Toss at 4:30 PM sharp, everyone be at the ground by 3:00 PM for warmups.', '{}', now() - interval '8 hours'),
    (gen_random_uuid(), v_tp2, v_hassan, null, 'Warmup schedule confirmed. Let''s get the win!', '{}', now() - interval '6 hours'),
    (gen_random_uuid(), v_tp2, v_zaid, null, 'Support Lahore Lions! Drop a comment if you are attending 🦁', '{}', now() - interval '4 hours'),

    -- v_tp3 (Karachi Eagles recruitment)
    (gen_random_uuid(), v_tp3, v_hassan, null, 'Sent my stats over DM, would love to join!', '{}', now() - interval '2 days'),
    (gen_random_uuid(), v_tp3, v_faraz, null, 'Great initiative, best of luck with the trials.', '{}', now() - interval '1 day'),
    (gen_random_uuid(), v_tp3, v_usman, null, 'Know a few fast bowlers from our club, sending them the link.', '{}', now() - interval '12 hours'),

    -- v_tp4 (Faraz personal post)
    (v_c_tp4_1, v_tp4, v_owner, null, 'Solid net session today Faraz! Keep that high elbow on the drive.', '{}', now() - interval '3 hours'),
    (gen_random_uuid(), v_tp4, v_bilal, null, 'Form is temporary, class is permanent brother 🔥', '{}', now() - interval '2 hours')
  on conflict do nothing;

  -- 5b. Threaded Replies
  insert into public.comments (comment_id, post_id, author_id, parent_comment_id, text, mentioned_user_ids, created_at)
  values
    -- Replies under v_c_tp1_1 (Bilal - 4 replies)
    (gen_random_uuid(), v_tp1, v_faraz, v_c_tp1_1, '@bilal 100%! Ready to dominate the powerplay.', '{}', now() - interval '100 minutes'),
    (gen_random_uuid(), v_tp1, v_karim, v_c_tp1_1, '@bilal Yorker drill paid off today, rhythm is feeling lethal.', '{}', now() - interval '95 minutes'),
    (gen_random_uuid(), v_tp1, v_owner, v_c_tp1_1, '@bilal Batting order looks solid, let''s stick to the gameplan.', '{}', now() - interval '90 minutes'),
    (gen_random_uuid(), v_tp1, v_zaid, v_c_tp1_1, '@saran Can''t wait for Sunday brother! Energy is high.', array[v_owner], now() - interval '85 minutes'),

    -- Replies under v_c_tp1_2 (Faraz - 2 replies)
    (gen_random_uuid(), v_tp1, v_usman, v_c_tp1_2, '@faraz 140+ on the radar in the first spell guaranteed!', '{}', now() - interval '75 minutes'),
    (gen_random_uuid(), v_tp1, v_karim, v_c_tp1_2, '@faraz Let''s hunt in pairs with the new ball.', '{}', now() - interval '70 minutes'),

    -- Replies under v_c_tp1_3 (Saran - 5 replies from teammates -> triggers 5 social.comment.replied notifications)
    (gen_random_uuid(), v_tp1, v_hassan, v_c_tp1_3, '@saran Keeper gloves ready, won''t let a single edge slip through skipper.', '{}', now() - interval '60 minutes'),
    (gen_random_uuid(), v_tp1, v_adeel, v_c_tp1_3, '@saran Off-spin might grip late in the second innings too.', '{}', now() - interval '55 minutes'),
    (gen_random_uuid(), v_tp1, v_bilal, v_c_tp1_3, '@saran I''ll anchor the top order and see off the swing.', '{}', now() - interval '50 minutes'),
    (gen_random_uuid(), v_tp1, v_saad, v_c_tp1_3, '@saran Fielding drills were intense today, everyone diving 100%.', '{}', now() - interval '45 minutes'),
    (gen_random_uuid(), v_tp1, v_yousaf, v_c_tp1_3, '@saran Backing the boys all the way! Big win loading.', '{}', now() - interval '40 minutes'),

    -- Replies under v_c_tp1_4 (Hassan - 2 replies)
    (gen_random_uuid(), v_tp1, v_adeel, v_c_tp1_4, '@hassan Stumping speed is lightning fast lately.', '{}', now() - interval '35 minutes'),
    (gen_random_uuid(), v_tp1, v_faraz, v_c_tp1_4, '@hassan Trusting you with every edge behind the stumps!', '{}', now() - interval '33 minutes'),

    -- Replies under v_c_tp1_5 (Karim - 3 replies)
    (gen_random_uuid(), v_tp1, v_zaid, v_c_tp1_5, '@karim Swing it both ways in the first 3 overs!', '{}', now() - interval '28 minutes'),
    (gen_random_uuid(), v_tp1, v_usman, v_c_tp1_5, '@karim We bowl them out under 140 easy.', '{}', now() - interval '25 minutes'),
    (gen_random_uuid(), v_tp1, v_bilal, v_c_tp1_5, '@karim Keep targeting that off-stump channel.', '{}', now() - interval '22 minutes'),

    -- Replies under v_c_tp1_7 (Adeel - 2 replies)
    (gen_random_uuid(), v_tp1, v_owner, v_c_tp1_7, '@adeel If we win toss, we bat first and put 180+ on the board.', '{}', now() - interval '15 minutes'),
    (gen_random_uuid(), v_tp1, v_adeel, v_c_tp1_7, '@saran Perfect, defending with our bowling lineup is our strength.', '{}', now() - interval '12 minutes'),

    -- Replies under v_c_tp1_12 (Faraz - 2 replies)
    (gen_random_uuid(), v_tp1, v_hassan, v_c_tp1_12, '@faraz Got a brand new pair in my kit bag, you can use them.', '{}', now() - interval '3 minutes'),
    (gen_random_uuid(), v_tp1, v_faraz, v_c_tp1_12, '@hassan Legend! Thanks brother.', '{}', now() - interval '2 minutes'),

    -- Replies under v_c_tp2_1 (Adeel on announcement - 2 replies)
    (gen_random_uuid(), v_tp2, v_bilal, v_c_tp2_1, '@adeel Gaddafi Ground 2 is going to be packed!', '{}', now() - interval '11 hours'),
    (gen_random_uuid(), v_tp2, v_owner, v_c_tp2_1, '@adeel Let''s give them a great game to remember.', '{}', now() - interval '10 hours'),

    -- Replies under v_c_tp4_1 (Saran on Faraz post - 2 replies -> triggers social.comment.replied notifications)
    (gen_random_uuid(), v_tp4, v_faraz, v_c_tp4_1, '@saran Thanks skipper! Working on that backfoot punch as well.', '{}', now() - interval '2 hours'),
    (gen_random_uuid(), v_tp4, v_hassan, v_c_tp4_1, '@saran His timing was echoing across the whole ground today!', '{}', now() - interval '1 hour')
  on conflict do nothing;

  -- 6. Comment Likes
  insert into public.comment_likes (like_id, comment_id, user_id, created_at)
  values
    (gen_random_uuid(), v_c_tp1_1, v_faraz, now() - interval '105 minutes'),
    (gen_random_uuid(), v_c_tp1_1, v_karim, now() - interval '100 minutes'),
    (gen_random_uuid(), v_c_tp1_1, v_hassan, now() - interval '95 minutes'),
    (gen_random_uuid(), v_c_tp1_1, v_adeel, now() - interval '90 minutes'),
    (gen_random_uuid(), v_c_tp1_1, v_owner, now() - interval '80 minutes'),

    (gen_random_uuid(), v_c_tp1_2, v_usman, now() - interval '78 minutes'),
    (gen_random_uuid(), v_c_tp1_2, v_karim, now() - interval '76 minutes'),
    (gen_random_uuid(), v_c_tp1_2, v_owner, now() - interval '74 minutes'),

    (gen_random_uuid(), v_c_tp1_3, v_bilal, now() - interval '64 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_faraz, now() - interval '63 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_hassan, now() - interval '62 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_adeel, now() - interval '61 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_karim, now() - interval '60 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_saad, now() - interval '59 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_usman, now() - interval '58 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_yousaf, now() - interval '57 minutes'),
    (gen_random_uuid(), v_c_tp1_3, v_zaid, now() - interval '56 minutes'),

    (gen_random_uuid(), v_c_tp1_4, v_adeel, now() - interval '48 minutes'),
    (gen_random_uuid(), v_c_tp1_4, v_faraz, now() - interval '46 minutes'),

    (gen_random_uuid(), v_c_tp1_5, v_zaid, now() - interval '40 minutes'),
    (gen_random_uuid(), v_c_tp1_5, v_usman, now() - interval '38 minutes'),

    (gen_random_uuid(), v_c_tp1_7, v_owner, now() - interval '24 minutes'),
    (gen_random_uuid(), v_c_tp1_7, v_bilal, now() - interval '22 minutes'),

    (gen_random_uuid(), v_c_tp2_1, v_bilal, now() - interval '11 hours'),
    (gen_random_uuid(), v_c_tp2_1, v_owner, now() - interval '10 hours'),

    (gen_random_uuid(), v_c_tp4_1, v_faraz, now() - interval '2 hours'),
    (gen_random_uuid(), v_c_tp4_1, v_hassan, now() - interval '1 hour'),
    (gen_random_uuid(), v_c_tp4_1, v_bilal, now() - interval '30 minutes')
  on conflict do nothing;

  -- 7. Post Likes
  insert into public.post_likes (post_id, user_id, created_at)
  values
    (v_tp1, v_bilal, now()),
    (v_tp1, v_faraz, now()),
    (v_tp1, v_hassan, now()),
    (v_tp2, v_bilal, now()),
    (v_tp2, v_adeel, now()),
    (v_tp3, v_owner, now())
  on conflict do nothing;
end $seed_posts$;

-- =============================================================================
-- Summary — what your inbox looks like when you sign in
-- =============================================================================
--   1. Lahore Lions       owner    curated 30 messages, captain you, very recent
--   2. Islamabad United   owner    ~30–100 random messages
--   3. Hyderabad Hawks    owner    EMPTY (zero messages, empty-thread state)
--   4. Karachi Eagles     member   250 messages, pagination stress
--   5. Multan Sultans     member   ~30–100 random
--   6. Quetta Cobras      member   ~30–100 random
--   7. Sialkot Stallions  member   ~30–100 random
--   8. Peshawar Tigers    member   ~30–100 random
--
-- Teammate sign-in credentials (all `pass1234`):
--   bilal@local.test    Bilal Ahmed
--   faraz@local.test    Faraz Khan
--   hassan@local.test   Hassan Tariq
--   adeel@local.test    Adeel Saeed
--   karim@local.test    Karim Anwar
--   saad@local.test     Saad Iqbal
--   usman@local.test    Usman Ali
--   yousaf@local.test   Yousaf Khan
--   zaid@local.test     Zaid Malik
--
-- Sign in as a teammate (e.g. bilal@local.test) to see the same chats from
-- a different perspective. Useful for testing realtime: have your real
-- account open in the app, then send a message from Bilal's account in
-- another window → your inbox + open thread should patch in-memory.
-- =============================================================================

-- =============================================================================
-- 4) Team Requests Seed (Match Requests, Team Invites & Player Claim Requests)
-- =============================================================================

do $seed_team_requests$
declare
  v_saran_uid   uuid;
  v_bilal_uid   constant uuid := '00000000-0000-0000-0000-000000000002';
  v_hassan_uid  constant uuid := '00000000-0000-0000-0000-000000000004';
  v_babar_uid   constant uuid := '00000000-0000-0000-0000-000000000010';
  v_shaheen_uid constant uuid := '00000000-0000-0000-0000-000000000011';
  v_rizwan_uid  constant uuid := '00000000-0000-0000-0000-000000000012';
  v_shadab_uid  constant uuid := '00000000-0000-0000-0000-000000000013';

  v_lahore_lions      constant uuid := '11111111-1111-1111-1111-111111111101';
  v_islamabad_united  constant uuid := '11111111-1111-1111-1111-111111111102';
  v_karachi_kings     constant uuid := '11111111-1111-1111-1111-111111111104';
  v_rawalpindi_rams   constant uuid := '11111111-1111-1111-1111-111111111106';

  v_unclaimed_wahab   constant uuid := '50000000-0000-0000-0000-000000000001';
  v_unclaimed_imad    constant uuid := '50000000-0000-0000-0000-000000000002';
begin
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;

  -- 1) Create Extra Stars in auth.users if not present
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    reauthentication_token, phone_change, phone_change_token,
    created_at, updated_at
  )
  values
    (
      '00000000-0000-0000-0000-000000000000',
      v_babar_uid, 'authenticated', 'authenticated', 'babar@cricket.pk',
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', 'Babar Azam'),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '', '', '', '', now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      v_shaheen_uid, 'authenticated', 'authenticated', 'shaheen@cricket.pk',
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', 'Shaheen Afridi'),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '', '', '', '', now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      v_rizwan_uid, 'authenticated', 'authenticated', 'rizwan@cricket.pk',
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', 'Mohammad Rizwan'),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '', '', '', '', now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      v_shadab_uid, 'authenticated', 'authenticated', 'shadab@cricket.pk',
      extensions.crypt('pass1234', extensions.gen_salt('bf')),
      now(),
      jsonb_build_object('display_name', 'Shadab Khan'),
      jsonb_build_object('provider', 'email', 'providers', array['email']),
      '', '', '', '', '', '', '', now(), now()
    )
  on conflict (id) do nothing;

  insert into public.profiles (user_id, username, display_name, bio, onboarded_at)
  values
    (v_babar_uid,   'babar',   'Babar Azam',       'Cover drive enthusiast · Batter · Lahore',       now()),
    (v_shaheen_uid, 'shaheen', 'Shaheen Afridi',   'Eagle of Lahore · Left-arm Fast Bowler',         now()),
    (v_rizwan_uid,  'rizwan',  'Mohammad Rizwan',  'Hard work & faith · Wicket-keeper Batter',       now()),
    (v_shadab_uid,  'shadab',  'Shadab Khan',      'Leg spin & fielding · All-Rounder',              now())
  on conflict (user_id) do update set
    username = excluded.username,
    display_name = excluded.display_name;

  -- 2) Unclaimed Players on Lahore Lions Roster
  insert into public.unclaimed_players (unclaimed_id, sport_id, display_name, phone_number, added_by, created_at, updated_at)
  values
    (v_unclaimed_wahab, 'cricket', 'Wahab Riaz', '+923001112233', v_saran_uid, now(), now()),
    (v_unclaimed_imad,  'cricket', 'Imad Wasim', '+923004445566', v_saran_uid, now(), now())
  on conflict (unclaimed_id) do nothing;

  insert into public.team_members (membership_id, team_id, unclaimed_id, added_by, jersey_number, status)
  values
    ('60000000-0000-0000-0000-000000000001', v_lahore_lions, v_unclaimed_wahab, v_saran_uid, 14, 'active'),
    ('60000000-0000-0000-0000-000000000002', v_lahore_lions, v_unclaimed_imad,  v_saran_uid, 9,  'active')
  on conflict (membership_id) do nothing;

  -- 3) Player Claim Request: Babar claiming the Wahab Riaz spot on Lahore Lions
  insert into public.claim_requests (request_id, unclaimed_id, requester_id, message, status, created_at, updated_at)
  values (
    '70000000-0000-0000-0000-000000000001',
    v_unclaimed_wahab,
    v_babar_uid,
    'Hey captain, that was me playing in the Sunday friendly! Linking my stats to my new Matchday account.',
    'pending',
    now() - interval '3 hours',
    now() - interval '3 hours'
  )
  on conflict (request_id) do nothing;

  -- 4) Player Join Requests (Players asking to join Lahore Lions)
  insert into public.team_join_requests (request_id, team_id, player_id, role, message, status, created_at)
  values
    (
      '75000000-0000-0000-0000-000000000001',
      v_lahore_lions,
      v_rizwan_uid,
      'player',
      'Assalam o Alaikum! I am a wicketkeeper-batter based in Lahore. Looking to join Lahore Lions for weekend league matches.',
      'pending',
      now() - interval '2 hours'
    ),
    (
      '75000000-0000-0000-0000-000000000002',
      v_lahore_lions,
      v_shadab_uid,
      'player',
      'Leg-spin all-rounder available for the upcoming season. Would love to join the squad!',
      'pending',
      now() - interval '6 hours'
    )
  on conflict (request_id) do nothing;

  -- 5) Team Invites:
  --    a. Outgoing invite from Lahore Lions to Shaheen Afridi
  insert into public.team_invites (invite_id, team_id, invitee_id, invited_by, message, role, jersey_number, status, created_at)
  values (
    '80000000-0000-0000-0000-000000000001',
    v_lahore_lions,
    v_shaheen_uid,
    v_saran_uid,
    'Join Lahore Lions as our premier strike bowler for the upcoming Super Weekend Derby!',
    'player',
    10,
    'pending',
    now() - interval '1 day'
  )
  on conflict (invite_id) do nothing;

  --    b. Incoming invite to Saran from Islamabad United
  insert into public.team_invites (invite_id, team_id, invitee_id, invited_by, message, role, jersey_number, status, created_at)
  values (
    '80000000-0000-0000-0000-000000000002',
    v_islamabad_united,
    v_saran_uid,
    v_bilal_uid,
    'Would love to have you guest-captain our Islamabad side this weekend!',
    'captain',
    7,
    'pending',
    now() - interval '5 hours'
  )
  on conflict (invite_id) do nothing;

  -- 5) Match Requests (Challenges for Lahore Lions):
  --    a. Incoming Match Challenge from Karachi Kings to Lahore Lions
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format_code, proposed_format,
    share_code, message, status,
    proposal_expires_at, created_at, updated_at
  )
  values (
    '90000000-0000-0000-0000-000000000001',
    v_karachi_kings,
    v_lahore_lions,
    v_bilal_uid,
    now() + interval '3 days',
    'Gaddafi Stadium, Lahore',
    't20',
    '{"overs_per_innings": 20, "ball_type": "leather", "pitch_type": "turf", "match_type": "limited_overs", "players_per_team": 11, "balls_per_over": 6, "max_overs_per_bowler": 4}'::jsonb,
    '582914',
    'Super Weekend 20-over challenge! We have booked the main turf ground. Let us know if you accept.',
    'pending',
    now() + interval '48 hours',
    now() - interval '4 hours',
    now() - interval '4 hours'
  )
  on conflict (request_id) do nothing;

  --    b. Countered Match Challenge from Rawalpindi Rams to Lahore Lions
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format_code, proposed_format,
    countered_start_time, countered_venue, countered_format_code, countered_format,
    share_code, message, status,
    decided_by, decided_at, decision_note,
    proposal_expires_at, counter_expires_at, created_at, updated_at
  )
  values (
    '90000000-0000-0000-0000-000000000002',
    v_rawalpindi_rams,
    v_lahore_lions,
    v_hassan_uid,
    now() + interval '5 days',
    'Rawalpindi Cricket Stadium',
    'custom',
    '{"overs_per_innings": 15, "ball_type": "tape", "match_type": "limited_overs", "players_per_team": 11, "balls_per_over": 6, "max_overs_per_bowler": 3}'::jsonb,
    now() + interval '5 days 2 hours',
    'LCCA Ground, Lahore',
    'custom',
    '{"overs_per_innings": 15, "ball_type": "tape", "match_type": "limited_overs", "players_per_team": 11, "balls_per_over": 6, "max_overs_per_bowler": 3}'::jsonb,
    '418902',
    'Tape ball night match challenge under lights.',
    'countered',
    v_saran_uid,
    now() - interval '1 hour',
    'Can we move the venue to LCCA Ground Lahore so our local squad can make it?',
    now() + interval '48 hours',
    now() + interval '24 hours',
    now() - interval '8 hours',
    now() - interval '1 hour'
  )
  on conflict (request_id) do nothing;

  --    c. Outgoing Open Challenge by Lahore Lions (with share code)
  insert into public.match_challenges (
    request_id, from_team_id, to_team_id, requested_by,
    proposed_start_time, proposed_venue, proposed_format_code, proposed_format,
    share_code, message, status,
    proposal_expires_at, code_expires_at, created_at, updated_at
  )
  values (
    '90000000-0000-0000-0000-000000000003',
    v_lahore_lions,
    null,
    v_saran_uid,
    now() + interval '2 days',
    'Model Town Club Ground, Lahore',
    't20',
    '{"overs_per_innings": 20, "ball_type": "leather", "match_type": "limited_overs", "players_per_team": 11, "balls_per_over": 6, "max_overs_per_bowler": 4}'::jsonb,
    '729401',
    'Open weekend friendly! Any Lahore team up for a 20-over leather ball match, enter share code 729401 to accept.',
    'pending',
    now() + interval '48 hours',
    now() + interval '24 hours',
    now() - interval '2 hours',
    now() - interval '2 hours'
  )
  on conflict (request_id) do nothing;

  -- ===========================================================================
  -- 5b) Seed Realistic Matches for Lahore Lions (Confirmed, Live, Past)
  -- ===========================================================================
  -- 1. Live Match in Play: Lahore Lions vs Karachi Kings (20 overs)
  --    Lahore Lions batting 142/3 in 15.4 overs
  declare
    m_live_id       constant uuid := '30000000-0000-0000-0000-000000000001';
    m_upcoming_id   constant uuid := '30000000-0000-0000-0000-000000000002';
    m_past_id       constant uuid := '30000000-0000-0000-0000-000000000003';
    mp_saran_live   constant uuid := '31000000-0000-0000-0000-000000000001';
    mp_babar_live   constant uuid := '31000000-0000-0000-0000-000000000002';
    mp_bilal_live   constant uuid := '31000000-0000-0000-0000-000000000003';
    -- match_players rows for the completed match. The live-match trio above
    -- belong to m_live_id and cannot be reused as the past match's lineup:
    -- cricket_match_deliveries' player FKs point at match_players, and match_players
    -- is scoped to one match_id.
    mp_saran_past   constant uuid := '31000000-0000-0000-0000-000000000011';
    mp_babar_past   constant uuid := '31000000-0000-0000-0000-000000000012';
    mp_bilal_past   constant uuid := '31000000-0000-0000-0000-000000000013';
    inn_live_1      constant uuid := '32000000-0000-0000-0000-000000000001';
    inn_past_1      constant uuid := '32000000-0000-0000-0000-000000000011';
    inn_past_2      constant uuid := '32000000-0000-0000-0000-000000000012';
  begin
    -- 1. LIVE MATCH
    insert into public.matches (
      match_id, match_type,
      venue, scheduled_start_time, actual_start_time,
      status, created_by, created_at, updated_at
    )
    values (
      m_live_id, 'friendly',
      'Gaddafi Stadium, Lahore',
      now() - interval '1 hour 15 minutes',
      now() - interval '1 hour 15 minutes',
      'scheduled', v_saran_uid, now() - interval '2 days', now()
    )
    on conflict (match_id) do update set
      status = excluded.status,
      scheduled_start_time = excluded.scheduled_start_time,
      actual_start_time = excluded.actual_start_time;

    -- Resolve match_teams side slots for the live match.
    -- The trigger auto-creates (team_a, NULL) and (team_b, NULL) on insert;
    -- we update them to set the resolved team_id and snapshot team_name.
    update public.match_teams
       set team_id   = v_lahore_lions,
           team_name = (select team_name from public.teams where team_id = v_lahore_lions)
     where match_id = m_live_id and team_side = 'team_a';

    update public.match_teams
       set team_id   = v_karachi_kings,
           team_name = (select team_name from public.teams where team_id = v_karachi_kings)
     where match_id = m_live_id and team_side = 'team_b';

    update public.matches
       set status = 'live'
     where match_id = m_live_id;

    insert into public.cricket_matches (
      match_id, format_code, rules_snapshot, phase,
      toss_won_by, toss_decision, toss_face, toss_recorded_at
    )
    values (
      m_live_id, 't20',
      '{"players_per_team": 11, "overs_per_innings": 20, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 4, "ball_type": "leather"}'::jsonb,
      'live', 'team_a', 'bat', 'heads', now() - interval '1 hour 15 minutes'
    )
    on conflict (match_id) do update set
      phase = excluded.phase;

    -- Match Players for Live Match
    insert into public.match_players (
      match_player_id, match_id, team_side, user_id,
      display_name, jersey_number
    )
    values
      (mp_saran_live, m_live_id, 'team_a', v_saran_uid, 'Saran Khalid', 7),
      (mp_babar_live, m_live_id, 'team_a', v_babar_uid, 'Babar Azam',   56),
      (mp_bilal_live, m_live_id, 'team_b', v_bilal_uid, 'Bilal Ahmed',  10)
    on conflict (match_player_id) do nothing;

    insert into public.cricket_match_players (
      match_player_id, match_id, is_playing_xi, batting_order, is_captain
    )
    values
      (mp_saran_live, m_live_id, true, 1, true),
      (mp_babar_live, m_live_id, true, 2, false),
      (mp_bilal_live, m_live_id, true, null, true)
    on conflict (match_player_id) do nothing;

    -- Live Innings. cricket_match_innings_state hangs off cricket_match_innings, so the parent
    -- has to exist first: its PK innings_id is NOT NULL on the state row.
    insert into public.cricket_match_innings (
      innings_id, match_id, innings_number,
      batting_team_side, bowling_team_side, overs_allocated
    )
    values (inn_live_1, m_live_id, 1, 'team_a', 'team_b', 20.0)
    on conflict (innings_id) do nothing;

    -- total_extras is GENERATED from the five breakdown columns and cannot be
    -- written directly; seed the parts and let it compute (8 = 5 wides + 3 byes).
    insert into public.cricket_match_innings_state (
      innings_id, match_id, innings_number,
      striker_id, non_striker_id, bowler_id,
      legal_ball_count, total_runs, total_wickets,
      total_wides, total_byes,
      version
    )
    values (
      inn_live_1, m_live_id, 1,
      mp_saran_live, mp_babar_live, mp_bilal_live,
      94, 142, 3,
      5, 3, 1
    )
    on conflict (innings_id) do update set
      legal_ball_count = excluded.legal_ball_count,
      total_runs = excluded.total_runs,
      total_wickets = excluded.total_wickets;

    -- 2. CONFIRMED UPCOMING MATCH: Lahore Lions vs Rawalpindi Rams (Tomorrow at 4:30 PM)
    insert into public.matches (
      match_id, match_type,
      venue, scheduled_start_time,
      status, created_by, created_at, updated_at
    )
    values (
      m_upcoming_id, 'friendly',
      'Model Town Club Ground, Lahore',
      now() + interval '1 day 2 hours',
      'scheduled', v_saran_uid, now() - interval '1 day', now()
    )
    on conflict (match_id) do update set
      status = excluded.status,
      scheduled_start_time = excluded.scheduled_start_time;

    -- Resolve match_teams side slots for the upcoming match.
    update public.match_teams
       set team_id   = v_lahore_lions,
           team_name = (select team_name from public.teams where team_id = v_lahore_lions)
     where match_id = m_upcoming_id and team_side = 'team_a';

    update public.match_teams
       set team_id   = v_rawalpindi_rams,
           team_name = (select team_name from public.teams where team_id = v_rawalpindi_rams)
     where match_id = m_upcoming_id and team_side = 'team_b';

    insert into public.cricket_matches (
      match_id, format_code, rules_snapshot, phase
    )
    values (
      m_upcoming_id, 't20',
      '{"players_per_team": 11, "overs_per_innings": 20, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 4, "ball_type": "leather"}'::jsonb,
      'toss'
    )
    on conflict (match_id) do update set
      phase = excluded.phase;

    -- 3. PAST COMPLETED MATCH: Lahore Lions vs Islamabad United (Yesterday)
    --    Lahore Lions won by 24 runs (LL: 168/5, IU: 144/9)
    insert into public.matches (
      match_id, match_type,
      venue, scheduled_start_time, actual_start_time, completed_at,
      status, created_by, created_at, updated_at
    )
    values (
      m_past_id, 'friendly',
      'LCCA Ground, Lahore',
      now() - interval '1 day 4 hours',
      now() - interval '1 day 4 hours',
      now() - interval '1 day 1 hour',
      'scheduled',
      v_saran_uid, now() - interval '2 days', now()
    )
    on conflict (match_id) do update set
      status = excluded.status,
      scheduled_start_time = excluded.scheduled_start_time,
      actual_start_time = excluded.actual_start_time,
      completed_at = excluded.completed_at;

    -- Resolve match_teams side slots for the completed match.
    update public.match_teams
       set team_id   = v_lahore_lions,
           team_name = (select team_name from public.teams where team_id = v_lahore_lions)
     where match_id = m_past_id and team_side = 'team_a';

    update public.match_teams
       set team_id   = v_islamabad_united,
           team_name = (select team_name from public.teams where team_id = v_islamabad_united)
     where match_id = m_past_id and team_side = 'team_b';

    update public.matches
       set status = 'completed',
           winner_side = 'team_a'
     where match_id = m_past_id;

    insert into public.cricket_matches (
      match_id, format_code, rules_snapshot, phase,
      toss_won_by, toss_decision, toss_face, toss_recorded_at,
      result, result_summary
    )
    values (
      m_past_id, 't20',
      '{"players_per_team": 11, "overs_per_innings": 20, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 4, "ball_type": "leather"}'::jsonb,
      'complete',
      'team_a', 'bat', 'heads', now() - interval '1 day 4 hours',
      '{"winner_team_id": "11111111-1111-1111-1111-111111111101", "win_type": "runs", "win_margin": 24, "summary": "Lahore Lions won by 24 runs"}'::jsonb,
      'Lahore Lions won by 24 runs'
    )
    on conflict (match_id) do update set
      phase = excluded.phase,
      result = excluded.result;

    -- Lineup for the completed match. Needed because cricket_match_deliveries' striker /
    -- non-striker / bowler FKs point at match_players, scoped per match.
    insert into public.match_players (
      match_player_id, match_id, team_side, user_id,
      display_name, jersey_number
    )
    values
      (mp_saran_past, m_past_id, 'team_a', v_saran_uid, 'Saran Khalid', 7),
      (mp_babar_past, m_past_id, 'team_a', v_babar_uid, 'Babar Azam',   56),
      (mp_bilal_past, m_past_id, 'team_b', v_bilal_uid, 'Bilal Ahmed',  10)
    on conflict (match_player_id) do nothing;

    insert into public.cricket_match_players (
      match_player_id, match_id, is_playing_xi, batting_order, is_captain
    )
    values
      (mp_saran_past, m_past_id, true, 1, true),
      (mp_babar_past, m_past_id, true, 2, false),
      (mp_bilal_past, m_past_id, true, 1, true)
    on conflict (match_player_id) do nothing;

    -- Past Match Innings 1 (Lahore Lions: 168/5) and 2 (Islamabad United: 144/9)
    insert into public.cricket_match_innings (
      innings_id, match_id, innings_number,
      batting_team_side, bowling_team_side, overs_allocated, is_completed
    )
    values
      (inn_past_1, m_past_id, 1, 'team_a', 'team_b', 20.0, true),
      (inn_past_2, m_past_id, 2, 'team_b', 'team_a', 20.0, true)
    on conflict (innings_id) do nothing;

    -- total_extras is generated; seed its parts (12 = 8 wides + 4 byes,
    -- 6 = 4 wides + 2 leg-byes).
    insert into public.cricket_match_innings_state (
      innings_id, match_id, innings_number,
      legal_ball_count, total_runs, total_wickets,
      total_wides, total_byes, total_leg_byes,
      target, version
    )
    values
      (inn_past_1, m_past_id, 1, 120, 168, 5, 8, 4, 0, null, 1),
      (inn_past_2, m_past_id, 2, 120, 144, 9, 4, 0, 2, 169,  1)
    on conflict (innings_id) do update set
      legal_ball_count = excluded.legal_ball_count,
      total_runs = excluded.total_runs,
      total_wickets = excluded.total_wickets;

    -- Sample deliveries for listInningsForMatches aggregation. Written to
    -- cricket_match_deliveries directly rather than through the `balls` view, with the
    -- columns the table actually has: innings_id and seq are NOT NULL, and
    -- idempotency_key no longer carries a default (the client owns it).
    insert into public.cricket_match_deliveries (
      innings_id, match_id, innings_number, seq,
      over_number, ball_in_over, is_legal_delivery, delivery_type,
      runs_off_bat, striker_id, non_striker_id, bowler_id,
      is_four, is_boundary, idempotency_key
    )
    values
      (inn_past_1, m_past_id, 1, 1, 19, 6, true, 'legal',
       4, mp_saran_past, mp_babar_past, mp_bilal_past,
       true, true, 'seed-past-inn1-ball1'),
      (inn_past_2, m_past_id, 2, 1, 19, 6, true, 'legal',
       1, mp_bilal_past, mp_babar_past, mp_saran_past,
       false, false, 'seed-past-inn2-ball1')
    on conflict (innings_id, seq) do nothing;
  end;

  raise notice 'Team requests & matches seeded successfully for Lahore Lions.';



end $seed_team_requests$;


-- =============================================================================
-- 6) Direct Message from Non-Follower (Message Request Demo)
-- =============================================================================
do $seed_dm$
declare
  v_saran_uid   uuid;
  v_sender_uid  constant uuid := '00000000-0000-0000-0000-000000000005'; -- Adeel Saeed (@adeel)
  v_user_a      uuid;
  v_user_b      uuid;
  v_chat_id     uuid;
  c_chat_id     constant uuid := '40000000-0000-0000-0000-000000000001';
  v_channel_key text;
begin
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;
  if v_saran_uid is null then
    v_saran_uid := '00000000-0000-0000-0000-000000000001'::uuid;
  end if;

  -- Ensure non-follower relationship
  delete from public.follows
   where (follower_id = v_saran_uid and target_type = 'user' and target_id = v_sender_uid)
      or (follower_id = v_sender_uid and target_type = 'user' and target_id = v_saran_uid);

  if v_saran_uid < v_sender_uid then
    v_user_a := v_saran_uid;
    v_user_b := v_sender_uid;
  else
    v_user_a := v_sender_uid;
    v_user_b := v_saran_uid;
  end if;

  v_channel_key := 'dm:' || v_user_a::text || ':' || v_user_b::text;

  select channel_id into v_chat_id
    from public.chat_channels
   where channel_key = v_channel_key;

  if v_chat_id is null then
    v_chat_id := c_chat_id;
    delete from public.messages where channel_id = v_chat_id;
    delete from public.channel_members where channel_id = v_chat_id;
    delete from public.chat_channels where channel_id = v_chat_id;

    insert into public.chat_channels (channel_id, channel_key, kind, context_type, visibility, created_by, last_message_at, created_at, updated_at)
    values (v_chat_id, v_channel_key, 'direct', 'none', 'private', v_sender_uid, now() - interval '25 minutes', now() - interval '2 days', now());

    insert into public.channel_policies (channel_id) values (v_chat_id) on conflict do nothing;
  end if;

  insert into public.channel_members (channel_id, user_id, role, status, invited_by, invited_at, joined_at, last_read_at, left_at)
  values
    (v_chat_id, v_sender_uid, 'member', 'active', v_sender_uid, now() - interval '2 days', now() - interval '2 days', now() - interval '10 minutes', null),
    (v_chat_id, v_saran_uid,  'member', 'pending', v_sender_uid, now() - interval '2 days', null, null, null)
  on conflict (channel_id, user_id) do update set
    status = excluded.status,
    last_read_at = excluded.last_read_at,
    left_at = null;

  delete from public.messages where channel_id = v_chat_id;

  insert into public.messages (
    message_id, channel_id, sender_id, body, message_type, payload, created_at
  )
  values (
    '41000000-0000-0000-0000-000000000001',
    v_chat_id,
    v_sender_uid,
    'Salam Saran! I saw your post regarding Lahore Lions trials. I am an off-spin all-rounder playing in Faisalabad Premier League. Would love to join the trial session this Tuesday at Model Town.',
    'text',
    '{}'::jsonb,
    now() - interval '25 minutes'
  );

  update public.chat_channels
     set last_message_at = now() - interval '25 minutes'
   where channel_id = v_chat_id;

  raise notice 'Message request DM seeded successfully from Adeel Saeed to Saran.';
end $seed_dm$;


-- =============================================================================
-- CLEANUP — paste into the SQL editor when you want to remove the seed
-- =============================================================================
-- Drops everything seeded above. Your own account + profile + any teams you
-- created OUTSIDE the seed remain untouched (the seed only deletes by
-- email-domain match for teammates and by pinned uuid for teams).
-- =============================================================================
--
-- begin;
-- delete from public.teams where team_id in (
--   '11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111102',
--   '11111111-1111-1111-1111-111111111103', '11111111-1111-1111-1111-111111111104',
--   '11111111-1111-1111-1111-111111111105', '11111111-1111-1111-1111-111111111106',
--   '11111111-1111-1111-1111-111111111107', '11111111-1111-1111-1111-111111111108',
--   '11111111-1111-1111-1111-111111111109', '1111111a-1111-1111-1111-11111111110a',
--   '1111111b-1111-1111-1111-11111111110b', '1111111c-1111-1111-1111-11111111110c',
--   '1111111d-1111-1111-1111-11111111110d', '1111111e-1111-1111-1111-11111111110e',
--   '1111111f-1111-1111-1111-11111111110f'
-- );
-- -- ON DELETE CASCADE on teams flows to chats / chat_members / messages /
-- -- team_members. So team deletion is sufficient for cleanup of the chat
-- -- and messaging layer. Only the auth users remain:
-- delete from auth.users where email like '%@local.test';
-- commit;

