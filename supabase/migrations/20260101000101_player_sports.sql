-- =============================================================================
-- Player Sports
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
