-- 20261001000220_tournament_squad_members.sql
-- Canonical Tournament Squad Members
-- Clean Architecture Step 6 / Phase 3.1

create table if not exists public.tournament_squad_members (
  squad_member_id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.tournament_entries(entry_id) on delete cascade,
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  user_id uuid references public.profiles(user_id) on delete set null,
  unclaimed_id uuid references public.unclaimed_players(unclaimed_id) on delete set null,
  membership_status text not null default 'active',
  added_by uuid references public.profiles(user_id) on delete set null,
  added_at timestamptz not null default now(),
  removed_by uuid references public.profiles(user_id) on delete set null,
  removed_at timestamptz,
  removal_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- XOR identity integrity: active members must reference either user_id OR unclaimed_id.
  -- Removed historical records may have both null if the identity was anonymized/deleted.
  constraint tournament_squad_members_identity_xor
    check (
      (membership_status = 'active' and num_nonnulls(user_id, unclaimed_id) = 1)
      or (membership_status = 'removed' and num_nonnulls(user_id, unclaimed_id) <= 1)
    ),
  constraint tournament_squad_members_status_check
    check (membership_status in ('active', 'removed')),
  constraint tournament_squad_members_removal_reason_check
    check (removal_reason is null or length(removal_reason) <= 500),
  constraint tournament_squad_members_removed_consistency
    check (membership_status != 'removed' or removed_at is not null)
);

-- Ensure unclaimed_id and XOR constraint exist for existing tables
alter table public.tournament_squad_members
  add column if not exists unclaimed_id uuid references public.unclaimed_players(unclaimed_id) on delete set null;

do $$ begin
  alter table public.tournament_squad_members drop constraint if exists tournament_squad_members_identity_xor;
  alter table public.tournament_squad_members
    add constraint tournament_squad_members_identity_xor
    check (
      (membership_status = 'active' and num_nonnulls(user_id, unclaimed_id) = 1)
      or (membership_status = 'removed' and num_nonnulls(user_id, unclaimed_id) <= 1)
    );
exception when others then null;
end $$;

-- Partial unique indexes 1: Unique active player per entry squad
create unique index if not exists idx_tournament_squad_entry_user
  on public.tournament_squad_members (entry_id, user_id)
  where membership_status = 'active' and user_id is not null;

create unique index if not exists idx_tournament_squad_entry_unclaimed
  on public.tournament_squad_members (entry_id, unclaimed_id)
  where membership_status = 'active' and unclaimed_id is not null;

-- Partial unique indexes 2: One person / one active entry default per tournament
create unique index if not exists idx_tournament_squad_tournament_user
  on public.tournament_squad_members (tournament_id, user_id)
  where membership_status = 'active' and user_id is not null;

create unique index if not exists idx_tournament_squad_tournament_unclaimed
  on public.tournament_squad_members (tournament_id, unclaimed_id)
  where membership_status = 'active' and unclaimed_id is not null;

-- Fast lookup indexes
create index if not exists idx_tournament_squad_entry
  on public.tournament_squad_members (entry_id);

create index if not exists idx_tournament_squad_tournament
  on public.tournament_squad_members (tournament_id);

create index if not exists idx_tournament_squad_user
  on public.tournament_squad_members (user_id);

create index if not exists idx_tournament_squad_unclaimed
  on public.tournament_squad_members (unclaimed_id);

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
  v_entry_status public.tournament_entry_status;
  v_is_team_member boolean;
begin
  -- Skip runtime checks during one-time migration backfill
  if current_setting('matchday.migration_backfill', true) = 'true' then
    return new;
  end if;

  -- 1. Ensure tournament_id matches entry's tournament_id
  select tournament_id, team_id, squad_state, status
    into v_entry_tournament_id, v_team_id, v_squad_state, v_entry_status
    from public.tournament_entries
   where entry_id = new.entry_id;

  if not found then
    raise exception 'Tournament entry % not found', new.entry_id
      using errcode = 'P0002';
  end if;

  if new.tournament_id is distinct from v_entry_tournament_id then
    new.tournament_id := v_entry_tournament_id;
  end if;

  -- 2. On new active insertion, entry must be active and squad must be editable
  if (tg_op = 'INSERT' or (tg_op = 'UPDATE' and old.membership_status = 'removed' and new.membership_status = 'active')) then
    if v_entry_status != 'active' then
      raise exception 'Cannot add player: tournament entry is not active (status: %)', v_entry_status
        using errcode = '22000';
    end if;

    if v_squad_state = 'frozen' then
      raise exception 'Cannot add player: squad is frozen for this tournament entry'
        using errcode = '22000';
    end if;

    -- 3. Verify player is on the team's active global roster
    if new.user_id is not null then
      select exists (
        select 1 from public.team_members
         where team_id = v_team_id
           and user_id = new.user_id
           and status = 'active'
      ) into v_is_team_member;

      if not v_is_team_member then
        raise exception 'Claimed player % is not an active member of team %', new.user_id, v_team_id
          using errcode = '22000';
      end if;
    elsif new.unclaimed_id is not null then
      select exists (
        select 1 from public.team_members
         where team_id = v_team_id
           and unclaimed_id = new.unclaimed_id
           and status = 'active'
      ) into v_is_team_member;

      if not v_is_team_member then
        raise exception 'Unclaimed player % is not an active member of team %', new.unclaimed_id, v_team_id
          using errcode = '22000';
      end if;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_tournament_squad_member_eligibility() from public;

