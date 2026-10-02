-- ==============================================================================
-- Match Day Tournament Structure, Reverse Graph Integrity & Revision Test Suite
-- ==============================================================================
-- Committed permanent regression test suite for Phase 4 & Phase 4.2.
-- Verifies:
--   1. Enum definitions and table structure
--   2. Entry Revision monotonicity and caller-mutation denial
--   3. Automatic DrawRevision entry_revision snapshotting
--   4. FixtureSlot source shape integrity (valid and invalid shapes)
--   5. Forward scope integrity (cross-tournament & cross-stage protection)
--   6. Reverse graph integrity (Stage sequence updates vs incoming/outgoing dependencies)
--   7. Published Stage structural field protection (immutability of structure, mutability of state/name)
--   8. Published StageEntry structural protection (whole-field deletion block, immutable seed/group, mutable status)
--   9. Published Round structural protection (immutable round_number/group, mutable label)
--  10. Published Group structural protection (immutable sequence, mutable name)
--  11. Fixture & Slot insert/re-parenting to published draw denial
--  12. Published Fixture & Slot topology protection (immutable topology, mutable operational fields)
--  13. DrawRevision full audit immutability on publication and supersession
--  14. Composite foreign key ON DELETE behavior (SET NULL on group_id, RESTRICT on source_stage)
--  15. Data API RLS direct mutation denial
--  16. Capability separation (draw.manage vs draw.publish vs fixture.schedule)
-- ==============================================================================

begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(64);

-- -----------------------------------------------------------------------------
-- 1. Enums & Tables
-- -----------------------------------------------------------------------------
select enum_has_labels(
  'public',
  'tournament_draw_revision_status',
  array['draft', 'published', 'superseded'],
  'draw revision status enum has exactly draft, published, superseded'
);

select enum_has_labels(
  'public',
  'fixture_slot_side',
  array['A', 'B'],
  'fixture slot side has exactly A, B'
);

select enum_has_labels(
  'public',
  'fixture_slot_source_type',
  array['entry', 'seed', 'fixture_winner', 'fixture_loser', 'group_rank', 'stage_rank', 'bye'],
  'fixture slot source type has all canonical source types including bye and rank'
);

select has_table('public', 'tournament_stages', 'tournament_stages table exists');
select has_table('public', 'tournament_groups', 'tournament_groups table exists');
select has_table('public', 'tournament_stage_entries', 'tournament_stage_entries table exists');
select has_table('public', 'tournament_rounds', 'tournament_rounds table exists');
select has_table('public', 'tournament_draw_revisions', 'tournament_draw_revisions table exists');
select has_table('public', 'tournament_fixtures', 'tournament_fixtures table exists');
select has_table('public', 'tournament_fixture_slots', 'tournament_fixture_slots table exists');

-- -----------------------------------------------------------------------------
-- 2. Setup Test Data (Tournaments, Teams, Users)
-- -----------------------------------------------------------------------------
insert into public.profiles (user_id, username, display_name)
values
  ('00000000-0000-0000-0000-000000000001', 'owner_user', 'Tournament Owner'),
  ('00000000-0000-0000-0000-000000000002', 'manager_user', 'Tournament Manager'),
  ('00000000-0000-0000-0000-000000000003', 'unrelated_user', 'Unrelated User')
on conflict (user_id) do nothing;

insert into public.tournaments (
  tournament_id, tournament_name, tournament_type, sport_id,
  publication_state, registration_state, entry_state, competition_state, termination_state,
  owner_user_id
)
values
  ('a1000000-0000-0000-0000-000000000001', 'Tournament Alpha', 'knockout', 'cricket', 'published', 'closed', 'locked', 'in_progress', 'none', '00000000-0000-0000-0000-000000000001'),
  ('b2000000-0000-0000-0000-000000000002', 'Tournament Beta',  'knockout', 'cricket', 'published', 'closed', 'locked', 'in_progress', 'none', '00000000-0000-0000-0000-000000000001');

