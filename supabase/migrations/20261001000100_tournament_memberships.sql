-- =============================================================================
-- Migration: 20261001000100_tournament_root_lifecycle_membership.sql
-- =============================================================================
-- Phase 2: Tournament Root, Lifecycle & Membership Foundation
--
-- 1. Authority vs Provenance:
--    - tournaments.created_by is historical provenance (who originated the row).
--    - tournaments.owner_user_id is the canonical current authority root.
-- 2. Orthogonal Tournament Lifecycle:
--    - publication_state (draft, published)
--    - registration_state (not_open, open, closed)
--    - entry_state (editable, locked)
--    - competition_state (not_started, in_progress, completed)
--    - termination_state (none, cancelled, abandoned)
--    - revision integer (default 1)
--    - Deterministic one-way projection from canonical states to legacy status.
-- 3. Normalized Tournament Membership:
--    - tournament_memberships relation with stable UUID identity, audit trail,
--      removal history preservation, and unique active membership constraint.
-- 4. Tournament Capability Model:
--    - Extend permission_scopes to include 'tournament' scope.
--    - Tournament roles in roles: 'owner' (rank 40), 'manager' (rank 30).
--    - 22 canonical capabilities in permissions.
--    - Default role bundles in role_permissions.
--    - Root authority for owner; delegated capability evaluation for managers.
--    - Scope isolation: Team roles never leak into tournament authority.
-- 5. Compatibility:
--    - Existing organizers[] backfilled into tournament_memberships.
--    - Continuous one-way projection: tournament_memberships -> organizers[].
--    - is_tournament_organizer() transitional wrapper delegating to canonical authority.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Orthogonal Lifecycle Enums
-- -----------------------------------------------------------------------------

