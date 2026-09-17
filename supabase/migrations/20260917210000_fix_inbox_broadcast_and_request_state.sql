-- =============================================================================
-- 20260917210000 · Fix Realtime Inbox Broadcast and DM Request State
-- =============================================================================
-- 1. Broadcasts to Ably user:<userId>:chat (matching client subscription and spec).
-- 2. Includes pending members in the broadcast loop so DM recipients receive request events.
-- 3. Exposes dm_other_member_status in list_my_chats() for accurate pending request state.
-- =============================================================================

-- 1. Broadcast Message Created (Updated Ably user channel & membership status filter)
create or replace function public.broadcast_message_to_ably()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  v_auth_header text;
  v_payload jsonb;
  v_sender_name text;
  v_sender_avatar text;
  v_sender_username text;
  v_member record;
begin
  v_auth_header := private.get_ably_auth_header();
  if v_auth_header is null then
    return new;
  end if;

  select display_name, profile_photo_url, username
    into v_sender_name, v_sender_avatar, v_sender_username
    from public.profiles
   where user_id = new.sender_id;

  v_payload := jsonb_build_object(
    'message_id', new.message_id,
    'channel_id', new.channel_id,
    'sender_id', new.sender_id,
    'sender_name', v_sender_name,
    'sender_avatar_url', v_sender_avatar,
    'sender_username', v_sender_username,
    'message_type', new.message_type,
    'body', new.body,
    'payload', new.payload,
    'reply_to_message_id', new.reply_to_message_id,
    'message_seq', new.message_seq,
    'version', new.version,
    'created_at', new.created_at
  );

  perform net.http_post(
    url := 'https://rest.ably.io/channels/chat:' || new.channel_id || '/messages',
    headers := jsonb_build_object(
      'Authorization', v_auth_header,
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'name', 'message.created',
      'data', v_payload::text
    )
  );

  -- Broadcast inbox update to both active and pending channel members
  for v_member in
    select user_id
      from public.channel_members
     where channel_id = new.channel_id
       and status in ('active', 'pending')
       and user_id <> coalesce(new.sender_id, '00000000-0000-0000-0000-000000000000'::uuid)
  loop
    perform net.http_post(
      url := 'https://rest.ably.io/channels/user:' || v_member.user_id || ':chat/messages',
      headers := jsonb_build_object(
        'Authorization', v_auth_header,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'name', 'channel.updated',
        'data', jsonb_build_object(
          'channel_id', new.channel_id,
          'last_message_seq', new.message_seq,
          'last_message_body', new.body,
          'last_message_at', new.created_at,
          'sender_id', new.sender_id,
          'sender_name', v_sender_name
        )::text
      )
    );
  end loop;

  return new;
end;
$$;

