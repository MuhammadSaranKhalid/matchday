-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 2B
-- Tournament / pool / remaining Cricket callers
-- =============================================================================
-- REQUIRES PHASE 2A FIRST.
--
-- Phase 2B migrates the remaining callers that would otherwise keep the
-- Phase-1 compatibility mirrors alive: pool acceptance, tournament fixture
-- creation/advancement, tournament result/rain/super-over operations, and
-- unclaimed-player merge logic. After these are canonical the mirrors are
-- removed. Deprecated columns themselves remain until Phase 3.
-- =============================================================================

-- =============================================================================
-- 0. Hard prerequisite: Phase 2A must already be applied
-- =============================================================================
do $$
begin
  if to_regclass('public.cricket_matches') is null
     or to_regclass('public.cricket_match_players') is null
     or to_regclass('public.cricket_match_details') is null
     or to_regprocedure('public._normalize_cricket_match_rules(jsonb)') is null
     or to_regprocedure('public._materialize_cricket_match_side(uuid,uuid,text,uuid[],uuid,uuid)') is null
     or to_regprocedure('public.list_my_cricket_matches()') is null
     or to_regprocedure('public.complete_cricket_match(uuid,text)') is null
  then
    raise exception
      'Phase 2A is required before Phase 2B. Apply the Phase 2A migration first.';
  end if;
end
$$;

