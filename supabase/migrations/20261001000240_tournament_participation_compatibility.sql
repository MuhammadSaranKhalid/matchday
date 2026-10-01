-- 20261001000240_tournament_participation_compatibility.sql
-- Canonical Transitional Operations, One-Way Compatibility Sync, and Backfill
-- Clean Architecture Step 6 / Phase 3

-- ─── 1. Canonical approve_tournament_registration RPC ────────────────────────
-- Atomic domain command: verifies preconditions, locks capacity, marks registration
-- approved, and creates canonical active TournamentEntry.
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
  v_legacy_squad uuid[];
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- 1. Lock registration row for update
  select tournament_id, team_id, status
    into v_tournament_id, v_team_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    -- Fallback: check legacy tournament_teams if registration row not yet created
    select tournament_id, team_id, status::text
      into v_tournament_id, v_team_id, v_reg_status
      from public.tournament_teams
     where registration_id = p_registration_id
       for update;

    if not found then
      raise exception 'Registration not found' using errcode = 'P0002';
    end if;

    -- Create canonical registration row on the fly
    insert into public.tournament_registrations (
      registration_id, tournament_id, team_id, registered_by, registered_at, status
    ) values (
      p_registration_id, v_tournament_id, v_team_id, v_uid, now(), v_reg_status
    ) on conflict (registration_id) do nothing;
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
  if not (
    public.can('tournament', v_tournament_id, 'tournament.registration.review')
    or public.is_tournament_organizer(v_tournament_id)
  ) then
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
  do nothing
  returning entry_id into v_entry_id;

  -- 10. If legacy squad UUIDs exist on tournament_teams, populate canonical squad
  select squad into v_legacy_squad
    from public.tournament_teams
   where registration_id = p_registration_id;

  if v_entry_id is not null and v_legacy_squad is not null and array_length(v_legacy_squad, 1) > 0 then
    insert into public.tournament_squad_members (
      entry_id, tournament_id, user_id, membership_status, added_by, added_at
    )
    select v_entry_id, v_tournament_id, u.user_id, 'active', v_uid, now()
      from unnest(v_legacy_squad) as u(user_id)
      join public.team_members tm on tm.team_id = v_team_id and tm.user_id = u.user_id
    on conflict do nothing;
  end if;

  -- 11. One-way sync to legacy tournament_teams projection
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

  -- 1. Lock registration row for update
  select tournament_id, status
    into v_tournament_id, v_reg_status
    from public.tournament_registrations
   where registration_id = p_registration_id
     for update;

  if not found then
    select tournament_id, status::text
      into v_tournament_id, v_reg_status
      from public.tournament_teams
     where registration_id = p_registration_id
       for update;

    if not found then
      raise exception 'Registration not found' using errcode = 'P0002';
    end if;
  end if;

  -- 2. Authorization
  if not (
    public.can('tournament', v_tournament_id, 'tournament.registration.review')
    or public.is_tournament_organizer(v_tournament_id)
  ) then
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

-- ─── 3. Canonical tournament_record_payment RPC & Ledger Adapter ─────────────
-- Accepts cumulative amount from legacy UI and maps it deterministically to
-- immutable transaction records in public.tournament_entry_payments.
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
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if p_amount_paid is null or p_amount_paid < 0 then
    raise exception 'Amount must be zero or more' using errcode = '22023';
  end if;

  -- 1. Find the canonical Entry associated with this registration
  select entry_id, tournament_id
    into v_entry_id, v_tournament_id
    from public.tournament_entries
   where registration_id = p_registration_id
     and status = 'active';

  if not found then
    -- Check if tournament_teams has this registration
    select tournament_id
      into v_tournament_id
      from public.tournament_teams
     where registration_id = p_registration_id;

    if not found then
      raise exception 'Registration not found' using errcode = 'P0002';
    end if;
  end if;

  -- 2. Authorization
  if not (
    public.can('tournament', v_tournament_id, 'tournament.finance.record')
    or public.is_tournament_organizer(v_tournament_id)
  ) then
    raise exception 'Only tournament organizers can record payments' using errcode = '42501';
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

  -- 4. Ledger Adapter: Compute incremental transaction delta
  if v_entry_id is not null then
    select coalesce(sum(amount), 0)
      into v_current_total
      from public.tournament_entry_payments
     where entry_id = v_entry_id
       and is_void = false;

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
  end if;

  -- 5. One-way update legacy tournament_teams projection
  update public.tournament_teams
     set amount_paid = p_amount_paid,
         payment_channel = p_channel,
         payment_reference = nullif(btrim(coalesce(p_reference, '')), ''),
         payment_recorded_at = now(),
         payment_recorded_by = v_uid,
         payment_status = case
           when v_entry_fee > 0 and p_amount_paid >= v_entry_fee then 'paid'
           when p_amount_paid > 0 then 'partial'
           else 'unpaid'
         end,
         updated_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.tournament_record_payment(uuid, numeric, text, text) from public;
