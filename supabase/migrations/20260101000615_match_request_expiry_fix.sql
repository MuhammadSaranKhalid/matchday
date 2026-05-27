-- =============================================================================
-- 0615 · match_requests · expiry split + decline-reason rename
-- =============================================================================
-- Two design-driven fixes to the 0600 match_requests contract:
--
-- 1. Expiry semantics. The 0600 schema folds three independent timers into a
--    single `code_expires_at`:
--       • Proposal lifetime (sender→receiver)  — design says 48h.
--       • Counter lifetime  (receiver→sender)  — design says 24h, restart
--                                                from the counter moment.
--       • Share-code lifetime (in-person flow) — design says 24h.
--    With one timer they share the worst case: a counter posted at T+47h on
--    a 24h budget has 1h to live. We split them:
--       • `proposal_expires_at` set on send  (now + 48h) — pending timer.
--       • `counter_expires_at`  set on counter (now + 24h) — countered timer.
--       • `code_expires_at` keeps its 24h share-code semantics (unchanged).
--    The expiry cron now branches on status so pending/countered each get
--    their own deadline.
--
-- 2. Decline-reason rename. The enum value `unknown` was originally meant as
--    "Don't know this team" but the design's copy is "No interest right now".
--    Rename in-place; no Dart-side workaround needed.
--
-- This migration is safe to re-run: the columns are guarded by IF NOT EXISTS,
-- the enum rename is idempotent via a DO block, the function bodies are
-- CREATE OR REPLACE.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Decline-reason rename (no_interest replaces unknown).
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from pg_enum e
      join pg_type t on t.oid = e.enumtypid
     where t.typname = 'decline_reason' and e.enumlabel = 'unknown'
  ) and not exists (
    select 1 from pg_enum e
      join pg_type t on t.oid = e.enumtypid
     where t.typname = 'decline_reason' and e.enumlabel = 'no_interest'
  ) then
    execute 'alter type public.decline_reason rename value ''unknown'' to ''no_interest''';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Add the two new timer columns + backfill any existing rows.
-- -----------------------------------------------------------------------------
alter table public.match_requests
  add column if not exists proposal_expires_at timestamptz;

alter table public.match_requests
  add column if not exists counter_expires_at timestamptz;

