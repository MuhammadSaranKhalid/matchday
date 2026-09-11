-- =============================================================================
-- 0205 · authorization engine — roles, permissions and grants as data
-- =============================================================================
-- Design + decision log: docs/team-roles-design.md
--
-- This file is the CATALOGUE. It declares what roles exist, what permissions
-- exist, which roles hold which permissions, and which one-off grants have been
-- handed out. It deliberately contains NO team-membership concepts — role
-- ASSIGNMENT lives in `team_member_roles` (0210), next to the membership it
-- hangs off, and `can()` is declared there too because it reads that table.
--
-- Why 0205 and not a later number: file numbers encode dependency order, not
-- dates (§12.0). These tables depend only on `teams` (0200) and `profiles`, and
-- going first lets 0210 declare `can()` beside the junction, so 0210's own
-- policies can use it.
--
-- THE SHAPE, and why:
--
--   roles                    what a person can BE          (data, not an enum)
--   role_exclusion_sets      "at most N of these roles     (NIST Static
--   role_exclusion_members    per member"                   Separation of Duty)
--   permissions              what can be DONE
--   permission_scopes        …and on which kind of entity
--   role_permissions         THE MATRIX: role → permission, globally or per team
--   grants                   a permission handed to ONE person on ONE resource
--
-- Before this, authority was `role >= 'manager'` compiled into ~45 SQL call
-- sites and 14 Dart getters. Moving a capability meant editing both and
-- shipping. Now it is an INSERT.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- roles — what a person can be.
-- -----------------------------------------------------------------------------
-- `rank` is a single scale used for exactly ONE thing: stopping privilege
-- escalation ("you may never grant a role at or above your own"). It does NOT
-- imply permissions — there is no inheritance. A manager holding `match.score`
-- holds it because a row says so, not because 30 > 20. That keeps the future
-- permissions grid honest: every tick is a fact, never an implication.
--
-- `is_singleton` means at most one HOLDER PER TEAM (one owner, one captain).
-- That is a cardinality limit on the role, NOT separation of duty — see the
-- exclusion sets below for the other rule, which is about one *person*.
--
-- `display_group` groups roles in the UI. It carries no rule whatsoever. An
-- earlier draft had a `category` column doing constraint + display + semantics
-- at once; splitting them is why exclusivity could become data.
create table public.roles (
  scope             text not null default 'team'
                      check (scope in ('team', 'match', 'tournament', 'club')),
  key               text not null check (key ~ '^[a-z][a-z_]{1,30}$'),
  name              text not null,
  rank              integer not null check (rank between 0 and 1000),
  is_system         boolean not null default false,
  is_singleton      boolean not null default false,
  -- May an unclaimed placeholder (someone with no MatchDay account) hold it?
  -- Only 'player'. A rung that grants power to nobody is a rung that lies.
  allows_unclaimed  boolean not null default false,
  display_group     text,
  created_at        timestamptz not null default now(),

  primary key (scope, key),
  -- Redundant given the PK, but a composite FK target must be UNIQUE. This is
  -- what lets team_member_roles carry is_singleton as a real column (see 0210)
  -- and therefore index on it — a partial-index predicate must be IMMUTABLE and
  -- cannot read this table.
  unique (scope, key, is_singleton),
  constraint unclaimed_roles_are_powerless
    check (not allows_unclaimed or rank = 0 or key = 'player')
);

insert into public.roles
  (scope, key,       name,      rank, is_system, is_singleton, allows_unclaimed, display_group)
values
  ('team', 'owner',   'Owner',    40, true,  true,  false, 'Club'),
  ('team', 'manager', 'Manager',  30, true,  false, false, 'Club'),
  ('team', 'captain', 'Captain',  20, true,  true,  false, 'Match day'),
  ('team', 'player',  'Player',   10, true,  false, true,  'Club');


-- -----------------------------------------------------------------------------
-- role_exclusion_sets / _members — NIST Static Separation of Duty.
-- -----------------------------------------------------------------------------
-- "A collection of pairs of a role set and an associated cardinality … the
--  cardinality of its subsets that cannot have common users." (INCITS 359-2004)
--
-- The default is that roles COMBINE FREELY. Exclusivity is the declared
-- exception. One seeded rule says a member is at most one of
-- {owner, manager, player}; `captain` is in no set, so owner+captain — the case
-- the previous single-column model could not represent at all — just works.
--
-- Relaxing the rule later is an UPDATE of max_roles, not a migration.
create table public.role_exclusion_sets (
  set_id      uuid primary key default gen_random_uuid(),
  scope       text not null default 'team',
  name        text not null,
  -- At most this many roles from the set, per member. NIST expresses the
  -- violating subset as n where 2 <= n <= |role_set|; this is n-1.
  max_roles   integer not null check (max_roles >= 1),
  created_at  timestamptz not null default now(),
  unique (scope, name)
);

