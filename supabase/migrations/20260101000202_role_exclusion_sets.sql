-- Migration file: 20260101000202_role_exclusion_sets.sql

-- 0202 · role_exclusion_sets — separation-of-duty limits
-- Design + decision log: docs/team-roles-design.md
-- role_exclusion_sets / _members — NIST Static Separation of Duty.
-- "A collection of pairs of a role set and an associated cardinality … the
--  cardinality of its subsets that cannot have common users." (INCITS 359-2004)
--
-- The default is that roles COMBINE FREELY. Exclusivity is the declared
-- exception. One seeded rule says a member is at most one of
-- {owner, manager, player}; `captain` is in no set, so owner+captain — the case
-- the previous single-column model could not represent at all — just works.
--
-- Relaxing the rule later is an UPDATE of max_roles, not a migration.

-- Section: Tables and constraints

create table public.role_exclusion_sets(
  set_id     uuid primary key default gen_random_uuid(),
  scope      text not null default 'team',
  name       text not null,
  -- At most this many roles from the set, per member. NIST expresses the
  -- violating subset as n where 2 <= n <= |role_set|; this is n-1.
  max_roles  integer not null check (max_roles >= 1),
  created_at timestamptz not null default now(),
  unique (scope, name)
);

-- Section: Enable row-level security

-- Catalogue data is world-readable and writable only by migrations/service_role.
alter table public.role_exclusion_sets enable row level security;

-- Section: Policies

create policy "role_exclusion_sets_read_all" on public.role_exclusion_sets
  for select to anon, authenticated
  using (true);

-- The default set is inserted atomically with its members in
-- 20260101000203_role_exclusion_members.sql.
