-- =============================================================================
-- 0802 · messages — chat ledger + realtime + read receipts + inbox queries
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- The source-of-truth ledger for every line of text in every chat. Soft-
-- deleted (deleted_at) instead of removed so quotes / replies always
-- resolve and an audit of "what was sent here" is possible.
-- =============================================================================

create table public.messages (
  message_id      uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id) on delete cascade,
  sender_id       uuid references public.profiles(user_id) on delete set null,
  body            text not null check (length(body) between 1 and 4000),
  message_type    text not null default 'text',
  payload         jsonb default '{}'::jsonb,
  reply_to_id     uuid references public.messages(message_id) on delete set null,
  created_at      timestamptz not null default now(),
  edited_at       timestamptz,
  deleted_at      timestamptz
);

-- Hot read path: "latest messages in this chat", paginated by created_at.
create index messages_chat_created on public.messages (chat_id, created_at desc);
create index messages_reply_to on public.messages (reply_to_id) where reply_to_id is not null;

alter table public.messages enable row level security;

-- =============================================================================
-- RLS
-- =============================================================================
create policy "messages_read_for_members"
  on public.messages for select
  using (public.is_chat_member(chat_id));

create policy "messages_insert_self"
  on public.messages for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_chat_member(chat_id)
  );

create policy "messages_update_own"
  on public.messages for update
  to authenticated
  using (sender_id = (select auth.uid()))
  with check (
    sender_id = (select auth.uid())
    and (edited_at is null or deleted_at is null)
  );

-- =============================================================================
-- bump_chat_last_message_at — keep the inbox sorted in sync
-- =============================================================================
create or replace function public.bump_chat_last_message_at()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  update public.chats
     set last_message_at = new.created_at,
         updated_at = now()
   where chat_id = new.chat_id;
  return new;
end;
$$;

create trigger messages_after_insert_bump_chat
  after insert on public.messages
  for each row execute function public.bump_chat_last_message_at();

-- =============================================================================
-- RPC: mark_chat_read
-- =============================================================================
create or replace function public.mark_chat_read(p_chat_id uuid)
returns timestamptz
language sql
security definer
set search_path = public, pg_temp
as $$
  update public.chat_members
     set last_read_at = now()
   where chat_id = p_chat_id
     and user_id = (select auth.uid())
     and left_at is null
  returning last_read_at;
$$;

revoke all on function public.mark_chat_read(uuid) from public;
grant execute on function public.mark_chat_read(uuid) to authenticated;

-- =============================================================================
-- RPC: list_my_chats — fast polymorphic inbox query
-- =============================================================================
create or replace function public.list_my_chats()
returns table (
  chat_id                  uuid,
  type                     public.chat_type,
  team_id                  uuid,
  last_message_at          timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz,
  team_name                text,
  team_logo_url            text,
  team_logo_monogram       text,
  team_primary_color       text,
  dm_other_user_id         uuid,
  dm_other_user_name       text,
  dm_other_user_username   text,
  dm_other_user_avatar_url text,
  you_follow               boolean,
  they_follow_you          boolean,
  last_message_body        text,
  last_message_sender_id   uuid,
  last_message_from_me     boolean,
  unread_count             int
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
    c.chat_id,
    c.type,
    c.team_id,
    c.last_message_at,
    c.created_at,
    c.updated_at,
    t.team_name,
    t.logo_url as team_logo_url,
    t.logo_monogram as team_logo_monogram,
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
      select count(*)::int from (
        select 1 from public.messages m
         where m.chat_id = c.chat_id
           and m.created_at > coalesce(cm.last_read_at, 'epoch'::timestamptz)
           and m.sender_id is distinct from v_actor
           and m.deleted_at is null
         limit 100
      ) capped
    ) as unread_count
  from public.chats c
  join public.chat_members cm
    on cm.chat_id = c.chat_id
   and cm.user_id = v_actor
   and cm.left_at is null
  left join public.teams t on t.team_id = c.team_id
  -- For DM chats, join the other participant's profile
  left join lateral (
    select p.user_id, p.display_name, p.username, p.profile_photo_url
      from public.chat_members other_cm
      join public.profiles p on p.user_id = other_cm.user_id
     where other_cm.chat_id = c.chat_id
       and other_cm.user_id <> v_actor
     limit 1
  ) other_p on c.type = 'dm'
  left join lateral (
    select m.body, m.sender_id
      from public.messages m
     where m.chat_id = c.chat_id
       and m.deleted_at is null
     order by m.created_at desc
     limit 1
  ) lm on true
  order by c.last_message_at desc nulls last;
end;
$$;

revoke all on function public.list_my_chats() from public;
grant execute on function public.list_my_chats() to authenticated;
