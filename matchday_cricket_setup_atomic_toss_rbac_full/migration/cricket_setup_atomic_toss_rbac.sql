-- =============================================================================
-- Matchday · Cricket Setup Authority + Atomic Toss + RBAC Hard Cut
-- =============================================================================
--
-- MULTI-SPORT BOUNDARY
-- --------------------
-- public.matches         = sport-neutral sporting-event shell
-- public.match_teams     = sport-neutral competitor slots
-- public.cricket_matches = Cricket-only workflow/rules/result extension
--
-- Therefore the side that initially administers Cricket Match Start belongs in
-- cricket_matches.setup_side, NOT matches.
--
-- AUTHORIZATION BOUNDARY
-- ----------------------
-- matches.created_by         = audit/history only
-- cricket_matches.setup_side = Cricket domain ownership of initial setup
-- cricket.match.setup        = which authenticated users may perform setup
--
-- TOSS BOUNDARY
-- -------------
-- The physical toss is recorded atomically: winner + bat/bowl decision.
-- There is no application state where the winner is stored while Matchday
-- waits for the winning team to make a second digital decision.
-- =============================================================================


-- =============================================================================
-- 0. PREFLIGHT
-- =============================================================================

do $$
begin
  if to_regclass('public.matches') is null
     or to_regclass('public.match_teams') is null
     or to_regclass('public.cricket_matches') is null
  then
    raise exception
      'Canonical multi-sport match schema must be deployed before this migration.';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='matches'
      and column_name in ('team_a_id','team_b_id','winner_id')
  ) then
    raise exception
      'Legacy physical match team/winner columns still exist. Apply the canonical match_teams cutover first.';
  end if;
end
$$;


-- =============================================================================
-- 1. CRICKET-OWNED SETUP SIDE + TOSS ACTOR
-- =============================================================================

alter table public.cricket_matches
  add column if not exists setup_side text;

alter table public.cricket_matches
  add column if not exists toss_recorded_by uuid;

alter table public.cricket_matches
  drop constraint if exists cricket_matches_setup_side_check;

alter table public.cricket_matches
  add constraint cricket_matches_setup_side_check
  check (
    setup_side is null
    or setup_side in ('team_a','team_b')
  );

-- If the superseded generic host_side experiment was ever applied, preserve its
-- Cricket data before removing the generic column.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='matches'
      and column_name='host_side'
  ) then
    execute $sql$
      update public.cricket_matches cm
      set setup_side = m.host_side
      from public.matches m
      where m.match_id = cm.match_id
        and cm.setup_side is null
        and m.host_side is not null
    $sql$;
  end if;
end
$$;

-- Accepted direct/open challenges already encode the real initiating team.
update public.cricket_matches cm
set setup_side = mt.team_side
from public.match_challenges mc
join public.match_teams mt
  on mt.match_id = mc.match_id
 and mt.team_id = mc.from_team_id
where mc.match_id = cm.match_id
  and cm.setup_side is null;

-- Development fallback for pre-existing non-tournament Cricket fixtures that
-- have no challenge relation. Team A is only a fallback for old rows; all new
-- creation paths below set setup_side deliberately.
update public.cricket_matches cm
set setup_side = 'team_a'
from public.matches m
where m.match_id = cm.match_id
  and m.tournament_id is null
  and cm.setup_side is null
  and exists (
    select 1
    from public.match_teams mt
    where mt.match_id = m.match_id
      and mt.team_side = 'team_a'
      and mt.team_id is not null
  );

alter table public.cricket_matches
  drop constraint if exists cricket_matches_setup_side_fkey;

alter table public.cricket_matches
  add constraint cricket_matches_setup_side_fkey
  foreign key (match_id, setup_side)
  references public.match_teams(match_id, team_side)
  deferrable initially deferred;

alter table public.cricket_matches
  drop constraint if exists cricket_matches_toss_recorded_by_fkey;

alter table public.cricket_matches
  add constraint cricket_matches_toss_recorded_by_fkey
  foreign key (toss_recorded_by)
  references public.profiles(user_id)
  on delete set null;

comment on column public.cricket_matches.setup_side is
  'Cricket-only side responsible for initial peer-to-peer Match Start setup. Null is valid for neutral/tournament fixtures controlled by a match-scoped Cricket setup grant.';

comment on column public.cricket_matches.toss_recorded_by is
  'Authenticated user who entered the physical toss winner and the winner''s bat/bowl choice.';

create or replace function public.enforce_cricket_setup_side_immutability()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_status public.match_status;
begin
  if old.setup_side is distinct from new.setup_side then
    if old.setup_side is not null then
      raise exception 'Cricket setup_side is immutable once assigned'
        using errcode = '23514';
    end if;

    select m.status
      into v_status
    from public.matches m
    where m.match_id = new.match_id;

    if v_status <> 'scheduled'
       or old.phase <> 'toss'
    then
      raise exception
        'Cricket setup_side may only be assigned before the toss while the match is scheduled'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

revoke all
  on function public.enforce_cricket_setup_side_immutability()
  from public, anon, authenticated;

drop trigger if exists cricket_matches_setup_side_immutable
  on public.cricket_matches;

create trigger cricket_matches_setup_side_immutable
before update of setup_side
on public.cricket_matches
for each row
execute function public.enforce_cricket_setup_side_immutability();

-- Remove the superseded generic design if it exists.
drop trigger if exists matches_host_side_immutable
  on public.matches;

alter table public.matches
  drop constraint if exists matches_host_side_fkey;

