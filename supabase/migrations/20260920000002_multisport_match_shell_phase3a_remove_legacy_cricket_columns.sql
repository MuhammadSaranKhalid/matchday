-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 3A
-- Physical removal of legacy Cricket columns
-- =============================================================================
--
-- REQUIRES:
--   Phase 2A core Cricket runtime cutover
--   Phase 2B tournament / pool cutover
--
-- SCOPE:
--   This migration ONLY removes legacy Cricket columns from shared tables and
--   rebuilds the canonical Cricket read/claim surfaces.
--
-- NOT IN THIS PHASE:
--   * match_status enum redesign
--   * renaming Cricket-specific enums
--   * dropping old enum types
--   * renaming innings/delivery tables
--
-- IMPORTANT:
--   NO CASCADE is used for the column drops. If an unknown database object
--   still depends on a legacy column, PostgreSQL must stop this migration.
-- =============================================================================


-- =============================================================================
-- 0. Destructive-migration preflight
-- =============================================================================

do $$
declare
  v_count bigint;
begin
  -- Phase 2A markers.
  if to_regprocedure('public.list_my_cricket_matches()') is null
     or to_regprocedure('public.complete_cricket_match(uuid,text)') is null
     or to_regclass('public.cricket_match_details') is null then
    raise exception
      'Phase 3A requires Phase 2A. list_my_cricket_matches / '
      'complete_cricket_match / cricket_match_details are missing.';
  end if;

  -- Phase 2B marker.
  if to_regprocedure('public._sync_cricket_result_to_parent()') is null then
    raise exception
      'Phase 3A requires Phase 2B. Canonical Cricket-result -> parent-winner '
      'sync is missing.';
  end if;

  -- Phase-1 mirrors must already be gone.
  if exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and not t.tgisinternal
      and t.tgname in (
        'matches_sync_cricket_extension',
        'match_players_sync_cricket_extension',
        'match_teams_sync_cricket_extension'
      )
  ) then
    raise exception
      'Phase-1 mirror triggers still exist. Complete Phase 2B first.';
  end if;

  -- Phase 2A deliberately retired cricket_match_sides. Captain/keeper are
  -- participant flags; batting-first is derived from the Cricket toss.
  if to_regclass('public.cricket_match_sides') is not null then
    raise exception
      'cricket_match_sides still exists. Complete Phase 2A cleanup first.';
  end if;

  -- Every Cricket parent must have its canonical extension before legacy
  -- columns can be destroyed.
  select count(*)
    into v_count
    from public.matches m
    left join public.cricket_matches cm
      on cm.match_id = m.match_id
   where m.sport_id = 'cricket'
     and cm.match_id is null;

  if v_count <> 0 then
    raise exception
      'Cannot remove legacy match columns: % Cricket matches lack '
      'cricket_matches rows.',
      v_count;
  end if;

  -- Same invariant for Cricket participants.
  select count(*)
    into v_count
    from public.match_players mp
    join public.matches m
      on m.match_id = mp.match_id
    left join public.cricket_match_players cmp
      on cmp.match_player_id = mp.match_player_id
   where m.sport_id = 'cricket'
     and cmp.match_player_id is null;

  if v_count <> 0 then
    raise exception
      'Cannot remove legacy participant columns: % Cricket match_players '
      'lack cricket_match_players rows.',
      v_count;
  end if;

  -- Parent winner is the generic projection of the canonical Cricket result.
  select count(*)
    into v_count
    from public.matches m
    join public.cricket_matches cm
      on cm.match_id = m.match_id
   where m.sport_id = 'cricket'
     and m.winner_id is distinct from
         nullif(cm.result->>'winner_team_id', '')::uuid;

  if v_count <> 0 then
    raise exception
      'Cannot remove legacy result columns: % Cricket matches have a '
      'winner mismatch between cricket_matches.result and matches.winner_id.',
      v_count;
  end if;
end
$$;


-- =============================================================================
-- 1. Drop APIs/views whose row types still include the legacy parent columns
-- =============================================================================

-- Phase 2A replaced this API. Keeping two "my matches" RPCs after the physical
-- split would invite callers back onto the shared parent row.
drop function if exists public.list_my_matches();

-- The function returns SETOF this view, so drop the function first.
drop function if exists public.list_my_cricket_matches();

-- Rebuilt below without parent captain fallbacks.
drop view if exists public.cricket_match_details;


-- =============================================================================
-- 2. Remove legacy Cricket fields from the shared matches shell
-- =============================================================================
--
-- KEEP:
--   match_id, tournament_id, match_type, stage/round/bracket metadata,
--   venue/ground, sport_id, schedule timestamps, status, winner_id,
--   team_a_id, team_b_id, created_by, created_at, updated_at.
--
-- DROP:
--   everything that describes Cricket rules, toss, Cricket start phase,
--   Cricket result detail, Cricket POTM, or Cricket-specific captain snapshot.
-- =============================================================================

