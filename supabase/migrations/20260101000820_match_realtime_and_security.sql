-- =============================================================================
-- 0820 · Match Realtime Broadcast, Publication & Security Lockdown
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Realtime Publication (CDC)
-- -----------------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.matches;
exception when others then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_innings_state;
exception when others then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_deliveries;
exception when others then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_wickets;
exception when others then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_batsman_stats;
exception when others then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.match_bowler_stats;
exception when others then null;
end $$;


-- -----------------------------------------------------------------------------
-- 2. Broadcast Trigger Functions (realtime.send for private channels)
-- -----------------------------------------------------------------------------

-- Broadcast match_state_updated on matches UPDATE
create or replace function public.broadcast_match_state_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- to_jsonb(NEW), NOT json_build_object('payload', ...). realtime.send already
  -- delivers the message as {event, payload, type}; the client unwraps exactly
  -- that one level. An extra wrapper made every frame parse as {payload:{...}}
  -- and throw — silently degrading match/innings to the snapshot poll and
  -- hard-erroring the balls stream, which has no snapshot fallback.
  perform realtime.send(
    to_jsonb(NEW),
    'match_state_updated',
    'match:' || NEW.match_id::text || ':state',
    true
  );
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_match_state_updated() from public;
grant execute on function public.broadcast_match_state_updated() to authenticated, service_role;

drop trigger if exists trg_broadcast_match_state on public.matches;
create trigger trg_broadcast_match_state
  after update on public.matches
  for each row
  execute function public.broadcast_match_state_updated();


-- Broadcast innings_state_updated on match_innings_state INSERT or UPDATE
create or replace function public.broadcast_innings_state_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- to_jsonb(NEW), NOT json_build_object('payload', ...). realtime.send already
  -- delivers the message as {event, payload, type}; the client unwraps exactly
  -- that one level. An extra wrapper made every frame parse as {payload:{...}}
  -- and throw — silently degrading match/innings to the snapshot poll and
  -- hard-erroring the balls stream, which has no snapshot fallback.
  perform realtime.send(
    to_jsonb(NEW),
    'innings_state_updated',
    'match:' || NEW.match_id::text || ':state',
    true
  );
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_innings_state_updated() from public;
grant execute on function public.broadcast_innings_state_updated() to authenticated, service_role;

drop trigger if exists trg_broadcast_innings_state on public.match_innings_state;
create trigger trg_broadcast_innings_state
  after insert or update on public.match_innings_state
  for each row
  execute function public.broadcast_innings_state_updated();


-- Broadcast ball_recorded on match_deliveries INSERT
create or replace function public.broadcast_new_delivery()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- to_jsonb(NEW), NOT json_build_object('payload', ...). realtime.send already
  -- delivers the message as {event, payload, type}; the client unwraps exactly
  -- that one level. An extra wrapper made every frame parse as {payload:{...}}
  -- and throw — silently degrading match/innings to the snapshot poll and
  -- hard-erroring the balls stream, which has no snapshot fallback.
  perform realtime.send(
    to_jsonb(NEW),
    'ball_recorded',
    'match:' || NEW.match_id::text || ':balls',
    true
  );
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_new_delivery() from public;
grant execute on function public.broadcast_new_delivery() to authenticated, service_role;

drop trigger if exists trg_broadcast_delivery on public.match_deliveries;
create trigger trg_broadcast_delivery
  after insert on public.match_deliveries
  for each row
  execute function public.broadcast_new_delivery();


-- -----------------------------------------------------------------------------
-- 3. Security Lockdown: Revoke direct client write access
-- -----------------------------------------------------------------------------
-- Direct client PostgREST writes are disabled; mutations must go through
-- authenticated Edge Functions (record-ball, start-innings, record-toss).

drop policy if exists "match_deliveries_write_scorer" on public.match_deliveries;
create policy "match_deliveries_write_scorer"
  on public.match_deliveries
  for insert
  to authenticated
  with check (false);

drop policy if exists "match_wickets_write_scorer" on public.match_wickets;
create policy "match_wickets_write_scorer"
  on public.match_wickets
  for insert
  to authenticated
  with check (false);

drop policy if exists "match_innings_state_write_scorer" on public.match_innings_state;
create policy "match_innings_state_write_scorer"
  on public.match_innings_state
  for update
  to authenticated
  using (false);

