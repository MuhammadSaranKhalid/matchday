-- =============================================================================
-- seed_posts.sql — home-feed test data: ~30 text posts across teammates + you
-- =============================================================================
-- Pairs with the Home tab's `getFeed` query (active posts newest-first,
-- author profile embedded). After running, the feed renders ~30 cricket-
-- themed posts spread over the last 30 days, authored by a mix of:
--   • YOU (muhammadsarankhalid@gmail.com) — a handful of posts
--   • The 9 fake teammates from seed.sql (Bilal/Faraz/Hassan/Adeel/Karim/
--     Saad/Usman/Yousaf/Zaid)
--
-- All posts are:
--   • post_type='text'        — no media uploads required (storage RLS
--                                 demands the row exists BEFORE upload;
--                                 trying to seed media would need real
--                                 storage objects — out of scope here)
--   • author_context='personal' — first-person; no team/tournament context
--   • status='active'           — visible in the feed
--   • visibility='public'       — only valid value today
--   • likes/comments/shares counts left at 0 (the triggers maintain them
--                                              for any future like/comment
--                                              inserts)
--
-- Idempotent: each post has a fixed UUID; re-runs hit
-- ON CONFLICT (post_id) DO NOTHING and don't double-insert.
--
-- Prereq: supabase/seed.sql must have been run first (creates the
-- teammate users this file references by their pinned UUIDs).
-- =============================================================================

do $seed_posts$
declare
  v_me uuid;
  -- Teammate UIDs (same constants as seed.sql lines 181-192).
  v_bilal   constant uuid := '00000000-0000-0000-0000-000000000002';
  v_faraz   constant uuid := '00000000-0000-0000-0000-000000000003';
  v_hassan  constant uuid := '00000000-0000-0000-0000-000000000004';
  v_adeel   constant uuid := '00000000-0000-0000-0000-000000000005';
  v_karim   constant uuid := '00000000-0000-0000-0000-000000000006';
  v_saad    constant uuid := '00000000-0000-0000-0000-000000000007';
  v_usman   constant uuid := '00000000-0000-0000-0000-000000000008';
  v_yousaf  constant uuid := '00000000-0000-0000-0000-000000000009';
  v_zaid    constant uuid := '0000000a-0000-0000-0000-00000000000a';