alter table public.matches
  drop column if exists match_format,
  drop column if exists format,
  drop column if exists toss_won_by,
  drop column if exists toss_decision,
  drop column if exists toss_face,
  drop column if exists toss_recorded_at,
  drop column if exists start_phase,
  drop column if exists openers_submitted_by,
  drop column if exists openers_submitted_at,
  drop column if exists scoring_mode,
  drop column if exists revised_conditions,
  drop column if exists result,
  drop column if exists result_summary,
  drop column if exists player_of_the_match_id,
  drop column if exists team_a_captain,
  drop column if exists team_b_captain;


comment on table public.matches is
  'Sport-neutral match shell. Sport-specific rules, toss/start state, result '
  'detail and sport-specific participant roles live in sport extensions.';

comment on column public.matches.winner_id is
  'Generic winner projection for cross-sport tournament/bracket joins. '
  'Sport-specific result detail remains in the sport extension.';


-- =============================================================================
-- 3. Remove legacy Cricket state from shared match_players
-- =============================================================================
--
-- Shared match_players now contains identity/snapshot facts only:
--   match, side, user/unclaimed identity, display name, jersey.
--
-- Cricket XI / order / captain / keeper / substitute live exclusively in
-- cricket_match_players.
-- =============================================================================

alter table public.match_players
  drop column if exists role,
  drop column if exists is_in_playing_xi,
  drop column if exists batting_order;


comment on table public.match_players is
  'Sport-neutral participant identity/snapshot for a match. Sport-specific '
  'per-match state belongs in sport participant extensions.';


-- =============================================================================
-- 4. Remove Cricket-only side fields from match_teams
-- =============================================================================
--
-- match_teams remains a shared side snapshot:
--   match_id, team_id, team_name, team_side, created_at.
--
-- captain/keeper are independent Cricket participant flags.
-- is_batting_first is derived from the Cricket toss / super-over result.
-- =============================================================================

alter table public.match_teams
  drop column if exists is_batting_first,
  drop column if exists captain_player_id,
  drop column if exists keeper_player_id;


comment on table public.match_teams is
  'Sport-neutral per-match team-side snapshot. Cricket captain/keeper state '
  'lives in cricket_match_players; batting order of sides is derived from '
  'Cricket match state.';


