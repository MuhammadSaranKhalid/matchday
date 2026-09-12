-- =============================================================================
-- 0205 · permission_scopes — valid entity types for each permission
-- =============================================================================
-- Design + decision log: docs/team-roles-design.md

create table public.permission_scopes (
  permission_key  text not null
                    references public.permissions(permission_key) on delete cascade,
  scope           text not null
                    check (scope in ('team', 'match', 'tournament', 'club')),
  primary key (permission_key, scope)
);

-- Which entity types each permission may be evaluated against.
-- match.score appears TWICE on purpose — that is the whole point.
insert into public.permission_scopes (permission_key, scope)
select permission_key, 'team' from public.permissions
union all
select 'match.score', 'match'            -- a scorer nominated for ONE match
union all
select 'match.official.assign', 'match'; -- an organiser delegating on ONE match

-- Catalogue data is world-readable and writable only by migrations/service_role.
alter table public.permission_scopes      enable row level security;

create policy "permission_scopes_read_all" on public.permission_scopes
  for select to anon, authenticated using (true);
