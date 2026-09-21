-- Migration file: 20260101000400_matches.sql

-- 0400 · matches
-- Match fixtures, rules, scheduling, teams and result snapshots.
-- Spec: docs/matches-schema-architecture.md
-- The canonical match-format shape
-- One place that decides what a format document looks like. Every key the
-- client's MatchDto and the Dart scoring engine read is guaranteed present with
-- a sane value, so no downstream reader has to guess what a missing key means.
--
-- `overs_per_innings` matters most: the engine treats 0 as "unlimited" (Test
-- cricket), so a format that merely omits it silently produces an innings that
-- never ends. `max_overs` is accepted as an alias because that is the key the
-- old `rules_config` column used before it was merged into `format`
-- (2026-09-06); competition RPCs that revise conditions write the canonical
-- key.
--
-- Moved here from 20260822110000 during the 2026-09-06 consolidation so that
-- `matches.format` can carry a playable DEFAULT from the moment the table
-- exists, rather than acquiring one two hundred migrations later.

-- Section: Functions

-- Section: Tables and constraints

-- Matches
create table public.matches(
  match_id uuid primary key default gen_random_uuid(),
  tournament_id uuid references public.tournaments(tournament_id) on delete set null,
  match_type public.match_type not null default 'friendly',
  stage public.match_stage,
  round text,
  bracket_round_number integer check (bracket_round_number is null or bracket_round_number >= 1),
  bracket_match_number integer check (bracket_match_number is null or bracket_match_number >= 1),
  prev_match_a_id uuid references public.matches(match_id) on delete set null,
  prev_match_b_id uuid references public.matches(match_id) on delete set null,
  group_id text,
  venue text,
  ground_id uuid references public.grounds(ground_id) on delete set null,
  sport_id text not null default 'cricket' references public.sports(sport_id),
  scheduled_start_time timestamptz not null default now(),
  actual_start_time timestamptz,
  completed_at timestamptz,
  status public.match_status not null default 'scheduled',
  winner_id uuid references public.teams(team_id) on delete set null,
  team_a_id uuid references public.teams(team_id) on delete set null,
  team_b_id uuid references public.teams(team_id) on delete set null,
  created_by uuid references public.profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.matches is 'Sport-neutral match shell. Sport-specific rules, toss/start state, result detail and sport-specific participant roles live in sport extensions.';

-- Section: Enable row-level security

alter table public.matches enable row level security;

-- Section: Policies

-- Public Read Policies
drop policy if exists "matches_read_all" on public.matches;

create policy "matches_read_all" on public.matches
  for select to anon, authenticated
  using (true);

-- Section: Indexes

-- Performance Indexes
create index idx_matches_status_time on public.matches(status, scheduled_start_time desc);

create index idx_matches_tournament on public.matches(tournament_id)
where
  tournament_id is not null;

create index idx_matches_team_a on public.matches(team_a_id)
where
  team_a_id is not null;

create index idx_matches_team_b on public.matches(team_b_id)
where
  team_b_id is not null;

create index matches_sport_id on public.matches(sport_id);

-- Section: Dependency-ordered operations

-- Matches
do $$
begin
  if not exists(
    select
      1
    from
      pg_constraint
    where
      conrelid = 'public.matches'::regclass
      and conname = 'matches_sport_id_fkey') then
  alter table public.matches
    add constraint matches_sport_id_fkey foreign key(sport_id) references public.sports(sport_id) on update restrict on delete restrict;
end if;
end
$$;

comment on column public.matches.sport_id is 'Stable sport identity of this match. For tournament/team matches the '
  'database derives and validates it from the related entities.';

-- The scheduler's lookup: "what else is on this ground around this time".
comment on column public.matches.venue is 'Free-text ground name, NULL when unknown. Retained for casual matches with '
  'no registered ground. Tournament fixtures should set ground_id and mirror '
  'the name here for display.';

-- Section: Functions (continued)

-- 7. Match sport integrity
--
-- The match sport is authoritative on the match row, but when relations are
-- present the database derives it from:
--
--   tournament
--   team A
--   team B
--
-- All supplied relations must agree.
--
-- This also supports unresolved tournament fixtures where team A/B may still
-- be NULL.
create or replace function public.enforce_match_sport()
  returns trigger
  language plpgsql
  set search_path = public, pg_temp
  as $$
declare
  v_tournament_sport text;
  v_team_a_sport text;
  v_team_b_sport text;
  v_effective_sport text;
begin
  if new.tournament_id is not null then
    select
      t.sport_id
    into
      v_tournament_sport
    from
      public.tournaments t
    where
      t.tournament_id = new.tournament_id;
  end if;
  if new.team_a_id is not null then
    select
      t.sport_id
    into
      v_team_a_sport
    from
      public.teams t
    where
      t.team_id = new.team_a_id;
  end if;
  if new.team_b_id is not null then
    select
      t.sport_id
    into
      v_team_b_sport
    from
      public.teams t
    where
      t.team_id = new.team_b_id;
  end if;
  -- First ensure the related entities themselves agree.
  if v_team_a_sport is not null and v_team_b_sport is not null and v_team_a_sport is distinct from v_team_b_sport then
    raise exception 'Both match teams must belong to the same sport'
      using errcode = '23514';
  end if;
  if v_tournament_sport is not null and v_team_a_sport is not null and v_tournament_sport is distinct from v_team_a_sport then
    raise exception 'Team A sport (%) does not match tournament sport (%)', v_team_a_sport, v_tournament_sport
      using errcode = '23514';
  end if;
  if v_tournament_sport is not null and v_team_b_sport is not null and v_tournament_sport is distinct from v_team_b_sport then
    raise exception 'Team B sport (%) does not match tournament sport (%)', v_team_b_sport, v_tournament_sport
      using errcode = '23514';
  end if;
  -- Validate that caller-supplied sport_id does not conflict with related entities
  if new.sport_id is not null then
    if v_team_a_sport is not null and new.sport_id is distinct from v_team_a_sport then
      raise exception 'Match sport (%) does not match Team A sport (%)', new.sport_id, v_team_a_sport
        using errcode = '23514';
    end if;
    if v_team_b_sport is not null and new.sport_id is distinct from v_team_b_sport then
      raise exception 'Match sport (%) does not match Team B sport (%)', new.sport_id, v_team_b_sport
        using errcode = '23514';
    end if;
    if v_tournament_sport is not null and new.sport_id is distinct from v_tournament_sport then
      raise exception 'Match sport (%) does not match tournament sport (%)', new.sport_id, v_tournament_sport
        using errcode = '23514';
    end if;
  end if;
  -- Relationships are more authoritative than default sport_id.
  v_effective_sport := coalesce(v_tournament_sport, v_team_a_sport, v_team_b_sport, new.sport_id, 'cricket');
  new.sport_id := v_effective_sport;
  return new;
end;
$$;

revoke all on function public.enforce_match_sport() from public, anon, authenticated;

-- Section: Triggers

create trigger matches_enforce_sport
  before insert or update of tournament_id,
  team_a_id,
  team_b_id,
  sport_id on public.matches for each row
  execute function public.enforce_match_sport();

-- Match sport is identity and is immutable after creation
create trigger matches_sport_immutable
  before update on public.matches for each row
  execute function public.prevent_sport_reassignment();

comment on column public.matches.sport_id is 'Immutable sport identity of this match. Related teams/tournament must '
  'agree with it. Sport-specific match rules/state live outside matches.';

-- Section: Indexes (continued)

create index if not exists matches_ground_time on public.matches(ground_id, scheduled_start_time)
where
  ground_id is not null;

create index if not exists idx_matches_tournament_winner on public.matches(tournament_id, winner_id)
where
  tournament_id is not null;

create index if not exists idx_matches_created_by on public.matches(created_by);

create index if not exists idx_matches_prev_match_a_id on public.matches(prev_match_a_id);

create index if not exists idx_matches_prev_match_b_id on public.matches(prev_match_b_id);

create index if not exists idx_matches_winner_id on public.matches(winner_id);

