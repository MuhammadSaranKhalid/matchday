-- =============================================================================
-- 0203 · role_exclusion_members — roles covered by an exclusion set
-- =============================================================================
-- Design + decision log: docs/team-roles-design.md

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
-- including `enable row level security` below.

-- Catalogue data is world-readable and writable only by migrations/service_role.
alter table public.role_exclusion_members enable row level security;

create policy "role_exclusion_members_read_all" on public.role_exclusion_members
  for select to anon, authenticated using (true);

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
