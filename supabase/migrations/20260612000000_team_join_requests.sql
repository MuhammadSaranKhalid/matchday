-- =============================================================================
-- 0612 · team_join_requests (Player -> Team join request flow)
-- =============================================================================
-- Allows authenticated players to request to join a public or searchable team.
-- The team managers see these in the Requests tab of Team Management and can
-- approve (adds player to team_members) or decline them.

create table public.team_join_requests (
  request_id   uuid primary key default gen_random_uuid(),
  team_id      uuid not null references public.teams(team_id) on delete cascade,
  player_id    uuid not null references public.profiles(user_id) on delete cascade,
  role         public.member_role not null default 'player',
  message      text check (message is null or length(message) <= 500),
  status       public.request_status not null default 'pending',
  decided_by   uuid references public.profiles(user_id) on delete set null,
  decided_at   timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint join_request_decision_consistency check (
    (status = 'pending' and decided_by is null and decided_at is null)
    or (status in ('approved', 'rejected') and decided_at is not null)
    or (status = 'cancelled')
  )
);

create unique index team_join_requests_one_pending
  on public.team_join_requests (team_id, player_id)
  where status = 'pending';

create index team_join_requests_team   on public.team_join_requests (team_id);
create index team_join_requests_player on public.team_join_requests (player_id);

create trigger team_join_requests_set_updated_at
  before update on public.team_join_requests
  for each row execute function public.set_updated_at();

-- RLS
alter table public.team_join_requests enable row level security;

-- `(select auth.uid())` rather than a bare `auth.uid()`: wrapping it in a
-- subquery makes the planner treat it as an InitPlan and evaluate it ONCE per
-- statement instead of once per row (Supabase advisor 0003). Same for the
-- is_team_manager() SECURITY DEFINER call. Every other policy in this schema
-- already used the wrapped form; these three were the stragglers.
create policy team_join_requests_read on public.team_join_requests
  for select to authenticated
  using (
    player_id = (select auth.uid())
    or (select public.is_team_manager(team_id))
  );

create policy team_join_requests_insert on public.team_join_requests
  for insert to authenticated
  with check (
    player_id = (select auth.uid())
  );

-- WITH CHECK is not optional on an UPDATE policy. USING decides which rows you
-- may target; WITH CHECK decides what the row is allowed to look like
-- afterwards. Without it a player could pass the USING test on their own
-- request and then rewrite player_id or team_id to anything at all.
create policy team_join_requests_update on public.team_join_requests
  for update to authenticated
  using (
    player_id = (select auth.uid())
    or (select public.is_team_manager(team_id))
  )
  with check (
    player_id = (select auth.uid())
    or (select public.is_team_manager(team_id))
  );

-- RPC to request joining a team
create or replace function public.request_to_join_team(
  p_team_id uuid,
  p_role public.member_role default 'player',
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_request_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if exists (
    select 1 from public.team_members
     where team_id = p_team_id and user_id = v_uid and status = 'active'
  ) then
    raise exception 'Already a member of this team' using errcode = '23505';
  end if;

  insert into public.team_join_requests (team_id, player_id, role, message)
  values (p_team_id, v_uid, coalesce(p_role, 'player'), p_message)
  returning request_id into v_request_id;

  return v_request_id;
end;
$$;

-- RPC for team manager to accept join request
create or replace function public.accept_team_join_request(
  p_request_id uuid,
  p_jersey_number integer default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_team_id       uuid;
  v_player_id     uuid;
  v_role          public.member_role;
  v_membership_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select team_id, player_id, role
    into v_team_id, v_player_id, v_role
    from public.team_join_requests
   where request_id = p_request_id and status = 'pending'
   for update;

  if v_team_id is null then
    raise exception 'Join request not found or not pending' using errcode = 'P0002';
  end if;

  if not public.is_team_manager(v_team_id) then
    raise exception 'Only team managers can approve join requests' using errcode = '42501';
  end if;

  insert into public.team_members (team_id, user_id, role, jersey_number, added_by)
  values (v_team_id, v_player_id, coalesce(v_role, 'player'), p_jersey_number, v_uid)
  returning membership_id into v_membership_id;

  update public.team_join_requests
     set status = 'approved',
         decided_by = v_uid,
         decided_at = now()
   where request_id = p_request_id;

  return v_membership_id;
end;
$$;

-- RPC for team manager to decline join request
create or replace function public.decline_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid     uuid := auth.uid();
  v_team_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select team_id into v_team_id
    from public.team_join_requests
   where request_id = p_request_id and status = 'pending';

  if v_team_id is null then
    raise exception 'Join request not found or not pending' using errcode = 'P0002';
  end if;

  if not public.is_team_manager(v_team_id) then
    raise exception 'Only team managers can decline join requests' using errcode = '42501';
  end if;

  update public.team_join_requests
     set status = 'rejected',
         decided_by = v_uid,
         decided_at = now()
   where request_id = p_request_id;
end;
$$;

grant execute on function public.request_to_join_team(uuid, public.member_role, text) to authenticated;
grant execute on function public.accept_team_join_request(uuid, integer) to authenticated;
grant execute on function public.decline_team_join_request(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_team_join_requests_decided_by
  on public.team_join_requests (decided_by);
