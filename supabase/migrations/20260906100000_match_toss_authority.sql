-- =============================================================================
-- 20260906100000 · match_toss_authority
-- =============================================================================
-- Who may do what between "match created" and "first ball".
--
-- The rule (product decision, 2026-09-06):
--   • Both captains hold equal authority over the match.
--   • The match CREATOR owns exactly one action: starting the toss and
--     recording who won it.
--   • The captain of the side that WON the toss owns the next decision, and
--     only that decision: bat or bowl.
--   • The batting side then owns the lineup and the Start CTA — which is
--     already what `submit_match_openers` / `start_match_now` enforce.
--
-- Two things had to change before that was expressible.
--
-- 1. `record_match_toss` wrote the winner AND the decision in one call, so
--    both belonged to whichever phone held the form. It is replaced by
--    `record_toss_winner` (creator) + `record_toss_decision` (toss winner).
--    `start_phase` stays 'toss' in between: the pause where the winner has
--    been named but the call has not been made is now a real, observable
--    state rather than a gap inside one statement. No new enum label — the
--    sub-step is derived from `toss_won_by is not null and toss_decision is
--    null`, the same way the batting side is derived rather than stored.
--
-- 2. `_is_match_captain` accepted `created_by`, which was quietly doing two
--    different jobs: granting the creator, and standing in for the captain
--    columns on tournament fixtures. The draw generator (20260903000000)
--    inserts fixtures WITHOUT team_a_captain / team_b_captain and nothing
--    ever backfilled them, so on those rows `created_by` was the only thing
--    keeping the lifecycle RPCs callable at all. Narrowing the predicate
--    without first filling those columns would have made every tournament
--    fixture impossible to start. So this migration fills them (trigger +
--    backfill), falls back to the live team captain when a column is still
--    null, and only then drops `created_by` from the predicate.
--
-- Consequence worth stating plainly: an organiser who is not a captain or
-- owner of either side can now start the toss on their fixture and nothing
-- else. The two captains run the rest.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Keep the captain columns populated.
-- -----------------------------------------------------------------------------
-- `matches.team_*_captain` is a snapshot taken when the fixture is made. Three
-- paths write a side onto a match: the challenge/application accept RPCs (which
-- already resolve captains), the tournament draw generator (which does not),
-- and bracket advancement (20260825000000 / 20260830000000), which fills a
-- feeder slot long after the row was inserted. A BEFORE trigger covers all
-- three and any future one, instead of four call sites that must remember.
create or replace function public._fill_match_captains()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.team_a_id is not null and new.team_a_captain is null then
    new.team_a_captain := public._team_current_captain(new.team_a_id);
  end if;
  if new.team_b_id is not null and new.team_b_captain is null then
    new.team_b_captain := public._team_current_captain(new.team_b_id);
  end if;
  return new;
end;
$$;

revoke all on function public._fill_match_captains() from public;
grant execute on function public._fill_match_captains() to authenticated, service_role;

drop trigger if exists matches_fill_captains on public.matches;
create trigger matches_fill_captains
  before insert or update of team_a_id, team_b_id on public.matches
  for each row execute function public._fill_match_captains();

-- Backfill what the trigger was not there for. Updating only the captain
-- columns does not re-fire the trigger above (it watches team_a_id/team_b_id).
update public.matches m
   set team_a_captain = public._team_current_captain(m.team_a_id)
 where m.team_a_captain is null
   and m.team_a_id is not null;

update public.matches m
   set team_b_captain = public._team_current_captain(m.team_b_id)
 where m.team_b_captain is null
   and m.team_b_id is not null;

-- -----------------------------------------------------------------------------
-- 2. Authority predicates.
-- -----------------------------------------------------------------------------
-- Captain-of-a-match, narrowed: the creator no longer qualifies. The stored
-- column stays authoritative when set; a null falls back to the team's live
-- captain so a fixture whose sides were filled before this migration — or by
-- some path that bypasses the trigger — can never lock both captains out.
create or replace function public._is_match_captain(p_match_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.matches m
    where m.match_id = p_match_id
      and (select auth.uid()) is not null
      and (select auth.uid()) in (
        coalesce(m.team_a_captain, public._team_current_captain(m.team_a_id)),
        coalesce(m.team_b_captain, public._team_current_captain(m.team_b_id))
      )
  );
$$;

revoke all on function public._is_match_captain(uuid) from public;
grant execute on function public._is_match_captain(uuid) to authenticated, service_role;

