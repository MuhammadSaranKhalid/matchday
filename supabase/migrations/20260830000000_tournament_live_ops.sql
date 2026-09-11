-- =============================================================================
-- 20260830000000 · tournament_live_ops
-- =============================================================================
-- Backs section F of the Tournaments design canvas (artboards 27, 27b–g, 28):
-- the organiser's Live Ops console and the three ground-ops sheets.
--
-- Also repairs two phantom references that 20260825000000 shipped against:
--
--   1. `matches.winner_id` — read by recalculate_tournament_standings() and
--      trg_advance_tournament_bracket(), but never defined by any migration.
--      Both are plpgsql, so the missing column fails at RUNTIME, not at
--      create time: standings never recompute and knockout brackets never
--      advance. The winner has always lived at result->>'winner_team_id'
--      (written by the record-ball edge function). This migration promotes it
--      to a real column kept in sync by trigger, so `result` stays the single
--      source of truth and no cricket arithmetic moves into SQL.
--
--   2. `match_officials` — referenced by list_my_matches() (20260816120000)
--      and by the 0300 tournaments comment, but never created. Created here
--      idempotently; it is where per-match scorer assignment lives, which is
--      what artboard 27's "No scorer assigned / Assign" row writes to.
--
-- Ops semantics come from the canvas, not from invention:
--   • Abandon → reschedule  discards the scorecard, fixture returns upcoming.
--   • Abandon → no result   points split 1–1, counts as played, NRR untouched.
--   • Walkover              winner takes 2 points; no runs or overs recorded,
--                           so neither side's NRR moves.
--   • Override              audited into match_result_history with a reason.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. match_officials — MOVED
-- -----------------------------------------------------------------------------
-- The table, its index and its RLS now live in 20260101000410_match_officials.sql
-- (split out 2026-09-06). It had to move: list_my_matches (20260816120000)
-- joins it and is `language sql`, so it is body-checked at CREATE time and a
-- clean db reset failed here. This migration keeps only the ops RPCs below,
-- which write the table.

-- -----------------------------------------------------------------------------
-- 2. matches.winner_id — promoted from result->>'winner_team_id'.
-- -----------------------------------------------------------------------------
-- matches.winner_id and its index are declared inline in
-- 20260101000400_matches.sql (folded there 2026-09-06). This migration owns
-- the trigger below that keeps it in step with `result`.

-- `result` remains authoritative: the trigger derives winner_id from it on
-- every write. Ops RPCs below therefore set `result` and let the trigger
-- follow, rather than setting winner_id by hand in two places.
create or replace function public.trg_sync_match_winner_id()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.winner_id := nullif(new.result->>'winner_team_id', '')::uuid;
  return new;
end;
$$;

drop trigger if exists match_sync_winner_id on public.matches;
create trigger match_sync_winner_id
  before insert or update of result on public.matches
  for each row execute function public.trg_sync_match_winner_id();

-- Backfill every match already carrying a computed result.
update public.matches
   set winner_id = nullif(result->>'winner_team_id', '')::uuid
 where winner_id is null
   and result ? 'winner_team_id';

