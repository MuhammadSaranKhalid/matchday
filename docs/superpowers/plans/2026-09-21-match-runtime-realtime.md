# Match Runtime and Realtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reliable two-phone match runtime in which every fixture has participants, toss and lineup state synchronize in realtime, the first innings starts atomically with all three on-field players, and scoring recovers from missed events without route flicker.

**Architecture:** PostgreSQL remains authoritative. Edge commands lock, authorize, mutate, and return a versioned canonical Match Room snapshot; Ably announces committed revisions to other devices. A route-scoped Flutter coordinator retains the last snapshot, reconciles after realtime gaps, and is the sole pre-live lifecycle owner, while the existing scoring outbox remains responsible for offline deliveries.

**Tech Stack:** Flutter, Dart, Riverpod 3.x code generation, Freezed/json_serializable, GoRouter, Supabase PostgreSQL/RLS, Deno TypeScript Edge Functions, Ably, flutter_test, PostgreSQL pgTAP-style SQL tests

**Spec:** `docs/superpowers/specs/2026-09-21-match-runtime-realtime-design.md`

## Global Constraints

- PostgreSQL is the canonical source of match state; Ably is a latency optimization only.
- Publish realtime events only after the database transaction commits.
- A match cannot become live without striker, non-striker, and bowler.
- Non-tournament rosters synchronize only before toss; tournament fixtures use their registered squad.
- A match-only participant may belong to either side and must not create a `team_members` row.
- Account claiming and permanent-roster promotion remain out of scope.
- Preserve stable `match_player_id` values and all existing match history.
- Only delivery operations are offline-queueable in V1; adding a participant requires connectivity.
- Do not replace cached match content with a full-screen loader during reconciliation.
- Create the schema migration with `supabase migration new match_runtime_realtime` before adding SQL; never fabricate migration history.
- Run Supabase security/performance advisors before finalizing database changes.

## Review Focus

- A roster member is added at the same moment toss is recorded: the toss transaction must include the member exactly once before freezing the roster.
- Two authorized devices submit the start command concurrently: one canonical live transition and one innings state must result.
- An Ably event is missed or delivered out of order: the client must retain current UI and reconcile by revision without navigating twice.
- A shared `match:<id>:state` channel has multiple listeners: cancelling one listener must not detach the other.
- A scorer has unsent local balls when a remote confirmed ball arrives: confirmed state must update beneath the FIFO pending projection without dropping or duplicating operations.

---

## File Structure

### Backend and database

- Create via CLI: the `supabase/migrations/*_match_runtime_realtime.sql` path printed by `supabase migration new match_runtime_realtime` — schema, participant invariants, revision, snapshot RPC, roster sync, backfill, grants, RLS, and retirement of redundant match broadcasts.
- Create: `supabase/tests/match_runtime_realtime_test.sql` — database invariants, race-safe transition preconditions, authorization, and backfill coverage.
- Create: `supabase/functions/cricket-match-action/commands/add_match_participant.ts` — online match-only participant command.
- Create: `supabase/functions/cricket-match-action/commands/start_match.ts` — atomic complete-trio first-innings start.
- Create: `supabase/functions/cricket-match-action/repositories/participant_repository.ts` — participant materialization/addition queries.
- Modify: `supabase/functions/cricket-match-action/types.ts` — action names, snapshot/event contracts.
- Modify: `supabase/functions/cricket-match-action/domain/validation.ts` — command input validation.
- Modify: `supabase/functions/cricket-match-action/command_router.ts` — route new commands.
- Modify: `supabase/functions/cricket-match-action/repositories/snapshot_repository.ts` — canonical Match Room snapshot.
- Modify: `supabase/functions/cricket-match-action/realtime/publisher.ts` — typed versioned events.
- Modify: `supabase/functions/cricket-match-action/index.ts` — return snapshot and publish event metadata.
- Modify: `supabase/functions/record-ball/index.ts` — align state-event envelopes.

### Flutter domain and data