-- =============================================================================
-- 1. Match pool applications
-- =============================================================================
-- Current production has no pool table even though the Flutter client calls
-- it. Define the final surface idempotently instead of replaying historical
-- migrations whose other changes have already been folded into base files.
-- =============================================================================
create table if not exists public.match_pool_applications (
  application_id       uuid primary key default gen_random_uuid(),
  request_id           uuid not null
                         references public.match_challenges(request_id)
                         on delete cascade,
  applicant_team_id    uuid not null
                         references public.teams(team_id)
                         on delete cascade,
  applicant_user_id    uuid not null
                         references public.profiles(user_id)
                         on delete cascade,
  applicant_xi         uuid[] not null default '{}'::uuid[],
  applicant_keeper_id  uuid,
  message              text,
  status               text not null default 'pending'
                         check (status in ('pending','accepted','rejected','withdrawn')),
  decision_note        text,
  decided_at           timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index if not exists match_pool_apps_request
  on public.match_pool_applications (request_id);
create index if not exists match_pool_apps_applicant_team
  on public.match_pool_applications (applicant_team_id);
create index if not exists match_pool_apps_status
  on public.match_pool_applications (status);
create index if not exists match_pool_apps_applicant_user
  on public.match_pool_applications (applicant_user_id);

drop trigger if exists match_pool_applications_set_updated_at
  on public.match_pool_applications;
create trigger match_pool_applications_set_updated_at
  before update on public.match_pool_applications
  for each row execute function public.set_updated_at();

alter table public.match_pool_applications enable row level security;

drop policy if exists "match_pool_apps_select"
  on public.match_pool_applications;
create policy "match_pool_apps_select"
  on public.match_pool_applications
  for select
  to authenticated
  using (
    public.is_team_manager(applicant_team_id)
    or exists (
      select 1
      from public.match_challenges mc
      where mc.request_id = match_pool_applications.request_id
        and public.is_team_manager(mc.from_team_id)
    )
  );

-- Mutations are RPC-owned.
revoke insert, update, delete, truncate
  on public.match_pool_applications
  from anon, authenticated;
grant select on public.match_pool_applications to authenticated;
grant all on public.match_pool_applications to service_role;

create or replace function public.apply_to_match_pool(
  p_request_id          uuid,
  p_applicant_team_id   uuid,
  p_applicant_xi        uuid[] default '{}'::uuid[],
  p_applicant_keeper_id uuid default null,
  p_message             text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req    public.match_challenges%rowtype;
  v_app_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  if not public.is_team_manager(p_applicant_team_id) then
    raise exception 'You can only apply on behalf of teams you manage'
      using errcode = '42501';
  end if;

  select * into v_req
    from public.match_challenges
   where request_id = p_request_id
   for share;

  if not found then
    raise exception 'Match request not found' using errcode = 'P0002';
  end if;

  if v_req.to_team_id is not null then
    raise exception 'This is a direct challenge, not an open pool post'
      using errcode = '22023';
  end if;

  if v_req.status <> 'pending' then
    raise exception 'This open match request is no longer accepting applications'
      using errcode = '22023';
  end if;

  if v_req.from_team_id = p_applicant_team_id then
    raise exception 'A team cannot apply to its own open challenge'
      using errcode = '23514';
  end if;

  perform public._validate_team_xi(p_applicant_team_id, p_applicant_xi);

  if exists (
    select 1
      from public.match_pool_applications a
     where a.request_id = p_request_id
       and a.applicant_team_id = p_applicant_team_id
       and a.status = 'pending'
  ) then
    raise exception 'Your team has already applied to this open challenge'
      using errcode = '23505';
  end if;

  insert into public.match_pool_applications (
    request_id, applicant_team_id, applicant_user_id,
    applicant_xi, applicant_keeper_id, message, status
  ) values (
    p_request_id, p_applicant_team_id, (select auth.uid()),
    coalesce(p_applicant_xi, '{}'::uuid[]), p_applicant_keeper_id,
    p_message, 'pending'
  ) returning application_id into v_app_id;

  perform public.notify(
    array(select public.team_staff_ids(v_req.from_team_id)),
    'match.application.received',
    jsonb_build_object(
      'request_id',        p_request_id,
      'from_team_id',      v_req.from_team_id,
      'applicant_team_id', p_applicant_team_id,
      'opponent_team_id',  p_applicant_team_id,
      'actor_id',          (select auth.uid())
    ),
    (select auth.uid()), 'team', v_req.from_team_id
  );

  return v_app_id;
end;
$$;
revoke all on function public.apply_to_match_pool(uuid, uuid, uuid[], uuid, text)
  from public, anon;
grant execute on function public.apply_to_match_pool(uuid, uuid, uuid[], uuid, text)
  to authenticated;

create or replace function public.accept_pool_application(
  p_application_id uuid,
  p_decision_note  text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app       public.match_pool_applications%rowtype;
  v_req       public.match_challenges%rowtype;
  v_match_id  uuid;
  v_rules     jsonb;
  v_a_captain uuid;
  v_b_captain uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_app
    from public.match_pool_applications
   where application_id = p_application_id
   for update;
  if not found then
    raise exception 'Application not found' using errcode = 'P0002';
  end if;
  if v_app.status <> 'pending' then
    raise exception 'Application is no longer pending' using errcode = '22023';
  end if;

  select * into v_req
    from public.match_challenges
   where request_id = v_app.request_id
   for update;
  if not found then
    raise exception 'Match request not found' using errcode = 'P0002';
  end if;
  if v_req.sport_id <> 'cricket' then
    raise exception 'The current frontend can only materialise Cricket pool matches'
      using errcode = '23514';
  end if;
  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the host team can accept applications'
      using errcode = '42501';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Open challenge is no longer active' using errcode = '22023';
  end if;

  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_app.applicant_team_id, v_app.applicant_xi);

  v_a_captain := public._team_current_captain(v_req.from_team_id);
  v_b_captain := public._team_current_captain(v_app.applicant_team_id);
  if v_a_captain is null or v_b_captain is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  v_rules := public._normalize_cricket_match_rules(
    coalesce(v_req.proposed_format, '{}'::jsonb)
  );

  -- Shared shell only.
  insert into public.matches (
    match_type, tournament_id, sport_id,
    team_a_id, team_b_id, venue, scheduled_start_time,
    status, created_by
  ) values (
    'friendly', null, 'cricket',
    v_req.from_team_id, v_app.applicant_team_id,
    v_req.proposed_venue, coalesce(v_req.proposed_start_time, now()),
    'scheduled', (select auth.uid())
  ) returning match_id into v_match_id;

  -- Canonical Cricket child.
  insert into public.cricket_matches (match_id, format_code, rules_snapshot)
  values (v_match_id, null, v_rules)
  on conflict (match_id) do update set
    rules_snapshot = excluded.rules_snapshot,
    updated_at = now();

  perform public._materialize_cricket_match_side(
    v_match_id, v_req.from_team_id, 'team_a', v_req.from_team_xi,
    v_a_captain, v_req.from_team_keeper_id
  );
  perform public._materialize_cricket_match_side(
    v_match_id, v_app.applicant_team_id, 'team_b', v_app.applicant_xi,
    v_b_captain, v_app.applicant_keeper_id
  );

  update public.match_pool_applications
     set status = 'accepted', decided_at = now(), decision_note = p_decision_note,
         updated_at = now()
   where application_id = p_application_id;

  update public.match_pool_applications
     set status = 'rejected', decided_at = now(),
         decision_note = 'Another opponent was selected for this fixture',
         updated_at = now()
   where request_id = v_app.request_id
     and application_id <> p_application_id
     and status = 'pending';

  update public.match_challenges
     set status = 'accepted', decided_by = (select auth.uid()), decided_at = now(),
         decision_note = p_decision_note, match_id = v_match_id,
         to_team_id = v_app.applicant_team_id
   where request_id = v_app.request_id;

  perform public.notify(
    array(select public.team_staff_ids(v_app.applicant_team_id)),
    'match.application.accepted',
    jsonb_build_object(
      'request_id',       v_app.request_id,
      'match_id',         v_match_id,
      'host_team_id',     v_req.from_team_id,
      'opponent_team_id', v_req.from_team_id,
      'actor_id',         (select auth.uid())
    ),
    (select auth.uid()), 'team', v_app.applicant_team_id
  );

  return v_match_id;
end;
$$;
revoke all on function public.accept_pool_application(uuid, text)
  from public, anon;
grant execute on function public.accept_pool_application(uuid, text)
  to authenticated;

create or replace function public.reject_pool_application(
  p_application_id uuid,
  p_reason         text default null
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
  if (select auth.uid()) is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_app
    from public.match_pool_applications
   where application_id = p_application_id
   for update;
  if not found then
    raise exception 'Application not found' using errcode = 'P0002';
  end if;

  select * into v_req
    from public.match_challenges
   where request_id = v_app.request_id;

  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the host team can reject applications'
      using errcode = '42501';
  end if;

  update public.match_pool_applications
     set status = 'rejected', decision_note = p_reason,
         decided_at = now(), updated_at = now()
   where application_id = p_application_id;
end;
$$;
revoke all on function public.reject_pool_application(uuid, text)
  from public, anon;
grant execute on function public.reject_pool_application(uuid, text)
  to authenticated;

-- =============================================================================
-- 2. Canonical tournament participant materialisation
-- =============================================================================
-- Initial concrete sides are materialised explicitly by fixture generation.
-- Later knockout slots are materialised by the team-slot update trigger.
-- =============================================================================
create or replace function public._materialize_cricket_tournament_side(
  p_match_id  uuid,
  p_team_id   uuid,
  p_team_side text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament_id uuid;
  v_squad         uuid[];
  v_captain       uuid;
begin
  if p_team_side not in ('team_a', 'team_b') then
    raise exception 'Invalid match side %', p_team_side using errcode = '22023';
  end if;

  select m.tournament_id into v_tournament_id
    from public.matches m
    join public.cricket_matches cm on cm.match_id = m.match_id
   where m.match_id = p_match_id
     and m.sport_id = 'cricket'
     and m.tournament_id is not null
     and p_team_id in (m.team_a_id, m.team_b_id);
  if not found then
    raise exception 'Cricket tournament match/side could not be resolved'
      using errcode = '23514';
  end if;

  select coalesce(tt.squad, '{}'::uuid[]) into v_squad
    from public.tournament_teams tt
   where tt.tournament_id = v_tournament_id
     and tt.team_id = p_team_id
     and tt.status = 'approved';
  if not found then
    raise exception 'Tournament side must belong to an approved registration'
      using errcode = '23514';
  end if;

  v_captain := public._team_current_captain(p_team_id);

  insert into public.match_players (
    match_id, team_side, user_id, unclaimed_id, display_name, jersey_number
  )
  select
    p_match_id, p_team_side, tm.user_id, tm.unclaimed_id,
    coalesce(pr.display_name, up.display_name, 'Player'), tm.jersey_number
  from public.team_members tm
  left join public.profiles pr on pr.user_id = tm.user_id
  left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
  where tm.team_id = p_team_id
    and (
      (cardinality(v_squad) = 0 and tm.status = 'active' and tm.in_squad = true)
      or
      (cardinality(v_squad) > 0 and (
        tm.user_id = any(v_squad) or tm.unclaimed_id = any(v_squad)
      ))
    )
  on conflict do nothing;

  insert into public.cricket_match_players (
    match_player_id, match_id, is_playing_xi, batting_order,
    is_captain, is_vice_captain, is_wicket_keeper, is_substitute
  )
  select
    mp.match_player_id, mp.match_id, true, null,
    coalesce(mp.user_id = v_captain, false), false, false, false
  from public.match_players mp
  where mp.match_id = p_match_id
    and mp.team_side = p_team_side
  on conflict (match_player_id) do update set
    match_id = excluded.match_id,
    is_playing_xi = true,
    is_captain = excluded.is_captain,
    -- Preserve choices that may have been set later in the match flow.
    is_wicket_keeper = public.cricket_match_players.is_wicket_keeper,
    is_substitute = public.cricket_match_players.is_substitute,
    batting_order = public.cricket_match_players.batting_order,
    updated_at = now();
end;
$$;
revoke all on function public._materialize_cricket_tournament_side(uuid, uuid, text)
  from public, anon, authenticated;

create or replace function public._sync_cricket_tournament_slot_players()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.sport_id <> 'cricket' or new.tournament_id is null then
    return new;
  end if;

  if old.team_a_id is distinct from new.team_a_id then
    if old.team_a_id is not null then
      if new.status <> 'scheduled'
         or exists (select 1 from public.match_innings mi where mi.match_id = new.match_id) then
        raise exception 'Cannot replace Team A after Cricket match setup has begun'
          using errcode = '22023';
      end if;
      delete from public.match_players
       where match_id = new.match_id and team_side = 'team_a';
    end if;
    if new.team_a_id is not null then
      perform public._materialize_cricket_tournament_side(
        new.match_id, new.team_a_id, 'team_a'
      );
    end if;
  end if;

  if old.team_b_id is distinct from new.team_b_id then
    if old.team_b_id is not null then
      if new.status <> 'scheduled'
         or exists (select 1 from public.match_innings mi where mi.match_id = new.match_id) then
        raise exception 'Cannot replace Team B after Cricket match setup has begun'
          using errcode = '22023';
      end if;
      delete from public.match_players
       where match_id = new.match_id and team_side = 'team_b';
    end if;
    if new.team_b_id is not null then
      perform public._materialize_cricket_tournament_side(
        new.match_id, new.team_b_id, 'team_b'
      );
    end if;
  end if;

  return new;
end;
$$;
revoke all on function public._sync_cricket_tournament_slot_players()
  from public, anon, authenticated;

drop trigger if exists matches_materialize_cricket_tournament_slots
  on public.matches;
create trigger matches_materialize_cricket_tournament_slots
  after update of team_a_id, team_b_id on public.matches
  for each row
  when (
    old.team_a_id is distinct from new.team_a_id
    or old.team_b_id is distinct from new.team_b_id
  )
  execute function public._sync_cricket_tournament_slot_players();

-- =============================================================================
-- 3. Cricket result -> generic parent winner
-- =============================================================================
-- cricket_matches.result is authoritative Cricket detail. matches.winner_id
-- remains the sport-neutral indexed winner used by brackets/standings.
-- =============================================================================
create or replace function public._sync_cricket_result_to_parent()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_winner uuid;
  v_team_a uuid;
  v_team_b uuid;
begin
  v_winner := nullif(new.result->>'winner_team_id', '')::uuid;

  select m.team_a_id, m.team_b_id
    into v_team_a, v_team_b
    from public.matches m
   where m.match_id = new.match_id;

  if v_winner is not null
     and v_winner is distinct from v_team_a
     and v_winner is distinct from v_team_b then
    raise exception 'Cricket result winner must be one of the two match teams'
      using errcode = '23514';
  end if;

  update public.matches
     set winner_id = v_winner,
         updated_at = now()
   where match_id = new.match_id
     and winner_id is distinct from v_winner;

  return new;
end;
$$;
revoke all on function public._sync_cricket_result_to_parent()
  from public, anon, authenticated;

drop trigger if exists cricket_match_sync_parent_winner
  on public.cricket_matches;
create trigger cricket_match_sync_parent_winner
  after insert or update of result on public.cricket_matches
  for each row execute function public._sync_cricket_result_to_parent();

-- Remove the legacy reverse source of truth if present.
drop trigger if exists match_sync_winner_id on public.matches;
drop function if exists public.trg_sync_match_winner_id();

-- Backfill generic winner from the canonical child if necessary.
update public.matches m
   set winner_id = nullif(cm.result->>'winner_team_id', '')::uuid,
       updated_at = now()
  from public.cricket_matches cm
 where cm.match_id = m.match_id
   and m.sport_id = 'cricket'
   and m.winner_id is distinct from nullif(cm.result->>'winner_team_id', '')::uuid;

-- Canonical player-of-the-match FK now belongs to the Cricket extension.
do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conrelid = 'public.cricket_matches'::regclass
       and conname = 'cricket_matches_player_of_the_match_fkey'
  ) then
    alter table public.cricket_matches
      add constraint cricket_matches_player_of_the_match_fkey
      foreign key (player_of_the_match_id)
      references public.match_players(match_player_id)
      on delete set null;
  end if;
end
$$;

-- =============================================================================
-- 4. Standings + bracket advancement
-- =============================================================================
create or replace function public.recalculate_tournament_standings(
  p_tournament_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament     record;
  v_team           record;
  v_matches_played integer;
  v_wins           integer;
  v_losses         integer;
  v_ties           integer;
  v_no_results     integer;
  v_points         integer;
  v_runs_scored    integer;
  v_overs_faced    numeric(6,2);
  v_runs_conceded  integer;
  v_overs_bowled   numeric(6,2);
  v_nrr            numeric(6,3);
  v_bat_rr         numeric;
  v_bowl_rr        numeric;
  v_max_overs      numeric;
begin
  select * into v_tournament
    from public.tournaments
   where tournament_id = p_tournament_id;
  if not found then
    return;
  end if;

  v_max_overs := coalesce(
    (v_tournament.format->>'max_overs')::numeric,
    (v_tournament.format->>'overs_per_innings')::numeric,
    20.0
  );

  for v_team in
    select team_id, group_id
      from public.tournament_teams
     where tournament_id = p_tournament_id
       and status = 'approved'
  loop
    select
      count(*) filter (
        where m.status in ('completed','tied','no_result','abandoned','walkover')
      ),
      count(*) filter (
        where m.status in ('completed','walkover') and m.winner_id = v_team.team_id
      ),
      count(*) filter (
        where m.status in ('completed','walkover')
          and m.winner_id is not null
          and m.winner_id <> v_team.team_id
      ),
      count(*) filter (where m.status = 'tied'),
      count(*) filter (where m.status in ('no_result','abandoned'))
    into v_matches_played, v_wins, v_losses, v_ties, v_no_results
    from public.matches m
    where m.tournament_id = p_tournament_id
      and (m.team_a_id = v_team.team_id or m.team_b_id = v_team.team_id);

    v_points := (v_wins * 2) + v_ties + v_no_results;

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          when mis.total_wickets >= 10 then v_max_overs
          else floor(mis.legal_ball_count / 6)
               + (mis.legal_ball_count % 6) / 10.0
        end
      ), 0)
    into v_runs_scored, v_overs_faced
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and case mi.batting_team_side
            when 'team_a' then m.team_a_id else m.team_b_id
          end = v_team.team_id;

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          when mis.total_wickets >= 10 then v_max_overs
          else floor(mis.legal_ball_count / 6)
               + (mis.legal_ball_count % 6) / 10.0
        end
      ), 0)
    into v_runs_conceded, v_overs_bowled
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and case mi.bowling_team_side
            when 'team_a' then m.team_a_id else m.team_b_id
          end = v_team.team_id;

    v_bat_rr := case
      when v_overs_faced > 0 then
        v_runs_scored / (
          floor(v_overs_faced)
          + ((v_overs_faced - floor(v_overs_faced)) * 10 / 6.0)
        )
      else 0.0
    end;
    v_bowl_rr := case
      when v_overs_bowled > 0 then
        v_runs_conceded / (
          floor(v_overs_bowled)
          + ((v_overs_bowled - floor(v_overs_bowled)) * 10 / 6.0)
        )
      else 0.0
    end;
    v_nrr := round((v_bat_rr - v_bowl_rr)::numeric, 3);

    insert into public.tournament_standings (
      tournament_id, team_id, group_id, matches_played, wins, losses, ties,
      no_results, points, runs_scored, overs_faced, runs_conceded,
      overs_bowled, net_run_rate, updated_at
    ) values (
      p_tournament_id, v_team.team_id, v_team.group_id, v_matches_played,
      v_wins, v_losses, v_ties, v_no_results, v_points, v_runs_scored,
      v_overs_faced, v_runs_conceded, v_overs_bowled, v_nrr, now()
    )
    on conflict (tournament_id, team_id) do update set
      group_id = excluded.group_id,
      matches_played = excluded.matches_played,
      wins = excluded.wins,
      losses = excluded.losses,
      ties = excluded.ties,
      no_results = excluded.no_results,
      points = excluded.points,
      runs_scored = excluded.runs_scored,
      overs_faced = excluded.overs_faced,
      runs_conceded = excluded.runs_conceded,
      overs_bowled = excluded.overs_bowled,
      net_run_rate = excluded.net_run_rate,
      updated_at = now();
  end loop;
