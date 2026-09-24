-- Migration: 20260923082500_fix_match_room_can_record_toss.sql
--
-- Aligns get_match_room_snapshot 'can_record_toss' capability with the
-- command write boundary in cricket-match-action authorization_repository.ts.
--
-- Toss authority belongs to:
--   1. Explicit match-scoped official (public.can('match', p_match_id, 'cricket.match.setup'))
--   2. Team-scoped cricket.match.setup for the configured setup side team
--      (cricket_matches.setup_side -> match_teams.team_id -> public.can('team', ...))

create or replace function public.get_match_room_snapshot(p_match_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    -- `cricket_match_details` is the canonical flattened match projection
    -- consumed by MatchDto; do not reconstruct lifecycle fields here.
    'match', to_jsonb(d),

    -- Every committed runtime mutation increments this value. Clients reject
    -- old/equal snapshots and use gaps as a signal to perform a fresh read.
    'revision', cm.state_revision,

    -- Participants are match-local identities. Profile/unclaimed joins are
    -- presentation metadata only; downstream scoring references the stable
    -- match_player_id regardless of which identity kind supplied the name.
    'participants', coalesce((
      select jsonb_agg(
        to_jsonb(mp)
        || jsonb_build_object(
          'cricket', to_jsonb(cmp),
          'profile', to_jsonb(pr),
          'unclaimed', to_jsonb(up)
        )
        order by mp.team_side, cmp.batting_order nulls last, mp.display_name
      )
      from public.match_players mp
      left join public.cricket_match_players cmp
        on cmp.match_player_id = mp.match_player_id
      left join public.profiles pr on pr.user_id = mp.user_id
      left join public.unclaimed_players up on up.unclaimed_id = mp.unclaimed_id
      where mp.match_id = p_match_id
    ), '[]'::jsonb),

    -- The highest innings is the currently relevant hot state. A missing row
    -- is valid before the complete opening trio is committed.
    'innings', (
      select to_jsonb(s)
      from public.cricket_match_innings_state s
      where s.match_id = p_match_id
      order by s.innings_number desc
      limit 1
    ),

    -- Lease data remains observable for scorer coordination. It is not used
    -- to invent a separate UI authorization answer; command authorization is
    -- based on the verified actor and effective RBAC permission.
    'scorer_lease', (
      select to_jsonb(sl)
      from public.match_scorer_leases sl
      where sl.match_id = p_match_id
        and sl.lease_expires_at > now()
    ),

    'capabilities', jsonb_build_object(
      -- Toss authority: belongs to the match-scoped Cricket official or
      -- team-scoped cricket.match.setup on the configured setup side.
      'can_record_toss', coalesce(
        public.can('match', p_match_id, 'cricket.match.setup')
        or exists (
          select 1
          from public.match_teams mt
          where mt.match_id = p_match_id
            and mt.team_side = cm.setup_side
            and public.can('team', mt.team_id, 'cricket.match.setup')
        ),
        false
      ),

      -- With no innings row the next operation is innings 1. At an innings
      -- break, max(innings_number) identifies the active/newest innings. Most
      -- importantly, this is the same function used by the write boundary,
      -- so team-role and match-role authorization cannot drift apart again.
      'can_setup_innings', coalesce(public.can_score_innings(
        p_match_id,
        coalesce((
          select max(s.innings_number)::integer
          from public.cricket_match_innings_state s
          where s.match_id = p_match_id
        ), 1)
      ), false),

      -- A scorer may add a match-only participant for either side so an
      -- unexpected batter or bowler can be entered without modifying either
      -- permanent team roster. The same scorer predicate gates this control.
      'can_add_participant', coalesce(public.can_score_innings(
        p_match_id,
        coalesce((
          select max(s.innings_number)::integer
          from public.cricket_match_innings_state s
          where s.match_id = p_match_id
        ), 1)
      ), false),

      -- Retained as the explicit scoring capability for scoring surfaces.
      'can_score', coalesce(public.can_score_innings(
        p_match_id,
        coalesce((
          select max(s.innings_number)::integer
          from public.cricket_match_innings_state s
          where s.match_id = p_match_id
        ), 1)
      ), false)
    ),
    'server_time', now()
  )
  from public.cricket_match_details d
  join public.cricket_matches cm on cm.match_id = d.match_id
  where d.match_id = p_match_id;
$$;

revoke all on function public.get_match_room_snapshot(uuid) from public, anon;
grant execute on function public.get_match_room_snapshot(uuid)
  to authenticated, service_role;
