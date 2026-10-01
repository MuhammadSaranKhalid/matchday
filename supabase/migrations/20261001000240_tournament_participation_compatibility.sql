-- 20261001000240_tournament_participation_compatibility.sql
-- Canonical Transitional Operations, One-Way Compatibility Sync, and Backfill
-- Clean Architecture Step 6 / Phase 3.1

-- ─── 0. Register Frozen Tournament & Team Capabilities ─────────────────────────
alter table public.permissions drop constraint if exists permissions_permission_key_check;
alter table public.permissions add constraint permissions_permission_key_check check (permission_key ~ '^[a-z]+(\.[a-z_]+){1,3}$');

alter table public.tournament_entries drop constraint if exists tournament_entries_source_registration_fk;
alter table public.tournament_entries add constraint tournament_entries_source_registration_fk
  foreign key (registration_id, tournament_id, team_id)
  references public.tournament_registrations (registration_id, tournament_id, team_id)
  on delete restrict;

insert into public.permissions
  (permission_key, resource, action, description, min_rank, direct_grantable, sort_order)
values
  ('tournament.payment.manage', 'finance', 'manage', 'Record and void tournament entry fee payments and manage financial ledger', 30, false, 245),
  ('tournament.squad.review', 'squad', 'review', 'Review, approve, and manage tournament participant squad rosters', 30, false, 246),
  ('team.tournament.squad.manage', 'tournaments', 'manage', 'Manage team squad roster submissions and amendments for tournaments', 30, false, 107)
on conflict (permission_key) do update set
  resource = excluded.resource,
  action = excluded.action,
  description = excluded.description,
  min_rank = excluded.min_rank,
  direct_grantable = excluded.direct_grantable,
  sort_order = excluded.sort_order;

insert into public.permission_scopes (permission_key, scope)
values
  ('tournament.payment.manage', 'tournament'),
  ('tournament.squad.review', 'tournament'),
  ('team.tournament.squad.manage', 'team')
on conflict (permission_key, scope) do nothing;

insert into public.role_permissions (team_id, scope, role_key, permission_key, granted)
values
  (null, 'tournament', 'owner', 'tournament.payment.manage', true),
  (null, 'tournament', 'owner', 'tournament.squad.review', true),
  (null, 'tournament', 'manager', 'tournament.payment.manage', true),
  (null, 'tournament', 'manager', 'tournament.squad.review', true),
  (null, 'team', 'owner', 'team.tournament.squad.manage', true),
  (null, 'team', 'manager', 'team.tournament.squad.manage', true)
on conflict (team_id, scope, role_key, permission_key) do nothing;

grant execute on function public.can(text, uuid, text) to anon, authenticated;

-- ─── 0.1 Sanitized Public Compatibility Projection (View) ───────────────────────
-- Exposes safe, public participant information without leaking private application
-- messages, decision notes, financial amounts, channels, references, or audit actors.
create or replace view public.tournament_public_participants with (security_invoker = false) as
  select
    te.entry_id,
    te.tournament_id,
    te.team_id,
    'approved'::text as status,
    te.accepted_at as registered_at,
    tt.seed_number,
    tt.group_id,
    tm.team_name,
    tm.logo_url,
    tm.logo_monogram,
    tm.team_colors
  from public.tournament_entries te
  join public.tournaments t on t.tournament_id = te.tournament_id
  join public.teams tm on tm.team_id = te.team_id
  left join public.tournament_teams tt on tt.tournament_id = te.tournament_id and tt.team_id = te.team_id
  where te.status = 'active'
    and (
      t.privacy = 'public'
      or (
        auth.uid() is not null
        and (
          public.can('tournament', te.tournament_id, 'tournament.entries.manage')
          or public.can('team', te.team_id, 'team.tournament.enter')
        )
      )
    );

revoke all on public.tournament_public_participants from public;
grant select on public.tournament_public_participants to anon, authenticated;

-- ─── 0.2 Restrict Raw Legacy tournament_teams Table Access ────────────────────
-- Raw administrative table must no longer be readable by anonymous or public users.
-- Accessible only to tournament review staff and participating team authority.
drop policy if exists "tournament_teams_read" on public.tournament_teams;
drop policy if exists "tournament_teams_read_restricted" on public.tournament_teams;
create policy "tournament_teams_read_restricted"
  on public.tournament_teams
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.registration.review')
    or public.can('tournament', tournament_id, 'tournament.entries.manage')
    or public.can('team', team_id, 'team.tournament.enter')
    or public.can('team', team_id, 'team.tournament.squad.manage')
  );

