-- Migration file: 20260101000201_roles.sql

-- 0201 · roles — authorization role catalogue
-- Design + decision log: docs/team-roles-design.md
-- roles — what a person can be.
-- `rank` is a single scale used for exactly ONE thing: stopping privilege
-- escalation ("you may never grant a role at or above your own"). It does NOT
-- imply permissions — there is no inheritance. A manager holding `match.score`
-- holds it because a row says so, not because 30 > 20. That keeps the future
-- permissions grid honest: every tick is a fact, never an implication.
--
-- `is_singleton` means at most one HOLDER PER TEAM (one owner, one captain).
-- That is a cardinality limit on the role, NOT separation of duty — see the
-- role_exclusion_sets for the other rule, which is about one *person*.
--
-- `display_group` groups roles in the UI. It carries no rule whatsoever. An
-- earlier draft had a `category` column doing constraint + display + semantics
-- at once; splitting them is why exclusivity could become data.

-- Section: Tables and constraints

create table public.roles(
  scope            text not null default 'team' check (scope in ('team', 'match', 'tournament', 'club')),
  key              text not null check (key ~ '^[a-z][a-z_]{1,30}$'),
  name             text not null,
  rank             integer not null check (rank between 0 and 1000),
  is_system        boolean not null default false,
  is_singleton     boolean not null default false,
  -- May an unclaimed placeholder (someone with no MatchDay account) hold it?
  -- Only 'player'. A rung that grants power to nobody is a rung that lies.
  allows_unclaimed boolean not null default false,
  display_group    text,
  created_at       timestamptz not null default now(),
  primary key (scope, key),
  -- Redundant given the PK, but a composite FK target must be UNIQUE. This is
  -- what lets team_member_roles carry is_singleton as a real column (see its migration)
  -- and therefore index on it — a partial-index predicate must be IMMUTABLE and
  -- cannot read this table.
  unique (scope, key, is_singleton),
  constraint unclaimed_roles_are_powerless check (not allows_unclaimed or rank = 0 or key = 'player')
);

-- Section: Data changes

insert into public.roles(scope, key, name, rank, is_system, is_singleton, allows_unclaimed, display_group)
values
  ('team', 'owner', 'Owner', 40, true, true, false, 'Club'),
('team', 'manager', 'Manager', 30, true, false, false, 'Club'),
('team', 'captain', 'Captain', 20, true, true, false, 'Match day'),
('team', 'player', 'Player', 10, true, false, true, 'Club');

-- Section: Enable row-level security

-- Catalogue data is world-readable and writable only by migrations/service_role.
alter table public.roles enable row level security;

-- Section: Policies

create policy "roles_read_all" on public.roles
  for select to anon, authenticated
  using (true);
