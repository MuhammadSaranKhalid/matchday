-- =============================================================================
-- 0010 · Default grants on public for anon / authenticated / service_role
-- =============================================================================
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
-- =============================================================================

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
alter default privileges for role postgres in schema public
  grant select on tables to anon;
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges for role postgres in schema public
  grant all on tables to service_role;

alter default privileges for role postgres in schema public
  grant usage on sequences to anon;
alter default privileges for role postgres in schema public
  grant usage, select on sequences to authenticated;
alter default privileges for role postgres in schema public
  grant all on sequences to service_role;

alter default privileges for role postgres in schema public
  grant execute on functions to authenticated, service_role;
-- anon explicitly gets no function execute by default; any RPC that wants
-- to be reachable from the signed-out spectator surface (e.g. the public
-- match link) must `grant execute ... to anon` at its declaration site.
