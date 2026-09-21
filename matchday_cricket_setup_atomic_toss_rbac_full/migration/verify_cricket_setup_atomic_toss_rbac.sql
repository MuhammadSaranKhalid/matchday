-- =============================================================================
-- Verify Matchday Cricket setup-side + atomic toss + RBAC hard cut
-- =============================================================================

-- 1. Generic matches stays sport-neutral: no setup/host field.
select
  not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='matches'
      and column_name in ('host_side','setup_side')
  ) as generic_match_has_no_cricket_setup_field;
-- EXPECT: true


-- 2. Cricket extension owns setup_side + toss actor.
select
  column_name,
  data_type,
  udt_name,
  is_nullable
from information_schema.columns
where table_schema='public'
  and table_name='cricket_matches'
  and column_name in ('setup_side','toss_recorded_by')
order by column_name;
-- EXPECT: 2 rows.


-- 3. setup_side has both local-value and same-match structural integrity.
select
  conname,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid='public.cricket_matches'::regclass
  and conname in (
    'cricket_matches_setup_side_check',
    'cricket_matches_setup_side_fkey',
    'cricket_matches_toss_recorded_by_fkey'
  )
order by conname;
-- EXPECT: 3 rows.

select
  t.tgname,
  pg_get_triggerdef(t.oid) as definition
from pg_trigger t
join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname='cricket_matches'
  and not t.tgisinternal
  and t.tgname='cricket_matches_setup_side_immutable';
-- EXPECT: 1 row.


-- 4. No invalid Cricket setup side exists.
select
  cm.match_id,
  cm.setup_side
from public.cricket_matches cm
left join public.match_teams mt
  on mt.match_id=cm.match_id
 and mt.team_side=cm.setup_side
where cm.setup_side is not null
  and mt.match_id is null;
-- EXPECT: 0 rows.


-- 5. Resolved peer-to-peer scheduled Cricket fixtures have a setup side.
select
  cm.match_id,
  m.match_type,
  m.status,
  cm.setup_side
from public.cricket_matches cm
join public.matches m
  on m.match_id=cm.match_id
where m.tournament_id is null
  and m.status='scheduled'
  and cm.setup_side is null
  and exists (
    select 1
    from public.match_teams mt
    where mt.match_id=m.match_id
      and mt.team_side='team_a'
      and mt.team_id is not null
  );
-- EXPECT: 0 rows.


-- 6. Cricket setup capability is sport-specific and valid at team + match scope.
select
  p.permission_key,
  p.resource,
  p.action,
  p.description,
  p.direct_grantable,
  p.sort_order
from public.permissions p
where p.permission_key in (
  'cricket.match.setup',
  'match.lineup.set'
)
order by p.permission_key;
-- EXPECT: only cricket.match.setup; direct_grantable=true.

select
  permission_key,
  scope
from public.permission_scopes
where permission_key='cricket.match.setup'
order by scope;
-- EXPECT: match, team.


-- 7. Default team role matrix was migrated.
select
  role_key,
  granted
from public.role_permissions
where team_id is null
  and scope='team'
  and permission_key='cricket.match.setup'
order by role_key;
-- EXPECT owner/manager/captain = true; player absent unless explicitly configured.


-- 8. Scorer grant mirror handles generic scoring and Cricket setup separately.
select
  pg_get_functiondef(
    'public.mirror_scorer_grant()'::regprocedure
  ) like '%match.score%' as mirrors_score,
  pg_get_functiondef(
    'public.mirror_scorer_grant()'::regprocedure
  ) like '%cricket.match.setup%' as mirrors_cricket_setup,
  pg_get_functiondef(
    'public.mirror_scorer_grant()'::regprocedure
  ) like '%m.sport_id = ''cricket''%' as cricket_grant_is_sport_guarded;
-- EXPECT: true / true / true.


-- 9. Every current Cricket scorer has both grants.
select
  mo.match_id,
  mo.user_id,
  array_agg(g.permission_key order by g.permission_key)
    filter (
      where g.permission_key in (
        'match.score',
        'cricket.match.setup'
      )
    ) as grants
