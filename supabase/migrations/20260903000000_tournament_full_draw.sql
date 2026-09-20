-- =============================================================================
-- 20260903000000 · tournament_full_draw
-- =============================================================================
-- Locking a draw only ever created round one.
--
-- 20260901000000 gave fixture generation a SECURITY DEFINER path (the client
-- could not insert into `matches` at all before that), but it kept two
-- restrictions that made a knockout unfinishable:
--
--   1. It dropped any slot with a null team — so the semi-finals and the final
--      were never inserted. `trg_advance_tournament_bracket` (20260825000000,
--      revised 20260830000000) moves a winner into the next round by looking
--      for a row whose `prev_match_a_id` / `prev_match_b_id` is the match that
--      just finished and whose corresponding side is still null. With no such
--      rows the trigger fired on every result and advanced nobody. A cup could
--      never reach a champion, which in turn made the whole wrap-up flow —
--      awards, the champion moment, the archive page — unreachable by playing.
--
--   2. It never stored the feeder columns at all, even though `matches` has
--      carried `prev_match_a_id` / `prev_match_b_id` since 20260101000400 and
--      the client's own `FixtureSlotParams` had fields for them.
--
-- Both sides are nullable already, so no schema change is needed here — this
-- is entirely about what the RPC accepts and writes.
--
-- The draw itself is computed on the client by `buildDraw`
-- (lib/features/tournaments/domain/draw/draw_builder.dart), which is the only
-- pairing implementation in the codebase and is covered by the Dart suite.
-- Deliberately NOT reimplemented in SQL: two implementations of a bracket
-- would drift exactly the way the two Dart ones did before they were merged.
-- This function's job is authorisation, referential integrity and atomicity.
--
-- Feeder links are expressed with client-side `slot_id` strings ("r2m1")
-- rather than match ids, because no match exists when the plan is built. The
-- function mints every match id up front, so a single INSERT can satisfy the
-- self-referencing foreign key: row-level FK triggers are queued and fire at
-- end of statement, by which point every referenced row is present.
--
-- Seeding is folded in. `tournament_teams.seed_number` was read in four places
-- and written in none, so the organiser's drag order was lost the moment they
-- left the tab and every "SEED #n" badge was blank. The order IS the draw, so
-- it is stored in the same transaction that locks it.
-- =============================================================================

-- The argument list changes, so the old function is dropped rather than
-- overloaded — an overload would leave the broken 2-arg version callable and
-- make `f(uuid, jsonb)` ambiguous.
drop function if exists public.tournament_generate_fixtures(uuid, jsonb);

