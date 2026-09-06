-- =============================================================================
-- 0822 · Make a match creatable and finishable again
-- =============================================================================
-- Three faults, all of which stop a match reaching a result. Found reviewing
-- the scoring path end to end (docs/offline-scoring-design.md, 2026-08-22).
--
-- 1. `_normalize_match_format(jsonb)` was CALLED by accept_pool_application and
--    had never been defined anywhere in this repo. Every pool acceptance failed
--    at runtime with "function does not exist".
--
-- 2. `matches.format` defaulted to '{}', and the sane defaults sat in
--    `rules_config` under DIFFERENT key names (`max_overs`, not
--    `overs_per_innings`). The client and the scoring engine read `format`, so
--    a match created without an explicit format had overs_per_innings = 0,
--    which the engine reads as UNLIMITED — the innings could never end on overs.
--    (Fixed at the source on 2026-09-06: the two blobs are now one column.)
--
-- 3. Both match-creation RPCs still wrote the pre-reset `match_players` shape:
--    `profile_id` (now `user_id`), `is_captain` / `is_keeper` (now one `role`
--    enum), `team_side` of 'a' / 'b' (now 'team_a' / 'team_b'), and no
--    `display_name` at all — which is NOT NULL. plpgsql bodies are not
--    column-checked at CREATE time, so both compiled fine and failed on the
--    first real acceptance. No match ever got a lineup.
--
-- Also closes an authorization hole in `start_innings` (below).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1 & 2. Format normalization — MOVED
-- -----------------------------------------------------------------------------
-- `_normalize_match_format(jsonb)` and the `matches.format` DEFAULT that uses
-- it were defined here. Both moved into 20260101000400_matches.sql during the
-- 2026-09-06 consolidation, so the column carries a playable default from the
-- moment the table exists rather than acquiring one much later in the run.
--
-- The backfill that once stood here read `rules_config`, the second format
-- blob. That column no longer exists (merged into `format`), and with the
-- default now set at CREATE TABLE time there are no unusable rows to repair.

-- -----------------------------------------------------------------------------
-- 3. Match creation writes the current match_players shape
-- -----------------------------------------------------------------------------
-- Bodies below are the existing RPCs with ONLY the lineup INSERT corrected (and
-- the format normalised in accept_match_request). Everything else — the race
-- guards, the counter/pending branches, the notification fan-out — is unchanged.

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
    v_format     := public._normalize_match_format(coalesce(p_format, v_req.countered_format, v_req.proposed_format, '{}'::jsonb));
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
    v_format     := public._normalize_match_format(coalesce(p_format, v_req.proposed_format, '{}'::jsonb));
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
    v_format     := public._normalize_match_format(coalesce(p_format, v_req.proposed_format, '{}'::jsonb));
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
    match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi
  )
  select v_match_id, 'team_a',
         tm.user_id, tm.unclaimed_id,
         -- display_name is NOT NULL on match_players: the lineup keeps its
         -- own copy of the name so a match still reads correctly if the
         -- profile is later renamed, suspended or deleted.
         coalesce(pr.display_name, up.display_name, 'Player'),
         -- The new schema carries ONE role enum where the old one had two
         -- independent booleans, so a captain who also keeps wicket can no
         -- longer be both. Captain wins — it is the role that carries
         -- permissions (toss, openers, starting the match).
         case
           when tm.user_id = v_a_captain then 'captain'::public.match_role
           when tm.user_id = v_req.from_team_keeper_id or tm.unclaimed_id = v_req.from_team_keeper_id
             then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end,
         true
    from public.team_members tm
    left join public.profiles pr          on pr.user_id      = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
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
    match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi
  )
  select v_match_id, 'team_b',
         tm.user_id, tm.unclaimed_id,
         -- display_name is NOT NULL on match_players: the lineup keeps its
         -- own copy of the name so a match still reads correctly if the
         -- profile is later renamed, suspended or deleted.
         coalesce(pr.display_name, up.display_name, 'Player'),
         -- The new schema carries ONE role enum where the old one had two
         -- independent booleans, so a captain who also keeps wicket can no
         -- longer be both. Captain wins — it is the role that carries
         -- permissions (toss, openers, starting the match).
         case
           when tm.user_id = v_b_captain then 'captain'::public.match_role
           when tm.user_id = v_to_keeper or tm.unclaimed_id = v_to_keeper
             then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end,
         true
    from public.team_members tm
    left join public.profiles pr          on pr.user_id      = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
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

