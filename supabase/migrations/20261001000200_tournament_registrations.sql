-- 20261001000200_tournament_registrations.sql
-- Canonical Tournament Registration (Application) Model
-- Clean Architecture Step 6 / Phase 3

-- Ensure table does not exist
create table if not exists public.tournament_registrations (
  registration_id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  team_id uuid not null references public.teams(team_id) on delete cascade,
  registered_by uuid references public.profiles(user_id) on delete set null,
  registered_at timestamptz not null default now(),
  status public.tournament_registration_status not null default 'pending',
  message text,
  decision_reason text,
  decided_by uuid references public.profiles(user_id) on delete set null,
  decided_at timestamptz,
  withdrawn_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tournament_registrations_message_check
    check (message is null or length(message) <= 500),
  constraint tournament_registrations_decision_reason_check
    check (decision_reason is null or length(decision_reason) <= 500),
  constraint tournament_registrations_decision_consistency
    check (
      (status in ('pending', 'withdrawn') and decided_at is null) or
      (status in ('approved', 'rejected') and decided_at is not null)
    ),
  constraint tournament_registrations_withdrawn_consistency
    check (status != 'withdrawn' or withdrawn_at is not null)
);

-- Partial unique index: A team can have only one pending application per tournament.
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

-- Trigger: enforce sport compatibility between registering team and tournament
create or replace function public.enforce_tournament_registration_sport()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tourn_sport text;
  v_team_sport text;
begin
  select sport_id into v_tourn_sport
    from public.tournaments
   where tournament_id = new.tournament_id;

  select sport_id into v_team_sport
    from public.teams
   where team_id = new.team_id;

  if v_tourn_sport is distinct from v_team_sport then
    raise exception 'Team sport (%) does not match tournament sport (%)',
      v_team_sport, v_tourn_sport
      using errcode = '22000';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tournament_registrations_enforce_sport on public.tournament_registrations;
create trigger trg_tournament_registrations_enforce_sport
  before insert or update of tournament_id, team_id
  on public.tournament_registrations
  for each row
  execute function public.enforce_tournament_registration_sport();

-- Trigger: set updated_at
drop trigger if exists trg_tournament_registrations_set_updated_at on public.tournament_registrations;
create trigger trg_tournament_registrations_set_updated_at
  before update on public.tournament_registrations
  for each row
  execute function public.set_updated_at();

-- RLS Security Policies
alter table public.tournament_registrations enable row level security;

-- Read policy: Organizers, Team Managers, or Public if Tournament is Public
drop policy if exists "tournament_registrations_read" on public.tournament_registrations;
create policy "tournament_registrations_read"
  on public.tournament_registrations
  for select
  to anon, authenticated
  using (
    public.is_tournament_organizer(tournament_id)
    or public.is_team_manager(team_id)
    or exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_registrations.tournament_id
         and t.privacy = 'public'::tournament_privacy
    )
  );

-- Insert policy: Team Manager applying while registration is open
drop policy if exists "tournament_registrations_insert" on public.tournament_registrations;
create policy "tournament_registrations_insert"
  on public.tournament_registrations
  for insert
  to authenticated
  with check (
    public.is_team_manager(team_id)
    and (select auth.uid()) = registered_by
    and exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_registrations.tournament_id
         and t.registration_state = 'open'::tournament_registration_state
    )
  );

-- Update policy:
-- 1. Team managers can withdraw their pending applications
-- 2. Tournament organizers can review (or transitional RPCs perform the updates)
drop policy if exists "tournament_registrations_update" on public.tournament_registrations;
create policy "tournament_registrations_update"
  on public.tournament_registrations
  for update
  to authenticated
  using (
    public.is_tournament_organizer(tournament_id)
    or public.is_team_manager(team_id)
  )
  with check (
    public.is_tournament_organizer(tournament_id)
    or (
      public.is_team_manager(team_id)
      and status = 'withdrawn'::tournament_registration_status
    )
  );
