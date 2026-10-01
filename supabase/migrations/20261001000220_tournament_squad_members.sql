-- 20261001000220_tournament_squad_members.sql
-- Canonical Tournament Squad Members
-- Clean Architecture Step 6 / Phase 3

create table if not exists public.tournament_squad_members (
  squad_member_id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.tournament_entries(entry_id) on delete cascade,
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  membership_status text not null default 'active',
  added_by uuid references public.profiles(user_id) on delete set null,
  added_at timestamptz not null default now(),
  removed_by uuid references public.profiles(user_id) on delete set null,
  removed_at timestamptz,
  removal_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tournament_squad_members_status_check
    check (membership_status in ('active', 'removed')),
  constraint tournament_squad_members_removal_reason_check
    check (removal_reason is null or length(removal_reason) <= 500),
  constraint tournament_squad_members_removed_consistency
    check (membership_status != 'removed' or removed_at is not null)
);

-- Partial unique index 1: Unique active player per entry squad
create unique index if not exists idx_tournament_squad_entry_user
  on public.tournament_squad_members (entry_id, user_id)
  where membership_status = 'active';

-- Partial unique index 2: One person / one active entry default per tournament
create unique index if not exists idx_tournament_squad_tournament_user
  on public.tournament_squad_members (tournament_id, user_id)
  where membership_status = 'active';

-- Fast lookup indexes
create index if not exists idx_tournament_squad_entry
  on public.tournament_squad_members (entry_id);

create index if not exists idx_tournament_squad_tournament
  on public.tournament_squad_members (tournament_id);

create index if not exists idx_tournament_squad_user
  on public.tournament_squad_members (user_id);

-- Trigger: enforce squad eligibility and tournament foreign-key consistency
create or replace function public.enforce_tournament_squad_member_eligibility()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_entry_tournament_id uuid;
  v_team_id uuid;
  v_squad_state public.tournament_squad_state;
  v_is_team_member boolean;
begin
  -- 1. Ensure tournament_id matches entry's tournament_id
  select tournament_id, team_id, squad_state
    into v_entry_tournament_id, v_team_id, v_squad_state
    from public.tournament_entries
   where entry_id = new.entry_id;

  if not found then
    raise exception 'Tournament entry % not found', new.entry_id
      using errcode = 'P0002';
  end if;

  if new.tournament_id is distinct from v_entry_tournament_id then
    new.tournament_id := v_entry_tournament_id;
  end if;

  -- 2. On new active insertion, check squad is editable unless caller is organizer
  if (tg_op = 'INSERT' or (tg_op = 'UPDATE' and old.membership_status = 'removed' and new.membership_status = 'active')) then
    if v_squad_state = 'frozen' and not public.is_tournament_organizer(v_entry_tournament_id) then
      raise exception 'Cannot add player: squad is frozen for this tournament entry'
        using errcode = '22000';
    end if;

    -- 3. Verify user is on the team's global roster
    select exists (
      select 1 from public.team_members
       where team_id = v_team_id
         and user_id = new.user_id
    ) into v_is_team_member;

    if not v_is_team_member then
      raise exception 'Player % is not a registered member of team %', new.user_id, v_team_id
        using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_tournament_squad_members_eligibility on public.tournament_squad_members;
create trigger trg_tournament_squad_members_eligibility
  before insert or update of entry_id, user_id, membership_status
  on public.tournament_squad_members
  for each row
  execute function public.enforce_tournament_squad_member_eligibility();

-- Trigger: set updated_at
drop trigger if exists trg_tournament_squad_members_set_updated_at on public.tournament_squad_members;
create trigger trg_tournament_squad_members_set_updated_at
  before update on public.tournament_squad_members
  for each row
  execute function public.set_updated_at();

-- RLS Security Policies
alter table public.tournament_squad_members enable row level security;

-- Read policy: Public if tournament is public, or organizers, or team managers
drop policy if exists "tournament_squad_members_read" on public.tournament_squad_members;
create policy "tournament_squad_members_read"
  on public.tournament_squad_members
  for select
  to anon, authenticated
  using (
    public.is_tournament_organizer(tournament_id)
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_squad_members.entry_id
         and public.is_team_manager(e.team_id)
    )
    or exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_squad_members.tournament_id
         and t.privacy = 'public'::tournament_privacy
    )
  );

-- Insert policy: Team Manager while entry squad is editable, or Tournament Organizer
drop policy if exists "tournament_squad_members_insert" on public.tournament_squad_members;
create policy "tournament_squad_members_insert"
  on public.tournament_squad_members
  for insert
  to authenticated
  with check (
    public.is_tournament_organizer(tournament_id)
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_squad_members.entry_id
         and public.is_team_manager(e.team_id)
         and e.squad_state = 'editable'::public.tournament_squad_state
    )
  );

-- Update policy: Team Manager while entry squad is editable, or Tournament Organizer
drop policy if exists "tournament_squad_members_update" on public.tournament_squad_members;
create policy "tournament_squad_members_update"
  on public.tournament_squad_members
  for update
  to authenticated
  using (
    public.is_tournament_organizer(tournament_id)
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_squad_members.entry_id
         and public.is_team_manager(e.team_id)
    )
  )
  with check (
    public.is_tournament_organizer(tournament_id)
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_squad_members.entry_id
         and public.is_team_manager(e.team_id)
         and e.squad_state = 'editable'::public.tournament_squad_state
    )
  );
