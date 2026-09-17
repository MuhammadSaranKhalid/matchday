-- =============================================================================
-- seed_dm_non_follower.sql — Direct Message from a Non-Follower
-- =============================================================================
-- Scenario:
--   A user (e.g. Adeel Saeed, @adeel) sends a direct message (DM) to the primary
--   user (Muhammad Saran, @saran).
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
  v_channel_key text;
begin
  -- 1) Resolve Primary User ("me")
  select id into v_saran_uid from auth.users where email = 'muhammadsarankhalid@gmail.com' limit 1;
  if v_saran_uid is null then
    select user_id into v_saran_uid from public.profiles limit 1;
  end if;
  if v_saran_uid is null then
    v_saran_uid := '00000000-0000-0000-0000-000000000001'::uuid;
  end if;

  -- 2) Remove any follow relationship
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

  v_channel_key := 'dm:' || v_user_a::text || ':' || v_user_b::text;

  -- 4) Check or Create Chat Container
  select channel_id into v_chat_id
    from public.chat_channels
   where channel_key = v_channel_key;

  if v_chat_id is null then
    v_chat_id := c_chat_id;

    delete from public.messages where channel_id = v_chat_id;
    delete from public.channel_members where channel_id = v_chat_id;
    delete from public.chat_channels where channel_id = v_chat_id;

    insert into public.chat_channels (
      channel_id, channel_key, kind, context_type, visibility, created_by,
      last_message_at, created_at, updated_at
    )
    values (
      v_chat_id, v_channel_key, 'direct', 'none', 'private', v_sender_uid,
      now() - interval '25 minutes', now() - interval '2 days', now()
    );

    insert into public.channel_policies (channel_id) values (v_chat_id) on conflict do nothing;
  end if;

  -- 5) Ensure Channel Memberships (Saran is pending, Adeel is active)
  insert into public.channel_members (
    channel_id, user_id, role, status, invited_by, invited_at, joined_at, last_read_at, left_at
  )
  values
    (v_chat_id, v_sender_uid, 'member', 'active', v_sender_uid, now() - interval '2 days', now() - interval '2 days', now() - interval '10 minutes', null),
    (v_chat_id, v_saran_uid,  'member', 'pending', v_sender_uid, now() - interval '2 days', null, null, null)
  on conflict (channel_id, user_id) do update set
    status = excluded.status,
    last_read_at = excluded.last_read_at,
    left_at = null;

  -- 6) Seed 1 Initial Message from Adeel (Message Request)
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

  -- 7) Update channel last_message_at
  update public.chat_channels
     set last_message_at = now() - interval '25 minutes'
   where channel_id = v_chat_id;

end $seed_dm$;