-- ─── 1. Canonical tournament_register_team RPC ───────────────────────────────
-- Submits an application and proposed squad atomically.
create or replace function public.tournament_register_team(
  p_tournament_id uuid,
  p_team_id uuid,
  p_player_ids uuid[] default '{}',
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_reg_id uuid;
  v_tourn_sport text;
  v_team_sport text;
  v_reg_state public.tournament_registration_state;
  v_reg_deadline date;
  v_pid uuid;
  v_user_id uuid;
  v_unclaimed_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Authorization: caller must have authority to register this team
  if not (
    public.can('team', p_team_id, 'team.tournament.enter')
    or public.can('team', p_team_id, 'team.tournament.squad.manage')
  ) then
    raise exception 'Unauthorized to register team for tournaments' using errcode = '42501';
  end if;

  -- 2. Validate tournament exists and registration window is open
  select sport_id, registration_state, registration_deadline
    into v_tourn_sport, v_reg_state, v_reg_deadline
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  if v_reg_state != 'open' then
    raise exception 'Tournament registration is not open (current state: %)', v_reg_state
      using errcode = '22000';
  end if;

  if v_reg_deadline is not null and current_date > v_reg_deadline then
    raise exception 'Tournament registration deadline has passed (%)', v_reg_deadline
      using errcode = '22000';
  end if;

  -- 3. Validate team sport
  select sport_id into v_team_sport
    from public.teams
   where team_id = p_team_id;

  if not found then
    raise exception 'Team not found' using errcode = 'P0002';
  end if;

  if v_tourn_sport is distinct from v_team_sport then
    raise exception 'Team sport (%) does not match tournament sport (%)', v_team_sport, v_tourn_sport
      using errcode = '22000';
  end if;

  -- 4. Insert canonical registration
  insert into public.tournament_registrations (
    tournament_id,
    team_id,
    registered_by,
    message,
    status
  ) values (
    p_tournament_id,
    p_team_id,
    v_uid,
    nullif(btrim(coalesce(p_message, '')), ''),
    'pending'
  )
  returning registration_id into v_reg_id;

  -- 5. Insert proposed squad members relationally
  if p_player_ids is not null and array_length(p_player_ids, 1) > 0 then
    foreach v_pid in array p_player_ids loop
      -- Resolve whether v_pid points to user_id or unclaimed_id on the team's active roster
      select user_id, unclaimed_id
        into v_user_id, v_unclaimed_id
        from public.team_members
       where team_id = p_team_id
         and (user_id = v_pid or unclaimed_id = v_pid)
         and status = 'active';

      if not found then
        raise exception 'Player % is not an active member of team %', v_pid, p_team_id
          using errcode = '22000';
      end if;

      insert into public.tournament_registration_squad_members (
        registration_id,
        tournament_id,
        team_id,
        user_id,
        unclaimed_id,
        submitted_by
      ) values (
        v_reg_id,
        p_tournament_id,
        p_team_id,
        v_user_id,
        v_unclaimed_id,
        v_uid
      )
      on conflict do nothing;
    end loop;
  end if;

  return v_reg_id;
end;
$$;

revoke all on function public.tournament_register_team(uuid, uuid, uuid[], text) from public;
grant execute on function public.tournament_register_team(uuid, uuid, uuid[], text) to authenticated;

-- ─── 2. Canonical approve_tournament_registration RPC ────────────────────────
-- Atomic domain command: verifies preconditions, locks capacity, marks registration
-- approved, creates canonical active TournamentEntry, validates complete proposed squad,
-- and materializes valid squad members (no silent drops).
create or replace function public.approve_tournament_registration(
  p_registration_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_team_id uuid;
  v_reg_status public.tournament_registration_status;
  v_max_teams integer;
  v_entry_state public.tournament_entry_state;
  v_active_entries integer;
  v_entry_id uuid;
  v_prop record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock canonical registration row for update (fail closed if missing, NO legacy fallback)
  select tournament_id, team_id, status
    into v_tournament_id, v_team_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Verify registration is currently pending
  if v_reg_status != 'pending' then
    if v_reg_status = 'approved' then
      -- Idempotent return if already approved
      return;
    end if;
    raise exception 'Registration is not pending (status: %)', v_reg_status
      using errcode = '22000';
  end if;

  -- 3. Lock tournament root and inspect capacity + entry state
  select max_teams, entry_state
    into v_max_teams, v_entry_state
    from public.tournaments
   where tournament_id = v_tournament_id
     for update;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  -- 4. Authorize via canonical capability check
  if not public.can('tournament', v_tournament_id, 'tournament.registration.review') then
    raise exception 'Unauthorized to review registrations' using errcode = '42501';
  end if;

  -- 5. Entry Set Lock Precondition: once entry_state is locked, ordinary approval is blocked
  if v_entry_state = 'locked' then
    raise exception 'Cannot approve registration: tournament entry set is locked'
      using errcode = '22000';
  end if;

  -- 6. Verify Team does not already have an active canonical Entry
  if exists (
    select 1 from public.tournament_entries
     where tournament_id = v_tournament_id
       and team_id = v_team_id
       and status = 'active'
  ) then
    raise exception 'Team already has an active entry in this tournament'
      using errcode = '22000';
  end if;

  -- 7. Capacity Precondition: max_teams counts ACTIVE ACCEPTED ENTRIES
  select count(*)
    into v_active_entries
    from public.tournament_entries
   where tournament_id = v_tournament_id
     and status = 'active';

  if v_max_teams is not null and v_active_entries >= v_max_teams then
    raise exception 'Tournament capacity reached (%/% active entries)', v_active_entries, v_max_teams
      using errcode = '22000';
  end if;

  -- 8. Validate COMPLETE squad proposal before creating any canonical squad rows (no silent drops)
  for v_prop in
    select proposal_member_id, user_id, unclaimed_id
      from public.tournament_registration_squad_members
     where registration_id = p_registration_id
  loop
    if v_prop.user_id is not null then
      if not exists (
        select 1 from public.team_members
         where team_id = v_team_id and user_id = v_prop.user_id and status = 'active'
      ) then
        raise exception 'Cannot approve registration: proposed claimed player % is no longer an active member of team %',
          v_prop.user_id, v_team_id using errcode = '22000';
      end if;

      if exists (
        select 1 from public.tournament_squad_members
         where tournament_id = v_tournament_id
           and user_id = v_prop.user_id
           and membership_status = 'active'
      ) then
        raise exception 'Cannot approve registration: proposed claimed player % is already active in another entry for this tournament',
          v_prop.user_id using errcode = '22000';
      end if;
    elsif v_prop.unclaimed_id is not null then
      if not exists (
        select 1 from public.team_members
         where team_id = v_team_id and unclaimed_id = v_prop.unclaimed_id and status = 'active'
      ) then
        raise exception 'Cannot approve registration: proposed unclaimed player % is no longer an active member of team %',
          v_prop.unclaimed_id, v_team_id using errcode = '22000';
      end if;

      if exists (
        select 1 from public.tournament_squad_members
         where tournament_id = v_tournament_id
           and unclaimed_id = v_prop.unclaimed_id
           and membership_status = 'active'
      ) then
        raise exception 'Cannot approve registration: proposed unclaimed player % is already active in another entry for this tournament',
          v_prop.unclaimed_id using errcode = '22000';
      end if;
    end if;
  end loop;

  -- 9. Mark canonical Registration as approved
  update public.tournament_registrations
     set status = 'approved',
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 10. Atomically create canonical TournamentEntry
  insert into public.tournament_entries (
    tournament_id,
    team_id,
    registration_id,
    status,
    entry_source,
    accepted_by,
    accepted_at
  ) values (
    v_tournament_id,
    v_team_id,
    p_registration_id,
    'active',
    'application',
    v_uid,
    now()
  )
  on conflict (tournament_id, team_id) where status = 'active'
  do update set registration_id = excluded.registration_id
  returning entry_id into v_entry_id;

  if v_entry_id is null then
    raise exception 'Failed to create active tournament entry for registration %', p_registration_id
      using errcode = '22000';
  end if;

  -- 11. Populate canonical squad strictly from valid squad proposal
  insert into public.tournament_squad_members (
    entry_id, tournament_id, user_id, unclaimed_id, membership_status, added_by, added_at
  )
  select v_entry_id, v_tournament_id, pr.user_id, pr.unclaimed_id, 'active', v_uid, now()
    from public.tournament_registration_squad_members pr
   where pr.registration_id = p_registration_id;

  -- 12. One-way sync to legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  update public.tournament_teams
     set status = 'approved',
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.approve_tournament_registration(uuid) from public;
grant execute on function public.approve_tournament_registration(uuid) to authenticated;

-- ─── 3. Canonical reject_tournament_registration RPC ────────────────────────
create or replace function public.reject_tournament_registration(
  p_registration_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_reg_status public.tournament_registration_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock canonical registration row for update (fail closed, NO legacy fallback)
  select tournament_id, status
    into v_tournament_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization via canonical capability
  if not public.can('tournament', v_tournament_id, 'tournament.registration.review') then
    raise exception 'Unauthorized to review registrations' using errcode = '42501';
  end if;

  if v_reg_status != 'pending' then
    if v_reg_status = 'rejected' then
      return;
    end if;
    raise exception 'Registration is not pending (status: %)', v_reg_status
      using errcode = '22000';
  end if;

  -- 3. Update canonical registration
  update public.tournament_registrations
     set status = 'rejected',
         decision_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 4. One-way sync to legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  update public.tournament_teams
     set status = 'rejected',
         decision_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.reject_tournament_registration(uuid, text) from public;
grant execute on function public.reject_tournament_registration(uuid, text) to authenticated;

-- ─── 4. Canonical withdraw_tournament_registration RPC ───────────────────────
create or replace function public.withdraw_tournament_registration(
  p_registration_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_team_id uuid;
  v_reg_status public.tournament_registration_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock canonical registration row for update
  select team_id, status
    into v_team_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization: Team representative with tournament entry authority
  if not (
    public.can('team', v_team_id, 'team.tournament.enter')
    or public.is_team_manager(v_team_id)
  ) then
    raise exception 'Unauthorized to withdraw team registration' using errcode = '42501';
  end if;

  -- 3. Precondition: Can only withdraw pre-approval application
  if v_reg_status != 'pending' then
    if v_reg_status = 'withdrawn' then
      return;
    end if;
    raise exception 'Cannot withdraw registration: application is not pending (status: %)', v_reg_status
      using errcode = '22000';
  end if;

  -- 4. Update canonical Registration
  update public.tournament_registrations
     set status = 'withdrawn',
         withdrawn_at = now(),
         withdrawn_by = v_uid,
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 5. One-way sync to legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  update public.tournament_teams
     set status = 'withdrawn',
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.withdraw_tournament_registration(uuid, text) from public;
grant execute on function public.withdraw_tournament_registration(uuid, text) to authenticated;

-- ─── 5. Canonical withdraw_tournament_entry RPC ──────────────────────────────
create or replace function public.withdraw_tournament_entry(
  p_entry_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_team_id uuid;
  v_entry_status public.tournament_entry_status;
  v_entry_state public.tournament_entry_state;
  v_registration_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock Entry row FOR UPDATE
  select tournament_id, team_id, status, registration_id
    into v_tournament_id, v_team_id, v_entry_status, v_registration_id
    from public.tournament_entries
   where entry_id = p_entry_id
     for update;

  if not found then
    raise exception 'Tournament entry not found' using errcode = 'P0002';
  end if;

  if v_entry_status != 'active' then
    if v_entry_status = 'withdrawn' then
      return;
    end if;
    raise exception 'Tournament entry is not active (status: %)', v_entry_status
      using errcode = '22000';
  end if;

  -- 2. Lock Tournament root FOR UPDATE
  select entry_state
    into v_entry_state
    from public.tournaments
   where tournament_id = v_tournament_id
     for update;

  -- 3. Authorization: Team representative with entry authority or Tournament staff
  if not (
    public.can('team', v_team_id, 'team.tournament.enter')
    or public.is_team_manager(v_team_id)
    or public.can('tournament', v_tournament_id, 'tournament.entries.manage')
  ) then
    raise exception 'Unauthorized to withdraw tournament entry' using errcode = '42501';
  end if;

  -- 4. Ordinary withdrawal blocked if entry_state is locked
  if v_entry_state = 'locked' then
    raise exception 'Cannot withdraw entry: tournament entry set is locked'
      using errcode = '22000';
  end if;

  -- 5. Stamp withdrawal on canonical Entry
  update public.tournament_entries
     set status = 'withdrawn',
         withdrawn_by = v_uid,
         withdrawn_at = now(),
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where entry_id = p_entry_id;

  -- 6. Release active squad conflict: transition active squad members of this entry to 'removed'
  update public.tournament_squad_members
     set membership_status = 'removed',
         removed_by = v_uid,
         removed_at = now(),
         removal_reason = 'Entry withdrawn',
         updated_at = now()
   where entry_id = p_entry_id
     and membership_status = 'active';

  -- 7. One-way sync to legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  if v_registration_id is not null then
    update public.tournament_teams
       set status = 'withdrawn',
           updated_at = now()
     where registration_id = v_registration_id;
  end if;
end;
$$;

revoke all on function public.withdraw_tournament_entry(uuid, text) from public;
grant execute on function public.withdraw_tournament_entry(uuid, text) to authenticated;

-- ─── 6. Canonical Squad Member Mutation RPCs (Server-Stamped) ─────────────────
create or replace function public.tournament_squad_add_member(
  p_entry_id uuid,
  p_user_id uuid default null,
  p_unclaimed_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_team_id uuid;
  v_entry_status public.tournament_entry_status;
  v_squad_state public.tournament_squad_state;
  v_squad_member_id uuid;
  v_is_team_member boolean;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Enforce XOR identity: exactly one of user_id or unclaimed_id
  if num_nonnulls(p_user_id, p_unclaimed_id) != 1 then
    raise exception 'Must provide exactly one of user_id or unclaimed_id' using errcode = '22000';
  end if;

  -- 2. Lock Entry and Tournament
  select tournament_id, team_id, status, squad_state
    into v_tournament_id, v_team_id, v_entry_status, v_squad_state
    from public.tournament_entries
   where entry_id = p_entry_id
     for update;

  if not found then
    raise exception 'Tournament entry not found' using errcode = 'P0002';
  end if;

  if v_entry_status != 'active' then
    raise exception 'Cannot add squad member: entry is not active (status: %)', v_entry_status
      using errcode = '22000';
  end if;

  if v_squad_state = 'frozen' then
    raise exception 'Cannot add squad member: squad is frozen for this entry'
      using errcode = '22000';
  end if;

  -- 3. Authorization: Team Squad authority
  if not (
    public.can('team', v_team_id, 'team.tournament.squad.manage')
    or public.can('team', v_team_id, 'team.tournament.enter')
  ) then
    raise exception 'Unauthorized to manage team tournament squad' using errcode = '42501';
  end if;

  -- 4. Verify player is on team's active roster
  if p_user_id is not null then
    select exists (
      select 1 from public.team_members
       where team_id = v_team_id and user_id = p_user_id and status = 'active'
    ) into v_is_team_member;

    if not v_is_team_member then
      raise exception 'Claimed player % is not an active member of team %', p_user_id, v_team_id
        using errcode = '22000';
    end if;

    -- Check one-person one-active-entry rule in this tournament
    if exists (
      select 1 from public.tournament_squad_members
       where tournament_id = v_tournament_id
         and user_id = p_user_id
         and entry_id != p_entry_id
         and membership_status = 'active'
    ) then
      raise exception 'Player % is already active in another entry for this tournament', p_user_id
        using errcode = '22000';
    end if;

  elsif p_unclaimed_id is not null then
    select exists (
      select 1 from public.team_members
       where team_id = v_team_id and unclaimed_id = p_unclaimed_id and status = 'active'
    ) into v_is_team_member;

    if not v_is_team_member then
      raise exception 'Unclaimed player % is not an active member of team %', p_unclaimed_id, v_team_id
        using errcode = '22000';
    end if;

    if exists (
      select 1 from public.tournament_squad_members
       where tournament_id = v_tournament_id
         and unclaimed_id = p_unclaimed_id
         and entry_id != p_entry_id
         and membership_status = 'active'
    ) then
      raise exception 'Unclaimed player % is already active in another entry for this tournament', p_unclaimed_id
        using errcode = '22000';
    end if;
  end if;

  -- 5. Insert or reactivate squad member row with server-bound audit
  insert into public.tournament_squad_members (
    entry_id,
    tournament_id,
    user_id,
    unclaimed_id,
    membership_status,
    added_by,
    added_at
  ) values (
    p_entry_id,
    v_tournament_id,
    p_user_id,
    p_unclaimed_id,
    'active',
    v_uid,
    now()
  )
  on conflict do nothing
  returning squad_member_id into v_squad_member_id;

  if v_squad_member_id is null then
    -- If already existed as removed, reactivate it cleanly
    update public.tournament_squad_members
       set membership_status = 'active',
           added_by = v_uid,
           added_at = now(),
           removed_by = null,
           removed_at = null,
           removal_reason = null,
           updated_at = now()
     where entry_id = p_entry_id
       and (
         (p_user_id is not null and user_id = p_user_id)
         or (p_unclaimed_id is not null and unclaimed_id = p_unclaimed_id)
       )
     returning squad_member_id into v_squad_member_id;
  end if;

  return v_squad_member_id;
end;
$$;

revoke all on function public.tournament_squad_add_member(uuid, uuid, uuid) from public;
grant execute on function public.tournament_squad_add_member(uuid, uuid, uuid) to authenticated;

create or replace function public.tournament_squad_remove_member(
  p_squad_member_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_entry_id uuid;
  v_team_id uuid;
  v_entry_status public.tournament_entry_status;
  v_squad_state public.tournament_squad_state;
  v_current_status text;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Select squad member and lock row
  select entry_id, membership_status
    into v_entry_id, v_current_status
    from public.tournament_squad_members
   where squad_member_id = p_squad_member_id
     for update;

  if not found then
    raise exception 'Squad member not found' using errcode = 'P0002';
  end if;

  if v_current_status = 'removed' then
    -- Idempotent return
    return;
  end if;

  -- 2. Lock parent Entry
  select team_id, status, squad_state
    into v_team_id, v_entry_status, v_squad_state
    from public.tournament_entries
   where entry_id = v_entry_id
     for update;

  if v_entry_status != 'active' then
    raise exception 'Cannot remove squad member: entry is not active' using errcode = '22000';
  end if;

  if v_squad_state = 'frozen' then
    raise exception 'Cannot remove squad member: squad is frozen for this entry' using errcode = '22000';
  end if;

  -- 3. Authorization: Team Squad authority
  if not (
    public.can('team', v_team_id, 'team.tournament.squad.manage')
    or public.can('team', v_team_id, 'team.tournament.enter')
  ) then
    raise exception 'Unauthorized to manage team tournament squad' using errcode = '42501';
  end if;

  -- 4. Transition to removed with server-bound audit
  update public.tournament_squad_members
     set membership_status = 'removed',
         removed_by = v_uid,
         removed_at = now(),
         removal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where squad_member_id = p_squad_member_id;
end;
$$;

revoke all on function public.tournament_squad_remove_member(uuid, text) from public;
grant execute on function public.tournament_squad_remove_member(uuid, text) to authenticated;

-- ─── 7. Canonical tournament_record_payment RPC & Ledger Adapter ─────────────
create or replace function public.tournament_record_payment(
  p_registration_id uuid,
  p_amount_paid numeric,
  p_channel text default 'cash',
  p_reference text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_entry_id uuid;
  v_current_total numeric;
  v_delta numeric;
  v_entry_fee numeric;
  v_legacy_status text;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_amount_paid is null or p_amount_paid < 0 then
    raise exception 'Amount paid must be non-negative' using errcode = '22003';
  end if;

  -- 1. Find entry from canonical registration or entry
  select e.entry_id, e.tournament_id
    into v_entry_id, v_tournament_id
    from public.tournament_entries e
   where e.registration_id = p_registration_id
     for update;

  if not found then
    select e.entry_id, e.tournament_id
      into v_entry_id, v_tournament_id
      from public.tournament_entries e
     where e.entry_id = p_registration_id
       for update;
  end if;

  if not found then
    raise exception 'Entry not found for registration %', p_registration_id using errcode = 'P0002';
  end if;

  -- 2. Authorization via canonical capability
  if not public.can('tournament', v_tournament_id, 'tournament.payment.manage') then
    raise exception 'Unauthorized to record tournament payments' using errcode = '42501';
  end if;

  -- 3. Calculate current non-voided total
  select coalesce(sum(amount), 0)
    into v_current_total
    from public.tournament_entry_payments
   where entry_id = v_entry_id
     and is_void = false;

  -- Non-decreasing monotonic cumulative payment check
  if p_amount_paid < v_current_total then
    raise exception 'New cumulative payment amount (%) cannot be less than current total (%). Use payment voiding to correct ledger.',
      p_amount_paid, v_current_total
      using errcode = '22000';
  end if;

  -- 4. Idempotency check: if delta is 0, cumulative total is already recorded
  v_delta := p_amount_paid - v_current_total;
  if v_delta = 0 then
    return;
  end if;

  -- 5. Append delta to immutable financial ledger
  insert into public.tournament_entry_payments (
    entry_id,
    tournament_id,
    amount,
    payment_channel,
    payment_reference,
    recorded_by,
    recorded_at
  ) values (
    v_entry_id,
    v_tournament_id,
    v_delta,
    coalesce(nullif(btrim(p_channel), ''), 'cash'),
    nullif(btrim(coalesce(p_reference, '')), ''),
    v_uid,
    now()
  );

  -- 6. Lock and update legacy projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  select coalesce(entry_fee, 0)
    into v_entry_fee
    from public.tournaments
   where tournament_id = v_tournament_id;

  if v_entry_fee = 0 then
    v_legacy_status := 'paid';
  elsif p_amount_paid >= v_entry_fee then
    v_legacy_status := 'paid';
  elsif p_amount_paid > 0 then
    v_legacy_status := 'partial';
  else
    v_legacy_status := 'unpaid';
  end if;

  update public.tournament_teams
     set amount_paid = p_amount_paid,
         payment_channel = p_channel,
         payment_reference = nullif(btrim(coalesce(p_reference, '')), ''),
         payment_recorded_at = now(),
         payment_recorded_by = v_uid,
         payment_status = v_legacy_status,
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.tournament_record_payment(uuid, numeric, text, text) from public;
grant execute on function public.tournament_record_payment(uuid, numeric, text, text) to authenticated;

-- ─── 8. Canonical void_tournament_entry_payment RPC ──────────────────────────
-- Corrective voiding: serializes on parent Entry lock, marks payment void, preserves audit,
-- and updates legacy projection.
create or replace function public.void_tournament_entry_payment(
  p_payment_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tournament_id uuid;
  v_entry_id uuid;
  v_registration_id uuid;
  v_is_void boolean;
  v_new_total numeric;
  v_entry_fee numeric;
  v_legacy_status text;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'Void reason is required' using errcode = '22023';
  end if;

  -- 1. Find payment and parent entry
  select p.entry_id, p.tournament_id, p.is_void, e.registration_id
    into v_entry_id, v_tournament_id, v_is_void, v_registration_id
    from public.tournament_entry_payments p
    join public.tournament_entries e on e.entry_id = p.entry_id
   where p.payment_id = p_payment_id;

  if not found then
    raise exception 'Payment not found' using errcode = 'P0002';
  end if;

  -- 2. Lock parent Entry row FOR UPDATE (serializes recording and voiding on one boundary)
  perform 1
     from public.tournament_entries
    where entry_id = v_entry_id
      for update;

  -- 3. Idempotency under Entry lock: check if already voided
  select is_void
    into v_is_void
    from public.tournament_entry_payments
   where payment_id = p_payment_id
     for update;

  if v_is_void then
    -- Already voided: return cleanly without rewriting original audit metadata
    return;
  end if;

  -- 4. Authorization via canonical capability
  if not public.can('tournament', v_tournament_id, 'tournament.payment.manage') then
    raise exception 'Unauthorized to void tournament payments' using errcode = '42501';
  end if;

  -- 5. Void payment
  update public.tournament_entry_payments
     set is_void = true,
         voided_by = v_uid,
         voided_at = now(),
         void_reason = btrim(p_reason),
         updated_at = now()
   where payment_id = p_payment_id;

  -- 6. Lock and update legacy projection
  select coalesce(sum(amount), 0)
    into v_new_total
    from public.tournament_entry_payments
   where entry_id = v_entry_id
     and is_void = false;

  select coalesce(entry_fee, 0)
    into v_entry_fee
    from public.tournaments
   where tournament_id = v_tournament_id;

  if v_entry_fee = 0 then
    v_legacy_status := 'paid';
  elsif v_new_total >= v_entry_fee then
    v_legacy_status := 'paid';
  elsif v_new_total > 0 then
    v_legacy_status := 'partial';
  else
    v_legacy_status := 'unpaid';
  end if;

  perform set_config('matchday.allow_legacy_projection', 'true', true);

  if v_registration_id is not null then
    update public.tournament_teams
       set amount_paid = v_new_total,
           payment_status = v_legacy_status,
           updated_at = now()
     where registration_id = v_registration_id;
  end if;
end;
$$;

revoke all on function public.void_tournament_entry_payment(uuid, text) from public;
grant execute on function public.void_tournament_entry_payment(uuid, text) to authenticated;

-- ─── 9. Legacy tournament_teams Write-Protection Trigger ─────────────────────
create or replace function public.enforce_tournament_teams_write_protection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Allow canonical projection triggers or migration backfill
  if current_setting('matchday.allow_legacy_projection', true) = 'true'
     or current_setting('matchday.migration_backfill', true) = 'true' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    raise exception 'Direct INSERT on tournament_teams is prohibited. Submit canonical tournament registration.'
      using errcode = '42501';
  end if;

  if tg_op = 'UPDATE' then
    -- Block any modification of migrated participation concerns
    if (
      new.status is distinct from old.status or
      new.squad is distinct from old.squad or
      new.amount_paid is distinct from old.amount_paid or
      new.payment_status is distinct from old.payment_status or
      new.payment_channel is distinct from old.payment_channel or
      new.payment_reference is distinct from old.payment_reference or
      new.payment_recorded_at is distinct from old.payment_recorded_at or
      new.payment_recorded_by is distinct from old.payment_recorded_by or
      new.message is distinct from old.message or
      new.decision_reason is distinct from old.decision_reason or
      new.decided_by is distinct from old.decided_by or
      new.decided_at is distinct from old.decided_at or
      new.registered_by is distinct from old.registered_by or
      new.registered_at is distinct from old.registered_at or
      new.tournament_id is distinct from old.tournament_id or
      new.team_id is distinct from old.team_id or
      new.registration_id is distinct from old.registration_id
    ) then
      raise exception 'Direct mutation of migrated participation fields on tournament_teams is prohibited. Use canonical APIs.'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_tournament_teams_write_protection() from public;

drop trigger if exists trg_tournament_teams_write_protection on public.tournament_teams;
create trigger trg_tournament_teams_write_protection
  before insert or update on public.tournament_teams
  for each row
  execute function public.enforce_tournament_teams_write_protection();

-- ─── 10. Backfill from legacy tournament_teams ───────────────────────────────
do $$
declare
  r record;
  v_entry_id uuid;
  v_player_id uuid;
begin
  -- Set backfill flag to bypass current-roster validation for historical squads
  perform set_config('matchday.migration_backfill', 'true', true);
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  for r in (select * from public.tournament_teams order by registered_at asc) loop
    if r.status = 'withdrawn' then
      if r.decided_at is not null then
        -- Post-approval withdrawal: registration was approved, then entry was withdrawn
        insert into public.tournament_registrations (
          registration_id, tournament_id, team_id, registered_by, registered_at,
          status, message, decision_reason, decided_by, decided_at,
          created_at, updated_at
        ) values (
          r.registration_id, r.tournament_id, r.team_id, r.registered_by, r.registered_at,
          'approved', r.message, r.decision_reason, r.decided_by, r.decided_at,
          r.created_at, r.updated_at
        ) on conflict (registration_id) do nothing;

        insert into public.tournament_entries (
          tournament_id, team_id, registration_id, status, entry_source,
          accepted_by, accepted_at, withdrawn_by, withdrawn_at, withdrawal_reason,
          created_at, updated_at
        ) values (
          r.tournament_id, r.team_id, r.registration_id, 'withdrawn', 'application',
          r.decided_by, r.decided_at, coalesce(r.registered_by, r.decided_by),
          coalesce(r.updated_at, r.decided_at, now()), 'Historical withdrawal after approval',
          r.created_at, r.updated_at
        )
        on conflict (tournament_id, team_id) where status = 'active'
        do nothing
        returning entry_id into v_entry_id;

      else
        -- Pre-approval withdrawal: withdrawn while still pending
        insert into public.tournament_registrations (
          registration_id, tournament_id, team_id, registered_by, registered_at,
          status, message, decision_reason, decided_by, decided_at,
          withdrawn_at, withdrawn_by, created_at, updated_at
        ) values (
          r.registration_id, r.tournament_id, r.team_id, r.registered_by, r.registered_at,
          'withdrawn', r.message, r.decision_reason, r.decided_by, r.decided_at,
          coalesce(r.updated_at, r.registered_at, now()), r.registered_by,
          r.created_at, r.updated_at
        ) on conflict (registration_id) do nothing;

        v_entry_id := null;
      end if;

    else
      -- Regular pending, approved, or rejected registration
      insert into public.tournament_registrations (
        registration_id, tournament_id, team_id, registered_by, registered_at,
        status, message, decision_reason, decided_by, decided_at,
        created_at, updated_at
      ) values (
        r.registration_id, r.tournament_id, r.team_id, r.registered_by, r.registered_at,
        r.status, r.message, r.decision_reason, r.decided_by, r.decided_at,
        r.created_at, r.updated_at
      ) on conflict (registration_id) do nothing;

      -- If approved, create active entry
      if r.status = 'approved' then
        insert into public.tournament_entries (
          tournament_id, team_id, registration_id, status, entry_source,
          accepted_by, accepted_at, created_at, updated_at
        ) values (
          r.tournament_id, r.team_id, r.registration_id, 'active', 'application',
          coalesce(r.decided_by, r.registered_by),
          coalesce(r.decided_at, r.registered_at),
          r.created_at, r.updated_at
        )
        on conflict (tournament_id, team_id) where status = 'active'
        do update set registration_id = excluded.registration_id
        returning entry_id into v_entry_id;
      else
        v_entry_id := null;
      end if;
    end if;

    -- Backfill Squad members if entry exists (preserves historical roster without today's team_members check)
    if v_entry_id is not null and r.squad is not null and array_length(r.squad, 1) > 0 then
      foreach v_player_id in array r.squad loop
        if exists (select 1 from public.profiles where user_id = v_player_id) then
          insert into public.tournament_squad_members (
            entry_id, tournament_id, user_id, membership_status, added_by, added_at
          ) values (
            v_entry_id, r.tournament_id, v_player_id, 'active',
            coalesce(r.decided_by, r.registered_by),
            coalesce(r.decided_at, r.registered_at)
          ) on conflict do nothing;
        elsif exists (select 1 from public.unclaimed_players where unclaimed_id = v_player_id) then
          insert into public.tournament_squad_members (
            entry_id, tournament_id, unclaimed_id, membership_status, added_by, added_at
          ) values (
            v_entry_id, r.tournament_id, v_player_id, 'active',
            coalesce(r.decided_by, r.registered_by),
            coalesce(r.decided_at, r.registered_at)
          ) on conflict do nothing;
        end if;
      end loop;
    end if;

    -- Backfill Payment history if amount_paid > 0
    if v_entry_id is not null and r.amount_paid is not null and r.amount_paid > 0 then
      insert into public.tournament_entry_payments (
        entry_id, tournament_id, amount, payment_channel, payment_reference,
        recorded_by, recorded_at
      ) values (
        v_entry_id, r.tournament_id, r.amount_paid,
        coalesce(r.payment_channel, 'cash'),
        r.payment_reference,
        coalesce(r.payment_recorded_by, r.decided_by, r.registered_by),
        coalesce(r.payment_recorded_at, r.decided_at, now())
      ) on conflict do nothing;
    end if;
  end loop;
end $$;

-- ─── 11. Canonical -> Legacy One-Way Projection Triggers ─────────────────────

create or replace function public.project_canonical_registration_to_legacy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  if tg_op = 'INSERT' then
    insert into public.tournament_teams (
      registration_id, tournament_id, team_id, registered_by, registered_at,
      status, message, decision_reason, decided_by, decided_at, created_at, updated_at
    ) values (
      new.registration_id, new.tournament_id, new.team_id, new.registered_by, new.registered_at,
      new.status, new.message, new.decision_reason, new.decided_by, new.decided_at, new.created_at, new.updated_at
    )
    on conflict (tournament_id, team_id) do update set
      registration_id = excluded.registration_id,
      registered_by = excluded.registered_by,
      registered_at = excluded.registered_at,
      status = excluded.status,
      message = excluded.message,
      decision_reason = excluded.decision_reason,
      decided_by = excluded.decided_by,
      decided_at = excluded.decided_at,
      updated_at = excluded.updated_at;
  elsif tg_op = 'UPDATE' then
    update public.tournament_teams
       set status = new.status,
           message = new.message,
           decision_reason = new.decision_reason,
           decided_by = new.decided_by,
           decided_at = new.decided_at,
           updated_at = new.updated_at
     where registration_id = new.registration_id;
  end if;
  return new;
end;
$$;

revoke all on function public.project_canonical_registration_to_legacy() from public;

drop trigger if exists trg_project_canonical_registration on public.tournament_registrations;
create trigger trg_project_canonical_registration
  after insert or update on public.tournament_registrations
  for each row
  execute function public.project_canonical_registration_to_legacy();

create or replace function public.project_canonical_entry_to_legacy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  if new.status = 'withdrawn' and (old.status is null or old.status != 'withdrawn') then
    update public.tournament_teams
       set status = 'withdrawn',
           updated_at = now()
     where registration_id = new.registration_id;
  end if;
  return new;
end;
$$;

revoke all on function public.project_canonical_entry_to_legacy() from public;

drop trigger if exists trg_project_canonical_entry on public.tournament_entries;
create trigger trg_project_canonical_entry
  after update on public.tournament_entries
  for each row
  execute function public.project_canonical_entry_to_legacy();

create or replace function public.project_canonical_squad_to_legacy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_entry_id uuid;
  v_reg_id uuid;
  v_squad uuid[];
begin
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  v_entry_id := coalesce(new.entry_id, old.entry_id);

  select registration_id into v_reg_id
    from public.tournament_entries
   where entry_id = v_entry_id;

  if v_reg_id is not null then
    -- Project only active squad members that have a non-null user_id into legacy uuid[]
    select coalesce(array_agg(user_id order by added_at), '{}'::uuid[])
      into v_squad
      from public.tournament_squad_members
     where entry_id = v_entry_id
       and membership_status = 'active'
       and user_id is not null;

    update public.tournament_teams
       set squad = v_squad,
           updated_at = now()
     where registration_id = v_reg_id;
  end if;
  return coalesce(new, old);
end;
$$;

revoke all on function public.project_canonical_squad_to_legacy() from public;

drop trigger if exists trg_project_canonical_squad on public.tournament_squad_members;
create trigger trg_project_canonical_squad
  after insert or update or delete on public.tournament_squad_members
  for each row
  execute function public.project_canonical_squad_to_legacy();

-- Ensure profile deletion strips user_id safely without failing on obsolete columns
create or replace function public._strip_deleted_profile_from_arrays()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Anonymize active tournament squad membership before profile is deleted
  update public.tournament_squad_members
     set membership_status = 'removed',
         removed_at = coalesce(removed_at, now()),
         removal_reason = coalesce(removal_reason, 'Profile deleted / anonymized'),
         updated_at = now()
   where user_id = old.user_id
     and membership_status = 'active';

  update public.tournaments
  set organizers = array_remove(organizers, old.user_id)
  where old.user_id = any (organizers);
  update public.tournament_teams
  set squad = array_remove(squad, old.user_id)
  where old.user_id = any (squad);
  update public.posts
  set linked_player_ids = array_remove(linked_player_ids, old.user_id)
  where old.user_id = any (linked_player_ids);
  update public.comments
  set mentioned_user_ids = array_remove(mentioned_user_ids, old.user_id)
  where old.user_id = any (mentioned_user_ids);
  return old;
end;
$$;
