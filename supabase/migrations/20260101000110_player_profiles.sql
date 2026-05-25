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

-- -----------------------------------------------------------------------------
-- Cricket-specific enums.
-- -----------------------------------------------------------------------------
create type public.batting_style as enum ('right_hand', 'left_hand');
create type public.bowling_style as enum (
  'right_arm_fast',
  'right_arm_medium',
  'right_arm_spin',
  'left_arm_fast',
  'left_arm_spin',
  'doesnt_bowl'
);
create type public.player_role as enum (
  'batter',
  'bowler',
  'all_rounder',
  'wicket_keeper'
);
create type public.ball_type as enum ('leather', 'tape', 'tennis');

-- -----------------------------------------------------------------------------
-- player_profiles table.
-- -----------------------------------------------------------------------------
create table public.player_profiles (
  user_id               uuid primary key
                          references public.profiles(user_id) on delete cascade,
  batting_style         public.batting_style,
  bowling_style         public.bowling_style,
  player_role           public.player_role,
  preferred_ball_types  public.ball_type[] not null default '{}',
  years_playing         integer
                          check (years_playing is null or years_playing between 0 and 80),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger player_profiles_set_updated_at
  before update on public.player_profiles
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — public read; owner-only write.
-- -----------------------------------------------------------------------------
alter table public.player_profiles enable row level security;

create policy "player_profiles_read_public"
  on public.player_profiles for select
  using (true);

create policy "player_profiles_write_self"
  on public.player_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

