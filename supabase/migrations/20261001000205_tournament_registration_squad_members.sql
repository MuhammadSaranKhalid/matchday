-- 20261001000205_tournament_registration_squad_members.sql
-- Pre-Approval Tournament Registration Squad Proposals (Option B)
-- Clean Architecture Step 6 / Phase 3.1

create table if not exists public.tournament_registration_squad_members (
  proposal_member_id uuid primary key default gen_random_uuid(),
  registration_id uuid not null references public.tournament_registrations(registration_id) on delete cascade,
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  team_id uuid not null references public.teams(team_id) on delete restrict,
  user_id uuid references public.profiles(user_id) on delete cascade,
  unclaimed_id uuid references public.unclaimed_players(unclaimed_id) on delete cascade,
  submitted_by uuid references public.profiles(user_id) on delete set null,
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- XOR identity integrity: exactly one of user_id or unclaimed_id must be populated
  constraint proposal_member_identity_xor
    check (num_nonnulls(user_id, unclaimed_id) = 1)
);

-- Partial unique indexes: No player can be added twice to the same proposed squad
create unique index if not exists idx_proposal_squad_registration_user
  on public.tournament_registration_squad_members (registration_id, user_id)
  where user_id is not null;

create unique index if not exists idx_proposal_squad_registration_unclaimed
  on public.tournament_registration_squad_members (registration_id, unclaimed_id)
  where unclaimed_id is not null;

-- Lookup indexes
create index if not exists idx_proposal_squad_registration
  on public.tournament_registration_squad_members (registration_id);

create index if not exists idx_proposal_squad_tournament
  on public.tournament_registration_squad_members (tournament_id);

create index if not exists idx_proposal_squad_team
  on public.tournament_registration_squad_members (team_id);

create index if not exists idx_proposal_squad_user
  on public.tournament_registration_squad_members (user_id);

create index if not exists idx_proposal_squad_unclaimed
  on public.tournament_registration_squad_members (unclaimed_id);

-- Trigger: enforce proposal eligibility and sync tournament_id and team_id from parent registration
create or replace function public.enforce_proposal_member_roster()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_reg_status text;
  v_reg_tournament_id uuid;
  v_reg_team_id uuid;
  v_is_team_member boolean;
begin
  if current_setting('matchday.migration_backfill', true) = 'true' then
    return new;
  end if;

  select status, tournament_id, team_id
    into v_reg_status, v_reg_tournament_id, v_reg_team_id
    from public.tournament_registrations
   where registration_id = new.registration_id;

  if not found then
    raise exception 'Registration % not found', new.registration_id using errcode = 'P0002';
  end if;

  if v_reg_status != 'pending' then
    raise exception 'Cannot modify squad proposal for non-pending registration (status: %)', v_reg_status
      using errcode = '22000';
  end if;

  new.tournament_id := v_reg_tournament_id;
  new.team_id := v_reg_team_id;

  -- Verify player belongs to team's active roster
  if new.user_id is not null then
    select exists (
      select 1 from public.team_members
       where team_id = v_reg_team_id
         and user_id = new.user_id
         and status = 'active'
    ) into v_is_team_member;

    if not v_is_team_member then
      raise exception 'Claimed player % is not an active member of team %', new.user_id, v_reg_team_id
        using errcode = '22000';
    end if;
  elsif new.unclaimed_id is not null then
    select exists (
      select 1 from public.team_members
       where team_id = v_reg_team_id
         and unclaimed_id = new.unclaimed_id
         and status = 'active'
    ) into v_is_team_member;

    if not v_is_team_member then
      raise exception 'Unclaimed player % is not an active member of team %', new.unclaimed_id, v_reg_team_id
        using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_proposal_member_roster() from public;

drop trigger if exists trg_proposal_member_roster on public.tournament_registration_squad_members;
create trigger trg_proposal_member_roster
  before insert or update of registration_id, user_id, unclaimed_id
  on public.tournament_registration_squad_members
  for each row
  execute function public.enforce_proposal_member_roster();

-- Trigger: set updated_at
drop trigger if exists trg_proposal_member_set_updated_at on public.tournament_registration_squad_members;
create trigger trg_proposal_member_set_updated_at
  before update on public.tournament_registration_squad_members
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS Security Policies
-- -----------------------------------------------------------------------------
alter table public.tournament_registration_squad_members enable row level security;

-- Read: tournament staff review OR team manager
drop policy if exists "proposal_members_read" on public.tournament_registration_squad_members;
create policy "proposal_members_read"
  on public.tournament_registration_squad_members
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.registration.review')
    or public.can('team', team_id, 'team.tournament.enter')
    or public.can('team', team_id, 'team.tournament.squad.manage')
  );

-- Insert: team manager while registration is pending
drop policy if exists "proposal_members_insert" on public.tournament_registration_squad_members;
create policy "proposal_members_insert"
  on public.tournament_registration_squad_members
  for insert
  to authenticated
  with check (
    (public.can('team', team_id, 'team.tournament.enter') or public.can('team', team_id, 'team.tournament.squad.manage'))
    and exists (
      select 1 from public.tournament_registrations r
       where r.registration_id = tournament_registration_squad_members.registration_id
         and r.status = 'pending'
    )
  );

-- Delete: team manager while registration is pending
drop policy if exists "proposal_members_delete" on public.tournament_registration_squad_members;
create policy "proposal_members_delete"
  on public.tournament_registration_squad_members
  for delete
  to authenticated
  using (
    (public.can('team', team_id, 'team.tournament.enter') or public.can('team', team_id, 'team.tournament.squad.manage'))
    and exists (
      select 1 from public.tournament_registrations r
       where r.registration_id = tournament_registration_squad_members.registration_id
         and r.status = 'pending'
    )
  );

-- Direct update blocked
drop policy if exists "proposal_members_no_update" on public.tournament_registration_squad_members;
create policy "proposal_members_no_update"
  on public.tournament_registration_squad_members
  for update
  to authenticated
  using (false)
  with check (false);
