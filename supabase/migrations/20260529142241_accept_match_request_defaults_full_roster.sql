-- Patch accept_match_request: when the sender or receiver leaves their
-- XI empty (the v1 UX never collects an XI up-front), default to the
-- team's full active roster instead of inserting zero match_players
-- rows. The captain picks openers from the full pool on the Lineup
-- screen — there is no separate Pick-XI step in v1.

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
  v_format      jsonb;
  v_start       timestamptz;
  v_venue       text;
  v_to_team_xi  uuid[];
  v_to_keeper   uuid;
  v_a_captain   uuid;
  v_b_captain   uuid;
  v_updated     integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_challenges
   where request_id = p_request_id
   for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if v_req.status not in ('pending', 'countered') then
    raise exception 'Request is no longer actionable (status: %)', v_req.status
      using errcode = '22023';
  end if;

  if v_req.status = 'countered' then
    if not public.is_team_manager(v_req.from_team_id) then
      raise exception 'Only the original sender can accept a countered request'
        using errcode = '42501';
    end if;
    v_to_team    := v_req.to_team_id;
    v_format     := coalesce(p_format, v_req.countered_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.countered_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.countered_venue, v_req.proposed_venue);
    v_to_team_xi := '{}'::uuid[];
    v_to_keeper  := null;
  elsif v_req.to_team_id is not null then
    if not public.is_team_manager(v_req.to_team_id) then
      raise exception 'Only managers of the receiving team can accept'
        using errcode = '42501';
    end if;
    v_to_team    := v_req.to_team_id;
    v_format     := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
    v_to_keeper  := p_to_team_keeper_id;
  else
    if p_to_team_id is null then
      raise exception 'Open requests require p_to_team_id to claim'
        using errcode = '22023';
    end if;
    if p_to_team_id = v_req.from_team_id then
      raise exception 'A team cannot accept its own challenge'
        using errcode = '23514';
    end if;
    if not public.is_team_manager(p_to_team_id) then
      raise exception 'You can only accept on behalf of teams you manage'
        using errcode = '42501';
    end if;
    v_to_team    := p_to_team_id;
    v_format     := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
    v_to_keeper  := p_to_team_keeper_id;
  end if;

  if v_to_team_xi is not null and array_length(v_to_team_xi, 1) is not null
     and array_length(v_to_team_xi, 1) > v_req.players_per_side then
    raise exception 'to_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;
  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_to_team, v_to_team_xi);

  v_a_captain := public._team_current_captain(v_req.from_team_id);
  v_b_captain := public._team_current_captain(v_to_team);
  if v_a_captain is null or v_b_captain is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  insert into public.matches (
    match_type, tournament_id,
    team_a_id, team_b_id,
    team_a_captain, team_b_captain,
    format, venue, scheduled_start_time,
    status, created_by
  ) values (
    'friendly', null,
    v_req.from_team_id, v_to_team,
    v_a_captain, v_b_captain,
    v_format, v_venue, v_start,
    'scheduled', auth.uid()
  )
  returning match_id into v_match_id;

  -- Cricket extension row.
  insert into public.cricket_matches (match_id, format_code, rules_snapshot)
  values (v_match_id, v_format->>'format_preset', v_format);

  -- ---------------------------------------------------------------------------
  -- MATERIALISE THE PLAYING XIS INTO match_players
  --
  -- v1 UX never collects an XI up front — the captain picks openers from
  -- the full roster on the Lineup screen. So if the XI list is empty,
  -- default to "the team's full active roster". When the XI is non-empty
  -- (a future Pick-XI flow), filter to the picked players.
  --
  -- Polymorphism: tm.user_id XOR tm.unclaimed_id is already enforced by
  -- team_members, so each row satisfies the match_players XOR check.
  -- ---------------------------------------------------------------------------
  insert into public.match_players (
    match_id, team_side, profile_id, unclaimed_id, is_captain, is_keeper
  )
  select v_match_id, 'a',
         tm.user_id, tm.unclaimed_id,
         coalesce(tm.user_id = v_a_captain, false),
         coalesce(tm.user_id    = v_req.from_team_keeper_id
                  or tm.unclaimed_id = v_req.from_team_keeper_id, false)
    from public.team_members tm
   where tm.team_id = v_req.from_team_id
     and tm.status  = 'active'
     and (
       -- Empty XI = include the full active roster.
       coalesce(array_length(v_req.from_team_xi, 1), 0) = 0
       -- Non-empty XI = filter to the picked players.
       or tm.user_id      = any(v_req.from_team_xi)
       or tm.unclaimed_id = any(v_req.from_team_xi)
     );

  insert into public.match_players (
    match_id, team_side, profile_id, unclaimed_id, is_captain, is_keeper
  )
  select v_match_id, 'b',
         tm.user_id, tm.unclaimed_id,
         coalesce(tm.user_id = v_b_captain, false),
         coalesce(tm.user_id    = v_to_keeper
                  or tm.unclaimed_id = v_to_keeper, false)
    from public.team_members tm
   where tm.team_id = v_to_team
     and tm.status  = 'active'
     and (
       coalesce(array_length(v_to_team_xi, 1), 0) = 0
       or tm.user_id      = any(v_to_team_xi)
       or tm.unclaimed_id = any(v_to_team_xi)
     );

  -- Race guard: the inner UPDATE re-asserts the status we read above. If
  -- another concurrent transaction (counter / cancel / decline) already
  -- transitioned the row, our UPDATE matches zero rows and we roll back
  -- — preventing a match from being created against stale terms.
  update public.match_challenges
     set status        = 'accepted',
         decided_by    = auth.uid(),
         decided_at    = now(),
         decision_note = p_decision_note,
         match_id      = v_match_id,
         to_team_id    = v_to_team
   where request_id = p_request_id
     and status     = v_req.status;
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Request changed under us; aborting accept'
      using errcode = '40001';
  end if;

  return v_match_id;
end;
$$;
