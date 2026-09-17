-- =============================================================================
-- 20260917000000 · Extend list_my_chats RPC with exact channel member horizons
-- =============================================================================
-- Exposes last_read_message_seq, last_read_at, last_delivered_message_seq,
-- and last_delivered_at from channel_members so clients receive authoritative
-- horizons without estimating them via (last_message_seq - unread_count).
-- =============================================================================

drop function if exists public.list_my_chats();

create or replace function public.list_my_chats()
returns table (
  chat_id                    uuid,
  channel_key                text,
  kind                       public.chat_channel_kind,
  context_type               public.chat_channel_context,
  team_id                    uuid,
  match_id                   uuid,
  last_message_seq           bigint,
  last_message_at            timestamptz,
  created_at                 timestamptz,
  updated_at                 timestamptz,
  title                      text,
  team_name                  text,
  team_logo_url              text,
  team_logo_monogram         text,
  team_primary_color         text,
  dm_other_user_id           uuid,
  dm_other_user_name         text,
  dm_other_user_username     text,
  dm_other_user_avatar_url   text,
  you_follow                 boolean,
  they_follow_you            boolean,
  last_message_body          text,
  last_message_sender_id     uuid,
  last_message_from_me       boolean,
  unread_count               int,
  is_accepted                boolean,
  is_pinned                  boolean,
  is_archived                boolean,
  is_muted                   boolean,
  last_read_message_seq      bigint,
  last_read_at               timestamptz,
  last_delivered_message_seq bigint,
  last_delivered_at          timestamptz
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    return;
  end if;

  return query
  select
    cc.channel_id as chat_id,
    cc.channel_key,
    cc.kind,
    cc.context_type,
    cc.team_id,
    cc.match_id,
    cc.last_message_seq,
    cc.last_message_at,
    cc.created_at,
    cc.updated_at,
    -- Title resolution
    case
      when cc.kind = 'direct' then other_p.display_name
      when cc.context_type = 'team' then t.team_name
      when cc.context_type = 'match' then coalesce(mt_a.team_name, 'Team A') || ' vs ' || coalesce(mt_b.team_name, 'Team B')
      else cc.title
    end as title,
    t.team_name,
    t.logo_url as team_logo_url,
    case
      when cc.context_type = 'team' then t.logo_monogram
      when cc.context_type = 'match' then 'VS'
      else null
    end as team_logo_monogram,
    (t.team_colors->>'primary') as team_primary_color,
    other_p.user_id as dm_other_user_id,
    other_p.display_name as dm_other_user_name,
    other_p.username as dm_other_user_username,
    other_p.profile_photo_url as dm_other_user_avatar_url,
    case
      when other_p.user_id is not null then
        exists (
          select 1 from public.follows
           where follower_id = v_actor
             and target_type = 'user'
             and target_id = other_p.user_id
        )
      else false
    end as you_follow,
    case
      when other_p.user_id is not null then
        exists (
          select 1 from public.follows
           where follower_id = other_p.user_id
             and target_type = 'user'
             and target_id = v_actor
        )
      else false
    end as they_follow_you,
    lm.body as last_message_body,
    lm.sender_id as last_message_sender_id,
    (lm.sender_id is not distinct from v_actor)::boolean as last_message_from_me,
    (
      select count(*)::int
        from public.messages m
       where m.channel_id = cc.channel_id
         and m.message_seq > coalesce(cm.last_read_message_seq, 0)
         and m.sender_id is distinct from v_actor
         and m.deleted_at is null
         and m.counts_as_unread = true
    ) as unread_count,
    (cm.status = 'active') as is_accepted,
    (cm.pinned_at is not null) as is_pinned,
    (cm.archived_at is not null) as is_archived,
    (cm.notifications_muted_until is not null and cm.notifications_muted_until > now()) as is_muted,
    cm.last_read_message_seq,
    cm.last_read_at,
    cm.last_delivered_message_seq,
    cm.last_delivered_at
  from public.chat_channels cc
  join public.channel_members cm
    on cm.channel_id = cc.channel_id
   and cm.user_id = v_actor
   and cm.status in ('active', 'pending')
  left join public.teams t on t.team_id = cc.team_id
  left join public.matches m on m.match_id = cc.match_id and cc.context_type = 'match'
  left join public.match_teams mt_a on mt_a.match_id = m.match_id and mt_a.team_side = 'team_a'
  left join public.match_teams mt_b on mt_b.match_id = m.match_id and mt_b.team_side = 'team_b'
  -- Direct message other participant lookup
  left join lateral (
    select p.user_id, p.display_name, p.username, p.profile_photo_url
      from public.channel_members other_cm
      join public.profiles p on p.user_id = other_cm.user_id
     where other_cm.channel_id = cc.channel_id
       and other_cm.user_id <> v_actor
     limit 1
  ) other_p on cc.kind = 'direct'
  -- Latest message lookup
  left join lateral (
    select m2.body, m2.sender_id
      from public.messages m2
     where m2.channel_id = cc.channel_id
       and m2.deleted_at is null
     order by m2.message_seq desc
     limit 1
  ) lm on true
  order by
    (cm.pinned_at is not null) desc,
    cc.last_message_at desc nulls last,
    cc.created_at desc;
end;
$$;

revoke all on function public.list_my_chats() from public;
grant execute on function public.list_my_chats() to authenticated;
