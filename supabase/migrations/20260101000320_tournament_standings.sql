-- Migration file: 20260101000320_tournament_standings.sql

-- 0320 · tournament_standings
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

-- Section: Tables and constraints

create table public.tournament_standings(
  tournament_id  uuid not null references public.tournaments(tournament_id) on delete cascade,
  team_id        uuid not null references public.teams(team_id) on delete cascade,
  group_id       text, -- null for non-group formats
  matches_played integer not null default 0,
  wins           integer not null default 0,
  losses         integer not null default 0,
  ties           integer not null default 0,
  no_results     integer not null default 0,
  points         integer not null default 0,
  -- NRR inputs — accumulated so recompute doesn't need to scan balls.
  runs_scored    integer not null default 0,
  overs_faced    numeric(6, 2) not null default 0,
  runs_conceded  integer not null default 0,
  overs_bowled   numeric(6, 2) not null default 0,
  net_run_rate   numeric(6, 3) not null default 0,
  updated_at     timestamptz not null default now(),
  primary key (tournament_id, team_id)
);

-- Section: Indexes

create index tournament_standings_team on public.tournament_standings(team_id);

-- Section: Triggers

create trigger tournament_standings_set_updated_at
  before update on public.tournament_standings for each row
  execute function public.set_updated_at();

-- Section: Enable row-level security

-- RLS — public read; no direct writes (recalc RPC is the only path).
alter table public.tournament_standings enable row level security;

-- Section: Policies

create policy "tournament_standings_read_public" on public.tournament_standings
  for select to anon, authenticated
  using (true);

create policy "tournament_standings_no_direct_write" on public.tournament_standings
  for all to authenticated
  using (false)
  with check (false);

-- Section: Functions

-- Realtime — Broadcast on standings change
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
  perform
    realtime.send(to_jsonb(coalesce(new, old)), case tg_op
      when 'DELETE' then
        'standings_deleted'
      else
        'standings_updated'
      end, 'tournament:' || coalesce(new.tournament_id, old.tournament_id)::text || ':standings', true);
  return null;
end;
$$;

revoke all on function public.broadcast_standings_change() from public;

-- Section: Triggers (continued)

drop trigger if exists tournament_standings_broadcast on public.tournament_standings;

create trigger tournament_standings_broadcast
  after insert or update or delete on public.tournament_standings for each row
  execute function public.broadcast_standings_change();

create or replace function public.tournament_batting_leaderboard(
  p_tournament_id uuid,
  p_limit integer default 5
)
  returns table(
    player_key text,
    display_name text,
    team_name text,
    team_monogram text,
    is_unclaimed boolean,
    runs integer,
    balls_faced integer,
    fours integer,
    sixes integer,
    strike_rate numeric,
    innings integer,
    high_score integer)
  language sql
  security definer stable
  set search_path = public,
  pg_temp
  as $$
  with deliveries as(
    select
      d.*,
      mp.display_name,
      mp.user_id,
      mp.unclaimed_id,
      mp.team_side,
      m.team_a_id,
      m.team_b_id
    from
      public.cricket_match_deliveries d
      join public.matches m on m.match_id = d.match_id
      join public.match_players mp on mp.match_player_id = d.striker_id
    where
      m.tournament_id = p_tournament_id
      and d.is_undone = false
      and m.status in('live', 'completed')
),
per_player_match as(
  select
    coalesce('u:' || dv.user_id::text, 'x:' || dv.unclaimed_id::text) as player_key,
    dv.match_id,
    max(dv.display_name) as display_name,
    bool_or(dv.user_id is null) as is_unclaimed,
(array_agg(
        case dv.team_side
        when 'team_a' then
          dv.team_a_id
        else
          dv.team_b_id
        end))[1] as team_id,
    sum(dv.runs_off_bat)::integer as runs,
    count(*) filter(where dv.is_legal_delivery)::integer as balls,
    count(*) filter(where dv.is_four)::integer as fours,
    count(*) filter(where dv.is_six)::integer as sixes
  from
    deliveries dv
  where
    coalesce(dv.user_id::text, dv.unclaimed_id::text) is not null
  group by
    1,
    2
),
totals as(
  select
    p.player_key,
    max(p.display_name) as display_name,
    bool_or(p.is_unclaimed) as is_unclaimed,
(array_agg(p.team_id order by p.match_id desc))[1] as team_id,
    sum(p.runs)::integer as runs,
    sum(p.balls)::integer as balls_faced,
    sum(p.fours)::integer as fours,
    sum(p.sixes)::integer as sixes,
    count(*)::integer as innings,
    max(p.runs)::integer as high_score
  from
    per_player_match p
  group by
    p.player_key
)
select
  t.player_key,
  t.display_name,
  tm.team_name,
  tm.logo_monogram,
  t.is_unclaimed,
  t.runs,
  t.balls_faced,
  t.fours,
  t.sixes,
  case when t.balls_faced = 0 then
    0
  else
    round((t.runs::numeric * 100) / t.balls_faced, 1)
  end,
  t.innings,
  t.high_score
