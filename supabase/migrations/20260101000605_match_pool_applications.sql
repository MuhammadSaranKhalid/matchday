-- =============================================================================
-- Migration: 20260101000605_match_pool_applications.sql
-- =============================================================================

-- 0605 · match_pool_applications

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table if not exists public.match_pool_applications (
  application_id      uuid primary key default gen_random_uuid(),
  request_id          uuid not null
    references public.match_challenges (request_id)
    on delete cascade,
  applicant_team_id   uuid not null
    references public.teams (team_id)
    on delete cascade,
  applicant_user_id   uuid not null
    references public.profiles (user_id)
    on delete cascade,
  applicant_xi        uuid[] default '{}'::uuid[],
  applicant_keeper_id uuid,
  message             text,
  status              text not null default 'pending' check (
    status in ('pending', 'accepted', 'rejected', 'withdrawn')
  ),
  decision_note       text,
  decided_at          timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists idx_match_pool_apps_request
  on public.match_pool_applications (
    request_id
  );

create index if not exists idx_match_pool_apps_applicant_team
  on public.match_pool_applications (
    applicant_team_id
  );

create index if not exists idx_match_pool_apps_status
  on public.match_pool_applications (
    status
  );

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- Enable RLS
alter table public.match_pool_applications enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

-- Drop any existing policies
drop policy if exists "match_pool_apps_select" on public.match_pool_applications;

-- Reads:
-- 1. Poster can view all applications for their open challenges.
-- 2. Applicant team managers can view their own applications.
create policy "match_pool_apps_select"
  on public.match_pool_applications
  for select
  to authenticated
  using (
    public.is_team_manager(applicant_team_id)
    or exists (
      select
        1
      from public.match_challenges mr
      where
        mr.request_id = match_pool_applications.request_id
        and public.is_team_manager(mr.from_team_id)
    )
  );

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- RPC: apply_to_match_pool
create or replace function public.apply_to_match_pool(
  p_request_id uuid,
  p_applicant_team_id uuid,
  p_applicant_xi uuid[] default '{}'::uuid[],
  p_applicant_keeper_id uuid default null,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req public.match_challenges%rowtype;
  v_app_id uuid;
  v_applicant_name text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;
  if not public.is_team_manager(p_applicant_team_id) then
    raise exception 'You can only apply on behalf of teams you manage'
      using errcode = '42501';
  end if;
  select
    *
  into
    v_req
  from
    public.match_challenges
  where
    request_id = p_request_id for share;
  if not found then
    raise exception 'Match request not found'
      using errcode = 'P0002';
  end if;
  if v_req.to_team_id is not null then
    raise exception 'This is a direct 1-to-1 challenge, not an open pool post'
      using errcode = '22023';
  end if;
  if v_req.status != 'pending' then
    raise exception 'This open match request is no longer accepting applications (status: %)', v_req.status
      using errcode = '22023';
  end if;
  if v_req.from_team_id = p_applicant_team_id then
    raise exception 'A team cannot apply to its own open challenge'
      using errcode = '23514';
  end if;
  -- Validate applicant squad members
  perform
    public._validate_team_xi(p_applicant_team_id, p_applicant_xi);
  -- Check if team has already applied and is pending
  if exists (
    select
      1
    from
      public.match_pool_applications
    where
      request_id = p_request_id
      and applicant_team_id = p_applicant_team_id
      and status = 'pending') then
  raise exception 'Your team has already applied to this open challenge'
    using errcode = '23505';
end if;
insert into public.match_pool_applications(request_id, applicant_team_id, applicant_user_id, applicant_xi, applicant_keeper_id, message, status)
  values (p_request_id, p_applicant_team_id, auth.uid(), coalesce(p_applicant_xi, '{}'::uuid[]), p_applicant_keeper_id, p_message, 'pending')
returning
  application_id
into
  v_app_id;
  -- Notify the host team's staff. The applicant's name is no longer looked up
  -- here: notify() resolves {{opponent_name}} from opponent_team_id, so the
  -- sentence lives in the catalogue instead of being concatenated into the
  -- payload as a 'message' key the client had to know to read.
  perform
    public.notify(array (
        select
          public.team_staff_ids(v_req.from_team_id)), 'match.application.received', jsonb_build_object('request_id', p_request_id, 'from_team_id', v_req.from_team_id, 'applicant_team_id', p_applicant_team_id, 'opponent_team_id', p_applicant_team_id, 'actor_id', auth.uid()), auth.uid(), 'team', v_req.from_team_id);
  return v_app_id;
end;
$$;

revoke all
on function public.apply_to_match_pool(uuid, uuid, uuid[], uuid, text)
from public;

grant execute
on function public.apply_to_match_pool(uuid, uuid, uuid[], uuid, text)
to authenticated;

-- RPC: accept_pool_application
create or replace function public.accept_pool_application(
  p_application_id uuid,
  p_decision_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app public.match_pool_applications%rowtype;
  v_req public.match_challenges%rowtype;
  v_match_id uuid;
  v_format jsonb;
  v_a_captain uuid;
  v_b_captain uuid;
  v_host_name text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;
  select
    *
  into
    v_app
  from
    public.match_pool_applications
  where
    application_id = p_application_id
  for update;
  if not found then
    raise exception 'Application not found'
      using errcode = 'P0002';
  end if;
  if v_app.status != 'pending' then
    raise exception 'Application is no longer pending (status: %)', v_app.status
      using errcode = '22023';
  end if;
  select
    *
  into
    v_req
  from
    public.match_challenges
  where
    request_id = v_app.request_id
  for update;
  if not found then
    raise exception 'Match request not found'
      using errcode = 'P0002';
  end if;
  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the host team can accept applications'
      using errcode = '42501';
  end if;
  if v_req.status != 'pending' then
    raise exception 'Open challenge is no longer active (status: %)', v_req.status
      using errcode = '22023';
  end if;
  -- Re-validate playing rosters
  perform
    public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform
    public._validate_team_xi(v_app.applicant_team_id, v_app.applicant_xi);
  v_a_captain := public._team_current_captain(v_req.from_team_id);
  v_b_captain := public._team_current_captain(v_app.applicant_team_id);
  if v_a_captain is null or v_b_captain is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;
  v_format := public._normalize_match_format(v_req.proposed_format);
  -- Insert match row
  insert into public.matches(match_type, tournament_id, team_a_id, team_b_id, format, venue, scheduled_start_time, status, created_by)
    values ('friendly', null, v_req.from_team_id, v_app.applicant_team_id, v_format, v_req.proposed_venue, v_req.proposed_start_time, 'scheduled', auth.uid())
  returning
    match_id
  into
    v_match_id;
  -- Cricket extension row.
  insert into public.cricket_matches(match_id, format_code, rules_snapshot)
    values (v_match_id, v_format ->> 'format_preset', v_format);
  -- Populate Team A match_players (sport-neutral identity)
  insert into public.match_players(match_id, team_side, user_id, unclaimed_id, display_name)
  select
    v_match_id,
    'team_a',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(p.display_name, u.display_name, 'Player')
  from
    public.team_members tm
    left join public.profiles p on p.user_id = tm.user_id
    left join public.unclaimed_players u on u.unclaimed_id = tm.unclaimed_id
  where
    tm.team_id = v_req.from_team_id
    and tm.status = 'active'
    and (coalesce(array_length(v_req.from_team_xi, 1), 0) = 0
      or tm.user_id = any (v_req.from_team_xi)
      or tm.unclaimed_id = any (v_req.from_team_xi));
  -- Populate Team B (Applicant) match_players (sport-neutral identity)
  insert into public.match_players(match_id, team_side, user_id, unclaimed_id, display_name)
  select
    v_match_id,
    'team_b',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(p.display_name, u.display_name, 'Player')
  from
    public.team_members tm
    left join public.profiles p on p.user_id = tm.user_id
    left join public.unclaimed_players u on u.unclaimed_id = tm.unclaimed_id
  where
    tm.team_id = v_app.applicant_team_id
    and tm.status = 'active'
    and (coalesce(array_length(v_app.applicant_xi, 1), 0) = 0
      or tm.user_id = any (v_app.applicant_xi)
      or tm.unclaimed_id = any (v_app.applicant_xi));
  -- Populate cricket_match_players with captain/keeper flags derived from
  -- v_a_captain / v_b_captain / keeper params.
  insert into public.cricket_match_players(match_player_id, match_id, is_captain, is_wicket_keeper)
  select
    mp.match_player_id,
    mp.match_id,
    coalesce(
      (mp.team_side = 'team_a' and mp.user_id = v_a_captain)
      or (mp.team_side = 'team_b' and mp.user_id = v_b_captain),
      false
    ),
    coalesce(
      mp.user_id      = v_req.from_team_keeper_id
      or mp.unclaimed_id = v_req.from_team_keeper_id
      or mp.user_id      = v_app.applicant_keeper_id
      or mp.unclaimed_id = v_app.applicant_keeper_id,
      false
    )
  from
    public.match_players mp
  where
    mp.match_id = v_match_id;
  -- Mark accepted application
  update
    public.match_pool_applications
  set
    status = 'accepted',
    decided_at = now(),
    decision_note = p_decision_note,
    updated_at = now()
  where
    application_id = p_application_id;
  -- Automatically reject all other pending applications for this challenge
  update
    public.match_pool_applications
  set
    status = 'rejected',
    decided_at = now(),
    decision_note = 'Another opponent was selected for this fixture',
    updated_at = now()
  where
    request_id = v_app.request_id
    and application_id != p_application_id
    and status = 'pending';
  -- Close the match_request
  update
    public.match_challenges
  set
    status = 'accepted',
    decided_by = auth.uid(),
    decided_at = now(),
    decision_note = p_decision_note,
    match_id = v_match_id,
    to_team_id = v_app.applicant_team_id
  where
    request_id = v_app.request_id;
  -- Notify the accepted team's staff. Host name comes from the catalogue via
  -- {{opponent_name}}, not from a concatenated 'message' payload key.
  perform
    public.notify(array (
        select
          public.team_staff_ids(v_app.applicant_team_id)), 'match.application.accepted', jsonb_build_object('request_id', v_app.request_id, 'match_id', v_match_id, 'host_team_id', v_req.from_team_id, 'opponent_team_id', v_req.from_team_id, 'actor_id', auth.uid()), auth.uid(), 'team', v_app.applicant_team_id);
  return v_match_id;
end;
$$;

revoke all on function public.accept_pool_application(uuid, text) from public;

grant execute on function public.accept_pool_application(uuid, text) to authenticated;

-- RPC: reject_pool_application
create or replace function public.reject_pool_application(
  p_application_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app public.match_pool_applications%rowtype;
  v_req public.match_challenges%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;
  select
    *
  into
    v_app
  from
    public.match_pool_applications
  where
    application_id = p_application_id
  for update;
  if not found then
    raise exception 'Application not found'
      using errcode = 'P0002';
  end if;
  select
    *
  into
    v_req
  from
    public.match_challenges
  where
    request_id = v_app.request_id;
  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the host team can reject applications'
      using errcode = '42501';
  end if;
  update
    public.match_pool_applications
  set
    status = 'rejected',
    decision_note = p_reason,
    decided_at = now(),
    updated_at = now()
  where
    application_id = p_application_id;
end;
$$;

revoke all on function public.reject_pool_application(uuid, text) from public;

grant execute on function public.reject_pool_application(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.
create index if not exists idx_match_pool_applications_applicant_user_id
  on public.match_pool_applications (
    applicant_user_id
  );
