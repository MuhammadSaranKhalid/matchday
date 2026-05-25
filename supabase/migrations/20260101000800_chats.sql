-- =============================================================================
-- 0800 · chats / chat_members / messages
-- =============================================================================
-- Group chat for teams. Lifecycle is fully driven from `teams` and
-- `team_members` via triggers — app code never has to remember to create
-- a chat or add a member; the source-of-truth tables do it automatically:
--
--   • teams INSERT          → chat created, owner added as admin
--   • team_members INSERT   → claimed user added as member (skip unclaimed)
--   • team_members UPDATE   → status active↔inactive flips chat membership;
--                             unclaimed→claimed cascade adds new claimer
--
-- v1 scope: text-only messages, group chats only, team-bound only. The
-- `chat_type` enum has room for `dm` and `tournament` later. System
-- messages (joined / left / match-start) are layered on later via a
-- nullable sender_id; for v1 every message has a real sender.
-- =============================================================================

create type public.chat_type as enum ('team');

-- -----------------------------------------------------------------------------
-- chats
-- -----------------------------------------------------------------------------
create table public.chats (
  chat_id          uuid primary key default gen_random_uuid(),
  type             public.chat_type not null,
  team_id          uuid references public.teams(team_id) on delete cascade,
  -- Denormalised so the inbox can sort by recency without a JOIN/aggregate.
  -- Updated by the messages-after-insert trigger below.
  last_message_at  timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  constraint chats_team_team_id_required check (
    (type = 'team' and team_id is not null)
  )
);

-- One chat per team. Partial unique index (room for non-team chats later).
create unique index chats_team_unique
  on public.chats (team_id)
  where team_id is not null;

create index chats_last_message_at on public.chats (last_message_at desc nulls last);

create trigger chats_set_updated_at
  before update on public.chats
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- chat_members
-- -----------------------------------------------------------------------------
create type public.chat_role as enum ('admin', 'member');

create table public.chat_members (
  membership_id   uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id) on delete cascade,
  user_id         uuid not null references public.profiles(user_id) on delete cascade,
  role            public.chat_role not null default 'member',
  joined_at       timestamptz not null default now(),
  -- When set, the user has left (or been removed). We keep the row so they
  -- can still read history they were part of.
  left_at         timestamptz,
  last_read_at    timestamptz,

  constraint chat_members_user_unique unique (chat_id, user_id)
);

create index chat_members_chat on public.chat_members (chat_id);
create index chat_members_user on public.chat_members (user_id);

-- -----------------------------------------------------------------------------
-- messages
-- -----------------------------------------------------------------------------
create table public.messages (
  message_id      uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id) on delete cascade,
  -- Nullable so a deleted profile doesn't drop messages — the row stays
  -- with sender_id = null and the UI renders "Deleted user".
  sender_id       uuid references public.profiles(user_id) on delete set null,
  body            text not null check (length(body) between 1 and 2000),
  created_at      timestamptz not null default now(),
  edited_at       timestamptz,
  deleted_at      timestamptz
);

create index messages_chat_created on public.messages (chat_id, created_at desc);

-- =============================================================================
-- RLS
-- =============================================================================
alter table public.chats enable row level security;
alter table public.chat_members enable row level security;
alter table public.messages enable row level security;

-- Helper: am I a current member of this chat? SECURITY DEFINER so it can
-- read chat_members regardless of the caller's RLS context (avoids
-- recursion when chat_members policies reference the function).
create or replace function public.is_chat_member(p_chat_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select exists (
    select 1 from public.chat_members cm
    where cm.chat_id = p_chat_id
      and cm.user_id = (select auth.uid())
      and cm.left_at is null
  );
$$;

revoke all on function public.is_chat_member(uuid) from public;
grant execute on function public.is_chat_member(uuid) to authenticated;

-- ----- chats -----
create policy "chats_read_members"
  on public.chats for select
  using (public.is_chat_member(chat_id));

-- Inserts are done by the trigger (security definer), not user-facing.
-- Updates: admins only. Identified via chat_members.role = 'admin'.
create policy "chats_update_admin"
  on public.chats for update
  to authenticated
  using (
    exists (
      select 1 from public.chat_members
      where chat_members.chat_id = chats.chat_id
        and chat_members.user_id = (select auth.uid())
        and chat_members.role = 'admin'
        and chat_members.left_at is null
    )
  );

-- ----- chat_members -----
create policy "chat_members_read_self_or_chat"
  on public.chat_members for select
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(chat_id)
  );

