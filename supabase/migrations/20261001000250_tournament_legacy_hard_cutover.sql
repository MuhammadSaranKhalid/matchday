-- =============================================================================
-- Migration: 20261001000250_tournament_legacy_hard_cutover.sql
-- Description: Phase 3.2 — Development Hard Cutover & Tournament Legacy Purge.
-- Drops public.tournament_teams, removes all projection machinery,
-- cleans organizers array and legacy stored status from tournaments,
-- and rewrites dependent runtime routines to canonical participation relations.
-- =============================================================================

-- ─── 1. Drop Dependent Views & Projection Triggers ────────────────────────────

drop view if exists public.tournament_public_participants cascade;

drop trigger if exists trg_project_canonical_registration on public.tournament_registrations;
drop function if exists public.project_canonical_registration_to_legacy();

drop trigger if exists trg_project_canonical_entry on public.tournament_entries;
drop function if exists public.project_canonical_entry_to_legacy();

drop trigger if exists trg_project_canonical_squad on public.tournament_squad_members;
drop function if exists public.project_canonical_squad_to_legacy();

do $$
begin
  if to_regclass('public.tournament_teams') is not null then
    execute 'drop trigger if exists trg_tournament_teams_write_protection on public.tournament_teams';
    execute 'drop trigger if exists trg_sync_tournament_team_chat on public.tournament_teams';
  end if;
end
$$;

drop function if exists public.enforce_tournament_teams_write_protection();

-- ─── 2. Canonical Public Participants Read RPC ────────────────────────────────
-- Dedicated safe read surface deriving strictly from tournament_entries + teams.
-- Exposes zero internal registration messages, notes, payments, or actor IDs.

create or replace function public.get_tournament_public_participants(
  p_tournament_id uuid
)
returns table (
  entry_id uuid,
  tournament_id uuid,
  team_id uuid,
  team_name text,
  logo_url text,
  logo_monogram text,
  team_colors jsonb,
  status text,
  accepted_at timestamptz
)
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
begin
  -- Validate tournament visibility
  if not exists (
    select 1
    from public.tournaments t
    where t.tournament_id = p_tournament_id
      and (
        t.privacy = 'public'
        or (
          auth.uid() is not null
          and (
            t.owner_user_id = auth.uid()
            or exists (
              select 1
              from public.tournament_memberships tm
              where tm.tournament_id = p_tournament_id
                and tm.user_id = auth.uid()
                and tm.status = 'active'
            )
          )
        )
      )
  ) then
    return;
  end if;

  return query
  select
    te.entry_id,
    te.tournament_id,
    te.team_id,
    tm.team_name,
    tm.logo_url,
    tm.logo_monogram,
    tm.team_colors,
    te.status::text as status,
    te.accepted_at
  from public.tournament_entries te
  join public.teams tm on tm.team_id = te.team_id
  where te.tournament_id = p_tournament_id
    and te.status = 'active'
  order by tm.team_name asc;
end;
$$;

revoke all on function public.get_tournament_public_participants(uuid) from public;
grant execute on function public.get_tournament_public_participants(uuid) to anon, authenticated;

-- ─── 3. Canonical Entry Chat Synchronization Trigger ──────────────────────────
-- Automatically synchronizes active participating team members into tournament chat.

create or replace function public.sync_tournament_entry_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_member record;
begin
  if new.status <> 'active' then
    return new;
  end if;

  select channel_id
    into v_channel_id
  from public.chat_channels
  where tournament_id = new.tournament_id
    and context_type = 'tournament'
    and purpose = 'main'
  limit 1;

  if v_channel_id is null then
    return new;
  end if;

  for v_member in
    select user_id
    from public.team_members
    where team_id = new.team_id
      and status = 'active'
      and user_id is not null
  loop
    insert into public.channel_members (channel_id, user_id, role, status, joined_at)
    values (v_channel_id, v_member.user_id, 'member', 'active', clock_timestamp())
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = clock_timestamp();
  end loop;

  return new;
end;
$$;

drop trigger if exists trg_sync_tournament_entry_chat on public.tournament_entries;
create trigger trg_sync_tournament_entry_chat
  after insert or update on public.tournament_entries
  for each row
  execute function public.sync_tournament_entry_chat();

-- ─── 4. Redefine Canonical Participation RPCs (No Legacy Projections) ──────────

