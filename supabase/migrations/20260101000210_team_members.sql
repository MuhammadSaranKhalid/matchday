-- =============================================================================
-- 0210 · team_members
-- =============================================================================
-- Spec §2.4, §2.6, §2.9. Memberships connecting users (or unclaimed
-- placeholders) to teams.
--
-- Polymorphic player reference:
--   Each row references EITHER profiles.user_id OR unclaimed_players.unclaimed_id,
--   never both, never neither. Postgres can't express a polymorphic FK so we
--   keep two real FKs and a CHECK constraint (`player_ref_xor`).
--
-- Lifecycle:
--   - Manager INSERTs a row (RLS: must call `is_team_manager`).
--   - Player can voluntarily leave only via the `leave_team()` RPC — direct
--     UPDATE is forbidden by RLS so no one can flip another player's status.
--   - Manager removes via direct UPDATE (status='removed', left_at=now()).
--
-- Claim cascade (the unclaimed → real-user merge):
--   When unclaimed_players.claimed_by_user_id is set (Path A or via
--   approve_claim_request from 0230), the AFTER-UPDATE trigger
--   `cascade_unclaimed_claim` rewrites this table:
--       UPDATE team_members
--          SET user_id = <new claimer>, unclaimed_id = null
--        WHERE unclaimed_id = <claimed placeholder> AND status='active';
--   Then it calls migrate_player_stats() (stub today, real in Stage W6+).
--   This is why the trigger lives here, not in 0120 — it has to query this
--   table.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Membership-only enums.
-- -----------------------------------------------------------------------------
create type public.member_role as enum (
  'captain',
  'vice_captain',
  'wicket_keeper',
  'player'
);
create type public.member_status as enum ('active', 'inactive', 'removed');

-- -----------------------------------------------------------------------------
-- team_members table.
-- -----------------------------------------------------------------------------
create table public.team_members (
  membership_id    uuid primary key default gen_random_uuid(),
  team_id          uuid not null
                       references public.teams(team_id) on delete cascade,
  user_id          uuid references public.profiles(user_id) on delete cascade,
  unclaimed_id     uuid references public.unclaimed_players(unclaimed_id) on delete cascade,
  jersey_number    integer
                    check (jersey_number is null or jersey_number between 0 and 999),
  role             public.member_role not null default 'player',
  joined_at        timestamptz not null default now(),
  left_at          timestamptz,
  status           public.member_status not null default 'active',
  added_by         uuid not null
                       references public.profiles(user_id) on delete restrict,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- Exactly one of (user_id, unclaimed_id) must be set.
  constraint player_ref_xor check (num_nonnulls(user_id, unclaimed_id) = 1),
  -- left_at must be set whenever status leaves 'active'.
  constraint left_at_for_inactive check (
    (status = 'active' and left_at is null)
    or (status in ('inactive', 'removed') and left_at is not null)
  )
);

-- -----------------------------------------------------------------------------
-- Indexes
--   * Two partial unique indexes — one per "namespace" of player ref —
--     enforce "one active membership per (team, player)".
--   * Jersey number is unique within a team for active members only.
-- -----------------------------------------------------------------------------
create unique index team_members_unique_active_user
  on public.team_members (team_id, user_id)
  where status = 'active' and user_id is not null;

create unique index team_members_unique_active_unclaimed
  on public.team_members (team_id, unclaimed_id)
  where status = 'active' and unclaimed_id is not null;

create unique index team_members_unique_jersey
  on public.team_members (team_id, jersey_number)
  where status = 'active' and jersey_number is not null;

create index team_members_team       on public.team_members (team_id);
create index team_members_user       on public.team_members (user_id)
  where user_id is not null;
create index team_members_unclaimed  on public.team_members (unclaimed_id)
  where unclaimed_id is not null;

create trigger team_members_set_updated_at
  before update on public.team_members
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- cascade_unclaimed_claim — fired when unclaimed_players.claimed_by_user_id
-- transitions null→non-null. Rewrites this table to point at the real user
-- and triggers stat migration.
-- -----------------------------------------------------------------------------
create or replace function public.cascade_unclaimed_claim()
returns trigger
language plpgsql
as $$
begin
  if new.claimed_by_user_id is not null
     and old.claimed_by_user_id is distinct from new.claimed_by_user_id then
    update public.team_members
       set user_id      = new.claimed_by_user_id,
           unclaimed_id = null
     where unclaimed_id = new.unclaimed_id
       and status = 'active';

    perform public.migrate_player_stats(new.unclaimed_id, new.claimed_by_user_id);
  end if;
  return new;
end;
$$;

create trigger unclaimed_players_cascade_claim
  after update on public.unclaimed_players
  for each row execute function public.cascade_unclaimed_claim();

-- -----------------------------------------------------------------------------
-- leave_team — spec §2.9 Flow 3.
-- The team_members RLS policy below denies users from updating their own row
-- (so a player can't unilaterally promote themselves to captain). This RPC
-- is the only path for self-leave; SECURITY DEFINER bypasses the policy and
-- constrains the change to status='inactive' + left_at=now().
-- -----------------------------------------------------------------------------
create or replace function public.leave_team(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid             uuid := auth.uid();
  v_member_user_id  uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select user_id
    into v_member_user_id
    from public.team_members
   where membership_id = p_membership_id and status = 'active'
   for update;
  if v_member_user_id is null or v_member_user_id <> v_uid then
    raise exception 'Cannot leave a membership that is not yours'
      using errcode = '42501';
  end if;
  update public.team_members
     set status  = 'inactive',
         left_at = now()
   where membership_id = p_membership_id;
end;
$$;

revoke all on function public.leave_team(uuid) from public;
grant execute on function public.leave_team(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS — public read; manager-only direct write. Self-leave is forbidden at
-- the policy level on purpose; users must call leave_team() instead.
-- -----------------------------------------------------------------------------
alter table public.team_members enable row level security;

create policy "team_members_read_public"
  on public.team_members for select
  using (true);

create policy "team_members_insert_managers"
  on public.team_members for insert
  to authenticated
  with check (public.is_team_manager(team_id) and (select auth.uid()) = added_by);

create policy "team_members_update_managers"
  on public.team_members for update
  to authenticated
  using (public.is_team_manager(team_id))
  with check (public.is_team_manager(team_id));

create policy "team_members_delete_managers"
  on public.team_members for delete
  to authenticated
  using (public.is_team_manager(team_id));
