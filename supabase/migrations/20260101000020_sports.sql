-- =============================================================================
-- Sports Kernel v1
-- =============================================================================
--
-- Domain contract:
--
--   * A user may participate in many sports.
--   * A team belongs to exactly one sport.
--   * A tournament belongs to exactly one sport.
--   * A match belongs to exactly one sport.
--   * A match-format preset belongs to exactly one sport.
--   * A match challenge belongs to exactly one sport.
--
-- Cricket is the only supported sport today.
--
-- IMPORTANT:
--   player_profiles remains cricket-specific and is NOT part of the shared
--   sport kernel. It will be redesigned separately when multi-sport player
--   profiles are introduced.
--
-- `sport_id` defaults to 'cricket' temporarily so the existing application
-- and RPCs remain backward-compatible. Before the second sport ships, client
-- creation flows must send sport_id explicitly.
-- =============================================================================


-- =============================================================================
-- 1. Sports catalog
-- =============================================================================

create table if not exists public.sports (
  sport_id   text primary key check (sport_id ~ '^[a-z][a-z0-9_]{1,30}$'),
  name       text not null check (length(btrim(name)) >= 2 and length(btrim(name)) <= 40),
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.sports is
  'Stable catalog of sports supported by Matchday. '
  'Sport-specific rules and scoring models do not belong in this table.';

comment on column public.sports.sport_id is
  'Stable machine identifier such as cricket or football. '
  'It is not a display label and must not be renamed after use.';


-- Cricket is the only real sport for now.

insert into public.sports (
  sport_id,
  name,
  is_active
)
values (
  'cricket',
  'Cricket',
  true
)
on conflict (sport_id) do update
set
  name      = excluded.name,
  is_active = excluded.is_active;


-- =============================================================================
-- 2. Security / Data API access
-- =============================================================================

alter table public.sports enable row level security;

drop policy if exists "sports_read_all" on public.sports;

create policy "sports_read_all"
  on public.sports
  for select
  to anon, authenticated
  using (true);


-- This table is system-owned reference data.
--
-- The application may read the catalog but must not create/edit/delete sports.
-- New sports are introduced by migrations.

revoke all on table public.sports from anon, authenticated;

grant select
  on table public.sports
  to anon, authenticated;

grant all
  on table public.sports
  to service_role;


-- =============================================================================
-- 5. Sport ownership is immutable
-- =============================================================================
--
-- Changing a Cricket team into a Football team is not an update to the same
-- domain entity. It is a different team.
--
-- The same principle applies to tournaments and format presets.
-- =============================================================================

create or replace function public.prevent_sport_reassignment()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.sport_id is distinct from old.sport_id then
    raise exception
      'sport_id cannot be changed after creation (% -> %)',
      old.sport_id,
      new.sport_id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

revoke all
  on function public.prevent_sport_reassignment()
  from public, anon, authenticated;


-- =============================================================================
-- 9. Documentation comments
-- =============================================================================

-- comment on function public.enforce_tournament_team_sport() is
--   'Rejects registration of a team into a tournament belonging to another sport.';

-- comment on function public.enforce_match_sport() is
--   'Derives matches.sport_id from tournament/team relations and rejects '
--   'cross-sport matches.';

-- comment on function public.enforce_match_challenge_sport() is
--   'Derives a challenge sport from its sending team and rejects a receiving '
--   'team from another sport.';

-- comment on function public.prevent_sport_reassignment() is
--   'Protects sport identity of durable domain entities after creation.';