-- No re-grant needed for either RPC: CREATE OR REPLACE FUNCTION preserves the
-- existing privileges, and both were already revoked from public and granted to
-- authenticated by the migrations that first defined them. Restating a grant
-- here would mean restating the signature, and getting that wrong fails the
-- whole migration for no benefit.

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
  v_app            public.match_pool_applications%rowtype;
  v_req            public.match_challenges%rowtype;
  v_match_id       uuid;
  v_format         jsonb;
  v_a_captain      uuid;
  v_b_captain      uuid;
  v_host_name      text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_app from public.match_pool_applications
   where application_id = p_application_id
   for update;

  if not found then
    raise exception 'Application not found' using errcode = 'P0002';
  end if;

  if v_app.status != 'pending' then
    raise exception 'Application is no longer pending (status: %)', v_app.status
      using errcode = '22023';
  end if;

  select * into v_req from public.match_challenges
   where request_id = v_app.request_id
   for update;

  if not found then
    raise exception 'Match request not found' using errcode = 'P0002';
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
  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_app.applicant_team_id, v_app.applicant_xi);

  v_a_captain := public._team_current_captain(v_req.from_team_id);
  v_b_captain := public._team_current_captain(v_app.applicant_team_id);
  if v_a_captain is null or v_b_captain is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  v_format := public._normalize_match_format(v_req.proposed_format);

  -- Insert match row
  insert into public.matches (
    match_type, tournament_id,
    team_a_id, team_b_id,
    team_a_captain, team_b_captain,
    format, venue, scheduled_start_time,
    status, created_by
  ) values (
    'friendly', null,
    v_req.from_team_id, v_app.applicant_team_id,
    v_a_captain, v_b_captain,
    v_format, v_req.proposed_venue, v_req.proposed_start_time,
    'scheduled', auth.uid()
  )
  returning match_id into v_match_id;

  -- Populate Team A match_players
  insert into public.match_players (
    match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi
  )
  select v_match_id, 'team_a',
         tm.user_id, tm.unclaimed_id,
         -- display_name is NOT NULL on match_players: the lineup keeps its
         -- own copy of the name so a match still reads correctly if the
         -- profile is later renamed, suspended or deleted.
         coalesce(pr.display_name, up.display_name, 'Player'),
         -- The new schema carries ONE role enum where the old one had two
         -- independent booleans, so a captain who also keeps wicket can no
         -- longer be both. Captain wins — it is the role that carries
         -- permissions (toss, openers, starting the match).
         case
           when tm.user_id = v_a_captain then 'captain'::public.match_role
           when tm.user_id = v_req.from_team_keeper_id or tm.unclaimed_id = v_req.from_team_keeper_id
             then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end,
         true
    from public.team_members tm
    left join public.profiles pr          on pr.user_id      = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
   where tm.team_id = v_req.from_team_id
     and tm.status  = 'active'
     and (
       coalesce(array_length(v_req.from_team_xi, 1), 0) = 0
       or tm.user_id      = any(v_req.from_team_xi)
       or tm.unclaimed_id = any(v_req.from_team_xi)
     );

  -- Populate Team B (Applicant) match_players
  insert into public.match_players (
    match_id, team_side, user_id, unclaimed_id, display_name,
    role, is_in_playing_xi
  )
  select v_match_id, 'team_b',
         tm.user_id, tm.unclaimed_id,
         -- display_name is NOT NULL on match_players: the lineup keeps its
         -- own copy of the name so a match still reads correctly if the
         -- profile is later renamed, suspended or deleted.
         coalesce(pr.display_name, up.display_name, 'Player'),
         -- The new schema carries ONE role enum where the old one had two
         -- independent booleans, so a captain who also keeps wicket can no
         -- longer be both. Captain wins — it is the role that carries
         -- permissions (toss, openers, starting the match).
         case
           when tm.user_id = v_b_captain then 'captain'::public.match_role
           when tm.user_id = v_app.applicant_keeper_id or tm.unclaimed_id = v_app.applicant_keeper_id
             then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end,
         true
    from public.team_members tm
    left join public.profiles pr          on pr.user_id      = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
   where tm.team_id = v_app.applicant_team_id
     and tm.status  = 'active'
     and (
       coalesce(array_length(v_app.applicant_xi, 1), 0) = 0
       or tm.user_id      = any(v_app.applicant_xi)
       or tm.unclaimed_id = any(v_app.applicant_xi)
     );

  -- Mark accepted application
  update public.match_pool_applications
     set status        = 'accepted',
         decided_at    = now(),
         decision_note = p_decision_note,
         updated_at    = now()
   where application_id = p_application_id;

  -- Automatically reject all other pending applications for this challenge
  update public.match_pool_applications
     set status        = 'rejected',
         decided_at    = now(),
         decision_note = 'Another opponent was selected for this fixture',
         updated_at    = now()
   where request_id = v_app.request_id
     and application_id != p_application_id
     and status = 'pending';

  -- Close the match_request
  update public.match_challenges
     set status        = 'accepted',
         decided_by    = auth.uid(),
         decided_at    = now(),
         decision_note = p_decision_note,
         match_id      = v_match_id,
         to_team_id    = v_app.applicant_team_id
   where request_id = v_app.request_id;

  -- Notifications
  select team_name into v_host_name from public.teams where team_id = v_req.from_team_id;

  -- Notify accepted team
  insert into public.notifications (
    recipient_id,
    type,
    payload
  )
  select distinct
    recip.uid,
    'match_request_decision'::public.notification_type,
    jsonb_build_object(
      'request_id',   v_app.request_id,
      'match_id',     v_match_id,
      'decision',     'accepted',
      'host_team_id', v_req.from_team_id,
      'actor_id',     auth.uid(),
      'message',      coalesce(v_host_name, 'Host team') || ' accepted your match application!'
    )
  from public.teams t,
  lateral (
    select t.owner_id as uid
    union
    select unnest(coalesce(t.managers, '{}'::uuid[])) as uid
  ) recip
  where t.team_id = v_app.applicant_team_id
    and recip.uid is not null;

  return v_match_id;
