-- =============================================================================
-- 0310 · tournament_teams
-- =============================================================================
-- Spec §3.7, §3.11. Team-to-tournament registration record.
--
-- Direction:
--   Team manager ────► Tournament organizer
--    registers via INSERT;       approves/rejects via RPC
--
-- Lifecycle (`status`):
--   pending     manager INSERTed; awaiting organizer decision
--   approved    organizer accepted; team is in the bracket
--   rejected    organizer declined
--   withdrawn   manager pulled the team after registering
--
-- Squad lock-in:
--   `squad` (uuid[]) freezes the player roster for this tournament. Spec
--   §3.7 says rosters are locked at tournament start unless
--   rules.allow_mid_tournament_squad_changes is on. Today the application
--   layer enforces that — promote to a trigger when match scheduling lands.
--
-- Group / seeding metadata:
--   `seed_number`, `group_id`, `payment_status` are filled in during the
--   bracket-build step (matches/standings migrations). Optional pre-bracket.
--
-- Approve/Reject:
--   Direct UPDATE via RLS would technically work, but going through the
--   approve_tournament_registration / reject_tournament_registration RPCs
--   keeps the decided_by + decided_at stamps consistent and gives us a
--   single hook for future notification fan-out.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Registration-status enum.
-- -----------------------------------------------------------------------------
create type public.tournament_registration_status as enum (
  'pending',
  'approved',
  'rejected',
  'withdrawn'
);

-- -----------------------------------------------------------------------------
-- tournament_teams table.
-- -----------------------------------------------------------------------------
create table public.tournament_teams (
  registration_id   uuid primary key default gen_random_uuid(),
  tournament_id     uuid not null
                       references public.tournaments(tournament_id) on delete cascade,
  team_id           uuid not null
                       references public.teams(team_id) on delete cascade,
  -- ON DELETE SET NULL so a deleted registrar's account doesn't block.
  -- The registration row itself outlives them.
  registered_by     uuid
                       references public.profiles(user_id) on delete set null,
  registered_at     timestamptz not null default now(),
  status            public.tournament_registration_status not null default 'pending',
  -- Player UUIDs from the team's roster locked in for this tournament.
  squad             uuid[] not null default '{}',
  seed_number       integer check (seed_number is null or seed_number >= 1),
  group_id          text,
  payment_status    text,
  decided_by        uuid references public.profiles(user_id) on delete set null,
  decided_at        timestamptz,
  message           text check (message is null or length(message) <= 500),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint tournament_teams_unique unique (tournament_id, team_id),
  constraint registration_decision_consistency check (
    (status in ('pending', 'withdrawn'))
    or (status in ('approved', 'rejected') and decided_at is not null)
  )
);

create index tournament_teams_tournament on public.tournament_teams (tournament_id);
create index tournament_teams_team       on public.tournament_teams (team_id);
create index tournament_teams_status     on public.tournament_teams (tournament_id, status);

create trigger tournament_teams_set_updated_at
  before update on public.tournament_teams
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Approve registration RPC.
-- -----------------------------------------------------------------------------
create or replace function public.approve_tournament_registration(p_registration_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_tournament_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select tournament_id
    into v_tournament_id
    from public.tournament_teams
   where registration_id = p_registration_id and status = 'pending'
   for update;
  if v_tournament_id is null then
    raise exception 'Registration not found or not pending' using errcode = 'P0002';
  end if;
  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can approve' using errcode = '42501';
  end if;

  update public.tournament_teams
     set status     = 'approved',
         decided_by = v_uid,
         decided_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.approve_tournament_registration(uuid) from public;
grant execute on function public.approve_tournament_registration(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Reject registration RPC.
-- -----------------------------------------------------------------------------
create or replace function public.reject_tournament_registration(p_registration_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_tournament_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select tournament_id
    into v_tournament_id
    from public.tournament_teams
   where registration_id = p_registration_id and status = 'pending'
   for update;
  if v_tournament_id is null then
    raise exception 'Registration not found or not pending' using errcode = 'P0002';
  end if;
  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can reject' using errcode = '42501';
  end if;

  update public.tournament_teams
     set status     = 'rejected',
         decided_by = v_uid,
         decided_at = now()
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.reject_tournament_registration(uuid) from public;
grant execute on function public.reject_tournament_registration(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS — read by organizers, registering team's manager, or anyone if the
-- tournament is public. INSERT only by team manager (matches the "Register
-- a team" row in §3.11) and only while the tournament is in draft or
-- registration. UPDATE allows team manager to withdraw OR organizers to
-- approve/reject (the RPCs go through this same gate).
-- -----------------------------------------------------------------------------
alter table public.tournament_teams enable row level security;

create policy "tournament_teams_read"
  on public.tournament_teams for select
  using (
    public.is_tournament_organizer(tournament_id)
    or public.is_team_manager(team_id)
    or exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_teams.tournament_id
         and t.privacy = 'public'
    )
  );

create policy "tournament_teams_insert_manager"
  on public.tournament_teams for insert
  to authenticated
  with check (
    public.is_team_manager(team_id)
    and (select auth.uid()) = registered_by
    and exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_teams.tournament_id
         and t.status in ('registration', 'draft')
    )
  );

create policy "tournament_teams_update_manager_or_organizer"
  on public.tournament_teams for update
  to authenticated
  using (
    public.is_team_manager(team_id)
    or public.is_tournament_organizer(tournament_id)
  )
  with check (
    public.is_team_manager(team_id)
    or public.is_tournament_organizer(tournament_id)
  );
