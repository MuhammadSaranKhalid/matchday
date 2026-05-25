-- =============================================================================
-- 0610 · scheduled cleanup jobs (pg_cron)
-- =============================================================================
-- Two scheduled jobs that close the loop on time-based state transitions:
--
-- 1. expire_stale_match_requests — friendly-match requests auto-cancel
--    24h after they were sent if the opponent captain hasn't responded.
--    Marked `expired` (not `cancelled`) so the schema's decision-
--    consistency CHECK is happy without a `decided_by` user.
--
-- 2. abandon_stale_matches — confirmed matches that never actually
--    started get flipped to `abandoned` once enough time has passed that
--    "scoring it later" is no longer plausible. The rule is intentionally
--    narrow (7+ days past start, no actual_start_time, zero balls scored)
--    so we don't accidentally erase a match the manager just hasn't
--    gotten around to scoring yet.
-- =============================================================================

-- pg_cron is allow-listed on Supabase but disabled by default. Enable it.
create extension if not exists pg_cron with schema extensions;

-- -----------------------------------------------------------------------------
-- Cleanup function — flips pending → expired once the row has been sitting
-- for more than 24h with no response. SECURITY DEFINER so the cron runner
-- (minimal privileges) can still bypass RLS and write the update.
-- -----------------------------------------------------------------------------
create or replace function public.expire_stale_match_requests()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  -- Drives expiry off `code_expires_at` (set by send_match_request) so the
  -- semantics match what the sender sees on the share-code chip. Also
  -- catches `countered` rows that have been sitting un-responded — the
  -- code is still live during a counter, so the same cutoff applies.
  update public.match_requests
     set status        = 'expired',
         decided_at    = now(),
         decision_note = 'auto-expired after 24h with no response'
   where status in ('pending', 'countered')
     and code_expires_at is not null
     and code_expires_at < now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.expire_stale_match_requests() from public;

-- -----------------------------------------------------------------------------
-- Match cleanup — flips confirmed-but-never-played matches to `abandoned`.
-- Conditions (all required, AND):
--   • status in ('scheduled', 'rescheduled') — never actually kicked off
--   • scheduled_start_time is in the past by at least 7 days
--   • actual_start_time is NULL (no manager ever tapped "Start match")
--   • zero rows in `balls` for this match (no scoring happened either)
--
-- The trigger at 0420 (match_results.matches_after_complete) only fires
-- when status flips to `completed`, so flipping to `abandoned` here will
-- NOT cascade into tournament standings or bracket advancement.
-- -----------------------------------------------------------------------------
create or replace function public.abandon_stale_matches()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  update public.matches m
     set status = 'abandoned'
   where m.status in ('scheduled', 'rescheduled')
     and m.scheduled_start_time is not null
     and m.scheduled_start_time < now() - interval '7 days'
     and m.actual_start_time is null
     and not exists (
       select 1 from public.balls b where b.match_id = m.match_id
     );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.abandon_stale_matches() from public;

-- -----------------------------------------------------------------------------
-- Schedule both cron jobs. The DO block makes the migration safely re-
-- runnable: existing jobs of the same name get unscheduled first so the
-- new schedules cleanly replace them.
--
-- Frequencies:
--   • match-request expiry runs every 15 min — small table, T-24h cutoff
--     wants prompt action so senders see the status change.
--   • match abandonment runs hourly — bigger window (7 days), so a 1h
--     scan latency is fine and reduces cron noise.
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from cron.job where jobname = 'expire_stale_match_requests') then
    perform cron.unschedule('expire_stale_match_requests');
  end if;
  perform cron.schedule(
    'expire_stale_match_requests',
    '*/15 * * * *',
    $sql$select public.expire_stale_match_requests();$sql$
  );

  if exists (select 1 from cron.job where jobname = 'abandon_stale_matches') then
    perform cron.unschedule('abandon_stale_matches');
  end if;
  perform cron.schedule(
    'abandon_stale_matches',
    '7 * * * *',
    $sql$select public.abandon_stale_matches();$sql$
  );
end $$;
