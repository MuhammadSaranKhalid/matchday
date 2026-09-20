-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 2A
-- Core Cricket caller migration
-- =============================================================================
--
-- PRECONDITION
--   Phase 1 exists:
--     public.cricket_matches
--     public.cricket_match_players
--     public.cricket_match_details
--
-- SCOPE
--   This migration moves the CORE CRICKET RUNTIME to the Cricket extension:
--
--     challenge accept -> matches + cricket_matches
--     lineup          -> match_players + cricket_match_players
--     toss             -> cricket_matches
--     openers          -> cricket_matches + innings
--     start innings    -> cricket_matches + innings
--     result           -> cricket_matches; matches keeps lifecycle/winner
--
-- TRANSITION
--   Phase-1 mirrors are intentionally retained in 2A because tournament/
--   console SQL still writes transitional columns. Phase 2B migrates those
--   writers, then removes the mirrors.
--
-- IMPORTANT
--   This is a FORWARD migration. Do not edit already-applied Phase-1 history.
-- =============================================================================


-- =============================================================================
-- 1. Cricket format contract
-- =============================================================================
--
-- Phase 1 used public.match_format for cricket_matches.format_code. That enum
-- cannot represent the actual preset catalogue (t10, list_a, super8, tape,
-- box, ...). The rules snapshot is authoritative; the preset code is optional
-- metadata and therefore becomes nullable text.
-- =============================================================================

drop view if exists public.cricket_match_details;

alter table public.cricket_matches
  alter column format_code drop default,
  alter column format_code drop not null,
  alter column format_code type text using format_code::text;


create or replace function public._normalize_cricket_match_rules(p_rules jsonb)
returns jsonb
language sql
immutable
set search_path = public, pg_temp
as $$
  select jsonb_strip_nulls(
    jsonb_build_object(
      'overs_per_innings', coalesce(
        (f->>'overs_per_innings')::int,
        (f->>'max_overs')::int,
        20
      ),
      'players_per_team', coalesce((f->>'players_per_team')::int, 11),
      'balls_per_over', coalesce((f->>'balls_per_over')::int, 6),
      'max_overs_per_bowler',
        coalesce((f->>'max_overs_per_bowler')::int, 4),
      'innings_per_side', coalesce((f->>'innings_per_side')::int, 1),
      'ball_type', coalesce(nullif(f->>'ball_type', ''), 'leather'),
      'super_over_enabled',
        coalesce((f->>'super_over_enabled')::boolean, true),
      'dls_enabled',
        coalesce((f->>'dls_enabled')::boolean, true),
      'wickets_to_all_out', (f->>'wickets_to_all_out')::int,
      'end_change_balls', (f->>'end_change_balls')::int
    )
  )
  from (select coalesce(p_rules, '{}'::jsonb) as f) s;
$$;

revoke all
  on function public._normalize_cricket_match_rules(jsonb)
  from public;

-- Internal helper. Database-owner functions can call it; Data API roles cannot.


alter table public.cricket_matches
  alter column rules_snapshot
  set default public._normalize_cricket_match_rules('{}'::jsonb);


comment on column public.cricket_matches.format_code is
  'Optional source preset code. Nullable because custom/challenge rules may '
  'not originate from a named preset. rules_snapshot is authoritative.';

comment on column public.cricket_matches.rules_snapshot is
  'Authoritative Cricket rules snapshot for this fixture. Never dynamically '
  're-read a mutable preset for an already-created match.';


-- =============================================================================
-- 2. Cricket participant helper
-- =============================================================================