-- `p_slots` is the ordered plan the console previews:
--   [{ "slot_id": text,                  -- unique within the payload
--      "team_a_id": uuid | null,         -- null when decided by prev_slot_a
--      "team_b_id": uuid | null,
--      "prev_slot_a": text | null,       -- another slot_id in this payload
--      "prev_slot_b": text | null,
--      "scheduled_start_time": iso8601,
--      "venue": text,
--      "round": text,
--      "bracket_round_number": int,
--      "bracket_match_number": int }]
--
-- A bye is expressed by omitting the fixture entirely and carrying the team
-- straight into the next round's slot as a concrete `team_a_id`/`team_b_id`.
-- A row with one side null and no feeder on that side is rejected: it is
-- indistinguishable from an unresolved tie and would never resolve.
--
-- `p_seed_order` is the approved teams in draw order; position becomes
-- `seed_number`.
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
  v_uid       uuid := auth.uid();
  v_t         record;
  v_existing  int;
  v_created   int;
  v_format    jsonb;
  v_count     int;
  v_distinct  int;
  v_bad       int;
  v_ids       jsonb;
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

  -- ── Validate the plan before writing any of it ────────────────────────────

  -- Order matters: a payload of all-null slot_ids would otherwise trip the
  -- duplicate check and report the wrong fault.
  select count(*) into v_bad
    from jsonb_array_elements(p_slots) as s(elem)
   where elem->>'slot_id' is null;

  if v_bad > 0 then
    raise exception 'Every fixture needs a slot_id' using errcode = '22023';
  end if;

  select count(*), count(distinct elem->>'slot_id')
    into v_count, v_distinct
    from jsonb_array_elements(p_slots) as s(elem);

  if v_distinct < v_count then
    raise exception 'Duplicate slot_id in the draw' using errcode = '22023';
  end if;

  -- Each side must be either a known team or a feeder. Anything else is a
  -- fixture that can never resolve.
  select count(*) into v_bad
    from jsonb_array_elements(p_slots) as s(elem)
   where (elem->>'team_a_id' is null and elem->>'prev_slot_a' is null)
      or (elem->>'team_b_id' is null and elem->>'prev_slot_b' is null);

  if v_bad > 0 then
    raise exception
      'A fixture has a side that is neither a team nor a feeder'
      using errcode = '22023';
  end if;

  -- Mint a match id per slot. Doing it here rather than letting the default
  -- fire is what lets the feeder columns be written in the same INSERT.
  select jsonb_object_agg(elem->>'slot_id', gen_random_uuid())
    into v_ids
    from jsonb_array_elements(p_slots) as s(elem);

  -- Every feeder must name a slot that is actually in this payload.
  select count(*) into v_bad
    from jsonb_array_elements(p_slots) as s(elem)
   where (elem->>'prev_slot_a' is not null
          and not jsonb_exists(v_ids, elem->>'prev_slot_a'))
      or (elem->>'prev_slot_b' is not null
          and not jsonb_exists(v_ids, elem->>'prev_slot_b'));

  if v_bad > 0 then
    raise exception 'A fixture feeds from a slot that is not in the draw'
      using errcode = '22023';
  end if;

  -- ── Write ─────────────────────────────────────────────────────────────────

  with inserted as (
    insert into public.matches (
      match_id, tournament_id, match_type, match_format, stage, round,
      bracket_round_number, bracket_match_number,
      prev_match_a_id, prev_match_b_id,
      team_a_id, team_b_id, venue, scheduled_start_time,
      format, status, created_by
    )
    select
      (v_ids->>(slot.elem->>'slot_id'))::uuid,
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
      (v_ids->>(slot.elem->>'prev_slot_a'))::uuid,
      (v_ids->>(slot.elem->>'prev_slot_b'))::uuid,
      (slot.elem->>'team_a_id')::uuid,
      (slot.elem->>'team_b_id')::uuid,
      nullif(slot.elem->>'venue', ''),
      (slot.elem->>'scheduled_start_time')::timestamptz,
      public._normalize_match_format(v_format),
      'scheduled',
      v_uid
    from jsonb_array_elements(p_slots) as slot(elem)
    returning match_id
  ),
  ext as (
    -- Cricket extension rows for each created fixture.
    insert into public.cricket_matches (match_id, format_code, rules_snapshot)
    select i.match_id, v_format->>'format_preset', v_format
    from inserted i
    returning 1
  )
  select count(*) into v_created from ext;

  -- The order the organiser dragged into IS the draw, so it is recorded in
  -- the same transaction. Read in four places before this, written in none.
  if p_seed_order is not null then
    update public.tournament_teams tt
       set seed_number = ord.pos,
           updated_at  = now()
      from unnest(p_seed_order) with ordinality as ord(team_id, pos)
     where tt.tournament_id = p_tournament_id
       and tt.team_id       = ord.team_id
       and tt.status        = 'approved';
  end if;

  update public.tournaments
     set status = 'upcoming', updated_at = now()
   where tournament_id = p_tournament_id;

  -- Seed the table so standings render from the moment the draw is locked.
  perform public.recalculate_tournament_standings(p_tournament_id);

  return v_created;
end;
$$;

revoke all on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  from public;
grant execute on function public.tournament_generate_fixtures(uuid, jsonb, uuid[])
  to authenticated;

comment on function public.tournament_generate_fixtures(uuid, jsonb, uuid[]) is
  'Locks a tournament draw: inserts every fixture in every round (later rounds '
  'unresolved, linked by prev_match_a_id/prev_match_b_id), records the seed '
  'order, moves the tournament to `upcoming` and seeds the standings table. '
  'Pairing is computed client-side by buildDraw — do not reimplement it here.';
