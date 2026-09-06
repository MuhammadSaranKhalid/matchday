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
  to anon, authenticated
  using (true);

create policy "player_profiles_write_self"
  on public.player_profiles for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