alter table public.matches
  drop constraint if exists matches_host_side_check;

alter table public.matches
  drop column if exists host_side;

drop function if exists public.enforce_match_host_side_immutability();


-- =============================================================================
-- 2. HARD-CUT THE SETUP CAPABILITY TO A CRICKET-SPECIFIC PERMISSION
-- =============================================================================

insert into public.permissions (
  permission_key,
  resource,
  action,
  description,
  min_rank,
  direct_grantable,
  sort_order
)
values (
  'cricket.match.setup',
  'cricket_match',
  'setup',
  'Administer Cricket pre-match setup: record the toss, select opening batters, and start play',
  null,
  true,
  130
)
on conflict (permission_key) do update
set
  resource = excluded.resource,
  action = excluded.action,
  description = excluded.description,
  direct_grantable = excluded.direct_grantable,
  sort_order = excluded.sort_order;

insert into public.permission_scopes (
  permission_key,
  scope
)
values
  ('cricket.match.setup', 'team'),
  ('cricket.match.setup', 'match')
on conflict do nothing;

-- Preserve global defaults and any development per-team overrides before
-- deleting the old generic-looking key.
insert into public.role_permissions (
  team_id,
  scope,
  role_key,
  permission_key,
  granted,
  created_at
)
select
  rp.team_id,
  rp.scope,
  rp.role_key,
  'cricket.match.setup',
  rp.granted,
  rp.created_at
from public.role_permissions rp
where rp.permission_key = 'match.lineup.set'
  and rp.scope = 'team'
on conflict on constraint
  role_permissions_team_id_scope_role_key_permission_key_key
do update
set granted = excluded.granted;

-- If this database never had the old defaults, establish the intended Cricket
-- team matrix explicitly.
insert into public.role_permissions (
  team_id,
  scope,
  role_key,
  permission_key,
  granted
)
values
  (null, 'team', 'owner',   'cricket.match.setup', true),
  (null, 'team', 'manager', 'cricket.match.setup', true),
  (null, 'team', 'captain', 'cricket.match.setup', true)
on conflict on constraint
  role_permissions_team_id_scope_role_key_permission_key_key
do nothing;

-- Preserve any temporary direct grants if the superseded package was tried.
insert into public.grants (
  subject_id,
  scope,
  entity_id,
  permission_key,
  granted_by,
  expires_at,
  created_at
)
select
  g.subject_id,
  g.scope,
  g.entity_id,
  'cricket.match.setup',
  g.granted_by,
  g.expires_at,
  g.created_at
from public.grants g
where g.permission_key = 'match.lineup.set'
on conflict (
  subject_id,
  scope,
  entity_id,
  permission_key
) do update
set
  granted_by = excluded.granted_by,
  expires_at = excluded.expires_at;

-- No compatibility alias. This project has no released legacy client.
delete from public.permissions
where permission_key = 'match.lineup.set';


-- =============================================================================
-- 2b. MATCH OFFICIAL RLS USES THE GENERIC OFFICIAL-ASSIGN CAPABILITY
-- =============================================================================
--
-- The live policy currently calls is_team_captain(), but that helper is
-- misnamed: it simply delegates to the old match.lineup.set capability.
-- Official assignment is a separate generic concern and already has the
-- correct permission: match.official.assign.


drop policy if exists match_officials_write_organizers
  on public.match_officials;

create policy match_officials_write_organizers
on public.match_officials
for all
to authenticated
using (
  exists (
    select 1
    from public.matches m
    where m.match_id = match_officials.match_id
      and case
        when m.tournament_id is not null then
          public.is_tournament_organizer(m.tournament_id)
        else
          exists (
            select 1
            from public.match_teams mt
            where mt.match_id = m.match_id
              and mt.team_id is not null
              and public.can(
                'team',
                mt.team_id,
                'match.official.assign'
              )
          )
      end
  )
)
with check (
  exists (
    select 1
    from public.matches m
    where m.match_id = match_officials.match_id
      and case
        when m.tournament_id is not null then
          public.is_tournament_organizer(m.tournament_id)
        else
          exists (
            select 1
            from public.match_teams mt
            where mt.match_id = m.match_id
              and mt.team_id is not null
              and public.can(
                'team',
                mt.team_id,
                'match.official.assign'
              )
          )
      end
  )
  and (
    match_officials.role = 'scorer'
    or exists (
      select 1
      from public.matches m
      where m.match_id = match_officials.match_id
        and m.tournament_id is not null
    )
  )
);

-- No remaining policy/function depends on this misleading wrapper.
drop function if exists public.is_team_captain(uuid);


-- =============================================================================
-- 3. ASSIGNED SCORER / NEUTRAL FIXTURE AUTHORITY
-- =============================================================================

create or replace function public.mirror_scorer_grant()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op in ('DELETE','UPDATE')
     and old.role = 'scorer'
  then
    delete from public.grants
    where subject_id = old.user_id
      and scope = 'match'
      and entity_id = old.match_id
      and permission_key in (
        'match.score',
        'cricket.match.setup'
      );
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  if new.role = 'scorer' then
    -- Generic live scoring capability.
    insert into public.grants (
      subject_id,
      scope,
      entity_id,
      permission_key,
      granted_by
    )
    values (
      new.user_id,
      'match',
      new.match_id,
      'match.score',
      new.assigned_by
    )
    on conflict (
      subject_id,
      scope,
      entity_id,
      permission_key
    ) do update
    set granted_by = excluded.granted_by;

    -- Cricket Match Start capability only belongs on Cricket fixtures.
    if exists (
      select 1
      from public.matches m
      where m.match_id = new.match_id
        and m.sport_id = 'cricket'
    ) then
      insert into public.grants (
        subject_id,
        scope,
        entity_id,
        permission_key,
        granted_by
      )
      values (
        new.user_id,
        'match',
        new.match_id,
        'cricket.match.setup',
        new.assigned_by
      )
      on conflict (
        subject_id,
        scope,
        entity_id,
        permission_key
      ) do update
      set granted_by = excluded.granted_by;
    end if;
  end if;

  return new;