from
  totals t
  left join public.teams tm on tm.team_id = t.team_id
where
  t.runs > 0
order by
  t.runs desc,
  t.balls_faced asc,
  t.display_name
limit greatest(coalesce(p_limit, 5), 1);
$$;

revoke all on function public.tournament_batting_leaderboard(uuid, integer) from public, anon;

grant execute on function public.tournament_batting_leaderboard(uuid, integer) to authenticated;

create or replace function public.tournament_bowling_leaderboard(
  p_tournament_id uuid,
  p_limit integer default 5
)
  returns table(
    player_key text,
    display_name text,
    team_name text,
    team_monogram text,
    is_unclaimed boolean,
    wickets integer,
    runs_conceded integer,
    legal_balls integer,
    economy numeric,
    innings integer,
    best_wickets integer,
    best_runs integer)
  language sql
  security definer stable
  set search_path = public,
  pg_temp
  as $$
  with deliveries as(
    select
      d.*,
      mp.display_name,
      mp.user_id,
      mp.unclaimed_id,
      mp.team_side,
      m.team_a_id,
      m.team_b_id
    from
      public.cricket_match_deliveries d
      join public.matches m on m.match_id = d.match_id
      join public.match_players mp on mp.match_player_id = d.bowler_id
    where
      m.tournament_id = p_tournament_id
      and d.is_undone = false
      and m.status in('live', 'completed')
),
per_player_match as(
  select
    coalesce('u:' || dv.user_id::text, 'x:' || dv.unclaimed_id::text) as player_key,
    dv.match_id,
    max(dv.display_name) as display_name,
    bool_or(dv.user_id is null) as is_unclaimed,
(array_agg(
        case dv.team_side
        when 'team_a' then
          dv.team_a_id
        else
          dv.team_b_id
        end))[1] as team_id,
    count(*) filter(where dv.is_wicket
      and dv.wicket_type::text = any(public._bowler_credited_wickets()))::integer as wickets,
  sum(
    case when dv.delivery_type in('bye', 'leg_bye', 'penalty') then
      dv.runs_off_bat
    else
      dv.runs_off_bat + dv.extra_runs
    end)::integer as runs_conceded,
  count(*) filter(where dv.is_legal_delivery)::integer as legal_balls
from
  deliveries dv
  where
    coalesce(dv.user_id::text, dv.unclaimed_id::text) is not null
  group by
    1,
    2
),
totals as(
  select
    p.player_key,
    max(p.display_name) as display_name,
    bool_or(p.is_unclaimed) as is_unclaimed,
(array_agg(p.team_id order by p.match_id desc))[1] as team_id,
    sum(p.wickets)::integer as wickets,
    sum(p.runs_conceded)::integer as runs_conceded,
    sum(p.legal_balls)::integer as legal_balls,
    count(*)::integer as innings,
(array_agg(p.wickets order by p.wickets desc, p.runs_conceded asc))[1] as best_wickets,
(array_agg(p.runs_conceded order by p.wickets desc, p.runs_conceded asc))[1] as best_runs
  from
    per_player_match p
  group by
    p.player_key
)
select
  t.player_key,
  t.display_name,
  tm.team_name,
  tm.logo_monogram,
  t.is_unclaimed,
  t.wickets,
  t.runs_conceded,
  t.legal_balls,
  case when t.legal_balls = 0 then
    0
  else
    round((t.runs_conceded::numeric * 6) / t.legal_balls, 2)
  end,
  t.innings,
  t.best_wickets,
  t.best_runs
from
  totals t
  left join public.teams tm on tm.team_id = t.team_id
where
  t.legal_balls > 0
order by
  t.wickets desc,
  t.runs_conceded asc,
  t.display_name
limit greatest(coalesce(p_limit, 5), 1);
$$;

revoke all on function public.tournament_bowling_leaderboard(uuid, integer) from public, anon;

grant execute on function public.tournament_bowling_leaderboard(uuid, integer) to authenticated;

-- Section: Enable row-level security

