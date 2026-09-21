-- Migration file: 20260101000408_match_result_history.sql

-- 0408 · match_result_history
-- Append-only audit history for match result overrides.
-- Spec: docs/matches-schema-architecture.md

-- Section: Tables and constraints

drop table if exists public.match_result_history cascade;

create table public.match_result_history(
  history_id      uuid primary key default gen_random_uuid(),
  match_id        uuid not null references public.matches(match_id) on delete cascade,
  previous_status public.match_status not null,
  new_status      public.match_status not null,
  result_payload  jsonb not null,
  reason          text,
  recorded_by     uuid references public.profiles(user_id) on delete set null,
  recorded_at     timestamptz not null default now()
);

-- Section: Enable row-level security

alter table public.match_result_history enable row level security;

-- Section: Policies

-- match_result_history is the audit trail for result overrides, so it is
-- append-only from the app's point of view: readable by anyone who can read the
-- match it belongs to (scores are public), never writable through PostgREST.
-- The three tournament_* RPCs that append to it are SECURITY DEFINER and run
-- as the owner, so they bypass RLS and are unaffected by the absence of an
-- INSERT policy. RLS was simply never enabled on this table before 2026-09-06,
-- which left the entire override trail world-writable with the anon key.
drop policy if exists "match_result_history_read_all" on public.match_result_history;

create policy "match_result_history_read_all" on public.match_result_history
  for select to anon, authenticated
  using (true);

-- Section: Indexes

create index if not exists idx_result_history_match on public.match_result_history(match_id, recorded_at desc);

create index if not exists idx_match_result_history_recorded_by on public.match_result_history(recorded_by);
