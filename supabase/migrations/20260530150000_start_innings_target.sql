-- F1.3 — Extend start_innings with a p_target param.
--
-- The scoring engine detects a successful run-chase by reading
-- match_innings_state.target (engine.ts: targetReached = totalRuns >= target).
-- Until now nothing could set that column. The innings-break flow now passes
-- target = (first-innings runs + 1) when it starts the second innings.
--
-- We must DROP the old 5-arg function before recreating the 6-arg version:
-- adding a defaulted 6th parameter would otherwise create an overload, making
-- the existing 5-arg named calls ambiguous. Existing callers (which pass the
-- five named params) keep working — p_target simply defaults to NULL.

drop function if exists public.start_innings(uuid, integer, uuid, uuid, uuid);

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
  -- Auth gate
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
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

revoke all on function public.start_innings(uuid, integer, uuid, uuid, uuid, integer)
  from public;
grant execute on function public.start_innings(uuid, integer, uuid, uuid, uuid, integer)
  to authenticated;
