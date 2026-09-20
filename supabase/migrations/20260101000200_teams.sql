-- =============================================================================
-- 0200 · teams
-- =============================================================================
-- Spec §2.3, §2.12. Feature 2 (Team & Player Model).
--
-- The `teams` row is the durable identity of a club / village / casual side.
-- Memberships live in 0210_team_members; join requests in 0220; claim
-- requests in 0230. Tournament registrations reference team_id from 0310.
--
-- Manager model (REWRITTEN 2026-09-10 — see docs/team-roles-design.md):
--   - Authority lives in `team_member_roles` (0210). A member holds ANY
--     number of roles; `owner` is one of them, and it is the CANONICAL
--     answer to "who runs this team?".
--   - There is no `managers uuid[]`, and since 2026-09-11 no `owner_id`
--     either. `created_by` replaces it: immutable, historical, "who made
--     this team" — and NEVER consulted for authorization. Storing
--     ownership in a column *and* a role was the same
--     two-sources-of-truth defect this whole redesign exists to remove.
--   - An AFTER INSERT trigger (0210) creates the creator's membership and
--     its `owner` role in one transaction.
--
--   ⚠️ WHY THE PREDICATE IS NOT IN THIS FILE. `is_team_manager()` /
--   `is_team_captain()` now read `team_members`, which does not exist until
--   0210. They are `language sql`, so their bodies ARE checked at CREATE
--   time (§12.0) and would fail here. They live in 0210 alongside the table
--   that stores the ladder — the same reason
--   `unclaimed_player_contact_for_manager` sits there rather than in 0120.
--
--   The knock-on: the policies below that need the predicate (teams UPDATE,
--   and the three team-logos write policies) are ALSO declared in 0210, in a
--   clearly-labelled section. This is the one place a table's policies are
--   split across two files; the alternative was a plpgsql predicate whose
--   body is unchecked, which is the trap §12.0 exists to prevent.
--
-- Privacy / discoverability:
--   - `privacy = 'private'` — team profile + roster hidden from non-members.
--     Enforced on `team_members` SELECT as of 2026-09-10; before that a
--     private team's whole roster was readable by anon.
--   - `max_squad_size` — soft cap (default 25, range 11–50). Enforced by
--     application code, not the DB, so the UI can show "X/25" hints. Counts
--     members with `in_squad = true` only.
--
-- Roster joining: BOTH directions exist. Manager-initiated invites live in
-- `team_invites` (0240); player-initiated requests in `team_join_requests`
-- (20260612000000). (This comment previously claimed the join-request flow
-- "was deleted as redundant" — stale since 20260612000000 reintroduced it.)
--
-- Storage: the team-logos bucket lives here; folder convention <team_id>/.
-- =============================================================================

-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.

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

  sport_id            text not null default 'cricket' references public.sports(sport_id),

  -- 1–3 letter override for the placeholder logo when no logo_url is set.
  logo_monogram       text check (logo_monogram is null
                                  or length(logo_monogram) between 1 and 3),
  team_colors         jsonb,                              -- {primary, secondary} hex
  description         text check (description is null or length(description) <= 500),
  home_ground         text,

  founded_year        integer
                       check (founded_year is null
                              or founded_year between 1700
                                 and date_part('year', now())::int + 1),

  -- WHO MADE THIS TEAM. History, not authority — see the header. It is what
  -- `teams_insert_self_owner` checks (a value must exist at INSERT time,
  -- before any membership row can), and what the chat-admin and geo-backfill
  -- triggers legitimately want. Authorization asks the `owner` role instead.
  --
  -- Nullable + ON DELETE SET NULL so self-service account deletion (0700) does
  -- not block. Ownership succession happens on the ROLE: the longest-tenured
  -- manager is promoted, and a team with no manager left is archived.
  created_by          uuid
                          references public.profiles(user_id) on delete set null,

  is_verified         boolean not null default false,
  privacy             public.team_privacy not null default 'public',
  status              public.team_status  not null default 'active',
  -- Spec §2.11: configurable squad size (floor 11 — minimum match-day XI;
  -- ceiling 50 — design's stepper max).
  max_squad_size      integer not null default 25
                       check (max_squad_size between 11 and 50),

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  -- Normalised team_name for trigram search. GENERATED — never write it.
  -- f_unaccent() is declared in 0000_shared_helpers.
  search_name         text generated always as (
                        lower(public.f_unaccent(team_name))
                      ) stored
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------
create index teams_created_by     on public.teams (created_by);
create index teams_sport_id       on public.teams (sport_id);
-- teams_managers_gin dropped 2026-09-10 with the `managers uuid[]` column.
-- The equivalent lookup ("which teams do I run?") is now
-- team_members_team_role in 0210.
-- create index teams_city           on public.teams ((location->>'city'));
-- create index teams_location_point on public.teams using gist (location_point);
create index teams_name_trgm      on public.teams using gin (team_name gin_trgm_ops);

create trigger teams_set_updated_at
  before update on public.teams
  for each row execute function public.set_updated_at();

create trigger teams_sport_immutable
  before update of sport_id
  on public.teams
  for each row
  execute function public.prevent_sport_reassignment();

-- -----------------------------------------------------------------------------
-- is_team_manager / is_team_captain are declared in 0210_team_members.sql.
-- They read the role ladder on `team_members`, and being `language sql` their
-- bodies are checked at CREATE time, so they cannot be declared before that
-- table exists. See the header of this file for the full rationale.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- RLS — public read; create-by-self-as-owner; delete by owner.
--
-- The UPDATE and DELETE policies need can(), and are therefore declared in
-- 0210, in the "policies deferred from 0200" section.
-- -----------------------------------------------------------------------------
alter table public.teams enable row level security;

create policy "teams_read_public"
  on public.teams for select
  to anon, authenticated
  using (true);

create policy "teams_insert_self_owner"
  on public.teams for insert
  to authenticated
  with check ((select auth.uid()) = created_by);


-- teams_delete_owner moved to 0210: it now asks for the `team.disband`
-- permission rather than comparing against a column.

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

-- The three write policies (insert / update / delete) call is_team_manager()
-- and are therefore declared in 0210, in the "policies deferred from 0200"
-- section. The bucket itself has no such dependency and stays here.