end;
$$;
revoke all on function public.recalculate_tournament_standings(uuid)
  from public, anon, authenticated;
grant execute on function public.recalculate_tournament_standings(uuid)
  to service_role;

create or replace function public.trg_advance_tournament_bracket()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.tournament_id is null then
    return new;
  end if;

  if new.status in ('completed','walkover')
     and new.winner_id is not null
     and (old.status is distinct from new.status
          or old.winner_id is distinct from new.winner_id) then
    update public.matches
       set team_a_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_a_id = new.match_id
       and team_a_id is null;

    update public.matches
       set team_b_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_b_id = new.match_id
       and team_b_id is null;
  end if;

  if old.status is distinct from new.status
     or old.winner_id is distinct from new.winner_id then
    perform public.recalculate_tournament_standings(new.tournament_id);
  end if;

  return new;
end;
$$;
revoke all on function public.trg_advance_tournament_bracket()
  from public, anon, authenticated;
drop trigger if exists match_advance_tournament_bracket on public.matches;
create trigger match_advance_tournament_bracket
  after update on public.matches
  for each row execute function public.trg_advance_tournament_bracket();

-- =============================================================================
-- 5. Tournament draw -> shared shell + Cricket child
-- =============================================================================
drop function if exists public.tournament_generate_fixtures(uuid, jsonb);