- Create: `lib/features/matches/domain/entities/match_room_snapshot.dart` — versioned aggregate and capabilities.
- Create: `lib/features/matches/domain/entities/match_runtime_event.dart` — typed event envelope.
- Create: `lib/features/matches/data/models/match_room_snapshot_dto.dart` — JSON boundary for canonical aggregate.
- Create generated companions for the new Freezed/json models through `dart run build_runner build --delete-conflicting-outputs`.
- Modify: `lib/features/matches/domain/entities/match_player.dart` — participant provenance.
- Modify: `lib/features/matches/data/models/match_player_dto.dart` — provenance decoding.
- Modify: `lib/features/matches/domain/repositories/matches_repository.dart` — Match Room query/stream and new commands.
- Modify: `lib/features/matches/data/datasources/matches_remote_datasource.dart` — canonical query, typed Ably events, new commands, recovery.
- Modify: `lib/features/matches/data/repositories/matches_repository_impl.dart` — failure mapping and entity conversion.
- Modify: `lib/core/realtime/ably_service.dart` — reference-counted channel leases and reconnect notifications.

### Flutter presentation and scoring

- Create: `lib/features/matches/presentation/controllers/match_room_controller.dart` — route-scoped lifecycle coordinator.
- Create: `lib/features/matches/presentation/state/match_room_state.dart` — retained snapshot, local form, refresh, connection, and transition state.
- Create: `lib/features/matches/presentation/widgets/match_room/match_room_body.dart` — stable phase renderer.
- Create: `lib/features/matches/presentation/widgets/match_room/add_match_player_sheet.dart` — online match-only participant form.
- Modify: `lib/features/matches/presentation/screens/match_detail_screen.dart` — host Match Room phases.
- Modify: `lib/features/matches/presentation/screens/match_start_screen.dart` — compatibility wrapper/redirect.
- Modify: `lib/features/matches/presentation/widgets/match_start/stage_lineup.dart` — select striker, non-striker, and bowler together.
- Modify: `lib/features/matches/data/scoring/scoring_session.dart` — remote confirmed-state subscriptions and reconciliation.
- Modify: `lib/features/matches/presentation/screens/scoring_screen.dart` — internal innings-break state and boundary-only navigation.
- Modify: `lib/features/matches/presentation/screens/innings_break_screen.dart` — compatibility redirect.
- Modify: `lib/features/matches/presentation/screens/my_matches_screen.dart` — open stable Match Hub/Scoring destinations.
- Modify: `lib/router/app_router.dart` — compatibility redirects and canonical routes.

---

### Task 1: Database Participant and Snapshot Invariants

**Files:**
- Create via CLI: the `supabase/migrations/*_match_runtime_realtime.sql` path printed by Step 1
- Create: `supabase/tests/match_runtime_realtime_test.sql`
- Modify only if delegation is required: `supabase/migrations/20260101000412_match_helpers.sql` is historical and must not be edited; replace behavior in the new migration.

**Interfaces:**
- Consumes: existing `matches`, `match_teams`, `cricket_matches`, `match_players`, `cricket_match_players`, `team_members`, `tournament_teams`, and `_materialize_match_team_side`.
- Produces: `match_players.source`, `match_players.added_by`, `match_players.added_at`, `cricket_matches.state_revision`, `sync_match_participants(uuid)`, `get_match_room_snapshot(uuid)`, and automatic pre-toss synchronization.

- [ ] **Step 1: Create the migration through the Supabase CLI**

Run:

```bash
supabase migration new match_runtime_realtime
```

Record the exact generated path and use that path for every remaining step in this task.

- [ ] **Step 2: Write failing SQL invariant tests**

Create `supabase/tests/match_runtime_realtime_test.sql` with transactions that assert:

```sql
select plan(12);

-- Fixtures created for two normal teams receive one match_players row for
-- every active in-squad member and no inactive member.
-- Calling sync_match_participants twice preserves the same row count.
-- A pre-toss team-member insert is synchronized exactly once.
-- A post-toss team-member insert is not synchronized.
-- Tournament materialization selects the registered squad.
-- get_match_room_snapshot returns both sides, capabilities and revision.
-- Existing scheduled empty fixtures are repaired by the migration backfill.
```

Use deterministic UUID fixtures and `throws_ok`/`is`/`results_eq` assertions following `supabase/tests/notifications_test.sql` conventions. Include the race-sensitive case by inserting the new member immediately before invoking the toss-side reconciliation in the same transaction.

