-- =============================================================================
-- 0420 · Match results — recalc standings, submit result, after-complete trigger
-- =============================================================================
-- Spec §3.9, §4.10. The "what happens when a match completes" pipeline.
-- This file owns three things, all hooking off a single completion event:
--
--   1. recalculate_standings(tournament_id)
--      Walks every completed match's `result` jsonb, aggregates wins / losses
--      / ties / no_results / points / NRR-inputs into tournament_standings,
--      then updates net_run_rate. SECURITY DEFINER so it can bypass the
--      "no direct writes" RLS on standings.
--
--      Idempotent — re-running just rewrites the same rows.
--
--   2. submit_match_result(match_id, result_jsonb)
--      Manual scorecard entry (post-match flow) + the live scorer's "End
--      match" action both call this. Validates the result payload, flips
--      matches.status='completed', stamps end_time/actual_start_time, and
--      relies on the after-complete trigger (3) to do the rest.
--
--   3. _after_match_complete trigger
--      AFTER UPDATE on matches. Fires when a row transitions to 'completed'
--      OR when a result is rewritten while already completed (corrections).
--      Recomputes standings + auto-advances the winner into any later
--      knockout round wired via prev_match_a_id / prev_match_b_id.
--
-- Result jsonb shape (§4.10):
--   {
--     "winner_team_id": "<uuid|null>",         null = tie / no_result
--     "win_type":       "runs|wickets|tie|no_result|walkover",
--     "win_margin":     <int|null>,
--     "summary":        "Lahore Lions won by 22 runs",
--     "innings": [
--       { "innings_number": 1,
--         "batting_team_id": "<uuid>", "bowling_team_id": "<uuid>",
--         "runs": 156, "wickets": 7, "overs": 20.0,
--         "extras": 12, "all_out": false, "declared": false }, ...
--     ]
--   }
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helpers used by recalculate_standings — extract per-team innings runs/overs
-- from the result jsonb.
-- -----------------------------------------------------------------------------
create or replace function public._innings_runs(
  p_result jsonb,
  p_team_id uuid,
  p_when_batting boolean
)
returns integer
language sql
immutable
set search_path = public, pg_temp
as $$
  select sum((i->>'runs')::int)::int
    from jsonb_array_elements(coalesce(p_result->'innings', '[]'::jsonb)) i
   where (
     case when p_when_batting
       then (i->>'batting_team_id')::uuid = p_team_id
       else (i->>'bowling_team_id')::uuid = p_team_id
     end
   );
$$;

create or replace function public._innings_overs(
  p_result jsonb,
  p_team_id uuid,
  p_when_batting boolean
)
returns numeric
language sql
immutable
set search_path = public, pg_temp
as $$
  select sum((i->>'overs')::numeric)
    from jsonb_array_elements(coalesce(p_result->'innings', '[]'::jsonb)) i
   where (
     case when p_when_batting
       then (i->>'batting_team_id')::uuid = p_team_id
       else (i->>'bowling_team_id')::uuid = p_team_id
     end
   );
$$;

revoke all on function public._innings_runs(jsonb, uuid, boolean)  from public;
revoke all on function public._innings_overs(jsonb, uuid, boolean) from public;