create or replace function public._materialize_cricket_match_side(
  p_match_id        uuid,
  p_team_id         uuid,
  p_team_side       text,
  p_selected_refs   uuid[] default '{}'::uuid[],
  p_captain_user_id uuid default null,
  p_keeper_ref_id   uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if p_team_side not in ('team_a', 'team_b') then
    raise exception 'Invalid match side %', p_team_side
      using errcode = '22023';
  end if;

  if not exists (
    select 1
      from public.matches m
      join public.cricket_matches cm on cm.match_id = m.match_id
     where m.match_id = p_match_id
       and m.sport_id = 'cricket'
       and p_team_id in (m.team_a_id, m.team_b_id)
  ) then
    raise exception 'Team is not a side of this Cricket match'
      using errcode = '23514';
  end if;

  -- Shared participant identity only.
  insert into public.match_players (
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name,
    jersey_number
  )
  select
    p_match_id,
    p_team_side,
    tm.user_id,
    tm.unclaimed_id,
    coalesce(pr.display_name, up.display_name, 'Player'),
    tm.jersey_number
  from public.team_members tm
  left join public.profiles pr
    on pr.user_id = tm.user_id
  left join public.unclaimed_players up
    on up.unclaimed_id = tm.unclaimed_id
  where tm.team_id = p_team_id
    and tm.status = 'active'
    and tm.in_squad = true
    and (
      coalesce(array_length(p_selected_refs, 1), 0) = 0
      or tm.user_id = any(p_selected_refs)
      or tm.unclaimed_id = any(p_selected_refs)
    );

  -- Cricket-only participant state.
  --
  -- Phase-1's match_players mirror may already have inserted a child row using
  -- the legacy role enum. This explicit UPSERT is canonical for Phase 2 and,
  -- critically, allows captain + wicket-keeper simultaneously.
  insert into public.cricket_match_players (
    match_player_id,
    match_id,
    is_playing_xi,
    batting_order,
    is_captain,
    is_vice_captain,
    is_wicket_keeper,
    is_substitute
  )
  select
    mp.match_player_id,
    mp.match_id,
    true,
    null,
    coalesce(mp.user_id = p_captain_user_id, false),
    false,
    coalesce(
      mp.user_id = p_keeper_ref_id
      or mp.unclaimed_id = p_keeper_ref_id,
      false
    ),
    false
  from public.match_players mp
  where mp.match_id = p_match_id
    and mp.team_side = p_team_side
  on conflict (match_player_id)
  do update set
    match_id          = excluded.match_id,
    is_playing_xi     = excluded.is_playing_xi,
    is_captain        = excluded.is_captain,
    is_vice_captain   = excluded.is_vice_captain,
    is_wicket_keeper  = excluded.is_wicket_keeper,
    is_substitute     = excluded.is_substitute,
    updated_at        = now();
end;
$$;

revoke all
  on function public._materialize_cricket_match_side(
    uuid, uuid, text, uuid[], uuid, uuid
  )
  from public;


-- =============================================================================
-- 3. Cricket captain / batting-side helpers
-- =============================================================================

create or replace function public._is_match_creator(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.matches m
     where m.match_id = p_match_id
       and m.created_by is not null
       and m.created_by = (select auth.uid())
  );
$$;

revoke all on function public._is_match_creator(uuid) from public;


create or replace function public._is_match_side_captain(
  p_match_id uuid,
  p_team_id  uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.matches m
    where m.match_id = p_match_id
      and p_team_id is not null
      and p_team_id in (m.team_a_id, m.team_b_id)
      and (select auth.uid()) is not null
      and (
        exists (
          select 1
          from public.match_players mp
          join public.cricket_match_players cmp
            on cmp.match_player_id = mp.match_player_id
           and cmp.match_id = mp.match_id
          where mp.match_id = m.match_id
            and mp.user_id = (select auth.uid())
            and cmp.is_captain = true
            and (
              (p_team_id = m.team_a_id and mp.team_side = 'team_a')
              or
              (p_team_id = m.team_b_id and mp.team_side = 'team_b')
            )
        )
        -- Tournament fixtures may exist before a lineup is materialised.
        -- Fall back to the team's live captain/owner until the match lineup
        -- supplies its own captain snapshot.
        or (select auth.uid()) = public._team_current_captain(p_team_id)
      )
  );
$$;

revoke all on function public._is_match_side_captain(uuid, uuid) from public;


create or replace function public._is_match_captain(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.matches m
     where m.match_id = p_match_id
       and (
         public._is_match_side_captain(m.match_id, m.team_a_id)
         or public._is_match_side_captain(m.match_id, m.team_b_id)
       )
  );
$$;

revoke all on function public._is_match_captain(uuid) from public;


create or replace function public._cricket_batting_team_id(
  p_match_id       uuid,
  p_innings_number integer default 1
)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with x as (
    select
      m.team_a_id,
      m.team_b_id,
      case
        when cm.toss_won_by is null or cm.toss_decision is null
          then m.team_a_id
        when cm.toss_decision = 'bat'
          then cm.toss_won_by
        when cm.toss_won_by = m.team_a_id
          then m.team_b_id
        else m.team_a_id
      end as bats_first
    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
    where m.match_id = p_match_id
      and m.sport_id = 'cricket'
  )
  select case
    when p_innings_number % 2 = 1 then x.bats_first
    when x.bats_first = x.team_a_id then x.team_b_id
    else x.team_a_id
  end
  from x;
$$;

revoke all
  on function public._cricket_batting_team_id(uuid, integer)
  from public;


create or replace function public._can_score_innings(
  p_match_id       uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with x as (
    select
      m.match_id,
      m.match_type,
      m.created_by,
      public._cricket_batting_team_id(
        m.match_id,
        p_innings_number
      ) as batting_team_id
    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
    where m.match_id = p_match_id
      and m.sport_id = 'cricket'
  )
  select exists (
    select 1
    from x
    where
      (x.match_type = 'practice'
       and x.created_by = (select auth.uid()))
      or public._is_match_side_captain(
           x.match_id,
           x.batting_team_id
         )
      or public.can(
           'team',
           x.batting_team_id,
           'match.score'
         )
      or public.can(
           'match',
           x.match_id,
           'match.score'
         )
  );
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;


create or replace function public.can_score_innings(
  p_match_id       uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public._can_score_innings(
    p_match_id,
    p_innings_number
  );
$$;

revoke all on function public.can_score_innings(uuid, integer) from public;
grant execute on function public.can_score_innings(uuid, integer)
  to authenticated;


-- =============================================================================
-- 4. Cricket match-start lifecycle
-- =============================================================================

create or replace function public.record_toss_winner(
  p_match_id uuid,
  p_won_by   uuid,
  p_face     char default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_team_a uuid;
  v_team_b uuid;
  v_phase public.match_start_phase;
begin
  select m.team_a_id, m.team_b_id, cm.phase
    into v_team_a, v_team_b, v_phase
    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
   where m.match_id = p_match_id
     and m.sport_id = 'cricket'
   for update of cm;

  if not found then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  if not public._is_match_creator(p_match_id) then
    raise exception 'Only the match creator can start the toss'
      using errcode = '42501';
  end if;

  if p_won_by is null
     or (
       p_won_by is distinct from v_team_a
       and p_won_by is distinct from v_team_b
     ) then
    raise exception
      'The toss winner must be one of the two teams in this match'
      using errcode = '22023';
  end if;

  if v_phase not in ('toss', 'lineup') then
    raise exception
      'The toss can no longer be changed once the openers are submitted'
      using errcode = '22023';
  end if;

  update public.cricket_matches
     set toss_won_by      = p_won_by,
         toss_decision    = null,
         toss_face        = coalesce(p_face, toss_face),
         toss_recorded_at = now(),
         phase            = 'toss',
         updated_at       = now()
   where match_id = p_match_id;

  -- Shared shell records lifecycle only. `toss` remains a transitional
  -- match_status until Phase 3 reduces the enum to generic lifecycle states.
  update public.matches
     set status = 'toss',
         updated_at = now()
   where match_id = p_match_id;
end;
$$;

revoke all on function public.record_toss_winner(uuid, uuid, char) from public;
revoke execute on function public.record_toss_winner(uuid, uuid, char)
  from anon, authenticated;


create or replace function public.record_toss_decision(
  p_match_id uuid,
  p_decision public.toss_decision
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_won_by uuid;
  v_phase public.match_start_phase;
begin
  select cm.toss_won_by, cm.phase
    into v_won_by, v_phase
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;

  if not found then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  if v_won_by is null then
    raise exception 'The toss winner has not been recorded yet'
      using errcode = '22023';
  end if;

  if not public._is_match_side_captain(
    p_match_id,
    v_won_by
  ) then
    raise exception
      'Only the captain of the side that won the toss can choose to bat or bowl'
      using errcode = '42501';
  end if;

  if v_phase not in ('toss', 'lineup') then
    raise exception
      'The toss decision can no longer be changed once the openers are submitted'
      using errcode = '22023';
  end if;

  update public.cricket_matches
     set toss_decision = p_decision,
         phase         = 'lineup',
         updated_at    = now()
   where match_id = p_match_id;

  update public.matches
     set status = 'toss',
         updated_at = now()
   where match_id = p_match_id;
end;
$$;

revoke all
  on function public.record_toss_decision(uuid, public.toss_decision)
  from public;

revoke execute
  on function public.record_toss_decision(uuid, public.toss_decision)
  from anon, authenticated;


-- Remove the old combined-authority API if the production database still has
-- it. Phase 2 deliberately exposes only the two-act toss flow.
drop function if exists public.record_match_toss(
  uuid,
  uuid,
  public.toss_decision,
  char
);


create or replace function public.submit_match_openers(
  p_match_id       uuid,
  p_striker_id     uuid,
  p_non_striker_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_innings_id uuid;
  v_batting_team uuid;
  v_batting_side text;
  v_bowling_side text;
  v_count integer;
  v_overs numeric(4,1);
  v_toss_winner uuid;
  v_toss_decision public.toss_decision;
begin
  if p_striker_id is null
     or p_non_striker_id is null
     or p_striker_id = p_non_striker_id then
    raise exception 'Openers must be different players'
      using errcode = '22023';
  end if;

  select
    cm.toss_won_by,
    cm.toss_decision,
    coalesce(
      (cm.rules_snapshot->>'overs_per_innings')::numeric,
      20
    )
  into
    v_toss_winner,
    v_toss_decision,
    v_overs
  from public.cricket_matches cm
  where cm.match_id = p_match_id
  for update;

  if not found then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  if v_toss_winner is null
     or v_toss_decision is null then
    raise exception 'The toss must be recorded before selecting openers'
      using errcode = '22023';
  end if;

  v_batting_team :=
    public._cricket_batting_team_id(p_match_id, 1);

  if not public._is_match_side_captain(
    p_match_id,
    v_batting_team
  ) then
    raise exception
      'Only the batting side captain can submit openers'
      using errcode = '42501';
  end if;

  select case
    when v_batting_team = m.team_a_id
      then 'team_a'
    else 'team_b'
  end
  into v_batting_side
  from public.matches m
  where m.match_id = p_match_id;

  v_bowling_side :=
    case when v_batting_side = 'team_a'
      then 'team_b'
      else 'team_a'
    end;

  select count(*)
    into v_count
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
   where mp.match_id = p_match_id
     and mp.team_side = v_batting_side
     and cmp.is_playing_xi = true
     and mp.match_player_id in (
       p_striker_id,
       p_non_striker_id
     );

  if v_count <> 2 then
    raise exception
      'Both openers must be in the batting XI'
      using errcode = '23514';
  end if;

  update public.cricket_matches
     set phase                = 'ready',
         openers_submitted_by = (select auth.uid()),
         openers_submitted_at = now(),
         updated_at           = now()
   where match_id = p_match_id;

  insert into public.match_innings (
    match_id,
    innings_number,
    batting_team_side,
    bowling_team_side,
    overs_allocated
  )
  values (
    p_match_id,
    1,
    v_batting_side,
    v_bowling_side,
    v_overs
  )
  on conflict (match_id, innings_number)
  do update set
    batting_team_side = excluded.batting_team_side,
    bowling_team_side = excluded.bowling_team_side,
    overs_allocated   = excluded.overs_allocated,
    updated_at        = now()
  returning innings_id into v_innings_id;

  insert into public.match_innings_state (
    innings_id,
    match_id,
    innings_number,
    striker_id,
    non_striker_id
  )
  values (
    v_innings_id,
    p_match_id,
    1,
    p_striker_id,
    p_non_striker_id
  )
  on conflict (innings_id)
  do update set
    striker_id     = excluded.striker_id,
    non_striker_id = excluded.non_striker_id,
    version        = public.match_innings_state.version + 1,
    updated_at     = now();
end;
$$;

revoke all
  on function public.submit_match_openers(uuid, uuid, uuid)
  from public;

revoke execute
  on function public.submit_match_openers(uuid, uuid, uuid)
  from anon, authenticated;


create or replace function public.start_match_now(
  p_match_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_batting_team uuid;
  v_phase public.match_start_phase;
  v_ready boolean;
begin
  select cm.phase
    into v_phase
    from public.cricket_matches cm
   where cm.match_id = p_match_id
   for update;

  if not found then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  v_batting_team :=
    public._cricket_batting_team_id(p_match_id, 1);

  if not public._is_match_side_captain(
    p_match_id,
    v_batting_team
  ) then
    raise exception
      'Only the batting side captain can start the match'
      using errcode = '42501';
  end if;

  if v_phase <> 'ready' then
    raise exception 'Openers must be locked before starting the match'
      using errcode = '23514';
  end if;

  select exists (
    select 1
      from public.match_innings_state s
     where s.match_id = p_match_id
       and s.innings_number = 1
       and s.striker_id is not null
       and s.non_striker_id is not null
  )
  into v_ready;

  if not v_ready then
    raise exception 'Openers must be locked before starting the match'
      using errcode = '23514';
  end if;

  update public.cricket_matches
     set phase      = 'live',
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status            = 'live',
         actual_start_time = coalesce(actual_start_time, now()),
         updated_at        = now()
   where match_id = p_match_id;
end;
$$;

revoke all on function public.start_match_now(uuid) from public;
revoke execute on function public.start_match_now(uuid)
  from anon, authenticated;


-- =============================================================================
-- 5. Cricket innings lifecycle
-- =============================================================================

create or replace function public.start_innings(
  p_match_id       uuid,
  p_innings_number integer,
  p_striker_id     uuid,
  p_non_striker_id uuid,
  p_bowler_id      uuid,
  p_target         integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_innings_id uuid;
  v_status public.match_status;
  v_batting_team uuid;
  v_team_a uuid;
  v_batting_side text;
  v_bowling_side text;
  v_batters integer;
  v_bowler integer;
  v_overs numeric(4,1);
begin
  if p_innings_number < 1 then
    raise exception 'Invalid innings number'
      using errcode = '22023';
  end if;

  if p_striker_id = p_non_striker_id then
    raise exception 'Striker and non-striker must be different players'
      using errcode = '22023';
  end if;

  if not public._can_score_innings(
    p_match_id,
    p_innings_number
  ) then
    raise exception
      'Only the batting side can start this innings'
      using errcode = '42501';
  end if;

  select
    m.status,
    m.team_a_id,
    coalesce(
      (cm.rules_snapshot->>'overs_per_innings')::numeric,
      20
    )
  into
    v_status,
    v_team_a,
    v_overs
  from public.matches m
  join public.cricket_matches cm
    on cm.match_id = m.match_id
  where m.match_id = p_match_id
    and m.sport_id = 'cricket';

  if not found then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  if v_status in (
    'completed',
    'abandoned',
    'walkover'
  ) then
    raise exception 'This match is already finished'
      using errcode = '22023';
  end if;

  v_batting_team :=
    public._cricket_batting_team_id(
      p_match_id,
      p_innings_number
    );

  v_batting_side :=
    case when v_batting_team = v_team_a
      then 'team_a'
      else 'team_b'
    end;

  v_bowling_side :=
    case when v_batting_side = 'team_a'
      then 'team_b'
      else 'team_a'
    end;

  select count(*)
    into v_batters
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
   where mp.match_id = p_match_id
     and mp.team_side = v_batting_side
     and cmp.is_playing_xi = true
     and mp.match_player_id in (
       p_striker_id,
       p_non_striker_id
     );

  if v_batters <> 2 then
    raise exception 'Batters must be in the batting XI'
      using errcode = '23514';
  end if;

  select count(*)
    into v_bowler
    from public.match_players mp
    join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
     and cmp.match_id = mp.match_id
   where mp.match_id = p_match_id
     and mp.team_side = v_bowling_side
     and cmp.is_playing_xi = true
     and mp.match_player_id = p_bowler_id;

  if v_bowler <> 1 then
    raise exception 'Bowler must be in the bowling XI'
      using errcode = '23514';
  end if;

  insert into public.match_innings (
    match_id,
    innings_number,
    batting_team_side,
    bowling_team_side,
    overs_allocated
  )
  values (
    p_match_id,
    p_innings_number,
    v_batting_side,
    v_bowling_side,
    v_overs
  )
  on conflict (match_id, innings_number)
  do update set
    batting_team_side = excluded.batting_team_side,
    bowling_team_side = excluded.bowling_team_side,
    overs_allocated   = excluded.overs_allocated,
    updated_at        = now()
  returning innings_id into v_innings_id;

  insert into public.match_innings_state (
    innings_id,
    match_id,
    innings_number,
    striker_id,
    non_striker_id,
    bowler_id,
    target
  )
  values (
    v_innings_id,
    p_match_id,
    p_innings_number,
    p_striker_id,
    p_non_striker_id,
    p_bowler_id,
    p_target
  )
  on conflict (innings_id)
  do update set
    striker_id     = excluded.striker_id,
    non_striker_id = excluded.non_striker_id,
    bowler_id      = excluded.bowler_id,
    target         = coalesce(
      excluded.target,
      public.match_innings_state.target
    ),
    version        = public.match_innings_state.version + 1,
    updated_at     = now();

  update public.cricket_matches
     set phase      = 'live',
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status            = 'live',
         actual_start_time = coalesce(actual_start_time, now()),
         updated_at        = now()
   where match_id = p_match_id;
end;
$$;

revoke all
  on function public.start_innings(
    uuid, integer, uuid, uuid, uuid, integer
  )
  from public;

revoke execute
  on function public.start_innings(
    uuid, integer, uuid, uuid, uuid, integer
  )
  from anon, authenticated;


-- =============================================================================
-- 6. Undo / manual completion
-- =============================================================================

create or replace function public.undo_last_ball(
  p_match_id       uuid,
  p_innings_number integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_innings_id uuid;
  v_row public.match_deliveries;
  v_status public.match_status;
begin
  if (select auth.uid()) is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;

  if not public._can_score_innings(
    p_match_id,
    p_innings_number
  ) then
    raise exception 'Only the batting team can score this innings'
      using errcode = '42501';
  end if;

  select innings_id
    into v_innings_id
    from public.match_innings_state
   where match_id = p_match_id
     and innings_number = p_innings_number
   for update;

  if not found then
    raise exception
      'Innings % has not been started for this match',
      p_innings_number
      using errcode = '23000';
  end if;

  delete from public.match_deliveries
   where delivery_id = (
     select delivery_id
       from public.match_deliveries
      where match_id = p_match_id
        and innings_number = p_innings_number
        and is_undone = false
      order by seq desc
      limit 1
   )
   returning * into v_row;

  if v_row.delivery_id is null then
    return false;
  end if;

  update public.match_innings_state s
     set total_runs       = agg.runs,
         total_wickets    = agg.wickets,
         legal_ball_count = agg.legal,
         total_wides      = agg.wides,
         total_no_balls   = agg.no_balls,
         total_byes       = agg.byes,
         total_leg_byes   = agg.leg_byes,
         total_penalties  = agg.penalties,
         striker_id       = coalesce(v_row.striker_id, s.striker_id),
         non_striker_id   = coalesce(v_row.non_striker_id, s.non_striker_id),
         bowler_id        = coalesce(v_row.bowler_id, s.bowler_id),
         is_all_out       = false,
         version          = s.version + 1,
         updated_at       = now()
    from (
      select
        coalesce(sum(runs_off_bat + extra_runs), 0)::int as runs,
        (count(*) filter (where is_wicket))::int as wickets,
        (count(*) filter (where is_legal_delivery))::int as legal,
        coalesce(sum(extra_runs)
          filter (where delivery_type = 'wide'), 0)::int as wides,
        coalesce(sum(extra_runs)
          filter (where delivery_type = 'no_ball'), 0)::int as no_balls,
        coalesce(sum(extra_runs)
          filter (where delivery_type = 'bye'), 0)::int as byes,
        coalesce(sum(extra_runs)
          filter (where delivery_type = 'leg_bye'), 0)::int as leg_byes,
        coalesce(sum(extra_runs)
          filter (where delivery_type = 'penalty'), 0)::int as penalties
      from public.match_deliveries
      where match_id = p_match_id
        and innings_number = p_innings_number
        and is_undone = false
    ) agg
   where s.match_id = p_match_id
     and s.innings_number = p_innings_number;

  select status
    into v_status
    from public.matches
   where match_id = p_match_id;

  if v_status in (
    'innings_break',
    'completed',
    'tied',
    'no_result'
  ) then
    update public.cricket_matches
       set result         = null,
           result_summary = null,
           phase          = 'live',
           updated_at     = now()
     where match_id = p_match_id;

    update public.matches
       set status       = 'live',
           winner_id    = null,
           completed_at = null,
           updated_at   = now()
     where match_id = p_match_id;
  end if;

  return true;
end;
$$;

revoke all
  on function public.undo_last_ball(uuid, integer)
  from public;

revoke execute
  on function public.undo_last_ball(uuid, integer)
  from anon, authenticated;


create or replace function public.complete_cricket_match(
  p_match_id    uuid,
  p_description text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_description text;
begin
  v_description := nullif(btrim(p_description), '');

  if v_description is null then
    raise exception 'A result description is required'
      using errcode = '22023';
  end if;

  if not (
    public._is_match_captain(p_match_id)
    or public.can('match', p_match_id, 'match.score')
  ) then
    raise exception 'Not allowed to complete this match'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
      from public.matches m
      join public.cricket_matches cm
        on cm.match_id = m.match_id
     where m.match_id = p_match_id
       and m.sport_id = 'cricket'
  ) then
    raise exception 'Cricket match not found'
      using errcode = 'P0002';
  end if;

  update public.cricket_matches
     set result = jsonb_build_object(
           'winner_team_id', null,
           'win_type', 'manual',
           'description', v_description,
           'summary', v_description
         ),
         result_summary = jsonb_build_object(
           'description', v_description
         ),
         updated_at = now()
   where match_id = p_match_id;

  update public.matches
     set status       = 'completed',
         winner_id    = null,
         completed_at = now(),
         updated_at   = now()
   where match_id = p_match_id;
end;
$$;

revoke all
  on function public.complete_cricket_match(uuid, text)
  from public;

revoke execute
  on function public.complete_cricket_match(uuid, text)
  from anon, authenticated;


-- =============================================================================
-- 7. Challenge acceptance creates the shell + Cricket extension explicitly
-- =============================================================================

create or replace function public.accept_match_request(
  p_request_id           uuid,
  p_scheduled_start_time timestamptz default null,
  p_venue                text default null,
  p_format               jsonb default null,
  p_decision_note        text default null,
  p_to_team_id           uuid default null,
  p_to_team_xi           uuid[] default '{}'::uuid[],
  p_to_team_keeper_id    uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req         public.match_challenges%rowtype;
  v_to_team     uuid;
  v_match_id    uuid;
  v_rules       jsonb;
  v_start       timestamptz;
  v_venue       text;
  v_to_team_xi  uuid[];
  v_to_keeper   uuid;
  v_a_captain   uuid;
  v_b_captain   uuid;
  v_updated     integer;
begin
  if (select auth.uid()) is null then
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

  if v_req.sport_id <> 'cricket' then
    raise exception
      'This Cricket match flow cannot accept a % challenge',
      v_req.sport_id
      using errcode = '23514';
  end if;

  if v_req.status not in ('pending', 'countered') then
    raise exception
      'Request is no longer actionable (status: %)',
      v_req.status
      using errcode = '22023';
  end if;

  if v_req.status = 'countered' then
    if not public.is_team_manager(v_req.from_team_id) then
      raise exception
        'Only the original sender can accept a countered request'
        using errcode = '42501';
    end if;

    v_to_team := v_req.to_team_id;
    v_rules := public._normalize_cricket_match_rules(
      coalesce(
        p_format,
        v_req.countered_format,
        v_req.proposed_format,
        '{}'::jsonb
      )
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.countered_start_time,
      v_req.proposed_start_time,
      now()
    );
    v_venue := coalesce(
      p_venue,
      v_req.countered_venue,
      v_req.proposed_venue
    );
    v_to_team_xi := '{}'::uuid[];
    v_to_keeper := null;

  elsif v_req.to_team_id is not null then
    if not public.is_team_manager(v_req.to_team_id) then
      raise exception
        'Only managers of the receiving team can accept'
        using errcode = '42501';
    end if;

    v_to_team := v_req.to_team_id;
    v_rules := public._normalize_cricket_match_rules(
      coalesce(
        p_format,
        v_req.proposed_format,
        '{}'::jsonb
      )
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.proposed_start_time,
      now()
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

    if not public.is_team_manager(p_to_team_id) then
      raise exception
        'You can only accept on behalf of teams you manage'
        using errcode = '42501';
    end if;

    v_to_team := p_to_team_id;
    v_rules := public._normalize_cricket_match_rules(
      coalesce(
        p_format,
        v_req.proposed_format,
        '{}'::jsonb
      )
    );
    v_start := coalesce(
      p_scheduled_start_time,
      v_req.proposed_start_time,
      now()
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
    raise exception 'Receiving team is required'
      using errcode = '23502';
  end if;

  if coalesce(array_length(v_to_team_xi, 1), 0)
       > v_req.players_per_side then
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

  v_a_captain :=
    public._team_current_captain(v_req.from_team_id);

  v_b_captain :=
    public._team_current_captain(v_to_team);

  if v_a_captain is null
     or v_b_captain is null then
    raise exception
      'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  -- Shared shell only. The old Cricket NOT NULL columns still receive their
  -- defaults until Phase 3 removes them, but this function no longer writes
  -- them as domain state.
  insert into public.matches (
    match_type,
    tournament_id,
    sport_id,
    team_a_id,
    team_b_id,
    venue,
    scheduled_start_time,
    status,
    created_by
  )
  values (
    'friendly',
    null,
    'cricket',
    v_req.from_team_id,
    v_to_team,
    v_venue,
    v_start,
    'scheduled',
    (select auth.uid())
  )
  returning match_id into v_match_id;

  -- Phase-1's matches mirror has already created the child on databases where
  -- that transition trigger still exists. This UPSERT makes the Phase-2 write
  -- explicit and authoritative either way.
  insert into public.cricket_matches (
    match_id,
    format_code,
    rules_snapshot
  )
  values (
    v_match_id,
    null,
    v_rules
  )
  on conflict (match_id)
  do update set
    format_code    = excluded.format_code,
    rules_snapshot = excluded.rules_snapshot,
    updated_at     = now();

  perform public._materialize_cricket_match_side(
    v_match_id,
    v_req.from_team_id,
    'team_a',
    v_req.from_team_xi,
    v_a_captain,
    v_req.from_team_keeper_id
  );

  perform public._materialize_cricket_match_side(
    v_match_id,
    v_to_team,
    'team_b',
    v_to_team_xi,
    v_b_captain,
    v_to_keeper
  );

  update public.match_challenges
     set status        = 'accepted',
         decided_by    = (select auth.uid()),
         decided_at    = now(),
         decision_note = p_decision_note,
         match_id      = v_match_id,
         to_team_id    = v_to_team
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
    uuid,
    timestamptz,
    text,
    jsonb,
    text,
    uuid,
    uuid[],
    uuid
  )
  from public;

grant execute
  on function public.accept_match_request(
    uuid,
    timestamptz,
    text,
    jsonb,
    text,
    uuid,
    uuid[],
    uuid
  )
  to authenticated;


-- =============================================================================
-- 8. Cricket read aggregate
-- =============================================================================

create or replace view public.cricket_match_details
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
  m.status,
  m.winner_id,
  m.team_a_id,
  m.team_b_id,
  m.created_by,
  m.created_at,
  m.updated_at,

  cm.format_code as match_format,
  cm.rules_snapshot as format,
  cm.toss_won_by,
  cm.toss_decision,
  cm.toss_face,
  cm.toss_recorded_at,
  cm.phase as start_phase,
  cm.openers_submitted_by,
  cm.openers_submitted_at,
  cm.scoring_mode,
  cm.result,
  cm.result_summary,
  cm.revised_conditions,
  cm.player_of_the_match_id,

  coalesce(
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
      limit 1
    ),
    m.team_a_captain
  ) as team_a_captain,

  coalesce(
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
      limit 1
    ),
    m.team_b_captain
  ) as team_b_captain

from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket';


grant select
  on public.cricket_match_details
  to anon, authenticated, service_role;


create or replace function public.list_my_cricket_matches()
returns setof public.cricket_match_details
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.*
  from public.cricket_match_details d
  where
    d.created_by = (select auth.uid())

    or public._is_match_captain(d.match_id)

    or exists (
      select 1
      from public.team_members tm
      where tm.team_id in (
        d.team_a_id,
        d.team_b_id
      )
        and tm.user_id = (select auth.uid())
        and tm.status = 'active'
    )

    or exists (
      select 1
      from public.match_players mp
      where mp.match_id = d.match_id
        and mp.user_id = (select auth.uid())
    )

    or exists (
      select 1
      from public.match_officials mo
      where mo.match_id = d.match_id
        and mo.user_id = (select auth.uid())
    )

  order by coalesce(
    d.scheduled_start_time,
    d.created_at
  ) desc;
$$;

revoke all
  on function public.list_my_cricket_matches()
  from public;

grant execute
  on function public.list_my_cricket_matches()
  to authenticated;


-- =============================================================================
-- 9. Remove a Phase-1 extension that duplicated facts unnecessarily
-- =============================================================================
--
-- is_batting_first is derivable from the Cricket toss.
-- captain/keeper are participant facts in cricket_match_players.
-- match_teams remains the shared side/team snapshot.
-- =============================================================================

drop trigger if exists
  match_teams_sync_cricket_extension
  on public.match_teams;

drop function if exists
  public.sync_legacy_match_side_to_cricket_extension();

drop table if exists public.cricket_match_sides;


-- =============================================================================
-- 10. Keep Phase-1 mirrors ONLY until Phase 2B
-- =============================================================================
--
-- Do not drop these yet:
--
--   matches_sync_cricket_extension
--   match_players_sync_cricket_extension
--
-- Tournament/console migrations still contain legacy writes. Phase 2B moves
-- those callers. After that, the mirrors become an architectural hazard and
-- must be removed before Phase 3 drops the old columns.
-- =============================================================================
