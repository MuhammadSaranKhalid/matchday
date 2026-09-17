-- =============================================================================
-- 20260917200000 · Function EXECUTE & Table Mutation Hardening (Runs Last)
-- =============================================================================
-- Closes Supabase advisor 0028/0029 and enforces least privilege:
--   1. Revoke EXECUTE from PUBLIC and anon on every project function in public and private.
--   2. Restrict private.get_ably_auth_header() strictly to service_role.
--   3. Revoke direct table mutations from client roles on all core chat tables.
--   4. Hand back explicit EXECUTE only to authenticated for application RPCs.
--   5. Restore deliberate anon exceptions (get_follow_list, _try_topic_uuid).
--
-- ⚠️ MAINTENANCE: This must remain the LAST migration.
-- =============================================================================

-- 1. Exhaustive Function Execute Sweep
DO $$
DECLARE
  r RECORD;
  n INT := 0;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace ns ON ns.oid = p.pronamespace
     WHERE ns.nspname IN ('public', 'private')
       AND p.prokind IN ('f', 'p')
       AND NOT EXISTS (
         SELECT 1
           FROM pg_depend d
          WHERE d.objid = p.oid
            AND d.classid = 'pg_proc'::regclass
            AND d.deptype = 'e'
       )
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM public, anon', r.sig);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'Function grants hardened: % functions', n;
END $$;

-- 2. Alter Default Privileges for Future Functions
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM public, anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA private
  REVOKE ALL ON FUNCTIONS FROM public, anon;

-- 3. Restrict Sensitive Secrets Helper to Service Role
REVOKE ALL ON FUNCTION private.get_ably_auth_header() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO service_role;
GRANT EXECUTE ON FUNCTION private.get_ably_auth_header() TO service_role;

-- 4. Revoke Direct Table Mutations on Chat Tables from Client Roles
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE
  public.chat_channels,
  public.channel_members,
  public.channel_membership_periods,
  public.channel_role_permissions,
  public.channel_policies,
  public.channel_member_restrictions,
  public.messages,
  public.message_attachments,
  public.message_reactions,
  public.message_user_state,
  public.channel_receipt_events,
  public.chat_changes
FROM anon, authenticated;

-- 5. Deliberate Public Exceptions (Signed-out Surface)
GRANT EXECUTE ON FUNCTION public.get_follow_list(UUID, TEXT, INT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public._try_topic_uuid(TEXT, INT) TO anon;

-- 6. Deliberate Authenticated Application Chat RPCs
GRANT EXECUTE ON FUNCTION public.list_my_chats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.edit_channel_message(UUID, INTEGER, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_channel_message(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_message_reaction(UUID, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_channel_read(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_channel_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decline_channel_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_channel(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_direct_channel(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_group_channel(TEXT, TEXT, TEXT, UUID[]) TO authenticated;
