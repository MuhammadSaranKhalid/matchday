-- =============================================================================
-- start_innings — let the BATTING SIDE set its own on-field lineup.
--
-- WHY
--   `20260603130000_batting_side_scoring` moved the per-delivery write path
--   (record_ball / undo_last_ball) onto `_can_score_innings` (the team currently
--   batting), but left `start_innings` on `_can_score_match` (creator/organiser).
--
--   `start_innings` is ALSO the RPC the scoring screen calls to set the on-field
--   trio mid-innings: the new batter after a wicket, the opening bowler, and the
--   next bowler at the end of an over (it upserts match_innings_state — totals
--   are preserved by the ON CONFLICT clause). So after the batting-side change a
--   batting manager who is NOT the match creator could record the wicket ball
--   (striker → null) but the follow-up start_innings that sets the new batter
--   was rejected by `_can_score_match` — and the client swallowed the error.
--   Net effect: pick a new batter and nobody appears on strike. Same failure hit
--   the opening-bowler and end-of-over-bowler pickers.
--
-- WHAT
--   Widen the auth gate to `_can_score_match OR _can_score_innings`. This is
--   STRICTLY ADDITIVE — everyone who could start an innings before still can
--   (preserving the match-start flow), and the batting side gains the ability to
--   set its own lineup. start_innings is idempotent setup (not delivery scoring),
--   so allowing both the organiser and the batting side is safe.
--
--   Only the deployed 6-arg overload (…,p_target) exists / is called by the app;
--   the legacy 5-arg overload is not present and is intentionally NOT recreated
--   here (doing so would add an ambiguous overload). Body is otherwise verbatim
--   from the deployed definition.
--
-- ROLLBACK
--   Restore the single `_can_score_match` check.
-- =============================================================================
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
  v_uid    uuid := auth.uid();
  v_status public.match_status;
begin
  -- Auth gate. Batting side (_can_score_innings) OR organiser/creator/assigned
  -- scorer (_can_score_match). Additive: nobody who could start before loses it.
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not (
       public._can_score_match(p_match_id)
       or public._can_score_innings(p_match_id, p_innings_number)
     ) then
    raise exception 'Only the batting team or the match organiser can set the lineup for this innings'
      using errcode = '42501';
  end if;

  -- Input shape
  if p_innings_number not between 1 and 4 then
    raise exception 'innings_number must be between 1 and 4' using errcode = '23514';
  end if;
  if p_striker_id is null or p_non_striker_id is null or p_bowler_id is null then
    raise exception 'Striker, non-striker and bowler are all required'
      using errcode = '23502';
  end if;
  if p_striker_id = p_non_striker_id then
    raise exception 'Striker and non-striker must be different players'
      using errcode = '23514';
  end if;

  -- Lock + status guard. The match row is locked so a concurrent
  -- submit_match_result / start_innings serialises.
  select status into v_status from public.matches
   where match_id = p_match_id for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'Cannot start innings on a finalised match (status %)', v_status
      using errcode = '23000';
  end if;

  -- Lineup membership. All three must belong to this match.
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_striker_id and match_id = p_match_id
  ) then
    raise exception 'Striker is not in this match''s lineup'
      using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_non_striker_id and match_id = p_match_id
  ) then
    raise exception 'Non-striker is not in this match''s lineup'
      using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.match_players
     where match_player_id = p_bowler_id and match_id = p_match_id
  ) then
    raise exception 'Bowler is not in this match''s lineup'
      using errcode = '23503';
  end if;

  -- Upsert the innings row. ON CONFLICT covers the re-call case (scorer
  -- correcting an opener). Totals are left untouched on re-call. The target is
  -- coalesced so a re-call that omits it preserves the chase target.
  insert into public.match_innings_state (
    match_id, innings_number, striker_id, non_striker_id, bowler_id, target
  )
  values (
    p_match_id, p_innings_number::smallint,
    p_striker_id, p_non_striker_id, p_bowler_id, p_target
  )
  on conflict (match_id, innings_number) do update
     set striker_id     = excluded.striker_id,
         non_striker_id = excluded.non_striker_id,
         bowler_id      = excluded.bowler_id,
         target         = coalesce(excluded.target, match_innings_state.target),
         version        = match_innings_state.version + 1;

  -- Flip the match to live (idempotent if already live; actual_start_time is
  -- only stamped the first time). This also covers the innings_break -> live
  -- transition when the second innings starts.
  update public.matches
     set status            = 'live',
         actual_start_time = coalesce(actual_start_time, now())
   where match_id = p_match_id;
end;
$$;
