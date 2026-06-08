-- =============================================================================
-- 20260608130000 · chat_members — replace fragile WITH CHECK with BEFORE
--                                  UPDATE trigger
-- =============================================================================
-- WHY
-- ---
-- Migration 20260607120000 added a WITH CHECK clause whose self-update
-- branch read:
--
--   role = (
--     select cm.role from public.chat_members cm
--      where cm.membership_id = chat_members.membership_id
--   )
--
-- That subselect re-enters RLS evaluation on chat_members recursively.
-- Postgres detects the recursion and silently returns FALSE — the WITH
-- CHECK clause rejects the row, 0 rows are affected, PostgREST returns
-- 200, and the client has no signal of failure. This was the root cause
-- of #39 (markRead silently failing → last_read_at stayed NULL across
-- every chat). #40 routed AROUND the bug with a SECURITY DEFINER RPC,
-- but the role-escalation guard the WITH CHECK was supposed to provide
-- is currently DEGRADED.
--
-- WHAT
-- ----
-- Drop the broken WITH CHECK. Restore the original USING-only policy
-- from 0801 (identical to what was there before 0607120000). Move the
-- role-escalation guard into a BEFORE UPDATE trigger that compares
-- OLD.role vs NEW.role directly — no subselect, no recursion, no
-- ambiguity.
--
-- Migration 0607120000 is intentionally NOT reverted in source; it
-- represents a historical step. This migration supersedes its WITH
-- CHECK and the trigger replaces the role-escalation guard.
-- =============================================================================

-- ─── Step 1: drop the broken policy ──────────────────────────────────────
drop policy if exists "chat_members_update_self_or_admin" on public.chat_members;

-- ─── Step 2: restore the original USING-only policy from 0801 ────────────
-- USING gates which rows you can target for UPDATE. The post-update row
-- state is no longer constrained at the RLS layer — the trigger below
-- handles role-change validation instead.
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

-- ─── Step 3: BEFORE UPDATE trigger for role-escalation prevention ────────
-- The trigger fires inside the same transaction as the UPDATE, sees both
-- OLD and NEW rows directly (no RLS recursion), and raises an exception
-- when a non-admin tries to change role. PostgREST surfaces the exception
-- as a 4xx with a message the client can act on — no more silent failures.
--
-- SECURITY DEFINER so the admin-existence check can read chat_members
-- regardless of the caller's RLS context. The function returns NEW
-- unchanged when the check passes; otherwise raises a typed exception.
create or replace function public.prevent_chat_member_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Role unchanged → nothing to check. Covers the common case
  -- (markRead, leave-chat, etc.) so the trigger costs ~nothing.
  if new.role is not distinct from old.role then
    return new;
  end if;

  -- Role changed → require the caller to be an active admin of THIS
  -- chat. The auth.uid() check is intentional: a service-role bypass
  -- (no auth.uid()) sets the predicate to NULL and the EXISTS short-
  -- circuits to false, so even SECURITY DEFINER paths without an
  -- explicit caller identity get blocked here.
  if not exists (
    select 1 from public.chat_members admin
     where admin.chat_id = new.chat_id
       and admin.user_id = (select auth.uid())
       and admin.role    = 'admin'
       and admin.left_at is null
  ) then
    raise exception 'cannot change chat member role: caller is not an admin of this chat'
      using errcode = '42501';  -- insufficient_privilege; PostgREST returns 403.
  end if;

  return new;
end;
$$;

revoke all on function public.prevent_chat_member_role_escalation() from public;

drop trigger if exists chat_members_block_role_escalation on public.chat_members;
create trigger chat_members_block_role_escalation
  before update on public.chat_members
  for each row
  execute function public.prevent_chat_member_role_escalation();

comment on function public.prevent_chat_member_role_escalation() is
  'BEFORE UPDATE guard on chat_members.role. Blocks non-admins from '
  'changing role. Replaces the recursive WITH CHECK from migration '
  '20260607120000. Ticket #42.';