end;
$$;

revoke all
  on function public.mirror_scorer_grant()
  from public, anon, authenticated;

-- Existing scorer rows get the new Cricket setup grant immediately.
insert into public.grants (
  subject_id,
  scope,
  entity_id,
  permission_key,
  granted_by
)
select
  mo.user_id,
  'match',
  mo.match_id,
  'cricket.match.setup',
  mo.assigned_by
from public.match_officials mo
join public.matches m
  on m.match_id = mo.match_id
where mo.role = 'scorer'
  and m.sport_id = 'cricket'
on conflict (
  subject_id,
  scope,
  entity_id,
  permission_key
) do update
set granted_by = excluded.granted_by;



-- Tournament scorer assignment ------------------------------------------------

create or replace function public.tournament_assign_scorer(
  p_match_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament_id uuid;
  v_status public.match_status;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;

  select
    m.tournament_id,
    m.status
  into
    v_tournament_id,
    v_status
  from public.matches m
  where m.match_id = p_match_id
  for update;

  if not found then
    raise exception 'Match not found'
      using errcode = 'P0002';
  end if;

  if v_tournament_id is null then
    raise exception 'This is not a tournament match'
      using errcode = '22023';
  end if;

  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can assign scorers'
      using errcode = '42501';
  end if;

  if v_status in ('completed','abandoned','cancelled') then
    raise exception 'This match is already finished'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.tournament_official_candidates(
      v_tournament_id,
      p_match_id
    ) c
    where c.user_id = p_user_id
  ) then
    raise exception 'Selected user is not an eligible tournament official candidate'
      using errcode = '23514';
  end if;

  delete from public.match_officials
  where match_id = p_match_id
    and role = 'scorer';

  insert into public.match_officials (
    match_id,
    user_id,
    role,
    assigned_by
  )
  values (
    p_match_id,
    p_user_id,
    'scorer',
    auth.uid()
  );
end;
$$;

revoke all
  on function public.tournament_assign_scorer(uuid, uuid)
  from public, anon;

grant execute
  on function public.tournament_assign_scorer(uuid, uuid)
  to authenticated;


-- Tournament official assignment ----------------------------------------------

create or replace function public.tournament_assign_official(
  p_match_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament_id uuid;
  v_status public.match_status;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;

  if p_role not in (
    'umpire_main',
    'umpire_leg',
    'umpire_third',
    'referee'
  ) then
    raise exception 'Use tournament_assign_scorer for the scorer role'
      using errcode = '22023';
  end if;

  select
    m.tournament_id,
    m.status
  into
    v_tournament_id,
    v_status
  from public.matches m
  where m.match_id = p_match_id
  for update;

  if not found then
    raise exception 'Match not found'
      using errcode = 'P0002';
  end if;

  if v_tournament_id is null then
    raise exception 'This is not a tournament match'
      using errcode = '22023';
  end if;

  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can assign officials'
      using errcode = '42501';
  end if;

  if v_status in ('completed','abandoned','cancelled') then
    raise exception 'This match is already finished'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.tournament_official_candidates(
      v_tournament_id,
      p_match_id
    ) c
    where c.user_id = p_user_id
  ) then
    raise exception 'Selected user is not an eligible tournament official candidate'
      using errcode = '23514';
  end if;

  delete from public.match_officials
  where match_id = p_match_id
    and role = p_role;

  delete from public.match_officials
  where match_id = p_match_id
    and user_id = p_user_id
    and role <> 'scorer';

  insert into public.match_officials (
    match_id,
    user_id,
    role,
    assigned_by
  )
  values (
    p_match_id,
    p_user_id,
    p_role,
    auth.uid()
  );
end;
$$;

revoke all
  on function public.tournament_assign_official(uuid, uuid, text)
  from public, anon;

grant execute
  on function public.tournament_assign_official(uuid, uuid, text)
  to authenticated;


-- Tournament scorer auto-assignment -------------------------------------------

