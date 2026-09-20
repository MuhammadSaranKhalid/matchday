-- =============================================================================
-- Player Sports + Cricket Player Profile
-- =============================================================================
--
-- Domain contract:
--
--   profiles
--      = global Matchday identity
--
--   player_sports
--      = sports in which the user has activated a player identity
--      = NOT team membership / authorization
--
--   cricket_player_profiles
--      = Cricket-specific player attributes only
--
-- A user may therefore have:
--
--   (user, cricket)
--   (user, football)
--   (user, badminton)
--
-- simultaneously.
-- =============================================================================


-- =============================================================================
-- 1. Shared player_sports identity
-- =============================================================================

create table public.player_sports (
  user_id uuid not null
    references public.profiles(user_id)
    on delete cascade,

  sport_id text not null
    references public.sports(sport_id)
    on update restrict
    on delete restrict,

  created_at timestamptz not null default now(),

  primary key (user_id, sport_id)
);

comment on table public.player_sports is
  'Sports for which a Matchday user has activated a player identity. '
  'This is not team membership, roster authority, or match participation.';

comment on column public.player_sports.user_id is
  'Global Matchday user identity.';

comment on column public.player_sports.sport_id is
  'Sport for which this user has activated a player identity.';


-- Useful for future:
--
--   "show Cricket players"
--   "show Football players"
--
-- PK(user_id, sport_id) is user-first, so add the inverse lookup.

create index player_sports_sport_user
  on public.player_sports (sport_id, user_id);


-- =============================================================================
-- 2. player_sports security
-- =============================================================================

alter table public.player_sports
  enable row level security;


-- Public player profiles are already part of the Matchday model, so the
-- sports a player identifies with are public as well.

create policy "player_sports_read_public"
  on public.player_sports
  for select
  to anon, authenticated
  using (true);


-- A user may activate an ACTIVE sport only for themselves.

create policy "player_sports_insert_self"
  on public.player_sports
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.sports s
      where s.sport_id = player_sports.sport_id
        and s.is_active = true
    )
  );


-- Removing the row means removing that optional sport-player identity.
-- Sport-specific profile rows cascade with it.

create policy "player_sports_delete_self"
  on public.player_sports
  for delete
  to authenticated
  using (
    (select auth.uid()) = user_id
  );


-- There is nothing mutable on player_sports.
-- sport_id is identity, not an editable attribute.

revoke all
  on table public.player_sports
  from anon, authenticated;

grant select
  on table public.player_sports
  to anon, authenticated;

grant insert, delete
  on table public.player_sports
  to authenticated;

grant all
  on table public.player_sports
  to service_role;


-- =============================================================================
-- 3. Backfill existing Cricket player identities
-- =============================================================================
--
-- Today player_profiles is Cricket-only.
--
-- Every existing row therefore represents:
--
--   (user_id, cricket)
--
-- Production currently has zero rows, but this keeps local/test data safe.
-- =============================================================================

insert into public.player_sports (
  user_id,
  sport_id
)
select
  pp.user_id,
  'cricket'
from public.player_profiles pp
on conflict (user_id, sport_id) do nothing;


-- =============================================================================
-- 4. Rename the old Cricket-specific table
-- =============================================================================

alter table public.player_profiles
  rename to cricket_player_profiles;


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


-- The composite FK above now provides the identity chain.
-- Remove the redundant direct FK to profiles.

alter table public.cricket_player_profiles
  drop constraint if exists player_profiles_user_id_fkey;


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


