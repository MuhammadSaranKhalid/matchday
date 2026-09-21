-- Migration file: 20260101000401_match_players.sql

-- 0401 · match_players
-- The polymorphic lineup for each match.
-- Spec: docs/matches-schema-architecture.md

-- Section: Tables and constraints

drop table if exists public.match_players cascade;

-- Lineup Boundary (match_players)
create table public.match_players(
  match_player_id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(match_id) on delete cascade,
  team_side text not null check (team_side in ('team_a', 'team_b')),
  user_id uuid references public.profiles(user_id) on delete set null,
  unclaimed_id uuid references public.unclaimed_players(unclaimed_id) on delete set null,
  display_name text not null,
  jersey_number smallint check (jersey_number is null or (jersey_number between 0 and 99)),
  created_at timestamptz not null default now(),
  constraint chk_match_player_identity check (num_nonnulls(user_id, unclaimed_id) = 1),
  unique (match_id, user_id),
  unique (match_id, unclaimed_id),
  unique (match_player_id, match_id)
);

comment on table public.match_players is 'Sport-neutral participant identity/snapshot for a match. Sport-specific per-match state belongs in sport participant extensions.';

-- Section: Enable row-level security

alter table public.match_players enable row level security;

-- Section: Policies

drop policy if exists "match_players_read_all" on public.match_players;

create policy "match_players_read_all" on public.match_players
  for select to anon, authenticated
  using (true);

-- Section: Indexes

create index if not exists idx_match_players_user on public.match_players(user_id)
where
  user_id is not null;

create index if not exists idx_match_players_unclaimed on public.match_players(unclaimed_id)
where
  unclaimed_id is not null;

create index if not exists idx_match_players_match on public.match_players(match_id);

-- Section: Functions

-- match_players sport integrity
create or replace function public.enforce_unclaimed_match_sport()
  returns trigger
  language plpgsql
  set search_path = public, pg_temp
  as $$
declare
  v_match_sport text;
  v_player_sport text;
begin
  if new.unclaimed_id is null then
    return new;
  end if;
  select
    m.sport_id
  into
    v_match_sport
  from
    public.matches m
  where
    m.match_id = new.match_id;
  select
    up.sport_id
  into
    v_player_sport
  from
    public.unclaimed_players up
  where
    up.unclaimed_id = new.unclaimed_id;
  if v_match_sport is not null and v_player_sport is not null and v_match_sport is distinct from v_player_sport then
    raise exception 'Unclaimed player sport (%) does not match match sport (%)', v_player_sport, v_match_sport
      using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function public.enforce_unclaimed_match_sport() from public, anon, authenticated;

-- Section: Triggers

create trigger match_players_enforce_unclaimed_sport
  before insert or update of match_id,
  unclaimed_id on public.match_players for each row
  execute function public.enforce_unclaimed_match_sport();

-- Section: Functions (continued)

-- Registered player-sport activation from match participation
--
-- A registered account appearing in match_players has participated in the
-- sport represented by the match.
--
-- This is deliberately independent of team_members:
--
--   * practice matches
--   * imported historical matches
--   * future non-team formats
--
-- may establish player participation without a current team membership.
create or replace function public.activate_player_sport_from_match_player()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
declare
  v_sport_id text;
begin
  if new.user_id is null then
    return new;
  end if;
  select
    m.sport_id
  into
    v_sport_id
  from
    public.matches m
  where
    m.match_id = new.match_id;
  if v_sport_id is null then
    raise exception 'Match sport could not be resolved'
      using errcode = 'P0002';
  end if;
  insert into public.player_sports(user_id, sport_id)
    values (new.user_id, v_sport_id)
  on conflict (user_id, sport_id)
    do nothing;
  return new;
end;
$$;

revoke all on function public.activate_player_sport_from_match_player() from public, anon, authenticated;

-- Section: Triggers (continued)

create trigger match_players_activate_player_sport
  after insert or update of user_id,
  match_id on public.match_players for each row
  execute function public.activate_player_sport_from_match_player();

-- Cricket participant extension
-- Transitional legacy column comments
  '(is_captain, is_wicket_keeper, is_substitute).';

  'cricket_match_players.is_playing_xi.';

  'cricket_match_players.batting_order.';
