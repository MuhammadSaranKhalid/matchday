-- Canonical match-creation architecture regression tests.
--
-- These assertions intentionally inspect the installed RPC definitions. They
-- protect a schema boundary that PostgreSQL cannot validate when a PL/pgSQL
-- function is created: SQL statements inside the function body are parsed
-- only when that branch executes. That allowed acceptance functions to remain
-- deployable while still referencing columns removed from `public.matches`.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(14);

select ok(
  strpos(pg_get_functiondef(
    'public.accept_match_request(uuid,timestamptz,text,jsonb,text,uuid,uuid[],uuid)'::regprocedure
  ), 'team_a_id') = 0,
  'direct challenge acceptance does not write removed matches.team_a_id'
);

select ok(
  strpos(lower(pg_get_functiondef(
    'public.accept_match_request(uuid,timestamptz,text,jsonb,text,uuid,uuid[],uuid)'::regprocedure
  )), 'update public.match_teams') > 0,
  'direct challenge acceptance resolves the canonical match-team slots'
);

select ok(
  strpos(lower(pg_get_functiondef(
    'public.accept_match_request(uuid,timestamptz,text,jsonb,text,uuid,uuid[],uuid)'::regprocedure
  )), 'insert into public.match_players') = 0,
  'direct challenge acceptance delegates participant materialization'
);

select ok(
  strpos(pg_get_functiondef(
    'public.accept_pool_application(uuid,text)'::regprocedure
  ), 'team_a_id') = 0,
  'pool acceptance does not write removed matches.team_a_id'
);

select ok(
  strpos(lower(pg_get_functiondef(
    'public.accept_pool_application(uuid,text)'::regprocedure
  )), 'update public.match_teams') > 0,
  'pool acceptance resolves the canonical match-team slots'
);

select ok(
  strpos(lower(pg_get_functiondef(
    'public.accept_pool_application(uuid,text)'::regprocedure
  )), 'insert into public.match_players') = 0,
  'pool acceptance delegates participant materialization'
);

-- Exercise both RPCs against the standard local seed. These are deliberately
-- end-to-end assertions: a PL/pgSQL body may pass definition checks and still
-- fail only when PostgreSQL parses an executed statement.
create temporary table accepted_match_under_test (
  origin text primary key,
  match_id uuid not null
) on commit drop;

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

insert into accepted_match_under_test (origin, match_id)
select 'direct', public.accept_match_request(
  '90000000-0000-0000-0000-000000000001',
  null, null, null, 'architecture test', null, '{}'::uuid[], null
);

-- Participant synchronization is a deferred constraint trigger in production.
-- Make it observable inside this transaction before evaluating assertions.
set constraints cricket_matches_materialize_participants immediate;

select is(
  (select m.sport_id
   from accepted_match_under_test t
   join public.matches m on m.match_id = t.match_id
   where t.origin = 'direct'),
  'cricket',
  'direct acceptance creates the sport-neutral match shell'
);

select is(
  (select array_agg(mt.team_id order by mt.team_side)
   from accepted_match_under_test t
   join public.match_teams mt on mt.match_id = t.match_id
   where t.origin = 'direct'),
  array[
    '11111111-1111-1111-1111-111111111104'::uuid,
    '11111111-1111-1111-1111-111111111101'::uuid
  ],
  'direct acceptance resolves both canonical team slots'
);

select ok(
  (select count(*) > 0
   from accepted_match_under_test t
   join public.match_players mp on mp.match_id = t.match_id
   where t.origin = 'direct'),
  'direct acceptance materializes participants through the trigger'
);

select is(
  (select cm.setup_side
   from accepted_match_under_test t
   join public.cricket_matches cm on cm.match_id = t.match_id
   where t.origin = 'direct'),
  'team_a',
  'direct acceptance assigns the host as the initial setup side'
);

insert into public.match_pool_applications (
  application_id, request_id, applicant_team_id, applicant_user_id,
  applicant_xi, status
) values (
  '99000000-0000-4000-8000-000000000001',
  '90000000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111103',
  '00000000-0000-0000-0000-000000000002',
  '{}'::uuid[], 'pending'
);

insert into accepted_match_under_test (origin, match_id)
select 'pool', public.accept_pool_application(
  '99000000-0000-4000-8000-000000000001',
  'architecture test'
);

select is(
  (select m.sport_id
   from accepted_match_under_test t
   join public.matches m on m.match_id = t.match_id
   where t.origin = 'pool'),
  'cricket',
  'pool acceptance creates the sport-neutral match shell'
);

select is(
  (select array_agg(mt.team_id order by mt.team_side)
   from accepted_match_under_test t
   join public.match_teams mt on mt.match_id = t.match_id
   where t.origin = 'pool'),
  array[
    '11111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111103'::uuid
  ],
  'pool acceptance resolves host and applicant team slots'
);

select ok(
  (select count(*) > 0
   from accepted_match_under_test t
   join public.match_players mp on mp.match_id = t.match_id
   where t.origin = 'pool'),
  'pool acceptance materializes participants through the trigger'
);

select is(
  (select status
   from public.match_pool_applications
   where application_id = '99000000-0000-4000-8000-000000000001'),
  'accepted',
  'pool acceptance atomically closes the selected application'
);

select * from finish();
rollback;
