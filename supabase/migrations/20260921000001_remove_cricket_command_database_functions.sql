-- =============================================================================
-- cricket-match-action direct-SQL cutover
-- Remove frequently-changing Cricket command PL/pgSQL functions
-- =============================================================================
--
-- APPLY ONLY AFTER:
--   1. Phase 3B/3C final schema is present.
--   2. The new direct-SQL cricket-match-action Edge Function is deployed.
--   3. A smoke test proves commands no longer call these functions.
--
-- NO CASCADE.
-- If another DB object still depends on one of these command functions, the
-- migration must fail so that hidden coupling is fixed explicitly.
--
-- KEEP:
--   public.can(...)
--   can_score_innings(...) / stable read authorization surfaces
--   list_my_cricket_matches()
--   read-heavy tournament leaderboards/live board
--   constraints, triggers/invariants, RLS, grants
--
-- REMOVE:
--   workflow commands whose business logic now lives in TypeScript.
-- =============================================================================

do $$
declare
  r record;
begin
  for r in
    select
      p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = any(
        array[
          'record_toss_winner',
          'record_toss_decision',
          'submit_match_openers',
          'start_match_now',
          'start_innings',
          'undo_last_ball',
          'complete_cricket_match',
          'tournament_reschedule_match',
          'tournament_abandon_match',
          'tournament_declare_walkover',
          'tournament_override_result',
          'tournament_revise_match_conditions',
          'tournament_trigger_super_over'
        ]
      )
  loop
    execute format(
      'drop function %s',
      r.signature
    );
  end loop;
end
$$;


comment on function public.can(
  text,
  uuid,
  text
) is
  'Stable generic authorization primitive. Cricket command behavior lives in Edge TypeScript.';
