-- =============================================================================
-- 0411 · cascade_unclaimed_claim — the unclaimed-to-profile identity merge
-- =============================================================================
-- WHAT THIS FILE OWNS
-- -------------------
-- A trigger function (`cascade_unclaimed_claim`) and the AFTER UPDATE
-- trigger that fires it (`unclaimed_players_cascade_claim`). The function
-- depends on both team_members (0210) and match_players (0405), so the
-- earliest point in the migration order where the body can be expressed
-- in its final form is here, right after 0410 (balls).
--
-- WHEN THE TRIGGER FIRES
-- ----------------------
-- AFTER UPDATE on every row of `unclaimed_players`. The function body
-- short-circuits unless the specific column `claimed_by_user_id` has
-- transitioned from NULL to a real profile id (or been reassigned),
-- so routine edits to placeholders (renames, etc.) have no effect.
--
-- THE BUSINESS FLOW
-- -----------------
-- An "unclaimed player" is a placeholder a manager created to fill a
-- team slot for a person who hasn't signed up to the app yet. When that
-- person eventually creates an account, they (or a manager) marks the
-- placeholder as claimed by setting `claimed_by_user_id`. From that
-- moment on, the placeholder and the profile are the same person, and
-- every reference in the system must point at the profile instead.
--
-- This function performs that flip atomically — in the same transaction
-- that set `claimed_by_user_id`:
--
--   1. team_members (active roster rows): rewrite unclaimed_id →
--      user_id. Inactive / removed rows are left alone because flipping
--      them could collide with the claimer's existing active membership
--      under the team_members_unique_active_user partial unique index,
--      and because the historical audit reads more truthfully if the
--      placeholder identity is preserved on past memberships.
--
--   2. match_players (every row pointing at the placeholder):
--      rewrite unclaimed_id → profile_id, INCLUDING completed matches.
--      This makes the claimer's career view (once stats ship) one
--      continuous identity. The NOT EXISTS guard skips any (match,
--      team_side) where the claimer is ALREADY present — a rare edge
--      case (the claimer played a match against an unclaimed copy of
--      themselves) that the partial unique would otherwise reject. The
--      bulk update completes; the operator can resolve the duplicate.
--
--   3. migrate_player_stats(unclaimed_id, profile_id): a stub today;
--      once player_career_stats lands, it will fold the placeholder's
--      accumulated batting / bowling totals into the claimer's career
--      row.
--
-- WHAT IT DOES NOT TOUCH
-- ----------------------
--   * unclaimed_players itself — the placeholder row stays, with its
--     claimed_by_user_id set. The historical display name is preserved
--     for any UI showing "was previously listed as ...".
--   * match_officials — officials are always claimed users, never
--     placeholders.
--   * Authentication / notifications — both are responsibilities of
--     the calling RPC (approve_claim_request in 0230, or a manager
--     direct-write).
--
-- CONCURRENCY
-- -----------
-- The trigger holds the row lock on unclaimed_players taken by the
-- triggering UPDATE. Two concurrent attempts to set claimed_by_user_id
-- on the same placeholder serialise on that row, so the cascade runs
-- exactly once per claim.
-- =============================================================================

create or replace function public.cascade_unclaimed_claim()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Short-circuit unless this is the claim transition.
  if new.claimed_by_user_id is not null
     and old.claimed_by_user_id is distinct from new.claimed_by_user_id then

    -- (1) Active team memberships. Inactive/removed memberships stay
    --     anchored to the placeholder so audit history reads truthfully.
    update public.team_members
       set user_id      = new.claimed_by_user_id,
           unclaimed_id = null
     where unclaimed_id = new.unclaimed_id
       and status = 'active';

    -- (2) Match lineups across all matches (active + completed). The
    --     outer UPDATE has an explicit alias `mp1` so the correlated
    --     subquery's references unambiguously target it; bare
    --     `match_players.col` would also resolve correctly in current
    --     Postgres, but the alias future-proofs against planner
    --     changes.
    update public.match_players mp1
       set profile_id   = new.claimed_by_user_id,
           unclaimed_id = null
     where mp1.unclaimed_id = new.unclaimed_id
       and not exists (
         select 1
           from public.match_players mp2
          where mp2.match_id   = mp1.match_id
            and mp2.team_side  = mp1.team_side
            and mp2.profile_id = new.claimed_by_user_id
       );

    -- (3) Downstream stat fold-up. No-op until player_career_stats
    --     lands; included now so the contract is set.
    perform public.migrate_player_stats(new.unclaimed_id, new.claimed_by_user_id);
  end if;

  return new;
end;
$$;

-- The AFTER UPDATE trigger on unclaimed_players. Lives here, not in 0120
-- (where unclaimed_players is created) or 0210 (where team_members and
-- the old stub used to live), because the function it calls now writes
-- to match_players (0405) and we want exactly one place that owns this
-- whole flow.
create trigger unclaimed_players_cascade_claim
  after update on public.unclaimed_players
  for each row execute function public.cascade_unclaimed_claim();