create table public.role_exclusion_members (
  set_id    uuid not null references public.role_exclusion_sets(set_id) on delete cascade,
  scope     text not null,
  role_key  text not null,
  primary key (set_id, scope, role_key),
  foreign key (scope, role_key) references public.roles (scope, key) on delete cascade
);

create index idx_role_exclusion_members_role
  on public.role_exclusion_members (scope, role_key);

-- A set must be able to be satisfied. max_roles >= |members| constrains nothing
-- (every member could hold them all), and is almost always a typo.
create or replace function public.guard_exclusion_set_sane()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_set_id uuid := coalesce(new.set_id, old.set_id);
  v_count  integer;
  v_max    integer;
begin
  select count(*) into v_count
    from public.role_exclusion_members where set_id = v_set_id;
  select max_roles into v_max
    from public.role_exclusion_sets where set_id = v_set_id;

  -- An empty or single-role set is inert, not broken — allow it while a set is
  -- being assembled. Only a set that cannot constrain anything is an error.
  if v_count > 1 and v_max >= v_count then
    raise exception
      'Exclusion set % allows % of % roles — it constrains nothing',
      v_set_id, v_max, v_count
      using errcode = '23514';
  end if;
  return null;
end;
$$;

create constraint trigger role_exclusion_members_sane
  after insert or update or delete on public.role_exclusion_members
  deferrable initially deferred
  for each row execute function public.guard_exclusion_set_sane();

-- The seed itself lives at the END of this file: the sanity trigger above is
-- DEFERRABLE, and pending trigger events block a later ALTER TABLE (55006) —
-- which every `enable row level security` below is.


-- -----------------------------------------------------------------------------
-- permissions — what can be done.
-- -----------------------------------------------------------------------------
-- `resource` and `action` are LOAD-BEARING, not decoration: they are the rows
-- and columns of the permissions grid a team owner will eventually edit. NIST
-- models a permission as an operation on an object for the same reason.
--
-- NOTE THE ABSENCE OF A `scope` COLUMN. A permission is not bound to one entity
-- type — `match.score` is legitimately held either through a team role (the
-- batting side's captain) or through a direct grant on one match (a nominated
-- scorer). Which entity types it may be evaluated against lives in
-- `permission_scopes` below. Collapsing the two into one column is a real bug
-- that was caught in review: it made the scoring model and scope validation
-- mutually exclusive.
create table public.permissions (
  permission_key    text primary key
                      check (permission_key ~ '^[a-z]+(\.[a-z_]+){1,2}$'),
  resource          text not null,
  action            text not null,
  description       text not null,
  -- Floor on the ROLE path: the lowest role rank that may be granted this.
  -- Any value — a future permission could legitimately require captain (20).
  -- Enforced by a trigger, not a CHECK: it compares two tables.
  min_rank          integer check (min_rank is null or min_rank between 0 and 1000),
  -- May this be handed out as a direct grant, bypassing roles entirely?
  -- min_rank guards the role path; without this flag `grants` would be a clean
  -- route around the matrix (a plain player handed `team.disband`).
  direct_grantable  boolean not null default false,
  sort_order        integer not null default 0
);

create table public.permission_scopes (
  permission_key  text not null
                    references public.permissions(permission_key) on delete cascade,
  scope           text not null
                    check (scope in ('team', 'match', 'tournament', 'club')),
  primary key (permission_key, scope)
);

insert into public.permissions
  (permission_key, resource, action, description, min_rank, direct_grantable, sort_order) values
  ('team.roster.write',       'roster',      'write',  'Add, remove and edit players',              null, false,  10),
  ('team.roster.role',        'roster',      'role',   'Change a member''s roles',                  null, false,  20),
  ('team.staff.appoint',      'staff',       'appoint','Create and remove managers',                  40, false,  30),
  ('team.invite',             'roster',      'invite', 'Send invites and decide join requests',     null, false,  40),
  ('team.profile.write',      'profile',     'write',  'Name, crest, colours, ground, privacy',     null, false,  50),
  ('team.post',               'posts',       'write',  'Post as the team',                          null, false,  60),
  ('team.challenge.send',     'matches',     'create', 'Send, accept and cancel challenges',        null, false,  70),
  ('team.tournament.enter',   'tournaments', 'enter',  'Register the team for a tournament',        null, false,  80),
  ('team.contact.view',       'roster',      'read',   'See an unclaimed player''s phone number',   null, false,  90),
  ('team.transfer',           'team',        'transfer','Hand over ownership',                        40, false, 100),
  ('team.disband',            'team',        'disband','Archive or disband the team',                 40, false, 110),
  ('team.permissions.manage', 'permissions', 'manage', 'Edit this team''s permission matrix',         40, false, 120),
  ('match.lineup.set',        'match',       'lineup', 'Pick the XI, run the toss, start the match',null, false, 130),
  ('match.score',             'match',       'score',  'Score an innings',                          null, true,  140),
  ('match.official.assign',   'match',       'assign', 'Appoint a scorer or umpire',                null, true,  150);