begin
  select id into v_me
    from auth.users
   where email = 'muhammadsarankhalid@gmail.com';
  if v_me is null then
    raise exception
      'seed_posts.sql: muhammadsarankhalid@gmail.com not found. '
      'Run seed.sql first.';
  end if;

  insert into public.posts (
    post_id, author_id, author_context, post_type, text, created_at
  ) values
    -- ── Recent (last 7 days) ─────────────────────────────────────────
    ('20260601-aaaa-aaaa-aaaa-000000000001', v_bilal, 'personal', 'text',
     'Match day mood. Lahore Lions vs Mohalla Kings, 8am Sunday at Model Town. Bring water, bring intent.',
     now() - interval '6 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000002', v_hassan, 'personal', 'text',
     'Watched Faraz bowl 4 overs of dot balls today. Some bowlers chase wickets. He just suffocates you.',
     now() - interval '5 days 8 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000003', v_me, 'personal', 'text',
     'Took a one-handed return catch at gully today and immediately blacked out from the adrenaline.',
     now() - interval '5 days 2 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000004', v_faraz, 'personal', 'text',
     'Question for the group: leather ball season starts in two weeks. Who has actually been practicing with the new ball?',
     now() - interval '4 days 18 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000005', v_adeel, 'personal', 'text',
     'Twelfth man duty today. Brought drinks for 14 overs. Made 0 not out off 0 balls. Greatest unbeaten innings of my career.',
     now() - interval '4 days 9 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000006', v_karim, 'personal', 'text',
     'Net session at Iqbal Stadium. Six bowlers, two batters, one ball. Cricket maths is brutal.',
     now() - interval '4 days 1 hour'),
    ('20260601-aaaa-aaaa-aaaa-000000000007', v_saad, 'personal', 'text',
     'Sunday tape ball league has been the best part of my year. No coach. No drama. Just cricket and chai.',
     now() - interval '3 days 14 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000008', v_usman, 'personal', 'text',
     'Hot take: a 6-over T6 format would be the most entertaining cricket on earth. Fight me.',
     now() - interval '3 days 6 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000009', v_bilal, 'personal', 'text',
     'Found my old bat in the storeroom. Last used 2019. Knock-in tonight, debut next Sunday. Wish me luck.',
     now() - interval '2 days 20 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000010', v_yousaf, 'personal', 'text',
     'Saw a kid at our ground bowl 6 overs on the trot, 1/14, age 13. Future. Mark him.',
     now() - interval '2 days 10 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000011', v_me, 'personal', 'text',
     'Captain''s job is 30% strategy, 70% reminding the team to drink water.',
     now() - interval '2 days 2 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000012', v_zaid, 'personal', 'text',
     'Bahawalpur Bears recruiting all-rounders for the autumn season. DM if you''re in or know someone.',
     now() - interval '1 day 18 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000013', v_hassan, 'personal', 'text',
     'Watched a kid hit six sixes in an over yesterday. Bowler is fine. He''ll be fine. He WILL be fine.',
     now() - interval '1 day 9 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000014', v_adeel, 'personal', 'text',
     'Reverse sweep: high-risk, high-reward, infinite-respect. Played one today. It bounced once. I''m calling it a six.',
     now() - interval '20 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000015', v_faraz, 'personal', 'text',
     'Bowling at 10am at Model Town tomorrow if anyone wants to face. Bring a helmet.',
     now() - interval '8 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000016', v_saad, 'personal', 'text',
     'Won the toss, chose to bowl, regretted everything by the third over. Lost by 38 runs.',
     now() - interval '3 hours'),

    -- ── Mid range (8 - 18 days ago) ───────────────────────────────────
    ('20260601-aaaa-aaaa-aaaa-000000000017', v_karim, 'personal', 'text',
     'I''ve decided that I''m going to be a left-arm spinner now. Spent two hours practicing. My elbow disagrees.',
     now() - interval '9 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000018', v_bilal, 'personal', 'text',
     'Result from yesterday: Lions 142/6, Knights 138 all out. Won it off the second-last ball. Karim with the wicket.',
     now() - interval '10 days 4 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000019', v_me, 'personal', 'text',
     'Three things I learned captaining today: trust the seamers in the powerplay, never bowl Yousaf in the death, and bring snacks.',
     now() - interval '11 days 10 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000020', v_usman, 'personal', 'text',
     'Reminder: every cricket coach in Pakistan says "use the crease" without ever explaining what that means.',
     now() - interval '12 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000021', v_yousaf, 'personal', 'text',
     'Match starts in four hours. I''ve already eaten lunch. I now realise this was a tactical error.',
     now() - interval '13 days 8 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000022', v_faraz, 'personal', 'text',
     'Watched a 60-over match end in a tie. Greatest day of my life. The ground had no scoreboard. We counted in our heads.',
     now() - interval '14 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000023', v_zaid, 'personal', 'text',
     'Helmet sponsorship update: my nephew offered me his old one in exchange for a chocolate bar. Best deal of my career.',
     now() - interval '15 days 6 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000024', v_adeel, 'personal', 'text',
     'There is no thrill on earth like running between the wickets with someone who isn''t calling.',
     now() - interval '16 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000025', v_hassan, 'personal', 'text',
     'Got out for 0 today. Came back. Made 47 in the second innings. Cricket is cinema.',
     now() - interval '17 days 9 hours'),

    -- ── Older (19 - 30 days ago) ──────────────────────────────────────
    ('20260601-aaaa-aaaa-aaaa-000000000026', v_saad, 'personal', 'text',
     'Asked our umpire how he calls leg-byes. He said "I just see if the batter looks guilty." 10/10 system.',
     now() - interval '20 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000027', v_karim, 'personal', 'text',
     'Lost the only good ball at the ground today. Match abandoned at 14.3 overs. We''re calling it a draw.',
     now() - interval '22 days 4 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000028', v_me, 'personal', 'text',
     'Trying to convince the team that wicket-keeping is a privilege, not a punishment. Mixed reception.',
     now() - interval '24 days'),
    ('20260601-aaaa-aaaa-aaaa-000000000029', v_bilal, 'personal', 'text',
     'Stepped on the ball during my run-up. Stepped on the ball during the next ball. Stepped on the ball a third time. Bowled overs anyway.',
     now() - interval '26 days 7 hours'),
    ('20260601-aaaa-aaaa-aaaa-000000000030', v_usman, 'personal', 'text',
     'New year, same cover drive. I''m at peace with this.',
     now() - interval '28 days')
  on conflict (post_id) do nothing;

  raise notice 'seed_posts.sql: % active posts in the feed',
    (select count(*) from public.posts where status = 'active');
end
$seed_posts$;

-- =============================================================================
-- Cleanup (run from a SQL editor if you want to reset, NOT auto-run):
-- =============================================================================
-- delete from public.posts
--  where post_id::text like '20260601-aaaa-aaaa-aaaa-%';
-- =============================================================================
