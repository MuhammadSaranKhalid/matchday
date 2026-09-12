-- =============================================================================
-- 0206 · role_permissions — global defaults and per-team permission deltas
-- =============================================================================
-- Design + decision log: docs/team-roles-design.md

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

alter table public.role_permissions       enable row level security;

-- Read and write policies are declared after the team membership helpers.
-- is_team_member() and can() depend on team_members / team_member_roles, so
-- those tables and helpers must exist before the policies can be created.
-- RLS is enabled here with no policy, which denies access until then.