-- Which entity types each permission may be evaluated against.
-- match.score appears TWICE on purpose — that is the whole point.
insert into public.permission_scopes (permission_key, scope)
select permission_key, 'team' from public.permissions
union all
select 'match.score', 'match'            -- a scorer nominated for ONE match
union all
select 'match.official.assign', 'match'; -- an organiser delegating on ONE match


-- -----------------------------------------------------------------------------
-- role_permissions — THE MATRIX. This is the table you flip a row in.
-- -----------------------------------------------------------------------------
-- `team_id IS NULL` is the shared default; a team's rows are DELTAS against it,
-- so a team that changes one thing need not restate the rest:
--
--   effective(team, role) = global rows + team grants − team revokes
--
-- `unique nulls not distinct` (PG15+, this project is PG17) is what keeps
-- exactly one global row per combination — without it Postgres treats every
-- NULL as distinct and duplicate globals would be allowed.
--
-- Both FKs matter. The second makes scope coherence structural: you cannot pair
-- a team role with a permission that is not valid at team scope.
create table public.role_permissions (
  team_id         uuid references public.teams(team_id) on delete cascade,
  scope           text not null default 'team',
  role_key        text not null,
  permission_key  text not null,
  granted         boolean not null default true,
  created_at      timestamptz not null default now(),

  foreign key (scope, role_key)
    references public.roles (scope, key) on delete cascade,
  foreign key (permission_key, scope)
    references public.permission_scopes (permission_key, scope) on delete cascade,
  unique nulls not distinct (team_id, scope, role_key, permission_key)
);

create index idx_role_permissions_team on public.role_permissions (team_id);
create index idx_role_permissions_perm on public.role_permissions (permission_key);
create index idx_role_permissions_lookup
  on public.role_permissions (scope, role_key, permission_key);

-- min_rank cannot be a row CHECK — it compares roles.rank against
-- permissions.min_rank, two tables. Applies to team overrides as well as
-- global rows, which is what makes a live permissions UI safe to ship.
create or replace function public.guard_permission_min_rank()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_min  integer;
  v_rank integer;
begin
  if not new.granted then
    return new;   -- revoking is always allowed
  end if;
  select min_rank into v_min
    from public.permissions where permission_key = new.permission_key;
  if v_min is null then
    return new;
  end if;
  select rank into v_rank
    from public.roles where scope = new.scope and key = new.role_key;

  if v_rank < v_min then
    raise exception
      'Permission % requires rank >= %; role % has rank %',
      new.permission_key, v_min, new.role_key, v_rank
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger role_permissions_min_rank
  before insert or update on public.role_permissions
  for each row execute function public.guard_permission_min_rank();

-- The seeded default matrix. Reproduces today's behaviour EXACTLY, so switching
-- the engine on is a no-op until someone edits a row:
--   is_team_manager  was role >= 'manager'  → owner + manager
--   is_team_captain  was role >= 'captain'  → owner + manager + captain
-- The repetition is deliberate: there is no inheritance, so every tick in the
-- future grid is a stated fact rather than an implication.
insert into public.role_permissions (team_id, scope, role_key, permission_key)
select null, 'team', r.key, p.permission_key
  from public.roles r
  cross join public.permissions p
 where r.scope = 'team'
   and (
     -- Owner holds everything. (can() also short-circuits for the owner, so
     -- these rows are belt-and-braces AND make the grid show the truth.)
     r.key = 'owner'
     -- Manager: everything that is not owner-floored.
     or (r.key = 'manager' and coalesce(p.min_rank, 0) <= 30)
     -- Captain: match-day authority plus the unclaimed-contact read, which is
     -- what is_team_captain gated before this change.
     or (r.key = 'captain' and p.permission_key in (
           'match.lineup.set', 'match.score', 'match.official.assign',
           'team.contact.view'))
     -- player: nothing.
   );