create or replace function public.tournament_generate_fixtures(
  p_tournament_id uuid,
  p_slots         jsonb,
  p_seed_order    uuid[]
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_t        record;
  v_existing integer;
  v_created  integer;
  v_rules    jsonb;
  v_count    integer;
  v_distinct integer;
  v_bad      integer;
  v_ids      jsonb;
  v_slot     jsonb;
  v_mid      uuid;
  v_team     uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can publish fixtures'
      using errcode = '42501';
  end if;

  select t.status, t.format, t.sport_id into v_t
    from public.tournaments t
   where t.tournament_id = p_tournament_id;
  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;
  if v_t.sport_id <> 'cricket' then
    raise exception 'The current tournament fixture publisher is Cricket-only'
      using errcode = '23514';
  end if;
  if v_t.status in ('completed','cancelled','abandoned') then
    raise exception 'This tournament is closed' using errcode = '22023';
  end if;

  v_rules := public._normalize_cricket_match_rules(coalesce(v_t.format, '{}'::jsonb));

  select count(*) into v_existing
    from public.matches where tournament_id = p_tournament_id;
  if v_existing > 0 then
    raise exception 'The draw is already locked (% fixtures exist)', v_existing
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_slots) <> 'array' or jsonb_array_length(p_slots) = 0 then
    raise exception 'No fixtures to publish' using errcode = '22023';
  end if;

  select count(*) into v_bad
    from jsonb_array_elements(p_slots) s(elem)
   where s.elem->>'slot_id' is null;
  if v_bad > 0 then
    raise exception 'Every fixture needs a slot_id' using errcode = '22023';
  end if;

  select count(*), count(distinct s.elem->>'slot_id')
    into v_count, v_distinct
    from jsonb_array_elements(p_slots) s(elem);
  if v_distinct < v_count then
    raise exception 'Duplicate slot_id in the draw' using errcode = '22023';
  end if;

  select count(*) into v_bad
    from jsonb_array_elements(p_slots) s(elem)
   where (s.elem->>'team_a_id' is null and s.elem->>'prev_slot_a' is null)
      or (s.elem->>'team_b_id' is null and s.elem->>'prev_slot_b' is null);
  if v_bad > 0 then
    raise exception 'A fixture side is neither a team nor a feeder'
      using errcode = '22023';
  end if;

  select jsonb_object_agg(s.elem->>'slot_id', gen_random_uuid()) into v_ids
    from jsonb_array_elements(p_slots) s(elem);

  select count(*) into v_bad
    from jsonb_array_elements(p_slots) s(elem)
   where (s.elem->>'prev_slot_a' is not null
          and not jsonb_exists(v_ids, s.elem->>'prev_slot_a'))
      or (s.elem->>'prev_slot_b' is not null
          and not jsonb_exists(v_ids, s.elem->>'prev_slot_b'));
  if v_bad > 0 then
    raise exception 'A fixture feeds from a slot that is not in the draw'
      using errcode = '22023';
  end if;

  with inserted as (
    insert into public.matches (
      match_id, tournament_id, match_type, stage, round,
      bracket_round_number, bracket_match_number,
      prev_match_a_id, prev_match_b_id,
      team_a_id, team_b_id, venue, sport_id,
      scheduled_start_time, status, created_by
    )
    select
      (v_ids->>(s.elem->>'slot_id'))::uuid,
      p_tournament_id,
      'tournament',
      case
        when s.elem->>'round' ilike '%final%'
             and s.elem->>'round' not ilike '%semi%'
             and s.elem->>'round' not ilike '%quarter%' then 'final'
        when s.elem->>'round' ilike '%semi%' then 'semi_final'
        when s.elem->>'round' ilike '%quarter%' then 'quarter_final'
        else 'group'
      end::public.match_stage,
      s.elem->>'round',
      (s.elem->>'bracket_round_number')::integer,
      (s.elem->>'bracket_match_number')::integer,
      (v_ids->>(s.elem->>'prev_slot_a'))::uuid,
      (v_ids->>(s.elem->>'prev_slot_b'))::uuid,
      (s.elem->>'team_a_id')::uuid,
      (s.elem->>'team_b_id')::uuid,
      nullif(s.elem->>'venue', ''),
      'cricket',
      coalesce((s.elem->>'scheduled_start_time')::timestamptz, now()),
      'scheduled',
      v_uid
    from jsonb_array_elements(p_slots) s(elem)
    returning match_id
  )
  select count(*) into v_created from inserted;

  insert into public.cricket_matches (match_id, format_code, rules_snapshot)
  select (v_ids->>(s.elem->>'slot_id'))::uuid, null, v_rules
    from jsonb_array_elements(p_slots) s(elem)
  on conflict (match_id) do update set
    rules_snapshot = excluded.rules_snapshot,
    updated_at = now();

  -- Initial concrete sides. Unresolved later rounds are handled when the
  -- bracket advancement trigger fills their team ids.
  for v_slot in
    select s.elem from jsonb_array_elements(p_slots) s(elem)
  loop
    v_mid := (v_ids->>(v_slot->>'slot_id'))::uuid;

    v_team := (v_slot->>'team_a_id')::uuid;
    if v_team is not null then
      perform public._materialize_cricket_tournament_side(v_mid, v_team, 'team_a');
    end if;

    v_team := (v_slot->>'team_b_id')::uuid;
    if v_team is not null then
      perform public._materialize_cricket_tournament_side(v_mid, v_team, 'team_b');
    end if;
  end loop;

  if p_seed_order is not null then
    update public.tournament_teams tt
       set seed_number = ord.pos,
           updated_at = now()
      from unnest(p_seed_order) with ordinality as ord(team_id, pos)
     where tt.tournament_id = p_tournament_id
       and tt.team_id = ord.team_id
       and tt.status = 'approved';
  end if;

  update public.tournaments
     set status = 'upcoming', updated_at = now()
   where tournament_id = p_tournament_id;

  perform public.recalculate_tournament_standings(p_tournament_id);
  return v_created;