-- Update your own row (last_read_at) or any row in a chat where you're admin.
create policy "chat_members_update_self_or_admin"
  on public.chat_members for update
  to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.chat_members admin
      where admin.chat_id = chat_members.chat_id
        and admin.user_id = (select auth.uid())
        and admin.role = 'admin'
        and admin.left_at is null
    )
  );

-- ----- messages -----
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

-- Edit / soft-delete only your own messages. An update may flip exactly one
-- of edited_at / deleted_at (XOR) so a single statement can't soft-delete
-- and "edit" simultaneously.
create policy "messages_update_own"
  on public.messages for update
  to authenticated
  using (sender_id = (select auth.uid()))
  with check (
    sender_id = (select auth.uid())
    and (edited_at is null or deleted_at is null)
  );

-- =============================================================================
-- Lifecycle triggers — keep chat membership in lock-step with team_members.
-- =============================================================================

-- 1. teams INSERT → create chat and add owner as admin.
create or replace function public.create_team_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  insert into public.chats (type, team_id)
  values ('team', new.team_id)
  returning chat_id into v_chat_id;

  insert into public.chat_members (chat_id, user_id, role)
  values (v_chat_id, new.owner_id, 'admin');

  return new;
end;
$$;

create trigger teams_after_insert_create_chat
  after insert on public.teams
  for each row execute function public.create_team_chat();

-- 2. team_members INSERT → add claimed members to chat.
create or replace function public.add_team_member_to_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  if new.user_id is null then return new; end if;       -- skip unclaimed
  if new.status <> 'active' then return new; end if;

  select chat_id into v_chat_id
  from public.chats
  where team_id = new.team_id and type = 'team';
  if v_chat_id is null then return new; end if;

  insert into public.chat_members (chat_id, user_id, role)
  values (v_chat_id, new.user_id, 'member')
  on conflict (chat_id, user_id)
  do update set left_at = null;  -- re-add if previously left

  return new;
end;
$$;

create trigger team_members_after_insert_add_to_chat
  after insert on public.team_members
  for each row execute function public.add_team_member_to_chat();

-- 3. team_members UPDATE → handle status flips and the unclaimed→claimed
--    cascade (which UPDATEs the row to set user_id).
create or replace function public.sync_team_member_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  if new.user_id is null then return new; end if;       -- still unclaimed

  select chat_id into v_chat_id
  from public.chats
  where team_id = new.team_id and type = 'team';
  if v_chat_id is null then return new; end if;

  -- Status flipped to active (either from inactive, or from a fresh
  -- claim cascade where user_id was just set) → ensure membership row.
  if new.status = 'active' and (
       old.status <> 'active'
       or (old.user_id is null and new.user_id is not null)
     ) then
    insert into public.chat_members (chat_id, user_id, role)
    values (v_chat_id, new.user_id, 'member')
    on conflict (chat_id, user_id)
    do update set left_at = null;
  end if;

  -- Status flipped to non-active → mark left (keep row for history read).
  if new.status <> 'active' and old.status = 'active' then
    update public.chat_members
    set left_at = now()
    where chat_id = v_chat_id and user_id = new.user_id and left_at is null;
  end if;

  return new;
end;
$$;

create trigger team_members_after_update_sync_chat
  after update on public.team_members
  for each row execute function public.sync_team_member_chat();

-- 4. messages INSERT → bump the chat's last_message_at for inbox sorting.
create or replace function public.bump_chat_last_message_at()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  update public.chats
  set last_message_at = new.created_at,
      updated_at = new.created_at
  where chat_id = new.chat_id;
  return new;
end;
$$;

create trigger messages_after_insert_bump_chat
  after insert on public.messages
  for each row execute function public.bump_chat_last_message_at();

-- =============================================================================
-- Backfill existing teams and team_members.
-- =============================================================================

-- Create chats for any existing team that doesn't have one.
insert into public.chats (type, team_id)
select 'team', t.team_id
from public.teams t
where not exists (
  select 1 from public.chats c where c.team_id = t.team_id and c.type = 'team'
);

-- Add owners as admins.
insert into public.chat_members (chat_id, user_id, role)
select c.chat_id, t.owner_id, 'admin'
from public.chats c
join public.teams t on t.team_id = c.team_id
where c.type = 'team'
on conflict (chat_id, user_id) do update set role = 'admin';

-- Add existing claimed active members.
insert into public.chat_members (chat_id, user_id, role)
select c.chat_id, tm.user_id, 'member'
from public.chats c
join public.team_members tm on tm.team_id = c.team_id
where c.type = 'team'
  and tm.user_id is not null
  and tm.status = 'active'