-- Backfill: existing pending rows get 48h from created_at (or now() if that's
-- already passed, so we don't auto-expire on first cron run). Existing
-- countered rows get 24h from decided_at (or now() if that's already passed).
-- Already-decided rows are untouched.
update public.match_requests
   set proposal_expires_at = greatest(created_at + interval '48 hours', now() + interval '1 hour')
 where status = 'pending'
   and proposal_expires_at is null;

update public.match_requests
   set counter_expires_at = greatest(coalesce(decided_at, created_at) + interval '24 hours', now() + interval '1 hour')
 where status = 'countered'
   and counter_expires_at is null;

-- -----------------------------------------------------------------------------
-- 3. send_match_request — same body as 0600 except we now also set
--    proposal_expires_at = now() + 48h alongside the existing 24h share code.
-- -----------------------------------------------------------------------------
create or replace function public.send_match_request(
  p_from_team_id        uuid,
  p_to_team_id          uuid default null,
  p_proposed_start_time timestamptz default null,
  p_proposed_venue      text default null,
  p_proposed_format     jsonb default '{}'::jsonb,
  p_message             text default null,
  p_players_per_side    integer default 11,
  p_from_team_xi        uuid[] default '{}'::uuid[],
  p_from_team_keeper_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_request_id uuid;
  v_code       text;
  v_attempts   integer := 0;
  v_pps        integer := coalesce(p_players_per_side, 11);
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;
  if p_to_team_id is not null and p_from_team_id = p_to_team_id then
    raise exception 'A team cannot challenge itself' using errcode = '23514';
  end if;
  if not public.is_team_manager(p_from_team_id) then
    raise exception 'Only managers of the requesting team can send a match request'
      using errcode = '42501';
  end if;
  if v_pps < 5 or v_pps > 15 then
    raise exception 'players_per_side must be between 5 and 15' using errcode = '22023';
  end if;
  if p_from_team_xi is not null and array_length(p_from_team_xi, 1) is not null
     and array_length(p_from_team_xi, 1) > v_pps then
    raise exception 'from_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;
  perform public._validate_team_xi(p_from_team_id, p_from_team_xi);

  if p_to_team_id is not null and exists (
    select 1 from public.match_requests
     where from_team_id = p_from_team_id
       and to_team_id   = p_to_team_id
       and status in ('pending', 'countered')
  ) then
    raise exception 'A pending request already exists for these teams'
      using errcode = '23505';
  end if;

  loop
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    begin
      insert into public.match_requests (
        from_team_id, to_team_id, requested_by,
        proposed_start_time, proposed_venue, proposed_format, message,
        players_per_side, from_team_xi, from_team_keeper_id,
        share_code, code_expires_at, proposal_expires_at
      ) values (
        p_from_team_id, p_to_team_id, auth.uid(),
        p_proposed_start_time, p_proposed_venue,
        coalesce(p_proposed_format, '{}'::jsonb), p_message,
        v_pps,
        coalesce(p_from_team_xi, '{}'::uuid[]),
        p_from_team_keeper_id,
        v_code,
        now() + interval '24 hours',
        now() + interval '48 hours'
      )
      returning request_id into v_request_id;
      exit;
    exception when unique_violation then
      v_attempts := v_attempts + 1;
      if v_attempts >= 6 then
        raise;
      end if;
    end;
  end loop;

  return v_request_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- 4. counter_match_request — same body as 0600 except the UPDATE now also
--    resets counter_expires_at = now() + 24h, restarting the timer from the
--    counter moment.
-- -----------------------------------------------------------------------------
create or replace function public.counter_match_request(
  p_request_id                 uuid,
  p_countered_start_time       timestamptz default null,
  p_countered_venue            text default null,
  p_countered_format           jsonb default null,
  p_countered_players_per_side integer default null,
  p_decision_note              text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req     public.match_requests%rowtype;
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_requests
   where request_id = p_request_id
   for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Only pending requests can be countered (status: %)', v_req.status
      using errcode = '22023';
  end if;
  if v_req.to_team_id is null then
    raise exception 'Open requests cannot be countered; claim with desired terms instead'
      using errcode = '22023';
  end if;
  if not public.is_team_manager(v_req.to_team_id) then
    raise exception 'Only managers of the receiving team can counter'
      using errcode = '42501';
  end if;
  if p_countered_players_per_side is not null
     and (p_countered_players_per_side < 5 or p_countered_players_per_side > 15) then
    raise exception 'players_per_side must be between 5 and 15' using errcode = '22023';
  end if;
  if p_countered_start_time is null and p_countered_venue is null
     and p_countered_format is null and p_countered_players_per_side is null then
    raise exception 'A counter must change at least one field' using errcode = '22023';
  end if;

  update public.match_requests
     set status                     = 'countered',
         decided_by                 = auth.uid(),
         decided_at                 = now(),
         decision_note              = p_decision_note,
         countered_start_time       = p_countered_start_time,
         countered_venue            = p_countered_venue,
         countered_format           = p_countered_format,
         countered_players_per_side = p_countered_players_per_side,
         counter_expires_at         = now() + interval '24 hours'
   where request_id = p_request_id
     and status     = 'pending';
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Request changed under us; aborting counter'
      using errcode = '40001';
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- 5. expire_stale_match_requests — branch by status:
--      pending   → proposal_expires_at (48h budget)
--      countered → counter_expires_at  (24h budget, restarted from counter)
--    Falls back to code_expires_at for legacy rows that pre-date this fix
--    and somehow still have no proposal/counter timer set (defensive — the
--    backfill above should cover them, but a tighter guard is cheap).
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
  update public.match_requests
     set status        = 'expired',
         decided_at    = now(),
         decision_note = case status
                           when 'pending'   then 'auto-expired after 48h with no response'
                           when 'countered' then 'auto-expired after 24h with no response to counter'
                           else 'auto-expired'
                         end
   where (
     (status = 'pending'
        and (
          (proposal_expires_at is not null and proposal_expires_at < now())
          or (proposal_expires_at is null and code_expires_at is not null
              and code_expires_at < now() - interval '24 hours')
        ))
     or
     (status = 'countered'
        and (
          (counter_expires_at is not null and counter_expires_at < now())
          or (counter_expires_at is null and code_expires_at is not null
              and code_expires_at < now())
        ))
   );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
