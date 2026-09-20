-- =============================================================================
-- Matchday Phase 3A verification
-- =============================================================================

-- 1. Shared matches must contain NO Cricket-only legacy columns.
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'matches'
  and column_name in (
    'match_format',
    'format',
    'toss_won_by',
    'toss_decision',
    'toss_face',
    'toss_recorded_at',
    'start_phase',
    'openers_submitted_by',
    'openers_submitted_at',
    'scoring_mode',
    'revised_conditions',
    'result',
    'result_summary',
    'player_of_the_match_id',
    'team_a_captain',
    'team_b_captain'
  )
order by column_name;

-- EXPECT: 0 rows.


-- 2. Shared match_players must contain identity/snapshot facts only.
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'match_players'
  and column_name in (
    'role',
    'is_in_playing_xi',
    'batting_order'
  );

-- EXPECT: 0 rows.


-- 3. Shared match_teams must contain no Cricket role/order fields.
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'match_teams'
  and column_name in (
    'is_batting_first',
    'captain_player_id',
    'keeper_player_id'
  );

-- EXPECT: 0 rows.


-- 4. Expected final shared shell.
select
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'matches'
order by ordinal_position;


-- 5. Expected final shared participant shell.
select
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'match_players'
order by ordinal_position;


-- 6. Canonical Cricket aggregate must still expose the Flutter wire shape.
select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'cricket_match_details'
  and column_name in (
    'format',
    'toss_won_by',
    'toss_decision',
    'start_phase',
    'result',
    'team_a_captain',
    'team_b_captain'
  )
order by column_name;

-- EXPECT: all 7 rows.


-- 7. No Cricket match may be missing its child.
select m.match_id
from public.matches m
left join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket'
  and cm.match_id is null;

-- EXPECT: 0 rows.


-- 8. No Cricket participant may be missing its child state.
select
  mp.match_player_id,
  mp.match_id
from public.match_players mp
join public.matches m
  on m.match_id = mp.match_id
left join public.cricket_match_players cmp
  on cmp.match_player_id = mp.match_player_id
where m.sport_id = 'cricket'
  and cmp.match_player_id is null;

-- EXPECT: 0 rows.


-- 9. Parent generic winner must still equal canonical Cricket result winner.
select
  m.match_id,
  m.winner_id,
  nullif(
    cm.result->>'winner_team_id',
    ''
  )::uuid as cricket_winner
from public.matches m
join public.cricket_matches cm
  on cm.match_id = m.match_id
where m.sport_id = 'cricket'
  and m.winner_id is distinct from
      nullif(
        cm.result->>'winner_team_id',
        ''
      )::uuid;

-- EXPECT: 0 rows.


-- 10. Old API and mirrors must be absent.
select
  to_regprocedure('public.list_my_matches()')
    as old_list_rpc,
  to_regclass('public.cricket_match_sides')
    as old_side_extension;

-- EXPECT: both null.


select
  c.relname as table_name,
  t.tgname
from pg_trigger t
join pg_class c
  on c.oid = t.tgrelid
join pg_namespace n
  on n.oid = c.relnamespace
where n.nspname = 'public'
  and not t.tgisinternal
  and t.tgname in (
    'matches_sync_cricket_extension',
    'match_players_sync_cricket_extension',
    'match_teams_sync_cricket_extension'
  );

-- EXPECT: 0 rows.


-- 11. Canonical public read view must be SECURITY INVOKER.
select
  c.relname,
  c.reloptions
from pg_class c
join pg_namespace n
  on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'cricket_match_details';

-- EXPECT reloptions to contain security_invoker=true.


-- 12. Search currently-installed function bodies for legacy column references.
-- This is a post-migration smoke detector. Review any returned function:
-- historical comments are harmless; executable SQL references are not.
select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
  and (
    pg_get_functiondef(p.oid) ~
      '\m(team_a_captain|team_b_captain|start_phase|openers_submitted_by|openers_submitted_at|revised_conditions)\M'
    or pg_get_functiondef(p.oid) ~
      '\m(is_in_playing_xi|captain_player_id|keeper_player_id|is_batting_first)\M'
  )
order by p.proname;

-- EXPECT:
-- Ideally 0 executable references.
-- If a function is returned, inspect pg_get_functiondef(...) before release.


-- 13. Core RPCs/views required by the app.
select
  to_regclass('public.cricket_match_details') is not null
    as cricket_view,
  to_regprocedure('public.list_my_cricket_matches()') is not null
    as list_rpc,
  to_regprocedure('public.complete_cricket_match(uuid,text)') is not null
    as complete_rpc,
  to_regprocedure('public.record_toss_winner(uuid,uuid,character)') is not null
    as toss_winner_rpc,
  to_regprocedure('public.record_toss_decision(uuid,public.toss_decision)') is not null
    as toss_decision_rpc;

-- EXPECT: all true.