-- Captain of ONE named side. The toss decision belongs to the winner's
-- captain specifically, not to "a captain on this match".
create or replace function public._is_match_side_captain(
  p_match_id uuid,
  p_team_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.matches m
    where m.match_id = p_match_id
      and p_team_id is not null
      and (select auth.uid()) is not null
      and (select auth.uid()) = coalesce(
            case
              when p_team_id = m.team_a_id then m.team_a_captain
              when p_team_id = m.team_b_id then m.team_b_captain
            end,
            public._team_current_captain(p_team_id)
          )
  );
$$;

revoke all on function public._is_match_side_captain(uuid, uuid) from public;
grant execute on function public._is_match_side_captain(uuid, uuid) to authenticated, service_role;

create or replace function public._is_match_creator(p_match_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.matches m
    where m.match_id = p_match_id
      and m.created_by is not null
      and m.created_by = (select auth.uid())
  );
$$;

revoke all on function public._is_match_creator(uuid) from public;
grant execute on function public._is_match_creator(uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 3. The toss, in two acts.
-- -----------------------------------------------------------------------------
-- Act one — the creator flips the coin in the real world and records who won.
-- No decision is written: naming the winner is the whole of this action.
create or replace function public.record_toss_winner(
  p_match_id uuid,
  p_won_by uuid,
  p_face char default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_team_a uuid;
  v_team_b uuid;
  v_phase  public.match_start_phase;
begin
  select team_a_id, team_b_id, start_phase
    into v_team_a, v_team_b, v_phase
    from public.matches
   where match_id = p_match_id
   for update;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if not public._is_match_creator(p_match_id) then
    raise exception 'Only the match creator can start the toss'
      using errcode = '42501';
  end if;

  -- `not in` is unusable here: one side is null on an unresolved bracket slot,
  -- and `x not in (a, null)` is null — which an `if` reads as false, letting
  -- any uuid through.
  if p_won_by is null
     or (p_won_by is distinct from v_team_a
         and p_won_by is distinct from v_team_b) then
    raise exception 'The toss winner must be one of the two teams in this match'
      using errcode = '22023';
  end if;

  -- Correcting a misrecorded toss is allowed right up until the openers are
  -- locked; after that the batting side is already committed and re-flipping
  -- would silently swap which XI is at the crease.
  if v_phase not in ('toss', 'lineup') then
    raise exception 'The toss can no longer be changed once the openers are submitted'
      using errcode = '22023';
  end if;

  update public.matches
     set toss_won_by = p_won_by,
         -- Re-recording the winner voids any call already made against the
         -- old one: the (possibly different) winner chooses again.
         toss_decision = null,
         toss_face = coalesce(p_face, toss_face),
         toss_recorded_at = now(),
         start_phase = 'toss',
         status = 'toss',
         updated_at = now()
   where match_id = p_match_id;
end;
$$;

revoke all on function public.record_toss_winner(uuid, uuid, char) from public;
grant execute on function public.record_toss_winner(uuid, uuid, char) to authenticated;

-- Act two — the winning captain's phone makes the call. Advances
-- `start_phase: toss → lineup`, which is what hands the flow to the batting
-- side.
create or replace function public.record_toss_decision(
  p_match_id uuid,
  p_decision public.toss_decision
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_won_by uuid;
  v_phase  public.match_start_phase;
begin
  select toss_won_by, start_phase
    into v_won_by, v_phase
    from public.matches
   where match_id = p_match_id
   for update;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  if v_won_by is null then
    raise exception 'The toss winner has not been recorded yet'
      using errcode = '22023';
  end if;

  if not public._is_match_side_captain(p_match_id, v_won_by) then
    raise exception 'Only the captain of the side that won the toss can choose to bat or bowl'
      using errcode = '42501';
  end if;

  if v_phase not in ('toss', 'lineup') then
    raise exception 'The toss decision can no longer be changed once the openers are submitted'
      using errcode = '22023';
  end if;

  update public.matches
     set toss_decision = p_decision,
         start_phase = 'lineup',
         status = 'toss',
         updated_at = now()
   where match_id = p_match_id;
end;
$$;

revoke all on function public.record_toss_decision(uuid, public.toss_decision) from public;
grant execute on function public.record_toss_decision(uuid, public.toss_decision) to authenticated;

-- The combined call is gone rather than deprecated: leaving it callable would
-- leave the old "either captain records everything" path open beside the new
-- one, and its only caller is this repo's own datasource.
drop function if exists public.record_match_toss(uuid, uuid, public.toss_decision, char);
