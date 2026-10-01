-- 20261001000200_tournament_registrations.sql
-- Canonical Tournament Registration (Application) Model
-- Clean Architecture Step 6 / Phase 3

-- Ensure table does not exist
create table if not exists public.tournament_registrations (
  registration_id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  team_id uuid not null references public.teams(team_id) on delete restrict,
  registered_by uuid references public.profiles(user_id) on delete set null,
  registered_at timestamptz not null default now(),
  status public.tournament_registration_status not null default 'pending',
  message text,
  squad_proposal uuid[] not null default '{}',
  decision_reason text,
  decided_by uuid references public.profiles(user_id) on delete set null,
  decided_at timestamptz,
  withdrawn_at timestamptz,
  withdrawn_by uuid references public.profiles(user_id) on delete set null,
  withdrawal_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tournament_registrations_message_check
    check (message is null or length(message) <= 500),
  constraint tournament_registrations_decision_reason_check
    check (decision_reason is null or length(decision_reason) <= 500),
  constraint tournament_registrations_withdrawal_reason_check
    check (withdrawal_reason is null or length(withdrawal_reason) <= 500),
  constraint tournament_registrations_decision_consistency
    check (
      (status in ('pending', 'withdrawn') and decided_at is null) or
      (status in ('approved', 'rejected') and decided_at is not null)
    ),
  constraint tournament_registrations_withdrawn_consistency
    check (status != 'withdrawn' or withdrawn_at is not null),
  -- Composite candidate key to guarantee Entry <-> Registration consistency (Item 33)
  constraint tournament_registrations_identity_unique
    unique (registration_id, tournament_id, team_id)
);

-- Partial unique index: A team can have only one unresolved pending application per tournament.
-- Rejected or pre-approval withdrawn applications remain as historical records.
create unique index if not exists idx_tournament_registrations_pending
  on public.tournament_registrations (tournament_id, team_id)
  where status = 'pending';

-- Fast lookup indexes
create index if not exists idx_tournament_registrations_tournament_status
  on public.tournament_registrations (tournament_id, status);

create index if not exists idx_tournament_registrations_team
  on public.tournament_registrations (team_id);

create index if not exists idx_tournament_registrations_registered_by
  on public.tournament_registrations (registered_by);

create index if not exists idx_tournament_registrations_decided_by
  on public.tournament_registrations (decided_by);

create index if not exists idx_tournament_registrations_withdrawn_by
  on public.tournament_registrations (withdrawn_by);

-- Trigger: enforce sport compatibility and registration window invariants on application
create or replace function public.enforce_tournament_registration_rules()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tourn_sport text;
  v_team_sport text;
  v_reg_state public.tournament_registration_state;
  v_reg_deadline date;
begin
  -- Skip runtime checks during one-time migration backfill
  if current_setting('matchday.migration_backfill', true) = 'true' then
    return new;
  end if;

  select sport_id, registration_state, registration_deadline
    into v_tourn_sport, v_reg_state, v_reg_deadline
    from public.tournaments
   where tournament_id = new.tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  select sport_id into v_team_sport
    from public.teams
   where team_id = new.team_id;

  if not found then
    raise exception 'Team not found' using errcode = 'P0002';
  end if;

  -- 1. Sport Compatibility Invariant
  if v_tourn_sport is distinct from v_team_sport then
    raise exception 'Team sport (%) does not match tournament sport (%)',
      v_team_sport, v_tourn_sport
      using errcode = '22000';
  end if;

  -- 2. Registration Open Invariant (for new applications)
  if tg_op = 'INSERT' then
    if v_reg_state != 'open' then
      raise exception 'Tournament registration is not open (current state: %)', v_reg_state
        using errcode = '22000';
    end if;

    -- 3. Registration Deadline Invariant (Item 15)
    -- Registration deadline closes NEW submissions; already pending applications remain resolvable.
    if v_reg_deadline is not null and current_date > v_reg_deadline then
      raise exception 'Tournament registration deadline has passed (%)', v_reg_deadline
        using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tournament_registrations_rules on public.tournament_registrations;
create trigger trg_tournament_registrations_rules
  before insert or update of tournament_id, team_id
  on public.tournament_registrations
  for each row
  execute function public.enforce_tournament_registration_rules();

-- Trigger: set updated_at
drop trigger if exists trg_tournament_registrations_set_updated_at on public.tournament_registrations;
create trigger trg_tournament_registrations_set_updated_at
  before update on public.tournament_registrations
  for each row
  execute function public.set_updated_at();

-- RLS Security Policies
alter table public.tournament_registrations enable row level security;

-- Read policy (Item 19): Administrative privacy preserved.
-- Only authorized Tournament review staff or authorized Team representatives may read base applications.
-- Anonymous / public users cannot see raw application notes, reasons, or draft squad proposals.
drop policy if exists "tournament_registrations_read" on public.tournament_registrations;
create policy "tournament_registrations_read"
  on public.tournament_registrations
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.registration.review')
    or public.can('team', team_id, 'team.tournament.enter')
    or (select auth.uid()) = registered_by
  );

-- Insert policy (Item 16): Team authority using canonical capability team.tournament.enter
drop policy if exists "tournament_registrations_insert" on public.tournament_registrations;
create policy "tournament_registrations_insert"
  on public.tournament_registrations
  for insert
  to authenticated
  with check (
    public.can('team', team_id, 'team.tournament.enter')
    and (select auth.uid()) = registered_by
    and status = 'pending'::tournament_registration_status
  );

-- Update policy (Item 14): Prevent direct tampering with administrative history.
-- All state transitions must occur through dedicated transactional commands (approve, reject, withdraw RPCs).
drop policy if exists "tournament_registrations_update" on public.tournament_registrations;
create policy "tournament_registrations_update"
  on public.tournament_registrations
  for update
  to authenticated
  using (false)
  with check (false);

-- Delete policy: No direct delete of application history
drop policy if exists "tournament_registrations_delete" on public.tournament_registrations;
create policy "tournament_registrations_delete"
  on public.tournament_registrations
  for delete
  to authenticated
  using (false);
