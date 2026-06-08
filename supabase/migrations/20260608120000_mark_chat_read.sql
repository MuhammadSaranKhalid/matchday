-- =============================================================================
-- 20260608120000 · mark_chat_read RPC — replace the silently-failing UPDATE
-- =============================================================================
-- WHY
-- ---
-- The client used to issue a direct PostgREST UPDATE against chat_members
-- to bump last_read_at. The WITH CHECK clause from migration 0607120000
-- intermittently rejected the row (self-referential subselect against the
-- in-memory row state), leaving last_read_at NULL across all chats. PostgREST
-- returns 200 even for "0 rows affected", so the silent failure was
-- invisible to the client — the unread badge kept re-computing the same
-- count after every chat open. See #39.
--
-- WHAT
-- ----
-- A SECURITY DEFINER function that bypasses the buggy RLS check and stamps
-- last_read_at = now() server-side. Authorization is enforced inside the
-- function via auth.uid() + left_at filter, so it can only ever stamp the
-- caller's own active membership.
--
-- USAGE
-- -----
--   await _supabase.rpc('mark_chat_read', params: {'p_chat_id': chatId});
--
-- Returns the new last_read_at value so the client can confirm the update
-- committed (the previous direct UPDATE had no positive success signal).
-- Returns NULL if the caller is not an active member of the chat — client
-- can treat that as a 404 / unauthorized state.
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
     and user_id  = (select auth.uid())
     and left_at  is null
  returning last_read_at;
$$;

-- Lock down the function: only authenticated callers, no anon / public.
revoke all on function public.mark_chat_read(uuid) from public;
grant execute on function public.mark_chat_read(uuid) to authenticated;

comment on function public.mark_chat_read(uuid) is
  'Stamp chat_members.last_read_at = now() for the calling user. '
  'SECURITY DEFINER to bypass the WITH CHECK trap in chat_members RLS '
  '(see migration 20260607120000). Returns the new timestamp on success, '
  'NULL if the caller is not an active member of the chat. Ticket #39.';
