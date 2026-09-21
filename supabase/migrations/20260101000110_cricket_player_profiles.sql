-- =============================================================================
-- Migration: 20260101000110_cricket_player_profiles.sql
-- =============================================================================

-- 0110 · cricket_player_profiles
--
-- OPTIONAL Cricket-specific attributes for a registered Cricket player.
--
-- Identity:
--
--   player_sports(user_id, 'cricket')
--
-- Optional details:
--
--   cricket_player_profiles
--
-- Therefore this is valid:
--
--   player_sports
--      U1 | cricket
--
--   cricket_player_profiles
--      no row
--
-- It means U1 is a Cricket player but has not supplied optional Cricket
-- attributes such as batting style or bowling style.
-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.
-- cricket_player_profiles table.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.cricket_player_profiles (
  user_id              uuid primary key
    references public.profiles (user_id)
    on delete cascade,
  sport_id             text not null default 'cricket' check (sport_id = 'cricket'),
  batting_style        public.batting_style,
  bowling_style        public.bowling_style,
  player_role          public.player_role,
  preferred_ball_types public.ball_type[] not null default '{}',
  years_playing        integer
    check (years_playing is null or years_playing between 0 and 80),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger cricket_player_profiles_set_updated_at
  before update on public.cricket_player_profiles
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

-- Bind the Cricket profile to player_sports
--
-- profiles
--    ↓
-- player_sports
--    ↓
-- cricket_player_profiles
alter table public.cricket_player_profiles
add constraint cricket_player_profiles_player_sport_fkey
  foreign key (user_id, sport_id) references public.player_sports (user_id, sport_id)
    on update restrict
    on delete cascade;

comment on table public.cricket_player_profiles is
  'Cricket-specific player attributes. A row requires the corresponding '
  '(user_id, cricket) identity in player_sports.';

comment on column public.cricket_player_profiles.sport_id is
  'Always cricket. Present to enforce the composite FK to player_sports.';

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.cricket_player_profiles enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "cricket_player_profiles_read_public"
  on public.cricket_player_profiles
  for select
  to anon, authenticated
  using (true);

create policy "cricket_player_profiles_insert_self"
  on public.cricket_player_profiles
  for insert
  to authenticated
  with check (
    (
      select
        auth.uid()
    ) = user_id
    and sport_id = 'cricket'
  );

create policy "cricket_player_profiles_update_self"
  on public.cricket_player_profiles
  for update
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = user_id
  )
  with check (
    (
      select
        auth.uid()
    ) = user_id
    and sport_id = 'cricket'
  );

create policy "cricket_player_profiles_delete_self"
  on public.cricket_player_profiles
  for delete
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = user_id
  );

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on table public.cricket_player_profiles from anon, authenticated;

grant select on table public.cricket_player_profiles to anon, authenticated;

grant insert, update, delete on table public.cricket_player_profiles to authenticated;

grant all on table public.cricket_player_profiles to service_role;
