-- =============================================================================
-- can_score_innings — expose the scoring-permission rule to the client
-- =============================================================================
-- The scoring screen was deciding who may score with its own rule:
--
--     battingTeam.isManagedBy(currentUserId)     -- owner or manager
--
-- while the write path (`record_ball` / `undo_last_ball`) uses
-- `_can_score_innings`, which is broader:
--
--     tournament organiser
--     OR an assigned `scorer` in match_officials
--     OR the creator of a single-team practice match
--     OR a manager/owner of the batting side
--
-- The client rule is a strict SUBSET, so it never let anyone in that the
-- server would reject — but it locked people OUT of matches the server would
-- happily let them score. Most importantly the assigned scorer: the person
-- `start_match_now` writes into match_officials at the moment the match goes
-- live. Whenever the captain is not also the team owner, the app handed them
-- a read-only scoreboard for a match they were just made scorer of.
--
-- Rather than teach the client the other three branches — a second copy of a
-- rule that must never drift — it now asks the server. One definition, two
-- consumers.
--
-- `_can_score_innings` is already SECURITY DEFINER and granted to
-- `authenticated`, so this adds no privilege. It exists as a separate public
-- name because the underscore prefix marks internal helpers throughout this
-- schema, and a client-facing contract should be explicit and stable even if
-- the internal helper's shape changes.
-- =============================================================================

create or replace function public.can_score_innings(
  p_match_id       uuid,
  p_innings_number integer default 1
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public._can_score_innings(p_match_id, p_innings_number);
$$;

comment on function public.can_score_innings(uuid, integer) is
  'True when the caller may record deliveries for this innings. The single '
  'source of truth for scoring permission — the client gates its UI on this '
  'so the controls never appear for someone whose taps the server rejects.';

revoke all on function public.can_score_innings(uuid, integer) from public;
grant execute on function public.can_score_innings(uuid, integer)
  to authenticated;