end;
$$;
revoke all on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  from public, anon;
grant execute on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  to authenticated;

-- =============================================================================
-- 6. Tournament live-ops guard + canonical Cricket mutations
-- =============================================================================
create or replace function public._require_match_organizer(p_match_id uuid)
returns public.matches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  if (select auth.uid()) is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select * into v_match from public.matches where match_id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;
  if v_match.tournament_id is null then
    raise exception 'Match is not part of a tournament' using errcode = '22023';
  end if;
  if not public.is_tournament_organizer(v_match.tournament_id) then
    raise exception 'Only tournament organizers can run live ops'
      using errcode = '42501';
  end if;
  return v_match;
end;
$$;
revoke all on function public._require_match_organizer(uuid)
  from public, anon, authenticated;

create or replace function public.tournament_reschedule_match(
  p_match_id uuid,
  p_start    timestamptz,
  p_venue    text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);
  if v_match.status in ('completed','walkover') then
    raise exception 'Cannot reschedule a finished match' using errcode = '22023';
  end if;

  update public.matches
     set scheduled_start_time = p_start,
         venue = coalesce(nullif(p_venue, ''), venue),
         updated_at = now()
   where match_id = p_match_id;
end;
$$;
revoke all on function public.tournament_reschedule_match(uuid, timestamptz, text)
  from public, anon, authenticated;

create or replace function public.tournament_abandon_match(
  p_match_id      uuid,
  p_mode          text,
  p_reschedule_to timestamptz default null,
  p_reason        text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match  public.matches;
  v_result jsonb;
begin
  v_match := public._require_match_organizer(p_match_id);

  select cm.result into v_result
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;
  if not found then
    raise exception 'Cricket match extension not found' using errcode = 'P0002';
  end if;

  if p_mode not in ('reschedule','no_result') then
    raise exception 'Unknown abandon mode: %', p_mode using errcode = '22023';
  end if;
  if p_mode = 'reschedule' and p_reschedule_to is null then
    raise exception 'A new date is required to reschedule' using errcode = '22023';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id,
    v_match.status,
    case when p_mode = 'reschedule'
         then 'scheduled'::public.match_status
         else 'no_result'::public.match_status end,
    coalesce(v_result, '{}'::jsonb)
      || jsonb_build_object('abandon_mode', p_mode),
    p_reason,
    (select auth.uid())
  );

  if p_mode = 'reschedule' then
    delete from public.match_innings where match_id = p_match_id;

    update public.cricket_matches
       set phase = 'toss',
           result = null,
           result_summary = null,
           revised_conditions = null,
           toss_won_by = null,
           toss_decision = null,
           toss_face = null,
           toss_recorded_at = null,
           openers_submitted_by = null,
           openers_submitted_at = null,
           player_of_the_match_id = null,
           updated_at = now()
     where match_id = p_match_id;

    update public.matches
       set status = 'scheduled',
           scheduled_start_time = p_reschedule_to,
           actual_start_time = null,
           completed_at = null,
           updated_at = now()
     where match_id = p_match_id;
  else
    update public.cricket_matches
       set result = jsonb_build_object(
             'winner_team_id', null,
             'win_type', 'no_result',
             'description', coalesce(nullif(p_reason, ''), 'Match abandoned — no result')
           ),
           result_summary = jsonb_build_object(
             'description', coalesce(nullif(p_reason, ''), 'Match abandoned — no result')
           ),
           updated_at = now()
     where match_id = p_match_id;

    update public.matches
       set status = 'no_result',
           completed_at = now(),
           updated_at = now()
     where match_id = p_match_id;
  end if;
end;
$$;
revoke all on function public.tournament_abandon_match(uuid, text, timestamptz, text)
  from public, anon, authenticated;

