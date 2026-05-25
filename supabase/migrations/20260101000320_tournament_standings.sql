-- =============================================================================
-- 0320 · tournament_standings
-- =============================================================================
-- Spec §3.9. Per-team accumulator inside a tournament.
--
-- One row per (tournament, team) — and per group when group_knockout lands
-- (v1.1). Recalculated end-to-end by recalculate_standings() in 0420 after
-- every match-result write. The accumulator columns let us recompute NRR
-- without having to walk the balls ledger.
--
-- Writes:
--   The recalc RPC is SECURITY DEFINER and the only path that mutates this
--   table — the RLS policy explicitly denies direct writes from clients.
--   This keeps the points + NRR math centralized.
--
-- Reads:
--   Public (every tournament page renders the standings table). FK CASCADE
--   on tournament + team so dropping a team auto-cleans its row.
-- =============================================================================

create table public.tournament_standings (
  tournament_id     uuid not null
                       references public.tournaments(tournament_id) on delete cascade,
  team_id           uuid not null
                       references public.teams(team_id) on delete cascade,
  group_id          text,                        -- null for non-group formats
  matches_played    integer not null default 0,
  wins              integer not null default 0,
  losses            integer not null default 0,
  ties              integer not null default 0,
  no_results        integer not null default 0,
  points            integer not null default 0,
  -- NRR inputs — accumulated so recompute doesn't need to scan balls.
  runs_scored       integer not null default 0,
  overs_faced       numeric(6, 2) not null default 0,
  runs_conceded     integer not null default 0,
  overs_bowled      numeric(6, 2) not null default 0,
  net_run_rate      numeric(6, 3) not null default 0,
  updated_at        timestamptz not null default now(),

  primary key (tournament_id, team_id)
);

create index tournament_standings_team on public.tournament_standings (team_id);

create trigger tournament_standings_set_updated_at
  before update on public.tournament_standings
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — public read; no direct writes (recalc RPC is the only path).
-- -----------------------------------------------------------------------------
alter table public.tournament_standings enable row level security;

create policy "tournament_standings_read_public"
  on public.tournament_standings for select
  using (true);

create policy "tournament_standings_no_direct_write"
  on public.tournament_standings for all
  to authenticated
  using (false)
  with check (false);

-- =============================================================================
-- Realtime — Broadcast on standings change
-- =============================================================================
-- Spectators on a tournament screen subscribe to
-- tournament:<id>:standings and see the table reorder live as feeder
-- matches complete. Standings are recomputed by the match-result trigger
-- (0420), so this fires once per match completion — low msg/s.
create or replace function public.broadcast_standings_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(coalesce(new, old)),
    case tg_op when 'DELETE' then 'standings_deleted' else 'standings_updated' end,
    'tournament:' || coalesce(new.tournament_id, old.tournament_id)::text || ':standings',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_standings_change() from public;

drop trigger if exists tournament_standings_broadcast on public.tournament_standings;

create trigger tournament_standings_broadcast
  after insert or update or delete on public.tournament_standings
  for each row execute function public.broadcast_standings_change();