-- -----------------------------------------------------------------------------
-- 4. Canonical undo_last_ball RPC targeting match_deliveries
-- -----------------------------------------------------------------------------
create or replace function public.undo_last_ball(
  p_match_id uuid,
  p_innings_number integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_innings_id uuid;
  v_row public.match_deliveries;
  v_status public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_innings(p_match_id, p_innings_number) then
    raise exception 'Only the batting team can score this innings'
      using errcode = '42501';
  end if;

  select innings_id into v_innings_id
  from public.match_innings_state
  where match_id = p_match_id and innings_number = p_innings_number
  for update;

  if not found then
    raise exception 'Innings % has not been started for this match', p_innings_number
      using errcode = '23000';
  end if;

  -- Delete latest delivery from match_deliveries
  delete from public.match_deliveries
  where delivery_id = (
    select delivery_id from public.match_deliveries
    where match_id = p_match_id and innings_number = p_innings_number
    order by seq desc
    limit 1
  )
  returning * into v_row;

  if v_row.delivery_id is null then
    return false;
  end if;

  -- Delete corresponding wicket row if delivery was a wicket
  if v_row.is_wicket then
    delete from public.match_wickets
    where delivery_id = v_row.delivery_id;
  end if;

  -- Re-derive totals from ledger
  update public.match_innings_state s set
    total_runs       = agg.runs,
    total_wickets    = agg.wickets,
    legal_ball_count = agg.legal,
    total_wides      = agg.wides,
    total_no_balls   = agg.no_balls,
    total_byes       = agg.byes,
    total_leg_byes   = agg.leg_byes,
    total_penalties  = agg.penalties,
    striker_id       = coalesce(v_row.striker_id, v_row.batsman_id, s.striker_id),
    non_striker_id   = coalesce(v_row.non_striker_id, s.non_striker_id),
    bowler_id        = coalesce(v_row.bowler_id, s.bowler_id),
    is_all_out       = false,
    version          = s.version + 1,
    updated_at       = now()
  from (
    select
      -- Read the real columns directly. `runs_scored`, `extras` and `ball_type`
      -- are vestigial duplicates that nothing writes, and `coalesce`-ing over
      -- them was not merely pointless — all four are NOT NULL — it did not
      -- typecheck: delivery_type is the delivery_kind ENUM and ball_type is
      -- text, so COALESCE could not resolve a common type and every undo
      -- failed with "COALESCE types delivery_kind and text cannot be matched".
      -- Matches the aggregate record-ball uses, deliberately: the two must
      -- agree about what an innings totals to.
      coalesce(sum(runs_off_bat + extra_runs), 0)::int                           as runs,
      (count(*) filter (where is_wicket))::int                                   as wickets,
      (count(*) filter (where is_legal_delivery))::int                           as legal,
      coalesce(sum(extra_runs) filter (where delivery_type = 'wide'), 0)::int    as wides,
      coalesce(sum(extra_runs) filter (where delivery_type = 'no_ball'), 0)::int as no_balls,
      coalesce(sum(extra_runs) filter (where delivery_type = 'bye'), 0)::int     as byes,
      coalesce(sum(extra_runs) filter (where delivery_type = 'leg_bye'), 0)::int as leg_byes,
      coalesce(sum(extra_runs) filter (where delivery_type = 'penalty'), 0)::int as penalties
    from public.match_deliveries
    where match_id = p_match_id and innings_number = p_innings_number and is_undone = false
  ) agg
  where s.match_id = p_match_id and s.innings_number = p_innings_number;

  -- Reverse the transition that delivery caused, if it caused one.
  --
  -- record-ball flips the match to 'innings_break' or 'completed' when the
  -- device reports the innings ended. Undoing that delivery has to put the
  -- match back, or the score says the innings is live while the match row says
  -- it is over — and everyone lands on the result screen with a scorecard that
  -- no longer supports it.
  --
  -- 🟥 This is the one path that can un-declare a result. Design doc §19.4 says
  -- a result must never be RENDERED from local computation, and it is not — the
  -- server declared it. But a scorer who mis-taps the winning run has to be
  -- able to take it back, and the alternative is a permanently wrong match.
  select status into v_status from public.matches where match_id = p_match_id;

  if v_status in ('innings_break', 'completed', 'tied', 'no_result') then
    update public.matches
       set status       = 'live',
           result       = null,
           end_time     = null,
           completed_at = null,
           updated_at   = now()
     where match_id = p_match_id;
  end if;

  return true;
end;
$$;

revoke all on function public.undo_last_ball(uuid, integer) from public;
grant execute on function public.undo_last_ball(uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Broadcast a removed delivery
-- -----------------------------------------------------------------------------
-- watchBalls has listened for `ball_deleted` since it was written; nothing has
-- ever sent it. Without this, an undo corrects the score on every device (the
-- innings_state broadcast does that) while the removed delivery stays in every
-- spectator's ball log until they reopen the screen.
create or replace function public.broadcast_delivery_deleted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(OLD),
    'ball_deleted',
    'match:' || OLD.match_id::text || ':balls',
    true
  );
  return OLD;
exception
  when others then
    return OLD;
end;
$$;

revoke all on function public.broadcast_delivery_deleted() from public;
grant execute on function public.broadcast_delivery_deleted() to authenticated, service_role;

drop trigger if exists trg_broadcast_delivery_deleted on public.match_deliveries;
create trigger trg_broadcast_delivery_deleted
  after delete on public.match_deliveries
  for each row
  execute function public.broadcast_delivery_deleted();
