-- Match runtime participant and snapshot invariants.
-- Run against a disposable local database after `supabase db reset`.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(14);

insert into public.teams (team_id, team_name, team_type, sport_id)
values
  ('11000000-0000-4000-8000-000000000001', 'Runtime Alpha', 'club', 'cricket'),
  ('11000000-0000-4000-8000-000000000002', 'Runtime Bravo', 'club', 'cricket'),
  ('11000000-0000-4000-8000-000000000003', 'Runtime Cup XI', 'club', 'cricket');

insert into public.unclaimed_players (unclaimed_id, sport_id, display_name)
values
  ('12000000-0000-4000-8000-000000000001', 'cricket', 'Alpha Active'),
  ('12000000-0000-4000-8000-000000000002', 'cricket', 'Alpha Inactive'),
  ('12000000-0000-4000-8000-000000000003', 'cricket', 'Bravo Active'),
  ('12000000-0000-4000-8000-000000000004', 'cricket', 'Alpha Late'),
  ('12000000-0000-4000-8000-000000000005', 'cricket', 'Alpha After Toss'),
  ('12000000-0000-4000-8000-000000000006', 'cricket', 'Cup Selected'),
  ('12000000-0000-4000-8000-000000000007', 'cricket', 'Cup Omitted');

insert into public.team_members (
  team_id, unclaimed_id, status, in_squad, left_at
)
values
  ('11000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000001', 'active', true, null),
  ('11000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000002', 'inactive', true, now()),
  ('11000000-0000-4000-8000-000000000002', '12000000-0000-4000-8000-000000000003', 'active', true, null),
  ('11000000-0000-4000-8000-000000000003', '12000000-0000-4000-8000-000000000006', 'active', true, null),
  ('11000000-0000-4000-8000-000000000003', '12000000-0000-4000-8000-000000000007', 'active', true, null);

insert into public.matches (match_id, match_type, sport_id, status)
values ('13000000-0000-4000-8000-000000000001', 'friendly', 'cricket', 'scheduled');

update public.match_teams
set team_id = case team_side
      when 'team_a' then '11000000-0000-4000-8000-000000000001'::uuid
      else '11000000-0000-4000-8000-000000000002'::uuid
    end,
    team_name = case team_side
      when 'team_a' then 'Runtime Alpha'
      else 'Runtime Bravo'
    end
where match_id = '13000000-0000-4000-8000-000000000001';

insert into public.cricket_matches (match_id, setup_side)
values ('13000000-0000-4000-8000-000000000001', 'team_a');

-- Production observes this at transaction commit. Force the deferred trigger
-- now so the test can inspect its committed-shape effect inside the rollback.
set constraints cricket_matches_materialize_participants immediate;

select is(
  (select count(*)::int from public.match_players where match_id = '13000000-0000-4000-8000-000000000001'),
  2,
  'creating the cricket fixture snapshots both active squads'
);

select is(
  (select count(*)::int from public.match_players where unclaimed_id = '12000000-0000-4000-8000-000000000002'),
  0,
  'inactive members are excluded'
);

select public.sync_match_participants('13000000-0000-4000-8000-000000000001');
select public.sync_match_participants('13000000-0000-4000-8000-000000000001');

select is(
  (select count(*)::int from public.match_players where match_id = '13000000-0000-4000-8000-000000000001'),
  2,
  'participant synchronization is idempotent'
);

insert into public.team_members (team_id, unclaimed_id, status, in_squad)
values ('11000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000004', 'active', true);

select is(
  (select count(*)::int from public.match_players where unclaimed_id = '12000000-0000-4000-8000-000000000004'),
  1,
  'a pre-toss roster addition is synchronized exactly once'
);

update public.cricket_matches
set roster_frozen_at = now()
where match_id = '13000000-0000-4000-8000-000000000001';

insert into public.team_members (team_id, unclaimed_id, status, in_squad)
values ('11000000-0000-4000-8000-000000000001', '12000000-0000-4000-8000-000000000005', 'active', true);

select is(
  (select count(*)::int from public.match_players where unclaimed_id = '12000000-0000-4000-8000-000000000005'),
  0,
  'a post-toss roster addition does not mutate the match snapshot'
);