create or replace function public.tournament_declare_walkover(
  p_match_id       uuid,
  p_winner_team_id uuid,
  p_reason         text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if p_winner_team_id is null
     or (p_winner_team_id is distinct from v_match.team_a_id
         and p_winner_team_id is distinct from v_match.team_b_id) then
    raise exception 'Winner must be one of the two teams in this fixture'
      using errcode = '22023';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id, v_match.status, 'walkover',
    jsonb_build_object('winner_team_id', p_winner_team_id),
    p_reason, (select auth.uid())
  );

  update public.cricket_matches
     set result = jsonb_build_object(
           'winner_team_id', p_winner_team_id,
           'win_type', 'walkover',
           'win_margin', null,
           'description', 'Won by walkover',
           'summary', 'Won by walkover'
         ),
         result_summary = jsonb_build_object('description', 'Won by walkover'),
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status = 'walkover',
         completed_at = now(),
         updated_at = now()
   where match_id = p_match_id;
end;
$$;
revoke all on function public.tournament_declare_walkover(uuid, uuid, text)
  from public, anon, authenticated;

create or replace function public.tournament_override_result(
  p_match_id       uuid,
  p_winner_team_id uuid,
  p_reason         text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match  public.matches;
  v_result jsonb;
begin
  v_match := public._require_match_organizer(p_match_id);

  if p_reason is null or length(btrim(p_reason)) < 10 then
    raise exception 'An override requires a reason of at least 10 characters'
      using errcode = '22023';
  end if;
  if p_winner_team_id is null
     or (p_winner_team_id is distinct from v_match.team_a_id
         and p_winner_team_id is distinct from v_match.team_b_id) then
    raise exception 'Winner must be one of the two teams in this fixture'
      using errcode = '22023';
  end if;

  select cm.result into v_result
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;
  if not found then
    raise exception 'Cricket match extension not found' using errcode = 'P0002';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id, v_match.status, 'completed',
    coalesce(v_result, '{}'::jsonb)
      || jsonb_build_object('overridden_to', p_winner_team_id),
    p_reason, (select auth.uid())
  );

  update public.cricket_matches
     set result = coalesce(result, '{}'::jsonb) || jsonb_build_object(
           'winner_team_id', p_winner_team_id,
           'overridden', true,
           'override_reason', p_reason,
           'overridden_by', (select auth.uid()),
           'overridden_at', now()
         ),
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status = 'completed',
         completed_at = coalesce(completed_at, now()),
         updated_at = now()
   where match_id = p_match_id;
end;
$$;
revoke all on function public.tournament_override_result(uuid, uuid, text)
  from public, anon, authenticated;

