-- Migration file: 20260101000820_match_realtime_and_security.sql

-- 0820 · Match Realtime Broadcast, Publication & Security Lockdown
-- 1. Realtime Publication (CDC)

-- Section: Dependency-ordered operations

do $$
begin
  alter publication supabase_realtime
    add table public.matches;
exception
  when others then
    null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.cricket_match_innings_state;
exception
  when others then
    null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.cricket_match_deliveries;
exception
  when others then
    null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.cricket_match_wickets;
exception
  when others then
    null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.match_batsman_stats;
exception
  when others then
    null;
end
$$;

do $$
begin
  alter publication supabase_realtime
    add table public.match_bowler_stats;
exception
  when others then
    null;
end
$$;

-- Section: Functions

-- 2. Broadcast Trigger Functions (realtime.send for private channels)
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
  perform
    realtime.send(to_jsonb(NEW), 'match_state_updated', 'match:' || new.match_id::text || ':state', true);
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_match_state_updated() from public;

grant execute on function public.broadcast_match_state_updated() to authenticated, service_role;

-- Section: Triggers

drop trigger if exists trg_broadcast_match_state on public.matches;

create trigger trg_broadcast_match_state
  after update on public.matches for each row
  execute function public.broadcast_match_state_updated();

-- Section: Functions (continued)

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
  perform
    realtime.send(to_jsonb(NEW), 'innings_state_updated', 'match:' || new.match_id::text || ':state', true);
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_innings_state_updated() from public;

grant execute on function public.broadcast_innings_state_updated() to authenticated, service_role;

-- Section: Triggers (continued)

drop trigger if exists trg_broadcast_innings_state on public.cricket_match_innings_state;

create trigger trg_broadcast_innings_state
  after insert or update on public.cricket_match_innings_state for each row
  execute function public.broadcast_innings_state_updated();

-- Section: Functions (continued)

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
  perform
    realtime.send(to_jsonb(NEW), 'ball_recorded', 'match:' || new.match_id::text || ':balls', true);
  return NEW;
exception
  when others then
    return NEW;
end;
$$;

revoke all on function public.broadcast_new_delivery() from public;

grant execute on function public.broadcast_new_delivery() to authenticated, service_role;

-- Section: Triggers (continued)

drop trigger if exists trg_broadcast_delivery on public.cricket_match_deliveries;

create trigger trg_broadcast_delivery
  after insert on public.cricket_match_deliveries for each row
  execute function public.broadcast_new_delivery();

-- Section: Policies

-- 3. Security Lockdown: Revoke direct client write access
-- Direct client PostgREST writes are disabled; mutations must go through
-- authenticated Edge Functions (record-ball, start-innings, record-toss).
drop policy if exists "match_deliveries_write_scorer" on public.cricket_match_deliveries;

create policy "match_deliveries_write_scorer" on public.cricket_match_deliveries
  for insert to authenticated
  with check (false);

drop policy if exists "match_wickets_write_scorer" on public.cricket_match_wickets;

create policy "match_wickets_write_scorer" on public.cricket_match_wickets
  for insert to authenticated
  with check (false);

drop policy if exists "match_innings_state_write_scorer" on public.cricket_match_innings_state;

create policy "match_innings_state_write_scorer" on public.cricket_match_innings_state
  for update to authenticated
  using (false);

-- Section: Functions (continued)

-- 4. undo_last_ball
-- undo_last_ball RPC has been moved to TypeScript Edge Functions
-- (cricket-match-action) executing direct SQL in a single transaction.
-- 5. Broadcast a removed delivery
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
  perform
    realtime.send(to_jsonb(OLD), 'ball_deleted', 'match:' || old.match_id::text || ':balls', true);
  return OLD;
exception
  when others then
    return OLD;
end;
$$;

revoke all on function public.broadcast_delivery_deleted() from public;

grant execute on function public.broadcast_delivery_deleted() to authenticated, service_role;

-- Section: Triggers (continued)

drop trigger if exists trg_broadcast_delivery_deleted on public.cricket_match_deliveries;

create trigger trg_broadcast_delivery_deleted
  after delete on public.cricket_match_deliveries for each row
  execute function public.broadcast_delivery_deleted();