on conflict (chat_id, user_id) do nothing;

-- =============================================================================
-- Realtime — Broadcast on every new message.
-- =============================================================================
-- Two channels per message:
--   1. chat:<chat_id>:messages         — ONE publish, hot stream for anyone
--                                        currently on this chat's screen
--   2. user:<member_id>:notifications  — small `chat_updated` ping per other
--                                        member for chat-list badges/unread
--
-- The hot stream cost is constant in group size; the per-member ping fans
-- out but with a tiny payload. Both run AFTER INSERT inside the original
-- transaction so a reader's immediate row fetch always sees the new row.
-- =============================================================================

-- Index supporting the per-message member fan-out below. Partial: only
-- active memberships participate, so the index stays small.
create index if not exists chat_members_active_chat_user
  on public.chat_members (chat_id, user_id)
  where left_at is null;

create or replace function public.broadcast_new_message()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_member_id uuid;
  v_payload   jsonb;
  v_preview   text;
begin
  -- Hot stream payload — mirrors the shape the chat screen renders so the
  -- Flutter side can swap data sources without reshaping its model.
  v_payload := jsonb_build_object(
    'message_id', new.message_id,
    'chat_id',    new.chat_id,
    'sender_id',  new.sender_id,
    'body',       new.body,
    'created_at', new.created_at
  );

  perform realtime.send(
    v_payload,
    'new_message',
    'chat:' || new.chat_id::text || ':messages',
    true
  );

  -- Lightweight per-member ping for chat-list badge / unread updates.
  -- Body capped at 160 chars; the chat screen reads the full body from
  -- the hot stream above.
  v_preview := left(new.body, 160);

  for v_member_id in
    select user_id
    from public.chat_members
    where chat_id = new.chat_id
      and user_id is not null
      and user_id is distinct from new.sender_id
      and left_at is null
  loop
    perform realtime.send(
      jsonb_build_object(
        'chat_id',      new.chat_id,
        'message_id',   new.message_id,
        'sender_id',    new.sender_id,
        'body_preview', v_preview,
        'created_at',   new.created_at
      ),
      'chat_updated',
      'user:' || v_member_id::text || ':notifications',
      true
    );
  end loop;

  return null;
end;
$$;

revoke all on function public.broadcast_new_message() from public;

drop trigger if exists messages_after_insert_broadcast on public.messages;

create trigger messages_after_insert_broadcast
  after insert on public.messages
  for each row execute function public.broadcast_new_message();


-- =============================================================================
-- Push fan-out for chat messages (FCM/APNs via the send-push Edge Function).
-- =============================================================================
-- Mirrors `invoke_send_push` in 0900_device_tokens.sql but with a
-- `message_id` payload. The Edge Function looks up active chat members
-- (excluding the sender) and pushes to every device they're signed in on.
--
-- This is the BACKGROUND delivery path. While the recipient is foregrounded,
-- the chat:<id>:messages Broadcast covers in-app rendering and FCM silences
-- the OS banner (configured in lib/core/push/push_service.dart).
--
-- Depends on `vault.decrypted_secrets` containing supabase_url +
-- service_role_key. See migration 0900 for the bootstrap notes.
-- =============================================================================
create or replace function public.invoke_send_push_message()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault, pg_temp
as $$
declare
  v_url text;
  v_key text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'supabase_url' limit 1;
  select decrypted_secret into v_key
    from vault.decrypted_secrets where name = 'service_role_key' limit 1;

  if v_url is null or v_key is null then
    raise warning
      '[invoke_send_push_message] vault secrets missing (url_present=%, key_present=%)',
      v_url is not null, v_key is not null;
    return new;
  end if;

  perform net.http_post(
    url     := rtrim(v_url, '/') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'content-type',  'application/json',
      'authorization', 'Bearer ' || v_key
    ),
    body    := jsonb_build_object('message_id', new.message_id)
  );
  return new;
exception
  when others then
    -- Never let push delivery failures abort the message insert. The
    -- in-app Broadcast already covers the foreground case; a failed push
    -- only affects backgrounded recipients for this one message.
    raise warning '[invoke_send_push_message] failed for message_id=%: %',
      new.message_id, sqlerrm;
    return new;
end;
$$;

drop trigger if exists messages_invoke_send_push on public.messages;

create trigger messages_invoke_send_push
  after insert on public.messages
  for each row execute function public.invoke_send_push_message();