create or replace function public.tournament_revise_match_conditions(
  p_match_id       uuid,
  p_revised_overs  integer,
  p_bowler_quota   integer,
  p_revised_target integer default null,
  p_method         text default 'run_rate',
  p_reason         text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match    public.matches;
  v_rules    jsonb;
  v_original integer;
begin
  if p_method not in ('run_rate','dls','custom','none') then
    raise exception 'Unknown target method %', p_method using errcode = '22023';
  end if;

  v_match := public._require_match_organizer(p_match_id);
  if v_match.status in ('completed','abandoned','walkover','no_result') then
    raise exception 'This match is already finished' using errcode = '22023';
  end if;

  select cm.rules_snapshot into v_rules
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;
  if not found then
    raise exception 'Cricket match extension not found' using errcode = 'P0002';
  end if;

  if p_revised_overs is null or p_revised_overs < 5 then
    raise exception 'A result needs at least 5 overs per side' using errcode = '22023';
  end if;
  v_original := coalesce((v_rules->>'overs_per_innings')::integer, 20);
  if p_revised_overs > v_original then
    raise exception 'Overs can only be reduced, not extended' using errcode = '22023';
  end if;
  if p_bowler_quota is null or p_bowler_quota < 1 then
    raise exception 'Each bowler needs at least one over' using errcode = '22023';
  end if;

  update public.cricket_matches
     set rules_snapshot = public._normalize_cricket_match_rules(
           rules_snapshot || jsonb_build_object(
             'overs_per_innings', p_revised_overs,
             'max_overs_per_bowler', p_bowler_quota
           )
         ),
         revised_conditions = jsonb_build_object(
           'applied_at', now(),
           'applied_by', (select auth.uid()),
           'original_overs', v_original,
           'revised_overs', p_revised_overs,
           'original_quota', coalesce((v_rules->>'max_overs_per_bowler')::integer, 4),
           'revised_quota', p_bowler_quota,
           'revised_target', p_revised_target,
           'method', p_method,
           'reason', nullif(btrim(coalesce(p_reason, '')), '')
         ),
         updated_at = now()
   where match_id = p_match_id;
end;
$$;
revoke all on function public.tournament_revise_match_conditions(
  uuid, integer, integer, integer, text, text
) from public, anon, authenticated;

create or replace function public.tournament_trigger_super_over(
  p_match_id      uuid,
  p_bats_first_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match  public.matches;
  v_rules  jsonb;
  v_result jsonb;
begin
  v_match := public._require_match_organizer(p_match_id);
  if v_match.status <> 'tied' then
    raise exception 'A super over needs a tied match' using errcode = '22023';
  end if;
  if p_bats_first_id is null
     or (p_bats_first_id is distinct from v_match.team_a_id
         and p_bats_first_id is distinct from v_match.team_b_id) then
    raise exception 'Choose one of the two sides to bat first' using errcode = '22023';
  end if;

  select cm.rules_snapshot, cm.result into v_rules, v_result
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;
  if not found then
    raise exception 'Cricket match extension not found' using errcode = 'P0002';
  end if;
  if not coalesce((v_rules->>'super_over_enabled')::boolean, true) then
    raise exception 'Super overs are disabled for this tournament'
      using errcode = '22023';
  end if;

  update public.cricket_matches
     set result = coalesce(v_result, '{}'::jsonb) || jsonb_build_object(
           'super_over', jsonb_build_object(
             'triggered_at', now(),
             'triggered_by', (select auth.uid()),
             'bats_first_id', p_bats_first_id
           )
         ),
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status = 'super_over',
         completed_at = null,
         updated_at = now()
   where match_id = p_match_id;
end;
$$;
revoke all on function public.tournament_trigger_super_over(uuid, uuid)
  from public, anon, authenticated;

-- =============================================================================
-- 7. Tournament live board reads canonical Cricket result
-- =============================================================================
create or replace function public.tournament_live_board(p_tournament_id uuid)
returns table (
  match_id             uuid,
  venue                text,
  status               text,
  scheduled_start_time timestamptz,
  round                text,
  team_a_id            uuid,
  team_a_name          text,
  team_b_id            uuid,
  team_b_name          text,
  winner_id            uuid,
  result               jsonb,
  scorer_id            uuid,
  scorer_name          text,
  last_ball_at         timestamptz,
  innings_lines        jsonb
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    m.match_id,
    m.venue,
    m.status::text,
    m.scheduled_start_time,
    m.round,
    m.team_a_id,
    ta.team_name,
    m.team_b_id,
    tb.team_name,
    m.winner_id,
    cm.result,
    mo.user_id,
    pr.display_name,
    (select max(d.recorded_at)
       from public.match_deliveries d
      where d.match_id = m.match_id
        and d.is_undone = false),
    coalesce(
      (select jsonb_agg(
                jsonb_build_object(
                  'innings_number', mi.innings_number,
                  'batting_team_id',
                    case mi.batting_team_side
                      when 'team_a' then m.team_a_id else m.team_b_id
                    end,
                  'total_runs', mis.total_runs,
                  'total_wickets', mis.total_wickets,
                  'legal_ball_count', mis.legal_ball_count
                ) order by mi.innings_number)
         from public.match_innings mi
         join public.match_innings_state mis on mis.innings_id = mi.innings_id
        where mi.match_id = m.match_id),
      '[]'::jsonb
    )
  from public.matches m
  join public.cricket_matches cm on cm.match_id = m.match_id
  left join public.teams ta on ta.team_id = m.team_a_id
  left join public.teams tb on tb.team_id = m.team_b_id
  left join public.match_officials mo
         on mo.match_id = m.match_id and mo.role = 'scorer'
  left join public.profiles pr on pr.user_id = mo.user_id
  where m.tournament_id = p_tournament_id
    and m.sport_id = 'cricket'
    and exists (
      select 1
        from public.tournaments t
       where t.tournament_id = p_tournament_id
         and (
           (t.privacy = 'public' and t.status <> 'draft')
           or public.is_tournament_organizer(p_tournament_id)
           or exists (
             select 1
               from public.tournament_teams tt
              where tt.tournament_id = p_tournament_id
                and (public.is_team_manager(tt.team_id)
                     or (select auth.uid()) = any(tt.squad))
           )
         )
    )
  order by m.scheduled_start_time asc;
$$;
revoke all on function public.tournament_live_board(uuid) from public, anon;
grant execute on function public.tournament_live_board(uuid) to authenticated;

-- =============================================================================
-- 8. Unclaimed -> claimed match identity merge
-- =============================================================================
-- Existing registered/self-owned Cricket profile values win. During a duplicate
-- match-player merge, canonical Cricket match-player flags are merged before
-- the duplicate shared participant row is deleted.
-- =============================================================================
create or replace function public.finalize_unclaimed_claim()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tm record;
  v_existing_membership uuid;
  v_mp record;
  v_existing_match_player uuid;
  v_existing_team_side text;
begin
  if old.claimed_by_user_id is not null
     or new.claimed_by_user_id is null then
    return new;
  end if;

  if not exists (
    select 1 from public.profiles p
     where p.user_id = new.claimed_by_user_id
  ) then
    raise exception 'Claim target profile does not exist'
      using errcode = 'P0002';
  end if;

  insert into public.player_sports (user_id, sport_id)
  values (new.claimed_by_user_id, new.sport_id)
  on conflict (user_id, sport_id) do nothing;

  if new.sport_id = 'cricket' then
    insert into public.cricket_player_profiles as cp (
      user_id, sport_id, batting_style, bowling_style, player_role,
      preferred_ball_types, years_playing
    )
    select
      new.claimed_by_user_id, 'cricket', cup.batting_style, cup.bowling_style,
      cup.player_role, cup.preferred_ball_types, cup.years_playing
    from public.cricket_unclaimed_player_profiles cup
    where cup.unclaimed_id = new.unclaimed_id
    on conflict (user_id) do update set
      batting_style = coalesce(cp.batting_style, excluded.batting_style),
      bowling_style = coalesce(cp.bowling_style, excluded.bowling_style),
      player_role = coalesce(cp.player_role, excluded.player_role),
      preferred_ball_types = case
        when cardinality(cp.preferred_ball_types) = 0
          then excluded.preferred_ball_types
        else cp.preferred_ball_types
      end,
      years_playing = coalesce(cp.years_playing, excluded.years_playing);
  end if;

  -- Team membership identity rewrite.
  for v_tm in
    select tm.membership_id, tm.team_id, tm.jersey_number, tm.in_squad
      from public.team_members tm
     where tm.unclaimed_id = new.unclaimed_id
     for update
  loop
    v_existing_membership := null;

    select tm.membership_id into v_existing_membership
      from public.team_members tm
     where tm.team_id = v_tm.team_id
       and tm.user_id = new.claimed_by_user_id
       and tm.status = 'active'
     order by tm.joined_at
     limit 1
     for update;

    if v_existing_membership is null then
      update public.team_members
         set user_id = new.claimed_by_user_id,
             unclaimed_id = null,
             is_primary = false
       where membership_id = v_tm.membership_id;
    else
      delete from public.team_members
       where membership_id = v_tm.membership_id;

      update public.team_members
         set in_squad = in_squad or v_tm.in_squad,
             jersey_number = coalesce(jersey_number, v_tm.jersey_number)
       where membership_id = v_existing_membership;
    end if;
  end loop;

  -- Match participant identity rewrite.
  for v_mp in
    select
      mp.match_player_id,
      mp.match_id,
      mp.team_side,
      mp.display_name,
      mp.jersey_number,
      mp.role,
      mp.is_in_playing_xi,
      mp.batting_order
    from public.match_players mp
    where mp.unclaimed_id = new.unclaimed_id
    for update
  loop
    v_existing_match_player := null;
    v_existing_team_side := null;

    select mp.match_player_id, mp.team_side
      into v_existing_match_player, v_existing_team_side
      from public.match_players mp
     where mp.match_id = v_mp.match_id
       and mp.user_id = new.claimed_by_user_id
     limit 1
     for update;

    if v_existing_match_player is null then
      -- Preserve match_player_id, so every delivery/wicket FK remains valid.
      update public.match_players
         set user_id = new.claimed_by_user_id,
             unclaimed_id = null
       where match_player_id = v_mp.match_player_id;
    else
      if v_existing_team_side is distinct from v_mp.team_side then
        raise exception 'Claim would place the same user on both sides of match %',
          v_mp.match_id using errcode = '23514';
      end if;

      -- Merge canonical Cricket participant state BEFORE deleting the duplicate.
      if new.sport_id = 'cricket' then
        insert into public.cricket_match_players (
          match_player_id, match_id, is_playing_xi, batting_order,
          is_captain, is_vice_captain, is_wicket_keeper, is_substitute
        )
        select
          v_existing_match_player,
          cmp.match_id,
          cmp.is_playing_xi,
          cmp.batting_order,
          cmp.is_captain,
          cmp.is_vice_captain,
          cmp.is_wicket_keeper,
          cmp.is_substitute
        from public.cricket_match_players cmp
        where cmp.match_player_id = v_mp.match_player_id
        on conflict (match_player_id) do update set
          is_playing_xi = public.cricket_match_players.is_playing_xi
                          or excluded.is_playing_xi,
          batting_order = coalesce(
            public.cricket_match_players.batting_order,
            excluded.batting_order
          ),
          is_captain = public.cricket_match_players.is_captain
                       or excluded.is_captain,
          is_vice_captain = public.cricket_match_players.is_vice_captain
                            or excluded.is_vice_captain,
          is_wicket_keeper = public.cricket_match_players.is_wicket_keeper
                             or excluded.is_wicket_keeper,
          is_substitute = public.cricket_match_players.is_substitute
                          or excluded.is_substitute,
          updated_at = now();

        update public.cricket_matches
           set player_of_the_match_id = v_existing_match_player,
               updated_at = now()
         where player_of_the_match_id = v_mp.match_player_id;
      end if;

      -- Transitional parent FK stays coherent until Phase 3 drops the column.
      update public.matches
         set player_of_the_match_id = v_existing_match_player
       where player_of_the_match_id = v_mp.match_player_id;

      update public.match_innings_state
         set striker_id = v_existing_match_player
       where striker_id = v_mp.match_player_id;
      update public.match_innings_state
         set non_striker_id = v_existing_match_player
       where non_striker_id = v_mp.match_player_id;
      update public.match_innings_state
         set bowler_id = v_existing_match_player
       where bowler_id = v_mp.match_player_id;

      update public.match_deliveries
         set striker_id = v_existing_match_player
       where striker_id = v_mp.match_player_id;
      update public.match_deliveries
         set non_striker_id = v_existing_match_player
       where non_striker_id = v_mp.match_player_id;
      update public.match_deliveries
         set bowler_id = v_existing_match_player
       where bowler_id = v_mp.match_player_id;
      update public.match_deliveries
         set fielder_id = v_existing_match_player
       where fielder_id = v_mp.match_player_id;

      update public.match_wickets
         set player_out_id = v_existing_match_player
       where player_out_id = v_mp.match_player_id;
      update public.match_wickets
         set credited_bowler_id = v_existing_match_player
       where credited_bowler_id = v_mp.match_player_id;
      update public.match_wickets
         set primary_fielder_id = v_existing_match_player
       where primary_fielder_id = v_mp.match_player_id;
      update public.match_wickets
         set assisted_fielder_id = v_existing_match_player
       where assisted_fielder_id = v_mp.match_player_id;

      -- match_teams keeps these transitional Cricket references until Phase 3.
      update public.match_teams
         set captain_player_id = v_existing_match_player
       where captain_player_id = v_mp.match_player_id;
      update public.match_teams
         set keeper_player_id = v_existing_match_player
       where keeper_player_id = v_mp.match_player_id;

      -- Keep deprecated parent columns coherent until they are physically
      -- removed in Phase 3. They are no longer canonical after Phase 2B.
      update public.match_players
         set jersey_number = coalesce(jersey_number, v_mp.jersey_number),
             role = case when role = 'player' then v_mp.role else role end,
             is_in_playing_xi = is_in_playing_xi or v_mp.is_in_playing_xi,
             batting_order = coalesce(batting_order, v_mp.batting_order)
       where match_player_id = v_existing_match_player;

      delete from public.match_players
       where match_player_id = v_mp.match_player_id;
    end if;
  end loop;

  perform public.migrate_player_stats(new.unclaimed_id, new.claimed_by_user_id);
  return new;
end;
$$;
revoke all on function public.finalize_unclaimed_claim()
  from public, anon, authenticated;

-- =============================================================================
-- 9. Phase-1 compatibility mirrors are no longer needed
-- =============================================================================
drop trigger if exists matches_sync_cricket_extension on public.matches;
drop function if exists public.sync_legacy_match_to_cricket_extension();

drop trigger if exists match_players_sync_cricket_extension on public.match_players;
drop function if exists public.sync_legacy_match_player_to_cricket_extension();

-- Phase 2A already removes this one; repeat idempotently.
drop trigger if exists match_teams_sync_cricket_extension on public.match_teams;
drop function if exists public.sync_legacy_match_side_to_cricket_extension();

-- =============================================================================
-- 10. Transitional-column comments after mirror removal
-- =============================================================================
comment on column public.matches.match_format is
  'DEPRECATED. No longer read or mirrored by Phase-2 Cricket runtime. Remove in Phase 3.';
comment on column public.matches.format is
  'DEPRECATED. Cricket rules are canonical in cricket_matches.rules_snapshot. Remove in Phase 3.';
comment on column public.matches.toss_won_by is
  'DEPRECATED. Canonical value is cricket_matches.toss_won_by. Remove in Phase 3.';
comment on column public.matches.toss_decision is
  'DEPRECATED. Canonical value is cricket_matches.toss_decision. Remove in Phase 3.';
comment on column public.matches.toss_face is
  'DEPRECATED. Canonical value is cricket_matches.toss_face. Remove in Phase 3.';
comment on column public.matches.start_phase is
  'DEPRECATED. Canonical value is cricket_matches.phase. Remove in Phase 3.';
comment on column public.matches.openers_submitted_by is
  'DEPRECATED. Canonical value is cricket_matches.openers_submitted_by. Remove in Phase 3.';
comment on column public.matches.openers_submitted_at is
  'DEPRECATED. Canonical value is cricket_matches.openers_submitted_at. Remove in Phase 3.';
comment on column public.matches.scoring_mode is
  'DEPRECATED. Canonical value is cricket_matches.scoring_mode. Remove in Phase 3.';
comment on column public.matches.revised_conditions is
  'DEPRECATED. Canonical value is cricket_matches.revised_conditions. Remove in Phase 3.';
comment on column public.matches.result is
  'DEPRECATED. Cricket result detail is canonical in cricket_matches.result; matches.winner_id is shared. Remove in Phase 3.';
comment on column public.matches.result_summary is
  'DEPRECATED. Canonical value is cricket_matches.result_summary. Remove in Phase 3.';
comment on column public.matches.player_of_the_match_id is
  'DEPRECATED. Canonical value is cricket_matches.player_of_the_match_id. Remove in Phase 3.';

comment on column public.match_players.role is
  'DEPRECATED. Cricket role flags are canonical in cricket_match_players. Remove in Phase 3.';
comment on column public.match_players.is_in_playing_xi is
  'DEPRECATED. Canonical value is cricket_match_players.is_playing_xi. Remove in Phase 3.';
comment on column public.match_players.batting_order is
  'DEPRECATED. Canonical value is cricket_match_players.batting_order. Remove in Phase 3.';
