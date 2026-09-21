-- =============================================================================
-- Migration: 20260101000412_match_helpers.sql
-- =============================================================================

-- 0412 · match_helpers
-- Cross-table match lifecycle and scoring helpers.
-- Spec: docs/matches-schema-architecture.md

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Match authorization predicates
-- Helper Predicates
create or replace function public._is_match_captain(
  p_match_id uuid
)
returns boolean
language sql
security definer
stable
as $$
  select
    exists (
      select
        1
      from public.matches m
      where
        m.match_id = p_match_id
        and (
          m.created_by = auth.uid()
          -- captain of either side (cricket_match_players is the authoritative
          -- captain record; team_a_captain / team_b_captain no longer exist as
          -- stored columns on matches).
          or exists (
            select 1
            from
              public.match_players mp
              join public.cricket_match_players cmp
                on cmp.match_player_id = mp.match_player_id
                and cmp.match_id = mp.match_id
            where
              mp.match_id = p_match_id
              and mp.user_id = auth.uid()
              and cmp.is_captain = true
          )
        )
    );
$$;

-- Who may score which innings (design doc D12)
-- The BATTING side scores its own innings; control passes at the innings break.
-- Odd innings belong to whoever batted first (derived from the toss), even
-- innings to the other side. Tournament organisers and the creator of a
-- practice match may score either side.
create or replace function public._can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with match_context as (
    select
      m.match_id,
      m.match_type,
      m.created_by,
      cm.toss_won_by,
      cm.toss_decision
    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
    where m.match_id = p_match_id
  ),
  batting_side as (
    select
      mc.*,
      case
        when p_innings_number % 2 = 1 then
          case
            when mc.toss_won_by is null
              or mc.toss_decision is null
              then 'team_a'
            when mc.toss_decision = 'bat'
              then mc.toss_won_by
            when mc.toss_won_by = 'team_a'
              then 'team_b'
            else 'team_a'
          end
        else
          case
            when (
              case
                when mc.toss_won_by is null
                  or mc.toss_decision is null
                  then 'team_a'
                when mc.toss_decision = 'bat'
                  then mc.toss_won_by
                when mc.toss_won_by = 'team_a'
                  then 'team_b'
                else 'team_a'
              end
            ) = 'team_a'
              then 'team_b'
            else 'team_a'
          end
      end as batting_side
    from match_context mc
  ),
  batting as (
    select
      b.*,
      mt.team_id as batting_team_id
    from batting_side b
    join public.match_teams mt
      on mt.match_id = b.match_id
     and mt.team_side = b.batting_side
  )
  select exists (
    select 1
    from batting b
    where
      (
        b.match_type = 'practice'
        and b.created_by = auth.uid()
      )
      or exists (
        select 1
        from public.match_players mp
        join public.cricket_match_players cmp
          on cmp.match_player_id = mp.match_player_id
         and cmp.match_id = mp.match_id
        where mp.match_id = b.match_id
          and mp.user_id = auth.uid()
          and mp.team_side = b.batting_side
          and cmp.is_captain = true
      )
      or (
        b.batting_team_id is not null
        and public.can(
          'team',
          b.batting_team_id,
          'match.score'
        )
      )
      or public.can(
        'match',
        b.match_id,
        'match.score'
      )
  );
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;

grant execute
on function public._can_score_innings(uuid, integer)
to authenticated, service_role;

-- can_score_innings is the client-facing gate.
create or replace function public.can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    public._can_score_innings(p_match_id, p_innings_number);
$$;

