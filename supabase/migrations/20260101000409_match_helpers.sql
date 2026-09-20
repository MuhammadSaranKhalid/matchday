-- =============================================================================
-- 0409 · match_helpers
-- =============================================================================
-- Cross-table match lifecycle and scoring helpers; circular lineup FK.
-- Spec: docs/matches-schema-architecture.md
-- Table declarations and their RLS/indexes live in their named migrations.
-- The matches -> match_players FK is deferred here because match_players
-- already references matches; neither declaration can precede the other.

-- Deferred FK: the PoM is a participant in THIS match, so it points at
-- match_players (which is polymorphic over profiles/unclaimed_players) rather
-- than profiles. This circular FK is declared after both tables exist.
alter table public.matches
  add constraint matches_player_of_the_match_fkey
  foreign key (player_of_the_match_id)
  references public.match_players(match_player_id) on delete set null;

-- -----------------------------------------------------------------------------
-- Match authorization predicates
-- -----------------------------------------------------------------------------

-- Helper Predicates
--
-- `_can_score_match(match_id)` was DELETED 2026-09-10. It answered the weaker
-- "may you score this match" (either side, plus the creator), had no callers
-- left, and was still granted — so the schema carried two live definitions of
-- "can score", the dead one being the more permissive. `_can_score_innings`
-- below is the only answer. Do not reintroduce a match-level variant: the
-- innings-level distinction IS the single-writer property the local-first
-- scoring design rests on (CLAUDE.md exemption 2).

create or replace function public._is_match_captain(p_match_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.matches m
    where m.match_id = p_match_id
      and (
        m.created_by = auth.uid()
        or m.team_a_captain = auth.uid()
        or m.team_b_captain = auth.uid()
      )
  );
$$;

-- -----------------------------------------------------------------------------
-- Who may score which innings  (design doc D12)
-- -----------------------------------------------------------------------------
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
security definer
stable
set search_path = public, pg_temp
as $$
  with m as (
    select * from public.matches where match_id = p_match_id
  ),
  sides as (
    select
      m.*,
      -- The team batting first: the toss winner if they chose to bat,
      -- otherwise the other team. Falls back to team_a before the toss.
      case
        when m.toss_won_by is null or m.toss_decision is null then m.team_a_id
        when m.toss_decision = 'bat' then m.toss_won_by
        when m.toss_won_by = m.team_a_id then m.team_b_id
        else m.team_a_id
      end as bats_first
    from m
  ),
  batting as (
    select
      sides.*,
      case
        when p_innings_number % 2 = 1 then sides.bats_first
        when sides.bats_first = sides.team_a_id then sides.team_b_id
        else sides.team_a_id
      end as batting_team_id
    from sides
  )
  select exists (
    select 1 from batting b
    where
      -- Practice matches have no opposition to hand over to.
      (b.match_type = 'practice' and b.created_by = auth.uid())
      -- The captain of the batting side.
      or (b.batting_team_id = b.team_a_id and b.team_a_captain = auth.uid())
      or (b.batting_team_id = b.team_b_id and b.team_b_captain = auth.uid())
      -- The batting side, via the authorization engine (2026-09-11).
      -- Superseded by the definition in 20260822120000, which adds the
      -- match-scope delegation branch — grants/match_officials are not wired
      -- up yet at this point in the run.
      or public.can('team', b.batting_team_id, 'match.score')
  );
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
security definer
stable
set search_path = public, pg_temp
as $$
  select public._can_score_innings(p_match_id, p_innings_number);
$$;

-- -----------------------------------------------------------------------------
-- NO SCORING TRIGGER.  (design doc D10 · CLAUDE.md exemption 2)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- Match Lifecycle RPCs
-- -----------------------------------------------------------------------------

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
    raise exception 'Only team captains can record the toss' using errcode = '42501';
  end if;

  update public.matches
  set
    toss_won_by = p_won_by,
    toss_decision = p_decision,
    toss_face = p_face,
    toss_recorded_at = now(),
    start_phase = 'lineup',
    status = 'toss',
    updated_at = now()
  where match_id = p_match_id;
end;
$$;

-- submit_match_openers, start_match_now, and start_innings RPCs
-- have been moved to TypeScript Edge Functions (cricket-match-action) executing direct SQL.

create or replace function public.list_my_matches()
returns setof public.matches
language sql
security definer
stable
as $$
  select * from public.matches m
  where m.created_by = auth.uid()
     or m.team_a_captain = auth.uid()
     or m.team_b_captain = auth.uid()
     or exists (
       select 1 from public.team_members tm
       where tm.user_id = auth.uid()
         and (tm.team_id = m.team_a_id or tm.team_id = m.team_b_id)
     )
  order by m.scheduled_start_time desc;
$$;
