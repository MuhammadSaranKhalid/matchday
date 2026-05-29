-- =============================================================================
-- 0240 · team_invites
-- =============================================================================
-- Spec §2.9. Manager-initiated "invite a registered user to join a team".
-- This is the only roster-add path in v1.0 — the inverse direction
-- (player → team join requests) was removed as redundant.
--
-- Direction:
--   Team ────► Player
--    inviter    invitee
--   manager     decides
--
-- Lifecycle:
--   1. Manager INSERTs from the Add Member → Find user flow (RLS: only allowed
--      when the caller is a manager of the team).
--   2. Trigger pushes a 'team_invitation' notification to the invitee. The bell
--      badge updates live via the notifications realtime publication.
--   3. Decision:
--        - accept:  accept_team_invite(invite_id) RPC. Atomically inserts
--                   the team_members row + flips status → 'approved'.
--        - decline: invitee UPDATEs status='rejected' directly (RLS allows).
--        - cancel:  inviter (any team manager) UPDATEs status='cancelled'.
--   4. The 'request_status' enum is reused (pending|approved|rejected|cancelled);
--      the API layer maps approved→accepted and rejected→declined for clarity.
--
-- Single-pending invariant:
--   `team_invites_one_pending` keeps a manager from spamming invites at the
--   same user. Resending after a decline/cancel is fine — only pending is unique.
-- =============================================================================

create table public.team_invites (
  invite_id     uuid primary key default gen_random_uuid(),
  team_id       uuid not null
                    references public.teams(team_id) on delete cascade,
  -- The user being invited. They make the accept/decline decision.
  invitee_id    uuid not null
                    references public.profiles(user_id) on delete cascade,
  -- The manager who sent the invite. Captured for audit + notification payload.
  invited_by    uuid not null
                    references public.profiles(user_id) on delete cascade,
  message       text check (message is null or length(message) <= 500),
  -- Pre-set role + jersey: when the manager already knows where the invitee
  -- fits. If null, accept_team_invite uses sensible defaults.
  role          public.member_role default 'player',
  jersey_number integer,
  -- request_status enum lives in 0000_shared_helpers.
  status        public.request_status not null default 'pending',
  decided_by    uuid references public.profiles(user_id) on delete set null,
  decided_at    timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  -- Decision metadata is set together with the status flip; cancellations
  -- (manager-initiated recall) don't require a decided_by since the actor is
  -- the same as invited_by.
  constraint invite_decision_consistency check (
    (status = 'pending'   and decided_by is null and decided_at is null)
    or (status in ('approved', 'rejected') and decided_at is not null)
    or (status = 'cancelled')
  )
);

create unique index team_invites_one_pending
  on public.team_invites (team_id, invitee_id)
  where status = 'pending';

create index team_invites_team    on public.team_invites (team_id);
create index team_invites_invitee on public.team_invites (invitee_id);

create trigger team_invites_set_updated_at
  before update on public.team_invites
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- accept_team_invite — atomic accept RPC.
-- Inserts the team_members row first, then marks the invite approved. Both
-- writes happen in a single transaction so a partial failure (e.g. a unique
-- constraint on jersey_number) leaves nothing behind.
-- -----------------------------------------------------------------------------
create or replace function public.accept_team_invite(p_invite_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_team_id       uuid;
  v_invitee_id    uuid;
  v_role          public.member_role;
  v_jersey        integer;
  v_invited_by    uuid;
  v_membership_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select team_id, invitee_id, role, jersey_number, invited_by
    into v_team_id, v_invitee_id, v_role, v_jersey, v_invited_by
    from public.team_invites
   where invite_id = p_invite_id and status = 'pending'
   for update;
  if v_team_id is null then
    raise exception 'Invite not found or not pending'
      using errcode = 'P0002';
  end if;
  if v_invitee_id <> v_uid then
    raise exception 'Only the invitee can accept this invite'
      using errcode = '42501';
  end if;

  insert into public.team_members
       (team_id, user_id, role,                          jersey_number, added_by)
  values (v_team_id, v_invitee_id, coalesce(v_role, 'player'), v_jersey,      v_invited_by)
  returning membership_id into v_membership_id;

  update public.team_invites
     set status     = 'approved',
         decided_by = v_uid,
         decided_at = now()
   where invite_id = p_invite_id;

  return v_membership_id;
end;
$$;

revoke all on function public.accept_team_invite(uuid) from public;
grant execute on function public.accept_team_invite(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- notify_on_team_invite — fan out a 'team_invitation' notification to the
-- invitee whenever a new invite is inserted. Mirrors notify_on_follow in
-- 0560_follows.sql.
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_team_invite()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notifications (recipient_id, type, payload)
  values (
    new.invitee_id,
    'team_invitation',
    jsonb_build_object(
      'invite_id',  new.invite_id,
      'team_id',    new.team_id,
      'actor_id',   new.invited_by
    )
  );
  return new;
end;
$$;

create trigger team_invites_notify
  after insert on public.team_invites
  for each row execute function public.notify_on_team_invite();

-- -----------------------------------------------------------------------------
-- RLS:
--   - read:   invitee or any manager of the team.
--   - insert: any manager of the team. Invites are the only roster-add path
--     in v1.0 (the player-initiated join_requests flow was removed as
--     redundant), so there's no toggle gating this.
--   - update: invitee (decline) OR manager (cancel). Accept rides the RPC
--     because it has to write to two tables atomically.
-- -----------------------------------------------------------------------------
alter table public.team_invites enable row level security;

create policy "team_invites_read_self_or_manager"
  on public.team_invites for select
  using ((select auth.uid()) = invitee_id or public.is_team_manager(team_id));

create policy "team_invites_insert_manager"
  on public.team_invites for insert
  to authenticated
  with check (
    public.is_team_manager(team_id)
    and (select auth.uid()) = invited_by
  );

create policy "team_invites_update_self_or_manager"
  on public.team_invites for update
  to authenticated
  using ((select auth.uid()) = invitee_id or public.is_team_manager(team_id))
  with check ((select auth.uid()) = invitee_id or public.is_team_manager(team_id));
