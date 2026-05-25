-- =============================================================================
-- Seed the full notification feed for user 9686500d-5c94-49ff-b4da-c3727d609d46.
--
-- Covers all 12 notification_type enum values:
--   Trigger-driven (real fan-out path):
--     follow, post_like, post_comment, comment_reply, mention
--   Direct-inserted (the producing trigger lives in another domain migration
--   that hasn't seeded test data yet):
--     team_post, tournament_post, match_starting, match_upcoming,
--     stat_milestone, claim_decision, team_invitation
--
-- Run:
--   docker exec -i supabase_db_crick psql -U postgres -d postgres \
--     < supabase/seed_notifications.sql
--
-- Idempotent: re-running wipes the previous seed and recreates it.
-- =============================================================================

begin;

do $$
declare
  v_recipient   uuid := '9686500d-5c94-49ff-b4da-c3727d609d46';
  v_actor_1     uuid := '11111111-1111-1111-1111-111111111111'; -- aiden
  v_actor_2     uuid := '22222222-2222-2222-2222-222222222222'; -- priya
  v_actor_3     uuid := '33333333-3333-3333-3333-333333333333'; -- omar

  -- Recipient's existing posts (created earlier via the app).
  v_post_1      uuid := 'aac1c542-2e32-4a10-bcac-775f7ef5ed20';
  v_post_2      uuid := 'd468b072-a501-45da-bfa0-4f849e58f68a';
  v_post_3      uuid := 'c36babfc-cdc2-441a-b552-4f355c550f0a';

  -- Extra post authored by actor_1 — needed so the trigger-driven `mention`
  -- path actually fires (the trigger de-dupes mentions when the mentioned
  -- user is the same as the post-comment recipient).
  v_actor_post  uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  -- Stable IDs for the entities referenced from non-trigger notifications,
  -- so re-running this script produces the same payloads.
  v_team_a      uuid := 'cccccccc-cccc-cccc-cccc-aaaaaaaaaaaa';
  v_team_b      uuid := 'cccccccc-cccc-cccc-cccc-bbbbbbbbbbbb';
  v_tournament  uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  v_match_live  uuid := 'eeeeeeee-eeee-eeee-eeee-aaaaaaaaaaaa';
  v_match_soon  uuid := 'eeeeeeee-eeee-eeee-eeee-bbbbbbbbbbbb';
  v_match_done  uuid := 'eeeeeeee-eeee-eeee-eeee-cccccccccccc';
  v_player_id   uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';

  v_top_comment uuid;
begin
  -- ===========================================================================
  -- 1. Actor auth.users → handle_new_auth_user creates profile rows.
  -- ===========================================================================
  insert into auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  )
  values
    ('00000000-0000-0000-0000-000000000000', v_actor_1, 'authenticated', 'authenticated',
     'aiden@test.local', '', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     jsonb_build_object('username','aiden','display_name','Aiden Carter'),
     now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_actor_2, 'authenticated', 'authenticated',
     'priya@test.local', '', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     jsonb_build_object('username','priya','display_name','Priya Sharma'),
     now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_actor_3, 'authenticated', 'authenticated',
     'omar@test.local', '', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     jsonb_build_object('username','omar','display_name','Omar Khan'),
     now(), now(), '', '', '', '')
  on conflict (id) do nothing;

  -- handle_new_auth_user only fills profile fields on first INSERT, so make
  -- the username/display_name deterministic on re-runs.
  update public.profiles set username = 'aiden', display_name = 'Aiden Carter' where user_id = v_actor_1;
  update public.profiles set username = 'priya', display_name = 'Priya Sharma' where user_id = v_actor_2;
  update public.profiles set username = 'omar',  display_name = 'Omar Khan'    where user_id = v_actor_3;

  -- ===========================================================================
  -- 2. Reset prior seed state for determinism.
  --    Order matters: comments cascade-delete the comment_likes/notifications
  --    they spawned, but we still wipe notifications explicitly to clear the
  --    direct-inserted ones too.
  -- ===========================================================================
  delete from public.notifications where recipient_id = v_recipient;
  delete from public.post_likes
    where post_id in (v_post_1, v_post_2, v_post_3, v_actor_post);
  delete from public.comments
    where post_id in (v_post_1, v_post_2, v_post_3, v_actor_post);
  delete from public.posts where post_id = v_actor_post;
  delete from public.follows
    where target_type = 'user' and target_id = v_recipient
      and follower_id in (v_actor_1, v_actor_2, v_actor_3);

  -- ===========================================================================
  -- 3. Extra post by actor_1 — used as the canvas for a real `mention`.
  -- ===========================================================================
  insert into public.posts (post_id, author_id, post_type, text)
  values (v_actor_post, v_actor_1, 'text',
          'Net session at the academy this evening — anyone joining?');

  -- ===========================================================================
  -- 4. follows  → notify_on_follow → 3 × `follow`
  -- ===========================================================================
  insert into public.follows (follower_id, target_type, target_id)
  values
    (v_actor_1, 'user', v_recipient),
    (v_actor_2, 'user', v_recipient),
    (v_actor_3, 'user', v_recipient);

  -- ===========================================================================
  -- 5. post_likes → notify_on_post_like → 3 × `post_like`
  --    (likes on actor_1's post don't notify the recipient — by design.)
  -- ===========================================================================
  insert into public.post_likes (post_id, user_id)
  values
    (v_post_1, v_actor_1),
    (v_post_1, v_actor_2),
    (v_post_2, v_actor_3);

  -- ===========================================================================
  -- 6. Comments → notify_on_comment → post_comment / comment_reply / mention
  -- ===========================================================================

  -- 6a. Top-level comment by actor_2 on recipient's post → `post_comment`.
  insert into public.comments (post_id, author_id, text)
  values (v_post_1, v_actor_2, 'Great shot! What pitch was this on?');

  -- 6b. Top-level comment by actor_1 on a different recipient post → `post_comment`.
  insert into public.comments (post_id, author_id, text)
  values (v_post_2, v_actor_1, 'Clean lines on that drive.');

  -- 6c. Recipient comments on their own post (no notification — self-event).
  --     Used as the parent for the next reply.
  insert into public.comments (post_id, author_id, text)
  values (v_post_1, v_recipient, 'Thanks for the support everyone!')
  returning comment_id into v_top_comment;

  -- 6d. Reply to recipient's own top-level comment → `comment_reply`.
  insert into public.comments (post_id, author_id, parent_comment_id, text)
  values (v_post_1, v_actor_3, v_top_comment, 'Bro you carried that match.');

  -- 6e. Comment by actor_2 on actor_1's post that @mentions recipient
  --     → `mention` (the post-comment recipient is actor_1, so the mention
  --     loop is NOT de-duped against v_recipient).
  insert into public.comments (post_id, author_id, text, mentioned_user_ids)
  values (v_actor_post, v_actor_2,
          '@saran you should come — pitch is rolling well.',
          array[v_recipient]);

  -- 6f. Second mention on a different post for variety.
  insert into public.comments (post_id, author_id, text, mentioned_user_ids)
  values (v_actor_post, v_actor_3,
          '@saran heads up, there is a 6-a-side tournament next weekend.',
          array[v_recipient]);

  -- ===========================================================================
  -- 7. Direct inserts for the 7 non-trigger types in this migration.
  --    Each gets at least one row; some get a couple for filter variety.
  -- ===========================================================================
  insert into public.notifications (recipient_id, type, payload, is_read, created_at)
  values
    -- team_post (×2)
    (v_recipient, 'team_post',
       jsonb_build_object('post_id', v_post_1, 'team_id', v_team_a, 'actor_id', v_actor_1),
       false, now() - interval '2 hours'),
    (v_recipient, 'team_post',
       jsonb_build_object('post_id', v_post_2, 'team_id', v_team_b, 'actor_id', v_actor_2),
       true,  now() - interval '1 day 4 hours'),

    -- tournament_post (×1)
    (v_recipient, 'tournament_post',
       jsonb_build_object('post_id', v_post_3, 'tournament_id', v_tournament, 'actor_id', v_actor_3),
       false, now() - interval '6 hours'),

    -- match_starting (×1) — recent, drives the red "live" tone in the UI
    (v_recipient, 'match_starting',
       jsonb_build_object('match_id', v_match_live),
       false, now() - interval '15 minutes'),

    -- match_upcoming (×2) — one read, one unread
    (v_recipient, 'match_upcoming',
       jsonb_build_object('match_id', v_match_soon),
       false, now() - interval '20 hours'),
    (v_recipient, 'match_upcoming',
       jsonb_build_object('match_id', v_match_done),
       true,  now() - interval '2 days'),

    -- stat_milestone (×2) — different milestones for variety
    (v_recipient, 'stat_milestone',
       jsonb_build_object('milestone', '50_runs', 'match_id', v_match_done),
       false, now() - interval '3 days'),
    (v_recipient, 'stat_milestone',
       jsonb_build_object('milestone', '5_wickets', 'match_id', v_match_done),
       false, now() - interval '3 days 1 hour'),

    -- claim_decision (×1)
    (v_recipient, 'claim_decision',
       jsonb_build_object('decision', 'approved', 'player_id', v_player_id),
       true,  now() - interval '4 days'),

    -- team_invitation (×1)
    (v_recipient, 'team_invitation',
       jsonb_build_object('team_id', v_team_a, 'actor_id', v_actor_2),
       false, now() - interval '5 days');
end$$;

commit;

-- Verify -----------------------------------------------------------------------
select type::text,
       count(*) filter (where not is_read) as unread,
       count(*) filter (where     is_read) as read,
       count(*)                            as total
  from public.notifications
 where recipient_id = '9686500d-5c94-49ff-b4da-c3727d609d46'
 group by type
 order by 1;
