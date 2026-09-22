-- Migration: normalize_challenge_match_creation
--
-- Match creation previously straddled two generations of the schema. The
-- challenge RPCs still attempted to write team and format columns that no
-- longer exist on the sport-neutral `matches` shell, then manually copied
-- roster rows. The canonical model is now deliberately single-owner:
--
--   matches            = fixture/lifecycle shell
--   match_teams        = the two stable team-side identities
--   cricket_matches    = Cricket rules and runtime state
--   sync trigger       = match-local participant snapshot
--
-- Both acceptance paths below create those records in dependency order. The
-- deferred cricket-match trigger performs participant materialization once,
-- using the same rules as every other match origin.

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
  v_format jsonb;
  v_start timestamptz;
  v_venue text;
  v_to_team_xi uuid[];
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- Serialize every decision about this request. The final guarded UPDATE is
  -- retained as defense in depth and documents the required state transition.
  select * into v_req
  from public.match_challenges
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
    v_to_team := v_req.to_team_id;
    v_format := coalesce(p_format, v_req.countered_format, v_req.proposed_format, '{}'::jsonb);
    v_start := coalesce(p_scheduled_start_time, v_req.countered_start_time, v_req.proposed_start_time);
    v_venue := coalesce(p_venue, v_req.countered_venue, v_req.proposed_venue);
    v_to_team_xi := '{}'::uuid[];
  elsif v_req.to_team_id is not null then
    if not public.is_team_manager(v_req.to_team_id) then
      raise exception 'Only managers of the receiving team can accept'
        using errcode = '42501';
    end if;
    v_to_team := v_req.to_team_id;
    v_format := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
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
    v_to_team := p_to_team_id;
    v_format := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
  end if;

  if coalesce(array_length(v_to_team_xi, 1), 0) > v_req.players_per_side then
    raise exception 'to_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;

  -- XI inputs remain validated while the development UI still sends them,
  -- but they do not own participant persistence. V1 snapshots the full active
  -- squad and performs playing-XI selection at match time.
  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_to_team, v_to_team_xi);
  if public._team_current_captain(v_req.from_team_id) is null
     or public._team_current_captain(v_to_team) is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  -- Challenge rows may still contain the form's `overs` key. Build the
  -- canonical scoring contract explicitly instead of depending on the removed
  -- `_normalize_match_format` helper. Right-hand JSON values win, except the
  -- canonical overs key which is always populated from either spelling.
  v_format := jsonb_build_object(
    'players_per_team', 11,
    'overs_per_innings', 20,
    'balls_per_over', 6,
    'max_overs_per_bowler', 4
  ) || coalesce(v_format, '{}'::jsonb)
    || jsonb_build_object(
      'overs_per_innings', coalesce(
        nullif(v_format ->> 'overs_per_innings', '')::integer,
        nullif(v_format ->> 'overs', '')::integer,
        20
      )
    );

  -- Create only the sport-neutral fields physically owned by `matches`.
  -- Its AFTER INSERT trigger creates empty team_a/team_b slots atomically.
  insert into public.matches (
    match_type, tournament_id, venue, sport_id,
    scheduled_start_time, status, created_by
  ) values (
    'friendly', null, v_venue, 'cricket',
    coalesce(v_start, now()), 'scheduled', auth.uid()
  ) returning match_id into v_match_id;

  -- Resolve the stable slots instead of embedding team identity on matches.
  -- The participant trigger sees no Cricket extension yet and safely defers
  -- work until the extension row below has been inserted.
  update public.match_teams
  set team_id = case team_side
    when 'team_a' then v_req.from_team_id
    when 'team_b' then v_to_team
  end
  where match_id = v_match_id;

  -- The sender/host is the initial setup side for a friendly. Inserting this
  -- row schedules the canonical deferred participant synchronization trigger.
  insert into public.cricket_matches (
    match_id, format_code, rules_snapshot, setup_side
  ) values (
    v_match_id,
    coalesce(v_format ->> 'format_preset', v_format ->> 'format_code', 't20'),
    v_format,
    'team_a'
  );

  -- The constraint trigger repeats this synchronization at commit, but an
  -- immediate canonical call gives this RPC rows on which to preserve the
  -- optional keeper choices. The synchronizer is idempotent, so there is still
  -- exactly one implementation of participant creation.
  perform public.sync_match_participants(v_match_id);

  update public.cricket_match_players cmp
  set is_wicket_keeper = true
  from public.match_players mp
  where cmp.match_player_id = mp.match_player_id
    and cmp.match_id = v_match_id
    and mp.match_id = v_match_id
    and (
      (mp.team_side = 'team_a' and (
        mp.user_id = v_req.from_team_keeper_id
        or mp.unclaimed_id = v_req.from_team_keeper_id
      ))
      or
      (mp.team_side = 'team_b' and (
        mp.user_id = p_to_team_keeper_id
        or mp.unclaimed_id = p_to_team_keeper_id
      ))
    );

  update public.match_challenges
  set status = 'accepted', decided_by = auth.uid(), decided_at = now(),
      decision_note = p_decision_note, match_id = v_match_id,
      to_team_id = v_to_team
  where request_id = p_request_id and status = v_req.status;
  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    raise exception 'Request changed under us; aborting accept'
      using errcode = '40001';
  end if;

  return v_match_id;