create or replace function public.tournament_auto_assign_scorers(
  p_tournament_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match record;
  v_person uuid;
  v_filled integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;

  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can assign scorers'
      using errcode = '42501';
  end if;

  for v_match in
    select
      m.match_id,
      m.scheduled_start_time
    from public.matches m
    where m.tournament_id = p_tournament_id
      and m.status = 'scheduled'
      and not exists (
        select 1
        from public.match_officials mo
        where mo.match_id = m.match_id
          and mo.role = 'scorer'
      )
    order by m.scheduled_start_time
  loop
    select c.user_id
      into v_person
    from public.tournament_official_candidates(
      p_tournament_id,
      v_match.match_id
    ) c
    where c.busy_on is null
    order by
      c.is_neutral desc,
      c.matches_officiated asc,
      c.display_name asc
    limit 1;

    if v_person is not null then
      insert into public.match_officials (
        match_id,
        user_id,
        role,
        assigned_by
      )
      values (
        v_match.match_id,
        v_person,
        'scorer',
        auth.uid()
      )
      on conflict do nothing;

      if found then
        v_filled := v_filled + 1;
      end if;
    end if;

    v_person := null;
  end loop;

  return v_filled;
end;
$$;

revoke all
  on function public.tournament_auto_assign_scorers(uuid)
  from public, anon;

grant execute
  on function public.tournament_auto_assign_scorers(uuid)
  to authenticated;


-- =============================================================================
-- 4. CRICKET READ PROJECTION
-- =============================================================================

-- list_my_cricket_matches returns the view row type, so drop it before replacing
-- the view shape.
drop function if exists public.list_my_cricket_matches();
drop view if exists public.cricket_match_details;

create view public.cricket_match_details
with (security_invoker = true)
as
select
  m.match_id,
  m.tournament_id,
  m.match_type,
  m.stage,
  m.round,
  m.bracket_round_number,
  m.bracket_match_number,
  m.prev_match_a_id,
  m.prev_match_b_id,
  m.group_id,
  m.venue,
  m.ground_id,
  m.sport_id,
  m.scheduled_start_time,
  m.actual_start_time,
  m.completed_at,

  m.status as lifecycle_status,
  cm.phase as cricket_phase,

  case
    when m.status = 'scheduled'
      and cm.toss_recorded_at is not null
      then 'toss'
    when m.status = 'live'
      and cm.phase = 'innings_break'
      then 'innings_break'
    when m.status = 'live'
      and cm.phase = 'super_over'
      then 'super_over'
    when m.status = 'completed'
      and cm.result ->> 'win_type' = 'tie'
      then 'tied'
    when m.status = 'completed'
      and cm.result ->> 'win_type' = 'walkover'
      then 'walkover'
    when cm.result ->> 'win_type' = 'no_result'
      then 'no_result'
    else m.status::text
  end as status,

  cm.setup_side,
  setup_slot.team_id as setup_team_id,

  m.winner_side,
  winner_slot.team_id as winner_id,

  team_a.team_id as team_a_id,
  team_b.team_id as team_b_id,
  team_a.team_name as team_a_name,
  team_b.team_name as team_b_name,

  m.created_by,
  m.created_at,
  m.updated_at,

  cm.format_code as match_format,
  cm.rules_snapshot as format,

  cm.toss_won_by as toss_won_by_side,
  case cm.toss_won_by
    when 'team_a' then team_a.team_id
    when 'team_b' then team_b.team_id
    else null
  end as toss_won_by,

  cm.toss_decision,
  cm.toss_face,
  cm.toss_recorded_at,
  cm.toss_recorded_by,

  case cm.phase
    when 'toss' then 'toss'
    when 'lineup' then 'lineup'
    when 'ready' then 'ready'
    else 'live'
  end as start_phase,

  cm.openers_submitted_by,
  cm.openers_submitted_at,
  cm.scoring_mode,

  case
    when cm.result is null then null
    else cm.result || jsonb_build_object(
      'winner_team_id',
      winner_slot.team_id
    )
  end as result,

  cm.result_summary,
  cm.revised_conditions,
  cm.player_of_the_match_id,

  (
    select mp.user_id
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
    where mp.match_id = m.match_id
      and mp.team_side = 'team_a'
      and cmp.is_captain = true
      and mp.user_id is not null
    order by
      cmp.updated_at desc,
      mp.created_at asc
    limit 1
  ) as team_a_captain,

  (
    select mp.user_id
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
    where mp.match_id = m.match_id
      and mp.team_side = 'team_b'
      and cmp.is_captain = true
      and mp.user_id is not null
    order by
      cmp.updated_at desc,
      mp.created_at asc
    limit 1
  ) as team_b_captain

from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
join public.match_teams team_a
  on team_a.match_id = m.match_id
 and team_a.team_side = 'team_a'
join public.match_teams team_b
  on team_b.match_id = m.match_id
 and team_b.team_side = 'team_b'
left join public.match_teams setup_slot
  on setup_slot.match_id = m.match_id
 and setup_slot.team_side = cm.setup_side
left join public.match_teams winner_slot
  on winner_slot.match_id = m.match_id
 and winner_slot.team_side = m.winner_side
where m.sport_id = 'cricket';

grant select
  on public.cricket_match_details
  to anon, authenticated, service_role;

create or replace function public.list_my_cricket_matches()
returns setof public.cricket_match_details
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select d.*
  from public.cricket_match_details d
  where
    d.created_by = auth.uid()
    or exists (
      select 1
      from public.match_teams ms
      join public.team_members tm
        on tm.team_id = ms.team_id
      where ms.match_id = d.match_id
        and tm.user_id = auth.uid()
        and tm.status = 'active'
    )
    or exists (
      select 1
      from public.match_players mp
      where mp.match_id = d.match_id
        and mp.user_id = auth.uid()
    )
    or exists (
      select 1
      from public.match_officials mo
      where mo.match_id = d.match_id
        and mo.user_id = auth.uid()
    )
  order by coalesce(
    d.scheduled_start_time,
    d.created_at
  ) desc;
$$;

revoke all
  on function public.list_my_cricket_matches()
  from public, anon;

grant execute
  on function public.list_my_cricket_matches()
  to authenticated;


-- =============================================================================
-- 5. PEER-TO-PEER MATCH CREATION: CANONICAL MATCH_TEAMS + CRICKET SETUP SIDE
-- =============================================================================
-- The accepted challenge's from_team becomes team_a and therefore the initial
-- Cricket setup side. created_by remains the USER who performed the database
-- action and is never used for Match Start authorization.

create or replace function public.accept_match_request(
  p_request_id uuid,
  p_scheduled_start_time timestamptz default null,
  p_venue text default null,
  p_format jsonb default null,
  p_decision_note text default null,
  p_to_team_id uuid default null,
  p_to_team_xi uuid[] default '{}'::uuid[],
  p_to_team_keeper_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req public.match_challenges%rowtype;
  v_to_team uuid;
  v_match_id uuid;
  v_rules jsonb;
  v_start timestamptz;
  v_venue text;
  v_to_team_xi uuid[];
  v_to_keeper uuid;
  v_a_captain uuid;
  v_b_captain uuid;
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  select *
    into v_req
  from public.match_challenges
  where request_id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found'
      using errcode = 'P0002';
  end if;

  if v_req.status not in ('pending', 'countered') then
    raise exception
      'Request is no longer actionable (status: %)',
      v_req.status
      using errcode = '22023';
  end if;

  if v_req.status = 'countered' then
    if not public.can('team', v_req.from_team_id, 'team.challenge.send') then
      raise exception
        'This user cannot accept a countered request for the originating team'
        using errcode = '42501';
    end if;

    v_to_team := v_req.to_team_id;
    v_rules := coalesce(
      p_format,
      v_req.countered_format,
      v_req.proposed_format,
      '{}'::jsonb
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.countered_start_time,
      v_req.proposed_start_time
    );
    v_venue := coalesce(
      p_venue,
      v_req.countered_venue,
      v_req.proposed_venue
    );
    v_to_team_xi := '{}'::uuid[];
    v_to_keeper := null;

  elsif v_req.to_team_id is not null then
    if not public.can('team', v_req.to_team_id, 'team.challenge.send') then
      raise exception
        'This user cannot accept on behalf of the receiving team'
        using errcode = '42501';
    end if;

    v_to_team := v_req.to_team_id;
    v_rules := coalesce(
      p_format,
      v_req.proposed_format,
      '{}'::jsonb
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.proposed_start_time
    );
    v_venue := coalesce(
      p_venue,
      v_req.proposed_venue
    );
    v_to_team_xi := coalesce(
      p_to_team_xi,
      '{}'::uuid[]
    );
    v_to_keeper := p_to_team_keeper_id;

  else
    if p_to_team_id is null then
      raise exception
        'Open requests require p_to_team_id to claim'
        using errcode = '22023';
    end if;

    if p_to_team_id = v_req.from_team_id then
      raise exception
        'A team cannot accept its own challenge'
        using errcode = '23514';
    end if;

    if not public.can('team', p_to_team_id, 'team.challenge.send') then
      raise exception
        'This user cannot accept on behalf of the selected team'
        using errcode = '42501';
    end if;

    v_to_team := p_to_team_id;
    v_rules := coalesce(
      p_format,
      v_req.proposed_format,
      '{}'::jsonb
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.proposed_start_time
    );
    v_venue := coalesce(
      p_venue,
      v_req.proposed_venue
    );
    v_to_team_xi := coalesce(
      p_to_team_xi,
      '{}'::uuid[]
    );
    v_to_keeper := p_to_team_keeper_id;
  end if;

  if v_to_team is null then
    raise exception 'Receiving team is unresolved'
      using errcode = '23502';
  end if;

  if v_to_team = v_req.from_team_id then
    raise exception
      'A team cannot play itself'
      using errcode = '23514';
  end if;

  if v_req.players_per_side is not null
     and coalesce(array_length(v_to_team_xi, 1), 0)
       > v_req.players_per_side
  then
    raise exception
      'to_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;

  perform public._validate_team_xi(
    v_req.from_team_id,
    v_req.from_team_xi
  );

  perform public._validate_team_xi(
    v_to_team,
    v_to_team_xi
  );

  if v_req.sport_id = 'cricket' then
    v_a_captain :=
      public._team_current_captain(v_req.from_team_id);
    v_b_captain :=
      public._team_current_captain(v_to_team);

    if v_a_captain is null
       or v_b_captain is null
    then
      raise exception
        'Both teams must have a captain or owner before a Cricket match can be created'
        using errcode = '23502';
    end if;
  end if;

  insert into public.matches (
    match_type,
    tournament_id,
    sport_id,
    venue,
    scheduled_start_time,
    status,
    created_by
  )
  values (
    'friendly',
    null,
    v_req.sport_id,
    v_venue,
    coalesce(v_start, now()),
    'scheduled',
    auth.uid()
  )
  returning match_id
  into v_match_id;

  -- Side rows already exist because matches_create_team_slots fires AFTER INSERT.
  update public.match_teams
  set team_id = case team_side
    when 'team_a' then v_req.from_team_id
    when 'team_b' then v_to_team
  end
  where match_id = v_match_id;

  if v_req.sport_id = 'cricket' then
    insert into public.cricket_matches (
      match_id,
      format_code,
      rules_snapshot,
      setup_side
    )
    values (
      v_match_id,
      coalesce(
        v_rules ->> 'format_preset',
        v_rules ->> 'format_code',
        't20'
      ),
      v_rules,
      'team_a'
    );
  end if;

  -- Generic participant identity.
  insert into public.match_players (
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name
  )
  select
    v_match_id,
    'team_a',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(
      p.display_name,
      u.display_name,
      'Player'
    )
  from public.team_members tm
  left join public.profiles p
    on p.user_id = tm.user_id
  left join public.unclaimed_players u
    on u.unclaimed_id = tm.unclaimed_id
  where tm.team_id = v_req.from_team_id
    and tm.status = 'active'
    and (
      coalesce(
        array_length(v_req.from_team_xi, 1),
        0
      ) = 0
      or tm.user_id = any(v_req.from_team_xi)
      or tm.unclaimed_id = any(v_req.from_team_xi)
    );

  insert into public.match_players (
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name
  )
  select
    v_match_id,
    'team_b',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(
      p.display_name,
      u.display_name,
      'Player'
    )
  from public.team_members tm
  left join public.profiles p
    on p.user_id = tm.user_id
  left join public.unclaimed_players u
    on u.unclaimed_id = tm.unclaimed_id
  where tm.team_id = v_to_team
    and tm.status = 'active'
    and (
      coalesce(
        array_length(v_to_team_xi, 1),
        0
      ) = 0
      or tm.user_id = any(v_to_team_xi)
      or tm.unclaimed_id = any(v_to_team_xi)
    );

  if v_req.sport_id = 'cricket' then
    insert into public.cricket_match_players (
      match_player_id,
      match_id,
      is_captain,
      is_wicket_keeper
    )
    select
      mp.match_player_id,
      mp.match_id,
      coalesce(
        (
          mp.team_side = 'team_a'
          and mp.user_id = v_a_captain
        )
        or (
          mp.team_side = 'team_b'
          and mp.user_id = v_b_captain
        ),
        false
      ),
      coalesce(
        mp.user_id = v_req.from_team_keeper_id
        or mp.unclaimed_id = v_req.from_team_keeper_id
        or mp.user_id = v_to_keeper
        or mp.unclaimed_id = v_to_keeper,
        false
      )
    from public.match_players mp
    where mp.match_id = v_match_id;
  end if;

  update public.match_challenges
  set
    status = 'accepted',
    decided_by = auth.uid(),
    decided_at = now(),
    decision_note = p_decision_note,
    match_id = v_match_id,
    to_team_id = v_to_team
  where request_id = p_request_id
    and status = v_req.status;

  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception
      'Request changed under us; aborting accept'
      using errcode = '40001';
  end if;

  return v_match_id;
end;
$$;

revoke all
  on function public.accept_match_request(
    uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
  )
  from public, anon;

grant execute
  on function public.accept_match_request(
    uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
  )
  to authenticated;

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
  v_rules jsonb;
  v_a_captain uuid;
  v_b_captain uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  select *
    into v_app
  from public.match_pool_applications
  where application_id = p_application_id
  for update;

  if not found then
    raise exception 'Application not found'
      using errcode = 'P0002';
  end if;

  if v_app.status <> 'pending' then
    raise exception
      'Application is no longer pending (status: %)',
      v_app.status
      using errcode = '22023';
  end if;

  select *
    into v_req
  from public.match_challenges
  where request_id = v_app.request_id
  for update;

  if not found then
    raise exception 'Match request not found'
      using errcode = 'P0002';
  end if;

  if not public.can('team', v_req.from_team_id, 'team.challenge.send') then
    raise exception
      'This user cannot select an applicant for the originating team'
      using errcode = '42501';
  end if;

  if v_req.status <> 'pending' then
    raise exception
      'Open challenge is no longer active (status: %)',
      v_req.status
      using errcode = '22023';
  end if;

  if v_req.from_team_id = v_app.applicant_team_id then
    raise exception
      'A team cannot play itself'
      using errcode = '23514';
  end if;

  perform public._validate_team_xi(
    v_req.from_team_id,
    v_req.from_team_xi
  );

  perform public._validate_team_xi(
    v_app.applicant_team_id,
    v_app.applicant_xi
  );

  v_rules := coalesce(
    v_req.proposed_format,
    '{}'::jsonb
  );

  if v_req.sport_id = 'cricket' then
    v_a_captain :=
      public._team_current_captain(v_req.from_team_id);
    v_b_captain :=
      public._team_current_captain(v_app.applicant_team_id);

    if v_a_captain is null
       or v_b_captain is null
    then
      raise exception
        'Both teams must have a captain or owner before a Cricket match can be created'
        using errcode = '23502';
    end if;
  end if;

  insert into public.matches (
    match_type,
    tournament_id,
    sport_id,
    venue,
    scheduled_start_time,
    status,
    created_by
  )
  values (
    'friendly',
    null,
    v_req.sport_id,
    v_req.proposed_venue,
    coalesce(v_req.proposed_start_time, now()),
    'scheduled',
    auth.uid()
  )
  returning match_id
  into v_match_id;

  update public.match_teams
  set team_id = case team_side
    when 'team_a' then v_req.from_team_id
    when 'team_b' then v_app.applicant_team_id
  end
  where match_id = v_match_id;

  if v_req.sport_id = 'cricket' then
    insert into public.cricket_matches (
      match_id,
      format_code,
      rules_snapshot,
      setup_side
    )
    values (
      v_match_id,
      coalesce(
        v_rules ->> 'format_preset',
        v_rules ->> 'format_code',
        't20'
      ),
      v_rules,
      'team_a'
    );
  end if;

  insert into public.match_players (
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name
  )
  select
    v_match_id,
    'team_a',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(
      p.display_name,
      u.display_name,
      'Player'
    )
  from public.team_members tm
  left join public.profiles p
    on p.user_id = tm.user_id
  left join public.unclaimed_players u
    on u.unclaimed_id = tm.unclaimed_id
  where tm.team_id = v_req.from_team_id
    and tm.status = 'active'
    and (
      coalesce(
        array_length(v_req.from_team_xi, 1),
        0
      ) = 0
      or tm.user_id = any(v_req.from_team_xi)
      or tm.unclaimed_id = any(v_req.from_team_xi)
    );

  insert into public.match_players (
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name
  )
  select
    v_match_id,
    'team_b',
    tm.user_id,
    tm.unclaimed_id,
    coalesce(
      p.display_name,
      u.display_name,
      'Player'
    )
  from public.team_members tm
  left join public.profiles p
    on p.user_id = tm.user_id
  left join public.unclaimed_players u
    on u.unclaimed_id = tm.unclaimed_id
  where tm.team_id = v_app.applicant_team_id
    and tm.status = 'active'
    and (
      coalesce(
        array_length(v_app.applicant_xi, 1),
        0
      ) = 0
      or tm.user_id = any(v_app.applicant_xi)
      or tm.unclaimed_id = any(v_app.applicant_xi)
    );

  if v_req.sport_id = 'cricket' then
    insert into public.cricket_match_players (
      match_player_id,
      match_id,
      is_captain,
      is_wicket_keeper
    )
    select
      mp.match_player_id,
      mp.match_id,
      coalesce(
        (
          mp.team_side = 'team_a'
          and mp.user_id = v_a_captain
        )
        or (
          mp.team_side = 'team_b'
          and mp.user_id = v_b_captain
        ),
        false
      ),
      coalesce(
        mp.user_id = v_req.from_team_keeper_id
        or mp.unclaimed_id = v_req.from_team_keeper_id
        or mp.user_id = v_app.applicant_keeper_id
        or mp.unclaimed_id = v_app.applicant_keeper_id,
        false
      )
    from public.match_players mp
    where mp.match_id = v_match_id;
  end if;

  update public.match_pool_applications
  set
    status = 'accepted',
    decided_at = now(),
    decision_note = p_decision_note,
    updated_at = now()
  where application_id = p_application_id;

  update public.match_pool_applications
  set
    status = 'rejected',
    decided_at = now(),
    decision_note =
      'Another opponent was selected for this fixture',
    updated_at = now()
  where request_id = v_app.request_id
    and application_id <> p_application_id
    and status = 'pending';

  update public.match_challenges
  set
    status = 'accepted',
    decided_by = auth.uid(),
    decided_at = now(),
    decision_note = p_decision_note,
    match_id = v_match_id,
    to_team_id = v_app.applicant_team_id
  where request_id = v_app.request_id;

  perform public.notify(
    array(
      select public.team_staff_ids(
        v_app.applicant_team_id
      )
    ),
    'match.application.accepted',
    jsonb_build_object(
      'request_id', v_app.request_id,
      'match_id', v_match_id,
      'host_team_id', v_req.from_team_id,
      'opponent_team_id', v_req.from_team_id,
      'actor_id', auth.uid()
    ),
    auth.uid(),
    'team',
    v_app.applicant_team_id
  );

  return v_match_id;
end;
$$;

revoke all
  on function public.accept_pool_application(uuid, text)
  from public, anon;

grant execute
  on function public.accept_pool_application(uuid, text)
  to authenticated;


-- =============================================================================
-- 6. TOURNAMENT FIXTURE CREATION: NEUTRAL CRICKET SETUP
-- =============================================================================

create or replace function public.tournament_generate_fixtures(
  p_tournament_id uuid,
  p_slots jsonb,
  p_seed_order uuid[] default '{}'::uuid[]
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament public.tournaments%rowtype;
  v_slot jsonb;
  v_slot_id text;
  v_match_id uuid;
  v_team_a uuid;
  v_team_b uuid;
  v_prev_a text;
  v_prev_b text;
  v_count integer := 0;
  v_i integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  if not public.is_tournament_organizer(
    p_tournament_id
  ) then
    raise exception
      'Only a tournament organizer can publish fixtures'
      using errcode = '42501';
  end if;

  select *
    into v_tournament
  from public.tournaments
  where tournament_id = p_tournament_id
  for update;

  if not found then
    raise exception 'Tournament not found'
      using errcode = 'P0002';
  end if;

  if jsonb_typeof(p_slots) <> 'array' then
    raise exception 'p_slots must be a JSON array'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.matches
    where tournament_id = p_tournament_id
  ) then
    raise exception
      'Fixtures have already been published for this tournament'
      using errcode = '23505';
  end if;

  if array_length(p_seed_order, 1) is not null then
    for v_i in 1..array_length(p_seed_order, 1) loop
      update public.tournament_teams
      set
        seed_number = v_i,
        updated_at = now()
      where tournament_id = p_tournament_id
        and team_id = p_seed_order[v_i]
        and status = 'approved';
    end loop;
  end if;

  create temporary table if not exists
    pg_temp.matchday_fixture_slot_map (
      slot_id text primary key,
      match_id uuid not null
    )
  on commit drop;

  truncate table pg_temp.matchday_fixture_slot_map;

  -- First pass: create all match shells and side slots.
  for v_slot in
    select value
    from jsonb_array_elements(p_slots)
  loop
    v_slot_id :=
      nullif(v_slot ->> 'slot_id', '');

    if v_slot_id is null then
      raise exception 'Every fixture needs slot_id'
        using errcode = '22023';
    end if;

    v_team_a :=
      nullif(v_slot ->> 'team_a_id', '')::uuid;
    v_team_b :=
      nullif(v_slot ->> 'team_b_id', '')::uuid;

    if v_team_a is not null
       and not exists (
         select 1
         from public.tournament_teams tt
         where tt.tournament_id = p_tournament_id
           and tt.team_id = v_team_a
           and tt.status = 'approved'
       )
    then
      raise exception
        'Team A % is not an approved tournament team',
        v_team_a
        using errcode = '23514';
    end if;

    if v_team_b is not null
       and not exists (
         select 1
         from public.tournament_teams tt
         where tt.tournament_id = p_tournament_id
           and tt.team_id = v_team_b
           and tt.status = 'approved'
       )
    then
      raise exception
        'Team B % is not an approved tournament team',
        v_team_b
        using errcode = '23514';
    end if;

    if v_team_a is not null
       and v_team_b is not null
       and v_team_a = v_team_b
    then
      raise exception 'A fixture cannot contain the same team twice'
        using errcode = '23514';
    end if;

    insert into public.matches (
      tournament_id,
      match_type,
      round,
      bracket_round_number,
      bracket_match_number,
      venue,
      sport_id,
      scheduled_start_time,
      status,
      created_by
    )
    values (
      p_tournament_id,
      'tournament',
      nullif(v_slot ->> 'round', ''),
      nullif(
        v_slot ->> 'bracket_round_number',
        ''
      )::integer,
      nullif(
        v_slot ->> 'bracket_match_number',
        ''
      )::integer,
      nullif(v_slot ->> 'venue', ''),
      v_tournament.sport_id,
      coalesce(
        nullif(
          v_slot ->> 'scheduled_start_time',
          ''
        )::timestamptz,
        now()
      ),
      'scheduled',
      auth.uid()
    )
    returning match_id
      into v_match_id;

    update public.match_teams
    set team_id = case team_side
      when 'team_a' then v_team_a
      when 'team_b' then v_team_b
    end
    where match_id = v_match_id;

    if v_tournament.sport_id = 'cricket' then
      insert into public.cricket_matches (
        match_id,
        format_code,
        rules_snapshot,
        setup_side
      )
      values (
        v_match_id,
        coalesce(
          v_tournament.format ->> 'format_preset',
          v_tournament.format ->> 'format_code',
          't20'
        ),
        coalesce(
          v_tournament.format,
          '{}'::jsonb
        )
        || coalesce(
          v_tournament.rules,
          '{}'::jsonb
        ),
        null
      );
    end if;

    if v_team_a is not null then
      perform public._materialize_match_team_side(
        v_match_id,
        'team_a'
      );
    end if;

    if v_team_b is not null then
      perform public._materialize_match_team_side(
        v_match_id,
        'team_b'
      );
    end if;

    insert into pg_temp.matchday_fixture_slot_map (
      slot_id,
      match_id
    )
    values (
      v_slot_id,
      v_match_id
    );

    v_count := v_count + 1;
  end loop;

  -- Second pass: resolve feeder match IDs now that every slot has a match_id.
  for v_slot in
    select value
    from jsonb_array_elements(p_slots)
  loop
    v_slot_id :=
      nullif(v_slot ->> 'slot_id', '');
    v_prev_a :=
      nullif(v_slot ->> 'prev_slot_a', '');
    v_prev_b :=
      nullif(v_slot ->> 'prev_slot_b', '');

    select sm.match_id
      into v_match_id
    from pg_temp.matchday_fixture_slot_map sm
    where sm.slot_id = v_slot_id;

    update public.matches
    set
      prev_match_a_id = (
        select sm.match_id
        from pg_temp.matchday_fixture_slot_map sm
        where sm.slot_id = v_prev_a
      ),
      prev_match_b_id = (
        select sm.match_id
        from pg_temp.matchday_fixture_slot_map sm
        where sm.slot_id = v_prev_b
      ),
      updated_at = now()
    where match_id = v_match_id;
  end loop;

  return v_count;
end;
$$;

revoke all
  on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  from public, anon;

grant execute
  on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  to authenticated;


-- =============================================================================
-- 7. COMMENTS / FINAL ASSERTIONS
-- =============================================================================

comment on column public.matches.created_by is
  'Audit/history: authenticated user who materialized the match row. Never use this column as match-day authorization.';

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='matches'
      and column_name='host_side'
  ) then
    raise exception
      'Generic matches.host_side must not exist after the Cricket setup cutover.';
  end if;

  if not exists (
    select 1
    from public.permission_scopes
    where permission_key='cricket.match.setup'
      and scope='team'
  ) or not exists (
    select 1
    from public.permission_scopes
    where permission_key='cricket.match.setup'
      and scope='match'
  ) then
    raise exception
      'cricket.match.setup must support both team and match scopes.';
  end if;

  if exists (
    select 1
    from public.permissions
    where permission_key='match.lineup.set'
  ) then
    raise exception
      'Legacy generic-looking match.lineup.set permission still exists.';
  end if;

  if exists (
    select 1
    from public.cricket_matches cm
    join public.matches m
      on m.match_id = cm.match_id
    where m.tournament_id is null
      and m.status = 'scheduled'
      and cm.setup_side is null
      and exists (
        select 1
        from public.match_teams mt
        where mt.match_id = m.match_id
          and mt.team_side='team_a'
          and mt.team_id is not null
      )
  ) then
    raise exception
      'Resolved peer-to-peer scheduled Cricket match is missing setup_side.';
  end if;
end
$$;
