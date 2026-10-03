-- 20261003000100_phase6_1_participation_cutover.sql
-- Phase 6.1: Participation Authority Cutover
-- Retires legacy workflow RPCs and closes direct Data API writes on tournament_registrations
-- Writes are now exclusively routed through NestJS TournamentCommandExecutor.

-- ─── 1. Drop Superseded Participation Mutation RPCs ──────────────────────────

-- 1.1 Registration commands
drop function if exists public.tournament_register_team(uuid, uuid, uuid[], text);
drop function if exists public.submit_tournament_registration(uuid, uuid, text, jsonb);

-- 1.2 Registration approval
drop function if exists public.approve_tournament_registration(uuid);

-- 1.3 Registration rejection
drop function if exists public.reject_tournament_registration(uuid, text);
drop function if exists public.reject_tournament_registration(uuid);

-- 1.4 Withdrawals
drop function if exists public.withdraw_tournament_pending_registration(uuid, text);
drop function if exists public.withdraw_tournament_registration(uuid, text);
drop function if exists public.withdraw_tournament_registration(uuid);
drop function if exists public.withdraw_tournament_entry(uuid, text);
drop function if exists public.withdraw_tournament_entry(uuid);

-- 1.5 Squad management
drop function if exists public.tournament_squad_add_member(uuid, uuid, uuid);
drop function if exists public.add_tournament_squad_member(uuid, uuid, uuid, boolean, text, text);
drop function if exists public.tournament_squad_remove_member(uuid, text);
drop function if exists public.remove_tournament_squad_member(uuid, text);

-- 1.6 Payment operations
drop function if exists public.tournament_record_payment(uuid, numeric, text, text);
drop function if exists public.record_tournament_entry_payment(uuid, numeric, text, text, text, text);
drop function if exists public.void_tournament_entry_payment(uuid, text);

-- ─── 2. Close Direct Data API Writes on Tournament Registrations ──────────────

-- Close direct INSERT on tournament_registrations (authenticated INSERT -> denied)
drop policy if exists "tournament_registrations_insert" on public.tournament_registrations;
create policy "tournament_registrations_insert"
  on public.tournament_registrations
  for insert
  to authenticated
  with check (false);

-- Close direct INSERT on tournament_registration_squad_members
drop policy if exists "proposal_members_insert" on public.tournament_registration_squad_members;
create policy "proposal_members_insert"
  on public.tournament_registration_squad_members
  for insert
  to authenticated
  with check (false);

-- Close direct DELETE on tournament_registration_squad_members
drop policy if exists "proposal_members_delete" on public.tournament_registration_squad_members;
create policy "proposal_members_delete"
  on public.tournament_registration_squad_members
  for delete
  to authenticated
  using (false);
