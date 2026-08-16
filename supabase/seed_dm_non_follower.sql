-- =============================================================================
-- seed_dm_non_follower.sql — Direct Message from a Non-Follower
-- =============================================================================
-- Scenario:
--   A user (e.g. Adeel Saeed, @adeel or a new player Tariq Mehmood) sends a
--   direct message (DM) to the primary logged-in user (Muhammad Saran, @saran).
--   Neither user follows the other (mutual non-followers) to test incoming
--   message requests / non-follower DM conversations.
-- =============================================================================

do $seed_dm$
declare
  v_saran_uid   uuid;
  v_sender_uid  constant uuid := '00000000-0000-0000-0000-000000000005'; -- Adeel Saeed (@adeel)
  v_user_a      uuid;
  v_user_b      uuid;
  v_chat_id     uuid;
  c_chat_id     constant uuid := '40000000-0000-0000-0000-000000000001';
begin
  -- 1) Resolve Primary User ("me")
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;
  if v_saran_uid is null then
    v_saran_uid := '00000000-0000-0000-0000-000000000001'::uuid;
  end if;

  -- 2) Explicitly remove any follow relationship between Saran and Adeel (guarantee non-follower state)
  delete from public.follows
   where (follower_id = v_saran_uid and target_type = 'user' and target_id = v_sender_uid)
      or (follower_id = v_sender_uid and target_type = 'user' and target_id = v_saran_uid);

  -- 3) Determine Canonical Ordering for DM channel
  if v_saran_uid < v_sender_uid then
    v_user_a := v_saran_uid;
    v_user_b := v_sender_uid;
  else
    v_user_a := v_sender_uid;
    v_user_b := v_saran_uid;
  end if;

  -- 4) Check or Create Chat Container
  select chat_id into v_chat_id
    from public.dm_channels
   where user_a = v_user_a and user_b = v_user_b;

  if v_chat_id is null then
    v_chat_id := c_chat_id;

    -- Clean any stale references if re-running
    delete from public.messages where chat_id = v_chat_id;
    delete from public.chat_members where chat_id = v_chat_id;
    delete from public.dm_channels where chat_id = v_chat_id;
    delete from public.chats where chat_id = v_chat_id;

    insert into public.chats (chat_id, type, last_message_at, created_at, updated_at)
    values (v_chat_id, 'dm', now() - interval '10 minutes', now() - interval '2 days', now());

    insert into public.dm_channels (chat_id, user_a, user_b, created_at, accepted_at, accepted_by)
    values (v_chat_id, v_user_a, v_user_b, now() - interval '2 days', null, null);
  else
    update public.dm_channels
       set accepted_at = null,
           accepted_by = null
     where chat_id = v_chat_id;
  end if;

  -- 5) Ensure Chat Memberships (both members present)
  insert into public.chat_members (chat_id, user_id, role, joined_at, last_read_at, left_at)
  values
    (v_chat_id, v_sender_uid, 'member', now() - interval '2 days', now() - interval '10 minutes', null),
    (v_chat_id, v_saran_uid,  'member', now() - interval '2 days', null, null) -- Unread for Saran
  on conflict (chat_id, user_id) do update set
    last_read_at = excluded.last_read_at,
    left_at = null;

  -- 6) Seed 1 Initial Message from Adeel (the non-follower) to Saran (Message Request)
  delete from public.messages where chat_id = v_chat_id;

  insert into public.messages (
    message_id, chat_id, sender_id, body, message_type, payload, created_at
  )
  values
    (
      '41000000-0000-0000-0000-000000000001',
      v_chat_id,
      v_sender_uid,
      'Salam Saran! I saw your post regarding Lahore Lions trials. I am an off-spin all-rounder playing in Faisalabad Premier League. Would love to join the trial session this Tuesday at Model Town.',
      'text',
      '{}'::jsonb,
      now() - interval '25 minutes'
    );

  -- 7) Update chat last_message_at
  update public.chats
     set last_message_at = now() - interval '25 minutes'
   where chat_id = v_chat_id;

end $seed_dm$;

