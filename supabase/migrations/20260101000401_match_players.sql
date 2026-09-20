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
  unique(match_id, unclaimed_id),
  unique(match_player_id, match_id)
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


-- =============================================================================
-- Registered player-sport activation from match participation
-- =============================================================================
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
-- =============================================================================


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


  select m.sport_id
  into v_sport_id
  from public.matches m
  where m.match_id = new.match_id;


  if v_sport_id is null then
    raise exception 'Match sport could not be resolved'
      using errcode = 'P0002';
  end if;


  insert into public.player_sports (
    user_id,
    sport_id
  )
  values (
    new.user_id,
    v_sport_id
  )
  on conflict (user_id, sport_id)
  do nothing;


  return new;
end;
$$;


revoke all
  on function public.activate_player_sport_from_match_player()
  from public, anon, authenticated;


create trigger match_players_activate_player_sport
  after insert
      or update of user_id, match_id
  on public.match_players
  for each row
  execute function public.activate_player_sport_from_match_player();


-- =============================================================================
-- Cricket participant extension
-- =============================================================================

create table public.cricket_match_players (
  match_player_id uuid primary key,
  match_id uuid not null,

  is_playing_xi boolean not null default true,

  batting_order smallint
    check (
      batting_order is null
      or batting_order between 1 and 15
    ),

  -- Deliberately independent booleans. A Cricket player may simultaneously
  -- be captain + wicket-keeper; the legacy single match_role enum cannot
  -- represent that combination.
  is_captain boolean not null default false,
  is_vice_captain boolean not null default false,
  is_wicket_keeper boolean not null default false,
  is_substitute boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint cricket_match_players_parent_player_fkey
    foreign key (match_player_id, match_id)
    references public.match_players(match_player_id, match_id)
    on delete cascade,

  constraint cricket_match_players_cricket_match_fkey
    foreign key (match_id)
    references public.cricket_matches(match_id)
    on delete cascade
);


comment on table public.cricket_match_players is
  'Cricket-only per-match player state. Shared identity remains in '
  'match_players. Captain, wicket-keeper and substitute are independent '
  'facts rather than mutually-exclusive roles.';


create trigger cricket_match_players_set_updated_at
  before update on public.cricket_match_players
  for each row
  execute function public.set_updated_at();


alter table public.cricket_match_players enable row level security;

create policy "cricket_match_players_read_all"
  on public.cricket_match_players
  for select
  to anon, authenticated
  using (true);

revoke all
  on table public.cricket_match_players
  from anon, authenticated;

grant select
  on table public.cricket_match_players
  to anon, authenticated;

grant all
  on table public.cricket_match_players
  to service_role;

create index cricket_match_players_match
  on public.cricket_match_players (match_id);


-- Existing writers still write role/is_in_playing_xi/batting_order on
-- match_players. Mirror those fields until Phase 2 moves the writers.

create or replace function public.sync_legacy_match_player_to_cricket_extension()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1
    from public.matches m
    where m.match_id = new.match_id
      and m.sport_id = 'cricket'
  ) then
    return new;
  end if;

  -- The match INSERT trigger creates cricket_matches before match_players are
  -- materialised. This guard makes the dependency explicit.
  if not exists (
    select 1
    from public.cricket_matches cm
    where cm.match_id = new.match_id
  ) then
    raise exception
      'Cricket match extension is missing for match %',
      new.match_id
      using errcode = '23503';
  end if;

  insert into public.cricket_match_players (
    match_player_id,
    match_id,
    is_playing_xi,
    batting_order,
    is_captain,
    is_vice_captain,
    is_wicket_keeper,
    is_substitute
  )
  values (
    new.match_player_id,
    new.match_id,
    new.is_in_playing_xi,
    new.batting_order,
    new.role = 'captain',
    new.role = 'vice_captain',
    new.role = 'wicket_keeper',
    new.role = 'substitute'
  )
  on conflict (match_player_id)
  do update set
    match_id          = excluded.match_id,
    is_playing_xi     = excluded.is_playing_xi,
    batting_order     = excluded.batting_order,
    is_captain        = excluded.is_captain,
    is_vice_captain   = excluded.is_vice_captain,
    is_wicket_keeper  = excluded.is_wicket_keeper,
    is_substitute     = excluded.is_substitute,
    updated_at        = now();

  return new;
end;
$$;

revoke all
  on function public.sync_legacy_match_player_to_cricket_extension()
  from public, anon, authenticated;


drop trigger if exists match_players_sync_cricket_extension
  on public.match_players;

create trigger match_players_sync_cricket_extension
  after insert
      or update of
        match_id,
        role,
        is_in_playing_xi,
        batting_order
  on public.match_players
  for each row
  execute function public.sync_legacy_match_player_to_cricket_extension();


-- =============================================================================
-- Transitional legacy column comments
-- =============================================================================

comment on column public.match_players.role is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored into independent flags on '
  'cricket_match_players.';

comment on column public.match_players.is_in_playing_xi is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_match_players.is_playing_xi.';

comment on column public.match_players.batting_order is
  'DEPRECATED TRANSITIONAL CRICKET FIELD. Mirrored to '
  'cricket_match_players.batting_order.';


