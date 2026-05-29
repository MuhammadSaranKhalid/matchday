-- =============================================================================
-- 0801 · chat_members — the participant list + the chat-access predicate
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- One row per (chat, user). Carries the user's role in the chat (admin /
-- member), join time, last-read marker, and a soft-left timestamp.
--
-- Keeping `left_at` rather than deleting the row preserves historical
-- access — a user who left a team can still read the chat history they
-- were part of without re-joining giving them the cliff edge.
--
-- WHY THE chats RLS LIVES IN THIS FILE
-- ------------------------------------
-- The chats SELECT and UPDATE policies depend on `is_chat_member()`,
-- which queries this table. Declaring the helper + the policies here
-- (instead of in 0800) avoids a forward reference.
--
-- LIFECYCLE TRIGGERS
-- ------------------
-- Two AFTER triggers on team_members keep chat membership in lock-step
-- with team membership:
--
--   add_team_member_to_chat   AFTER INSERT on team_members
--     ↳ inserts the user into the team's chat (skipping unclaimed
--       placeholders since they don't have an auth identity).
--
--   sync_team_member_chat     AFTER UPDATE on team_members
--     ↳ handles two cases:
--       * status flipped to/from 'active' — toggles left_at.
--       * unclaimed → claimed cascade (user_id was just set, the row's
--         status is active) — inserts the new claimer into the chat.
-- =============================================================================

create type public.chat_role as enum ('admin', 'member');

create table public.chat_members (
  membership_id   uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id)    on delete cascade,
  -- ON DELETE CASCADE so a profile delete (delete_user RPC in 0700)
  -- removes the user's chat memberships cleanly.
  user_id         uuid not null references public.profiles(user_id) on delete cascade,
  role            public.chat_role not null default 'member',
  joined_at       timestamptz not null default now(),
  -- Set when the user leaves (or is removed). The row stays so they can
  -- still read history. NULL means active membership.
  left_at         timestamptz,
  -- Per-member read marker. The unread badge query is
  -- (last_message_at > last_read_at) ON the chats row.
  last_read_at    timestamptz,

  constraint chat_members_user_unique unique (chat_id, user_id)
);

create index chat_members_chat on public.chat_members (chat_id);
create index chat_members_user on public.chat_members (user_id);

-- Partial index supporting the per-message member fan-out in 0802. Only
-- active memberships participate in the broadcast loop, so a partial
-- index keeps it small.
create index chat_members_active_chat_user
  on public.chat_members (chat_id, user_id)
  where left_at is null;

alter table public.chat_members enable row level security;

-- =============================================================================
-- is_chat_member — the central "may I see this chat?" predicate
-- =============================================================================
-- SECURITY DEFINER so it can read chat_members regardless of the
-- caller's own RLS context (preventing the recursion that would
-- otherwise occur when chat_members policies reference the function
-- and the function queries chat_members).
--
-- Returns true if (and only if) the calling auth.uid() has an active
-- (left_at IS NULL) membership in the given chat.
-- =============================================================================
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

-- =============================================================================
-- chats RLS — declared here because it needs is_chat_member
-- =============================================================================
-- READ: any active member of the chat.
-- UPDATE: any active admin of the chat (currently no UPDATE-able
-- columns are exposed to the client; the policy is preventative).
-- INSERT: no policy — chats are created by create_team_chat (0800),
-- a SECURITY DEFINER trigger that bypasses RLS.
-- DELETE: no policy — chats are torn down via teams.cascade.
-- =============================================================================
create policy "chats_read_members"
  on public.chats for select
  using (public.is_chat_member(chat_id));

create policy "chats_update_admin"
  on public.chats for update
  to authenticated
  using (
    exists (
      select 1 from public.chat_members
       where chat_members.chat_id = chats.chat_id
         and chat_members.user_id = (select auth.uid())
         and chat_members.role    = 'admin'
         and chat_members.left_at is null
    )
  );

-- =============================================================================
-- chat_members RLS
-- =============================================================================
-- READ: your own row OR any row in a chat where you're an active member.
-- UPDATE: your own row (typically to bump last_read_at) OR any row in a
-- chat where you're an admin (e.g. promote / kick).
-- INSERT and DELETE: SECURITY DEFINER lifecycle triggers below; no
-- direct user policy.
-- =============================================================================
create policy "chat_members_read_self_or_chat"
  on public.chat_members for select
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(chat_id)
  );

