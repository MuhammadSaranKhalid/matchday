-- =============================================================================
-- Migration: 20260101000408_cricket_match_wickets.sql
-- =============================================================================

-- 0408 · cricket_match_wickets
-- Dismissal details attached to deliveries.
-- Spec: docs/matches-schema-architecture.md

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.cricket_match_wickets (
  wicket_id             uuid primary key default gen_random_uuid(),
  delivery_id           uuid not null unique
    references public.cricket_match_deliveries (delivery_id)
    on delete cascade,
  innings_id            uuid not null
    references public.cricket_match_innings (innings_id)
    on delete cascade,
  player_out_id         uuid not null
    references public.match_players (match_player_id)
    on delete restrict,
  dismissal_kind        public.cricket_wicket_kind not null,
  is_bowler_credited    boolean not null default true,
  credited_bowler_id    uuid
    references public.match_players (match_player_id)
    on delete restrict,
  primary_fielder_id    uuid
    references public.match_players (match_player_id)
    on delete set null,
  assisted_fielder_id   uuid
    references public.match_players (match_player_id)
    on delete set null,
  fall_of_wicket_score  integer not null,
  fall_of_wicket_number smallint not null check (
    fall_of_wicket_number between 1 and 11
  ),
  fall_of_wicket_overs  numeric(4, 1) not null,
  created_at            timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.cricket_match_wickets enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

drop policy if exists "cricket_match_wickets_read_all" on public.cricket_match_wickets;

create policy "cricket_match_wickets_read_all"
  on public.cricket_match_wickets
  for select
  to anon, authenticated
  using (true);

drop policy if exists "cricket_match_wickets_write_scorer" on public.cricket_match_wickets;

create policy "cricket_match_wickets_write_scorer"
  on public.cricket_match_wickets
  for all
  to authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists idx_wickets_innings
  on public.cricket_match_wickets (
    innings_id
  );

create index if not exists idx_cricket_match_wickets_assisted_fielder_id
  on public.cricket_match_wickets (
    assisted_fielder_id
  );

create index if not exists idx_cricket_match_wickets_credited_bowler_id
  on public.cricket_match_wickets (
    credited_bowler_id
  );

create index if not exists idx_cricket_match_wickets_player_out_id
  on public.cricket_match_wickets (
    player_out_id
  );

create index if not exists idx_cricket_match_wickets_primary_fielder_id
  on public.cricket_match_wickets (
    primary_fielder_id
  );

comment on table public.cricket_match_wickets is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_wickets.';
