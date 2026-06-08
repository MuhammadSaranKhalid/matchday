-- =============================================================================
-- seed_follows.sql — follow flow test data anchored to YOUR existing account
-- =============================================================================
-- Pairs with #49 (P1 follow button on team page). After running, the user
-- has a mix of:
--   • pre-followed teams        → Team page shows "Following" + check icon
--   • not-yet-followed teams    → Team page shows "Follow" + plus icon
--   • outgoing user follows     → follows table has rows; no UI surface yet
--   • incoming user follows     → triggers notify_on_follow → notifications
--                                 rows for the user, visible in the
--                                 notifications screen
--
-- Anchored to muhammadsarankhalid@gmail.com — fails loudly if your account
-- is absent (e.g. wrong Supabase project, seed run before sign-up).
--
-- Idempotent: re-runs are safe. The (follower_id, target_type, target_id)
-- unique index turns repeat inserts into ON CONFLICT DO NOTHING.
--
-- Prereq: supabase/seed.sql must have been run first (teams + memberships +
-- teammate users). This file only inserts into `follows`.
-- =============================================================================

-- =============================================================================
-- 1) Resolve "me" + the teammate UUIDs we'll reference. The teammate UIDs
--    are the SAME constants used in supabase/seed.sql lines 181-192.
-- =============================================================================

do $seed_follows$
declare
  v_me uuid;
  -- Teammate UIDs (subset of the 9 from supabase/seed.sql).
  v_bilal  constant uuid := '00000000-0000-0000-0000-000000000002';
  v_faraz  constant uuid := '00000000-0000-0000-0000-000000000003';
  v_hassan constant uuid := '00000000-0000-0000-0000-000000000004';
  v_adeel  constant uuid := '00000000-0000-0000-0000-000000000005';

  -- Teams YOU are NOT a member of (full Follow surface). Lifted from
  -- supabase/seed.sql lines 181-192.
  v_karachi_knights   constant uuid := '11111111-1111-1111-1111-111111111104';
  v_multan_mavericks  constant uuid := '11111111-1111-1111-1111-111111111106';
  v_quetta_gladiators constant uuid := '11111111-1111-1111-1111-111111111108';
  v_sialkot_strikers  constant uuid := '1111111a-1111-1111-1111-11111111110a';
  v_faisalabad        constant uuid := '1111111c-1111-1111-1111-11111111110c';
  v_rawalpindi_rams   constant uuid := '1111111d-1111-1111-1111-11111111110d';
  v_bahawalpur_bears  constant uuid := '1111111f-1111-1111-1111-11111111110f';
begin
  select id into v_me
    from auth.users
   where email = 'muhammadsarankhalid@gmail.com';
  if v_me is null then
    raise exception
      'seed_follows.sql: muhammadsarankhalid@gmail.com not found. '
      'Sign in once on this Supabase project (or run seed.sql first).';
  end if;

  -- ─────────────────────────────────────────────────────────────────────
  -- 2) YOU already follow 3 of the 7 stranger teams.
  --    The other 4 stay unfollowed so the Follow button has work to do.
  -- ─────────────────────────────────────────────────────────────────────
  insert into public.follows (follower_id, target_type, target_id, status,
                              notifications_enabled, created_at)
  values
    (v_me, 'team', v_karachi_knights,   'active', true,
     now() - interval '14 days'),
    (v_me, 'team', v_quetta_gladiators, 'active', true,
     now() - interval '9 days'),
    (v_me, 'team', v_rawalpindi_rams,   'active', false,  -- muted notifs
     now() - interval '3 days')
  on conflict (follower_id, target_type, target_id) do nothing;

  -- Stays unfollowed (so you can tap Follow to test the insert path):
  --   v_multan_mavericks, v_sialkot_strikers, v_faisalabad, v_bahawalpur_bears

  -- ─────────────────────────────────────────────────────────────────────
  -- 3) YOU follow 2 teammates (target_type='user'). No client UI surface
  --    yet — these are DB records that exercise the user-target path of
  --    the same code. They DO NOT trigger notifications for you (the
  --    actor); they trigger one notification on each teammate's side.
  -- ─────────────────────────────────────────────────────────────────────
  insert into public.follows (follower_id, target_type, target_id, status,
                              notifications_enabled, created_at)
  values
    (v_me, 'user', v_bilal,  'active', true,  now() - interval '21 days'),
    (v_me, 'user', v_hassan, 'active', true,  now() - interval '12 days')
  on conflict (follower_id, target_type, target_id) do nothing;

  -- ─────────────────────────────────────────────────────────────────────
  -- 4) 3 teammates follow YOU. Each insert fires notify_on_follow →
  --    creates a `notifications` row (type='follow', payload.actor_id =
  --    teammate uid). Lets the notifications screen render the
  --    NotificationType.follow case with real data.
  -- ─────────────────────────────────────────────────────────────────────
  insert into public.follows (follower_id, target_type, target_id, status,
                              notifications_enabled, created_at)
  values
    (v_bilal,  'user', v_me, 'active', true, now() - interval '18 days'),
    (v_hassan, 'user', v_me, 'active', true, now() - interval '11 days'),
    (v_adeel,  'user', v_me, 'active', true, now() - interval '4 days'),
    -- Faraz follows you too but their muting choice is on: tests that
    -- notifications_enabled=false doesn't suppress the followed-on
    -- notification (the column is a follower-side push toggle for FUTURE
    -- pushes about the target's activity, not about the follow event
    -- itself).
    (v_faraz,  'user', v_me, 'active', false, now() - interval '2 days')
  on conflict (follower_id, target_type, target_id) do nothing;

  raise notice 'seed_follows.sql: % follow rows present for user',
    (select count(*) from public.follows where follower_id = v_me);
end
$seed_follows$;

-- =============================================================================
-- Cleanup (run from a SQL editor if you want to reset, NOT auto-run):
-- =============================================================================
-- -- All follows involving YOU (both directions):
-- delete from public.follows
--  where follower_id = (select id from auth.users
--                        where email = 'muhammadsarankhalid@gmail.com')
--     or (target_type = 'user'
--         and target_id = (select id from auth.users
--                           where email = 'muhammadsarankhalid@gmail.com'));
--
-- -- The 4 inbound user-follows above also wrote notification rows; clear
-- -- them too if you want a clean notifications screen:
-- delete from public.notifications
--  where recipient_id = (select id from auth.users
--                         where email = 'muhammadsarankhalid@gmail.com')
--    and type = 'follow';
-- =============================================================================
