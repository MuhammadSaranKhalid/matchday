-- =============================================================================
-- Migration: 20260101000010_default_grants.sql
-- =============================================================================

-- 0010 · Default grants on public for anon / authenticated / service_role
-- Hosted Supabase projects ship with these grants pre-seeded on `public`. If
-- the schema ever gets dropped + recreated (e.g. wiping a project before
-- repurposing it, or a fresh self-hosted setup), those defaults are lost and
-- every later table created by a migration shows `42501 permission denied`
-- to the API roles even when RLS policies are correct — Postgres checks
-- table-level GRANTs before RLS.
--
-- Runs after 0000 (extensions / helpers) and before any migration that
-- creates a table, so every subsequent `create table public.foo` inherits
-- privileges automatically via ALTER DEFAULT PRIVILEGES.

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

grant usage on schema public to anon, authenticated, service_role;

-- Future tables / sequences / functions created by `postgres` (the migration
-- runner) inherit the API-role grants without each migration restating them.
--
-- Anon gets read-only by default — a forgotten RLS policy on a new table no
-- longer becomes a free CRUD endpoint to the public internet. Authenticated
-- gets full CRUD because every per-user surface in this app is logged-in;
-- RLS narrows the rows. service_role gets ALL because Edge Functions /
-- migration tooling run as it. Explicit FOR ROLE postgres pins the grantor
-- so self-hosted setups don't inherit the wrong owner.
alter default privileges
for role postgres
in schema public
grant select on tables to anon;

alter default privileges
for role postgres
in schema public
grant select, insert, update, delete on tables to authenticated;

alter default privileges
for role postgres
in schema public
grant all on tables to service_role;

alter default privileges
for role postgres
in schema public
grant usage on sequences to anon;

alter default privileges
for role postgres
in schema public
grant usage, select on sequences to authenticated;

alter default privileges
for role postgres
in schema public
grant all on sequences to service_role;

-- ⚠️ The REVOKE is load-bearing and must come first. Postgres grants EXECUTE
-- on every newly created function to PUBLIC automatically, and `anon` inherits
-- PUBLIC. Granting to `authenticated, service_role` therefore did NOT make anon
-- execute impossible — it left the automatic PUBLIC grant untouched. Verified
-- on 2026-09-06: 28 SECURITY DEFINER functions, including request_to_join_team,
-- start_match_now and submit_match_openers, were executable by anon. A
-- SECURITY DEFINER function reachable by anon bypasses RLS entirely
-- (Supabase advisor 0028), so this was the widest hole in the schema.
--
-- Default privileges apply to objects created AFTER this statement, and this
-- migration runs before every table and function, so one revoke here fixes the
-- whole run.
alter default privileges
for role postgres
in schema public
revoke execute on functions from public;

alter default privileges
for role postgres
in schema public
grant execute on functions to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- Dependency-ordered operations
-- -----------------------------------------------------------------------------

-- anon explicitly gets no function execute by default; any RPC that wants
-- to be reachable from the signed-out spectator surface (e.g. the public
-- match link) must `grant execute ... to anon` at its declaration site.
-- Two do: get_follow_list (0561) and _try_topic_uuid (0810).
-- PostGIS system table — KNOWN GAP, cannot be closed from here
-- `postgis` installs spatial_ref_sys into public, where PostgREST exposes it.
-- The 2026-09-06 audit flagged it as RLS-disabled and world-writable.
--
-- It cannot be fixed by this migration, and the attempt is left in place only
-- because it is correct on self-hosted setups where `postgres` owns the table:
--
--   * RLS   — `alter table ... enable row level security` needs ownership.
--   * GRANT — on hosted Supabase the table is owned by `supabase_admin` and
--             every grant on it was issued BY supabase_admin. Migrations run as
--             `postgres`, which is neither owner nor grantor, so the revoke
--             below succeeds syntactically, emits "no privileges could be
--             revoked", and changes nothing. Verified: after running it,
--             `set role anon; delete from spatial_ref_sys` still worked.
--
-- The real fix is the one the audit recommends — keep it out of the exposed
-- schema — which means installing PostGIS into an `extensions` schema rather
-- than `public`. That is a deliberate, separate change: every geography column
-- and ST_* call in the schema and in the edge functions has to resolve against
-- the new search_path. Tracked, not done here.
--
-- Residual risk is low and is availability, not disclosure: spatial_ref_sys is
-- a static catalogue of coordinate systems, so the exposure is that someone
-- could corrupt projections and break geo queries. No user data lives in it.
do $$
begin
  revoke insert, update, delete, truncate
    on table public.spatial_ref_sys from public,
    anon,
    authenticated;
exception
  when insufficient_privilege
    or undefined_table then
    raise notice 'spatial_ref_sys: not owner — writes left as PostGIS granted them.';
end
$$;