insert into public.tournaments (
  tournament_id, tournament_name, tournament_type, sport_id, status
)
values (
  '14000000-0000-4000-8000-000000000001', 'Runtime Cup', 'knockout', 'cricket', 'upcoming'
);

insert into public.tournament_teams (
  tournament_id, team_id, status, squad, decided_at
)
values (
  '14000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000003',
  'approved',
  array['12000000-0000-4000-8000-000000000006'::uuid],
  now()
);

insert into public.matches (
  match_id, tournament_id, match_type, sport_id, status
)
values (
  '13000000-0000-4000-8000-000000000002',
  '14000000-0000-4000-8000-000000000001',
  'tournament', 'cricket', 'scheduled'
);

update public.match_teams
set team_id = '11000000-0000-4000-8000-000000000003',
    team_name = 'Runtime Cup XI'
where match_id = '13000000-0000-4000-8000-000000000002'
  and team_side = 'team_a';

insert into public.cricket_matches (match_id)
values ('13000000-0000-4000-8000-000000000002');

set constraints cricket_matches_materialize_participants immediate;

select is(
  (select count(*)::int from public.match_players where match_id = '13000000-0000-4000-8000-000000000002'),
  1,
  'a tournament fixture uses only the registered squad'
);

select is(
  (select source::text from public.match_players where match_id = '13000000-0000-4000-8000-000000000002'),
  'tournament_squad',
  'tournament participants record their provenance'
);

select is(
  (select state_revision::int from public.cricket_matches where match_id = '13000000-0000-4000-8000-000000000001'),
  0,
  'new cricket matches begin at revision zero'
);

select is(
  jsonb_array_length(public.get_match_room_snapshot('13000000-0000-4000-8000-000000000001')->'participants'),
  3,
  'the canonical snapshot contains both participant sides'
);

select ok(
  public.get_match_room_snapshot('13000000-0000-4000-8000-000000000001') ? 'capabilities',
  'the canonical snapshot includes caller capabilities'
);

-- Reproduce the production authorization shape: the batting team's owner has
-- `match.score` through a TEAM role, not through a direct MATCH grant. The
-- Match Room capability must use the same can_score_innings(...) predicate as
-- the command boundary or the UI hides a command that the server accepts.
insert into public.team_members (
  membership_id, team_id, user_id, status, in_squad
)
values (
  '16000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'active',
  true
);

-- The membership insert assigns the default player role. Owner and player are
-- intentionally mutually exclusive in the team-authority exclusion set, so
-- replace that default exactly as the owner-creation workflow does.
delete from public.team_member_roles
where membership_id = '16000000-0000-4000-8000-000000000001';

insert into public.team_member_roles (
  membership_id, scope, role_key, team_id, is_singleton, granted_by
)
values (
  '16000000-0000-4000-8000-000000000001',
  'team',
  'owner',
  '11000000-0000-4000-8000-000000000001',
  true,
  '00000000-0000-0000-0000-000000000001'
);

update public.cricket_matches
set phase = 'lineup',
    toss_won_by = 'team_a',
    toss_decision = 'bat',
    toss_recorded_at = now(),
    toss_recorded_by = '00000000-0000-0000-0000-000000000001'
where match_id = '13000000-0000-4000-8000-000000000001';

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

select is(
  public.get_match_room_snapshot('13000000-0000-4000-8000-000000000001')
    #>> '{capabilities,can_setup_innings}',
  'true',
  'the batting team owner receives the lineup capability through team RBAC'
);

delete from public.match_players
where match_id = '13000000-0000-4000-8000-000000000002';
select public.sync_match_participants('13000000-0000-4000-8000-000000000002');

select is(
  (select count(*)::int from public.match_players where match_id = '13000000-0000-4000-8000-000000000002'),
  1,
  'synchronization repairs an empty scheduled participant set'
);

select ok(
  not has_function_privilege('authenticated', 'public.sync_match_participants(uuid)', 'execute'),
  'clients cannot invoke internal participant synchronization'
);

select ok(
  has_function_privilege('authenticated', 'public.get_match_room_snapshot(uuid)', 'execute'),
  'authenticated clients can load the canonical Match Room snapshot'
);

select * from finish();
rollback;
