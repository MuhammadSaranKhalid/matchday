-- =============================================================================
-- Migration: 20260101000230_claim_requests.sql
-- =============================================================================

-- 0230 · claim_requests
-- Spec §2.6 Path B — player-initiated claim of an unclaimed_players row.
--
-- Path A (manager-initiated invite) does NOT use this table. The manager
-- links the unclaimed row to a real user_id directly via UPDATE and the
-- cascade trigger (0210) does the rewrite.
--
-- Path B flow:
--   1. New user installs the app, finds an old scorebook with their name on
--      it as an unclaimed_players row.
--   2. They INSERT a claim_request: requester_id = self, unclaimed_id =
--      target. RLS allows this for any authenticated user.
--   3. The manager who originally added the placeholder (added_by on the
--      unclaimed_players row) sees it in their approvals queue (RLS:
--      is_unclaimed_owner predicate from 0120).
--   4. Manager approves via approve_claim_request(request_id) RPC. The RPC:
--        a. Sets unclaimed_players.claimed_by_user_id = requester_id.
--        b. Triggers cascade_unclaimed_claim (defined in 0210) which
--           rewrites all team_members rows + calls migrate_player_stats.
--        c. Marks the claim_request status='approved'.
--   5. Reject:  manager UPDATEs status='rejected' directly (RLS allows it).
--   6. Cancel:  requester UPDATEs status='cancelled' directly.
--
-- Unique partial index keeps one pending claim per (unclaimed, requester).
-- After a reject the requester can try again.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.claim_requests (
  request_id   uuid primary key default gen_random_uuid(),
  unclaimed_id uuid not null
    references public.unclaimed_players (unclaimed_id)
    on delete cascade,
  requester_id uuid not null
    references public.profiles (user_id)
    on delete cascade,
  message      text check (message is null or length(message) <= 500),
  status       public.request_status not null default 'pending',
  decided_by   uuid
    references public.profiles (user_id)
    on delete set null,
  decided_at   timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint claim_request_decision_consistency
    check (
      (status = 'pending' and decided_by is null and decided_at is null)
      or (status in ('approved', 'rejected') and decided_at is not null)
      or (status = 'cancelled')
    )
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create unique index claim_requests_one_pending
  on public.claim_requests (
    unclaimed_id,
    requester_id
  )
  where status = 'pending';

create index claim_requests_unclaimed
  on public.claim_requests (unclaimed_id);

create index claim_requests_requester
  on public.claim_requests (requester_id);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger claim_requests_set_updated_at
  before update on public.claim_requests
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- approve_claim_request — atomic approval RPC.
-- Updates two tables; relies on the cascade trigger from 0210 to rewrite
-- team_members and call the stat-migration stub.
create or replace function public.approve_claim_request(
  p_request_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_unclaimed_id uuid;
  v_requester_id uuid;
  v_added_by uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select
    cr.unclaimed_id,
    cr.requester_id,
    up.added_by
  into v_unclaimed_id, v_requester_id, v_added_by
  from
    public.claim_requests cr
    join public.unclaimed_players up on up.unclaimed_id = cr.unclaimed_id
  where cr.request_id = p_request_id and cr.status = 'pending'
  for update;
  if v_unclaimed_id is null then
    raise exception 'Claim request not found or not pending' using errcode = 'P0002';
  end if;
  if v_added_by <> v_uid then
    raise exception 'Only the manager who added this player can approve'
      using errcode = '42501';
  end if;
  -- Setting claimed_by_user_id fires cascade_unclaimed_claim (0210), which
  -- rewrites team_members and calls migrate_player_stats.
  update public.unclaimed_players
  set claimed_by_user_id = v_requester_id
  where unclaimed_id = v_unclaimed_id;
  update public.claim_requests
  set
    status = 'approved',
    decided_by = v_uid,
    decided_at = now()
  where request_id = p_request_id;
end;
$$;

revoke all on function public.approve_claim_request(uuid) from public;

grant execute on function public.approve_claim_request(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- RLS:
--   - read:    requester OR the manager who added the unclaimed row.
--   - insert:  requester only.
--   - update:  requester (cancel-own) OR unclaimed-owner (approve/reject).
alter table public.claim_requests enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "claim_requests_read_self_or_owner"
  on public.claim_requests
  for select
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = requester_id
    or public.is_unclaimed_owner(unclaimed_id)
  );

create policy "claim_requests_insert_self"
  on public.claim_requests
  for insert
  to authenticated
  with check (
    (
      select
        auth.uid()
    ) = requester_id
  );

create policy "claim_requests_update_self_or_owner"
  on public.claim_requests
  for update
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = requester_id
    or public.is_unclaimed_owner(unclaimed_id)
  )
  with check (
    (
      select
        auth.uid()
    ) = requester_id
    or public.is_unclaimed_owner(unclaimed_id)
  );

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.
create index if not exists idx_claim_requests_decided_by
  on public.claim_requests (
    decided_by
  );
