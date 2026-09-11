-- =============================================================================
-- 0600 · match_challenges (friendly-match consent flow)
-- =============================================================================
-- RENAMED 2026-09-06: this table and every object named after it were called
-- `match_requests` here, but the deployed database had been renamed to
-- `match_challenges` out of band and the migration history never caught up.
-- lib/.../match_requests_remote_datasource.dart queries 'match_challenges', so
-- against a freshly reset database the whole challenge flow 404'd. The RPCs
-- keep their singular names (accept_match_request, counter_match_request, …)
-- because the client calls those by name; only the table and its constraint /
-- index / policy / trigger names moved.
-- =============================================================================
-- Spec §4.4. Friendlies between two teams (no tournament). Spec is silent on
-- consent, so we use the same approval pattern as claim_requests and team-
-- join_requests: one team's manager *requests*, the other team's manager
-- accepts / declines / counters. Only on accept does a row land in
-- `matches`. Keeps the matches table clean and mirrors a consent flow users
-- already understand.
--
-- Two flavours of request:
--   targeted   from_team_id ─► to_team_id              (Schedule a friendly)
--   open       from_team_id ─► null   then ─► picked   (Start a match now)
--
-- Both flavours mint a 6-digit share code with a 24h expiry so the in-person
-- flow is "Adil shows 482917 → Bilal types it → tap Accept" without
-- scrolling the inbox. Targeted requests notify the receiver's managers on
-- insert; open requests notify on accept (once the team_b is filled in).
--
-- XI exchange + counter-proposal:
--   The sender pencils their playing XI at send time; the receiver supplies
--   their XI at accept time. Both XIs materialise into match_players rows
--   (see 0405) at the moment accept_match_request runs — one row per
--   (match, side, player), already polymorphism-resolved against
--   team_members. The countered flow leaves the receiver-side XI empty
--   until a follow-up Pick-XI flow locks it in. The receiver can
--   counter-propose changes (date, venue, format, players-per-side) instead
--   of accepting outright; status flips to `countered` and the original
--   sender then accepts (match is created with countered terms) or declines
--   (status flips to declined).
--
-- Captains derive from `team_members.role = 'captain'` (falling back to
-- `teams.owner_id`) at the moment of accept, snapshotted into
-- `matches.team_a_captain` / `team_b_captain`. v1.0 doesn't support
-- mid-match captain changes; v1.1+ will add `set_match_captain`.
--
-- Writes to this table are RPC-only; direct INSERT/UPDATE/DELETE is denied
-- by RLS. The RPCs below are SECURITY DEFINER and bypass the lean read RLS.
-- =============================================================================

-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.