end;
$$;

revoke all on function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
) from public, anon;
grant execute on function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
) to authenticated;

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
begin
  if auth.uid() is null then
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
    raise exception 'Application is no longer pending (status: %)', v_app.status
      using errcode = '22023';
  end if;

  select * into v_req
  from public.match_challenges
  where request_id = v_app.request_id
  for update;
  if not found then
    raise exception 'Match request not found' using errcode = 'P0002';
  end if;
  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the host team can accept applications'
      using errcode = '42501';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Open challenge is no longer active (status: %)', v_req.status
      using errcode = '22023';
  end if;

  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_app.applicant_team_id, v_app.applicant_xi);
  if public._team_current_captain(v_req.from_team_id) is null
     or public._team_current_captain(v_app.applicant_team_id) is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  v_format := jsonb_build_object(
    'players_per_team', 11,
    'overs_per_innings', 20,
    'balls_per_over', 6,
    'max_overs_per_bowler', 4
  ) || coalesce(v_req.proposed_format, '{}'::jsonb)
    || jsonb_build_object(
      'overs_per_innings', coalesce(
        nullif(v_req.proposed_format ->> 'overs_per_innings', '')::integer,
        nullif(v_req.proposed_format ->> 'overs', '')::integer,
        20
      )
    );

  insert into public.matches (
    match_type, tournament_id, venue, sport_id,
    scheduled_start_time, status, created_by
  ) values (
    'friendly', null, v_req.proposed_venue, 'cricket',
    coalesce(v_req.proposed_start_time, now()), 'scheduled', auth.uid()
  ) returning match_id into v_match_id;

  update public.match_teams
  set team_id = case team_side
    when 'team_a' then v_req.from_team_id
    when 'team_b' then v_app.applicant_team_id
  end
  where match_id = v_match_id;

  insert into public.cricket_matches (
    match_id, format_code, rules_snapshot, setup_side
  ) values (
    v_match_id,
    coalesce(v_format ->> 'format_preset', v_format ->> 'format_code', 't20'),
    v_format,
    'team_a'
  );

  perform public.sync_match_participants(v_match_id);

  update public.cricket_match_players cmp
  set is_wicket_keeper = true
  from public.match_players mp
  where cmp.match_player_id = mp.match_player_id
    and cmp.match_id = v_match_id
    and mp.match_id = v_match_id
    and (
      (mp.team_side = 'team_a' and (
        mp.user_id = v_req.from_team_keeper_id
        or mp.unclaimed_id = v_req.from_team_keeper_id
      ))
      or
      (mp.team_side = 'team_b' and (
        mp.user_id = v_app.applicant_keeper_id
        or mp.unclaimed_id = v_app.applicant_keeper_id
      ))
    );

  update public.match_pool_applications
  set status = 'accepted', decided_at = now(),
      decision_note = p_decision_note, updated_at = now()
  where application_id = p_application_id;

  update public.match_pool_applications
  set status = 'rejected', decided_at = now(),
      decision_note = 'Another opponent was selected for this fixture',
      updated_at = now()
  where request_id = v_app.request_id
    and application_id <> p_application_id
    and status = 'pending';

  update public.match_challenges
  set status = 'accepted', decided_by = auth.uid(), decided_at = now(),
      decision_note = p_decision_note, match_id = v_match_id,
      to_team_id = v_app.applicant_team_id
  where request_id = v_app.request_id and status = 'pending';

  if not found then
    raise exception 'Open challenge changed under us; aborting accept'
      using errcode = '40001';
  end if;

  perform public.notify(
    array(select public.team_staff_ids(v_app.applicant_team_id)),
    'match.application.accepted',
    jsonb_build_object(
      'request_id', v_app.request_id,
      'match_id', v_match_id,
      'host_team_id', v_req.from_team_id,
      'opponent_team_id', v_req.from_team_id,
      'actor_id', auth.uid()
    ),
    auth.uid(), 'team', v_app.applicant_team_id
  );

  return v_match_id;
end;
$$;

revoke all on function public.accept_pool_application(uuid, text)
  from public, anon;
grant execute on function public.accept_pool_application(uuid, text)
  to authenticated;