from public.match_officials mo
join public.matches m
  on m.match_id=mo.match_id
left join public.grants g
  on g.subject_id=mo.user_id
 and g.scope='match'
 and g.entity_id=mo.match_id
where mo.role='scorer'
  and m.sport_id='cricket'
group by mo.match_id, mo.user_id
having count(*) filter (
  where g.permission_key in (
    'match.score',
    'cricket.match.setup'
  )
) <> 2;
-- EXPECT: 0 rows.


-- 10. Cricket aggregate remains security-invoker and exposes setup projection.
select
  c.relname,
  c.reloptions
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname='cricket_match_details';
-- EXPECT reloptions includes security_invoker=true.

select column_name
from information_schema.columns
where table_schema='public'
  and table_name='cricket_match_details'
  and column_name in (
    'setup_side',
    'setup_team_id',
    'toss_recorded_by',
    'toss_won_by',
    'toss_won_by_side',
    'team_a_id',
    'team_b_id'
  )
order by column_name;
-- EXPECT: 7 rows.


-- 11. Peer-to-peer creation paths are canonical and capability-driven.
select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as args,
  pg_get_functiondef(p.oid) like '%team.challenge.send%' as uses_generic_rbac,
  pg_get_functiondef(p.oid) like '%setup_side%' as assigns_cricket_setup_side,
  pg_get_functiondef(p.oid) ~
    'insert[[:space:]]+into[[:space:]]+public\.matches[[:space:]]*\([^;]*(team_a_id|team_b_id)'
      as writes_old_match_team_columns
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in (
    'accept_match_request',
    'accept_pool_application'
  )
order by p.proname;
-- EXPECT both: uses_generic_rbac=true, assigns_cricket_setup_side=true,
-- writes_old_match_team_columns=false.


-- 12. Tournament fixture creation remains neutral for Cricket setup.
select
  pg_get_functiondef(p.oid) like '%setup_side%' as mentions_setup_side,
  pg_get_functiondef(p.oid) like '%null%' as contains_neutral_assignment
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname='tournament_generate_fixtures'
limit 1;
-- EXPECT: true / true. Manual review should confirm setup_side is inserted NULL.


-- 13. Tournament assignment helpers no longer depend on nonexistent legacy helpers.
select
  p.proname,
  pg_get_functiondef(p.oid) like '%_require_match_organizer%' as uses_missing_organizer_helper,
  pg_get_functiondef(p.oid) like '%tournament_scorer_candidates%' as uses_missing_scorer_candidates,
  pg_get_functiondef(p.oid) like '%tournament_official_candidates%' as uses_live_candidate_api
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in (
    'tournament_assign_scorer',
    'tournament_assign_official',
    'tournament_auto_assign_scorers'
  )
order by p.proname;
-- EXPECT missing-helper columns=false. Candidate API true where applicable.


-- 14. list_my_cricket_matches still exists.
select
  to_regprocedure('public.list_my_cricket_matches()') is not null
    as list_my_cricket_matches_exists;
-- EXPECT: true.


-- 15. Final match lifecycle is still generic.
select e.enumlabel
from pg_type t
join pg_enum e on e.enumtypid=t.oid
join pg_namespace n on n.oid=t.typnamespace
where n.nspname='public'
  and t.typname='match_status'
order by e.enumsortorder;
-- EXPECT exactly: scheduled, live, completed, abandoned, cancelled.

-- 16. Official RLS no longer depends on the misleading old setup helper.
select
  policyname,
  qual,
  with_check
from pg_policies
where schemaname='public'
  and tablename='match_officials'
  and policyname='match_officials_write_organizers';
-- EXPECT policy text contains match.official.assign and not is_team_captain.

select
  to_regprocedure('public.is_team_captain(uuid)') is null
    as misleading_is_team_captain_removed;
-- EXPECT: true.