-- -----------------------------------------------------------------------------
-- match_challenges table.
-- -----------------------------------------------------------------------------
create table public.match_challenges (
  request_id            uuid primary key default gen_random_uuid(),
  from_team_id          uuid not null
                            references public.teams(team_id) on delete cascade,
  -- Nullable so an open challenge can be sent without picking the opponent.
  -- The accept RPC fills this in when the receiving team claims the code.
  to_team_id            uuid references public.teams(team_id) on delete cascade,
  -- ON DELETE SET NULL so a deleted sender's account doesn't block.
  -- The request row outlives them; the inbox renders "deleted user".
  requested_by          uuid
                            references public.profiles(user_id) on delete set null,

  -- Proposed terms (sender side).
  proposed_start_time   timestamptz,
  proposed_venue        text,
  proposed_format       jsonb not null default '{}'::jsonb,
  message               text check (message is null or length(message) <= 500),

  -- Players-per-side as a typed column so the roster gate compares an integer
  -- rather than parsing jsonb. GENERATED from proposed_format rather than
  -- stored separately: it used to be an independent column that could disagree
  -- with the blob it was supposed to mirror (20260604120100 found them
  -- diverging and made it a projection; folded inline 2026-09-06).
  players_per_side      smallint
                          generated always as (
                            (proposed_format->>'players_per_team')::smallint
                          ) stored,
  -- Sender's pencilled XI (user_ids). Length should equal players_per_side
  -- by match-day; smaller is allowed at send-time.
  from_team_xi          uuid[] not null default '{}'::uuid[],
  from_team_keeper_id   uuid   references public.profiles(user_id)
                                on delete set null,

  -- Counter-proposal columns (receiver-side, when status flips to countered).
  countered_start_time         timestamptz,
  countered_venue              text,
  countered_format             jsonb,
  countered_players_per_side   integer
                                check (countered_players_per_side is null
                                       or countered_players_per_side between 5 and 15),

  status                public.match_request_status not null default 'pending',

  -- Decision metadata (set on accept / decline / cancel / counter / expire).
  decided_by            uuid references public.profiles(user_id) on delete set null,
  decided_at            timestamptz,
  decision_note         text check (decision_note is null or length(decision_note) <= 500),
  decision_reason       public.decline_reason,

  -- The match row that materialised from this request (accept path only).
  match_id              uuid references public.matches(match_id) on delete set null,

  -- 6-digit code for the in-person flow + 24h expiry. The send RPC retries
  -- collisions against the partial unique index below.
  share_code            text,
  code_expires_at       timestamptz,

  -- Three independent timers, set by the RPCs below.
  --   proposal_expires_at — pending lifetime  (now + 48h on send).
  --   counter_expires_at  — countered lifetime (now + 24h on counter,
  --                          restarted from the counter moment).
  --   code_expires_at     — share-code lifetime (now + 24h on send).
  -- Folding them into one column caused the worst-case behaviour where a
  -- counter posted at T+47h on a 24h budget got only 1 hour to live.
  -- expire_stale_match_requests (0610) branches on status to honour
  -- whichever timer governs the current state.
  proposal_expires_at   timestamptz,
  counter_expires_at    timestamptz,

  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  -- A team can't challenge itself when both sides are filled in.
  -- Makes the players_per_side projection above sound: the key is always
  -- present and in range, so the generated column is never null or absurd.
  constraint match_challenges_proposed_ppt_valid check (
    proposed_format ? 'players_per_team'
    and (proposed_format->>'players_per_team')::int between 5 and 15
  ),

  constraint match_challenges_distinct_teams check (
    from_team_id is null
    or to_team_id is null
    or from_team_id <> to_team_id
  ),
  -- Decision/match_id consistency by status.
  constraint match_challenges_decision_consistency check (
    (status = 'pending'
       and decided_by is null and decided_at is null and match_id is null)
    or (status = 'countered'
       and decided_by is not null and decided_at is not null and match_id is null)
    or (status in ('declined', 'cancelled', 'expired')
       and (status = 'expired' or decided_by is not null)
       and decided_at is not null
       and match_id is null)
    or (status = 'accepted'
       and decided_by is not null and decided_at is not null and match_id is not null)
  )
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------
create index match_challenges_to_team_status
  on public.match_challenges (to_team_id, status, created_at desc);
create index match_challenges_from_team_status
  on public.match_challenges (from_team_id, status, created_at desc);
create index match_challenges_requested_by
  on public.match_challenges (requested_by);
-- Active codes are unique across pending + countered (a countered request
-- still owns its code until the sender resolves it).
create unique index match_challenges_active_code
  on public.match_challenges (share_code)
  where status in ('pending', 'countered') and share_code is not null;

create trigger match_challenges_set_updated_at
  before update on public.match_challenges
  for each row execute function public.set_updated_at();

-- =============================================================================
-- Helpers
-- =============================================================================

-- -----------------------------------------------------------------------------
-- _team_current_captain — the canonical captain user_id for a team.
-- Order of preference:
--   1. the active captain — now unique, see below.
--   2. the holder of the `owner` role — NOT teams.created_by, which is
--      history: a team's creator may have left.
-- Returns NULL only if the team itself is missing (caller's responsibility).
--
-- 2026-09-10: the `order by joined_at desc limit 1` tie-break is GONE. Single
-- captaincy used to be enforced only in Dart, so this function had to guess
-- which of several 'captain' rows was real; `team_members_one_captain` (0210)
-- now makes at most one possible. `role_requires_account` also guarantees a
-- captain has a user_id, so the null-filter is redundant — kept as a cheap
-- assertion in case the constraint is ever relaxed.
-- -----------------------------------------------------------------------------
create or replace function public._team_current_captain(p_team_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select tm.user_id
       from public.team_members tm
       join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
      where tm.team_id  = p_team_id
        and tmr.role_key = 'captain'
        and tm.status   = 'active'
        and tm.user_id is not null),
    (select tm.user_id
       from public.team_members tm
       join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
      where tm.team_id  = p_team_id
        and tmr.role_key = 'owner'
        and tm.status   = 'active'
        and tm.user_id is not null)
  );
$$;

revoke all on function public._team_current_captain(uuid) from public;
grant execute on function public._team_current_captain(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- _validate_team_xi — every uuid in p_xi must be an active claimed
-- team_member of p_team_id. Empty / null XI passes (managers can leave it
-- blank pre-match-day). Raises with a clear errcode/message on the first
-- mismatch so the caller's catch can surface a helpful UI message.
-- -----------------------------------------------------------------------------
create or replace function public._validate_team_xi(p_team_id uuid, p_xi uuid[])
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_invalid uuid;
begin
  if p_xi is null or array_length(p_xi, 1) is null then
    return;
  end if;

  select uid into v_invalid
    from unnest(p_xi) as t(uid)
   where not exists (
     select 1 from public.team_members tm
      where tm.team_id = p_team_id
        and tm.user_id = t.uid
        and tm.status  = 'active'
   )
   limit 1;

  if v_invalid is not null then
    raise exception 'Player % is not an active member of team %', v_invalid, p_team_id
      using errcode = '23514';
  end if;
end;
$$;

revoke all on function public._validate_team_xi(uuid, uuid[]) from public;
grant execute on function public._validate_team_xi(uuid, uuid[]) to authenticated;

-- =============================================================================
-- RPCs (writes go through these; direct INSERT/UPDATE/DELETE blocked by RLS).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- send_match_request — targeted OR open challenge. Always mints a 6-digit
-- code with a 24-hour expiry. p_to_team_id NULL ⇒ open challenge.
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
  -- Every pencilled player must actually be on the sending team.
  perform public._validate_team_xi(p_from_team_id, p_from_team_xi);

  -- Block duplicates only when targeted — open requests can stack (manager
  -- might want multiple parallel codes if they mistype or change ground).
  if p_to_team_id is not null and exists (
    select 1 from public.match_challenges
     where from_team_id = p_from_team_id
       and to_team_id   = p_to_team_id
       and status in ('pending', 'countered')
  ) then
    raise exception 'A pending request already exists for these teams'
      using errcode = '23505';
  end if;

  -- Mint a unique 6-digit code; retry on collision.
  loop
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    begin
      insert into public.match_challenges (
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
        now() + interval '24 hours',   -- share code lifetime
        now() + interval '48 hours'    -- proposal lifetime
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

revoke all on function public.send_match_request(
  uuid, uuid, timestamptz, text, jsonb, text, integer, uuid[], uuid
) from public;
grant execute on function public.send_match_request(
  uuid, uuid, timestamptz, text, jsonb, text, integer, uuid[], uuid
) to authenticated;

-- -----------------------------------------------------------------------------
-- accept_match_request — three flows behind one signature:
--   1. Targeted pending: caller is to_team manager; supplies their XI.
--   2. Open pending:     caller picks p_to_team_id + supplies XI.
--   3. Countered:        caller is the original sender (from_team manager).
--                        Match is created with the countered_* terms.
--                        Receiver XI is left empty (set at match day).
--
-- Captains snapshot from team_members at insert time. Both must resolve
-- (helper falls back to owner_id) or the insert fails its NOT NULL guard.
-- -----------------------------------------------------------------------------
create or replace function public.accept_match_request(
  p_request_id           uuid,
  p_scheduled_start_time timestamptz default null,
  p_venue                text default null,
  p_format               jsonb default null,
  p_decision_note        text default null,
  p_to_team_id           uuid default null,
  p_to_team_xi           uuid[] default '{}'::uuid[],
  p_to_team_keeper_id    uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req         public.match_challenges%rowtype;
  v_to_team     uuid;
  v_match_id    uuid;
  v_format      jsonb;
  v_start       timestamptz;
  v_venue       text;
  v_to_team_xi  uuid[];
  v_to_keeper   uuid;
  v_a_captain   uuid;
  v_b_captain   uuid;
  v_updated     integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_challenges
   where request_id = p_request_id
   for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if v_req.status not in ('pending', 'countered') then
    raise exception 'Request is no longer actionable (status: %)', v_req.status
      using errcode = '22023';
  end if;

  if v_req.status = 'countered' then
    if not public.is_team_manager(v_req.from_team_id) then
      raise exception 'Only the original sender can accept a countered request'
        using errcode = '42501';
    end if;
    v_to_team    := v_req.to_team_id;
    v_format     := coalesce(p_format, v_req.countered_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.countered_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.countered_venue, v_req.proposed_venue);
    v_to_team_xi := '{}'::uuid[];
    v_to_keeper  := null;
  elsif v_req.to_team_id is not null then
    if not public.is_team_manager(v_req.to_team_id) then
      raise exception 'Only managers of the receiving team can accept'
        using errcode = '42501';
    end if;
    v_to_team    := v_req.to_team_id;
    v_format     := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
    v_to_keeper  := p_to_team_keeper_id;
  else
    if p_to_team_id is null then
      raise exception 'Open requests require p_to_team_id to claim'
        using errcode = '22023';
    end if;
    if p_to_team_id = v_req.from_team_id then
      raise exception 'A team cannot accept its own challenge'
        using errcode = '23514';
    end if;
    if not public.is_team_manager(p_to_team_id) then
      raise exception 'You can only accept on behalf of teams you manage'
        using errcode = '42501';
    end if;
    v_to_team    := p_to_team_id;
    v_format     := coalesce(p_format, v_req.proposed_format, '{}'::jsonb);
    v_start      := coalesce(p_scheduled_start_time, v_req.proposed_start_time);
    v_venue      := coalesce(p_venue, v_req.proposed_venue);
    v_to_team_xi := coalesce(p_to_team_xi, '{}'::uuid[]);
    v_to_keeper  := p_to_team_keeper_id;
  end if;

  if v_to_team_xi is not null and array_length(v_to_team_xi, 1) is not null
     and array_length(v_to_team_xi, 1) > v_req.players_per_side then
    raise exception 'to_team_xi has more players than players_per_side'
      using errcode = '22023';
  end if;
  -- Re-validate sender XI in case team_members changed since send (player
  -- removed from squad, etc.), and validate receiver XI.
  perform public._validate_team_xi(v_req.from_team_id, v_req.from_team_xi);
  perform public._validate_team_xi(v_to_team, v_to_team_xi);

  v_a_captain := public._team_current_captain(v_req.from_team_id);
  v_b_captain := public._team_current_captain(v_to_team);
  if v_a_captain is null or v_b_captain is null then
    raise exception 'Both teams must have a captain or owner before a match can be created'
      using errcode = '23502';
  end if;

  insert into public.matches (
    match_type, tournament_id,
    team_a_id, team_b_id,
    team_a_captain, team_b_captain,
    format, venue, scheduled_start_time,
    status, created_by
  ) values (
    'friendly', null,
    v_req.from_team_id, v_to_team,
    v_a_captain, v_b_captain,
    v_format, v_venue, v_start,
    'scheduled', auth.uid()
  )
  returning match_id into v_match_id;

  -- ---------------------------------------------------------------------------
  -- MATERIALISE THE PLAYING XIS INTO match_players
  --
  -- v1 UX never collects an XI up front — the captain picks openers from
  -- the full roster on the Lineup screen. So if the supplied XI list is
  -- empty (most common path: the sender hadn't selected one, or the
  -- receiver accepted without supplying `p_to_team_xi`), default to
  -- "the team's full active roster". When the XI is non-empty (a future
  -- Pick-XI flow), filter to the picked players.
  --
  -- The request carries `from_team_xi`; the receiver supplies its XI as
  -- the `p_to_team_xi` RPC param (held in `v_to_team_xi`). Both are
  -- uuid[] lists of either profile ids or unclaimed_player ids — the
  -- polymorphism is resolved by joining against team_members, which
  -- already enforces the (user_id XOR unclaimed_id) check that
  -- match_players inherits.
  --
  -- KEEPER FLAG
  --   `from_team_keeper_id` / `v_to_keeper` are uuids that may resolve
  --   to either column. We match on either, so an unclaimed wicket-
  --   keeper is first-class.
  --
  -- CAPTAIN FLAG
  --   v_a_captain / v_b_captain come from _team_current_captain (0240),
  --   which returns the team's owner or captain — always a real profile.
  --   Matching only on tm.user_id is therefore correct.
  --
  -- LINEUP SHAPE (corrected 2026-09-06)
  --   These two INSERTs wrote the pre-reset match_players shape — profile_id
  --   (now user_id), is_captain / is_keeper (now one `role` enum), team_side
  --   'a' / 'b' (now 'team_a' / 'team_b') — and omitted display_name, which is
  --   NOT NULL. plpgsql bodies are not column-checked at CREATE time, so this
  --   compiled and failed on the first real acceptance. 20260822110000 fixed it
  --   by replacing the whole function later in the run; the base is now correct
  --   in its own right.
  -- ---------------------------------------------------------------------------
  insert into public.match_players (
    match_id, team_side, user_id, unclaimed_id, display_name, role
  )
  select v_match_id, 'team_a',
         tm.user_id, tm.unclaimed_id,
         coalesce(p.display_name, u.display_name, 'Player'),
         case
           when coalesce(tm.user_id = v_a_captain, false) then 'captain'::public.match_role
           when coalesce(tm.user_id      = v_req.from_team_keeper_id
                      or tm.unclaimed_id = v_req.from_team_keeper_id, false) then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end
    from public.team_members tm
    left join public.profiles p           on p.user_id      = tm.user_id
    left join public.unclaimed_players u   on u.unclaimed_id = tm.unclaimed_id
   where tm.team_id = v_req.from_team_id
     and tm.status  = 'active'
     and (
       -- Empty XI = include the full active roster.
       coalesce(array_length(v_req.from_team_xi, 1), 0) = 0
       -- Non-empty XI = filter to the picked players.
       or tm.user_id      = any(v_req.from_team_xi)
       or tm.unclaimed_id = any(v_req.from_team_xi)
     );

  insert into public.match_players (
    match_id, team_side, user_id, unclaimed_id, display_name, role
  )
  select v_match_id, 'team_b',
         tm.user_id, tm.unclaimed_id,
         coalesce(p.display_name, u.display_name, 'Player'),
         case
           when coalesce(tm.user_id = v_b_captain, false) then 'captain'::public.match_role
           when coalesce(tm.user_id      = v_to_keeper
                      or tm.unclaimed_id = v_to_keeper, false) then 'wicket_keeper'::public.match_role
           else 'player'::public.match_role
         end
    from public.team_members tm
    left join public.profiles p           on p.user_id      = tm.user_id
    left join public.unclaimed_players u   on u.unclaimed_id = tm.unclaimed_id
   where tm.team_id = v_to_team
     and tm.status  = 'active'
     and (
       -- Empty XI = include the full active roster.
       coalesce(array_length(v_to_team_xi, 1), 0) = 0
       -- Non-empty XI = filter to the picked players.
       or tm.user_id      = any(v_to_team_xi)
       or tm.unclaimed_id = any(v_to_team_xi)
     );

  -- Race guard: the inner UPDATE re-asserts the status we read above. If
  -- another concurrent transaction (counter / cancel / decline) already
  -- transitioned the row, our UPDATE matches zero rows and we roll back
  -- — preventing a match from being created against stale terms.
  update public.match_challenges
     set status        = 'accepted',
         decided_by    = auth.uid(),
         decided_at    = now(),
         decision_note = p_decision_note,
         match_id      = v_match_id,
         to_team_id    = v_to_team
   where request_id = p_request_id
     and status     = v_req.status;
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Request changed under us; aborting accept'
      using errcode = '40001';
  end if;

  return v_match_id;
end;
$$;

revoke all on function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
) from public;
grant execute on function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
) to authenticated;

-- -----------------------------------------------------------------------------
-- counter_match_request — receiver proposes changes. Status: pending →
-- countered. Requires at least one field different from the original. Only
-- once per request (no re-counter loop in v1).
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
  v_req     public.match_challenges%rowtype;
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_challenges
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

  -- Race guard: only transition if we still observe 'pending'. A concurrent
  -- accept_match_request that's already moved the row to 'accepted' will
  -- cause this UPDATE to match zero rows and we abort cleanly.
  update public.match_challenges
     set status                     = 'countered',
         decided_by                 = auth.uid(),
         decided_at                 = now(),
         decision_note              = p_decision_note,
         countered_start_time       = p_countered_start_time,
         countered_venue            = p_countered_venue,
         countered_format           = p_countered_format,
         countered_players_per_side = p_countered_players_per_side,
         -- Counter timer is restarted from THIS moment, not from the
         -- original send. The countered party gets a fresh 24h to decide.
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

revoke all on function public.counter_match_request(
  uuid, timestamptz, text, jsonb, integer, text
) from public;
grant execute on function public.counter_match_request(
  uuid, timestamptz, text, jsonb, integer, text
) to authenticated;

-- -----------------------------------------------------------------------------
-- decline_match_request — structured reason + free-text note. Handles both
-- pending (receiver declines) and countered (sender declines the counter).
-- -----------------------------------------------------------------------------
create or replace function public.decline_match_request(
  p_request_id      uuid,
  p_decision_note   text default null,
  p_decision_reason public.decline_reason default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req     public.match_challenges%rowtype;
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_challenges
   where request_id = p_request_id
   for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;

  if v_req.status = 'pending' then
    if v_req.to_team_id is null then
      raise exception 'Open requests cannot be declined; cancel from sender side instead'
        using errcode = '22023';
    end if;
    if not public.is_team_manager(v_req.to_team_id) then
      raise exception 'Only managers of the receiving team can decline'
        using errcode = '42501';
    end if;
  elsif v_req.status = 'countered' then
    if not public.is_team_manager(v_req.from_team_id) then
      raise exception 'Only the original sender can decline a countered request'
        using errcode = '42501';
    end if;
  else
    raise exception 'Request is no longer actionable (status: %)', v_req.status
      using errcode = '22023';
  end if;

  update public.match_challenges
     set status          = 'declined',
         decided_by      = auth.uid(),
         decided_at      = now(),
         decision_note   = p_decision_note,
         decision_reason = p_decision_reason
   where request_id = p_request_id
     and status     = v_req.status;
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Request changed under us; aborting decline'
      using errcode = '40001';
  end if;
end;
$$;

revoke all on function public.decline_match_request(
  uuid, text, public.decline_reason
) from public;
grant execute on function public.decline_match_request(
  uuid, text, public.decline_reason
) to authenticated;

-- -----------------------------------------------------------------------------
-- cancel_match_request — sender withdraws a pending OR countered request.
-- -----------------------------------------------------------------------------
create or replace function public.cancel_match_request(
  p_request_id    uuid,
  p_decision_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_req     public.match_challenges%rowtype;
  v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_req from public.match_challenges
   where request_id = p_request_id
   for update;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  if v_req.status not in ('pending', 'countered') then
    raise exception 'Request is no longer actionable (status: %)', v_req.status
      using errcode = '22023';
  end if;
  if not public.is_team_manager(v_req.from_team_id) then
    raise exception 'Only managers of the requesting team can cancel'
      using errcode = '42501';
  end if;

  update public.match_challenges
     set status        = 'cancelled',
         decided_by    = auth.uid(),
         decided_at    = now(),
         decision_note = p_decision_note
   where request_id = p_request_id
     and status     = v_req.status;
  get diagnostics v_updated = row_count;

  if v_updated = 0 then
    raise exception 'Request changed under us; aborting cancel'
      using errcode = '40001';
  end if;
end;
$$;

revoke all on function public.cancel_match_request(uuid, text) from public;
grant execute on function public.cancel_match_request(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- find_match_request_by_code — receiver-side resolver for a 6-digit code.
-- SECURITY DEFINER bypasses the read RLS so:
--   - Open requests (to_team_id null) are visible to anyone holding the code;
--     the team-picker step gates accept on is_team_manager(picked).
--   - Targeted requests are visible only to managers of to_team_id.
-- Wrong / expired / unauthorised codes return zero rows (look identical so
-- nothing leaks).
-- -----------------------------------------------------------------------------
create or replace function public.find_match_request_by_code(
  p_code text
)
returns setof public.match_challenges
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row public.match_challenges%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select * into v_row
    from public.match_challenges
   where share_code      = p_code
     and status          in ('pending', 'countered')
     and code_expires_at > now()
   limit 1;

  if v_row.request_id is null then
    return;
  end if;
  if v_row.to_team_id is not null and not public.is_team_manager(v_row.to_team_id) then
    return;
  end if;

  return next v_row;
end;
$$;

revoke all on function public.find_match_request_by_code(text) from public;
grant execute on function public.find_match_request_by_code(text) to authenticated;

-- =============================================================================
-- Notification fan-out triggers.
-- INSERT (status='pending')            → notify every manager of to_team
--                                         (open requests skip — no recipient
--                                          pool yet; notified on accept).
-- UPDATE pending  → not-pending        → notify the requester + every other
--                                         manager of from_team.
-- UPDATE countered → not-countered     → notify the from_team's counter-poser
--                                         side (i.e. members of to_team) so
--                                         they learn the sender's verdict.
-- =============================================================================
create or replace function public.notify_on_match_request_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient uuid;
begin
  if new.status <> 'pending' then
    return new;
  end if;
  if new.to_team_id is null then
    return new;
  end if;

  -- 2026-09-10: owner and managers used to be read from two different places
  -- (teams.owner_id and teams.managers[]) and looped separately, with a manual
  -- dedup between them. team_staff_ids() returns the one set.
  for v_recipient in select public.team_staff_ids(new.to_team_id) loop
    if v_recipient <> new.requested_by then
      insert into public.notifications (recipient_id, type, payload)
      values (
        v_recipient,
        'match_request',
        jsonb_build_object(
          'request_id',    new.request_id,
          'from_team_id',  new.from_team_id,
          'to_team_id',    new.to_team_id,
          'actor_id',      new.requested_by
        )
      );
    end if;
  end loop;
  return new;
end;
$$;

create trigger match_challenges_notify_insert
  after insert on public.match_challenges
  for each row execute function public.notify_on_match_request_insert();

create or replace function public.notify_on_match_request_decision()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient   uuid;
  v_actor       uuid;
  v_notify_team uuid;
begin
  -- Fire on pending→X or countered→X status flips only.
  if old.status = new.status
     or old.status not in ('pending', 'countered') then
    return new;
  end if;
  v_actor := coalesce(new.decided_by, auth.uid());

  if old.status = 'pending' then
    v_notify_team := new.from_team_id;

    -- Always notify the original requester.
    if new.requested_by <> v_actor then
      insert into public.notifications (recipient_id, type, payload)
      values (
        new.requested_by,
        'match_request_decision',
        jsonb_build_object(
          'request_id',    new.request_id,
          'from_team_id',  new.from_team_id,
          'to_team_id',    new.to_team_id,
          'status',        new.status::text,
          'match_id',      new.match_id,
          'actor_id',      v_actor
        )
      );
    end if;
  else
    -- countered → X: the team that countered is to_team_id.
    v_notify_team := new.to_team_id;
  end if;

  if v_notify_team is null then
    return new;
  end if;

  -- 2026-09-10: one set instead of owner-then-array with a manual dedup.
  -- The `old.status <> 'pending'` guard stays: on a pending→X flip the original
  -- requester was already notified above, so they must not be told twice.
  for v_recipient in select public.team_staff_ids(v_notify_team) loop
      if v_recipient <> v_actor
         and (old.status <> 'pending' or v_recipient <> new.requested_by) then
        insert into public.notifications (recipient_id, type, payload)
        values (
          v_recipient,
          'match_request_decision',
          jsonb_build_object(
            'request_id',    new.request_id,
            'from_team_id',  new.from_team_id,
            'to_team_id',    new.to_team_id,
            'status',        new.status::text,
            'match_id',      new.match_id,
            'actor_id',      v_actor
          )
        );
      end if;
  end loop;
  return new;
end;
$$;

create trigger match_challenges_notify_decision
  after update of status on public.match_challenges
  for each row execute function public.notify_on_match_request_decision();

-- =============================================================================
-- Row-level security.
-- Read: managers of either team (to_team_id null = visible only via the
--       SECURITY DEFINER lookup RPC above).
-- Writes: blocked direct — RPCs are the only path.
-- =============================================================================
alter table public.match_challenges enable row level security;

create policy "match_challenges_read_team_managers"
  on public.match_challenges for select
  to anon, authenticated
  using (
    public.is_team_manager(from_team_id)
    or (to_team_id is not null and public.is_team_manager(to_team_id))
    or (to_team_id is null and status = 'pending')
  );

create policy "match_challenges_no_direct_insert"
  on public.match_challenges for insert
  to authenticated
  with check (false);

create policy "match_challenges_no_direct_update"
  on public.match_challenges for update
  to authenticated
  using (false)
  with check (false);

create policy "match_challenges_no_direct_delete"
  on public.match_challenges for delete
  to authenticated
  using (false);

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_match_challenges_decided_by
  on public.match_challenges (decided_by);
create index if not exists idx_match_challenges_match_id
  on public.match_challenges (match_id);
