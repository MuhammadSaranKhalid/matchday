-- =============================================================================
-- 0000 · Shared helpers
-- =============================================================================
-- Foundation that every later migration assumes is already there:
--
--  1. Extensions
--       pgcrypto  → gen_random_uuid() for primary keys
--       postgis   → "near me" geo queries (Feature 7, future)
--       pg_trgm   → trigram fuzzy search (usernames, team names, profiles)
--
--  2. set_updated_at()
--       Generic BEFORE-UPDATE trigger that stamps `updated_at = now()` on any
--       row that carries an `updated_at` column. Wired by every later table
--       via a one-liner trigger declared in that table's migration. Keeping
--       this function here means we never duplicate it.
--
--  3. request_status enum
--       Shared lifecycle for the "ask → approve / reject / cancel" pattern
--       used by both team_join_requests and claim_requests. (Match requests
--       and tournament registrations have richer states and own their own
--       enums in their respective migrations.)
--
-- Migrations after this one declare table-specific enums and helpers next to
-- the table they belong to — only truly cross-cutting code lives here.
-- =============================================================================

create extension if not exists pgcrypto;
create extension if not exists postgis;
create extension if not exists pg_trgm;

-- -----------------------------------------------------------------------------
-- set_updated_at() — generic BEFORE-UPDATE trigger function.
-- Each table that needs it wires it via:
--   create trigger <table>_set_updated_at
--     before update on public.<table>
--     for each row execute function public.set_updated_at();
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- request_status — shared by team_join_requests and claim_requests.
-- 'pending' is the default; 'approved' / 'rejected' come from the manager's
-- decision; 'cancelled' is requester-initiated withdrawal before a decision.
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.request_status as enum (
    'pending',
    'approved',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;
