-- 20261001000240_tournament_participation_compatibility.sql
-- Canonical Transitional Operations, One-Way Compatibility Sync, and Backfill
-- Clean Architecture Step 6 / Phase 3

-- ─── 0. Register Frozen Tournament Capabilities ──────────────────────────────
insert into public.permissions
  (permission_key, resource, action, description, min_rank, direct_grantable, sort_order)
values
  ('tournament.payment.manage', 'finance', 'manage', 'Record and void tournament entry fee payments and manage financial ledger', 30, false, 245),
  ('tournament.squad.review', 'squad', 'review', 'Review, approve, and manage tournament participant squad rosters', 30, false, 246)
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
  ('tournament.squad.review', 'tournament')
on conflict (permission_key, scope) do nothing;

insert into public.role_permissions (team_id, scope, role_key, permission_key, granted)
values
  (null, 'tournament', 'owner', 'tournament.payment.manage', true),
  (null, 'tournament', 'owner', 'tournament.squad.review', true),
  (null, 'tournament', 'manager', 'tournament.payment.manage', true),
  (null, 'tournament', 'manager', 'tournament.squad.review', true)
on conflict (team_id, scope, role_key, permission_key) do nothing;

-- ─── 1. Canonical approve_tournament_registration RPC ────────────────────────
-- Atomic domain command: verifies preconditions, locks capacity, marks registration
-- approved, creates canonical active TournamentEntry, and populates squad from proposal.
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
  v_squad_proposal uuid[];
  v_max_teams integer;
  v_entry_state public.tournament_entry_state;
  v_active_entries integer;
  v_entry_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock canonical registration row for update (fail closed if missing, NO legacy fallback)
  select tournament_id, team_id, status, squad_proposal
    into v_tournament_id, v_team_id, v_reg_status, v_squad_proposal
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

  -- 4. Authorize via canonical capability check (no generic organizer bypass)
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

  -- 8. Mark canonical Registration as approved
  update public.tournament_registrations
     set status = 'approved',
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 9. Atomically create canonical TournamentEntry
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

  -- 10. Populate canonical squad strictly from Registration squad proposal (Option B, never legacy squad[])
  if v_squad_proposal is not null and array_length(v_squad_proposal, 1) > 0 then
    insert into public.tournament_squad_members (
      entry_id, tournament_id, user_id, membership_status, added_by, added_at
    )
    select v_entry_id, v_tournament_id, u.user_id, 'active', v_uid, now()
      from unnest(v_squad_proposal) as u(user_id)
      join public.team_members tm on tm.team_id = v_team_id and tm.user_id = u.user_id
    on conflict do nothing;
  end if;

  -- 11. One-way sync to legacy tournament_teams projection
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

-- ─── 2. Canonical reject_tournament_registration RPC ────────────────────────
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
         decision_reason = btrim(coalesce(p_reason, '')),
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 4. One-way update legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  update public.tournament_teams
     set status = 'rejected',
         decision_reason = btrim(coalesce(p_reason, '')),
         decided_by = v_uid,
         decided_at = now(),
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.reject_tournament_registration(uuid, text) from public;
grant execute on function public.reject_tournament_registration(uuid, text) to authenticated;

-- ─── 3. Canonical withdraw_tournament_registration RPC ──────────────────────
-- Audited server-side command for withdrawing a pending application before decision.
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

  -- 1. Lock canonical registration row
  select team_id, status
    into v_team_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  -- 2. Authorize via Team capability
  if not (
    public.can('team', v_team_id, 'team.tournament.enter')
    or public.is_team_manager(v_team_id)
  ) then
    raise exception 'Unauthorized to withdraw registration for team' using errcode = '42501';
  end if;

  -- 3. Verify status is pending
  if v_reg_status != 'pending' then
    if v_reg_status = 'withdrawn' then
      return;
    end if;
    raise exception 'Cannot withdraw registration with status %', v_reg_status
      using errcode = '22000';
  end if;

  -- 4. Update canonical registration with actor audit
  update public.tournament_registrations
     set status = 'withdrawn',
         withdrawn_at = now(),
         withdrawn_by = v_uid,
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where registration_id = p_registration_id;

  -- 5. One-way update legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

  update public.tournament_teams
     set status = 'withdrawn',
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.withdraw_tournament_registration(uuid, text) from public;
grant execute on function public.withdraw_tournament_registration(uuid, text) to authenticated;

