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
-- =============================================================================


create table public.chat_members (
  membership_id   uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id)    on delete cascade,
  user_id         uuid not null references public.profiles(user_id) on delete cascade,
  role            public.chat_role not null default 'member',
  joined_at       timestamptz not null default now(),
  left_at         timestamptz,
  last_read_at    timestamptz,

  constraint chat_members_user_unique unique (chat_id, user_id)
);

create index chat_members_chat on public.chat_members (chat_id);
create index chat_members_user on public.chat_members (user_id);

create index chat_members_active_chat_user
  on public.chat_members (chat_id, user_id)
  where left_at is null;

alter table public.chat_members enable row level security;

-- =============================================================================
-- is_chat_member — the central "may I see this chat?" predicate
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
-- chat_members RLS & Role Guard
-- =============================================================================
create policy "chat_members_read_self_or_chat"
  on public.chat_members for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_chat_member(chat_id)
  );

-- WITH CHECK mirrors USING. Without it, a member passing the USING test on
-- their own row could rewrite user_id or chat_id and move themselves into a
-- chat they were never added to. (The role-change guard trigger below is a
-- separate concern — it stops privilege escalation *within* a legal row.)
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
  )
  with check (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.chat_members admin
       where admin.chat_id = chat_members.chat_id
         and admin.user_id = (select auth.uid())
         and admin.role    = 'admin'
         and admin.left_at is null
    )
  );

-- Guard trigger to prevent non-admins from self-escalating role
create or replace function public.guard_chat_members_role_change()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if new.role is distinct from old.role then
    if not exists (
      select 1 from public.chat_members admin
       where admin.chat_id = old.chat_id
         and admin.user_id = v_actor
         and admin.role    = 'admin'
         and admin.left_at is null
    ) then
      raise exception 'Only active chat admins can change member roles';
    end if;
  end if;
  return new;
end;
$$;

create trigger chat_members_before_update_role_guard
  before update on public.chat_members
  for each row execute function public.guard_chat_members_role_change();

-- =============================================================================
-- Lifecycle triggers for team members
-- =============================================================================

-- ---- add_team_member_to_chat ----
create or replace function public.add_team_member_to_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  if new.user_id is null then return new; end if;
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
create or replace function public.sync_team_member_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_chat_id uuid;
begin
  select chat_id into v_chat_id
    from public.chats
   where team_id = new.team_id and type = 'team';
  if v_chat_id is null then return new; end if;

  if old.status <> 'active' and new.status = 'active' and new.user_id is not null then
    insert into public.chat_members (chat_id, user_id, role)
    values (v_chat_id, new.user_id, 'member')
    on conflict (chat_id, user_id)
    do update set left_at = null;
  elsif old.status = 'active' and new.status <> 'active' and new.user_id is not null then
    update public.chat_members
       set left_at = now()
     where chat_id = v_chat_id
       and user_id = new.user_id;
  end if;

  return new;
end;
$$;

create trigger team_members_after_update_sync_chat
  after update on public.team_members
  for each row execute function public.sync_team_member_chat();