-- 4.1 submit_tournament_registration
create or replace function public.submit_tournament_registration(
  p_tournament_id uuid,
  p_team_id uuid,
  p_message text default null,
  p_squad_proposals jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_tourn record;
  v_team record;
  v_reg_id uuid;
  v_prop jsonb;
  v_user_id uuid;
  v_unclaimed_id uuid;
  v_is_captain boolean;
  v_jersey_number text;
  v_role_title text;
  v_person_key text;
  v_seen_keys text[] := '{}'::text[];
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- 1. Authorization: Caller must have authority to enter the team in tournaments
  if not (
    public.can('team', p_team_id, 'team.tournament.enter')
    or public.is_team_manager(p_team_id)
  ) then
    raise exception 'Unauthorized to enter team in tournaments' using errcode = '42501';
  end if;

  -- 2. Validate Tournament Lifecycle State
  select *
    into v_tourn
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  if v_tourn.publication_state != 'published' then
    raise exception 'Tournament is not published' using errcode = '22000';
  end if;

  if v_tourn.registration_state != 'open' then
    raise exception 'Tournament registration is not open (current state: %)', v_tourn.registration_state
      using errcode = '22000';
  end if;

  if v_tourn.registration_deadline is not null and now() > v_tourn.registration_deadline then
    raise exception 'Tournament registration deadline has passed' using errcode = '22000';
  end if;

  -- 3. Validate Team Status
  select *
    into v_team
    from public.teams
   where team_id = p_team_id;

  if not found or v_team.status != 'active' then
    raise exception 'Team is not active' using errcode = '22000';
  end if;

  -- 4. Check for Existing Active Registration or Active Entry
  if exists (
    select 1
      from public.tournament_registrations
     where tournament_id = p_tournament_id
       and team_id = p_team_id
       and status in ('pending', 'approved')
  ) then
    raise exception 'Team already has a pending or approved registration for this tournament'
      using errcode = '23505';
  end if;

  if exists (
    select 1
      from public.tournament_entries
     where tournament_id = p_tournament_id
       and team_id = p_team_id
       and status = 'active'
  ) then
    raise exception 'Team already has an active entry in this tournament'
      using errcode = '23505';
  end if;

  -- 5. Insert Canonical Registration Application
  insert into public.tournament_registrations (
    tournament_id,
    team_id,
    registered_by,
    registered_at,
    status,
    message
  ) values (
    p_tournament_id,
    p_team_id,
    v_uid,
    now(),
    'pending',
    nullif(btrim(coalesce(p_message, '')), '')
  ) returning registration_id into v_reg_id;

  -- 6. Insert Squad Proposals
  if p_squad_proposals is not null and jsonb_typeof(p_squad_proposals) = 'array' then
    for v_prop in select * from jsonb_array_elements(p_squad_proposals) loop
      v_user_id := null;
      v_unclaimed_id := null;

      if (v_prop->>'user_id') is not null and btrim(v_prop->>'user_id') != '' then
        v_user_id := (v_prop->>'user_id')::uuid;
        v_person_key := 'u:' || v_user_id::text;
      elsif (v_prop->>'unclaimed_id') is not null and btrim(v_prop->>'unclaimed_id') != '' then
        v_unclaimed_id := (v_prop->>'unclaimed_id')::uuid;
        v_person_key := 'p:' || v_unclaimed_id::text;
      else
        raise exception 'Proposed player must specify user_id or unclaimed_id' using errcode = '22023';
      end if;

      if v_person_key = any(v_seen_keys) then
        raise exception 'Duplicate player proposal in registration payload' using errcode = '23505';
      end if;
      v_seen_keys := array_append(v_seen_keys, v_person_key);

      v_is_captain := coalesce((v_prop->>'is_captain')::boolean, false);
      v_jersey_number := nullif(btrim(coalesce(v_prop->>'jersey_number', '')), '');
      v_role_title := nullif(btrim(coalesce(v_prop->>'role_title', '')), '');

      insert into public.tournament_registration_squad_members (
        registration_id,
        user_id,
        unclaimed_id,
        is_captain,
        jersey_number,
        role_title
      ) values (
        v_reg_id,
        v_user_id,
        v_unclaimed_id,
        v_is_captain,
        v_jersey_number,
        v_role_title
      );
    end loop;
  end if;

  return v_reg_id;
end;
$$;

-- 4.2 approve_tournament_registration
drop function if exists public.approve_tournament_registration(uuid);
create or replace function public.approve_tournament_registration(
  p_registration_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_reg record;
  v_tourn record;
  v_active_entries integer;
  v_entry_id uuid;
  v_prop record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- 1. Fetch Registration with row-level lock
  select *
    into v_reg
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization: Tournament entries management authority
  if not (
    public.can('tournament', v_reg.tournament_id, 'tournament.entries.manage')
    or public.is_tournament_organizer(v_reg.tournament_id)
  ) then
    raise exception 'Unauthorized to approve tournament registrations' using errcode = '42501';
  end if;

  -- 3. Precondition: Can only approve pending applications
  if v_reg.status != 'pending' then
    if v_reg.status = 'approved' then
      select entry_id into v_entry_id
        from public.tournament_entries
       where registration_id = p_registration_id
         and status = 'active';
      return v_entry_id;
    end if;
    raise exception 'Registration application is not in pending status (current status: %)', v_reg.status
      using errcode = '22000';
  end if;

  -- 4. Lock Tournament and check capacity concurrency
  select *
    into v_tourn
    from public.tournaments
   where tournament_id = v_reg.tournament_id
     for update;

  if v_tourn.max_teams is not null then
    select count(*)
      into v_active_entries
      from public.tournament_entries
     where tournament_id = v_reg.tournament_id
       and status = 'active';

    if v_active_entries >= v_tourn.max_teams then
      raise exception 'Tournament maximum team capacity reached (% teams)', v_tourn.max_teams
        using errcode = '22000';
    end if;
  end if;

  -- 5. Update Registration to Approved
  update public.tournament_registrations
     set status = 'approved',
         decided_at = now(),
         decided_by = v_uid,
         decision_reason = null,
         updated_at = now()
   where registration_id = p_registration_id;

  -- 6. Materialize Canonical Tournament Entry
  insert into public.tournament_entries (
    tournament_id,
    team_id,
    registration_id,
    status,
    entry_source,
    squad_state,
    accepted_at,
    accepted_by
  ) values (
    v_reg.tournament_id,
    v_reg.team_id,
    p_registration_id,
    'active',
    'application',
    'editable',
    now(),
    v_uid
  ) returning entry_id into v_entry_id;

  -- 7. Materialize Proposed Squad Members into Tournament Squad
  for v_prop in
    select *
      from public.tournament_registration_squad_members
     where registration_id = p_registration_id
  loop
    insert into public.tournament_squad_members (
      entry_id,
      tournament_id,
      user_id,
      unclaimed_id,
      membership_status,
      is_captain,
      jersey_number,
      role_title,
      added_by,
      added_at
    ) values (
      v_entry_id,
      v_reg.tournament_id,
      v_prop.user_id,
      v_prop.unclaimed_id,
      'active',
      v_prop.is_captain,
      v_prop.jersey_number,
      v_prop.role_title,
      v_uid,
      now()
    ) on conflict do nothing;
  end loop;

  return v_entry_id;
end;
$$;

-- 4.3 reject_tournament_registration
drop function if exists public.reject_tournament_registration(uuid);
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
  v_reg record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- 1. Fetch Registration with row-level lock
  select *
    into v_reg
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization
  if not (
    public.can('tournament', v_reg.tournament_id, 'tournament.entries.manage')
    or public.is_tournament_organizer(v_reg.tournament_id)
  ) then
    raise exception 'Unauthorized to reject tournament registrations' using errcode = '42501';
  end if;

  -- 3. Precondition: Can only reject pending applications
  if v_reg.status != 'pending' then
    if v_reg.status = 'rejected' then
      return;
    end if;
    raise exception 'Registration application is not pending (status: %)', v_reg.status
      using errcode = '22000';
  end if;

  -- 4. Update Registration
  update public.tournament_registrations
     set status = 'rejected',
         decided_at = now(),
         decided_by = v_uid,
         decision_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

-- 4.4 withdraw_tournament_pending_registration
create or replace function public.withdraw_tournament_pending_registration(
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
  v_reg record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select *
    into v_reg
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- Authorization
  if not (
    public.can('team', v_reg.team_id, 'team.tournament.enter')
    or public.is_team_manager(v_reg.team_id)
  ) then
    raise exception 'Unauthorized to withdraw team registration' using errcode = '42501';
  end if;

  -- Precondition
  if v_reg.status != 'pending' then
    if v_reg.status = 'withdrawn' then
      return;
    end if;
    raise exception 'Cannot withdraw registration: application is not pending (status: %)', v_reg.status
      using errcode = '22000';
  end if;

  update public.tournament_registrations
     set status = 'withdrawn',
         withdrawn_at = now(),
         withdrawn_by = v_uid,
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

-- 4.5 withdraw_tournament_entry
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
  v_entry record;
  v_tourn record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select *
    into v_entry
    from public.tournament_entries
   where entry_id = p_entry_id
     for update;

  if not found then
    raise exception 'Tournament entry not found' using errcode = 'P0002';
  end if;

  -- Authorization: Team manager or Tournament manager
  if not (
    public.can('team', v_entry.team_id, 'team.tournament.enter')
    or public.is_team_manager(v_entry.team_id)
    or public.can('tournament', v_entry.tournament_id, 'tournament.entries.manage')
    or public.is_tournament_organizer(v_entry.tournament_id)
  ) then
    raise exception 'Unauthorized to withdraw tournament entry' using errcode = '42501';
  end if;

  -- Precondition: Competition must not have started
  select *
    into v_tourn
    from public.tournaments
   where tournament_id = v_entry.tournament_id;

  if v_tourn.competition_state in ('in_progress', 'completed') then
    raise exception 'Cannot withdraw entry after competition has commenced' using errcode = '22000';
  end if;

  if v_entry.status = 'withdrawn' then
    return;
  end if;

  -- Update Entry to withdrawn
  update public.tournament_entries
     set status = 'withdrawn',
         withdrawn_at = now(),
         withdrawn_by = v_uid,
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where entry_id = p_entry_id;
end;
$$;

-- 4.6 record_tournament_entry_payment
create or replace function public.record_tournament_entry_payment(
  p_entry_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_reference text default null,
  p_notes text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_entry record;
  v_payment_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero' using errcode = '22023';
  end if;

  -- 1. Idempotency Check
  if p_idempotency_key is not null and btrim(p_idempotency_key) != '' then
    select payment_id
      into v_payment_id
      from public.tournament_entry_payments
     where idempotency_key = btrim(p_idempotency_key);

    if found then
      return v_payment_id;
    end if;
  end if;

  -- 2. Fetch Entry
  select *
    into v_entry
    from public.tournament_entries
   where entry_id = p_entry_id
     for update;

  if not found then
    raise exception 'Tournament entry not found' using errcode = 'P0002';
  end if;

  -- 3. Authorization: Finance management authority
  if not (
    public.can('tournament', v_entry.tournament_id, 'tournament.finance.manage')
    or public.is_tournament_organizer(v_entry.tournament_id)
  ) then
    raise exception 'Unauthorized to record tournament payments' using errcode = '42501';
  end if;

  -- 4. Insert Canonical Ledger Record
  insert into public.tournament_entry_payments (
    entry_id,
    tournament_id,
    amount,
    payment_channel,
    payment_reference,
    notes,
    recorded_by,
    recorded_at
  ) values (
    p_entry_id,
    v_entry.tournament_id,
    p_amount,
    coalesce(nullif(btrim(p_payment_method), ''), 'cash'),
    nullif(btrim(coalesce(p_reference, '')), ''),
    nullif(btrim(coalesce(p_notes, '')), ''),
    v_uid,
    now()
  ) returning payment_id into v_payment_id;

  return v_payment_id;
end;
$$;

-- 4.7 void_tournament_entry_payment
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
  v_pay record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Void reason is required' using errcode = '22023';
  end if;

  -- 1. Fetch Payment with lock
  select *
    into v_pay
    from public.tournament_entry_payments
   where payment_id = p_payment_id
     for update;

  if not found then
    raise exception 'Payment record not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization
  if not (
    public.can('tournament', v_pay.tournament_id, 'tournament.finance.manage')
    or public.is_tournament_organizer(v_pay.tournament_id)
  ) then
    raise exception 'Unauthorized to void tournament payments' using errcode = '42501';
  end if;

  -- 3. Precondition: Check void state
  if v_pay.is_void then
    return;
  end if;

  -- 4. Mark Payment as Voided
  update public.tournament_entry_payments
     set is_void = true,
         voided_at = now(),
         voided_by = v_uid,
         void_reason = btrim(p_reason),
         updated_at = now()
   where payment_id = p_payment_id;
end;
$$;

-- 4.8 add_tournament_squad_member
create or replace function public.add_tournament_squad_member(
  p_entry_id uuid,
  p_user_id uuid default null,
  p_unclaimed_id uuid default null,
  p_is_captain boolean default false,
  p_jersey_number text default null,
  p_role_title text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_entry record;
  v_tourn record;
  v_member_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if (p_user_id is null and p_unclaimed_id is null) or
     (p_user_id is not null and p_unclaimed_id is not null) then
    raise exception 'Must specify exactly one of user_id or unclaimed_id' using errcode = '22023';
  end if;

  select *
    into v_entry
    from public.tournament_entries
   where entry_id = p_entry_id
     for update;

  if not found then
    raise exception 'Tournament entry not found' using errcode = 'P0002';
  end if;

  -- Authorization
  if not (
    public.can('team', v_entry.team_id, 'team.roster.manage')
    or public.is_team_manager(v_entry.team_id)
    or public.can('tournament', v_entry.tournament_id, 'tournament.entries.manage')
    or public.is_tournament_organizer(v_entry.tournament_id)
  ) then
    raise exception 'Unauthorized to modify tournament squad' using errcode = '42501';
  end if;

  -- Freeze check
  select *
    into v_tourn
    from public.tournaments
   where tournament_id = v_entry.tournament_id;

  if v_tourn.entry_state = 'locked' or v_entry.squad_state = 'locked' then
    raise exception 'Tournament squad is locked and cannot be modified' using errcode = '22000';
  end if;

  -- Insert or reactivate member
  insert into public.tournament_squad_members (
    entry_id,
    tournament_id,
    user_id,
    unclaimed_id,
    membership_status,
    is_captain,
    jersey_number,
    role_title,
    added_by,
    added_at,
    removed_at,
    removal_reason
  ) values (
    p_entry_id,
    v_entry.tournament_id,
    p_user_id,
    p_unclaimed_id,
    'active',
    coalesce(p_is_captain, false),
    nullif(btrim(coalesce(p_jersey_number, '')), ''),
    nullif(btrim(coalesce(p_role_title, '')), ''),
    v_uid,
    now(),
    null,
    null
  ) on conflict (entry_id, coalesce(user_id, '00000000-0000-0000-0000-000000000000'::uuid), coalesce(unclaimed_id, '00000000-0000-0000-0000-000000000000'::uuid))
  do update set
    membership_status = 'active',
    is_captain = coalesce(excluded.is_captain, tournament_squad_members.is_captain),
    jersey_number = coalesce(excluded.jersey_number, tournament_squad_members.jersey_number),
    role_title = coalesce(excluded.role_title, tournament_squad_members.role_title),
    removed_at = null,
    removal_reason = null,
    updated_at = now()
  returning squad_member_id into v_member_id;

  return v_member_id;
end;
$$;

-- 4.9 remove_tournament_squad_member
create or replace function public.remove_tournament_squad_member(
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
  v_sqm record;
  v_entry record;
  v_tourn record;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select *
    into v_sqm
    from public.tournament_squad_members
   where squad_member_id = p_squad_member_id
     for update;

  if not found then
    raise exception 'Squad member not found' using errcode = 'P0002';
  end if;

  select *
    into v_entry
    from public.tournament_entries
   where entry_id = v_sqm.entry_id
     for update;

  -- Authorization
  if not (
    public.can('team', v_entry.team_id, 'team.roster.manage')
    or public.is_team_manager(v_entry.team_id)
    or public.can('tournament', v_entry.tournament_id, 'tournament.entries.manage')
    or public.is_tournament_organizer(v_entry.tournament_id)
  ) then
    raise exception 'Unauthorized to modify tournament squad' using errcode = '42501';
  end if;

  -- Freeze check
  select *
    into v_tourn
    from public.tournaments
   where tournament_id = v_entry.tournament_id;

  if v_tourn.entry_state = 'locked' or v_entry.squad_state = 'locked' then
    raise exception 'Tournament squad is locked and cannot be modified' using errcode = '22000';
  end if;

  -- Soft delete / record removal
  update public.tournament_squad_members
     set membership_status = 'removed',
         removed_at = now(),
         removed_by = v_uid,
         removal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where squad_member_id = p_squad_member_id;
end;
$$;

-- 4.10 Drop transitional registration withdrawal aliases
drop function if exists public.withdraw_tournament_registration(uuid, text);
drop function if exists public.withdraw_tournament_registration(uuid);

-- ─── 5. Rewrite Match Runtime Roster Snapshots (Canonical Squad) ───────────────

create or replace function public.sync_match_participants(
  p_match_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches%rowtype;
  v_cricket public.cricket_matches%rowtype;
  v_side text;
  v_team_id uuid;
begin
  select m.*
    into v_match
    from public.matches m
   where m.match_id = p_match_id
   for update;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  select cm.*
    into v_cricket
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;

  -- Match slots are created before the sport extension. The cricket insert
  -- trigger calls this function again once the extension exists.
  if not found then
    return;
  end if;

  if v_cricket.roster_frozen_at is not null then
    return;
  end if;

  foreach v_side in array array['team_a', 'team_b'] loop
    select mt.team_id
      into v_team_id
      from public.match_teams mt
     where mt.match_id = p_match_id
       and mt.team_side = v_side;

    if v_team_id is null then
      delete from public.match_players mp
       where mp.match_id = p_match_id
         and mp.team_side = v_side
         and mp.source <> 'match_added';
      continue;
    end if;

    -- Non-tournament match path
    if v_match.tournament_id is null then
      update public.match_players mp
      set display_name = coalesce(pr.display_name, up.display_name, mp.display_name),
          jersey_number = tm.jersey_number,
          source = 'team_snapshot'::public.match_player_source
      from public.team_members tm
      left join public.profiles pr on pr.user_id = tm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
      where mp.match_id = p_match_id
        and mp.team_side = v_side
        and mp.source <> 'match_added'
        and tm.team_id = v_team_id
        and tm.status = 'active'
        and tm.in_squad
        and mp.user_id is not distinct from tm.user_id
        and mp.unclaimed_id is not distinct from tm.unclaimed_id;

      insert into public.match_players (
        match_id, team_side, user_id, unclaimed_id, display_name,
        jersey_number, source, added_by
      )
      select
        p_match_id,
        v_side,
        tm.user_id,
        tm.unclaimed_id,
        coalesce(pr.display_name, up.display_name, 'Player'),
        tm.jersey_number,
        'team_snapshot'::public.match_player_source,
        auth.uid()
      from public.team_members tm
      left join public.profiles pr on pr.user_id = tm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
      where tm.team_id = v_team_id
        and tm.status = 'active'
        and tm.in_squad
      on conflict do nothing;
    else
      -- Tournament match path: read canonical tournament_squad_members
      update public.match_players mp
      set display_name = coalesce(pr.display_name, up.display_name, mp.display_name),
          jersey_number = tm.jersey_number,
          source = 'tournament_squad'::public.match_player_source
      from public.tournament_entries te
      join public.tournament_squad_members tsm on tsm.entry_id = te.entry_id and tsm.membership_status = 'active'
      left join public.profiles pr on pr.user_id = tsm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tsm.unclaimed_id
      left join public.team_members tm
        on tm.team_id = v_team_id
       and ((tsm.user_id is not null and tm.user_id = tsm.user_id)
            or (tsm.unclaimed_id is not null and tm.unclaimed_id = tsm.unclaimed_id))
      where te.tournament_id = v_match.tournament_id
        and te.team_id = v_team_id
        and te.status = 'active'
        and mp.match_id = p_match_id
        and mp.team_side = v_side
        and mp.source <> 'match_added'
        and (
          (tsm.user_id is not null and mp.user_id = tsm.user_id)
          or (tsm.unclaimed_id is not null and mp.unclaimed_id = tsm.unclaimed_id)
        );

      insert into public.match_players (
        match_id, team_side, user_id, unclaimed_id, display_name,
        jersey_number, source, added_by
      )
      select
        p_match_id,
        v_side,
        tsm.user_id,
        tsm.unclaimed_id,
        coalesce(pr.display_name, up.display_name, 'Player'),
        tm.jersey_number,
        'tournament_squad'::public.match_player_source,
        auth.uid()
      from public.tournament_entries te
      join public.tournament_squad_members tsm on tsm.entry_id = te.entry_id and tsm.membership_status = 'active'
      left join public.profiles pr on pr.user_id = tsm.user_id
      left join public.unclaimed_players up on up.unclaimed_id = tsm.unclaimed_id
      left join public.team_members tm
        on tm.team_id = v_team_id
       and ((tsm.user_id is not null and tm.user_id = tsm.user_id)
            or (tsm.unclaimed_id is not null and tm.unclaimed_id = tsm.unclaimed_id))
      where te.tournament_id = v_match.tournament_id
        and te.team_id = v_team_id
        and te.status = 'active'
        and (tsm.user_id is not null or tsm.unclaimed_id is not null)
      on conflict do nothing;
    end if;

    -- Cricket match player captain assignment (guarded by cricket_matches existence)
    if exists (select 1 from public.cricket_matches cm where cm.match_id = p_match_id) then
      insert into public.cricket_match_players (match_player_id, match_id, is_captain)
      select
        mp.match_player_id,
        mp.match_id,
        coalesce(mp.user_id = public._team_current_captain(v_team_id), false)
      from public.match_players mp
      where mp.match_id = p_match_id
        and mp.team_side = v_side
      on conflict (match_player_id) do nothing;
    end if;

    -- Before freeze, remove obsolete automatic snapshots not referenced by historical cricket events
    delete from public.match_players mp
    where mp.match_id = p_match_id
      and mp.team_side = v_side
      and mp.source <> 'match_added'
      and not exists (
        select 1
        from public.team_members tm
        where tm.team_id = v_team_id
          and tm.status = 'active'
          and tm.in_squad
          and tm.user_id is not distinct from mp.user_id
          and tm.unclaimed_id is not distinct from mp.unclaimed_id
          and (
            v_match.tournament_id is null
            or exists (
              select 1
              from public.tournament_entries te
              join public.tournament_squad_members tsm on tsm.entry_id = te.entry_id and tsm.membership_status = 'active'
              where te.tournament_id = v_match.tournament_id
                and te.team_id = v_team_id
                and te.status = 'active'
                and (
                  (tsm.user_id is not null and tm.user_id = tsm.user_id)
                  or (tsm.unclaimed_id is not null and tm.unclaimed_id = tsm.unclaimed_id)
                )
            )
          )
      )
      and not exists (
        select 1 from public.cricket_match_innings_state s
        where mp.match_player_id in (s.striker_id, s.non_striker_id, s.bowler_id)
      )
      and not exists (
        select 1 from public.cricket_match_deliveries d
        where mp.match_player_id in (d.striker_id, d.non_striker_id, d.bowler_id, d.fielder_id)
      )
      and not exists (
        select 1 from public.cricket_match_wickets w
        where mp.match_player_id in (
          w.player_out_id,
          w.credited_bowler_id,
          w.primary_fielder_id,
          w.assisted_fielder_id
        )
      )
      and not exists (
        select 1 from public.cricket_matches cm
        where cm.player_of_the_match_id = mp.match_player_id
      );
  end loop;
end;
$$;

create or replace function public.sync_match_roster_snapshot(
  p_match_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.sync_match_participants(p_match_id);
end;
$$;

create or replace function public._materialize_match_team_side(
  p_match_id uuid,
  p_team_side text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.sync_match_participants(p_match_id);
end;
$$;

-- ─── 6. Rewrite Tournament Operations (Fee Ledger & Official Candidates) ──────

-- 6.1 Drop obsolete legacy fee & fixture functions
drop function if exists public.tournament_record_payment(uuid, numeric, text, text);
drop function if exists public.tournament_generate_fixtures(uuid, jsonb, uuid[]);

-- 6.2 tournament_fee_ledger
create or replace function public.tournament_fee_ledger(
  p_tournament_id uuid
)
returns table (
  registration_id uuid,
  team_id uuid,
  team_name text,
  team_monogram text,
  team_logo_url text,
  entry_fee numeric,
  amount_paid numeric,
  payment_channel text,
  payment_reference text,
  payment_recorded_at timestamptz,
  recorded_by_name text,
  status text
)
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not (
    public.can('tournament', p_tournament_id, 'tournament.finance.view')
    or public.is_tournament_organizer(p_tournament_id)
  ) then
    raise exception 'Only tournament organizers can view fee ledger' using errcode = '42501';
  end if;

  return query
  with entry_payments as (
    select
      p.entry_id,
      sum(p.amount) filter (where not p.is_void) as total_paid
    from public.tournament_entry_payments p
    where p.tournament_id = p_tournament_id
    group by p.entry_id
  ),
  latest_payments as (
    select distinct on (p.entry_id)
      p.entry_id,
      p.payment_channel,
      p.payment_reference,
      p.recorded_at,
      pr.display_name as recorder_name
    from public.tournament_entry_payments p
    left join public.profiles pr on pr.user_id = p.recorded_by
    where p.tournament_id = p_tournament_id
      and not p.is_void
    order by p.entry_id, p.recorded_at desc
  )
  select
    coalesce(te.registration_id, te.entry_id) as registration_id,
    te.team_id,
    tm.team_name,
    tm.logo_monogram,
    tm.logo_url as team_logo_url,
    coalesce(t.entry_fee, 0) as entry_fee,
    coalesce(ep.total_paid, 0)::numeric as amount_paid,
    lp.payment_channel as payment_channel,
    lp.payment_reference as payment_reference,
    lp.recorded_at as payment_recorded_at,
    lp.recorder_name as recorded_by_name,
    te.status::text as status
  from public.tournament_entries te
  join public.tournaments t on t.tournament_id = te.tournament_id
  join public.teams tm on tm.team_id = te.team_id
  left join entry_payments ep on ep.entry_id = te.entry_id
  left join latest_payments lp on lp.entry_id = te.entry_id
  where te.tournament_id = p_tournament_id
    and te.status = 'active'
  order by tm.team_name;
end;
$$;

revoke all on function public.tournament_fee_ledger(uuid) from public;
grant execute on function public.tournament_fee_ledger(uuid) to authenticated;

-- 6.3 tournament_official_candidates
create or replace function public.tournament_official_candidates(
  p_tournament_id uuid,
  p_match_id uuid
)
returns table (
  user_id uuid,
  display_name text,
  username text,
  avatar_url text,
  club_name text,
  is_neutral boolean,
  matches_officiated integer,
  busy_on text
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with
    target as (
      select
        m.match_id,
        m.scheduled_start_time
      from public.matches m
      where m.match_id = p_match_id
    ),
    people as (
      -- Tournament owner
      select t.owner_user_id as uid
      from public.tournaments t
      where t.tournament_id = p_tournament_id and t.owner_user_id is not null
      union
      -- Normalized tournament managers / staff
      select tm.user_id as uid
      from public.tournament_memberships tm
      where tm.tournament_id = p_tournament_id and tm.status = 'active' and tm.user_id is not null
      union
      -- Participating team staff from active canonical entries
      select public.team_staff_ids(te.team_id) as uid
      from public.tournament_entries te
      where te.tournament_id = p_tournament_id and te.status = 'active'
    )
  select distinct on (pr.user_id)
    pr.user_id,
    pr.display_name,
    pr.username,
    pr.profile_photo_url as avatar_url,
    (
      select t.team_name
      from public.teams t
      where public._user_team_can(pr.user_id, t.team_id, 'team.roster.write')
      order by t.created_at
      limit 1
    ) as club_name,
    not exists (
      select 1
      from public.match_teams ms
      where ms.match_id = p_match_id
        and ms.team_id is not null
        and public._user_team_can(pr.user_id, ms.team_id, 'team.roster.write')
    ) as is_neutral,
    (
      select count(*)::integer
      from public.match_officials mo2
      where mo2.user_id = pr.user_id and mo2.role <> 'scorer'
    ) as matches_officiated,
    (
      select coalesce(m2.round, 'another match')
      from public.match_officials mo3
      join public.matches m2 on m2.match_id = mo3.match_id,
      target tg
      where mo3.user_id = pr.user_id
        and m2.match_id <> tg.match_id
        and m2.scheduled_start_time between tg.scheduled_start_time - interval '4 hours' and tg.scheduled_start_time + interval '4 hours'
      limit 1
    ) as busy_on
  from people p
  join public.profiles pr on pr.user_id = p.uid
  where p.uid is not null
    and (
      public.can('tournament', p_tournament_id, 'tournament.officials.manage')
      or public.is_tournament_organizer(p_tournament_id)
    )
  order by pr.user_id, pr.display_name;
$$;

revoke all on function public.tournament_official_candidates(uuid, uuid) from public;
grant execute on function public.tournament_official_candidates(uuid, uuid) to authenticated;

-- ─── 7. Clean Profile Deletion Cascade ────────────────────────────────────────

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

  update public.posts
     set linked_player_ids = array_remove(linked_player_ids, old.user_id)
   where old.user_id = any (linked_player_ids);

  update public.comments
     set mentioned_user_ids = array_remove(mentioned_user_ids, old.user_id)
   where old.user_id = any (mentioned_user_ids);

  return old;
end;
$$;

create or replace function public.handle_profile_cascade_user_deletion()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public._strip_deleted_profile_from_arrays();
  return old;
end;
$$;

-- ─── 8. Drop Table public.tournament_teams ───────────────────────────────────

drop table if exists public.tournament_teams cascade;

-- ─── 9. Remove organizers Array & Compatibility Projection ────────────────────

drop trigger if exists tournament_memberships_sync_organizers_projection on public.tournament_memberships;
drop function if exists public.project_tournament_memberships_to_organizers();

-- Recreate tournament RLS policies without organizers column
drop policy if exists "tournaments_read_visible" on public.tournaments;
drop policy if exists "tournaments_read" on public.tournaments;
create policy "tournaments_read_visible"
  on public.tournaments
  for select
  using (
    privacy = 'public'
    or (select auth.uid()) is not null
    and (
      owner_user_id = (select auth.uid())
      or exists (
        select 1
        from public.tournament_memberships tm
        where tm.tournament_id = tournaments.tournament_id
          and tm.user_id = (select auth.uid())
          and tm.status = 'active'
      )
    )
  );

drop policy if exists "tournaments_update_organizers" on public.tournaments;
create policy "tournaments_update_organizers"
  on public.tournaments
  for update
  using (
    owner_user_id = (select auth.uid())
    or public.can('tournament', tournament_id, 'tournament.edit')
    or (owner_user_id is null and (select auth.uid()) = created_by)
  )
  with check (
    owner_user_id = (select auth.uid())
    or public.can('tournament', tournament_id, 'tournament.edit')
    or (owner_user_id is null and (select auth.uid()) = created_by)
  );

drop policy if exists "tournaments_delete_creator" on public.tournaments;
create policy "tournaments_delete_creator"
  on public.tournaments
  for delete
  using (
    owner_user_id = (select auth.uid())
    or (owner_user_id is null and (select auth.uid()) = created_by)
  );

drop index if exists public.tournaments_organizers_gin;
alter table public.tournaments drop column if exists organizers;

-- ─── 10. Streamline is_tournament_organizer & is_tournament_admin ─────────────

create or replace function public.is_tournament_organizer(
  p_tournament_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = p_tournament_id
        and t.owner_user_id = auth.uid()
    )
    or exists (
      select 1
      from public.tournament_memberships tm
      where tm.tournament_id = p_tournament_id
        and tm.user_id = auth.uid()
        and tm.status = 'active'
        and tm.role_key in ('owner', 'manager')
    );
$$;

revoke all on function public.is_tournament_organizer(uuid) from public;
grant execute on function public.is_tournament_organizer(uuid) to authenticated;

create or replace function public.is_tournament_admin(
  p_tournament_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = p_tournament_id
        and t.owner_user_id = auth.uid()
    )
    or exists (
      select 1
      from public.tournament_memberships tm
      where tm.tournament_id = p_tournament_id
        and tm.user_id = auth.uid()
        and tm.status = 'active'
        and tm.role_key in ('owner', 'manager')
    );
$$;

revoke all on function public.is_tournament_admin(uuid) from public;
grant execute on function public.is_tournament_admin(uuid) to authenticated;

-- ─── 11. Remove Stored tournaments.status ─────────────────────────────────────
-- Public tournament status is derived on read from the orthogonal canonical states.

drop trigger if exists tournaments_sync_status_projection on public.tournaments;
drop function if exists public.project_tournament_canonical_to_legacy_status();

alter table public.tournaments drop column if exists status;