-- 6. Data-API / RLS contract on the new physical names
--
-- These are renamed existing tables, not new tables, so grants survive the
-- rename. We still state the intended access explicitly:
--
--   public score ledger/state = SELECT
--   all mutations             = server-owned RPC / Edge only
alter table public.cricket_match_innings enable row level security;

alter table public.cricket_match_innings_state enable row level security;

alter table public.cricket_match_deliveries enable row level security;

alter table public.cricket_match_wickets enable row level security;

-- Section: Policies

drop policy if exists "match_innings_read_all" on public.cricket_match_innings;

drop policy if exists "cricket_match_innings_read_all" on public.cricket_match_innings;

create policy "cricket_match_innings_read_all" on public.cricket_match_innings
  for select to anon, authenticated
  using (true);

drop policy if exists "match_innings_state_read_all" on public.cricket_match_innings_state;

drop policy if exists "match_innings_state_write_scorer" on public.cricket_match_innings_state;

drop policy if exists "cricket_match_innings_state_read_all" on public.cricket_match_innings_state;

create policy "cricket_match_innings_state_read_all" on public.cricket_match_innings_state
  for select to anon, authenticated
  using (true);

drop policy if exists "match_deliveries_read_all" on public.cricket_match_deliveries;

drop policy if exists "match_deliveries_write_scorer" on public.cricket_match_deliveries;

drop policy if exists "cricket_match_deliveries_read_all" on public.cricket_match_deliveries;

create policy "cricket_match_deliveries_read_all" on public.cricket_match_deliveries
  for select to anon, authenticated
  using (true);

drop policy if exists "match_wickets_read_all" on public.cricket_match_wickets;

drop policy if exists "match_wickets_write_scorer" on public.cricket_match_wickets;

drop policy if exists "cricket_match_wickets_read_all" on public.cricket_match_wickets;

create policy "cricket_match_wickets_read_all" on public.cricket_match_wickets
  for select to anon, authenticated
  using (true);

-- Section: Permissions

grant select on public.cricket_match_innings, public.cricket_match_innings_state, public.cricket_match_deliveries, public.cricket_match_wickets to anon, authenticated;

revoke insert, update, delete, truncate
  on public.cricket_match_innings,
  public.cricket_match_innings_state,
  public.cricket_match_deliveries,
  public.cricket_match_wickets from anon,
  authenticated;

grant all on public.cricket_match_innings, public.cricket_match_innings_state, public.cricket_match_deliveries, public.cricket_match_wickets to service_role;

-- 7. Canonical comments
comment on table public.cricket_match_innings is 'Cricket innings definition. Structurally owned by cricket_matches.';

comment on table public.cricket_match_innings_state is 'Cricket live innings hot-state: totals, target and on-field trio.';

comment on table public.cricket_match_deliveries is 'Authoritative Cricket delivery ledger. All ball-by-ball persistence lives here.';

comment on table public.cricket_match_wickets is 'Cricket dismissal details attached to cricket_match_deliveries.';

-- Section: Dependency-ordered operations (continued)

-- 8. Hard internal-cleanliness assertion
--
-- No compatibility relation names are allowed anywhere after the hard cut.
-- Installed PUBLIC FUNCTION BODIES must use only cricket_* physical tables.
do $$
declare
  v_refs text;
begin
  select
    string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')', E'\n')
  into
    v_refs
  from
    pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
  where
    n.nspname = 'public'
    and p.prokind = 'f'
    and (position('match_innings_state' in pg_get_functiondef(p.oid)) > 0
      or position('match_deliveries' in pg_get_functiondef(p.oid)) > 0
      or position('match_wickets' in pg_get_functiondef(p.oid)) > 0
      or position('match_innings' in pg_get_functiondef(p.oid)) > 0)
    -- New canonical names contain the old substrings. Remove canonical names
    -- before testing whether a legacy token remains.
    and (position('match_innings_state' in replace(replace(replace(replace(pg_get_functiondef(p.oid), 'cricket_match_innings_state', ''), 'cricket_match_deliveries', ''), 'cricket_match_wickets', ''), 'cricket_match_innings', '')) > 0
          or position('match_deliveries' in replace(pg_get_functiondef(p.oid), 'cricket_match_deliveries', '')) > 0
          or position('match_wickets' in replace(pg_get_functiondef(p.oid), 'cricket_match_wickets', '')) > 0
          or position('match_innings' in replace(replace(pg_get_functiondef(p.oid), 'cricket_match_innings_state', ''), 'cricket_match_innings', '')) > 0);
  if v_refs is not null then
    raise exception 'Phase 3C found installed functions that still depend on legacy engine relation names:%', E'\n' || v_refs;
  end if;
end
$$;