end;
$$;


-- -----------------------------------------------------------------------------
-- 4. start_innings: authorize the caller
-- -----------------------------------------------------------------------------
-- It was the only lifecycle RPC with NO permission check at all, while its three
-- siblings each call _is_match_captain. Any authenticated account could
-- overwrite any match's on-field trio, and because it unconditionally set
-- status = 'live' it could also resurrect a completed match.
--
-- Gated on _can_score_innings, not _is_match_captain: starting an innings is
-- the same act as scoring it, and the batting side owns that (design doc D12).
create or replace function public.start_innings(
  p_match_id uuid,
  p_innings_number integer,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_bowler_id uuid,
  p_target integer default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_innings_id   uuid;
  v_status       public.match_status;
  v_team_a       uuid;
  v_team_b       uuid;
  v_toss_won     uuid;
  v_toss_dec     public.toss_decision;
  -- Team IDS are uuid and side LABELS are text. Keeping them in one variable
  -- is what broke this: a uuid was assigned into a text variable and then
  -- compared back against a uuid column, which is `text = uuid` and has no
  -- operator, so every call failed at runtime.
  v_batting_team uuid;
  v_batting_side text;
  v_bowling_side text;
begin
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting side can start this innings'
      using errcode = '42501';
  end if;

  select team_a_id, team_b_id, toss_won_by, toss_decision, status
    into v_team_a, v_team_b, v_toss_won, v_toss_dec, v_status
    from public.matches
   where match_id = p_match_id;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'This match is already finished' using errcode = '22023';
  end if;

  -- Which side bats is decided by the toss, not by the innings number being
  -- odd. The previous version hardcoded odd = team_a, so every match where
  -- team B batted first recorded both innings against the wrong side.
  v_batting_team := case
    when v_toss_won is null or v_toss_dec is null then v_team_a
    when v_toss_dec = 'bat' then v_toss_won
    when v_toss_won = v_team_a then v_team_b
    else v_team_a
  end;

  if p_innings_number % 2 = 0 then
    v_batting_team := case
      when v_batting_team = v_team_a then v_team_b else v_team_a
    end;
  end if;

  v_batting_side := case when v_batting_team = v_team_a then 'team_a' else 'team_b' end;
  v_bowling_side := case when v_batting_team = v_team_a then 'team_b' else 'team_a' end;

  -- The target goes to match_innings_state only. match_innings.target_runs was
  -- a second copy written by this same statement and was dropped 2026-09-06.
  insert into public.match_innings (
    match_id, innings_number, batting_team_side, bowling_team_side
  ) values (
    p_match_id, p_innings_number, v_batting_side, v_bowling_side
  )
  on conflict (match_id, innings_number) do update set
    batting_team_side = excluded.batting_team_side,
    bowling_team_side = excluded.bowling_team_side
  returning innings_id into v_innings_id;

  insert into public.match_innings_state (
    innings_id, match_id, innings_number, striker_id, non_striker_id, bowler_id, target
  ) values (
    v_innings_id, p_match_id, p_innings_number, p_striker_id, p_non_striker_id, p_bowler_id, p_target
  )
  on conflict (innings_id) do update set
    striker_id = p_striker_id,
    non_striker_id = p_non_striker_id,
    bowler_id = p_bowler_id,
    target = coalesce(excluded.target, match_innings_state.target),
    version = match_innings_state.version + 1,
    updated_at = now();

  update public.matches
  set status = 'live', updated_at = now()
  where match_id = p_match_id;
end;
$$;

revoke all on function public.start_innings(uuid, integer, uuid, uuid, uuid, integer) from public;
grant execute on function public.start_innings(uuid, integer, uuid, uuid, uuid, integer) to authenticated;
