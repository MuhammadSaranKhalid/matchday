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
-- 4. Cricket match-start lifecycle commands
-- =============================================================================
-- The 7 match command RPCs (record_toss_winner, record_toss_decision,
-- submit_match_openers, start_match_now, start_innings, undo_last_ball,
-- complete_cricket_match) have been moved to TypeScript Edge Functions
-- (cricket-match-action) executing direct SQL in single transactions.


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