- [ ] **Step 3: Run the database tests and verify failure**

Run:

```bash
supabase test db supabase/tests/match_runtime_realtime_test.sql
```

Expected: FAIL because the new columns/functions do not exist and generic fixtures remain empty.

- [ ] **Step 4: Implement schema and participant invariants**

In the CLI-generated migration:

```sql
create type public.match_player_source as enum (
  'team_snapshot',
  'tournament_squad',
  'match_added'
);

alter table public.match_players
  add column source public.match_player_source not null default 'team_snapshot',
  add column added_by uuid references public.profiles(user_id),
  add column added_at timestamptz not null default now();

alter table public.cricket_matches
  add column state_revision bigint not null default 0,
  add column roster_frozen_at timestamptz;
```

Add an idempotent `sync_match_participants(p_match_id uuid)` function that:

- locks the match/cricket row;
- selects registered tournament squad members for tournaments;
- otherwise selects active, in-squad team members;
- inserts missing `match_players` and cricket extensions using stable conflict keys;
- removes only unreferenced, pre-freeze snapshot rows that are no longer eligible;
- never deletes `match_added` rows;
- refuses automatic mutation after `roster_frozen_at` is set.

Add a narrow team-membership trigger that invokes synchronization only for scheduled, non-tournament, non-frozen matches involving the changed team. The toss command will still perform final synchronization under the match lock.

Add `get_match_room_snapshot(p_match_id uuid)` returning one JSON object with match, teams, participants, current innings, caller capabilities, scorer lease, `state_revision`, and `server_time`.

Backfill scheduled/toss matches whose participant sets are empty, using the shared synchronization function. Grant only required execution/select privileges, set explicit `search_path` on privileged functions, and revoke default `PUBLIC` execution.

- [ ] **Step 5: Run database tests and advisors**

Run:

```bash
supabase test db supabase/tests/match_runtime_realtime_test.sql
supabase db advisors
```

