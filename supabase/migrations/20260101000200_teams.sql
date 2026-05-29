-- =============================================================================
-- 0200 · teams
-- =============================================================================
-- Spec §2.3, §2.12. Feature 2 (Team & Player Model).
--
-- The `teams` row is the durable identity of a club / village / casual side.
-- Memberships live in 0210_team_members; join requests in 0220; claim
-- requests in 0230. Tournament registrations reference team_id from 0310.
--
-- Manager model:
--   - Exactly one `owner_id` (the user who created the team). Cannot be
--     deleted while the team exists (FK ON DELETE RESTRICT).
--   - `managers` is a uuid[] of co-managers. Owner is implicitly a manager;
--     RLS predicates check both. Stored as an array per spec §2.3.
--   - is_team_manager() is the single source of truth — every later
--     migration uses it for RLS / RPC authorization.
--
-- Privacy / discoverability:
--   - `privacy = 'private'` — team profile + roster hidden from non-members.
--   - `max_squad_size` — soft cap (default 25, range 11–50). Enforced by
--     application code, not the DB, so the UI can show "X/25" hints.
--
-- Roster joining: there is only one direction in v1.0 — manager-initiated
-- invites (table `team_invites` in 0240). The player-initiated "ask to join"
-- flow was deleted as redundant; reintroduce by adding a join_requests table
-- + a discovery surface if v1.1 brings team browsing back.
--
-- Storage: the team-logos bucket lives here; folder convention <team_id>/.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Team-only enums.
-- -----------------------------------------------------------------------------
create type public.team_type as enum (
  'club',
  'village',
  'casual',
  'corporate',
  'school',
  'university'
);
create type public.team_privacy as enum ('public', 'private');
create type public.team_status  as enum ('active', 'disbanded', 'archived');

-- -----------------------------------------------------------------------------
-- teams table.
-- -----------------------------------------------------------------------------
create table public.teams (
  team_id             uuid primary key default gen_random_uuid(),
  team_name           text not null check (length(team_name) between 3 and 50),
  team_type           public.team_type not null,
  -- Optional short marketing line shown on team cards.
  tagline             text check (tagline is null or length(tagline) <= 60),
  logo_url            text,
  -- 1–3 letter override for the placeholder logo when no logo_url is set.
  logo_monogram       text check (logo_monogram is null
                                  or length(logo_monogram) between 1 and 3),
  team_colors         jsonb,                              -- {primary, secondary} hex
  description         text check (description is null or length(description) <= 500),
  home_ground         text,

  -- Same shape as profiles.location.
  location            jsonb not null default '{}'::jsonb,
  location_point      geography(point, 4326) generated always as (
                         case
                           when location ? 'lat' and location ? 'lng' then
                             st_setsrid(
                               st_makepoint(
                                 (location->>'lng')::double precision,
                                 (location->>'lat')::double precision
                               ),
                               4326
                             )::geography
                           else null
                         end
                       ) stored,

  founded_year        integer
                       check (founded_year is null
                              or founded_year between 1700
                                 and date_part('year', now())::int + 1),

  -- Nullable + ON DELETE SET NULL so self-service account deletion (the
  -- delete_user RPC in 0700) does not block on team ownership. An
  -- ownerless team is a "needs attention" state; a manager from the
  -- `managers` array can take over via a future ownership-transfer RPC.
  owner_id            uuid
                          references public.profiles(user_id) on delete set null,
  managers            uuid[] not null default '{}',

  is_verified         boolean not null default false,
  privacy             public.team_privacy not null default 'public',
  status              public.team_status  not null default 'active',
  -- Spec §2.11: configurable squad size (floor 11 — minimum match-day XI;
  -- ceiling 50 — design's stepper max).
  max_squad_size      integer not null default 25
                       check (max_squad_size between 11 and 50),

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------
create index teams_owner          on public.teams (owner_id);
create index teams_managers_gin   on public.teams using gin (managers);
create index teams_city           on public.teams ((location->>'city'));
create index teams_location_point on public.teams using gist (location_point);
create index teams_name_trgm      on public.teams using gin (team_name gin_trgm_ops);

create trigger teams_set_updated_at
  before update on public.teams
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- is_team_manager — the universal RLS predicate. SECURITY DEFINER so policies
-- on other tables can ask "is the caller a manager of <team_id>?" without
-- recursing through the teams table's own policies.
-- -----------------------------------------------------------------------------
create or replace function public.is_team_manager(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.teams t
     where t.team_id = p_team_id
       and (t.owner_id = auth.uid() or auth.uid() = any(t.managers))
  );
$$;

revoke all on function public.is_team_manager(uuid) from public;
grant execute on function public.is_team_manager(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS — public read; create-by-self-as-owner; update by manager/owner.
-- -----------------------------------------------------------------------------
alter table public.teams enable row level security;

create policy "teams_read_public"
  on public.teams for select
  using (true);

create policy "teams_insert_self_owner"
  on public.teams for insert
  to authenticated
  with check ((select auth.uid()) = owner_id);

create policy "teams_update_managers"
  on public.teams for update
  to authenticated
  using ((select auth.uid()) = owner_id or (select auth.uid()) = any(managers))
  with check ((select auth.uid()) = owner_id or (select auth.uid()) = any(managers));

create policy "teams_delete_owner"
  on public.teams for delete
  to authenticated
  using ((select auth.uid()) = owner_id);

-- =============================================================================
-- Storage bucket: team-logos
-- Public-read; manager-only write under <team_id>/.
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'team-logos',
  'team-logos',
  true,
  5 * 1024 * 1024,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "team_logos_read_public"
  on storage.objects for select
  using (bucket_id = 'team-logos');

create policy "team_logos_insert_manager"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'team-logos'
    and public.is_team_manager(((storage.foldername(name))[1])::uuid)
  );

create policy "team_logos_update_manager"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'team-logos'
    and public.is_team_manager(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'team-logos'
    and public.is_team_manager(((storage.foldername(name))[1])::uuid)
  );

create policy "team_logos_delete_manager"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'team-logos'
    and public.is_team_manager(((storage.foldername(name))[1])::uuid)
  );
