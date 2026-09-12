-- =============================================================================
-- 0212 · team_authorization — shared predicates, RPCs, and dependent policies
-- =============================================================================
-- Requires both team_members and team_member_roles.

-- =============================================================================
-- can() — the one authorization question
-- =============================================================================
-- Declared here after the catalogue migrations because it reads team_members and
-- team_member_roles, and it is `language sql`, so its body IS checked at CREATE
-- time (§12.0).
--
-- ORDER MATTERS, and validation comes first. With the owner short-circuit
-- ahead of validation, a typo'd or wrong-scope key — can('team', t,
-- 'team.disbnad') — would return TRUE for every owner. A misspelling must
-- silently DENY, never silently GRANT.
--
--   0. (permission, scope) is registered          → else false, fail closed
--   1. a live direct grant on this exact resource, of a direct_grantable key
--   2. the owner short-circuit
--   3. role-derived: union over the member's roles of effective(entity, role)
--
-- SECURITY DEFINER + a pinned search_path is non-negotiable here: this function
-- IS the RLS boundary, and a definer function with a mutable search_path runs
-- as its owner against schemas the caller may control (advisor 0011).
-- -----------------------------------------------------------------------------

-- effective(team, role, permission): the team's delta over the global default.
-- coalesce IS the delta semantics — a team row (true OR false) wins over the
-- global row, and absence of both denies.
create or replace function public._role_grants(
  p_team_id    uuid,
  p_scope      text,
  p_role_key   text,
  p_permission text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select rp.granted from public.role_permissions rp
      where rp.team_id = p_team_id and rp.scope = p_scope
        and rp.role_key = p_role_key and rp.permission_key = p_permission),
    (select rp.granted from public.role_permissions rp
      where rp.team_id is null and rp.scope = p_scope
        and rp.role_key = p_role_key and rp.permission_key = p_permission),
    false
  );
$$;

revoke all on function public._role_grants(uuid, text, text, text) from public;
grant execute on function public._role_grants(uuid, text, text, text) to authenticated;