-- Internal Side-Roster Materialization
create or replace function public._materialize_match_team_side(
  p_match_id uuid,
  p_team_side text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches%rowtype;
  v_team_id uuid;
  v_tournament_squad uuid[];
begin
  if p_team_side not in ('team_a', 'team_b') then
    raise exception 'Invalid match side: %', p_team_side
      using errcode = '22023';
  end if;

  select m.*
    into v_match
  from public.matches m
  where m.match_id = p_match_id;

  if not found then
    raise exception 'Match not found'
      using errcode = 'P0002';
  end if;

  select mt.team_id
    into v_team_id
  from public.match_teams mt
  where mt.match_id = p_match_id
    and mt.team_side = p_team_side;

  -- An unresolved future bracket slot intentionally has no participants yet.
  if v_team_id is null then
    delete from public.match_players
    where match_id = p_match_id
      and team_side = p_team_side;
    return;
  end if;

  if v_match.tournament_id is not null then
    select tt.squad
      into v_tournament_squad
    from public.tournament_teams tt
    where tt.tournament_id = v_match.tournament_id
      and tt.team_id = v_team_id
      and tt.status = 'approved'
    limit 1;
  end if;

  delete from public.match_players
  where match_id = p_match_id
    and team_side = p_team_side;

  insert into public.match_players (
    match_player_id,
    match_id,
    team_side,
    user_id,
    unclaimed_id,
    display_name,
    jersey_number
  )
  select
    gen_random_uuid(),
    p_match_id,
    p_team_side,
    tm.user_id,
    tm.unclaimed_id,
    coalesce(
      pr.display_name,
      up.display_name,
      'Player'
    ),
    tm.jersey_number
  from public.team_members tm
  left join public.profiles pr
    on pr.user_id = tm.user_id
  left join public.unclaimed_players up
    on up.unclaimed_id = tm.unclaimed_id
  where tm.team_id = v_team_id
    and tm.status = 'active'
    and tm.in_squad = true
    and (
      coalesce(cardinality(v_tournament_squad), 0) = 0
      or tm.user_id = any(v_tournament_squad)
      or tm.unclaimed_id = any(v_tournament_squad)
    );

  if v_match.sport_id = 'cricket' then
    insert into public.cricket_match_players (
      match_player_id,
      match_id,
      is_captain,
      is_vice_captain,
      is_wicket_keeper
    )
    select
      mp.match_player_id,
      mp.match_id,
      coalesce(
        mp.user_id = public._team_current_captain(v_team_id),
        false
      ),
      false,
      false
    from public.match_players mp
    where mp.match_id = p_match_id
      and mp.team_side = p_team_side;
  end if;
end;
$$;

revoke all
  on function public._materialize_match_team_side(uuid, text)
  from public, anon, authenticated;

-- List matches user participates in
create or replace function public.list_my_matches()
returns setof public.matches
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select m.*
  from public.matches m
  where
    m.created_by = auth.uid()
    or exists (
      select 1
      from public.match_players mp
      join public.cricket_match_players cmp
        on cmp.match_player_id = mp.match_player_id
       and cmp.match_id = mp.match_id
      where mp.match_id = m.match_id
        and mp.user_id = auth.uid()
        and cmp.is_captain = true
    )
    or exists (
      select 1
      from public.match_teams ms
      join public.team_members tm
        on tm.team_id = ms.team_id
      where ms.match_id = m.match_id
        and tm.user_id = auth.uid()
        and tm.status = 'active'
    )
    or exists (
      select 1
      from public.match_officials mo
      where mo.match_id = m.match_id
        and mo.user_id = auth.uid()
    )
  order by m.scheduled_start_time desc;
$$;

revoke all
  on function public.list_my_matches()
  from public, anon;

grant execute
  on function public.list_my_matches()
  to authenticated;

-- -----------------------------------------------------------------------------
-- Views
-- -----------------------------------------------------------------------------

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
    order by cmp.updated_at desc, mp.created_at asc
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
    order by cmp.updated_at desc, mp.created_at asc
    limit 1
  ) as team_b_captain,

  cm.setup_side,
  setup_slot.team_id as setup_team_id,
  cm.toss_recorded_by

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

comment on view public.cricket_match_details is
  'Canonical Cricket aggregate view with match_teams projection.';

-- -----------------------------------------------------------------------------
-- List My Cricket Matches
-- -----------------------------------------------------------------------------

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
    or public._is_match_captain(d.match_id)
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
