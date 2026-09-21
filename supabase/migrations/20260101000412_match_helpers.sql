-- Migration file: 20260101000412_match_helpers.sql

-- 0412 · match_helpers
-- Cross-table match lifecycle and scoring helpers; circular lineup FK.
-- Spec: docs/matches-schema-architecture.md
-- Table declarations and their RLS/indexes live in their named migrations.
-- The matches -> match_players FK is deferred here because match_players
-- already references matches; neither declaration can precede the other.
-- Deferred FK: the PoM is a participant in THIS match, so it points at
-- match_players (which is polymorphic over profiles/unclaimed_players) rather
-- than profiles. This circular FK is declared after both tables exist.

-- Section: Tables and constraints

alter table public.matches
  add constraint matches_player_of_the_match_fkey foreign key (player_of_the_match_id) references public.match_players(match_player_id) on delete set null;

-- Section: Functions

-- Match authorization predicates
-- Helper Predicates
--
-- `_can_score_match(match_id)` was DELETED 2026-09-10. It answered the weaker
-- "may you score this match" (either side, plus the creator), had no callers
-- left, and was still granted — so the schema carried two live definitions of
-- "can score", the dead one being the more permissive. `_can_score_innings`
-- below is the only answer. Do not reintroduce a match-level variant: the
-- innings-level distinction IS the single-writer property the local-first
-- scoring design rests on (CLAUDE.md exemption 2).
create or replace function public._is_match_captain(
  p_match_id uuid
)
  returns boolean
  language sql
  security definer stable
  as $$
  select
    exists(
      select
        1
      from
        public.matches m
      where
        m.match_id = p_match_id
        and(
          m.created_by = auth.uid()
          -- captain of either side (cricket_match_players is the authoritative
          -- captain record; team_a_captain / team_b_captain no longer exist as
          -- stored columns on matches).
          or exists (
            select 1
            from public.match_players mp
            join public.cricket_match_players cmp
              on cmp.match_player_id = mp.match_player_id
             and cmp.match_id       = mp.match_id
            where mp.match_id  = p_match_id
              and mp.user_id   = auth.uid()
              and cmp.is_captain = true
          )
        )
    );
$$;

-- Who may score which innings  (design doc D12)
-- The BATTING side scores its own innings; control passes at the innings break.
-- Odd innings belong to whoever batted first (derived from the toss), even
-- innings to the other side. Tournament organisers and the creator of a
-- practice match may score either side.
--
-- record-ball calls this as its writer check. It takes the innings number
-- precisely so it can answer "may you score THIS innings" rather than the
-- weaker "may you score this match" — that distinction is the whole of the
-- single-writer property the local-first design rests on.
create or replace function public._can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
  returns boolean
  language sql
  security definer stable
  set search_path = public, pg_temp
  as $$
  with m as(
    select
      *
    from
      public.matches
    where
      match_id = p_match_id
),
sides as(
  select
    m.*,
    -- The team batting first: the toss winner if they chose to bat,
    -- otherwise the other team. Falls back to team_a before the toss.
    case when m.toss_won_by is null
      or m.toss_decision is null then
      m.team_a_id
    when m.toss_decision = 'bat' then
      m.toss_won_by
    when m.toss_won_by = m.team_a_id then
      m.team_b_id
    else
      m.team_a_id
    end as bats_first
  from
    m
),
batting as(
  select
    sides.*,
    case when p_innings_number % 2 = 1 then
      sides.bats_first
    when sides.bats_first = sides.team_a_id then
      sides.team_b_id
    else
      sides.team_a_id
    end as batting_team_id
  from
    sides
)
select
  exists(
    select
      1
    from
      batting b
    where
      -- Practice matches have no opposition to hand over to.
      (b.match_type = 'practice'
        and b.created_by = auth.uid())
      -- The captain of the batting side (derived from cricket_match_players;
      -- team_a_captain / team_b_captain no longer exist as stored columns).
      or exists (
        select 1
        from public.match_players mp
        join public.cricket_match_players cmp
          on cmp.match_player_id = mp.match_player_id
         and cmp.match_id       = mp.match_id
        where mp.match_id   = b.match_id
          and mp.user_id    = auth.uid()
          and mp.team_side  = case when b.batting_team_id = b.team_a_id then 'team_a' else 'team_b' end
          and cmp.is_captain = true
      )
      -- The batting side, via the authorization engine (2026-09-11).
      or public.can('team', b.batting_team_id, 'match.score'));
$$;

revoke all on function public._can_score_innings(uuid, integer) from public;

grant execute on function public._can_score_innings(uuid, integer) to authenticated, service_role;