-- -----------------------------------------------------------------------------
-- grants — a permission handed to ONE person on ONE resource.
-- -----------------------------------------------------------------------------
-- The delegation path, and the reason `match_officials.scorer` stops being a
-- special case inside _can_score_innings. Before this, that row granted nothing
-- at all while the organiser console advertised "revoke scoring rights or take
-- over the match at any time".
--
-- entity_id is polymorphic (a team id OR a match id) so it carries no FK — the
-- same trade-off team_members already makes with its user_id/unclaimed_id XOR.
-- Cleanup triggers on teams/matches live in their own files.
create table public.grants (
  grant_id        uuid primary key default gen_random_uuid(),
  subject_id      uuid not null references public.profiles(user_id) on delete cascade,
  scope           text not null,
  entity_id       uuid not null,
  permission_key  text not null,
  granted_by      uuid references public.profiles(user_id) on delete set null,
  expires_at      timestamptz,
  created_at      timestamptz not null default now(),

  foreign key (permission_key, scope)
    references public.permission_scopes (permission_key, scope) on delete cascade,
  unique (subject_id, scope, entity_id, permission_key)
);

create index idx_grants_subject on public.grants (subject_id);
create index idx_grants_perm    on public.grants (permission_key);
create index idx_grants_granted_by on public.grants (granted_by);
-- The index can()'s first branch depends on.
create index idx_grants_lookup
  on public.grants (scope, entity_id, permission_key);

-- A direct grant has no role, so min_rank cannot apply to it. Without this
-- check, `grants` would be a clean route around the matrix.
create or replace function public.guard_grant_is_grantable()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.permissions
     where permission_key = new.permission_key and direct_grantable
  ) then
    raise exception
      'Permission % cannot be granted directly; it is role-only',
      new.permission_key
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger grants_grantable
  before insert or update on public.grants
  for each row execute function public.guard_grant_is_grantable();


-- =============================================================================
-- RLS
-- =============================================================================
-- The catalogue is world-readable: clients render role names and permission
-- descriptions. None of it is user-writable — migrations and service_role only.
-- `role_permissions` is the exception and its write policies need can(), so
-- they are declared in 0210 with the other deferred policies.
alter table public.roles                  enable row level security;
alter table public.role_exclusion_sets    enable row level security;
alter table public.role_exclusion_members enable row level security;
alter table public.permissions            enable row level security;
alter table public.permission_scopes      enable row level security;
alter table public.role_permissions       enable row level security;
alter table public.grants                 enable row level security;

create policy "roles_read_all" on public.roles
  for select to anon, authenticated using (true);
create policy "role_exclusion_sets_read_all" on public.role_exclusion_sets
  for select to anon, authenticated using (true);
create policy "role_exclusion_members_read_all" on public.role_exclusion_members
  for select to anon, authenticated using (true);
create policy "permissions_read_all" on public.permissions
  for select to anon, authenticated using (true);
create policy "permission_scopes_read_all" on public.permission_scopes
  for select to anon, authenticated using (true);

-- Grants' SELECT policy is declared in 0210 as a SINGLE policy covering both
-- "the subject sees their own" and "team staff can see it". Splitting it across
-- the two files would leave two permissive policies on the same (table,
-- command, role), which advisor 0006 rejects — every permissive policy is
-- tested for every row.

-- -----------------------------------------------------------------------------
-- Deferred to 0210: role_permissions' read AND write policies.
--
-- The read policy needs is_team_member() and the write policy needs can(), both
-- of which read team_members / team_member_roles and so cannot exist until
-- 0210. RLS is enabled here with no policy, which denies everything — the safe
-- direction — and 0210 adds all three. (Advisor 0008 flags "RLS enabled, no
-- policy"; it passes once 0210 has run, which is the only state that ships.)
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- Seed: the one exclusion rule. Last, for the 55006 reason noted above.
-- -----------------------------------------------------------------------------
-- "A member is at most ONE of owner / manager / player." That is the whole of
-- the old single-column model, expressed as data — and `captain` is absent on
-- purpose, so owner+captain (the case the column could not represent) is simply
-- not constrained.
--
-- Deferral matters here too: with max_roles 1 and three members the build order
-- is harmless, but a future set with max_roles 2 would be transiently invalid
-- at the second insert and valid again at the third.
do $$
declare v_set uuid;
begin
  insert into public.role_exclusion_sets (scope, name, max_roles)
  values ('team', 'Team authority', 1)
  returning set_id into v_set;

  insert into public.role_exclusion_members (set_id, scope, role_key)
  values (v_set, 'team', 'owner'),
         (v_set, 'team', 'manager'),
         (v_set, 'team', 'player');
end $$;
