-- =============================================================================
-- Migration: 20260101000204_permissions.sql
-- =============================================================================

-- 0204 · permissions — authorization capabilities
-- Design + decision log: docs/team-roles-design.md
-- permissions — what can be done.
-- `resource` and `action` are LOAD-BEARING, not decoration: they are the rows
-- and columns of the permissions grid a team owner will eventually edit. NIST
-- models a permission as an operation on an object for the same reason.
--
-- NOTE THE ABSENCE OF A `scope` COLUMN. A permission is not bound to one entity
-- type — `match.score` is legitimately held either through a team role (the
-- batting side's captain) or through a direct grant on one match (a nominated
-- scorer). Which entity types it may be evaluated against lives in
-- `permission_scopes`. Collapsing the two into one column is a real bug
-- that was caught in review: it made the scoring model and scope validation
-- mutually exclusive.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.permissions (
  permission_key   text primary key check (permission_key ~ '^[a-z]+(\.[a-z_]+){1,2}$'),
  resource         text not null,
  action           text not null,
  description      text not null,
  -- Floor on the ROLE path: the lowest role rank that may be granted this.
  -- Any value — a future permission could legitimately require captain (20).
  -- Enforced by a trigger, not a CHECK: it compares two tables.
  min_rank         integer check (min_rank is null or min_rank between 0 and 1000),
  -- May this be handed out as a direct grant, bypassing roles entirely?
  -- min_rank guards the role path; without this flag `grants` would be a clean
  -- route around the matrix (a plain player handed `team.disband`).
  direct_grantable boolean not null default false,
  sort_order       integer not null default 0
);

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

insert into public.permissions
  (
    permission_key,
    resource,
    action,
    description,
    min_rank,
    direct_grantable,
    sort_order
  )
values
  (
    'team.roster.write',
    'roster',
    'write',
    'Add, remove and edit players',
    null,
    false,
    10
  ),
  ('team.roster.role', 'roster', 'role', 'Change a member''s roles', null, false, 20),
  (
    'team.staff.appoint',
    'staff',
    'appoint',
    'Create and remove managers',
    40,
    false,
    30
  ),
  (
    'team.invite',
    'roster',
    'invite',
    'Send invites and decide join requests',
    null,
    false,
    40
  ),
  (
    'team.profile.write',
    'profile',
    'write',
    'Name, crest, colours, ground, privacy',
    null,
    false,
    50
  ),
  ('team.post', 'posts', 'write', 'Post as the team', null, false, 60),
  (
    'team.challenge.send',
    'matches',
    'create',
    'Send, accept and cancel challenges',
    null,
    false,
    70
  ),
  (
    'team.tournament.enter',
    'tournaments',
    'enter',
    'Register the team for a tournament',
    null,
    false,
    80
  ),
  (
    'team.contact.view',
    'roster',
    'read',
    'See an unclaimed player''s phone number',
    null,
    false,
    90
  ),
  ('team.transfer', 'team', 'transfer', 'Hand over ownership', 40, false, 100),
  ('team.disband', 'team', 'disband', 'Archive or disband the team', 40, false, 110),
  (
    'team.permissions.manage',
    'permissions',
    'manage',
    'Edit this team''s permission matrix',
    40,
    false,
    120
  ),
  (
    'cricket.match.setup',
    'cricket_match',
    'setup',
    'Configure and advance pre-live Cricket Match Start (toss and openers).',
    null,
    true,
    130
  ),
  ('match.score', 'match', 'score', 'Score an innings', null, true, 140),
  (
    'match.official.assign',
    'match',
    'assign',
    'Appoint a scorer or umpire',
    null,
    true,
    150
  );

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- Catalogue data is world-readable and writable only by migrations/service_role.
alter table public.permissions enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "permissions_read_all"
  on public.permissions
  for select
  to anon, authenticated
  using (true);