-- can_score_innings is the client-facing gate. It MUST delegate to the same
-- predicate record-ball enforces — two definitions of "may you score" is how
-- the UI and the write path drifted apart last time.
create or replace function public.can_score_innings(
  p_match_id uuid,
  p_innings_number integer default 1
)
  returns boolean
  language sql
  security definer stable
  set search_path = public, pg_temp
  as $$
  select
    public._can_score_innings(p_match_id, p_innings_number);
$$;

-- NO SCORING TRIGGER.  (design doc D10 · CLAUDE.md exemption 2)
-- `fn_process_delivery` used to live here: it reduced each inserted delivery
-- into match_innings_state — running totals, strike rotation, over completion,
-- free-hit derivation — and upserted the materialised batting/bowling cards.
--
-- It is GONE, deliberately. The rules of cricket now live in exactly one place,
-- the Dart engine on the scoring device, because that device has to compute an
-- innings unaided while it has no signal. A second implementation here could
-- only ever agree or silently disagree, and it did the latter: it rotated
-- strike on `runs_off_bat % 2` (so runs run off a no-ball never changed ends),
-- hardcoded a six-ball over, never incremented `total_wickets`, and never
-- cleared `bowler_id` at the end of an over.
--
-- record-ball now writes match_innings_state itself: aggregate columns are
-- SUMMED from match_deliveries (D13 — derive, never accumulate, which is what
-- makes undo "delete the last row and re-total"), and the on-field trio comes
-- from the engine that computed the delivery.
--
-- 🟥 DO NOT reintroduce scoring arithmetic in SQL. If a scorecard number looks
-- wrong, the fix belongs in the Dart engine and its vectors.
--
-- That decision left match_batsman_stats and match_bowler_stats populated by
-- nothing. They were retained empty "pending a decision to drop them or back
-- them with views"; on 2026-09-06 the decision was made and they were dropped.
-- Scorecards are derived from the delivery ledger on the client
-- (see scoring_rules.dart), which is the only place the rules live.
-- Match Lifecycle RPCs
create or replace function public.record_match_toss(
  p_match_id uuid,
  p_won_by uuid,
  p_decision public.toss_decision,
  p_face char default null
)
  returns void
  language plpgsql
  security definer
  as $$
begin
  if not public._is_match_captain(p_match_id) then
    raise exception 'Only team captains can record the toss'
      using errcode = '42501';
  end if;
  update
    public.matches
  set
    toss_won_by = p_won_by,
    toss_decision = p_decision,
    toss_face = p_face,
    toss_recorded_at = now(),
    start_phase = 'lineup',
    status = 'toss',
    updated_at = now()
  where
    match_id = p_match_id;
end;
$$;

-- submit_match_openers, start_match_now, and start_innings RPCs
-- have been moved to TypeScript Edge Functions (cricket-match-action) executing direct SQL.
create or replace function public.list_my_matches()
  returns setof public.matches
  language sql
  security definer stable
  as $$
  select
    *
  from
    public.matches m
  where
    m.created_by = auth.uid()
    -- captain of either side (derived from cricket_match_players)
    or exists (
      select 1
      from public.match_players mp
      join public.cricket_match_players cmp
        on cmp.match_player_id = mp.match_player_id
       and cmp.match_id       = mp.match_id
      where mp.match_id   = m.match_id
        and mp.user_id    = auth.uid()
        and cmp.is_captain = true
    )
    or exists(
      select
        1
      from
        public.team_members tm
      where
        tm.user_id = auth.uid()
        and(tm.team_id = m.team_a_id
          or tm.team_id = m.team_b_id))
  order by
    m.scheduled_start_time desc;
$$;

