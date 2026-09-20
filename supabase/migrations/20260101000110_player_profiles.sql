-- =============================================================================
-- 0110 · player_profiles
-- =============================================================================
-- Spec §1.4. Optional 1:1 extension of profiles for users who play. A
-- profile exists for every signed-in user, but a player_profile only exists
-- if the user has filled in cricket-specific details during onboarding's
-- "are you a player?" branch.
--
-- Flow:
--   - Onboarding asks: "Do you play cricket?"
--   - If yes → INSERT into player_profiles (or UPSERT) with batting_style,
--     bowling_style, player_role, preferred_ball_types, years_playing.
--   - If no  → no row written. The Pavilion / leaderboards skip them.
--
-- Stats migrations (claim flow §2.5/§2.6) reference these fields when an
-- unclaimed player's stats merge into a real user's account: if the user's
-- player_profile is empty, the unclaimed_players.player_profile JSON is
-- copied over by the cascade trigger.
-- =============================================================================

-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.

-- -----------------------------------------------------------------------------
-- cricket_player_profiles table.
-- -----------------------------------------------------------------------------
create table public.cricket_player_profiles (
  user_id               uuid primary key
                          references public.profiles(user_id) on delete cascade,
  sport_id              text not null default 'cricket'
                          references public.sports(sport_id) on update restrict on delete restrict,
  batting_style         public.batting_style,
  bowling_style         public.bowling_style,
  player_role           public.player_role,
  preferred_ball_types  public.ball_type[] not null default '{}',
  years_playing         integer
                          check (years_playing is null or years_playing between 0 and 80),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger cricket_player_profiles_set_updated_at
  before update on public.cricket_player_profiles
  for each row execute function public.set_updated_at();

-- Clean object names left behind by PostgreSQL's table rename.

alter table public.cricket_player_profiles
  rename constraint player_profiles_pkey
  to cricket_player_profiles_pkey;

alter table public.cricket_player_profiles
  rename constraint player_profiles_years_playing_check
  to cricket_player_profiles_years_playing_check;

alter trigger player_profiles_set_updated_at
  on public.cricket_player_profiles
  rename to cricket_player_profiles_set_updated_at;


-- =============================================================================
-- 5. Bind the Cricket profile to player_sports
-- =============================================================================

alter table public.cricket_player_profiles
  add column sport_id text not null default 'cricket';


-- This table can NEVER accidentally contain Football/etc. data.

alter table public.cricket_player_profiles
  add constraint cricket_player_profiles_sport_check
  check (sport_id = 'cricket');


-- The old table referenced profiles directly.
--
-- It should now belong to the shared player_sports identity instead:
--
-- profiles
--    ↓
-- player_sports
--    ↓
-- cricket_player_profiles

alter table public.cricket_player_profiles
  add constraint cricket_player_profiles_player_sport_fkey
  foreign key (user_id, sport_id)
  references public.player_sports(user_id, sport_id)
  on update restrict
  on delete cascade;

comment on table public.cricket_player_profiles is
  'Cricket-specific player attributes. A row requires the corresponding '
  '(user_id, cricket) identity in player_sports.';

comment on column public.cricket_player_profiles.sport_id is
  'Always cricket. Present to enforce the composite FK to player_sports.';


-- =============================================================================
-- 6. Rebuild Cricket profile RLS with explicit names
-- =============================================================================

alter table public.cricket_player_profiles
  enable row level security;


drop policy if exists "player_profiles_read_public"
  on public.cricket_player_profiles;

drop policy if exists "player_profiles_write_self"
  on public.cricket_player_profiles;


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
    (select auth.uid()) = user_id
    and sport_id = 'cricket'
  );


create policy "cricket_player_profiles_update_self"
  on public.cricket_player_profiles
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
  )
  with check (
    (select auth.uid()) = user_id
    and sport_id = 'cricket'
  );


create policy "cricket_player_profiles_delete_self"
  on public.cricket_player_profiles
  for delete
  to authenticated
  using (
    (select auth.uid()) = user_id
  );


revoke all
  on table public.cricket_player_profiles
  from anon, authenticated;

grant select
  on table public.cricket_player_profiles
  to anon, authenticated;

grant insert, update, delete
  on table public.cricket_player_profiles
  to authenticated;

grant all
  on table public.cricket_player_profiles
  to service_role;

