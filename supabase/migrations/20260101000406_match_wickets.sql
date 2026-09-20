-- =============================================================================
-- 0406 · match_wickets
-- =============================================================================
-- Dismissal details attached to deliveries.
-- Spec: docs/matches-schema-architecture.md

create table public.match_wickets (
  wicket_id              uuid primary key default gen_random_uuid(),
  delivery_id            uuid not null unique references public.match_deliveries(delivery_id) on delete cascade,
  innings_id             uuid not null references public.match_innings(innings_id) on delete cascade,
  
  player_out_id          uuid not null references public.match_players(match_player_id) on delete restrict,
  dismissal_kind         public.wicket_kind not null,
  
  is_bowler_credited     boolean not null default true,
  credited_bowler_id     uuid references public.match_players(match_player_id) on delete restrict,
  
  primary_fielder_id     uuid references public.match_players(match_player_id) on delete set null,
  assisted_fielder_id    uuid references public.match_players(match_player_id) on delete set null,
  
  fall_of_wicket_score   integer not null,
  fall_of_wicket_number  smallint not null check (fall_of_wicket_number between 1 and 11),
  fall_of_wicket_overs   numeric(4,1) not null,

  created_at             timestamptz not null default now()
);

alter table public.match_wickets enable row level security;

drop policy if exists "match_wickets_read_all" on public.match_wickets;

create policy "match_wickets_read_all" on public.match_wickets for select
  to anon, authenticated
  using (true);

drop policy if exists "match_wickets_write_scorer" on public.match_wickets;

create policy "match_wickets_write_scorer" on public.match_wickets for all to authenticated using (true);

create index if not exists idx_wickets_innings on public.match_wickets(innings_id);

create index if not exists idx_match_wickets_assisted_fielder_id
  on public.match_wickets (assisted_fielder_id);

create index if not exists idx_match_wickets_credited_bowler_id
  on public.match_wickets (credited_bowler_id);

create index if not exists idx_match_wickets_player_out_id
  on public.match_wickets (player_out_id);

create index if not exists idx_match_wickets_primary_fielder_id
  on public.match_wickets (primary_fielder_id);

comment on table public.match_wickets is
  'CRICKET ENGINE TABLE (legacy generic name). Planned rename: '
  'cricket_match_wickets.';