-- =============================================================================
-- 5. Canonical unclaimed-player claim finalization
-- =============================================================================
--
-- Phase 2B still retained a few assignments to deprecated columns so it could
-- bridge the transition. Rebuild the function now using only canonical state.
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
    select 1
    from public.profiles p
    where p.user_id = new.claimed_by_user_id
  ) then
    raise exception 'Claim target profile does not exist'
      using errcode = 'P0002';
  end if;


  -- ---------------------------------------------------------------------------
  -- Durable player/sport identity.
  -- ---------------------------------------------------------------------------

  insert into public.player_sports (
    user_id,
    sport_id
  )
  values (
    new.claimed_by_user_id,
    new.sport_id
  )
  on conflict (user_id, sport_id)
  do nothing;


  -- ---------------------------------------------------------------------------
  -- Optional Cricket profile attributes.
  -- Existing registered/self-owned values win.
  -- ---------------------------------------------------------------------------

  if new.sport_id = 'cricket' then

    insert into public.cricket_player_profiles as cp (
      user_id,
      sport_id,
      batting_style,
      bowling_style,
      player_role,
      preferred_ball_types,
      years_playing
    )
    select
      new.claimed_by_user_id,
      'cricket',
      cup.batting_style,
      cup.bowling_style,
      cup.player_role,
      cup.preferred_ball_types,
      cup.years_playing
    from public.cricket_unclaimed_player_profiles cup
    where cup.unclaimed_id = new.unclaimed_id

    on conflict (user_id)
    do update set
      batting_style =
        coalesce(cp.batting_style, excluded.batting_style),

      bowling_style =
        coalesce(cp.bowling_style, excluded.bowling_style),

      player_role =
        coalesce(cp.player_role, excluded.player_role),

      preferred_ball_types =
        case
          when cardinality(cp.preferred_ball_types) = 0
          then excluded.preferred_ball_types
          else cp.preferred_ball_types
        end,

      years_playing =
        coalesce(cp.years_playing, excluded.years_playing);
  end if;


  -- ---------------------------------------------------------------------------
  -- Team membership identity rewrite.
  -- ---------------------------------------------------------------------------

  for v_tm in
    select
      tm.membership_id,
      tm.team_id,
      tm.jersey_number,
      tm.in_squad
    from public.team_members tm
    where tm.unclaimed_id = new.unclaimed_id
    for update
  loop

    v_existing_membership := null;

    select tm.membership_id
      into v_existing_membership
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
             -- A manager-entered placeholder cannot decide a signed-in user's
             -- primary team.
             is_primary = false
       where membership_id = v_tm.membership_id;

    else

      -- Remove placeholder first so active-team jersey uniqueness cannot
      -- collide while merging.
      delete from public.team_members
       where membership_id = v_tm.membership_id;

      update public.team_members
         set in_squad =
               in_squad or v_tm.in_squad,
             jersey_number =
               coalesce(jersey_number, v_tm.jersey_number)
       where membership_id = v_existing_membership;

    end if;
  end loop;


  -- ---------------------------------------------------------------------------
  -- Match participant identity rewrite.
  -- ---------------------------------------------------------------------------

  for v_mp in
    select
      mp.match_player_id,
      mp.match_id,
      mp.team_side,
      mp.jersey_number
    from public.match_players mp
    where mp.unclaimed_id = new.unclaimed_id
    for update
  loop

    v_existing_match_player := null;
    v_existing_team_side := null;

    select
      mp.match_player_id,
      mp.team_side
    into
      v_existing_match_player,
      v_existing_team_side
    from public.match_players mp
    where mp.match_id = v_mp.match_id
      and mp.user_id = new.claimed_by_user_id
    limit 1
    for update;

    if v_existing_match_player is null then

      -- Preserve match_player_id so every delivery/wicket FK remains valid.
      update public.match_players
         set user_id = new.claimed_by_user_id,
             unclaimed_id = null
       where match_player_id = v_mp.match_player_id;

    else

      if v_existing_team_side
           is distinct from v_mp.team_side then
        raise exception
          'Claim would place the same user on both sides of match %',
          v_mp.match_id
          using errcode = '23514';
      end if;


      -- -----------------------------------------------------------------------
      -- Merge Cricket participant extension BEFORE deleting the old shared row.
      -- The old cricket_match_players row would otherwise cascade away.
      -- -----------------------------------------------------------------------

      if new.sport_id = 'cricket' then

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

        on conflict (match_player_id)
        do update set
          is_playing_xi =
            public.cricket_match_players.is_playing_xi
            or excluded.is_playing_xi,

          batting_order =
            coalesce(
              public.cricket_match_players.batting_order,
              excluded.batting_order
            ),

          is_captain =
            public.cricket_match_players.is_captain
            or excluded.is_captain,

          is_vice_captain =
            public.cricket_match_players.is_vice_captain
            or excluded.is_vice_captain,

          is_wicket_keeper =
            public.cricket_match_players.is_wicket_keeper
            or excluded.is_wicket_keeper,

          is_substitute =
            public.cricket_match_players.is_substitute
            or excluded.is_substitute,

          updated_at = now();


        update public.cricket_matches
           set player_of_the_match_id = v_existing_match_player,
               updated_at = now()
         where player_of_the_match_id = v_mp.match_player_id;

      end if;


      -- -----------------------------------------------------------------------
      -- Repoint every shared Cricket engine FK to the surviving participant.
      -- -----------------------------------------------------------------------

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


      -- Shared snapshot metadata can be merged without knowing the sport.
      update public.match_players
         set jersey_number =
               coalesce(jersey_number, v_mp.jersey_number)
       where match_player_id = v_existing_match_player;


      delete from public.match_players
       where match_player_id = v_mp.match_player_id;

    end if;

  end loop;


  perform public.migrate_player_stats(
    new.unclaimed_id,
    new.claimed_by_user_id
  );

  return new;
end;
$$;

revoke all
  on function public.finalize_unclaimed_claim()
  from public, anon, authenticated;


-- =============================================================================
-- 6. Rebuild the Cricket read aggregate using canonical sources only
-- =============================================================================
--
-- The Flutter Cricket model may stay flat. The compatibility here is only
-- SHAPE compatibility; no legacy storage remains.
--
-- team_a_captain / team_b_captain are now derived exclusively from the
-- canonical per-match Cricket participant flags.
-- =============================================================================

create view public.cricket_match_details
with (security_invoker = true)
as
select
  -- Shared shell.
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

  -- Cricket extension, exposed under the current Flutter wire names.
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
  ) as team_b_captain

from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket';


grant select
  on public.cricket_match_details
  to anon, authenticated, service_role;


comment on view public.cricket_match_details is
  'Canonical Cricket read aggregate. Shared match facts come from matches; '
  'Cricket state comes from cricket_matches; captain snapshots are derived '
  'from cricket_match_players. No legacy Cricket storage is read.';


-- =============================================================================
-- 7. Rebuild the Cricket "my matches" API on the canonical aggregate
-- =============================================================================

create function public.list_my_cricket_matches()
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

  order by
    coalesce(
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
-- 8. Final documentation comments
-- =============================================================================

comment on table public.cricket_matches is
  'Cricket extension of the sport-neutral matches shell. Owns Cricket format '
  'snapshot, toss/start state, scoring mode, revised conditions, detailed '
  'result and player-of-the-match.';

comment on table public.cricket_match_players is
  'Cricket extension of match_players. Owns playing-XI state, batting order, '
  'captain/vice-captain/wicket-keeper/substitute flags.';
