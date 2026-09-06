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

-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.

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
  -- "Current club" — at most one active team per user can carry is_primary,
  -- enforced by the partial unique index below. Setting a new primary is the
  -- application's job (unset old + set new in one transaction); the DB only
  -- enforces the invariant.
  is_primary       boolean not null default false,
  -- Manager who added this membership. ON DELETE SET NULL so a deleted
  -- manager's account doesn't block; the membership row outlives them.
  -- Who added this member. NULL once that person deletes their account: this
  -- is an audit breadcrumb, not an owner, so the roster row must survive them.
  -- (20260609000000 set NOT NULL here, which contradicts ON DELETE SET NULL
  -- and made account deletion raise. Folded and corrected 2026-09-06.)
  added_by         uuid
                       references public.profiles(user_id) on delete set null,
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

-- At most one primary active team per user. Drops out of the constraint
-- automatically when the row becomes inactive/removed, so a new primary
-- can be chosen without manual cleanup.
create unique index team_members_unique_primary_per_user
  on public.team_members (user_id)
  where is_primary = true
    and status = 'active'
    and user_id is not null;

create index team_members_team       on public.team_members (team_id);
create index team_members_user       on public.team_members (user_id)
  where user_id is not null;
create index team_members_unclaimed  on public.team_members (unclaimed_id)
  where unclaimed_id is not null;

create trigger team_members_set_updated_at
  before update on public.team_members
  for each row execute function public.set_updated_at();

-- cascade_unclaimed_claim (the trigger function that flips team_members
-- rows from unclaimed_id → user_id when an unclaimed player claims a
-- profile) is declared by 0411_cascade_unclaimed_claim_extension.sql,
-- because the same function also rewrites match_players (created in
-- 0405). That file owns both the function and the AFTER UPDATE trigger
-- on unclaimed_players.

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
  to anon, authenticated
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


-- =============================================================================
-- unclaimed_player_contact_for_manager() — the one way to read the PII
-- =============================================================================
-- unclaimed_players.phone_number / email are revoked from anon and
-- authenticated at column level in 20260101000120 (they are contact details
-- for people who never signed up and never consented). This is the sanctioned
-- read: SECURITY DEFINER, and it re-checks that the caller actually manages a
-- team the placeholder plays for.
--
-- It lives here rather than with its table because it is `language sql` — body
-- checked at CREATE time — and it reads teams (0200) and team_members (this
-- file). At 0120 neither exists.
create or replace function public.unclaimed_player_contact_for_manager(
  p_unclaimed_id uuid
)
returns table (phone_number text, email text)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select u.phone_number, u.email
    from public.unclaimed_players u
   where u.unclaimed_id = p_unclaimed_id
     and (
       -- The manager who created the placeholder.
       u.added_by = auth.uid()
       -- Or an owner / manager / captain of a team the placeholder plays for.
       or exists (
         select 1
           from public.team_members tm
           join public.teams t on t.team_id = tm.team_id
          where tm.unclaimed_id = u.unclaimed_id
            and tm.status = 'active'
            and (
              t.owner_id = auth.uid()
              or auth.uid() = any(t.managers)
              or exists (
                select 1 from public.team_members me
                 where me.team_id = t.team_id
                   and me.user_id = auth.uid()
                   and me.status  = 'active'
                   and me.role in ('captain', 'vice_captain')
              )
            )
       )
     );
$$;

revoke all on function public.unclaimed_player_contact_for_manager(uuid) from public;
grant execute on function public.unclaimed_player_contact_for_manager(uuid)
  to authenticated;

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_team_members_added_by
  on public.team_members (added_by);