-- -----------------------------------------------------------------------------
-- 3. Standings — count walkovers.
-- -----------------------------------------------------------------------------
-- Replaces the 20260825000000 body. Only the aggregate filters change: a
-- walkover is a played match and a win worth 2 points, but contributes no
-- innings rows, so the NRR aggregates (still `status = 'completed'` only)
-- are untouched by construction — matching the canvas ruling that "a
-- walkover cannot help or hurt run rate".
create or replace function public.recalculate_tournament_standings(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament record;
  v_team record;
  v_matches_played int;
  v_wins int;
  v_losses int;
  v_ties int;
  v_no_results int;
  v_points int;
  v_runs_scored int;
  v_overs_faced numeric(6, 2);
  v_runs_conceded int;
  v_overs_bowled numeric(6, 2);
  v_nrr numeric(6, 3);
  v_bat_rr numeric;
  v_bowl_rr numeric;
  v_max_overs numeric;
begin
  select * into v_tournament
    from public.tournaments
   where tournament_id = p_tournament_id;

  if not found then
    return;
  end if;

  v_max_overs := coalesce((v_tournament.format->>'max_overs')::numeric, 20.0);

  for v_team in
    select team_id, group_id
      from public.tournament_teams
     where tournament_id = p_tournament_id
       and status = 'approved'
  loop
    v_matches_played := 0;
    v_wins := 0;
    v_losses := 0;
    v_ties := 0;
    v_no_results := 0;
    v_points := 0;
    v_runs_scored := 0;
    v_overs_faced := 0;
    v_runs_conceded := 0;
    v_overs_bowled := 0;
    v_nrr := 0.0;

    select
      count(*) filter (
        where m.status in ('completed', 'tied', 'no_result', 'abandoned', 'walkover')
      ),
      count(*) filter (
        where m.status in ('completed', 'walkover') and m.winner_id = v_team.team_id
      ),
      count(*) filter (
        where m.status in ('completed', 'walkover')
          and m.winner_id is not null
          and m.winner_id <> v_team.team_id
      ),
      count(*) filter (where m.status = 'tied'),
      count(*) filter (where m.status in ('no_result', 'abandoned'))
    into
      v_matches_played,
      v_wins,
      v_losses,
      v_ties,
      v_no_results
    from public.matches m
    where m.tournament_id = p_tournament_id
      and (m.team_a_id = v_team.team_id or m.team_b_id = v_team.team_id);

    -- Standard cricket points: Win = 2, Tie/NR = 1, Loss = 0
    v_points := (v_wins * 2) + (v_ties * 1) + (v_no_results * 1);

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          when mis.total_wickets >= 10 then v_max_overs
          else (floor(mis.legal_ball_count / 6) + (mis.legal_ball_count % 6) / 10.0)
        end
      ), 0)
    into v_runs_scored, v_overs_faced
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      -- match_innings stores 'team_a' / 'team_b', not a team id.
      and case mi.batting_team_side
            when 'team_a' then m.team_a_id else m.team_b_id
          end = v_team.team_id;

    select
      coalesce(sum(mis.total_runs), 0),
      coalesce(sum(
        case
          when mis.total_wickets >= 10 then v_max_overs
          else (floor(mis.legal_ball_count / 6) + (mis.legal_ball_count % 6) / 10.0)
        end
      ), 0)
    into v_runs_conceded, v_overs_bowled
    from public.matches m
    join public.match_innings mi on mi.match_id = m.match_id
    join public.match_innings_state mis on mis.innings_id = mi.innings_id
    where m.tournament_id = p_tournament_id
      and m.status = 'completed'
      and case mi.bowling_team_side
            when 'team_a' then m.team_a_id else m.team_b_id
          end = v_team.team_id;

    v_bat_rr := case
      when v_overs_faced > 0 then
        v_runs_scored / (floor(v_overs_faced) + ((v_overs_faced - floor(v_overs_faced)) * 10 / 6.0))
      else 0.0
    end;

    v_bowl_rr := case
      when v_overs_bowled > 0 then
        v_runs_conceded / (floor(v_overs_bowled) + ((v_overs_bowled - floor(v_overs_bowled)) * 10 / 6.0))
      else 0.0
    end;

    v_nrr := round((v_bat_rr - v_bowl_rr)::numeric, 3);

    insert into public.tournament_standings (
      tournament_id, team_id, group_id, matches_played, wins, losses, ties,
      no_results, points, runs_scored, overs_faced, runs_conceded,
      overs_bowled, net_run_rate, updated_at
    ) values (
      p_tournament_id, v_team.team_id, v_team.group_id, v_matches_played,
      v_wins, v_losses, v_ties, v_no_results, v_points, v_runs_scored,
      v_overs_faced, v_runs_conceded, v_overs_bowled, v_nrr, now()
    )
    on conflict (tournament_id, team_id) do update set
      group_id = excluded.group_id,
      matches_played = excluded.matches_played,
      wins = excluded.wins,
      losses = excluded.losses,
      ties = excluded.ties,
      no_results = excluded.no_results,
      points = excluded.points,
      runs_scored = excluded.runs_scored,
      overs_faced = excluded.overs_faced,
      runs_conceded = excluded.runs_conceded,
      overs_bowled = excluded.overs_bowled,
      net_run_rate = excluded.net_run_rate,
      updated_at = now();
  end loop;
end;
$$;