create policy "chat_members_update_self_or_admin"
  on public.chat_members for update
  to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.chat_members admin
       where admin.chat_id = chat_members.chat_id
         and admin.user_id = (select auth.uid())
         and admin.role    = 'admin'
         and admin.left_at is null
    )
  );

-- =============================================================================
-- Lifecycle triggers
-- =============================================================================

-- ---- add_team_member_to_chat ----
-- Triggered on team_members INSERT. For claimed-and-active rows, inserts
-- the user into the team's chat as a regular member. Unclaimed
-- placeholders are skipped (they have no auth identity).
--
-- ON CONFLICT DO UPDATE handles the re-add path: a user who previously
-- left the team and the chat gets `left_at` reset when they re-join.
create or replace function public.add_team_member_to_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  if new.user_id is null then return new; end if;      -- skip unclaimed
  if new.status  <> 'active' then return new; end if;

  select chat_id into v_chat_id
    from public.chats
   where team_id = new.team_id and type = 'team';
  if v_chat_id is null then return new; end if;

  insert into public.chat_members (chat_id, user_id, role)
  values (v_chat_id, new.user_id, 'member')
  on conflict (chat_id, user_id)
  do update set left_at = null;

  return new;
end;
$$;

create trigger team_members_after_insert_add_to_chat
  after insert on public.team_members
  for each row execute function public.add_team_member_to_chat();

-- ---- sync_team_member_chat ----
-- Triggered on team_members UPDATE. Handles two distinct events:
--
--   1. Status flipped to/from 'active':
--      • active   → flip chat_members.left_at to NULL (or insert).
--      • inactive → set left_at = now() on the chat membership.
--
--   2. The unclaimed → claimed cascade fired (cascade_unclaimed_claim,
--      0411) which sets user_id from NULL to the claimer's profile.
--      Detected by (old.user_id IS NULL and new.user_id IS NOT NULL).
--      The claimer is inserted into the team's chat as a member.
create or replace function public.sync_team_member_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  if new.user_id is null then return new; end if;     -- still unclaimed

  select chat_id into v_chat_id
    from public.chats
   where team_id = new.team_id and type = 'team';
  if v_chat_id is null then return new; end if;

  -- Status flipped to active OR claim cascade just attached a profile.
  if new.status = 'active' and (
       old.status <> 'active'
       or (old.user_id is null and new.user_id is not null)
     ) then
    insert into public.chat_members (chat_id, user_id, role)
    values (v_chat_id, new.user_id, 'member')
    on conflict (chat_id, user_id)
    do update set left_at = null;
  end if;

  -- Status flipped to non-active. Keep the row for history-read.
  if new.status <> 'active' and old.status = 'active' then
    update public.chat_members
       set left_at = now()
     where chat_id  = v_chat_id
       and user_id  = new.user_id
       and left_at is null;
  end if;

  return new;
end;
$$;

create trigger team_members_after_update_sync_chat
  after update on public.team_members
  for each row execute function public.sync_team_member_chat();

-- =============================================================================
-- Backfill — covers teams + team_members that existed BEFORE the chat
-- layer was introduced. For a clean reset (no pre-existing rows) these
-- are no-ops but harmless to ship.
-- =============================================================================
insert into public.chats (type, team_id)
select 'team', t.team_id
  from public.teams t
 where not exists (
   select 1 from public.chats c
    where c.team_id = t.team_id and c.type = 'team'
 );

insert into public.chat_members (chat_id, user_id, role)
select c.chat_id, t.owner_id, 'admin'
  from public.chats c
  join public.teams t on t.team_id = c.team_id
 where c.type = 'team'
on conflict (chat_id, user_id) do update set role = 'admin';

insert into public.chat_members (chat_id, user_id, role)
select c.chat_id, tm.user_id, 'member'
  from public.chats c
  join public.team_members tm on tm.team_id = c.team_id
 where c.type = 'team'
   and tm.user_id is not null
   and tm.status  = 'active'
on conflict (chat_id, user_id) do nothing;