Expected: all 12 assertions pass; no new security or performance findings attributable to the migration.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/*_match_runtime_realtime.sql supabase/tests/match_runtime_realtime_test.sql
git commit -m "feat: enforce match participant snapshots"
```

### Task 2: Atomic Runtime Commands

**Files:**
- Create: `supabase/functions/cricket-match-action/commands/start_match.ts`
- Create: `supabase/functions/cricket-match-action/commands/add_match_participant.ts`
- Create: `supabase/functions/cricket-match-action/repositories/participant_repository.ts`
- Modify: `supabase/functions/cricket-match-action/types.ts`
- Modify: `supabase/functions/cricket-match-action/domain/validation.ts`
- Modify: `supabase/functions/cricket-match-action/command_router.ts`
- Modify: `supabase/functions/cricket-match-action/commands/record_toss.ts`
- Modify: `supabase/functions/cricket-match-action/repositories/snapshot_repository.ts`
- Create: `supabase/functions/cricket-match-action/commands/runtime_commands.test.ts`

**Interfaces:**
- Consumes: `sync_match_participants(uuid)` and `get_match_room_snapshot(uuid)` from Task 1.
- Produces: actions `start_match` and `add_match_participant`; every successful runtime command returns `TransactionOutput.snapshot` and `TransactionOutput.revision`.

- [ ] **Step 1: Write failing command tests**

Test the command handlers with a fake transaction/repository boundary:

```ts
Deno.test("start_match rejects an incomplete trio", async () => {
  await assertRejects(
    () => startMatch(context({ p_bowler_id: null })),
    DomainError,
    "striker, non-striker, and bowler are required",
  );
});

Deno.test("add_match_participant never creates team membership", async () => {
  const out = await addMatchParticipant(context(validGuest));
  assertEquals(out.result.source, "match_added");
  assertEquals(fakeDb.teamMemberInsertCount, 0);
});
```

Also test same-player openers, bowler on the batting side, unauthorized scorer, additions to both sides, duplicate idempotency key, and two start attempts returning one canonical live transition.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
deno test --allow-env supabase/functions/cricket-match-action/commands/runtime_commands.test.ts
```

Expected: FAIL because the new action handlers and contracts do not exist.

- [ ] **Step 3: Implement typed command contracts**

Extend `Action` with:

```ts
| "start_match"
| "add_match_participant";
```

Extend `TransactionOutput` with:

```ts
snapshot: unknown;
revision: number;
events: RuntimeEvent[];
```

Define `RuntimeEvent` with `eventId`, `matchId`, `revision`, `eventType`, optional `inningsNumber`, and `occurredAt`.

- [ ] **Step 4: Implement `start_match`**

The handler must lock the match, authorize `match.score` plus the scorer lease, require lineup/ready phase, validate two distinct batting-side players and one bowling-side player, upsert innings 1, set actual start time/status/phase, increment revision once, and return the canonical snapshot.

Keep legacy `submit_match_openers` and `start_match_now` callable temporarily for compatibility, but remove them from new Flutter usage.

- [ ] **Step 5: Implement `add_match_participant`**

Accept:

```ts
{
  p_match_id: string;
  p_team_side: "team_a" | "team_b";
  p_display_name: string;
  p_idempotency_key: string;
}
```

Normalize and validate a non-empty display name, authorize the active scorer, create the unclaimed identity and match/cricket participant in one transaction, record `source = 'match_added'`, increment revision, and return the participant plus canonical snapshot. Do not insert a team membership.

- [ ] **Step 6: Reconcile and freeze inside toss**

Before recording toss fields, invoke `sync_match_participants(matchId)` while the match is locked, then set `roster_frozen_at` and increment the revision in the same transaction.

- [ ] **Step 7: Run tests**

```bash
deno test --allow-env supabase/functions/cricket-match-action/commands/runtime_commands.test.ts
deno check supabase/functions/cricket-match-action/index.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add supabase/functions/cricket-match-action
git commit -m "feat: add atomic match runtime commands"
```

### Task 3: Versioned Ably Events and Channel Ownership

**Files:**
- Modify: `supabase/functions/cricket-match-action/realtime/publisher.ts`
- Modify: `supabase/functions/cricket-match-action/index.ts`
- Modify: `supabase/functions/record-ball/index.ts`
- Modify: `lib/core/realtime/ably_service.dart`
- Create: `test/core/realtime/ably_service_test.dart`

**Interfaces:**
- Consumes: `RuntimeEvent[]` and revision from Task 2.
- Produces: `AblyChannelLease acquireChannel(String name)`, whose `release()` detaches only on the final lease; state events use the common versioned envelope.

- [ ] **Step 1: Write failing channel lease tests**

Cover two acquisitions of the same channel, first release retaining attachment, final release detaching once, duplicate release being harmless, and reconnect listener delivery.

```dart
test('shared channel detaches only after final lease releases', () async {
  final first = service.acquireChannel('match:m1:state');
  final second = service.acquireChannel('match:m1:state');
  await first.release();
  expect(fake.detachCalls, 0);
  await second.release();
  expect(fake.detachCalls, 1);
});
```

- [ ] **Step 2: Run the test and verify failure**

```bash
flutter test test/core/realtime/ably_service_test.dart
```

Expected: FAIL because `acquireChannel` and reference counting do not exist.

- [ ] **Step 3: Implement reference-counted leases**

Replace the active-name `Set` with a map of channel entries and counts. Preserve one Ably channel reference per name. Make release idempotent and detach only when the count reaches zero. Expose subscribed/reconnected transitions without coupling feature code to Ably SDK types.

- [ ] **Step 4: Publish typed state envelopes**

Publish `match_changed`, `participants_changed`, `innings_changed`, and `match_completed` from the command output after commit. Align `record-ball` state publications to the same envelope while retaining full-row `ball_recorded` on the balls channel.

- [ ] **Step 5: Run tests and type checks**

```bash
flutter test test/core/realtime/ably_service_test.dart
deno check supabase/functions/cricket-match-action/index.ts
deno check supabase/functions/record-ball/index.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/realtime/ably_service.dart test/core/realtime/ably_service_test.dart supabase/functions/cricket-match-action supabase/functions/record-ball/index.ts
git commit -m "fix: make match realtime channels recoverable"
```

### Task 4: Match Room Domain, DTO, and Repository

**Files:**
- Create: `lib/features/matches/domain/entities/match_room_snapshot.dart`
- Create: `lib/features/matches/domain/entities/match_runtime_event.dart`
- Create: `lib/features/matches/data/models/match_room_snapshot_dto.dart`
- Modify: `lib/features/matches/domain/entities/match_player.dart`
- Modify: `lib/features/matches/data/models/match_player_dto.dart`
- Modify: `lib/features/matches/domain/repositories/matches_repository.dart`
- Modify: `lib/features/matches/data/datasources/matches_remote_datasource.dart`
- Modify: `lib/features/matches/data/repositories/matches_repository_impl.dart`
- Create: `test/features/matches/data/models/match_room_snapshot_dto_test.dart`
- Create: `test/features/matches/data/datasources/match_room_remote_datasource_test.dart`

**Interfaces:**
- Consumes: Task 1 snapshot JSON, Task 2 command shapes, Task 3 channel leases/events.
- Produces: `getMatchRoom`, `watchMatchRoom`, `startMatch`, and `addMatchParticipant` repository APIs.

- [ ] **Step 1: Write failing DTO and stream tests**

Test complete snapshot decoding, missing optional innings, both participant sources, capability defaults that fail closed, older event rejection, a revision gap forcing one snapshot fetch, reconnect/resume refetch, and preserving the last snapshot when reconciliation fails.

```dart
expect(dto.toEntity().revision, 7);
expect(dto.toEntity().capabilities.canAddParticipant, isFalse);
expect(room.participants.single.source, MatchPlayerSource.matchAdded);
```

- [ ] **Step 2: Run tests and verify failure**

```bash
flutter test test/features/matches/data/models/match_room_snapshot_dto_test.dart test/features/matches/data/datasources/match_room_remote_datasource_test.dart
```

Expected: FAIL because the aggregate and APIs do not exist.

- [ ] **Step 3: Implement domain contracts**

Define immutable entities for:

```dart
enum MatchPlayerSource { teamSnapshot, tournamentSquad, matchAdded }

class MatchRoomSnapshot {
  final Match match;
  final int revision;
  final List<MatchPlayer> participants;
  final MatchInningsState? innings;
  final MatchRoomCapabilities capabilities;
  final DateTime serverTime;
}
```

Define `MatchRuntimeEvent` with event ID, match ID, revision, type, innings number, and occurrence time.

- [ ] **Step 4: Implement data and repository APIs**

Add repository signatures:

```dart
Future<Either<Failure, MatchRoomSnapshot>> getMatchRoom(MatchId id);
Stream<MatchRoomSnapshot> watchMatchRoom(MatchId id);
Future<Either<Failure, MatchRoomSnapshot>> startMatch({...});
Future<Either<Failure, MatchRoomSnapshot>> addMatchParticipant({...});
```

`watchMatchRoom` must fetch before subscribing, acquire a channel lease, reconcile new revisions, ignore duplicate/older events, refetch on a gap or malformed event, and refetch after connection restoration. A transient refetch error after first data must not terminate the stream.

- [ ] **Step 5: Generate code and run tests**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/matches test/features/matches
flutter test test/features/matches/data/models/match_room_snapshot_dto_test.dart test/features/matches/data/datasources/match_room_remote_datasource_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/matches test/features/matches/data
git commit -m "feat: add canonical match room data contract"
```

### Task 5: Match Room Coordinator

**Files:**
- Create: `lib/features/matches/presentation/state/match_room_state.dart`
- Create: `lib/features/matches/presentation/controllers/match_room_controller.dart`
- Create generated controller/state files with build_runner.
- Create: `test/features/matches/presentation/controllers/match_room_controller_test.dart`

**Interfaces:**
- Consumes: repository APIs from Task 4.
- Produces: one retained route state and intentions `submitToss`, `startMatch`, `addParticipant`, `refresh`, and `consumeNavigation`.

- [ ] **Step 1: Write failing controller tests**

Cover initial loading, cached-data refresh, command-response adoption without waiting for Ably, duplicate revision suppression, one-shot navigation, connection banner state, and the pre-toss addition/toss ordering case.

```dart
await controller.startMatch(striker: 'p1', nonStriker: 'p2', bowler: 'p3');
expect(controller.state.value!.snapshot.revision, 9);
expect(controller.state.value!.navigation, MatchRoomNavigation.scoring);
controller.consumeNavigation();
expect(controller.state.value!.navigation, isNull);
```

- [ ] **Step 2: Run the test and verify failure**

```bash
flutter test test/features/matches/presentation/controllers/match_room_controller_test.dart
```

Expected: FAIL because the controller does not exist.

- [ ] **Step 3: Implement retained route state**

State must distinguish first load from reconciliation:

```dart
class MatchRoomState {
  final MatchRoomSnapshot snapshot;
  final bool isRefreshing;
  final bool isCommandPending;
  final bool isRealtimeConnected;
  final MatchRoomNavigation? navigation;
  final Object? nonBlockingError;
}
```

Keep toss/lineup form selections local and preserve them across unrelated snapshot revisions when the selected players remain eligible.

- [ ] **Step 4: Implement coordinator commands and lifecycle**

Watch exactly one Match Room stream per route. Adopt successful command snapshots immediately. Derive navigation only at Match Hub→Scoring and Scoring→Result boundaries and attach the originating revision so it can be consumed once.

- [ ] **Step 5: Generate and test**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/matches/presentation test/features/matches/presentation/controllers
flutter test test/features/matches/presentation/controllers/match_room_controller_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/matches/presentation test/features/matches/presentation/controllers
git commit -m "feat: coordinate match room lifecycle"
```

### Task 6: Stable Match Hub and Match-Only Player UI

**Files:**
- Create: `lib/features/matches/presentation/widgets/match_room/match_room_body.dart`
- Create: `lib/features/matches/presentation/widgets/match_room/add_match_player_sheet.dart`
- Modify: `lib/features/matches/presentation/screens/match_detail_screen.dart`
- Modify: `lib/features/matches/presentation/screens/match_start_screen.dart`
- Modify: `lib/features/matches/presentation/widgets/match_start/stage_lineup.dart`
- Modify: `lib/features/matches/presentation/screens/my_matches_screen.dart`
- Modify: `lib/router/app_router.dart`
- Create: `test/features/matches/presentation/screens/match_room_screen_test.dart`

**Interfaces:**
- Consumes: Match Room coordinator from Task 5.
- Produces: one pre-live route with toss, complete-trio lineup, waiting, reconnect, and match-only participant experiences.

- [ ] **Step 1: Write failing widget tests**

Test that phase changes replace body content without route changes, opening bowler is required before Start, the scorer can open Add Player for either side, a failed refresh retains content, duplicate live snapshots navigate once, and `/start` resolves into the Match Hub.

- [ ] **Step 2: Run tests and verify failure**

```bash
flutter test test/features/matches/presentation/screens/match_room_screen_test.dart
```

Expected: FAIL because the stable Match Room widgets are absent.

- [ ] **Step 3: Implement Match Hub phase rendering**

Render fixture, roster readiness, toss, lineup, and waiting states under one scaffold. Replace full-screen loaders after first data with inline progress/reconnect notices.

- [ ] **Step 4: Implement complete-trio lineup and player addition**

The lineup stage selects two batting-side players and one bowling-side player. Start invokes only the atomic `startMatch` command. The Add Player sheet asks for side and display name, requires connectivity, shows a scoped pending state, and selects the returned participant when appropriate.

- [ ] **Step 5: Replace pre-live navigation ownership**

Route scheduled/toss/lineup fixtures to `/matches/:id`. Keep `/start` as a redirect or wrapper with no independent listeners. Perform Match Hub→Scoring navigation only when the controller exposes its one-shot transition.

- [ ] **Step 6: Run tests**

```bash
dart format lib/features/matches/presentation lib/router test/features/matches/presentation/screens
flutter test test/features/matches/presentation/screens/match_room_screen_test.dart test/features/matches/presentation/screens/my_matches_screen_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/matches/presentation lib/router/app_router.dart test/features/matches/presentation/screens
git commit -m "feat: unify pre-match setup in match hub"
```

### Task 7: Scoring Realtime Reconciliation

**Files:**
- Modify: `lib/features/matches/data/scoring/scoring_session.dart`
- Modify: `lib/features/matches/presentation/controllers/scoring_controller.dart`
- Modify: `test/features/matches/data/scoring/scoring_session_test.dart`
- Modify: `test/features/matches/presentation/controllers/scoring_controller_test.dart`

**Interfaces:**
- Consumes: typed room/ball streams from Task 4 and existing local WAL.
- Produces: a scoring projection whose confirmed base follows remote state while pending operations remain FIFO and deterministic.

- [ ] **Step 1: Add failing reconciliation tests**

Add cases for a remote ball below one pending local ball, duplicate remote delivery, sequence gap resnapshot, remote trio change, participant addition, permission/lease loss, and stream disposal.

```dart
remoteBalls.add([confirmedRemoteBall]);
expect(session.current!.balls.map((b) => b.id), contains(confirmedRemoteBall.id));
expect(session.current!.pendingCount, 1);
expect(session.current!.computedByOpId, contains(pendingOpId));
```

- [ ] **Step 2: Run tests and verify failure**

```bash
flutter test test/features/matches/data/scoring/scoring_session_test.dart test/features/matches/presentation/controllers/scoring_controller_test.dart
```

Expected: FAIL because `ScoringSession` does not subscribe to remote changes.

- [ ] **Step 3: Implement confirmed-base subscriptions**

On load, subscribe to match room and balls. Update `_match`, `_innings`, `_players`, `_canScore`, and `_balls` only as confirmed base. Dedupe balls by stable ID, sort by sequence, request a canonical refresh on gaps, and call `_emit()` so pending operations replay over the new base.

Never clear `_pending` merely because remote state changed. Cancel every subscription in `dispose`.

- [ ] **Step 4: Run tests**

```bash
dart format lib/features/matches/data/scoring lib/features/matches/presentation/controllers test/features/matches
flutter test test/features/matches/data/scoring/scoring_session_test.dart test/features/matches/presentation/controllers/scoring_controller_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/matches/data/scoring lib/features/matches/presentation/controllers test/features/matches
git commit -m "feat: reconcile scoring with remote match state"
```

### Task 8: Innings Break Integration and Navigation Cleanup

**Files:**
- Modify: `lib/features/matches/presentation/screens/scoring_screen.dart`
- Modify: `lib/features/matches/presentation/screens/innings_break_screen.dart`
- Modify: `lib/features/matches/presentation/state/scoring_state.dart`
- Modify: `lib/router/app_router.dart`
- Create: `test/features/matches/presentation/screens/scoring_lifecycle_test.dart`

**Interfaces:**
- Consumes: coordinator boundary navigation and scoring confirmed state.
- Produces: one scoring route spanning innings 1, innings break setup, innings 2, and terminal navigation.

- [ ] **Step 1: Write failing lifecycle widget tests**

Cover first-innings completion rendering break setup without leaving scoring, second-innings atomic trio submission, another device starting innings 2, `/innings-break` compatibility routing, duplicate terminal revisions navigating once, and a missing bowler preventing transition.

- [ ] **Step 2: Run test and verify failure**

```bash
flutter test test/features/matches/presentation/screens/scoring_lifecycle_test.dart
```

Expected: FAIL because innings break is a separate screen/route owner.

- [ ] **Step 3: Implement internal scoring phases**

Derive `activeInnings`, `isInningsBreak`, `needsTrio`, and `isTerminal` from the canonical snapshot. Render break lineup content inside `ScoringScreen`. Start innings 2 through the complete-trio command with target set to first-innings runs plus one.

- [ ] **Step 4: Restrict route navigation to terminal boundaries**

Make `/innings-break` redirect to `/score?innings=2`. Remove independent status listeners that race the scoring shell. Navigate to Result once when the canonical terminal revision is consumed.

- [ ] **Step 5: Run tests**

```bash
dart format lib/features/matches/presentation lib/router test/features/matches/presentation/screens
flutter test test/features/matches/presentation/screens/scoring_lifecycle_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/matches/presentation lib/router/app_router.dart test/features/matches/presentation/screens
git commit -m "refactor: keep innings handover inside scoring"
```

### Task 9: Remove Redundant Runtime Paths and Verify End to End

**Files:**
- Modify: CLI-generated match runtime migration if dependency verification allows dropping old match `realtime.send` triggers.
- Modify: `lib/features/matches/data/datasources/matches_remote_datasource.dart`
- Modify: `lib/features/matches/domain/repositories/matches_repository.dart`
- Modify: `lib/features/matches/data/repositories/matches_repository_impl.dart`
- Modify: obsolete Match Start providers/controllers only after all consumers have moved.
- Create: `test/features/matches/integration/two_device_match_runtime_test.dart`

**Interfaces:**
- Consumes: all preceding tasks.
- Produces: one supported runtime path with compatibility routes but no duplicate workflow/realtime ownership.

- [ ] **Step 1: Write the end-to-end two-device test**

Model two coordinators against one fake backend/event bus and verify:

```text
fixture creation -> both rosters present
phone A records toss -> phone B reaches lineup
phone A adds a team B bowler -> both devices receive participant
phone A starts complete trio -> both devices reach live exactly once
phone B misses an event -> reconnect snapshot repairs it
concurrent start attempt -> no duplicate innings
```

- [ ] **Step 2: Run test and verify failure before cleanup**

```bash
flutter test test/features/matches/integration/two_device_match_runtime_test.dart
```

Expected: FAIL if any legacy provider or route still owns an incompatible transition.

- [ ] **Step 3: Remove obsolete consumers and broadcasts**

Use `rg` to prove no Flutter consumer needs the old independent `watchMatch`/`watchMatchInningsState` start flow. Remove legacy start methods only after all callers use the atomic command. Confirm no external consumer relies on the Supabase `realtime.send` topics, then drop the redundant match-runtime triggers in the new migration while retaining unrelated Realtime publication required elsewhere.

- [ ] **Step 4: Run generated-code and static verification**

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
deno check supabase/functions/cricket-match-action/index.ts
deno check supabase/functions/record-ball/index.ts
supabase test db
supabase db advisors
```

Expected: all commands exit 0 and advisors report no newly introduced issue.

- [ ] **Step 5: Verify the repaired live fixture safely**

Against the configured development Supabase project, run read-only queries first to identify scheduled fixtures with empty `match_players`. Apply the reviewed migration through the normal deployment workflow, then verify that the Saran XI versus Hyderabad Hawks fixture has both participant sides and that no `team_members` row was created for any match-only test participant.

- [ ] **Step 6: Commit cleanup and integration coverage**

```bash
git add lib test supabase
git commit -m "test: verify two-device match runtime"
```

### Task 10: Final Review and Rollout Guard

**Files:**
- Modify: `docs/database/MATCHDAY_MATCH_CRICKET_RUNTIME_ARCHITECTURE.md`
- Create: `docs/database/MATCH_RUNTIME_ROLLOUT.md`

**Interfaces:**
- Consumes: verified implementation from Tasks 1–9.
- Produces: deployment order, rollback boundaries, observability queries, and operator checks.

- [ ] **Step 1: Document deployment order**

Record this exact rollout sequence:

```text
1. Apply additive database migration and participant backfill.
2. Deploy cricket-match-action and record-ball functions.
3. Verify canonical snapshot and typed publications.
4. Release Flutter client with compatibility routes/methods intact.
5. Observe revision gaps, publish failures, lease conflicts, and command errors.
6. Remove legacy methods/triggers only after supported client adoption permits it.
```

Include a rollback matrix distinguishing safe client rollback, Edge Function rollback, and database columns/functions that must remain after clients have written new provenance/revision data.

- [ ] **Step 2: Run final verification from a clean command invocation**

```bash
git diff --check
flutter analyze
flutter test
deno check supabase/functions/cricket-match-action/index.ts
deno check supabase/functions/record-ball/index.ts
supabase test db
```

Expected: all exit 0.

- [ ] **Step 3: Commit documentation**

```bash
git add docs/database
git commit -m "docs: add match runtime rollout guide"
```

- [ ] **Step 4: Request whole-branch code review**

Review the branch against `docs/superpowers/specs/2026-09-21-match-runtime-realtime-design.md`, concentrating on authorization bypass, destructive backfill behavior, transaction boundaries, stale-event ordering, shared-channel teardown, pending-scoring replay, and navigation duplication. Address every actionable finding and rerun the final verification commands before merge.
