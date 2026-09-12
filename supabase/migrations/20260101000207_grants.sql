-- =============================================================================
-- 0207 · grants — direct permissions on individual resources
-- =============================================================================
-- Design + decision log: docs/team-roles-design.md

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

alter table public.grants                 enable row level security;

-- Grants' SELECT policy is declared after the team membership helpers as a SINGLE policy covering both
-- "the subject sees their own" and "team staff can see it". Splitting it across
-- the two files would leave two permissive policies on the same (table,
-- command, role), which advisor 0006 rejects — every permissive policy is
-- tested for every row.