-- Section: Views
create view public.cricket_match_details with ( security_invoker = true
) as
select
  m.match_id,
  m.tournament_id,
  m.match_type,
  m.stage,
  m.round,
  m.bracket_round_number,
  m.bracket_match_number,
  m.prev_match_a_id,
  m.prev_match_b_id,
  m.group_id,
  m.venue,
  m.ground_id,
  m.sport_id,
  m.scheduled_start_time,
  m.actual_start_time,
  m.completed_at,
  -- Canonical generic lifecycle for future backend/frontend consumers.
  m.status as lifecycle_status,
  -- Canonical Cricket phase.
  cm.phase as cricket_phase,
  -- Compatibility status for the existing Cricket-only Flutter app.
  case when m.status = 'scheduled'
    and cm.toss_recorded_at is not null then
    'toss'
  when m.status = 'live'
    and cm.phase = 'innings_break' then
    'innings_break'
  when m.status = 'live'
    and cm.phase = 'super_over' then
    'super_over'
  when m.status = 'completed'
    and cm.result ->> 'win_type' = 'tie' then
    'tied'
  when m.status = 'completed'
    and cm.result ->> 'win_type' = 'walkover' then
    'walkover'
  when cm.result ->> 'win_type' = 'no_result' then
    'no_result'
  else
    m.status::text
  end as status,
  m.winner_id,
  m.team_a_id,
  m.team_b_id,
  m.created_by,
  m.created_at,
  m.updated_at,
  cm.format_code as match_format,
  cm.rules_snapshot as format,
  cm.toss_won_by,
  cm.toss_decision,
  cm.toss_face,
  cm.toss_recorded_at,
  -- Existing MatchStartPhase has only the pre-live values. Once Cricket moves
  -- into innings-break/super-over/complete, expose `live` on the compatibility
  -- field while `cricket_phase` carries the exact phase.
  case cm.phase
  when 'toss' then
    'toss'
  when 'lineup' then
    'lineup'
  when 'ready' then
    'ready'
  else
    'live'
  end as start_phase,
  cm.openers_submitted_by,
  cm.openers_submitted_at,
  cm.scoring_mode,
  cm.result,
  cm.result_summary,
  cm.revised_conditions,
  cm.player_of_the_match_id,
(
    select
      mp.user_id
    from
      public.match_players mp
      join public.cricket_match_players cmp on cmp.match_player_id = mp.match_player_id
        and cmp.match_id = mp.match_id
    where
      mp.match_id = m.match_id
      and mp.team_side = 'team_a'
      and cmp.is_captain = true
      and mp.user_id is not null
    order by
      cmp.updated_at desc,
      mp.created_at asc
    limit 1
) as team_a_captain,
(
  select
    mp.user_id
  from
    public.match_players mp
    join public.cricket_match_players cmp on cmp.match_player_id = mp.match_player_id
      and cmp.match_id = mp.match_id
  where
    mp.match_id = m.match_id
    and mp.team_side = 'team_b'
    and cmp.is_captain = true
    and mp.user_id is not null
  order by
    cmp.updated_at desc,
    mp.created_at asc
  limit 1
) as team_b_captain
from
  public.matches m
  join public.cricket_matches cm on cm.match_id = m.match_id
where
  m.sport_id = 'cricket';

-- Section: Permissions (continued)

grant select on public.cricket_match_details to anon, authenticated, service_role;

comment on view public.cricket_match_details is 'Canonical Cricket aggregate. lifecycle_status is the generic parent '
  'lifecycle; cricket_phase is the exact Cricket phase; status/start_phase are '
  'compatibility projections for the current Cricket Flutter UI.';

create function public.list_my_cricket_matches()
  returns setof public.cricket_match_details
  language sql
  stable
  security definer
  set search_path = public, pg_temp
  as $$
  select
    d.*
  from
    public.cricket_match_details d
  where
    d.created_by =(
      select
        auth.uid())
    or public._is_match_captain(d.match_id)
    or exists(
      select
        1
      from
        public.team_members tm
      where
        tm.team_id in(d.team_a_id, d.team_b_id)
        and tm.user_id =(
          select
            auth.uid())
          and tm.status = 'active')
      or exists(
        select
          1
        from
          public.match_players mp
        where
          mp.match_id = d.match_id
          and mp.user_id =(
            select
              auth.uid()))
        or exists(
          select
            1
          from
            public.match_officials mo
          where
            mo.match_id = d.match_id
            and mo.user_id =(
              select
                auth.uid()))
        order by
          coalesce(d.scheduled_start_time, d.created_at) desc;
$$;

revoke all on function public.list_my_cricket_matches() from public, anon;

grant execute on function public.list_my_cricket_matches() to authenticated;



create or replace function public._can_score_innings(
  p_match_id uuid,
  p_innings_number smallint
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.match_scorer_leases l
    where l.match_id = p_match_id
      and l.innings_number = p_innings_number
      and l.scorer_id = auth.uid()
      and l.expires_at > now()
  ) or exists (
    select 1
    from public.matches m
    where m.match_id = p_match_id
      and (
        m.created_by = auth.uid()
        or public._is_match_captain(p_match_id)
      )
  );
$$;

grant execute on function public._can_score_innings(uuid, smallint) to authenticated;

create or replace function public.can_score_innings(
  p_match_id uuid,
  p_innings_number smallint
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select public._can_score_innings(p_match_id, p_innings_number);
$$;

grant execute on function public.can_score_innings(uuid, smallint) to authenticated;