insert into public.teams (team_id, team_name, team_type, created_by)
values
  ('11000000-0000-0000-0000-000000000001', 'Alpha Lions', 'club', '00000000-0000-0000-0000-000000000001'),
  ('11000000-0000-0000-0000-000000000002', 'Alpha Tigers', 'club', '00000000-0000-0000-0000-000000000001'),
  ('11000000-0000-0000-0000-000000000003', 'Beta Eagles', 'club', '00000000-0000-0000-0000-000000000001');

-- -----------------------------------------------------------------------------
-- 3. Entry Revision Monotonicity & Database Protection
-- -----------------------------------------------------------------------------
select is(
  (select entry_revision from public.tournaments where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  1,
  'tournament entry_revision initializes to 1'
);

-- Direct client update of entry_revision is rejected
select throws_ok(
  $$ update public.tournaments set entry_revision = 999 where tournament_id = 'a1000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'direct mutation of tournament entry_revision is rejected'
);

-- Active entry inserts increment entry_revision
insert into public.tournament_entries (entry_id, tournament_id, team_id, status)
values ('e1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-000000000001', 'active');

select is(
  (select entry_revision from public.tournaments where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  2,
  'inserting first active entry advances entry_revision to 2'
);

insert into public.tournament_entries (entry_id, tournament_id, team_id, status)
values ('e1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-000000000002', 'active');

select is(
  (select entry_revision from public.tournaments where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  3,
  'inserting second active entry advances entry_revision to 3'
);

-- Beta entry insert isolates to Beta
insert into public.tournament_entries (entry_id, tournament_id, team_id, status)
values ('e2000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-000000000003', 'active');

select is(
  (select entry_revision from public.tournaments where tournament_id = 'b2000000-0000-0000-0000-000000000002'),
  2,
  'Beta entry insert advances Beta entry_revision independently'
);

-- Withdrawal and reactivation advance revision monotonically
update public.tournament_entries
set status = 'withdrawn', withdrawn_at = now()
where entry_id = 'e1000000-0000-0000-0000-000000000002';

select is(
  (select entry_revision from public.tournaments where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  4,
  'withdrawing entry advances entry_revision to 4'
);

update public.tournament_entries
set status = 'active', withdrawn_at = null
where entry_id = 'e1000000-0000-0000-0000-000000000002';

select is(
  (select entry_revision from public.tournaments where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  5,
  'reactivating entry advances entry_revision to 5'
);

-- -----------------------------------------------------------------------------
-- 4. Automatic DrawRevision Entry Revision Snapshotting
-- -----------------------------------------------------------------------------
insert into public.tournament_stages (
  stage_id, tournament_id, sequence, name, competition_format, state
)
values
  ('15000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 1, 'Group Stage', 'round_robin', 'active'),
  ('15000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 2, 'Playoffs', 'single_elimination', 'pending'),
  ('15000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 3, 'Finals Stage', 'single_elimination', 'pending');

-- Caller passes forged based_on_entry_revision = 999; DB must stamp current tournament revision (5)
insert into public.tournament_draw_revisions (
  draw_revision_id, stage_id, tournament_id, revision_number,
  status, based_on_entry_revision, created_by
)
values (
  '25000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001',
  1, 'draft', 999, '00000000-0000-0000-0000-000000000001'
);

select is(
  (select based_on_entry_revision from public.tournament_draw_revisions where draw_revision_id = '25000000-0000-0000-0000-000000000001'),
  5,
  'database stamps canonical tournament entry_revision overriding caller-supplied value'
);

-- -----------------------------------------------------------------------------
-- 5. Setup Groups, StageEntries, Rounds & Fixture Topology
-- -----------------------------------------------------------------------------
insert into public.tournament_groups (
  group_id, stage_id, tournament_id, sequence, name
)
values
  ('30000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 1, 'Group A'),
  ('30000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 2, 'Group B');

insert into public.tournament_stage_entries (
  stage_entry_id, stage_id, entry_id, tournament_id, group_id, seed, status
)
values
  ('1e000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 1, 'active'),
  ('1e000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 2, 'active');

insert into public.tournament_stage_entries (
  stage_entry_id, stage_id, entry_id, tournament_id, source_stage_id, status
)
values
  ('2e000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'e1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000001', 'active'),
  ('2e000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-000000000002', 'e1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000001', 'active');

insert into public.tournament_rounds (
  round_id, stage_id, tournament_id, round_number, label
)
values
  ('20000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 1, 'Semi-finals'),
  ('20000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 2, 'Final'),
  ('20000000-0000-0000-0000-000000000003', '15000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 3, 'Third Place Playoff');

insert into public.tournament_fixtures (
  fixture_id, tournament_id, stage_id, round_id, draw_revision_id, fixture_number, state
)
values
  ('f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', '25000000-0000-0000-0000-000000000001', 1, 'ready'),
  ('f1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', '25000000-0000-0000-0000-000000000001', 2, 'ready'),
  ('f1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '25000000-0000-0000-0000-000000000001', 1, 'unresolved'),
  ('f1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', '25000000-0000-0000-0000-000000000001', 1, 'unresolved');

-- -----------------------------------------------------------------------------
-- 6. Slot Source Shape & Forward Integrity Tests
-- -----------------------------------------------------------------------------
-- SF1: Group Rank from Stage 1
insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type, source_group_id, source_rank
)
values
  ('f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'A', 'group_rank', '30000000-0000-0000-0000-000000000001', 1),
  ('f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'B', 'group_rank', '30000000-0000-0000-0000-000000000002', 1);

-- SF2: Direct Entry A and BYE B
insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type, source_entry_id
)
values
  ('f1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'A', 'entry', 'e1000000-0000-0000-0000-000000000001');

insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type
)
values
  ('f1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'B', 'bye');

-- Final: Winner(SF1) and Winner(SF2)
insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type, source_fixture_id
)
values
  ('f1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'A', 'fixture_winner', 'f1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'B', 'fixture_winner', 'f1000000-0000-0000-0000-000000000002');

-- Third Place: Loser(SF1) and Loser(SF2)
insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type, source_fixture_id
)
values
  ('f1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'A', 'fixture_loser', 'f1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002', 'B', 'fixture_loser', 'f1000000-0000-0000-0000-000000000002');

select is(
  (select count(*) from public.tournament_fixture_slots where tournament_id = 'a1000000-0000-0000-0000-000000000001'),
  8::bigint,
  'fixture slots successfully populated with valid shapes and scopes'
);

-- Reject invalid source shape (group_rank without source_rank)
select throws_ok(
  $$ insert into public.tournament_fixture_slots (
       fixture_id, tournament_id, stage_id, side, source_type, source_group_id
     ) values (
       'f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002',
       'A', 'group_rank', '30000000-0000-0000-0000-000000000001'
     ) $$,
  '23514',
  null,
  'group_rank requires both source_group_id and source_rank'
);

-- Reject cross-tournament source entry
select throws_ok(
  $$ insert into public.tournament_fixture_slots (
       fixture_id, tournament_id, stage_id, side, source_type, source_entry_id
     ) values (
       'f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002',
       'A', 'entry', 'e2000000-0000-0000-0000-000000000003'
     ) $$,
  '22000',
  null,
  'cross-tournament source entry is rejected'
);

-- -----------------------------------------------------------------------------
-- 7. Reverse Scope Integrity (Stage Sequence Update Checks)
-- -----------------------------------------------------------------------------
-- Stage 1 sequence = 1, Stage 2 sequence = 2.
-- Stage 2 has StageEntry referencing Stage 1 as source_stage_id,
-- and FixtureSlot sourcing Group A (Stage 1).
-- Attempting to move Stage 1 sequence to 3 violates sequence precedence (1 < 2 becomes 3 < 2 -> INVALID).
select throws_ok(
  $$ update public.tournament_stages set sequence = 3 where stage_id = '15000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'moving upstream stage sequence past downstream dependent stage is rejected'
);

-- Attempting to move Stage 2 sequence down to 1 violates sequence precedence (must be > Stage 1 sequence)
select throws_ok(
  $$ update public.tournament_stages set sequence = 1 where stage_id = '15000000-0000-0000-0000-000000000002' $$,
  '22000',
  null,
  'moving downstream stage sequence before upstream feeder stage is rejected'
);

-- -----------------------------------------------------------------------------
-- 8. Publish the Draw Revision
-- -----------------------------------------------------------------------------
update public.tournament_draw_revisions
set status = 'published',
    plan_snapshot = '{"fixtures_count": 4}'::jsonb,
    published_at = now(),
    published_by = '00000000-0000-0000-0000-000000000001'
where draw_revision_id = '25000000-0000-0000-0000-000000000001';

select is(
  (select status from public.tournament_draw_revisions where draw_revision_id = '25000000-0000-0000-0000-000000000001'),
  'published'::public.tournament_draw_revision_status,
  'draw revision successfully published'
);

-- -----------------------------------------------------------------------------
-- 9. Published Stage Structural Field Protection
-- -----------------------------------------------------------------------------
-- Structural fields frozen once draw is published
select throws_ok(
  $$ update public.tournament_stages set sequence = 5 where stage_id = '15000000-0000-0000-0000-000000000002' $$,
  '22000',
  null,
  'cannot alter sequence of stage with published draw'
);

select throws_ok(
  $$ update public.tournament_stages set competition_format = 'double_elimination' where stage_id = '15000000-0000-0000-0000-000000000002' $$,
  '22000',
  null,
  'cannot alter competition_format of stage with published draw'
);

select throws_ok(
  $$ delete from public.tournament_stages where stage_id = '15000000-0000-0000-0000-000000000002' $$,
  '22000',
  null,
  'cannot delete stage with published draw'
);

-- Cosmetic name and operational state remain editable
select lives_ok(
  $$ update public.tournament_stages set name = 'Championship Playoffs', state = 'active' where stage_id = '15000000-0000-0000-0000-000000000002' $$,
  'stage name and lifecycle state remain editable after publication'
);

-- -----------------------------------------------------------------------------
-- 10. Published StageEntry Protection (Whole-Field Deletion Block & Field Matrix)
-- -----------------------------------------------------------------------------
-- Delete is blocked for ANY stage entry in published stage, even without direct slot reference
select throws_ok(
  $$ delete from public.tournament_stage_entries where stage_entry_id = '2e000000-0000-0000-0000-000000000002' $$,
  '22000',
  null,
  'cannot delete stage entry belonging to published stage'
);

-- Structural identity/placement fields are frozen
select throws_ok(
  $$ update public.tournament_stage_entries set seed = 99 where stage_entry_id = '2e000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter seed of stage entry in published stage'
);

select throws_ok(
  $$ update public.tournament_stage_entries set group_id = '30000000-0000-0000-0000-000000000001' where stage_entry_id = '2e000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter group_id of stage entry in published stage'
);

-- Operational progression status remains editable
select lives_ok(
  $$ update public.tournament_stage_entries set status = 'eliminated' where stage_entry_id = '2e000000-0000-0000-0000-000000000001' $$,
  'stage entry competition progression status remains editable after publication'
);

-- -----------------------------------------------------------------------------
-- 11. Published Round Structural Protection
-- -----------------------------------------------------------------------------
select throws_ok(
  $$ update public.tournament_rounds set round_number = 99 where round_id = '20000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter round_number of round with published fixtures'
);

select throws_ok(
  $$ delete from public.tournament_rounds where round_id = '20000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot delete round with published fixtures'
);

select lives_ok(
  $$ update public.tournament_rounds set label = 'Semi Finals - Best of 3' where round_id = '20000000-0000-0000-0000-000000000001' $$,
  'round label remains editable after publication'
);

-- -----------------------------------------------------------------------------
-- 12. Published Group Structural Protection
-- -----------------------------------------------------------------------------
select throws_ok(
  $$ update public.tournament_groups set stage_id = '15000000-0000-0000-0000-000000000003' where group_id = '30000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot move group to a different stage'
);

select lives_ok(
  $$ update public.tournament_groups set name = 'Group A - Platinum' where group_id = '30000000-0000-0000-0000-000000000001' $$,
  'group name remains editable'
);

-- Group 1 is referenced by published fixture slot (SF1 Group A Rank 1), cannot be deleted
select throws_ok(
  $$ delete from public.tournament_groups where group_id = '30000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot delete group referenced by published fixture slot'
);

-- -----------------------------------------------------------------------------
-- 13. Published Fixture Protection & Re-parenting Prevention
-- -----------------------------------------------------------------------------
-- Cannot insert new fixture into published draw revision
select throws_ok(
  $$ insert into public.tournament_fixtures (
       tournament_id, stage_id, round_id, draw_revision_id, fixture_number
     ) values (
       'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000002',
       '20000000-0000-0000-0000-000000000001', '25000000-0000-0000-0000-000000000001', 99
     ) $$,
  '22000',
  null,
  'cannot add fixture to a published draw revision'
);

-- Create a draft draw revision to test re-parenting
insert into public.tournament_draw_revisions (
  draw_revision_id, stage_id, tournament_id, revision_number,
  status, created_by
)
values (
  '25000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001',
  1, 'draft', '00000000-0000-0000-0000-000000000001'
);

insert into public.tournament_rounds (
  round_id, stage_id, tournament_id, round_number, label
)
values
  ('20000000-0000-0000-0000-000000000004', '15000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 1, 'Final Round');

insert into public.tournament_fixtures (
  fixture_id, tournament_id, stage_id, round_id, draw_revision_id, fixture_number
)
values
  ('f2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000003',
   '20000000-0000-0000-0000-000000000004', '25000000-0000-0000-0000-000000000002', 1);

-- Re-parenting draft fixture to published draw revision is rejected
select throws_ok(
  $$ update public.tournament_fixtures
     set draw_revision_id = '25000000-0000-0000-0000-000000000001'
     where fixture_id = 'f2000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot move fixture into a published draw revision'
);

-- Topology mutation of published fixture rejected
select throws_ok(
  $$ update public.tournament_fixtures set fixture_number = 77 where fixture_id = 'f1000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter topology of published fixture'
);

select throws_ok(
  $$ delete from public.tournament_fixtures where fixture_id = 'f1000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot delete published fixture'
);

-- Operational fields of published fixture remain mutable
select lives_ok(
  $$ update public.tournament_fixtures
     set scheduled_start_time = now() + interval '2 days',
         state = 'in_progress'
     where fixture_id = 'f1000000-0000-0000-0000-000000000001' $$,
  'published fixture operational fields (schedule, state) remain mutable'
);

-- -----------------------------------------------------------------------------
-- 14. Published FixtureSlot Protection & Re-parenting Prevention
-- -----------------------------------------------------------------------------
-- Cannot insert slot into published fixture
select throws_ok(
  $$ insert into public.tournament_fixture_slots (
       fixture_id, tournament_id, stage_id, side, source_type
     ) values (
       'f1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
       '15000000-0000-0000-0000-000000000002', 'A', 'bye'
     ) $$,
  '22000',
  null,
  'cannot add fixture slot to a published draw revision'
);

-- Draft slot in draft fixture f2000000...
insert into public.tournament_fixture_slots (
  fixture_id, tournament_id, stage_id, side, source_type
)
values
  ('f2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
   '15000000-0000-0000-0000-000000000003', 'A', 'bye');

-- Re-parenting draft slot to published fixture is rejected
select throws_ok(
  $$ update public.tournament_fixture_slots
     set fixture_id = 'f1000000-0000-0000-0000-000000000001'
     where fixture_id = 'f2000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot move fixture slot into a published fixture'
);

-- Topology mutation of published slot rejected
select throws_ok(
  $$ update public.tournament_fixture_slots
     set source_type = 'bye', source_group_id = null, source_rank = null
     where fixture_id = 'f1000000-0000-0000-0000-000000000001' and side = 'A' $$,
  '22000',
  null,
  'cannot alter topology of published fixture slot'
);

select throws_ok(
  $$ delete from public.tournament_fixture_slots
     where fixture_id = 'f1000000-0000-0000-0000-000000000001' and side = 'A' $$,
  '22000',
  null,
  'cannot delete published fixture slot'
);

-- Operational fields of published fixture slot remain mutable (resolution)
select lives_ok(
  $$ update public.tournament_fixture_slots
     set resolved_entry_id = 'e1000000-0000-0000-0000-000000000001',
         resolved_at = now(),
         resolution_reason = 'Group A Rank 1 confirmed'
     where fixture_id = 'f1000000-0000-0000-0000-000000000001' and side = 'A' $$,
  'published fixture slot resolution fields remain mutable'
);

-- -----------------------------------------------------------------------------
-- 15. DrawRevision Full Audit Immutability on Publication and Supersession
-- -----------------------------------------------------------------------------
-- Transition to superseded is permitted
select lives_ok(
  $$ update public.tournament_draw_revisions
     set status = 'superseded'
     where draw_revision_id = '25000000-0000-0000-0000-000000000001' $$,
  'published draw revision can transition status to superseded'
);

-- Audit fields cannot be altered on superseded revision
select throws_ok(
  $$ update public.tournament_draw_revisions
     set created_by = '00000000-0000-0000-0000-000000000002'
     where draw_revision_id = '25000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter audit created_by on superseded draw revision'
);

select throws_ok(
  $$ update public.tournament_draw_revisions
     set revision_reason = 'tampered'
     where draw_revision_id = '25000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter revision_reason on superseded draw revision'
);

select throws_ok(
  $$ update public.tournament_draw_revisions
     set based_on_entry_revision = 99
     where draw_revision_id = '25000000-0000-0000-0000-000000000001' $$,
  '22000',
  null,
  'cannot alter based_on_entry_revision on superseded draw revision'
);

-- -----------------------------------------------------------------------------
-- 16. Composite Foreign Key ON DELETE Behavior
-- -----------------------------------------------------------------------------
-- Stage 3 has draft Group and draft Round
insert into public.tournament_groups (
  group_id, stage_id, tournament_id, sequence, name
)
values
  ('30000000-0000-0000-0000-000000000003', '15000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 1, 'Draft Group');

insert into public.tournament_stage_entries (
  stage_entry_id, stage_id, entry_id, tournament_id, group_id, status
)
values
  ('3e000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000003', 'e1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 'active');

update public.tournament_rounds
set group_id = '30000000-0000-0000-0000-000000000003'
where round_id = '20000000-0000-0000-0000-000000000004';

-- Deleting draft group sets group_id to null on stage entry and round without nulling stage_id
delete from public.tournament_groups where group_id = '30000000-0000-0000-0000-000000000003';

select is(
  (select group_id from public.tournament_stage_entries where stage_entry_id = '3e000000-0000-0000-0000-000000000001'),
  null::uuid,
  'group deletion nulls group_id on stage entry'
);

select is(
  (select stage_id from public.tournament_stage_entries where stage_entry_id = '3e000000-0000-0000-0000-000000000001'),
  '15000000-0000-0000-0000-000000000003'::uuid,
  'stage_id remains intact on stage entry after group deletion'
);

select is(
  (select group_id from public.tournament_rounds where round_id = '20000000-0000-0000-0000-000000000004'),
  null::uuid,
  'group deletion nulls group_id on round'
);

select is(
  (select stage_id from public.tournament_rounds where round_id = '20000000-0000-0000-0000-000000000004'),
  '15000000-0000-0000-0000-000000000003'::uuid,
  'stage_id remains intact on round after group deletion'
);

-- fk_stage_entries_source_stage_tournament RESTRICT test:
-- Create stages 4 and 5 in Beta with no groups. Stage 5 references Stage 4 as source_stage_id.
insert into public.tournament_stages (
  stage_id, tournament_id, sequence, name, competition_format, state
) values
  ('15000000-0000-0000-0000-000000000004', 'b2000000-0000-0000-0000-000000000002', 1, 'Beta Prelim', 'single_elimination', 'pending'),
  ('15000000-0000-0000-0000-000000000005', 'b2000000-0000-0000-0000-000000000002', 2, 'Beta Main', 'single_elimination', 'pending');

insert into public.tournament_stage_entries (
  stage_entry_id, stage_id, entry_id, tournament_id, source_stage_id, status
) values (
  '4e000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000005',
  'e2000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000002',
  '15000000-0000-0000-0000-000000000004', 'active'
);

select throws_ok(
  $$ delete from public.tournament_stages where stage_id = '15000000-0000-0000-0000-000000000004' $$,
  '23503',
  null,
  'deleting source stage referenced by stage entries is restricted by foreign key'
);

-- -----------------------------------------------------------------------------
-- 17. Direct Data API RLS Mutation Denial
-- -----------------------------------------------------------------------------
set local role authenticated;
set local "request.jwt.claims" = '{"sub": "00000000-0000-0000-0000-000000000003"}';

select throws_ok(
  $$ insert into public.tournament_stages (tournament_id, sequence, name, competition_format)
     values ('a1000000-0000-0000-0000-000000000001', 99, 'Hacked Stage', 'single_elimination') $$,
  '42501',
  null,
  'direct client insert on tournament_stages is denied under RLS'
);

select throws_ok(
  $$ insert into public.tournament_fixtures (tournament_id, stage_id, round_id, draw_revision_id, fixture_number)
     values ('a1000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-000000000003',
             '20000000-0000-0000-0000-000000000004', '25000000-0000-0000-0000-000000000002', 88) $$,
  '42501',
  null,
  'direct client insert on tournament_fixtures is denied under RLS'
);

-- Owner directly attempting mutation via Data API is also denied (command path required)
set local "request.jwt.claims" = '{"sub": "00000000-0000-0000-0000-000000000001"}';

select throws_ok(
  $$ insert into public.tournament_stages (tournament_id, sequence, name, competition_format)
     values ('a1000000-0000-0000-0000-000000000001', 99, 'Owner Direct Stage', 'single_elimination') $$,
  '42501',
  null,
  'owner direct client insert on stages is denied under RLS'
);

reset role;

-- -----------------------------------------------------------------------------
-- 18. Capability Separation (draw.manage vs draw.publish vs fixture.schedule)
-- -----------------------------------------------------------------------------
insert into public.grants (subject_id, scope, entity_id, permission_key)
values
  ('00000000-0000-0000-0000-000000000002', 'tournament', 'a1000000-0000-0000-0000-000000000001', 'tournament.draw.manage'),
  ('00000000-0000-0000-0000-000000000002', 'tournament', 'a1000000-0000-0000-0000-000000000001', 'tournament.fixture.schedule');

set local role authenticated;
set local "request.jwt.claims" = '{"sub": "00000000-0000-0000-0000-000000000002"}';

select ok(
  public.can('tournament', 'a1000000-0000-0000-0000-000000000001', 'tournament.draw.manage'),
  'manager has tournament.draw.manage capability'
);

select ok(
  not public.can('tournament', 'a1000000-0000-0000-0000-000000000001', 'tournament.draw.publish'),
  'manager lacks tournament.draw.publish capability without explicit grant'
);

select ok(
  public.can('tournament', 'a1000000-0000-0000-0000-000000000001', 'tournament.fixture.schedule'),
  'manager has tournament.fixture.schedule capability'
);

-- User with fixture.schedule capability cannot directly mutate fixture topology via PostgREST
update public.tournament_fixtures set fixture_number = 77 where fixture_id = 'f1000000-0000-0000-0000-000000000001';

select is(
  (select fixture_number from public.tournament_fixtures where fixture_id = 'f1000000-0000-0000-0000-000000000001'),
  1,
  'user with fixture.schedule cannot mutate fixture topology via Data API'
);

reset role;

-- -----------------------------------------------------------------------------
-- Finish
-- -----------------------------------------------------------------------------
select * from finish();

rollback;
