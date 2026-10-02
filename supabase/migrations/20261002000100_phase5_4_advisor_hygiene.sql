-- =============================================================================
-- Phase 5.4 Advisor Hygiene — RLS Init-Plan & Search Path Fixes
-- =============================================================================
-- Date: 2026-10-02
-- Phase: 5.4
-- Scope: Fix two Supabase Advisor warnings introduced by Phase 2 migrations
--        (20261001000100_tournament_memberships.sql):
--
--   1. [auth_rls_initplan] tournament_memberships_read
--      auth.uid() is re-evaluated per-row. Replace with (select auth.uid()).
--
--   2. [function_search_path_mutable] public.derive_tournament_public_status
--      IMMUTABLE SQL function lacks a fixed search_path. Add
--      set search_path = public, pg_temp.
--
-- Phase 5 introduced only private.tournament_command_receipts, which has zero
-- advisor findings (private schema, no public RLS, no exposed functions).
-- These two findings belong to Phase 2 code and are addressed here because
-- tournament_memberships is within Phase 5's authorization domain.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Fix 1: auth_rls_initplan on tournament_memberships_read
--
-- Replace direct auth.uid() call (re-evaluated per row) with
-- (select auth.uid()) so the result is materialized once per statement.
-- ---------------------------------------------------------------------------
drop policy if exists "tournament_memberships_read" on public.tournament_memberships;
create policy "tournament_memberships_read"
  on public.tournament_memberships
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_tournament_admin(tournament_id)
  );

-- ---------------------------------------------------------------------------
-- Fix 2: function_search_path_mutable on public.derive_tournament_public_status
--
-- IMMUTABLE SQL function must pin search_path to prevent schema-injection.
-- ---------------------------------------------------------------------------
create or replace function public.derive_tournament_public_status(
  p_publication_state public.tournament_publication_state,
  p_registration_state public.tournament_registration_state,
  p_entry_state public.tournament_entry_state,
  p_competition_state public.tournament_competition_state,
  p_termination_state public.tournament_termination_state
)
returns public.tournament_status
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    -- Precedence 1: Explicit termination states override ordinary display
    when p_termination_state = 'cancelled' then 'cancelled'::public.tournament_status
    when p_termination_state = 'abandoned' then 'abandoned'::public.tournament_status
    -- Precedence 2: Draft publication
    when p_publication_state = 'draft' then 'draft'::public.tournament_status
    -- Precedence 3: Competition completion / progress
    when p_competition_state = 'completed' then 'completed'::public.tournament_status
    when p_competition_state = 'in_progress' then 'live'::public.tournament_status
    -- Precedence 4: Registration open
    when p_registration_state = 'open' then 'registration'::public.tournament_status
    -- Precedence 5: Upcoming (published, registration closed/not_open, competition not started)
    else 'upcoming'::public.tournament_status
  end;
$$;