-- =============================================================================
-- recalculate_standings — full implementation.
-- Idempotent. Algorithm:
--   1. Seed missing tournament_standings rows for every approved team.
--   2. Drop standings rows for teams no longer approved.
--   3. Reset accumulators to zero (so the recompute doesn't double-count).
--   4. Walk completed matches once per team, aggregate, then UPDATE.
--   5. NRR per team = (runs_for / overs_faced) − (runs_against / overs_bowled).
--
-- group_id filtering is intentionally absent (group_knockout = v1.1).
-- =============================================================================
create or replace function public.recalculate_standings(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_team uuid;
begin
  -- 1. Seed missing rows for approved teams.
  insert into public.tournament_standings (tournament_id, team_id)
  select p_tournament_id, t.team_id
    from public.tournament_approved_teams(p_tournament_id) t
   on conflict (tournament_id, team_id) do nothing;

  -- 2. Drop standings rows for teams no longer approved.
  delete from public.tournament_standings ts
   where ts.tournament_id = p_tournament_id
     and not exists (
       select 1 from public.tournament_approved_teams(p_tournament_id) t
        where t.team_id = ts.team_id
     );

  -- 3. Zero out every counter so the recompute is idempotent.
  update public.tournament_standings
     set matches_played = 0,
         wins           = 0,
         losses         = 0,
         ties           = 0,
         no_results     = 0,
         points         = 0,
         runs_scored    = 0,
         overs_faced    = 0,
         runs_conceded  = 0,
         overs_bowled   = 0,
         net_run_rate   = 0
   where tournament_id = p_tournament_id;

  -- 4. Aggregate completed matches into each team's row.
  for v_team in select team_id from public.tournament_standings
                where tournament_id = p_tournament_id
  loop
    update public.tournament_standings ts
       set matches_played = matches_played + agg.played,
           wins           = wins + agg.wins,
           losses         = losses + agg.losses,
           ties           = ties + agg.ties,
           no_results     = no_results + agg.no_results,
           points         = points + agg.points,
           runs_scored    = runs_scored + coalesce(agg.runs_scored, 0),
           overs_faced    = overs_faced + coalesce(agg.overs_faced, 0),
           runs_conceded  = runs_conceded + coalesce(agg.runs_conceded, 0),
           overs_bowled   = overs_bowled + coalesce(agg.overs_bowled, 0)
      from (
        select
          count(*)::int as played,
          sum(case when (m.result->>'winner_team_id')::uuid = v_team
                   then 1 else 0 end)::int as wins,
          sum(case when (m.result->>'winner_team_id') is not null
                    and (m.result->>'winner_team_id')::uuid <> v_team
                    and (m.result->>'win_type') not in ('no_result')
                   then 1 else 0 end)::int as losses,
          sum(case when m.result->>'win_type' = 'tie'
                   then 1 else 0 end)::int as ties,
          sum(case when m.result->>'win_type' = 'no_result'
                   then 1 else 0 end)::int as no_results,
          sum(case
                when (m.result->>'winner_team_id')::uuid = v_team then 2
                when m.result->>'win_type' = 'tie'                then 1
                when m.result->>'win_type' = 'no_result'          then 1
                else 0
              end)::int as points,
          sum(coalesce(public._innings_runs (m.result, v_team, true),  0))::int as runs_scored,
          sum(coalesce(public._innings_overs(m.result, v_team, true),  0))      as overs_faced,
          sum(coalesce(public._innings_runs (m.result, v_team, false), 0))::int as runs_conceded,
          sum(coalesce(public._innings_overs(m.result, v_team, false), 0))      as overs_bowled
        from public.matches m
        where m.tournament_id = p_tournament_id
          and m.status = 'completed'
          and m.result is not null
          and (m.team_a_id = v_team or m.team_b_id = v_team)
      ) agg
     where ts.tournament_id = p_tournament_id
       and ts.team_id = v_team;
  end loop;

  -- 5. NRR.
  update public.tournament_standings ts
     set net_run_rate = case
            when ts.overs_faced = 0 or ts.overs_bowled = 0 then 0
            else round(
              ((ts.runs_scored::numeric / ts.overs_faced)
                - (ts.runs_conceded::numeric / ts.overs_bowled))::numeric,
              3
            )
          end
   where ts.tournament_id = p_tournament_id;
end;
$$;

revoke all on function public.recalculate_standings(uuid) from public;
grant execute on function public.recalculate_standings(uuid) to authenticated;

-- =============================================================================
-- submit_match_result — finalise a match with its scorecard payload
-- =============================================================================
-- WHEN IT IS CALLED
-- -----------------
--   * From the LiveScoringScreen's "End match" action, after the last
--     ball of the last innings is recorded.
--   * From a future post-match scorecard import flow for matches that
--     are scored offline.
--
-- AUTHORISATION
-- -------------
-- Routes through _can_score_match (0407). Tournament organisers,
-- per-match scorers, and the friendly/practice creator are accepted.
-- The previous shape inlined `auth.uid() = any(assigned_scorers)` here;
-- now match_officials owns that set and _can_score_match is the single
-- predicate.
--
-- INPUTS
-- ------
-- p_match_id  The match.
-- p_result    The result jsonb (§4.10) — winner_team_id, win_type,
--             win_margin, summary, plus a per-innings array used by the
--             post-match trigger's standings recompute.
--
-- WHAT IT DOES
-- ------------
--   1. Auth + signed-in checks.
--   2. Lock matches row and read team identities + current status.
--   3. Reject if the match is already finalised (re-finalising would
--      corrupt the after-complete trigger's idempotence).
--   4. Validate winner_team_id (must be one of the two playing teams,
--      or NULL for a tie / no-result).
--   5. UPDATE matches SET status='completed', result=p_result, end_time
--      → fires _after_match_complete which:
--        - inserts a match_result_history audit row,
--        - calls recalculate_standings for the tournament,
--        - propagates winners into downstream knockout matches via
--          prev_match_a_id / prev_match_b_id linkage.
--
-- WHAT IT DOES NOT DO
-- -------------------
-- It does not touch balls / match_innings_state / match_players.
-- Per-innings totals are sourced from the p_result payload, not
-- recomputed. The ledger is the truth, and the client builds the result
-- jsonb from it before calling this.
-- =============================================================================
create or replace function public.submit_match_result(
  p_match_id uuid,
  p_result   jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_tournament_id uuid;
  v_team_a        uuid;
  v_team_b        uuid;
  v_status        public.match_status;
  v_winner        uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Authorization via the shared scoring predicate (tournament organiser,
  -- per-match scorer in match_officials, or friendly/practice creator).
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organizers or assigned scorers can submit results'
      using errcode = '42501';
  end if;

  select tournament_id, team_a_id, team_b_id, status
    into v_tournament_id, v_team_a, v_team_b, v_status
    from public.matches
   where match_id = p_match_id
   for update;

  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;

  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'Match has already been finalized (status %)', v_status
      using errcode = '23000';
  end if;

  -- Winner sanity check — must be one of the playing teams (or null for tie/NR).
  v_winner := nullif(p_result->>'winner_team_id', '')::uuid;
  if v_winner is not null and v_winner <> v_team_a and v_winner <> v_team_b then
    raise exception 'winner_team_id is not one of the match teams'
      using errcode = '23514';
  end if;

  update public.matches
     set result            = p_result,
         status            = 'completed',
         end_time          = coalesce(end_time, now()),
         actual_start_time = coalesce(actual_start_time, scheduled_start_time, now())
   where match_id = p_match_id;
end;
$$;

revoke all on function public.submit_match_result(uuid, jsonb) from public;
grant execute on function public.submit_match_result(uuid, jsonb) to authenticated;

-- =============================================================================
-- match_result_history — append-only audit trail of every result write.
--
-- submit_match_result lets a scorer correct an already-completed result
-- without any record of what changed. For dispute resolution + spec §4.10
-- ("results are immutable to spectators, mutable to scorers") we need to
-- know who rewrote what and when. The trigger below appends one row per
-- meaningful change.
-- =============================================================================
create table public.match_result_history (
  history_id    uuid primary key default gen_random_uuid(),
  match_id      uuid not null references public.matches(match_id) on delete cascade,
  -- Null when an event source (cron, trigger, anonymised user) overwrote
  -- the result. UI renders "(system)" or "(deleted user)" in that case.
  changed_by    uuid references public.profiles(user_id) on delete set null,
  changed_at    timestamptz not null default now(),
  -- 'submit' = first result write (status flipped to completed).
  -- 'rewrite' = correction made after the row was already completed.
  change_kind   text not null check (change_kind in ('submit', 'rewrite')),
  prior_result  jsonb,
  new_result    jsonb not null
);

create index match_result_history_match
  on public.match_result_history (match_id, changed_at desc);

alter table public.match_result_history enable row level security;

-- Read mirrors matches: public. The trigger writes are SECURITY DEFINER and
-- bypass RLS — clients have no direct write path.
create policy "match_result_history_read_public"
  on public.match_result_history for select
  using (true);

create policy "match_result_history_no_direct_write"
  on public.match_result_history for insert
  to authenticated
  with check (false);

-- =============================================================================
-- _after_match_complete — AFTER-UPDATE trigger.
-- Fires on transitions into 'completed' or when the result is rewritten
-- while already completed (correction). Idempotent (recalculate_standings
-- and the bracket-advance UPDATEs all tolerate re-runs).
-- =============================================================================
create or replace function public._after_match_complete()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_winner uuid;
  v_kind   text;
begin
  if (new.status = 'completed' and (old.status is distinct from 'completed'
                                    or new.result is distinct from old.result)) then

    -- Audit trail. 'submit' on the first transition into completed;
    -- 'rewrite' on every subsequent change to the result jsonb.
    v_kind := case
      when old.status is distinct from 'completed' then 'submit'
      else 'rewrite'
    end;
    insert into public.match_result_history (
      match_id, changed_by, change_kind, prior_result, new_result
    ) values (
      new.match_id,
      auth.uid(),
      v_kind,
      case when v_kind = 'rewrite' then old.result end,
      new.result
    );

    -- Standings (round-robin / league only — knockout has no standings).
    if new.tournament_id is not null then
      perform public.recalculate_standings(new.tournament_id);
    end if;

    -- Knockout advance: fill team_a_id / team_b_id of any later match that
    -- points back at this one via prev_match_a_id / prev_match_b_id.
    v_winner := nullif(new.result->>'winner_team_id', '')::uuid;
    if v_winner is not null then
      update public.matches
         set team_a_id = v_winner
       where prev_match_a_id = new.match_id and team_a_id is null;
      update public.matches
         set team_b_id = v_winner
       where prev_match_b_id = new.match_id and team_b_id is null;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists matches_after_complete on public.matches;
create trigger matches_after_complete
  after update on public.matches
  for each row execute function public._after_match_complete();