do $$
begin
  create type public.tournament_publication_state as enum(
    'draft',
    'published'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.tournament_registration_state as enum(
    'not_open',
    'open',
    'closed'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.tournament_entry_state as enum(
    'editable',
    'locked'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.tournament_competition_state as enum(
    'not_started',
    'in_progress',
    'completed'
  );
exception
  when duplicate_object then null;
end
$$;

do $$
begin
  create type public.tournament_termination_state as enum(
    'none',
    'cancelled',
    'abandoned'
  );
exception
  when duplicate_object then null;
end
$$;

-- -----------------------------------------------------------------------------
-- 2. Add Canonical Root & Lifecycle Columns to tournaments
-- -----------------------------------------------------------------------------

alter table public.tournaments
  add column if not exists owner_user_id uuid references public.profiles(user_id) on delete restrict,
  add column if not exists revision integer not null default 1 check (revision >= 1),
  add column if not exists publication_state public.tournament_publication_state not null default 'draft',
  add column if not exists registration_state public.tournament_registration_state not null default 'not_open',
  add column if not exists entry_state public.tournament_entry_state not null default 'editable',
  add column if not exists competition_state public.tournament_competition_state not null default 'not_started',
  add column if not exists termination_state public.tournament_termination_state not null default 'none';

-- -----------------------------------------------------------------------------
-- 3. Backfill Existing tournaments (Idempotent & Deterministic)
-- -----------------------------------------------------------------------------

-- 3.1 Backfill owner_user_id from created_by or first organizer
update public.tournaments
set owner_user_id = coalesce(
  created_by,
  (case when array_length(organizers, 1) > 0 then organizers[1] else null end)
)
where owner_user_id is null;

-- 3.2 Ensure default owner for edge cases (if any exist without creator/organizer)
-- Fallback to the first existing profile in the system if orphan tournaments exist in test environments.
do $$
declare
  v_fallback_user_id uuid;
begin
  if exists (select 1 from public.tournaments where owner_user_id is null) then
    select user_id into v_fallback_user_id from public.profiles order by created_at limit 1;
    if v_fallback_user_id is not null then
      update public.tournaments set owner_user_id = v_fallback_user_id where owner_user_id is null;
    end if;
  end if;
end
$$;

-- 3.3 Backfill lifecycle states from legacy status
update public.tournaments
set
  publication_state = case
    when status = 'draft' then 'draft'::public.tournament_publication_state
    else 'published'::public.tournament_publication_state
  end,
  registration_state = case
    when status = 'registration' then 'open'::public.tournament_registration_state
    when status in ('upcoming', 'live', 'completed', 'cancelled', 'abandoned') then 'closed'::public.tournament_registration_state
    else 'not_open'::public.tournament_registration_state
  end,
  entry_state = case
    when status in ('upcoming', 'live', 'completed', 'cancelled', 'abandoned') then 'locked'::public.tournament_entry_state
    else 'editable'::public.tournament_entry_state
  end,
  competition_state = case
    when status in ('live', 'abandoned') then 'in_progress'::public.tournament_competition_state
    when status = 'completed' then 'completed'::public.tournament_competition_state
    else 'not_started'::public.tournament_competition_state
  end,
  termination_state = case
    when status = 'cancelled' then 'cancelled'::public.tournament_termination_state
    when status = 'abandoned' then 'abandoned'::public.tournament_termination_state
    else 'none'::public.tournament_termination_state
  end
where publication_state = 'draft' and status != 'draft';

-- Enforce owner_user_id NOT NULL after backfill
alter table public.tournaments
  alter column owner_user_id set not null;

create index if not exists tournaments_owner_user_id
  on public.tournaments (owner_user_id);

-- Invariant constraints on orthogonal lifecycle states
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournaments'::regclass
      and conname = 'tournament_termination_consistency'
  ) then
    alter table public.tournaments
      add constraint tournament_termination_consistency
      check (
        (termination_state = 'none')
        or (termination_state = 'cancelled')
        or (termination_state = 'abandoned' and publication_state = 'published')
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournaments'::regclass
      and conname = 'tournament_publication_competition_consistency'
  ) then
    alter table public.tournaments
      add constraint tournament_publication_competition_consistency
      check (
        publication_state = 'published' or competition_state = 'not_started'
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournaments'::regclass
      and conname = 'tournament_publication_registration_consistency'
  ) then
    alter table public.tournaments
      add constraint tournament_publication_registration_consistency
      check (
        publication_state = 'published' or registration_state = 'not_open'
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournaments'::regclass
      and conname = 'tournament_competition_registration_consistency'
  ) then
    alter table public.tournaments
      add constraint tournament_competition_registration_consistency
      check (
        competition_state != 'completed' or registration_state != 'open'
      );
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 4. Canonical Public Status Projection (One-Way: Canonical -> Compatibility)
-- -----------------------------------------------------------------------------

create or replace function public.derive_tournament_public_status(
  p_publication_state public.tournament_publication_state,
  p_registration_state public.tournament_registration_state,
  p_entry_state public.tournament_entry_state,
  p_competition_state public.tournament_competition_state,
  p_termination_state public.tournament_termination_state
)
returns public.tournament_status
language sql
immutable
as $$
  select case
    -- Precedence 1: Explicit termination states override ordinary display
    when p_termination_state = 'cancelled' then 'cancelled'::public.tournament_status
    when p_termination_state = 'abandoned' then 'abandoned'::public.tournament_status
    -- Precedence 2: Draft publication
    when p_publication_state = 'draft' then 'draft'::public.tournament_status
    -- Precedence 3: Competition completion / progress
    when p_competition_state = 'completed' then 'completed'::public.tournament_status
    when p_competition_state = 'in_progress' then 'live'::public.tournament_status
    -- Precedence 4: Registration open
    when p_registration_state = 'open' then 'registration'::public.tournament_status
    -- Precedence 5: Upcoming (published, registration closed/not_open, competition not started)
    else 'upcoming'::public.tournament_status
  end;
$$;

create or replace function public.project_tournament_canonical_to_legacy_status()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Ensure owner_user_id default if not supplied
  if new.owner_user_id is null then
    new.owner_user_id := coalesce(new.created_by, auth.uid());
  end if;

  -- Option A: Canonical lifecycle fields are strictly authoritative.
  -- Legacy status is derived deterministically from canonical state.
  -- Any direct write to `status` is overwritten by the canonical projection.
  -- There is NO ingestion of legacy status into canonical lifecycle columns.
  new.status := public.derive_tournament_public_status(
    new.publication_state,
    new.registration_state,
    new.entry_state,
    new.competition_state,
    new.termination_state
  );

  return new;
end;
$$;

drop trigger if exists tournaments_sync_status_projection on public.tournaments;
create trigger tournaments_sync_status_projection
  before insert or update
  on public.tournaments
  for each row
  execute function public.project_tournament_canonical_to_legacy_status();

-- -----------------------------------------------------------------------------
-- 5. Tournament Roles in roles Catalogue
-- -----------------------------------------------------------------------------

insert into public.roles (scope, key, name, rank, is_system, is_singleton, allows_unclaimed, display_group)
values
  ('tournament', 'owner', 'Owner', 40, true, true, false, 'Tournament'),
  ('tournament', 'manager', 'Manager', 30, true, false, false, 'Tournament')
on conflict (scope, key) do update set
  name = excluded.name,
  rank = excluded.rank,
  is_system = excluded.is_system,
  is_singleton = excluded.is_singleton;

-- -----------------------------------------------------------------------------
-- 6. Tournament Capabilities in permissions Catalogue
-- -----------------------------------------------------------------------------

insert into public.permissions
  (permission_key, resource, action, description, min_rank, direct_grantable, sort_order)
values
  ('tournament.profile.edit', 'tournament', 'edit', 'Edit name, description, artwork, and public tournament metadata', 30, false, 200),
  ('tournament.settings.edit', 'settings', 'edit', 'Edit competition settings, rules, and sport format defaults', 30, false, 210),
  ('tournament.publish', 'tournament', 'publish', 'Publish draft tournament to public or invited participants', 30, false, 220),
  ('tournament.registration.manage', 'registration', 'manage', 'Open, close, or extend team registration window', 30, false, 230),
  ('tournament.registration.review', 'registration', 'review', 'Approve or reject team registration applications', 30, false, 240),
  ('tournament.entries.manage', 'entries', 'manage', 'Manage accepted tournament entries prior to draw lock', 30, false, 250),
  ('tournament.entries.lock', 'entries', 'lock', 'Lock final participant field before draw generation', 30, false, 260),
  ('tournament.structure.manage', 'structure', 'manage', 'Configure stages, groups, rounds, and advancement rules', 30, false, 270),
  ('tournament.draw.manage', 'draw', 'manage', 'Generate, preview, or regenerate draft tournament draw', 30, false, 280),
  ('tournament.draw.publish', 'draw', 'publish', 'Publish authoritative competition draw and schedule', 30, false, 290),
  ('tournament.fixture.schedule', 'fixtures', 'schedule', 'Schedule fixture times, grounds, and playing conditions', 30, false, 300),
  ('tournament.fixture.reschedule', 'fixtures', 'reschedule', 'Reschedule published fixtures due to weather or conflict', 30, false, 310),
  ('tournament.match.setup', 'matches', 'setup', 'Operate pre-match toss, lineups, and start for tournament fixtures', 30, false, 320),
  ('tournament.match.score', 'matches', 'score', 'Score matches whose authoritative parent is this tournament', 30, true, 330),
  ('tournament.official.assign', 'officials', 'assign', 'Assign scorers, umpires, and match officials to fixtures', 30, false, 340),
  ('tournament.result.override', 'results', 'override', 'Correct or override authoritative fixture match result with audit', 30, false, 350),
  ('tournament.announcement.send', 'announcements', 'send', 'Broadcast official announcements to tournament participants', 30, false, 360),
  ('tournament.awards.manage', 'awards', 'manage', 'Configure and publish post-tournament awards and honors', 30, false, 370),
  ('tournament.cancel', 'tournament', 'cancel', 'Cancel tournament before competition begins (Owner governance)', 40, false, 380),
  ('tournament.abandon', 'tournament', 'abandon', 'Terminate started tournament (Owner governance)', 40, false, 390),
  ('tournament.staff.manage', 'staff', 'manage', 'Appoint, update, or remove tournament managers (Owner governance)', 40, false, 400),
  ('tournament.ownership.transfer', 'ownership', 'transfer', 'Transfer root tournament ownership to another user (Owner only)', 40, false, 410)
on conflict (permission_key) do update set
  resource = excluded.resource,
  action = excluded.action,
  description = excluded.description,
  min_rank = excluded.min_rank,
  direct_grantable = excluded.direct_grantable,
  sort_order = excluded.sort_order;

-- -----------------------------------------------------------------------------
-- 7. Register Tournament Permissions in permission_scopes
-- -----------------------------------------------------------------------------

insert into public.permission_scopes (permission_key, scope)
select p.permission_key, 'tournament'
from public.permissions p
where p.permission_key like 'tournament.%'
on conflict (permission_key, scope) do nothing;

-- -----------------------------------------------------------------------------
-- 8. Seed Default Role Capability Bundles in role_permissions
-- -----------------------------------------------------------------------------

-- 8.1 Owner receives all tournament capabilities
insert into public.role_permissions (team_id, scope, role_key, permission_key, granted)
select
  null,
  'tournament',
  'owner',
  p.permission_key,
  true
from public.permissions p
where p.permission_key like 'tournament.%'
on conflict (team_id, scope, role_key, permission_key) do nothing;

-- 8.2 Manager receives operational capabilities (all capabilities with min_rank <= 30)
insert into public.role_permissions (team_id, scope, role_key, permission_key, granted)
select
  null,
  'tournament',
  'manager',
  p.permission_key,
  true
from public.permissions p
where p.permission_key like 'tournament.%'
  and coalesce(p.min_rank, 0) <= 30
on conflict (team_id, scope, role_key, permission_key) do nothing;

-- -----------------------------------------------------------------------------
-- 9. Canonical Normalized Tournament Memberships Table
-- -----------------------------------------------------------------------------

create table if not exists public.tournament_memberships (
  membership_id  uuid primary key default gen_random_uuid(),
  tournament_id  uuid not null
    references public.tournaments (tournament_id)
    on delete cascade,
  user_id        uuid
    references public.profiles (user_id)
    on delete set null,
  scope          text not null default 'tournament'
    check (scope = 'tournament'),
  role_key       text not null default 'manager',
  status         text not null default 'active'
    check (status in ('active', 'removed', 'suspended')),
  appointed_by   uuid
    references public.profiles (user_id)
    on delete set null,
  appointed_at   timestamptz not null default now(),
  removed_by     uuid
    references public.profiles (user_id)
    on delete set null,
  removed_at     timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  foreign key (scope, role_key)
    references public.roles (scope, key)
    on delete restrict,
  constraint tournament_memberships_removal_audit
    check (
      (status = 'removed' and removed_at is not null)
      or (status != 'removed')
    ),
  constraint tournament_memberships_active_user_check
    check (
      (status != 'active')
      or (user_id is not null)
    )
);

drop index if exists public.idx_tournament_memberships_active_unique;
create unique index if not exists idx_tournament_memberships_active_unique
  on public.tournament_memberships (tournament_id, user_id)
  where (status = 'active');

create index if not exists idx_tournament_memberships_lookup
  on public.tournament_memberships (tournament_id, user_id, status);

create index if not exists idx_tournament_memberships_user
  on public.tournament_memberships (user_id);

drop trigger if exists tournament_memberships_set_updated_at on public.tournament_memberships;
create trigger tournament_memberships_set_updated_at
  before update on public.tournament_memberships
  for each row
  execute function public.set_updated_at();

-- History preservation on account deletion:
-- When a user profile is deleted, ON DELETE SET NULL nullifies user_id.
-- This trigger automatically transitions active membership to 'removed' with timestamp.
-- The historical membership record is preserved, while the deleted user's direct identity
-- is intentionally anonymized. Appointment and removal metadata is retained where
-- privacy and account-deletion rules allow.
create or replace function public.tournament_memberships_anonymize_on_user_delete()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.user_id is null and old.user_id is not null then
    new.status := 'removed';
    new.removed_at := coalesce(new.removed_at, now());
  end if;
  return new;
end;
$$;

drop trigger if exists tournament_memberships_anonymize_on_user_delete_trg on public.tournament_memberships;
create trigger tournament_memberships_anonymize_on_user_delete_trg
  before update of user_id on public.tournament_memberships
  for each row
  execute function public.tournament_memberships_anonymize_on_user_delete();

-- -----------------------------------------------------------------------------
-- 10. Backfill Existing organizers into tournament_memberships
-- -----------------------------------------------------------------------------

insert into public.tournament_memberships (
  tournament_id,
  user_id,
  role_key,
  status,
  appointed_by,
  appointed_at
)
select
  t.tournament_id,
  u.user_id,
  'manager',
  'active',
  t.owner_user_id,
  t.created_at
from
  public.tournaments t,
  unnest(t.organizers) as u(user_id)
join public.profiles p on p.user_id = u.user_id
where
  u.user_id is not null
  and u.user_id != t.owner_user_id
on conflict (tournament_id, user_id) where (status = 'active')
do nothing;

-- -----------------------------------------------------------------------------
-- 11. One-Way Projection: tournament_memberships -> tournaments.organizers
-- -----------------------------------------------------------------------------

create or replace function public.project_tournament_memberships_to_organizers()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_tournament_id uuid;
begin
  v_tournament_id := coalesce(new.tournament_id, old.tournament_id);

  update public.tournaments
  set organizers = coalesce(
    (
      select array_agg(user_id order by appointed_at)
      from public.tournament_memberships
      where tournament_id = v_tournament_id
        and status = 'active'
        and user_id is not null
    ),
    '{}'::uuid[]
  )
  where tournament_id = v_tournament_id;

  return null;
end;
$$;

drop trigger if exists tournament_memberships_sync_organizers_projection on public.tournament_memberships;
create trigger tournament_memberships_sync_organizers_projection
  after insert or update or delete on public.tournament_memberships
  for each row
  execute function public.project_tournament_memberships_to_organizers();

-- -----------------------------------------------------------------------------
-- 12. Transitional is_tournament_organizer Compatibility Function
-- -----------------------------------------------------------------------------

create or replace function public.is_tournament_organizer(
  p_tournament_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    -- 1. Canonical owner authority
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = p_tournament_id
        and (
          t.owner_user_id = auth.uid()
          or (t.owner_user_id is null and t.created_by = auth.uid())
        )
    )
    -- 2. Normalized active tournament membership
    or exists (
      select 1
      from public.tournament_memberships tm
      where tm.tournament_id = p_tournament_id
        and tm.user_id = auth.uid()
        and tm.status = 'active'
        and tm.role_key in ('owner', 'manager')
    )
    -- 3. Legacy compatibility fallback ONLY if no normalized memberships exist for this tournament
    or (
      not exists (
        select 1
        from public.tournament_memberships tm
        where tm.tournament_id = p_tournament_id
      )
      and exists (
        select 1
        from public.tournaments t
        where t.tournament_id = p_tournament_id
          and auth.uid() = any (t.organizers)
      )
    );
$$;

revoke all on function public.is_tournament_organizer(uuid) from public;
grant execute on function public.is_tournament_organizer(uuid) to authenticated;

-- Helper to check if caller is tournament admin (owner or active manager)
create or replace function public.is_tournament_admin(
  p_tournament_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.tournaments t
    where t.tournament_id = p_tournament_id
      and (
        t.owner_user_id = auth.uid()
        or (t.owner_user_id is null and t.created_by = auth.uid())
      )
  )
  or exists (
    select 1
    from public.tournament_memberships tm
    where tm.tournament_id = p_tournament_id
      and tm.user_id = auth.uid()
      and tm.status = 'active'
      and tm.role_key in ('owner', 'manager')
  );
$$;

revoke all on function public.is_tournament_admin(uuid) from public;
grant execute on function public.is_tournament_admin(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 13. Extended Universal Capability Resolver (can) with Tournament Scope
-- -----------------------------------------------------------------------------

create or replace function public.can(
  p_scope text,
  p_entity_id uuid,
  p_permission text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    -- 0. Validate first: fail closed if permission is not registered for scope.
    exists (
      select 1
      from public.permission_scopes ps
      where ps.permission_key = p_permission and ps.scope = p_scope
    )
    and (
      -- 1. Direct grant: live grant on exact resource for this subject
      exists (
        select 1
        from
          public.grants g
          join public.permissions p on p.permission_key = g.permission_key
        where
          g.subject_id = auth.uid()
          and g.scope = p_scope
          and g.entity_id = p_entity_id
          and g.permission_key = p_permission
          and p.direct_grantable
          and (g.expires_at is null or g.expires_at > now())
      )
      -- 2. Team scope role-derived
      or (
        p_scope = 'team'
        and exists (
          select 1
          from
            public.team_members tm
            join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
          where
            tm.team_id = p_entity_id
            and tm.user_id = auth.uid()
            and tm.status = 'active'
            and (
              tmr.role_key = 'owner'
              or public._role_grants(p_entity_id, tmr.scope, tmr.role_key, p_permission)
            )
        )
      )
      -- 3. Tournament scope
      or (
        p_scope = 'tournament'
        and (
          -- Root authority: Tournament owner holds all tournament capabilities unconditionally
          exists (
            select 1
            from public.tournaments t
            where t.tournament_id = p_entity_id
              and (t.owner_user_id = auth.uid() or (t.owner_user_id is null and t.created_by = auth.uid()))
          )
          -- Role-derived from normalized tournament memberships
          or exists (
            select 1
            from public.tournament_memberships tm
            where tm.tournament_id = p_entity_id
              and tm.user_id = auth.uid()
              and tm.status = 'active'
              and (
                tm.role_key = 'owner'
                or public._role_grants(null, 'tournament', tm.role_key, p_permission)
              )
          )
        )
      )
    );
$$;

revoke all on function public.can(text, uuid, text) from public;
grant execute on function public.can(text, uuid, text) to authenticated;

-- Helper to check capability of an arbitrary user in tournament scope
create or replace function public._user_tournament_can(
  p_user_id uuid,
  p_tournament_id uuid,
  p_permission text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    exists (
      select 1
      from public.permission_scopes ps
      where ps.permission_key = p_permission and ps.scope = 'tournament'
    )
    and (
      -- Root authority: Tournament owner
      exists (
        select 1
        from public.tournaments t
        where t.tournament_id = p_tournament_id
          and (t.owner_user_id = p_user_id or (t.owner_user_id is null and t.created_by = p_user_id))
      )
      -- Role-derived
      or exists (
        select 1
        from public.tournament_memberships tm
        where tm.tournament_id = p_tournament_id
          and tm.user_id = p_user_id
          and tm.status = 'active'
          and (
            tm.role_key = 'owner'
            or public._role_grants(null, 'tournament', tm.role_key, p_permission)
          )
      )
      -- Direct grant
      or exists (
        select 1
        from public.grants g
        join public.permissions p on p.permission_key = g.permission_key
        where g.subject_id = p_user_id
          and g.scope = 'tournament'
          and g.entity_id = p_tournament_id
          and g.permission_key = p_permission
          and p.direct_grantable
          and (g.expires_at is null or g.expires_at > now())
      )
    );
$$;

revoke all on function public._user_tournament_can(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public._user_tournament_can(uuid, uuid, text) to service_role;

-- -----------------------------------------------------------------------------
-- 14. Row-Level Security for tournament_memberships & tournaments
-- -----------------------------------------------------------------------------

alter table public.tournament_memberships enable row level security;

-- Ensure column nullability and constraints for existing tables during development re-runs
alter table public.tournament_memberships
  alter column user_id drop not null;

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_name = 'tournament_memberships' and constraint_name = 'tournament_memberships_user_id_fkey'
  ) then
    alter table public.tournament_memberships drop constraint tournament_memberships_user_id_fkey;
    alter table public.tournament_memberships
      add constraint tournament_memberships_user_id_fkey
      foreign key (user_id) references public.profiles (user_id) on delete set null;
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournament_memberships'::regclass
      and conname = 'tournament_memberships_active_user_check'
  ) then
    alter table public.tournament_memberships
      add constraint tournament_memberships_active_user_check
      check ((status != 'active') or (user_id is not null));
  end if;
end
$$;

-- Read policy: Users see their own memberships, or if they are admin of the tournament
drop policy if exists "tournament_memberships_read" on public.tournament_memberships;
create policy "tournament_memberships_read"
  on public.tournament_memberships
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_tournament_admin(tournament_id)
  );

-- Insert policy: Tournament owner or staff manager
drop policy if exists "tournament_memberships_insert" on public.tournament_memberships;
create policy "tournament_memberships_insert"
  on public.tournament_memberships
  for insert
  to authenticated
  with check (
    public.can('tournament', tournament_id, 'tournament.staff.manage')
  );

-- Update policy: Tournament owner or staff manager
drop policy if exists "tournament_memberships_update" on public.tournament_memberships;
create policy "tournament_memberships_update"
  on public.tournament_memberships
  for update
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.staff.manage')
  )
  with check (
    public.can('tournament', tournament_id, 'tournament.staff.manage')
  );

-- Update tournaments policies to recognize owner_user_id as canonical authority
drop policy if exists "tournaments_read_visible" on public.tournaments;
create policy "tournaments_read_visible"
  on public.tournaments
  for select
  to anon, authenticated
  using (
    privacy = 'public'
    or (select auth.uid()) = owner_user_id
    or ((select auth.uid()) = created_by and owner_user_id is null)
    or (select auth.uid()) = any (organizers)
    or public.is_tournament_admin(tournament_id)
  );

drop policy if exists "tournaments_update_organizers" on public.tournaments;
create policy "tournaments_update_organizers"
  on public.tournaments
  for update
  to authenticated
  using (
    (select auth.uid()) = owner_user_id
    or ((select auth.uid()) = created_by and owner_user_id is null)
    or (select auth.uid()) = any (organizers)
    or public.is_tournament_organizer(tournament_id)
  )
  with check (
    (select auth.uid()) = owner_user_id
    or ((select auth.uid()) = created_by and owner_user_id is null)
    or (select auth.uid()) = any (organizers)
    or public.is_tournament_organizer(tournament_id)
  );

drop policy if exists "tournaments_delete_creator" on public.tournaments;
create policy "tournaments_delete_creator"
  on public.tournaments
  for delete
  to authenticated
  using (
    (select auth.uid()) = owner_user_id
    or ((select auth.uid()) = created_by and owner_user_id is null)
  );

-- -----------------------------------------------------------------------------
-- 15. Transitional Tournament Cancellation RPC
-- TODO(Phase 5/9): Replace temporary RPC with canonical tournament-action CancelTournament command pipeline
-- -----------------------------------------------------------------------------
create or replace function public.tournament_cancel(
  p_tournament_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_competition_state public.tournament_competition_state;
  v_termination_state public.tournament_termination_state;
begin
  -- 1. Authenticate caller
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 2. Inspect tournament exists and retrieve current lifecycle states
  select competition_state, termination_state
    into v_competition_state, v_termination_state
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  -- 3. Authorize via canonical capability check (tournament.cancel requires Owner root governance)
  if not public.can('tournament', p_tournament_id, 'tournament.cancel') then
    raise exception 'Unauthorized to cancel tournament' using errcode = '42501';
  end if;

  -- 4. Idempotency: if already cancelled, return cleanly without duplicate operations
  if v_termination_state = 'cancelled' then
    return;
  end if;

  -- 5. Lifecycle Precondition: Cancellation is only permitted before competition has started or completed.
  -- Started tournaments must be abandoned (Phase 9 tournament.abandon), not cancelled.
  if v_competition_state != 'not_started' then
    raise exception 'Cannot cancel a tournament once competition has started. Use abandonment instead.'
      using errcode = '22000';
  end if;

  -- 6. Validate cancellation reason
  if p_reason is null or length(btrim(p_reason)) < 10 then
    raise exception 'Cancelling requires a reason of at least 10 characters'
      using errcode = '22023';
  end if;

  -- 7. Void unplayed matches if any fixtures were generated.
  -- Completed scorecards are deliberately preserved to protect sporting history.
  update public.matches
     set status = 'cancelled',
         updated_at = now()
   where tournament_id = p_tournament_id
     and status in ('scheduled', 'live');

  -- 8. Mutate CANONICAL termination_state.
  -- Do NOT write legacy status directly: trigger tournaments_sync_status_projection
  -- projects termination_state = 'cancelled' -> status = 'cancelled'.
  update public.tournaments
     set termination_state = 'cancelled',
         rules = coalesce(rules, '{}'::jsonb) || jsonb_build_object(
           'cancelled_reason', btrim(p_reason),
           'cancelled_at', now(),
           'cancelled_by', auth.uid()
         ),
         updated_at = now()
   where tournament_id = p_tournament_id;

  -- 9. Notify participants via tournament_announce if routine exists
  if exists (
    select 1 from pg_proc
     where proname = 'tournament_announce'
       and pronamespace = 'public'::regnamespace
  ) then
    perform public.tournament_announce(
      p_tournament_id,
      left('Cancelled: ' || btrim(p_reason), 300)
    );
  end if;
end;
$$;

revoke all on function public.tournament_cancel(uuid, text) from public;
grant execute on function public.tournament_cancel(uuid, text) to authenticated;