create or replace function public.can(
  p_scope      text,
  p_entity_id  uuid,
  p_permission text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    -- 0. Validate first. Fail closed.
    exists (
      select 1 from public.permission_scopes ps
       where ps.permission_key = p_permission and ps.scope = p_scope
    )
    and (
      -- 1. A live direct grant of a directly-grantable permission. Re-checking
      --    direct_grantable here (not only at write time) means clearing the
      --    flag revokes existing grants immediately.
      exists (
        select 1
          from public.grants g
          join public.permissions p on p.permission_key = g.permission_key
         where g.subject_id = auth.uid()
           and g.scope     = p_scope
           and g.entity_id = p_entity_id
           and g.permission_key = p_permission
           and p.direct_grantable
           and (g.expires_at is null or g.expires_at > now())
      )
      -- 2 + 3. Role-derived. Team scope only for now; tournaments keep
      --        organizers uuid[] and will need their own assignment relation.
      or (
        p_scope = 'team'
        and exists (
          select 1
            from public.team_members tm
            join public.team_member_roles tmr
              on tmr.membership_id = tm.membership_id
           where tm.team_id = p_entity_id
             and tm.user_id = auth.uid()
             and tm.status  = 'active'
             and (
               -- The owner is unconditional: no matrix edit, and no per-team
               -- override, can lock a team out of itself.
               tmr.role_key = 'owner'
               or public._role_grants(p_entity_id, tmr.scope, tmr.role_key, p_permission)
             )
        )
      )
    );
$$;

revoke all on function public.can(text, uuid, text) from public;
grant execute on function public.can(text, uuid, text) to authenticated;

-- The same question asked about SOMEONE ELSE. can() is always about auth.uid();
-- a few server-side reports need "does user X run team Y?" — e.g. deciding
-- whether an appointed umpire is neutral with respect to a fixture.
--
-- Deliberately NOT granted to authenticated: "what can that person do?" is an
-- information leak. Callers are SECURITY DEFINER functions that have already
-- authorized the caller for something else.
create or replace function public._user_team_can(
  p_user_id    uuid,
  p_team_id    uuid,
  p_permission text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.team_members tm
      join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
     where tm.team_id = p_team_id
       and tm.user_id = p_user_id
       and tm.status  = 'active'
       and (
         tmr.role_key = 'owner'
         or public._role_grants(p_team_id, tmr.scope, tmr.role_key, p_permission)
       )
  );
$$;

revoke all on function public._user_team_can(uuid, uuid, text) from public;

create or replace function public.team_can(p_team_id uuid, p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can('team', p_team_id, p_permission);
$$;

revoke all on function public.team_can(uuid, text) from public;
grant execute on function public.team_can(uuid, text) to authenticated;


-- -----------------------------------------------------------------------------
-- The shims. ~45 call sites still say is_team_manager / is_team_captain, and
-- they keep working unchanged — that is the whole point of staging the sweep.
-- Step 2 replaces each with the specific key that fits; Step 4 deletes these.
-- -----------------------------------------------------------------------------
create or replace function public.is_team_manager(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can('team', p_team_id, 'team.roster.write');
$$;

revoke all on function public.is_team_manager(uuid) from public;
grant execute on function public.is_team_manager(uuid) to authenticated;

create or replace function public.is_team_captain(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.can('team', p_team_id, 'match.lineup.set');
$$;

revoke all on function public.is_team_captain(uuid) from public;
grant execute on function public.is_team_captain(uuid) to authenticated;

-- NOT a permission — plain membership. Used by the private-roster read policy.
create or replace function public.is_team_member(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.team_members tm
     where tm.team_id = p_team_id
       and tm.user_id = auth.uid()
       and tm.status  = 'active'
  );
$$;

revoke all on function public.is_team_member(uuid) from public;
-- authenticated only: anon-facing policies use the public-team branch instead,
-- so no SECURITY DEFINER function is reachable by anon (advisor 0028/0029).
grant execute on function public.is_team_member(uuid) to authenticated;

-- The notification AUDIENCE, and it must follow the matrix: if captains gain
-- team.challenge.send, the challenge notification has to reach them. This
-- replaces team_staff_ids(), which hardcoded "role >= manager" and would have
-- desynchronised the first time anyone edited the matrix.
create or replace function public.team_members_with(
  p_team_id    uuid,
  p_permission text
)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select distinct tm.user_id
    from public.team_members tm
    join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
   where tm.team_id = p_team_id
     and tm.status  = 'active'
     and tm.user_id is not null
     and (
       tmr.role_key = 'owner'
       or public._role_grants(p_team_id, tmr.scope, tmr.role_key, p_permission)
     );
$$;

revoke all on function public.team_members_with(uuid, text) from public;
grant execute on function public.team_members_with(uuid, text) to authenticated;

-- Back-compat wrapper for the 17 fan-out call sites. "Staff" now means whoever
-- can actually edit the roster, which is the honest audience.
create or replace function public.team_staff_ids(p_team_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.team_members_with(p_team_id, 'team.roster.write');
$$;

revoke all on function public.team_staff_ids(uuid) from public;
grant execute on function public.team_staff_ids(uuid) to authenticated;


-- =============================================================================
-- Membership + role mutation
-- =============================================================================
-- There is NO universal "every new membership gets player" trigger. That is
-- what collided with the SSD set: create_owner_membership would have produced
-- player + owner and violated {owner, manager, player} max 1 on the very first
-- team. Each creation path names the role it is creating, atomically.
-- -----------------------------------------------------------------------------

-- Internal: attach a role, filling in the denormalised columns from the
-- catalogue so callers cannot get them wrong.
create or replace function public._attach_role(
  p_membership_id uuid,
  p_role_key      text,
  p_granted_by    uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_team_id   uuid;
  v_singleton boolean;
begin
  select team_id into v_team_id
    from public.team_members where membership_id = p_membership_id;
  if v_team_id is null then
    raise exception 'No such membership %', p_membership_id using errcode = 'P0002';
  end if;

  select is_singleton into v_singleton
    from public.roles where scope = 'team' and key = p_role_key;
  if v_singleton is null then
    raise exception 'No such team role "%"', p_role_key using errcode = 'P0002';
  end if;

  -- The conflict target is the PRIMARY KEY and nothing else. A bare
  -- `on conflict do nothing` also swallows a violation of
  -- team_member_roles_singleton_per_team — so granting `captain` to a second
  -- person would report success and write nothing, which is how a silent
  -- failure gets shipped. Re-granting a role someone already holds is the only
  -- no-op; taking a singleton someone else holds must raise 23505.
  insert into public.team_member_roles
    (membership_id, scope, role_key, team_id, is_singleton, granted_by)
  values
    (p_membership_id, 'team', p_role_key, v_team_id, v_singleton, p_granted_by)
  on conflict (membership_id, scope, role_key) do nothing;
end;
$$;

revoke all on function public._attach_role(uuid, text, uuid) from public;

-- 4. Every new membership gets exactly ONE initial role, chosen by whoever is
--    creating it.
--
--    An earlier design had a universal "everyone starts as player" trigger.
--    That collided with the SSD set on the very first team ever created:
--    create_owner_membership would produce player + owner, and
--    {owner, manager, player} max 1 would reject it. The fix is not to drop the
--    trigger — it is to let the creating path SAY which role it means, via a
--    transaction-local setting. One role is attached, and it is the right one.
--
--    Default 'player' keeps every other path (seeds, add_unclaimed_team_member,
--    a direct insert by a superuser) correct without ceremony.
create or replace function public.assign_initial_role()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_role text := nullif(current_setting('matchday.initial_role', true), '');
begin
  perform public._attach_role(new.membership_id, coalesce(v_role, 'player'), new.added_by);
  -- Reset so a second insert in the same transaction does not inherit it.
  perform set_config('matchday.initial_role', '', true);
  return null;
end;
$$;

create trigger team_members_assign_initial_role
  after insert on public.team_members
  for each row execute function public.assign_initial_role();



-- The ONLY way an owner row is born. teams.created_by is history; this is what
-- makes the `owner` role the canonical answer to "who runs this team?".
create or replace function public.create_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_membership uuid;
begin
  if new.created_by is null then
    return new;
  end if;

  -- Declare the intent; assign_initial_role() attaches exactly this role, so
  -- the membership never passes through a `player` state that would collide
  -- with the {owner, manager, player} exclusion set.
  perform set_config('matchday.initial_role', 'owner', true);

  insert into public.team_members (team_id, user_id, in_squad, added_by)
  values (new.team_id, new.created_by, true, new.created_by)
  returning membership_id into v_membership;

  return new;
end;
$$;

create trigger teams_create_owner_membership
  after insert on public.teams
  for each row execute function public.create_owner_membership();

-- Membership creation. team_members INSERT is RPC-only (policy below), so the
-- membership and its first role are always created together.
create or replace function public.add_team_member(
  p_team_id       uuid,
  p_user_id       uuid,
  p_role_key      text default 'player',
  p_jersey_number integer default null,
  p_in_squad      boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid        uuid := auth.uid();
  v_membership uuid;
  v_rank       integer;
  v_caller     integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public.can('team', p_team_id, 'team.roster.write') then
    raise exception 'Not allowed to add players to this team' using errcode = '42501';
  end if;

  -- You may not seat someone at or above your own rung.
  select rank into v_rank from public.roles where scope='team' and key = p_role_key;
  select max(r.rank) into v_caller
    from public.team_members tm
    join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
    join public.roles r on r.scope = tmr.scope and r.key = tmr.role_key
   where tm.team_id = p_team_id and tm.user_id = v_uid and tm.status = 'active';

  if v_rank is null then
    raise exception 'No such team role "%"', p_role_key using errcode = 'P0002';
  end if;
  if coalesce(v_caller, -1) <= v_rank then
    raise exception 'Cannot grant a role at or above your own' using errcode = '42501';
  end if;

  perform set_config('matchday.initial_role', p_role_key, true);

  insert into public.team_members (team_id, user_id, jersey_number, in_squad, added_by)
  values (p_team_id, p_user_id, p_jersey_number, p_in_squad, v_uid)
  returning membership_id into v_membership;

  return v_membership;
end;
$$;

revoke all on function public.add_team_member(uuid, uuid, text, integer, boolean) from public;
grant execute on function public.add_team_member(uuid, uuid, text, integer, boolean)
  to authenticated;

-- -----------------------------------------------------------------------------
-- grant_team_role / revoke_team_role
-- -----------------------------------------------------------------------------
-- Roles are added and removed individually now, not swapped within a slot. So
-- "promote to manager" is revoke player + grant manager in ONE transaction —
-- which is exactly why the at-least-one-role trigger has to be deferred.
--
-- The invariant, using the member's MAX rank across their roles: you may never
-- grant a role at or above your own rank, nor act on a member whose max rank is
-- at or above yours.
-- -----------------------------------------------------------------------------
create or replace function public._member_rank(p_membership_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(max(r.rank), -1)
    from public.team_member_roles tmr
    join public.roles r on r.scope = tmr.scope and r.key = tmr.role_key
   where tmr.membership_id = p_membership_id;
$$;

revoke all on function public._member_rank(uuid) from public;

create or replace function public._my_rank(p_team_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(max(r.rank), -1)
    from public.team_members tm
    join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
    join public.roles r on r.scope = tmr.scope and r.key = tmr.role_key
   where tm.team_id = p_team_id and tm.user_id = auth.uid() and tm.status = 'active';
$$;

revoke all on function public._my_rank(uuid) from public;

create or replace function public.grant_team_role(
  p_membership_id uuid,
  p_role_key      text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid       uuid := auth.uid();
  v_team_id   uuid;
  v_target    uuid;
  v_rank      integer;
  v_min_rank  integer;
  v_mine      integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_role_key = 'owner' then
    raise exception 'Use transfer_team_ownership() to move ownership'
      using errcode = '42501';
  end if;

  select tm.team_id, tm.user_id into v_team_id, v_target
    from public.team_members tm
   where tm.membership_id = p_membership_id and tm.status = 'active'
   for update;
  if v_team_id is null then
    raise exception 'No such active membership' using errcode = 'P0002';
  end if;

  select rank into v_rank from public.roles where scope='team' and key = p_role_key;
  if v_rank is null then
    raise exception 'No such team role "%"', p_role_key using errcode = 'P0002';
  end if;

  -- Which permission is needed depends on how powerful the role is.
  select min_rank into v_min_rank from public.permissions
   where permission_key = 'team.staff.appoint';
  if v_rank >= coalesce(v_min_rank, 40) - 10 then
    if not public.can('team', v_team_id, 'team.staff.appoint') then
      raise exception 'Only the team owner can appoint staff' using errcode = '42501';
    end if;
  elsif not public.can('team', v_team_id, 'team.roster.role') then
    raise exception 'Not allowed to change roles on this team' using errcode = '42501';
  end if;

  v_mine := public._my_rank(v_team_id);
  if v_mine <= v_rank then
    raise exception 'Cannot grant a role at or above your own rank'
      using errcode = '42501';
  end if;
  if v_target is distinct from v_uid
     and v_mine <= public._member_rank(p_membership_id) then
    raise exception 'Cannot change the roles of someone at or above your own rank'
      using errcode = '42501';
  end if;

  -- Nobody's role change may strip `owner` — least of all the owner's own.
  -- `owner` shares the {owner, manager, player} exclusion set, so "make me a
  -- manager" used to delete the owner row and hand back a team with ZERO
  -- owners: no one holding the short-circuit in can(), so no one able to
  -- disband it, appoint staff or hand it on. leave_team() already refuses an
  -- owner for the same reason, and the repository contract promises this one
  -- does too. Ownership moves through transfer_team_ownership, or not at all.
  if exists (
    select 1 from public.team_member_roles
     where membership_id = p_membership_id and scope = 'team' and role_key = 'owner'
  ) and exists (
    select 1
      from public.role_exclusion_members a
      join public.role_exclusion_members b on b.set_id = a.set_id
     where a.scope = 'team' and a.role_key = 'owner'
       and b.scope = 'team' and b.role_key = p_role_key
  ) then
    raise exception 'Transfer ownership before changing the owner''s role'
      using errcode = '42501';
  end if;

  -- Granting a role that shares an exclusion set with one they already hold
  -- REPLACES it. That is what "at most one of these" means in practice: making
  -- someone a manager is exactly making them stop being a player.
  --
  -- Doing it here rather than making callers pre-revoke matters: the two
  -- statements have to be one transaction (the at-least-one-role check is
  -- deferred precisely so they can be), and leaving that to every call site is
  -- how you get a half-promoted member. The SSD trigger still guards every
  -- other write path — see the direct-insert case in the test suite.
  delete from public.team_member_roles tmr
   where tmr.membership_id = p_membership_id
     and tmr.role_key <> p_role_key
     and exists (
       select 1
         from public.role_exclusion_members a
         join public.role_exclusion_members b on b.set_id = a.set_id
        where a.scope = tmr.scope and a.role_key = tmr.role_key
          and b.scope = 'team'    and b.role_key = p_role_key
     );

  perform public._attach_role(p_membership_id, p_role_key, v_uid);
end;
$$;

revoke all on function public.grant_team_role(uuid, text) from public;
grant execute on function public.grant_team_role(uuid, text) to authenticated;

create or replace function public.revoke_team_role(
  p_membership_id uuid,
  p_role_key      text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid     uuid := auth.uid();
  v_team_id uuid;
  v_target  uuid;
  v_rank    integer;
  v_mine    integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  -- is_singleton stops a SECOND owner; nothing stops ZERO. Ownership leaves
  -- only by transfer, or by the succession path in delete_user.
  if p_role_key = 'owner' then
    raise exception 'Transfer ownership instead of revoking it' using errcode = '42501';
  end if;

  select tm.team_id, tm.user_id into v_team_id, v_target
    from public.team_members tm
   where tm.membership_id = p_membership_id and tm.status = 'active'
   for update;
  if v_team_id is null then
    raise exception 'No such active membership' using errcode = 'P0002';
  end if;

  select rank into v_rank from public.roles where scope='team' and key = p_role_key;
  v_mine := public._my_rank(v_team_id);

  -- Stepping down from your own non-owner role is always allowed.
  if v_target is distinct from v_uid then
    if not public.can('team', v_team_id, 'team.roster.role') then
      raise exception 'Not allowed to change roles on this team' using errcode = '42501';
    end if;
    if v_mine <= public._member_rank(p_membership_id) then
      raise exception 'Cannot change the roles of someone at or above your own rank'
        using errcode = '42501';
    end if;
  end if;

  delete from public.team_member_roles
   where membership_id = p_membership_id and scope = 'team' and role_key = p_role_key;

  -- Taking away someone's LAST role would trip the at-least-one-role check at
  -- COMMIT. In the domain that is never what "un-captain them" means: they are
  -- still on the team, just not captain any more. Fall back to `player`.
  --
  -- Without this, a member created as captain-only could never be demoted at
  -- all — the caller would have to know to grant a second role first, in the
  -- same transaction, which is a trap rather than an API.
  if not exists (
    select 1 from public.team_member_roles where membership_id = p_membership_id
  ) then
    perform public._attach_role(p_membership_id, 'player', v_uid);
  end if;
end;
$$;

revoke all on function public.revoke_team_role(uuid, text) from public;
grant execute on function public.revoke_team_role(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- transfer_team_ownership — the only way the owner role moves.
-- -----------------------------------------------------------------------------
create or replace function public.transfer_team_ownership(
  p_team_id      uuid,
  p_new_owner_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_mine     uuid;
  v_theirs   uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Authorize BEFORE the self-transfer short-circuit. Reversed, this returned
  -- success to any caller passing themselves — harmless, but a non-owner being
  -- told "OK" is the kind of answer a client builds wrong UI on.
  select tm.membership_id into v_mine
    from public.team_members tm
    join public.team_member_roles tmr
      on tmr.membership_id = tm.membership_id and tmr.role_key = 'owner'
   where tm.team_id = p_team_id and tm.user_id = v_uid and tm.status = 'active'
   for update;

  if v_mine is null then
    raise exception 'Only the team owner can transfer ownership' using errcode = '42501';
  end if;
  if p_new_owner_id = v_uid then
    return;
  end if;

  select tm.membership_id into v_theirs
    from public.team_members tm
   where tm.team_id = p_team_id and tm.user_id = p_new_owner_id and tm.status = 'active'
   for update;
  if v_theirs is null then
    raise exception 'The new owner must already be an active member of the team'
      using errcode = '42501';
  end if;

  -- Demote first: team_member_roles_singleton_per_team forbids two owners even
  -- momentarily. The outgoing owner becomes a manager; the deferred
  -- at-least-one-role check is satisfied at COMMIT either way.
  delete from public.team_member_roles
   where membership_id = v_mine and scope = 'team' and role_key = 'owner';
  perform public._attach_role(v_mine, 'manager', v_uid);

  delete from public.team_member_roles
   where membership_id = v_theirs and scope = 'team'
     and role_key in ('manager', 'player');
  perform public._attach_role(v_theirs, 'owner', v_uid);
end;
$$;

revoke all on function public.transfer_team_ownership(uuid, uuid) from public;
grant execute on function public.transfer_team_ownership(uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- leave_team — spec §2.9 Flow 3. The only self-leave path; RLS denies a direct
-- self-update so nobody can flip another player's status, or their own role.
-- -----------------------------------------------------------------------------
create or replace function public.leave_team(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid            uuid := auth.uid();
  v_member_user_id uuid;
  v_is_owner       boolean;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select tm.user_id,
         exists (select 1 from public.team_member_roles tmr
                  where tmr.membership_id = tm.membership_id and tmr.role_key = 'owner')
    into v_member_user_id, v_is_owner
    from public.team_members tm
   where tm.membership_id = p_membership_id and tm.status = 'active'
   for update;

  if v_member_user_id is null or v_member_user_id <> v_uid then
    raise exception 'Cannot leave a membership that is not yours' using errcode = '42501';
  end if;
  if v_is_owner then
    raise exception 'Transfer ownership before leaving the team' using errcode = '42501';
  end if;

  -- Roles are a live assignment, not history: they go with the membership.
  delete from public.team_member_roles where membership_id = p_membership_id;

  update public.team_members
     set status = 'inactive', left_at = now()
   where membership_id = p_membership_id;
end;
$$;

revoke all on function public.leave_team(uuid) from public;
grant execute on function public.leave_team(uuid) to authenticated;


-- =============================================================================
-- RLS
-- =============================================================================

-- Read: public teams are world-readable; a PRIVATE team's roster only by its
-- own members. This was `using (true)` until 2026-09-10, which contradicted the
-- privacy='private' promise outright.
-- Split by ROLE on purpose. `is_team_member` is SECURITY DEFINER, and the
-- last-migration sweep (20260906120000) revokes anon's EXECUTE on every
-- definer function for good reason — one anon can call bypasses RLS as its
-- owner. Anon only ever needs the public-team branch, so it never touches the
-- function; the member branch is authenticated-only.
--
-- Two policies, but disjoint TO clauses, so advisor 0006 (one permissive
-- policy per table+command+ROLE) is satisfied.
create policy "team_members_read_anon"
  on public.team_members for select
  to anon
  using (
    exists (select 1 from public.teams t
             where t.team_id = team_members.team_id and t.privacy = 'public')
  );

create policy "team_members_read_public"
  on public.team_members for select
  to authenticated
  using (
    exists (select 1 from public.teams t
             where t.team_id = team_members.team_id and t.privacy = 'public')
    or (select public.is_team_member(team_id))
  );

-- INSERT is RPC-only: add_team_member() creates the membership and its first
-- role together. A bare insert would make a roleless member and fail the
-- deferred check at COMMIT — correct, but a worse error than refusing up front.
create policy "team_members_insert_rpc_only"
  on public.team_members for insert
  to authenticated
  with check (false);

create policy "team_members_update_managers"
  on public.team_members for update
  to authenticated
  using ((select public.team_can(team_id, 'team.roster.write')))
  with check ((select public.team_can(team_id, 'team.roster.write')));

create policy "team_members_delete_managers"
  on public.team_members for delete
  to authenticated
  using ((select public.team_can(team_id, 'team.roster.write')));

-- Roles follow the roster's visibility, and are written only through the RPCs.
create policy "team_member_roles_read_anon"
  on public.team_member_roles for select
  to anon
  using (
    exists (select 1 from public.teams t
             where t.team_id = team_member_roles.team_id and t.privacy = 'public')
  );

create policy "team_member_roles_read"
  on public.team_member_roles for select
  to authenticated
  using (
    exists (select 1 from public.teams t
             where t.team_id = team_member_roles.team_id and t.privacy = 'public')
    or (select public.is_team_member(team_id))
  );

create policy "team_member_roles_write_rpc_only"
  on public.team_member_roles for all
  to authenticated
  using (false)
  with check (false);


-- =============================================================================
-- Policies deferred from 0200 (teams) and the authorization catalogues
-- =============================================================================
-- They call can() / is_team_member(), which cannot exist before this table
-- does. Declaring them here beats making the predicate `language plpgsql`,
-- whose body would go unchecked at CREATE time — exactly the trap §12.0 warns
-- about. The headers of both files point here.
-- -----------------------------------------------------------------------------

create policy "teams_update_managers"
  on public.teams for update
  to authenticated
  using ((select public.team_can(team_id, 'team.profile.write')))
  with check ((select public.team_can(team_id, 'team.profile.write')));

create policy "teams_delete_owner"
  on public.teams for delete
  to authenticated
  using ((select public.team_can(team_id, 'team.disband')));

create policy "team_logos_insert_manager"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'team-logos'
    and (select public.team_can(((storage.foldername(name))[1])::uuid, 'team.profile.write'))
  );

create policy "team_logos_update_manager"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'team-logos'
    and (select public.team_can(((storage.foldername(name))[1])::uuid, 'team.profile.write'))
  )
  with check (
    bucket_id = 'team-logos'
    and (select public.team_can(((storage.foldername(name))[1])::uuid, 'team.profile.write'))
  );

create policy "team_logos_delete_manager"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'team-logos'
    and (select public.team_can(((storage.foldername(name))[1])::uuid, 'team.profile.write'))
  );

-- The matrix: global rows are a public catalogue; team overrides are visible to
-- that team and writable only by whoever holds team.permissions.manage — which
-- is floored at owner. Nobody may write a global row.
-- The global matrix is a public catalogue; team overrides are members-only.
create policy "role_permissions_read_anon"
  on public.role_permissions for select
  to anon
  using (team_id is null);

create policy "role_permissions_read"
  on public.role_permissions for select
  to authenticated
  using (team_id is null or (select public.is_team_member(team_id)));

create policy "role_permissions_write_team"
  on public.role_permissions for all
  to authenticated
  using (
    team_id is not null
    and (select public.team_can(team_id, 'team.permissions.manage'))
  )
  with check (
    team_id is not null
    and (select public.team_can(team_id, 'team.permissions.manage'))
  );

-- ONE permissive policy per (table, command, role) — advisor 0006 — so the two
-- cases are branches of a single expression rather than two policies.
-- Readable by: the subject themselves, or whoever can manage roles on the team
-- the grant is scoped to. Written only through RPCs / the match_officials
-- mirror trigger.
create policy "grants_read"
  on public.grants for select
  to authenticated
  using (
    (select auth.uid()) = subject_id
    or (scope = 'team' and (select public.team_can(entity_id, 'team.roster.role')))
  );

create policy "grants_write_rpc_only"
  on public.grants for all
  to authenticated
  using (false)
  with check (false);


-- =============================================================================
-- unclaimed_player_contact_for_manager() — the one way to read the PII
-- =============================================================================
-- unclaimed_players.phone_number / email are column-revoked in 0120: they are
-- contact details for people who never signed up and never consented. This is
-- the sanctioned read, and it re-checks that the caller actually has standing
-- on a team the placeholder plays for.
--
-- It lives here rather than with its table because it is `language sql` — body
-- checked at CREATE time — and reads teams (0200) and team_members (0210).
create or replace function public.unclaimed_player_contact_for_manager(
  p_unclaimed_id uuid
)
returns table (phone_number text, email text)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select u.phone_number, u.email
    from public.unclaimed_players u
   where u.unclaimed_id = p_unclaimed_id
     and (
       u.added_by = auth.uid()
       or exists (
         select 1
           from public.team_members tm
          where tm.unclaimed_id = u.unclaimed_id
            and tm.status = 'active'
            and public.can('team', tm.team_id, 'team.contact.view')
       )
     );
$$;

revoke all on function public.unclaimed_player_contact_for_manager(uuid) from public;
grant execute on function public.unclaimed_player_contact_for_manager(uuid)
  to authenticated;


-- =============================================================================
-- add_unclaimed_team_member() — the one way to put a placeholder on a roster
-- =============================================================================
-- Creating an unclaimed player and rostering them is ONE user action, and it
-- must be one transaction: the two inserts straddle two tables, and a jersey
-- clash on the second would otherwise leave an orphaned placeholder behind.
--
-- SECURITY DEFINER since 2026-09-11 (was INVOKER): team_members INSERT is now
-- RPC-only, so this has to be able to write it. The explicit permission check
-- below is therefore load-bearing, not just a nicer error.
create or replace function public.add_unclaimed_team_member(
  p_team_id        uuid,
  p_display_name   text,
  p_phone_number   text default null,
  p_jersey_number  integer default null,
  p_player_profile jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_unclaimed_id  uuid;
  v_membership_id uuid;
begin
  if auth.uid() is null
     or not public.can('team', p_team_id, 'team.roster.write') then
    raise exception 'Only team staff can add players' using errcode = '42501';
  end if;

  insert into public.unclaimed_players
    (display_name, phone_number, player_profile, added_by)
  values
    (p_display_name,
     nullif(trim(p_phone_number), ''),
     coalesce(p_player_profile, '{}'::jsonb),
     (select auth.uid()))
  returning unclaimed_id into v_unclaimed_id;

  -- A duplicate jersey raises here, and the placeholder above goes with it.
  insert into public.team_members
    (team_id, unclaimed_id, jersey_number, added_by)
  values
    (p_team_id, v_unclaimed_id, p_jersey_number, (select auth.uid()))
  returning membership_id into v_membership_id;
  -- No set_config: the default is 'player', which is the only role flagged
  -- allows_unclaimed — and the only one guard_role_needs_account would permit.

  return v_membership_id;
end;
$$;

revoke all on function
  public.add_unclaimed_team_member(uuid, text, text, integer, jsonb)
  from public;
grant execute on function
  public.add_unclaimed_team_member(uuid, text, text, integer, jsonb)
  to authenticated;
