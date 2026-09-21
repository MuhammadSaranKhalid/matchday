-- =============================================================================
-- Migration: 20260101000211_team_member_roles.sql
-- =============================================================================

-- 0211 · team_member_roles — roles held by each team member
-- team_member_roles — what a member IS. Pure many-to-many.
-- `is_singleton` and `team_id` are denormalised onto this row ON PURPOSE: a
-- partial-index predicate must be IMMUTABLE and cannot read another table. The
-- composite FKs keep both honest — a row that lies about is_singleton, or whose
-- team_id disagrees with its membership, is rejected with 23503. Verified.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.team_member_roles (
  -- NOTE: membership_id carries NO FK of its own. The composite
  -- (membership_id, team_id) below already enforces existence, agreement and
  -- the cascade — and a second, single-column FK made PostgREST ambiguous
  -- (PGRST201) when embedding roles into a roster query, because it could not
  -- tell which relationship to traverse.
  membership_id uuid not null,
  scope         text not null default 'team' check (scope = 'team'),
  role_key      text not null,
  team_id       uuid not null,
  is_singleton  boolean not null,
  granted_by    uuid
    references public.profiles (user_id)
    on delete set null,
  granted_at    timestamptz not null default now(),
  primary key (membership_id, scope, role_key),
  foreign key (scope, role_key, is_singleton)
    references public.roles (scope, key, is_singleton)
    on update cascade,
  constraint team_member_roles_membership_fk
    foreign key (membership_id, team_id)
    references public.team_members (membership_id, team_id)
    on delete cascade
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- "At most one holder of this role per team" — owner, captain. A cardinality
-- limit on the role, not separation of duty. Airtight, no race.
create unique index team_member_roles_singleton_per_team
  on public.team_member_roles (
    team_id,
    scope,
    role_key
  )
  where is_singleton;

create index team_member_roles_membership
  on public.team_member_roles (membership_id);

create index team_member_roles_team_role
  on public.team_member_roles (
    team_id,
    scope,
    role_key
  );

create index team_member_roles_granted_by
  on public.team_member_roles (granted_by);

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Role integrity: three triggers.
-- 1. Separation of duty. A role may belong to several exclusion sets, so no
--    column can carry the rule and no unique index can express it. AFTER, so
--    the new row is counted. The FOR UPDATE lock on the membership is what
--    stops two concurrent grants from both passing the count.
create or replace function public.guard_role_exclusion()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_set_name text;
begin
  perform
    1
  from public.team_members
  where membership_id = new.membership_id
  for update;
  select
    s.name
  into v_set_name
  from
    public.role_exclusion_sets s
    join public.role_exclusion_members m
      on m.set_id = s.set_id and m.scope = new.scope and m.role_key = new.role_key
  where
    (
      select
        count(*)
      from
        public.team_member_roles tmr
        join public.role_exclusion_members m2
          on m2.set_id = s.set_id
          and m2.scope = tmr.scope
          and m2.role_key = tmr.role_key
      where tmr.membership_id = new.membership_id
    ) > s.max_roles
  limit 1;
  if v_set_name is not null then
    raise exception 'Role "%" breaches exclusion set "%" for this member',
      new.role_key,
      v_set_name
      using errcode = '23514';
  end if;
  return null;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create constraint trigger team_member_roles_exclusion
  after insert or update on public.team_member_roles
  for each row
  execute function public.guard_role_exclusion();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- 2. A placeholder with no MatchDay account may only hold a role flagged
--    allows_unclaimed (i.e. 'player'). A rung that grants power to nobody is a
--    rung that lies, and _team_current_captain could otherwise return a uuid
--    that can never equal auth.uid().
create or replace function public.guard_role_needs_account()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
  v_allows boolean;
begin
  select
    user_id
  into v_user_id
  from public.team_members
  where membership_id = new.membership_id;
  if v_user_id is not null then
    return new;
  end if;
  select
    allows_unclaimed
  into v_allows
  from public.roles
  where scope = new.scope and key = new.role_key;
  if not coalesce(v_allows, false) then
    raise exception 'Role "%" requires a MatchDay account; this member is an unclaimed placeholder',
      new.role_key
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger team_member_roles_needs_account
  before insert or update on public.team_member_roles
  for each row
  execute function public.guard_role_needs_account();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- 3. Every active membership holds at least one role.
--
--    DEFERRED, and that is not a detail: the promotion path is "revoke player,
--    grant manager" inside one transaction, and an immediate trigger would
--    reject the first statement. Checked at COMMIT instead.
--
--    It must also skip a membership that no longer exists — deleting a member
--    cascades its role rows, which would otherwise fire this against a row
--    that is already gone.
create or replace function public.guard_member_has_role()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_membership uuid := coalesce(new.membership_id, old.membership_id);
begin
  if
    not exists (
      select
        1
      from public.team_members
      where membership_id = v_membership and status = 'active'
    )
  then
    return null;
    -- membership gone or inactive: nothing to check
  end if;
  if
    not exists (
      select
        1
      from public.team_member_roles
      where membership_id = v_membership
    )
  then
    raise exception 'A team member must hold at least one role' using errcode = '23514';
  end if;
  return null;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create constraint trigger team_member_roles_at_least_one
  after insert or update or delete on public.team_member_roles
  deferrable initially deferred
  for each row
  execute function public.guard_member_has_role();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.team_member_roles enable row level security;

-- Read/write policies depend on the authorization predicates installed in
-- 20260101000212_team_authorization.sql.