-- ─── 4. Canonical withdraw_tournament_entry RPC ──────────────────────────────
-- Audited server-side command for withdrawing an accepted Entry before Entry Set Lock.
-- Releases active squad conflicts while preserving history.
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

  -- 1. Lock Entry row
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
    raise exception 'Only active entries can be withdrawn (current status: %)', v_entry_status
      using errcode = '22000';
  end if;

  -- 2. Lock / read Tournament root
  select entry_state
    into v_entry_state
    from public.tournaments
   where tournament_id = v_tournament_id
     for update;

  -- 3. Authorization: Team participation authority or Tournament staff
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

  -- 5. Stamp withdrawal on canonical Entry (Registration remains 'approved')
  update public.tournament_entries
     set status = 'withdrawn',
         withdrawn_by = v_uid,
         withdrawn_at = now(),
         withdrawal_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at = now()
   where entry_id = p_entry_id;

  -- 6. Release active squad conflict: transition active squad members of this entry to 'removed'
  -- Preserves historical record without deleting rows
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

-- ─── 5. Canonical tournament_record_payment RPC & Ledger Adapter ─────────────
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
  v_entry_fee numeric;
  v_current_total numeric;
  v_delta numeric;
  v_legacy_status text;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_amount_paid is null or p_amount_paid < 0 then
    raise exception 'Amount must be zero or more' using errcode = '22023';
  end if;

  -- 1. Find canonical active Entry and acquire deterministic row lock (fail closed, NO legacy fallback)
  select entry_id, tournament_id
    into v_entry_id, v_tournament_id
    from public.tournament_entries
   where registration_id = p_registration_id
     and status = 'active'
     for update;

  if not found then
    raise exception 'Active tournament entry not found for registration %', p_registration_id
      using errcode = 'P0002';
  end if;

  -- 2. Authorization via canonical capability
  if not public.can('tournament', v_tournament_id, 'tournament.payment.manage') then
    raise exception 'Unauthorized to record tournament payments' using errcode = '42501';
  end if;

  -- 3. Verify entry fee
  select coalesce(entry_fee, 0)
    into v_entry_fee
    from public.tournaments
   where tournament_id = v_tournament_id;

  if v_entry_fee > 0 and p_amount_paid > v_entry_fee then
    raise exception 'Amount exceeds the entry fee of %', v_entry_fee
      using errcode = '22023';
  end if;

  -- 4. Ledger Adapter: Compute incremental transaction delta under Entry lock
  select coalesce(sum(amount), 0)
    into v_current_total
    from public.tournament_entry_payments
   where entry_id = v_entry_id
     and is_void = false;

  -- Disallow decreasing cumulative payment (must use explicit voiding)
  if p_amount_paid < v_current_total then
    raise exception 'Requested cumulative amount (%) is less than current recorded total (%). Void existing payments to reduce.',
      p_amount_paid, v_current_total
      using errcode = '22000';
  end if;

  v_delta := p_amount_paid - v_current_total;

  if v_delta > 0 then
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
      coalesce(p_channel, 'cash'),
      nullif(btrim(coalesce(p_reference, '')), ''),
      v_uid,
      now()
    );
  end if;

  -- 5. One-way update legacy tournament_teams projection
  perform set_config('matchday.allow_legacy_projection', 'true', true);

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

-- ─── 6. Canonical void_tournament_entry_payment RPC ──────────────────────────
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

  -- 1. Find and lock payment row
  select p.entry_id, p.tournament_id, e.registration_id
    into v_entry_id, v_tournament_id, v_registration_id
    from public.tournament_entry_payments p
    join public.tournament_entries e on e.entry_id = p.entry_id
   where p.payment_id = p_payment_id
     for update;

  if not found then
    raise exception 'Payment not found' using errcode = 'P0002';
  end if;

  -- 2. Authorization via canonical capability
  if not public.can('tournament', v_tournament_id, 'tournament.payment.manage') then
    raise exception 'Unauthorized to void tournament payments' using errcode = '42501';
  end if;

  -- 3. Void payment
  update public.tournament_entry_payments
     set is_void = true,
         voided_by = v_uid,
         voided_at = now(),
         void_reason = btrim(p_reason),
         updated_at = now()
   where payment_id = p_payment_id;

  -- 4. Lock and update legacy projection
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

-- ─── 7. Legacy tournament_teams Write-Protection Trigger ─────────────────────
-- Prohibits direct Data API mutation of migrated participation concerns on legacy table.
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

-- ─── 8. Backfill from legacy tournament_teams ────────────────────────────────
-- Deterministically migrates historical rows into canonical relations.
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
        squad_proposal, created_at, updated_at
      ) values (
        r.registration_id, r.tournament_id, r.team_id, r.registered_by, r.registered_at,
        r.status, r.message, r.decision_reason, r.decided_by, r.decided_at,
        coalesce(r.squad, '{}'), r.created_at, r.updated_at
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

-- ─── 9. Canonical -> Legacy One-Way Projection Triggers ──────────────────────

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
    select coalesce(array_agg(user_id order by added_at), '{}'::uuid[])
      into v_squad
      from public.tournament_squad_members
     where entry_id = v_entry_id
       and membership_status = 'active';

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
