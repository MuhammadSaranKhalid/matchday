-- =============================================================================
-- Matchday · Multi-Sport Match Shell · Phase 1 verification
-- =============================================================================

-- 1. Every Cricket match has exactly one Cricket extension.
select m.match_id
from public.matches m
left join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket'
  and cm.match_id is null;

-- EXPECTED: 0 rows.


-- 2. Non-Cricket matches cannot have Cricket extensions.
select cm.match_id, m.sport_id
from public.cricket_matches cm
join public.matches m
  on m.match_id = cm.match_id
where m.sport_id <> 'cricket';

-- EXPECTED: 0 rows.


-- 3. Every legacy Cricket player extension mirrors a Cricket match.
select cmp.match_player_id
from public.cricket_match_players cmp
join public.matches m
  on m.match_id = cmp.match_id
where m.sport_id <> 'cricket';

-- EXPECTED: 0 rows.


-- 4. Every innings row is attached to a Cricket match extension.
select mi.innings_id, mi.match_id
from public.match_innings mi
left join public.cricket_matches cm
  on cm.match_id = mi.match_id
where cm.match_id is null;

-- EXPECTED: 0 rows.


-- 5. Compare old/current Cricket match state to the extension.
select
  m.match_id,
  m.match_format = cm.format_code as format_code_ok,
  public._normalize_match_format(m.format) = cm.rules_snapshot as rules_ok,
  m.toss_won_by is not distinct from cm.toss_won_by as toss_winner_ok,
  m.toss_decision is not distinct from cm.toss_decision as toss_decision_ok,
  m.start_phase = cm.phase as phase_ok,
  m.scoring_mode = cm.scoring_mode as scoring_mode_ok,
  m.result is not distinct from cm.result as result_ok
from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket';

-- EXPECTED: every boolean column TRUE.


-- 6. Verify the Cricket aggregate view returns the same count.
select
  (select count(*) from public.matches where sport_id = 'cricket')
    as cricket_matches,
  (select count(*) from public.cricket_match_details)
    as cricket_aggregate_rows;

-- EXPECTED: counts equal.


-- 7. Verify sport immutability manually after creating a Cricket match.
-- Replace UUID and run inside a test transaction:
--
-- begin;
-- update public.matches
-- set sport_id = 'football'
-- where match_id = '<CRICKET_MATCH_UUID>';
-- -- EXPECTED: prevent_sport_reassignment error.
-- rollback;


-- 8. Inspect permissions. cricket_matches and its child extensions should be
-- read-only to anon/authenticated at the table privilege layer.
select
  grantee,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'cricket_matches',
    'cricket_match_players',
    'cricket_match_sides'
  )
order by table_name, grantee, privilege_type;