drop trigger if exists trg_tournament_squad_members_eligibility on public.tournament_squad_members;
create trigger trg_tournament_squad_members_eligibility
  before insert or update of entry_id, user_id, unclaimed_id, membership_status
  on public.tournament_squad_members
  for each row
  execute function public.enforce_tournament_squad_member_eligibility();

-- Trigger: Account deletion anonymization
-- When user profile or unclaimed placeholder is deleted, nulling user_id / unclaimed_id,
-- the squad member transitions to 'removed' with timestamp and audit reason.
create or replace function public.tournament_squad_members_anonymize_on_delete()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if (old.user_id is not null and new.user_id is null and new.membership_status = 'active')
     or (old.unclaimed_id is not null and new.unclaimed_id is null and new.membership_status = 'active') then
    update public.tournament_squad_members
       set membership_status = 'removed',
           removed_at = coalesce(removed_at, now()),
           removal_reason = coalesce(removal_reason, 'Player account or profile deleted'),
           updated_at = now()
     where squad_member_id = new.squad_member_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_tournament_squad_members_anonymize_on_delete on public.tournament_squad_members;
create trigger trg_tournament_squad_members_anonymize_on_delete
  after update
  on public.tournament_squad_members
  for each row
  execute function public.tournament_squad_members_anonymize_on_delete();

-- Trigger: When unclaimed player record is deleted, transition active squad membership to removed
create or replace function public.tournament_squad_unclaimed_anonymize_on_delete()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.tournament_squad_members
     set membership_status = 'removed',
         removed_at = coalesce(removed_at, now()),
         removal_reason = coalesce(removal_reason, 'Unclaimed player deleted / anonymized'),
         updated_at = now()
   where unclaimed_id = old.unclaimed_id
     and membership_status = 'active';
  return old;
end;
$$;

drop trigger if exists trg_tournament_squad_unclaimed_anonymize on public.unclaimed_players;
create trigger trg_tournament_squad_unclaimed_anonymize
  before delete on public.unclaimed_players
  for each row
  execute function public.tournament_squad_unclaimed_anonymize_on_delete();

-- Trigger: Claim propagation from unclaimed_players to tournament_squad_members
create or replace function public.tournament_squad_claim_unclaimed()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.claimed_by_user_id is null and new.claimed_by_user_id is not null then
    -- Guard: verify the claiming user is not already active in another entry for the same tournament
    if exists (
      select 1
        from public.tournament_squad_members tsm_unclaimed
        join public.tournament_squad_members tsm_claimed
          on tsm_claimed.tournament_id = tsm_unclaimed.tournament_id
         and tsm_claimed.entry_id != tsm_unclaimed.entry_id
         and tsm_claimed.user_id = new.claimed_by_user_id
         and tsm_claimed.membership_status = 'active'
       where tsm_unclaimed.unclaimed_id = new.unclaimed_id
         and tsm_unclaimed.membership_status = 'active'
    ) then
      raise exception 'Claim would violate one-person one-active-entry rule in a tournament'
        using errcode = '23514';
    end if;

    -- Update tournament squad rows to point to claimed user_id
    update public.tournament_squad_members
       set user_id = new.claimed_by_user_id,
           unclaimed_id = null,
           updated_at = now()
     where unclaimed_id = new.unclaimed_id;
  end if;
  return new;
end;
$$;

revoke all on function public.tournament_squad_claim_unclaimed() from public;

drop trigger if exists trg_tournament_squad_claim_unclaimed on public.unclaimed_players;
create trigger trg_tournament_squad_claim_unclaimed
  after update of claimed_by_user_id
  on public.unclaimed_players
  for each row
  when (old.claimed_by_user_id is null and new.claimed_by_user_id is not null)
  execute function public.tournament_squad_claim_unclaimed();

-- Trigger: set updated_at
drop trigger if exists trg_tournament_squad_members_set_updated_at on public.tournament_squad_members;
create trigger trg_tournament_squad_members_set_updated_at
  before update on public.tournament_squad_members
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS Security Policies
-- -----------------------------------------------------------------------------
alter table public.tournament_squad_members enable row level security;

-- Read policy: Tournament staff with squad review capability or Team authority of the entry
drop policy if exists "tournament_squad_members_read" on public.tournament_squad_members;
create policy "tournament_squad_members_read"
  on public.tournament_squad_members
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.squad.review')
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_squad_members.entry_id
         and (
           public.can('team', e.team_id, 'team.tournament.squad.manage')
           or public.can('team', e.team_id, 'team.tournament.enter')
         )
    )
  );

-- Direct client INSERT, UPDATE, DELETE are blocked to eliminate audit forgery.
-- Mutations route through server-stamped RPCs:
-- tournament_squad_add_member, tournament_squad_remove_member, approve_tournament_registration.
drop policy if exists "tournament_squad_members_no_direct_insert" on public.tournament_squad_members;
create policy "tournament_squad_members_no_direct_insert"
  on public.tournament_squad_members
  for insert
  to authenticated
  with check (false);

drop policy if exists "tournament_squad_members_no_direct_update" on public.tournament_squad_members;
create policy "tournament_squad_members_no_direct_update"
  on public.tournament_squad_members
  for update
  to authenticated
  using (false)
  with check (false);

drop policy if exists "tournament_squad_members_no_direct_delete" on public.tournament_squad_members;
create policy "tournament_squad_members_no_direct_delete"
  on public.tournament_squad_members
  for delete
  to authenticated
  using (false);
