-- =============================================================================
-- 0804 · chat_lifecycle — policies and triggers requiring chat members
-- =============================================================================

-- =============================================================================
-- chats RLS
-- =============================================================================
create policy "chats_read_members"
  on public.chats for select
  to authenticated
  using (public.is_chat_member(chat_id));

-- WITH CHECK mirrors USING: an admin may edit a chat they administer, and the
-- row must still be one they administer afterwards. Without the WITH CHECK an
-- UPDATE policy constrains only which rows you may touch, never what you may
-- turn them into.
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
  )
  with check (
    exists (
      select 1 from public.chat_members
       where chat_members.chat_id = chats.chat_id
         and chat_members.user_id = (select auth.uid())
         and chat_members.role    = 'admin'
         and chat_members.left_at is null
    )
  );

-- =============================================================================
-- Lifecycle Triggers & RPCs
-- =============================================================================

-- ---- create_team_chat ----
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
  -- created_by, not an authority lookup: this fires on team INSERT, before
  -- any role exists, and "who opened the chat" is a creator fact anyway.
  values (v_chat_id, new.created_by, 'admin');

  return new;
end;
$$;

create trigger teams_after_insert_create_chat
  after insert on public.teams
  for each row execute function public.create_team_chat();
