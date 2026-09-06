-- =============================================================================
-- 20260906120000 · Function EXECUTE hardening (runs last, on purpose)
-- =============================================================================
-- Closes Supabase advisor 0028/0029: a SECURITY DEFINER function that `anon`
-- can execute bypasses RLS entirely, because it runs as its owner. On
-- 2026-09-06 twenty-eight of them were reachable by anon, including
-- request_to_join_team, start_match_now, submit_match_openers,
-- accept_team_join_request and decline_team_join_request.
--
-- WHY A SWEEP AND NOT DEFAULT PRIVILEGES
-- --------------------------------------
-- 20260101000010 says anon "explicitly gets no function execute by default".
-- It did not hold. Postgres grants EXECUTE on every new function to PUBLIC,
-- and anon holds PUBLIC. Adding
--   alter default privileges for role postgres in schema public
--     revoke execute on functions from public;
-- to that migration is correct in principle and is kept there, but it does NOT
-- work on this stack: `public` carries TWO default-ACL entries for functions —
-- one for `supabase_admin` (which grants anon outright) and one for `postgres`
-- — and a function created afterwards still comes out with the `=X/postgres`
-- PUBLIC grant. Verified empirically: create a function, inspect proacl, the
-- PUBLIC entry is there either way.
--
-- So the guarantee is made here instead, declaratively and verifiably: revoke
-- EXECUTE from PUBLIC and anon on every function this project owns in `public`,
-- then hand back the two that are deliberately public. 33 migrations already
-- end with `revoke all on function ... from public` at the declaration site;
-- this is the same rule applied exhaustively so a new function cannot forget.
--
-- Extension-owned functions (PostGIS, pg_trgm, pgcrypto...) are skipped: they
-- are not ours, several are needed by anon-reachable expressions such as
-- generated search_name columns, and revoking on them breaks geo/search.
--
-- ⚠️ MAINTENANCE: this must remain the LAST migration. A migration added after
-- it creates functions that this sweep never sees. If you add one, either move
-- this file's timestamp past it or `revoke all on function ... from public` at
-- the new function's declaration site (the established convention).
-- =============================================================================

do $$
declare
  r record;
  n int := 0;
begin
  for r in
    select p.oid::regprocedure as sig
      from pg_proc p
      join pg_namespace ns on ns.oid = p.pronamespace
     where ns.nspname = 'public'
       and p.prokind in ('f', 'p')
       -- Not owned by an extension.
       and not exists (
         select 1
           from pg_depend d
          where d.objid = p.oid
            and d.classid = 'pg_proc'::regclass
            and d.deptype = 'e'
       )
  loop
    execute format('revoke all on function %s from public, anon', r.sig);
    n := n + 1;
  end loop;
  raise notice 'function grants hardened: % functions', n;
end $$;

-- -----------------------------------------------------------------------------
-- The deliberate exceptions: RPCs the signed-out surface genuinely calls.
-- -----------------------------------------------------------------------------
-- Both were already granted to anon at their declaration sites; the sweep above
-- is indiscriminate, so they are restored here. Anything added to this list
-- needs a reason recorded next to it.
--
--   get_follow_list  — follower/following lists on a public profile
--                      (/u/<username> deep link, 20260101000561).
--   _try_topic_uuid  — realtime topic parsing used by the authorization
--                      policies themselves (20260101000810).
grant execute on function public.get_follow_list(uuid, text, int, int) to anon;
grant execute on function public._try_topic_uuid(text, int) to anon;
