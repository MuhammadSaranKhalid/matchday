-- =============================================================================
-- 0407 · match_scorer_leases
-- =============================================================================
-- The current scoring device lease for a match.
-- Spec: docs/matches-schema-architecture.md

drop table if exists public.match_scorer_leases cascade;

-- -----------------------------------------------------------------------------
-- Scorer Leases
-- -----------------------------------------------------------------------------
-- match_batsman_stats and match_bowler_stats used to live here. Nothing has
-- written them since 20260822120000 removed the SQL scoring engine, and
-- nothing read them either: the Dart repository exposed getters that no
-- controller called. Scorecards are derived on the client from the delivery
-- ledger (scoring_rules.dart). Dropped 2026-09-06 rather than re-backed with
-- views, because a view would put cricket arithmetic back in SQL — which the
-- CLAUDE.md banner forbids: the rules live in the Dart engine only.

create table public.match_scorer_leases (
  match_id               uuid primary key references public.matches(match_id) on delete cascade,
  active_scorer_id       uuid not null references public.profiles(user_id) on delete cascade,
  device_id              text not null,
  lease_acquired_at      timestamptz not null default now(),
  lease_expires_at       timestamptz not null default (now() + interval '5 minutes'),
  heartbeat_at           timestamptz not null default now()
);

alter table public.match_scorer_leases enable row level security;

drop policy if exists "match_scorer_leases_read_all" on public.match_scorer_leases;

create policy "match_scorer_leases_read_all" on public.match_scorer_leases for select
  to anon, authenticated
  using (true);

create index if not exists idx_match_scorer_leases_active_scorer_id
  on public.match_scorer_leases (active_scorer_id);
