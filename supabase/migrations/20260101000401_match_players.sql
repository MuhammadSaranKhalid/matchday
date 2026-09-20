-- =============================================================================
-- 0401 · match_players
-- =============================================================================
-- The polymorphic lineup for each match.
-- Spec: docs/matches-schema-architecture.md

drop table if exists public.match_players cascade;

-- -----------------------------------------------------------------------------
-- Lineup Boundary (match_players)
-- -----------------------------------------------------------------------------
create table public.match_players (
  match_player_id        uuid primary key default gen_random_uuid(),
  match_id               uuid not null references public.matches(match_id) on delete cascade,
  team_side              text not null check (team_side in ('team_a', 'team_b')),
  
  user_id                uuid references public.profiles(user_id) on delete set null,
  unclaimed_id           uuid references public.unclaimed_players(unclaimed_id) on delete set null,
  
  display_name           text not null,
  jersey_number          smallint check (jersey_number is null or (jersey_number between 0 and 99)),
  role                   public.match_role not null default 'player',
  is_in_playing_xi       boolean not null default true,
  batting_order          smallint check (batting_order is null or (batting_order between 1 and 15)),

  created_at             timestamptz not null default now(),

  -- Exactly one of (user_id, unclaimed_id). Same shape as
  -- team_members.player_ref_xor so the two read identically.
  constraint chk_match_player_identity check (
    num_nonnulls(user_id, unclaimed_id) = 1
  ),
  unique(match_id, user_id),
  unique(match_id, unclaimed_id)
);

alter table public.match_players enable row level security;

drop policy if exists "match_players_read_all" on public.match_players;

create policy "match_players_read_all" on public.match_players for select
  to anon, authenticated
  using (true);

create index if not exists idx_match_players_user on public.match_players(user_id) where user_id is not null;

create index if not exists idx_match_players_unclaimed on public.match_players(unclaimed_id) where unclaimed_id is not null;

create index if not exists idx_match_players_match on public.match_players(match_id);

-- =============================================================================
-- match_players sport integrity
-- =============================================================================

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

  select m.sport_id
  into v_match_sport
  from public.matches m
  where m.match_id = new.match_id;

  select up.sport_id
  into v_player_sport
  from public.unclaimed_players up
  where up.unclaimed_id = new.unclaimed_id;

  if v_match_sport is not null
     and v_player_sport is not null
     and v_match_sport is distinct from v_player_sport then

    raise exception
      'Unclaimed player sport (%) does not match match sport (%)',
      v_player_sport,
      v_match_sport
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all
  on function public.enforce_unclaimed_match_sport()
  from public, anon, authenticated;

create trigger match_players_enforce_unclaimed_sport
  before insert
      or update of match_id, unclaimed_id
  on public.match_players
  for each row
  execute function public.enforce_unclaimed_match_sport();