grant execute on function public.tournament_record_payment(uuid, numeric, text, text) to authenticated;

-- ─── 4. Backfill from legacy tournament_teams ────────────────────────────────
-- Deterministically migrates existing rows into canonical relations.
do $$
declare
  r record;
  v_entry_id uuid;
  v_player_id uuid;
begin
  for r in (select * from public.tournament_teams order by registered_at asc) loop
    -- A. Backfill Tournament Registration
    insert into public.tournament_registrations (
      registration_id,
      tournament_id,
      team_id,
      registered_by,
      registered_at,
      status,
      message,
      decision_reason,
      decided_by,
      decided_at,
      withdrawn_at,
      created_at,
      updated_at
    ) values (
      r.registration_id,
      r.tournament_id,
      r.team_id,
      r.registered_by,
      r.registered_at,
      r.status,
      r.message,
      r.decision_reason,
      r.decided_by,
      r.decided_at,
      case when r.status = 'withdrawn' then coalesce(r.decided_at, r.updated_at, now()) else null end,
      r.created_at,
      r.updated_at
    ) on conflict (registration_id) do nothing;

    -- B. Backfill Tournament Entry for approved rows
    if r.status = 'approved' then
      insert into public.tournament_entries (
        tournament_id,
        team_id,
        registration_id,
        status,
        entry_source,
        accepted_by,
        accepted_at,
        created_at,
        updated_at
      ) values (
        r.tournament_id,
        r.team_id,
        r.registration_id,
        'active',
        'application',
        coalesce(r.decided_by, r.registered_by),
        coalesce(r.decided_at, r.registered_at),
        r.created_at,
        r.updated_at
      )
      on conflict (tournament_id, team_id) where status = 'active'
      do update set registration_id = excluded.registration_id
      returning entry_id into v_entry_id;

      -- C. Backfill Squad members from squad uuid[]
      if v_entry_id is not null and r.squad is not null and array_length(r.squad, 1) > 0 then
        foreach v_player_id in array r.squad loop
          -- Only add if player profile exists
          if exists (select 1 from public.profiles where user_id = v_player_id) then
            insert into public.tournament_squad_members (
              entry_id,
              tournament_id,
              user_id,
              membership_status,
              added_by,
              added_at
            ) values (
              v_entry_id,
              r.tournament_id,
              v_player_id,
              'active',
              coalesce(r.decided_by, r.registered_by),
              coalesce(r.decided_at, r.registered_at)
            ) on conflict do nothing;
          end if;
        end loop;
      end if;

      -- D. Backfill Payment history if amount_paid > 0
      if v_entry_id is not null and r.amount_paid is not null and r.amount_paid > 0 then
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
          r.tournament_id,
          r.amount_paid,
          coalesce(r.payment_channel, 'cash'),
          r.payment_reference,
          coalesce(r.payment_recorded_by, r.decided_by, r.registered_by),
          coalesce(r.payment_recorded_at, r.decided_at, now())
        ) on conflict do nothing;
      end if;
    end if;
  end loop;
end $$;

-- ─── 5. Canonical -> Legacy One-Way Projection Triggers ──────────────────────

create or replace function public.project_canonical_registration_to_legacy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
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
  if new.status = 'withdrawn' and (old.status is null or old.status != 'withdrawn') then
    update public.tournament_teams
       set status = 'withdrawn',
           updated_at = now()
     where registration_id = new.registration_id;
  end if;
  return new;
end;
$$;

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

drop trigger if exists trg_project_canonical_squad on public.tournament_squad_members;
create trigger trg_project_canonical_squad
  after insert or update or delete on public.tournament_squad_members
  for each row
  execute function public.project_canonical_squad_to_legacy();