revoke all on function public.recalculate_tournament_standings(uuid) from public;
grant execute on function public.recalculate_tournament_standings(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Bracket advancement — walkovers advance too, and any terminal status
--    recomputes the table.
-- -----------------------------------------------------------------------------
create or replace function public.trg_advance_tournament_bracket()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.tournament_id is null then
    return new;
  end if;

  -- Advance the winner into whichever downstream slot feeds off this match.
  -- A walkover is as final as a scored win, so it advances the bracket.
  if new.status in ('completed', 'walkover')
     and new.winner_id is not null
     and (old.status is distinct from new.status
          or old.winner_id is distinct from new.winner_id) then

    update public.matches
       set team_a_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_a_id = new.match_id
       and team_a_id is null;

    update public.matches
       set team_b_id = new.winner_id
     where tournament_id = new.tournament_id
       and prev_match_b_id = new.match_id
       and team_b_id is null;
  end if;

  -- Any move into or out of a terminal status changes the table, including
  -- an abandon that sends a played fixture back to `scheduled`.
  if old.status is distinct from new.status
     or old.winner_id is distinct from new.winner_id then
    perform public.recalculate_tournament_standings(new.tournament_id);
  end if;

  return new;
end;
$$;

drop trigger if exists match_advance_tournament_bracket on public.matches;

create trigger match_advance_tournament_bracket
  after update on public.matches
  for each row execute function public.trg_advance_tournament_bracket();

-- -----------------------------------------------------------------------------
-- 5. Shared guard — organiser of the tournament this match belongs to.
-- -----------------------------------------------------------------------------
create or replace function public._require_match_organizer(p_match_id uuid)
returns public.matches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select * into v_match from public.matches where match_id = p_match_id;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_match.tournament_id is null then
    raise exception 'Match is not part of a tournament' using errcode = '22023';
  end if;

  if not public.is_tournament_organizer(v_match.tournament_id) then
    raise exception 'Only tournament organizers can run live ops'
      using errcode = '42501';
  end if;

  return v_match;
end;
$$;

revoke all on function public._require_match_organizer(uuid) from public;
grant execute on function public._require_match_organizer(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Assign a scorer to a fixture (artboard 27 "No scorer assigned · Assign").
-- -----------------------------------------------------------------------------
create or replace function public.tournament_assign_scorer(
  p_match_id uuid,
  p_user_id  uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if v_match.status in ('completed', 'abandoned', 'walkover', 'no_result') then
    raise exception 'Cannot reassign a scorer on a finished match'
      using errcode = '22023';
  end if;

  -- One scorer per match: replace rather than accumulate.
  delete from public.match_officials
   where match_id = p_match_id and role = 'scorer';

  insert into public.match_officials (match_id, user_id, role, assigned_by)
  values (p_match_id, p_user_id, 'scorer', auth.uid());

  insert into public.notifications (recipient_id, type, payload)
  values (
    p_user_id,
    'match_starting',
    jsonb_build_object(
      'match_id', p_match_id,
      'tournament_id', v_match.tournament_id,
      'route', '/matches/' || p_match_id::text,
      'reason', 'scorer_assigned'
    )
  );
end;
$$;

revoke all on function public.tournament_assign_scorer(uuid, uuid) from public;
grant execute on function public.tournament_assign_scorer(uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Reschedule a fixture (artboard 27c "Change ground or time").
-- -----------------------------------------------------------------------------
create or replace function public.tournament_reschedule_match(
  p_match_id uuid,
  p_start    timestamptz,
  p_venue    text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if v_match.status in ('completed', 'walkover') then
    raise exception 'Cannot reschedule a finished match' using errcode = '22023';
  end if;

  update public.matches
     set scheduled_start_time = p_start,
         venue = coalesce(nullif(p_venue, ''), venue),
         updated_at = now()
   where match_id = p_match_id;
end;
$$;

revoke all on function public.tournament_reschedule_match(uuid, timestamptz, text) from public;
grant execute on function public.tournament_reschedule_match(uuid, timestamptz, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Abandon a match (artboard 28, sheet 1).
-- -----------------------------------------------------------------------------
-- p_mode = 'reschedule' → scorecard discarded, fixture returns as upcoming.
-- p_mode = 'no_result'  → points split 1–1, counts as played, NRR unaffected.
create or replace function public.tournament_abandon_match(
  p_match_id       uuid,
  p_mode           text,
  p_reschedule_to  timestamptz default null,
  p_reason         text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if p_mode not in ('reschedule', 'no_result') then
    raise exception 'Unknown abandon mode: %', p_mode using errcode = '22023';
  end if;

  if p_mode = 'reschedule' and p_reschedule_to is null then
    raise exception 'A new date is required to reschedule' using errcode = '22023';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id,
    v_match.status,
    case when p_mode = 'reschedule' then 'scheduled'::public.match_status
         else 'no_result'::public.match_status end,
    coalesce(v_match.result, '{}'::jsonb) || jsonb_build_object('abandon_mode', p_mode),
    p_reason,
    auth.uid()
  );

  if p_mode = 'reschedule' then
    -- Discard the scorecard. Children of match_innings (innings state, balls,
    -- partnerships) cascade, so the fixture comes back genuinely clean.
    delete from public.match_innings where match_id = p_match_id;

    update public.matches
       set status = 'scheduled',
           start_phase = 'toss',
           result = null,
           result_summary = null,
           scheduled_start_time = p_reschedule_to,
           actual_start_time = null,
           completed_at = null,
           toss_won_by = null,
           toss_decision = null,
           toss_face = null,
           toss_recorded_at = null,
           openers_submitted_by = null,
           openers_submitted_at = null,
           updated_at = now()
     where match_id = p_match_id;
  else
    update public.matches
       set status = 'no_result',
           result = jsonb_build_object(
             'winner_team_id', null,
             'win_type', 'no_result',
             'description', coalesce(nullif(p_reason, ''), 'Match abandoned — no result')
           ),
           -- Was `end_time = now()` while completed_at stayed null — the one
           -- place the two finish-time columns actually disagreed. An abandoned
           -- match IS finished, so it gets the finish timestamp.
           completed_at = now(),
           updated_at = now()
     where match_id = p_match_id;
  end if;

  perform public.recalculate_tournament_standings(v_match.tournament_id);
end;
$$;

revoke all on function public.tournament_abandon_match(uuid, text, timestamptz, text) from public;
grant execute on function public.tournament_abandon_match(uuid, text, timestamptz, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. Declare a walkover (artboard 28, sheet 2).
-- -----------------------------------------------------------------------------
create or replace function public.tournament_declare_walkover(
  p_match_id       uuid,
  p_winner_team_id uuid,
  p_reason         text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  -- `is distinct from` rather than `not in`: an unfilled bracket slot is
  -- NULL, and `x not in (a, NULL)` is NULL, which would pass the guard.
  if p_winner_team_id is null
     or (p_winner_team_id is distinct from v_match.team_a_id
         and p_winner_team_id is distinct from v_match.team_b_id) then
    raise exception 'Winner must be one of the two teams in this fixture'
      using errcode = '22023';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id, v_match.status, 'walkover',
    jsonb_build_object('winner_team_id', p_winner_team_id),
    p_reason, auth.uid()
  );

  -- No runs and no overs are recorded, so NRR is untouched by construction:
  -- the standings NRR aggregates only read `completed` matches.
  update public.matches
     set status = 'walkover',
         result = jsonb_build_object(
           'winner_team_id', p_winner_team_id,
           'win_type', 'walkover',
           'win_margin', null,
           'description', 'Won by walkover',
           'summary', 'Won by walkover'
         ),
         completed_at = now(),
         updated_at = now()
   where match_id = p_match_id;

  perform public.recalculate_tournament_standings(v_match.tournament_id);
end;
$$;

revoke all on function public.tournament_declare_walkover(uuid, uuid, text) from public;
grant execute on function public.tournament_declare_walkover(uuid, uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 10. Override a recorded result (artboard 28, sheet 3). Always audited.
-- -----------------------------------------------------------------------------
create or replace function public.tournament_override_result(
  p_match_id       uuid,
  p_winner_team_id uuid,
  p_reason         text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if p_reason is null or length(btrim(p_reason)) < 10 then
    raise exception 'An override requires a reason of at least 10 characters'
      using errcode = '22023';
  end if;

  if p_winner_team_id is null
     or (p_winner_team_id is distinct from v_match.team_a_id
         and p_winner_team_id is distinct from v_match.team_b_id) then
    raise exception 'Winner must be one of the two teams in this fixture'
      using errcode = '22023';
  end if;

  insert into public.match_result_history (
    match_id, previous_status, new_status, result_payload, reason, recorded_by
  ) values (
    p_match_id, v_match.status, 'completed',
    coalesce(v_match.result, '{}'::jsonb)
      || jsonb_build_object('overridden_to', p_winner_team_id),
    p_reason, auth.uid()
  );

  -- The scorecard itself is left intact; only the recorded outcome moves.
  update public.matches
     set status = 'completed',
         result = coalesce(result, '{}'::jsonb) || jsonb_build_object(
           'winner_team_id', p_winner_team_id,
           'overridden', true,
           'override_reason', p_reason,
           'overridden_by', auth.uid(),
           'overridden_at', now()
         ),
         updated_at = now()
   where match_id = p_match_id;

  perform public.recalculate_tournament_standings(v_match.tournament_id);
end;
$$;

revoke all on function public.tournament_override_result(uuid, uuid, text) from public;
grant execute on function public.tournament_override_result(uuid, uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 11. Co-organisers (artboard 27f).
-- -----------------------------------------------------------------------------
-- Only the creator may change the co-organiser set — a co-organiser cannot
-- add further co-organisers, per the canvas note.
create or replace function public.tournament_set_coorganizer(
  p_tournament_id uuid,
  p_user_id       uuid,
  p_add           boolean
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_created_by uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select created_by into v_created_by
    from public.tournaments where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  if v_created_by is distinct from auth.uid() then
    raise exception 'Only the tournament creator can manage co-organisers'
      using errcode = '42501';
  end if;

  if p_user_id = v_created_by then
    raise exception 'The creator is already an organiser' using errcode = '22023';
  end if;

  if p_add then
    update public.tournaments
       set organizers = (
             select array(select distinct unnest(organizers || p_user_id))
           ),
           updated_at = now()
     where tournament_id = p_tournament_id;

    insert into public.notifications (recipient_id, type, payload)
    values (
      p_user_id, 'tournament_post',
      jsonb_build_object(
        'tournament_id', p_tournament_id,
        'route', '/tournaments/' || p_tournament_id::text || '/console',
        'reason', 'coorganizer_added'
      )
    );
  else
    update public.tournaments
       set organizers = array_remove(organizers, p_user_id),
           updated_at = now()
     where tournament_id = p_tournament_id;
  end if;
end;
$$;

revoke all on function public.tournament_set_coorganizer(uuid, uuid, boolean) from public;
grant execute on function public.tournament_set_coorganizer(uuid, uuid, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- 12. Broadcast an announcement (artboard 27e).
-- -----------------------------------------------------------------------------
-- Fans out to team managers of approved teams, their squad players, and
-- anyone following the tournament. Returns the recipient count so the sheet
-- can render "Send to N people" honestly.
create or replace function public.tournament_announce(
  p_tournament_id uuid,
  p_message       text
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can send announcements'
      using errcode = '42501';
  end if;

  if p_message is null or length(btrim(p_message)) = 0 then
    raise exception 'Announcement cannot be empty' using errcode = '22023';
  end if;

  if length(p_message) > 300 then
    raise exception 'Announcement is limited to 300 characters'
      using errcode = '22023';
  end if;

  with recipients as (
    -- Managers and owners of approved teams. 2026-09-10: was two UNIONed
    -- branches (teams.owner_id, then unnest(teams.managers)); team_staff_ids()
    -- returns both from the role ladder.
    select public.team_staff_ids(tt.team_id) as user_id
      from public.tournament_teams tt
     where tt.tournament_id = p_tournament_id
       and tt.status = 'approved'
    union
    -- Squad players locked into an approved registration.
    select unnest(tt.squad)
      from public.tournament_teams tt
     where tt.tournament_id = p_tournament_id
       and tt.status = 'approved'
    union
    -- Followers of the tournament.
    select f.follower_id
      from public.follows f
     where f.target_type = 'tournament'
       and f.target_id = p_tournament_id
  ),
  deduped as (
    select distinct r.user_id
      from recipients r
      join public.profiles p on p.user_id = r.user_id
     where r.user_id is not null
  ),
  inserted as (
    insert into public.notifications (recipient_id, type, payload)
    select
      d.user_id,
      'tournament_post',
      jsonb_build_object(
        'tournament_id', p_tournament_id,
        'route', '/tournaments/' || p_tournament_id::text,
        'reason', 'announcement',
        'message', p_message
      )
    from deduped d
    returning 1
  )
  select count(*) into v_count from inserted;

  return coalesce(v_count, 0);
end;
$$;

revoke all on function public.tournament_announce(uuid, text) from public;
grant execute on function public.tournament_announce(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 13. Cancel a tournament (artboard 27g) — the one genuinely destructive act.
-- -----------------------------------------------------------------------------
-- Completed scorecards are KEPT and stay visible; only unplayed fixtures are
-- voided. Creator-only, and the reason is stored on the tournament because
-- the cancelled console renders it back to everyone.
create or replace function public.tournament_cancel(
  p_tournament_id uuid,
  p_reason        text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_created_by uuid;
  v_name text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select created_by, tournament_name into v_created_by, v_name
    from public.tournaments where tournament_id = p_tournament_id;

  if not found then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  if v_created_by is distinct from auth.uid() then
    raise exception 'Only the tournament creator can cancel it'
      using errcode = '42501';
  end if;

  if p_reason is null or length(btrim(p_reason)) < 10 then
    raise exception 'Cancelling requires a reason of at least 10 characters'
      using errcode = '22023';
  end if;

  -- Void what was never played. Completed scorecards are deliberately left
  -- alone so they keep counting towards player stats.
  update public.matches
     set status = 'no_result',
         updated_at = now()
   where tournament_id = p_tournament_id
     and status in ('scheduled', 'toss', 'live', 'innings_break', 'super_over');

  update public.tournaments
     set status = 'cancelled',
         rules = coalesce(rules, '{}'::jsonb) || jsonb_build_object(
           'cancelled_reason', p_reason,
           'cancelled_at', now(),
           'cancelled_by', auth.uid()
         ),
         updated_at = now()
   where tournament_id = p_tournament_id;

  -- Everyone hears about it immediately.
  perform public.tournament_announce(
    p_tournament_id,
    left('Cancelled: ' || p_reason, 300)
  );
end;
$$;

revoke all on function public.tournament_cancel(uuid, text) from public;
grant execute on function public.tournament_cancel(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 14. Live Ops board feed (artboard 27).
-- -----------------------------------------------------------------------------
-- One row per fixture on the console's Live Ops tab, with the scorer already
-- resolved so the client does not fan out N profile reads per ground.
create or replace function public.tournament_live_board(p_tournament_id uuid)
returns table (
  match_id             uuid,
  venue                text,
  status               text,
  scheduled_start_time timestamptz,
  round                text,
  team_a_id            uuid,
  team_a_name          text,
  team_b_id            uuid,
  team_b_name          text,
  winner_id            uuid,
  result               jsonb,
  scorer_id            uuid,
  scorer_name          text,
  last_ball_at         timestamptz,
  innings_lines        jsonb
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    m.match_id,
    m.venue,
    m.status::text,
    m.scheduled_start_time,
    m.round,
    m.team_a_id,
    ta.team_name,
    m.team_b_id,
    tb.team_name,
    m.winner_id,
    m.result,
    mo.user_id,
    pr.display_name,
    -- "Last ball 40s ago" on the ground card. match_deliveries carries
    -- match_id directly, and an undone ball must not count as activity.
    (select max(d.recorded_at)
       from public.match_deliveries d
      where d.match_id = m.match_id
        and d.is_undone = false),
    coalesce(
      (select jsonb_agg(
                jsonb_build_object(
                  'innings_number', mi.innings_number,
                  -- Resolve the recorded side back to a team id so the client
                  -- can line each innings up with the right name.
                  'batting_team_id',
                    case mi.batting_team_side
                      when 'team_a' then m.team_a_id else m.team_b_id
                    end,
                  'total_runs', mis.total_runs,
                  'total_wickets', mis.total_wickets,
                  'legal_ball_count', mis.legal_ball_count
                ) order by mi.innings_number)
         from public.match_innings mi
         join public.match_innings_state mis on mis.innings_id = mi.innings_id
        where mi.match_id = m.match_id),
      '[]'::jsonb
    )
  from public.matches m
  left join public.teams ta on ta.team_id = m.team_a_id
  left join public.teams tb on tb.team_id = m.team_b_id
  left join public.match_officials mo
         on mo.match_id = m.match_id and mo.role = 'scorer'
  left join public.profiles pr on pr.user_id = mo.user_id
  where m.tournament_id = p_tournament_id
    -- SECURITY DEFINER bypasses the tournaments RLS, so re-state its
    -- visibility rule here: a private or draft cup is organiser-only, and a
    -- manager of a registered team can see the cup they entered.
    and exists (
      select 1 from public.tournaments t
       where t.tournament_id = p_tournament_id
         and (
           (t.privacy = 'public' and t.status <> 'draft')
           or public.is_tournament_organizer(p_tournament_id)
           or exists (
             select 1
               from public.tournament_teams tt
              where tt.tournament_id = p_tournament_id
                and (public.is_team_manager(tt.team_id)
                     or auth.uid() = any(tt.squad))
           )
         )
    )
  order by m.scheduled_start_time asc;
$$;

revoke all on function public.tournament_live_board(uuid) from public;
grant execute on function public.tournament_live_board(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 15. Who can be appointed to score (artboard 27 "Assign").
-- -----------------------------------------------------------------------------
-- Organisers plus the owners and managers of approved teams — the people who
-- are actually at the ground. Returned with names so the picker is one call.
create or replace function public.tournament_scorer_candidates(
  p_tournament_id uuid
)
returns table (
  user_id      uuid,
  display_name text,
  username     text,
  role_label   text
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with people as (
    select t.created_by as uid, 'Organiser'::text as role_label
      from public.tournaments t
     where t.tournament_id = p_tournament_id
       and t.created_by is not null
    union
    select unnest(t.organizers), 'Co-organiser'::text
      from public.tournaments t
     where t.tournament_id = p_tournament_id
    union
    -- 2026-09-10: was owner_id UNION unnest(managers) against teams; both come
    -- from the role ladder now. team_staff_ids is role >= 'manager', so this
    -- returns exactly the same people as before — captains are deliberately
    -- NOT offered here. They can already score their own side without an
    -- appointment (_can_score_innings), so listing them in an organiser's
    -- assign-a-scorer picker would only invite a redundant row.
    select public.team_staff_ids(tt.team_id), 'Team manager'::text
      from public.tournament_teams tt
     where tt.tournament_id = p_tournament_id
       and tt.status = 'approved'
  ),
  ranked as (
    -- An organiser who also manages a team should read as an organiser.
    select
      p.uid,
      min(case p.role_label
            when 'Organiser' then 1
            when 'Co-organiser' then 2
            else 3
          end) as rank
    from people p
    where p.uid is not null
    group by p.uid
  )
  select
    pr.user_id,
    pr.display_name,
    pr.username,
    case r.rank when 1 then 'Organiser'
                when 2 then 'Co-organiser'
                else 'Team manager' end
  from ranked r
  join public.profiles pr on pr.user_id = r.uid
  where public.is_tournament_organizer(p_tournament_id)
  order by r.rank, pr.display_name;
$$;

revoke all on function public.tournament_scorer_candidates(uuid) from public;
grant execute on function public.tournament_scorer_candidates(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- tournament_ground_clashes() — moved here 2026-09-06
-- -----------------------------------------------------------------------------
-- Declared in grounds until that file was renumbered to 20260101000330 to run
-- before matches. This function joins public.matches twice, so it must live in
-- a migration that runs after the matches schema — here, with the other
-- tournament ops RPCs.
-- 7. Fixture clashes on a ground (the soft check, per decision 3).
-- Returns pairs of fixtures sharing a ground whose scheduled starts fall
-- within p_window of each other. The console shows these; nothing blocks the
-- write, so a rain reshuffle can pass through a colliding intermediate state.
create or replace function public.tournament_ground_clashes(
  p_tournament_id uuid,
  p_window        interval default interval '3 hours'
)
returns table (
  ground_id     uuid,
  ground_name   text,
  match_a_id    uuid,
  match_a_start timestamptz,
  match_b_id    uuid,
  match_b_start timestamptz,
  gap           interval
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    g.ground_id,
    g.name,
    a.match_id,
    a.scheduled_start_time,
    b.match_id,
    b.scheduled_start_time,
    b.scheduled_start_time - a.scheduled_start_time
  from public.matches a
  join public.matches b
    on b.tournament_id = a.tournament_id
   and b.ground_id = a.ground_id
   -- Ordered pair, so each clash is reported once rather than twice.
   and (a.scheduled_start_time, a.match_id) < (b.scheduled_start_time, b.match_id)
  join public.grounds g on g.ground_id = a.ground_id
  where a.tournament_id = p_tournament_id
    and a.ground_id is not null
    and a.status not in ('completed', 'abandoned', 'no_result', 'walkover')
    and b.status not in ('completed', 'abandoned', 'no_result', 'walkover')
    and b.scheduled_start_time - a.scheduled_start_time < p_window
    and public.is_tournament_organizer(p_tournament_id)
  order by g.name, a.scheduled_start_time;
$$;

revoke all on function public.tournament_ground_clashes(uuid, interval) from public;
grant execute on function public.tournament_ground_clashes(uuid, interval) to authenticated;
