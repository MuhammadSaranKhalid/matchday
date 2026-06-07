-- =============================================================================
-- 20260607120000 · chat_members RLS — add WITH CHECK to prevent role escalation
-- =============================================================================
-- WHY
-- ---
-- The original `chat_members_update_self_or_admin` policy (migration 0801) only
-- declared a USING clause. USING gates which rows you can target for UPDATE;
-- it does NOT constrain the post-update row state.
--
-- Concretely: any authenticated user could issue
--   UPDATE chat_members SET role = 'admin' WHERE user_id = me
-- and Postgres would accept it — the USING clause is satisfied ("it's their
-- own row → allowed"), and without WITH CHECK the new row state is not
-- examined. Real privilege escalation via a single REST call.
--
-- The client only sends `last_read_at` in the markRead path, so an honest
-- caller is never affected; the bug is exploitable only by hand-crafting
-- a REST request. Closing it here as a follow-up to the
-- 2026-06-07 architecture review.
--
-- WHAT
-- ----
-- Replace the policy with one that mirrors USING and adds WITH CHECK:
--
--   • SELF UPDATE branch — the new row must still belong to the actor AND
--     their role must equal their current (pre-update) role. This blocks
--     role escalation while keeping `last_read_at` updates working. The
--     pre-update role is read via a self-referential subselect against the
--     row being updated (Postgres sees the old row inside CHECK because the
--     UPDATE hasn't committed yet).
--
--   • ADMIN UPDATE branch — an active admin in the chat can change anything
--     on any member row in their chat (promote, demote, set role, etc.).
--     Unchanged from the existing intent.
--
-- The USING clause is reproduced verbatim so nothing READ-able becomes
-- WRITE-able and vice versa.
-- =============================================================================

drop policy if exists "chat_members_update_self_or_admin" on public.chat_members;

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
    -- (A) Active admin in this chat can write whatever.
    exists (
      select 1 from public.chat_members admin
       where admin.chat_id = chat_members.chat_id
         and admin.user_id = (select auth.uid())
         and admin.role    = 'admin'
         and admin.left_at is null
    )
    or
    -- (B) Self update: row still belongs to me AND role unchanged.
    -- The subselect returns the pre-update role because the UPDATE has not
    -- committed at CHECK-evaluation time. This is the load-bearing guard
    -- that blocks role escalation via raw REST.
    (
      user_id = (select auth.uid())
      and role = (
        select cm.role
          from public.chat_members cm
         where cm.membership_id = chat_members.membership_id
      )
    )
  );