-- 2. Authoritative list_my_chats with dm_other_member_status
drop function if exists public.list_my_chats();
create or replace function public.list_my_chats()
returns table (
  channel_id                 uuid,
  channel_key                text,
  kind                       public.chat_channel_kind,
  context_type               public.chat_channel_context,
  title                      text,
  avatar_url                 text,
  team_id                    uuid,
  match_id                   uuid,
  tournament_id              uuid,
  team_name                  text,
  team_logo_url              text,
  team_logo_monogram         text,
  team_primary_color         text,
  is_accepted                boolean,
  unread_count               bigint,
  last_message_seq           bigint,
  last_message_body          text,
  last_message_at            timestamptz,
  last_message_sender_id     uuid,
  last_message_from_me       boolean,
  last_read_message_seq      bigint,
  last_read_at               timestamptz,
  last_delivered_message_seq bigint,
  last_delivered_at          timestamptz,
  is_pinned                  boolean,
  pinned_at                  timestamptz,
  is_archived                boolean,
  archived_at                timestamptz,
  is_muted                   boolean,
  notifications_muted_until  timestamptz,
  dm_other_user_id           uuid,
  dm_other_user_name         text,
  dm_other_user_username     text,
  dm_other_user_avatar_url   text,
  dm_other_member_status     text,
  they_follow_you            boolean,
  you_follow                 boolean,
  created_at                 timestamptz,
  updated_at                 timestamptz
)
language sql
security definer
stable
set search_path = public, auth, pg_temp
as $$
  select
    c.channel_id,
    c.channel_key,
    c.kind,
    c.context_type,
    case
      when c.kind = 'direct' then dm_user.display_name
      when c.context_type = 'team' then t.team_name
      when c.context_type = 'tournament' then tourn.tournament_name
      else c.title
    end as title,
    case
      when c.kind = 'direct' then dm_user.profile_photo_url
      when c.context_type = 'team' then t.logo_url
      when c.context_type = 'tournament' then tourn.logo_url
      else c.avatar_url
    end as avatar_url,
    c.team_id,
    c.match_id,
    c.tournament_id,
    t.team_name,
    t.logo_url as team_logo_url,
    t.logo_monogram as team_logo_monogram,
    (t.team_colors->>'primary') as team_primary_color,
    (m.status = 'active') as is_accepted,
    coalesce((
      select count(*)
      from public.messages msg
      where msg.channel_id = c.channel_id
        and msg.message_seq > coalesce(m.last_read_message_seq, 0)
        and msg.sender_id <> (select auth.uid())
        and msg.counts_as_unread = true
        and msg.deleted_at is null
    ), 0) as unread_count,
    c.last_message_seq,
    last_msg.body as last_message_body,
    c.last_message_at,
    last_msg.sender_id as last_message_sender_id,
    (last_msg.sender_id = (select auth.uid())) as last_message_from_me,
    m.last_read_message_seq,
    m.last_read_at,
    m.last_delivered_message_seq,
    m.last_delivered_at,
    (m.pinned_at is not null) as is_pinned,
    m.pinned_at,
    (m.archived_at is not null) as is_archived,
    m.archived_at,
    (m.notifications_muted_until is not null and m.notifications_muted_until > now()) as is_muted,
    m.notifications_muted_until,
    dm_user.user_id as dm_other_user_id,
    dm_user.display_name as dm_other_user_name,
    dm_user.username as dm_other_user_username,
    dm_user.profile_photo_url as dm_other_user_avatar_url,
    dm_other.dm_other_member_status,
    coalesce(tf.they_follow, false) as they_follow_you,
    coalesce(yf.you_follow, false) as you_follow,
    c.created_at,
    c.updated_at
  from public.channel_members m
  join public.chat_channels c on c.channel_id = m.channel_id
  left join public.teams t on t.team_id = c.team_id
  left join public.tournaments tourn on tourn.tournament_id = c.tournament_id
  left join lateral (
    select cm_other.user_id, cm_other.status::text as dm_other_member_status
    from public.channel_members cm_other
    where cm_other.channel_id = c.channel_id
      and cm_other.user_id <> (select auth.uid())
      and c.kind = 'direct'
    limit 1
  ) dm_other on true
  left join public.profiles dm_user on dm_user.user_id = dm_other.user_id
  left join lateral (
    select exists (
      select 1 from public.follows f
      where f.follower_id = dm_other.user_id
        and f.target_type = 'user'
        and f.target_id = (select auth.uid())
    ) as they_follow
  ) tf on true
  left join lateral (
    select exists (
      select 1 from public.follows f
      where f.follower_id = (select auth.uid())
        and f.target_type = 'user'
        and f.target_id = dm_other.user_id
    ) as you_follow
  ) yf on true
  left join lateral (
    select msg.body, msg.sender_id
    from public.messages msg
    where msg.channel_id = c.channel_id
      and msg.deleted_at is null
    order by msg.message_seq desc
    limit 1
  ) last_msg on true
  where m.user_id = (select auth.uid())
    and m.status in ('active', 'pending')
  order by
    (m.pinned_at is not null) desc,
    coalesce(c.last_message_at, c.created_at) desc;
$$;

revoke all on function public.list_my_chats() from public;
grant execute on function public.list_my_chats() to authenticated;
