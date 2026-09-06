-- =============================================================================
-- 20260901000000 · tournament_fixtures_and_decline_reason
-- =============================================================================
-- Two faults found by driving the organiser console against this database.
--
--   1. Lock & Publish silently created nothing. `matches` has RLS enabled with
--      exactly one policy — `matches_read_all` FOR SELECT — so there is no
--      client INSERT path at all, yet fixture generation inserted straight
--      from the client. Every other write in this schema goes through a
--      SECURITY DEFINER RPC; this one didn't. Nothing downstream of the draw
--      (bracket, live ops, standings, awards) could ever run.
--
--   2. The decline dialog promises "they are told the reason", but
--      reject_tournament_registration(uuid) has no reason parameter, so the
--      organiser's words were collected and dropped. This adds a column to
--      keep the reason and an overload that stores it and notifies the team.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Keep the decision reason.
-- -----------------------------------------------------------------------------
-- tournament_teams.decision_reason is declared inline in
-- 20260101000310_tournament_teams.sql (folded there 2026-09-06).

-- Overload rather than a replacement: the 1-arg form stays for any caller that
-- has no reason to give.
create or replace function public.reject_tournament_registration(
  p_registration_id uuid,
  p_reason          text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_tournament_id uuid;
  v_registered_by uuid;
  v_team_id       uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select tournament_id, registered_by, team_id
    into v_tournament_id, v_registered_by, v_team_id
    from public.tournament_teams
   where registration_id = p_registration_id and status = 'pending'
   for update;

  if v_tournament_id is null then
    raise exception 'Registration not found or not pending' using errcode = 'P0002';
  end if;

  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can reject' using errcode = '42501';
  end if;

  update public.tournament_teams
     set status          = 'rejected',
         decided_by      = v_uid,
         decided_at      = now(),
         decision_reason = nullif(btrim(coalesce(p_reason, '')), ''),
         updated_at      = now()
   where registration_id = p_registration_id;

  -- Tell the manager who applied, so the reason actually reaches someone.
  if v_registered_by is not null then
    insert into public.notifications (recipient_id, type, payload)
    values (
      v_registered_by,
      'tournament_post',
      jsonb_build_object(
        'tournament_id', v_tournament_id,
        'team_id', v_team_id,
        'route', '/tournaments/' || v_tournament_id::text,
        'reason', 'registration_declined',
        'message', nullif(btrim(coalesce(p_reason, '')), '')
      )
    );
  end if;
end;
$$;

revoke all on function public.reject_tournament_registration(uuid, text) from public;
grant execute on function public.reject_tournament_registration(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Fixture generation.
-- -----------------------------------------------------------------------------
-- `p_slots` is the ordered draw the console previews:
--   [{ "team_a_id": uuid, "team_b_id": uuid, "scheduled_start_time": iso8601,
--      "venue": text, "round": text, "bracket_round_number": int,
--      "bracket_match_number": int }]
--
-- A bye is expressed by omitting the team from the array entirely — an odd
-- field simply produces one fewer fixture, and that team enters the next round
-- untouched. No half-populated match row is created, because a match with one
-- side null would break the scoring engine's assumptions.
create or replace function public.tournament_generate_fixtures(
  p_tournament_id uuid,
  p_slots         jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_t        record;
  v_existing int;
  v_created  int;
  v_format   jsonb;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can publish fixtures'
      using errcode = '42501';
  end if;

  select status, format into v_t
    from public.tournaments where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  v_format := v_t.format;

  if v_t.status in ('completed', 'cancelled', 'abandoned') then
    raise exception 'This tournament is closed' using errcode = '22023';
  end if;

  -- Locking the draw is once-only: the dialog says so, and re-running would
  -- duplicate the bracket.
  select count(*) into v_existing
    from public.matches where tournament_id = p_tournament_id;

  if v_existing > 0 then
    raise exception 'The draw is already locked (% fixtures exist)', v_existing
      using errcode = '22023';
  end if;

  if jsonb_typeof(p_slots) <> 'array' or jsonb_array_length(p_slots) = 0 then
    raise exception 'No fixtures to publish' using errcode = '22023';
  end if;

  with slot as (
    select * from jsonb_array_elements(p_slots) as s(elem)
  ),
  inserted as (
    insert into public.matches (
      tournament_id, match_type, match_format, stage, round,
      bracket_round_number, bracket_match_number,
      team_a_id, team_b_id, venue, scheduled_start_time,
      format, status, created_by
    )
    select
      p_tournament_id,
      'tournament',
      -- Keep the match's own format aligned with the cup's. The wizard writes
      -- a human preset ("T20", "The Hundred"); map it rather than casting,
      -- which would throw on anything that is not already an enum label.
      case lower(coalesce(v_format->>'format_preset', ''))
        when 'odi'          then 'odi'
        when 'the hundred'  then 'the_hundred'
        when 'test'         then 'test'
        when 'custom limited overs' then 'custom_limited'
        else 't20'
      end::public.match_format,
      case
        when slot.elem->>'round' ilike '%final%'
             and slot.elem->>'round' not ilike '%semi%'
             and slot.elem->>'round' not ilike '%quarter%' then 'final'
        when slot.elem->>'round' ilike '%semi%'    then 'semi_final'
        when slot.elem->>'round' ilike '%quarter%' then 'quarter_final'
        else 'group'
      end::public.match_stage,
      slot.elem->>'round',
      (slot.elem->>'bracket_round_number')::int,
      (slot.elem->>'bracket_match_number')::int,
      (slot.elem->>'team_a_id')::uuid,
      (slot.elem->>'team_b_id')::uuid,
      nullif(slot.elem->>'venue', ''),
      (slot.elem->>'scheduled_start_time')::timestamptz,
      public._normalize_match_format(v_format),
      'scheduled',
      v_uid
    from slot
    where (slot.elem->>'team_a_id') is not null
      and (slot.elem->>'team_b_id') is not null
    returning 1
  )
  select count(*) into v_created from inserted;

  update public.tournaments
     set status = 'upcoming', updated_at = now()
   where tournament_id = p_tournament_id;

  -- Seed the table so standings render from the moment the draw is locked.
  perform public.recalculate_tournament_standings(p_tournament_id);

  return v_created;
end;
$$;

revoke all on function public.tournament_generate_fixtures(uuid, jsonb) from public;
grant execute on function public.tournament_generate_fixtures(uuid, jsonb) to authenticated;
