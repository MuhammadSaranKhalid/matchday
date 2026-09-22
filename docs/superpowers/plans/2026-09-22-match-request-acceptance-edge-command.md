# Match Request Acceptance Edge Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `accept_match_request` and `accept_pool_application` database RPC workflows with one transactional `match-request-action` Edge Function and migrate Flutter to that command boundary.

**Architecture:** The Edge Function authenticates the caller, injects verified JWT claims into one direct PostgreSQL transaction, and dispatches to isolated TypeScript commands. PostgreSQL remains authoritative for constraints, permission primitives, notifications, and canonical participant synchronization; Flutter invokes the Edge command and maps its typed HTTP failures.

**Tech Stack:** Supabase Edge Functions, Deno/TypeScript, postgres.js, PostgreSQL/pgTAP, Flutter/Dart, Supabase Flutter.

**Spec:** `docs/superpowers/specs/2026-09-22-match-request-acceptance-edge-command-design.md`

## Global Constraints

- Matchday has no released clients; remove the obsolete RPCs without compatibility wrappers.
- `matches` owns only the sport-neutral fixture shell.
- `match_teams` is the only physical match-to-team relationship.
- `cricket_matches` owns Cricket rules and setup state.
- `sync_match_participants` is the sole implementation allowed to create automatic match participants.
- Every acceptance effect must commit or roll back in one PostgreSQL transaction.
- Actor identity must come only from the verified bearer token.
- No match-runtime Ably event is emitted for creation of a previously unknown match.
- Preserve the current domain repository and presentation interfaces.

## Review Focus

- Two callers accepting the same challenge concurrently: exactly one match survives and the loser receives `409 CONFLICT`; Task 2 integration tests cover this.
- Two pool applications accepted concurrently: one application wins, competitors reject, and only one match exists; Task 2 integration tests cover this.
- Counter acceptance authority: only the original sender may accept countered terms; Task 1 command tests cover this.
- Keeper supplied outside the selected/eligible roster: return `422` without partial writes; Tasks 1 and 2 cover validation and rollback.
- Edge returns HTTP 200 without a valid `match_id`: Flutter treats it as a server failure rather than navigating with invalid state; Task 4 covers this.

---

### Task 1: Define and test the request command contracts

**Files:**
- Create: `supabase/functions/match-request-action/types.ts`
- Create: `supabase/functions/match-request-action/domain/errors.ts`
- Create: `supabase/functions/match-request-action/domain/validation.ts`
- Create: `supabase/functions/match-request-action/domain/validation.test.ts`

**Interfaces:**
- Produces: `Action = "accept_challenge" | "accept_pool_application"`.
- Produces: `RequestEnvelope { action: Action; body: Record<string, unknown> }`.
- Produces: `parseEnvelope(raw)`, `parseAcceptChallenge(body)`, and `parseAcceptPoolApplication(body)`.
- Produces: `CommandError` plus `badRequest`, `forbidden`, `notFound`, `conflict`, `unprocessable`, and `normalizeUnexpectedError`.

- [ ] **Step 1: Write failing validation tests**

Create table-driven Deno tests asserting:

```ts
const direct = parseEnvelope({
  action: "accept_challenge",
  body: {
    request_id: ids.request,
    to_team_xi: [ids.player],
  },
});
assertEquals(direct.action, "accept_challenge");

assertThrows(
  () => parseEnvelope({ action: "unknown", body: {} }),
  CommandError,
  "Unsupported action",
);

assertThrows(
  () => parseAcceptChallenge({ request_id: "not-a-uuid" }),
  CommandError,
  "valid UUID",
);

assertThrows(
  () => parseAcceptChallenge({
    request_id: ids.request,
    to_team_xi: [ids.player],
    to_team_keeper_id: ids.otherPlayer,
  }),
  CommandError,
  "Wicket-keeper must be part of the picked XI",
);
```

Also cover malformed timestamps, non-array XI input, invalid XI UUIDs, malformed format JSON, and the pool application envelope.

- [ ] **Step 2: Run the tests and verify the expected red state**

Run:

```bash
npx -y deno test supabase/functions/match-request-action/domain/validation.test.ts
```

Expected: FAIL because the new modules do not exist.

- [ ] **Step 3: Implement the minimal typed contracts and parsers**

Use a strict envelope with an object-valued `body`. Normalize optional empty strings to `null`, require RFC-compatible timestamps through `Date.parse`, validate UUID arrays, and return typed command inputs:

```ts
export interface AcceptChallengeInput {
  requestId: string;
  scheduledStartTime: string | null;
  venue: string | null;
  format: Record<string, unknown> | null;
  decisionNote: string | null;
  toTeamId: string | null;
  toTeamXi: string[];
  toTeamKeeperId: string | null;
}
```

Keep error normalization compatible with `cricket-match-action` HTTP status semantics.

- [ ] **Step 4: Run the validation tests and verify green**

Run the Step 2 command. Expected: all validation tests pass.

- [ ] **Step 5: Commit the command contract**

```bash
git add supabase/functions/match-request-action
git commit -m "feat: define match request action contract"
```

---

### Task 2: Implement transaction repositories and acceptance commands

**Files:**
- Create: `supabase/functions/match-request-action/repositories/challenge_repository.ts`
- Create: `supabase/functions/match-request-action/repositories/team_repository.ts`
- Create: `supabase/functions/match-request-action/repositories/match_creation_repository.ts`
- Create: `supabase/functions/match-request-action/commands/accept_challenge.ts`
- Create: `supabase/functions/match-request-action/commands/accept_pool_application.ts`
- Create: `supabase/functions/match-request-action/commands/acceptance_commands.test.ts`
- Create: `supabase/functions/match-request-action/repositories/acceptance_integration_test.ts`
- Modify: `supabase/tests/match_creation_architecture_test.sql`

**Interfaces:**
- Consumes: typed inputs and `CommandError` from Task 1.
- Produces: `acceptChallenge(ctx, deps): Promise<{ matchId: string }>`.
- Produces: `acceptPoolApplication(ctx, deps): Promise<{ matchId: string }>`.
- Produces: `MatchCreationRepository.createFriendlyCricketMatch(tx, input): Promise<string>`.
- Produces: repository lock/transition methods whose SQL is executed only inside the caller's transaction.

- [ ] **Step 1: Write failing command tests with stateful fakes**

Create fakes that model locked challenge/application rows and record mutations. Cover:

```ts
Deno.test("receiving manager accepts a targeted challenge", async () => {
  const deps = new FakeAcceptanceDependencies({ status: "pending" });
  const out = await acceptChallenge(context(targetedBody), deps);
  assertEquals(out.matchId, ids.match);
  assertEquals(deps.createdMatches, 1);
  assertEquals(deps.challengeStatus, "accepted");
});

Deno.test("only sender accepts countered terms", async () => { /* 403 */ });
Deno.test("open challenge requires an authorized claiming team", async () => { /* 422/403 */ });
Deno.test("terminal challenge conflicts before match creation", async () => { /* 409 */ });
Deno.test("host accepts one pool application and rejects competitors", async () => { /* assertions */ });
```

Name the production defect each test catches: creation before authorization,
unguarded terminal transition, wrong counter actor, or incomplete pool closure.

- [ ] **Step 2: Run command tests and verify red**

```bash
npx -y deno test supabase/functions/match-request-action/commands/acceptance_commands.test.ts
```

Expected: FAIL because command modules and dependency interfaces do not exist.

- [ ] **Step 3: Implement repositories with parameterized SQL**

`ChallengeRepository` must expose exact lock-first operations:

```ts
lockChallenge(tx, requestId)
lockApplication(tx, applicationId)
acceptChallenge(tx, requestId, observedStatus, matchId, actorId, note, toTeamId)
acceptApplication(tx, applicationId, note)
rejectCompetingApplications(tx, requestId, selectedApplicationId)
```

Every terminal update returns its affected-row count; zero rows throw conflict.

`TeamRepository` must call current database permission and XI helpers after
`setTransactionJwtClaims` has installed the verified actor.

`MatchCreationRepository` must insert only normalized shell fields, resolve the
two `match_teams` slots, create `cricket_matches`, call
`sync_match_participants`, and update keeper flags. It must not contain an
`insert into public.match_players` or `insert into public.cricket_match_players`.

- [ ] **Step 4: Implement minimal command orchestration**

Commands must lock, authorize, derive effective terms, validate, create the
aggregate, and perform guarded terminal transitions in that order. Keep the
three direct challenge variants explicit rather than merging them into
condition-heavy repository SQL.

- [ ] **Step 5: Run command tests and verify green**

Run the Step 2 command. Expected: all command tests pass.

- [ ] **Step 6: Extend database architecture invariants without removing RPCs yet**

Keep the current RPC assertions green until the coordinated removal in Task 5.
Add source-level architecture coverage asserting that the new match-creation
repository contains neither removed shell columns nor manual participant
inserts:

```dart
expect(source, isNot(contains('team_a_id')));
expect(source, isNot(contains('team_b_id')));
expect(source, isNot(contains('insert into public.match_players')));
expect(source, isNot(contains('insert into public.cricket_match_players')));
```

Retain existing pgTAP normalized aggregate, participant-source, and keeper
invariants until Task 5 rewrites them for the removed RPC boundary.

- [ ] **Step 7: Add a forced-conflict rollback integration test**

Use the local `SUPABASE_DB_URL` and postgres.js to run the real repositories
inside `sql.begin`. Force the guarded terminal update to return zero rows,
assert rejection with `CONFLICT`, then query after rollback and confirm no
orphan `matches` row exists. Exercise two acceptance transactions against one
seeded request and assert exactly one committed match ID.

Run:

```bash
npx -y deno test --allow-env --allow-net \
  supabase/functions/match-request-action/repositories/acceptance_integration_test.ts
```

- [ ] **Step 8: Commit repositories and commands**

```bash
git add supabase/functions/match-request-action supabase/tests/match_creation_architecture_test.sql
git commit -m "feat: add transactional acceptance commands"
```

---

### Task 3: Add the Edge HTTP and transaction boundary

**Files:**
- Create: `supabase/functions/match-request-action/command_router.ts`
- Create: `supabase/functions/match-request-action/index.ts`
- Create: `supabase/functions/match-request-action/index.test.ts`
- Modify: `supabase/config.toml`

**Interfaces:**
- Consumes: Task 1 envelope/errors and Task 2 commands.
- Consumes: `db`, `authenticateRequest`, `setTransactionJwtClaims`, `corsPreflight`, and `json` shared infrastructure.
- Produces: HTTP `POST /functions/v1/match-request-action` returning `{ok:true, match_id}` or the typed error envelope.

- [ ] **Step 1: Write failing router and handler tests**

Test command dispatch for both actions and HTTP behavior for OPTIONS, invalid
JSON, unauthenticated requests, success, and normalized command errors. Extract
`handleRequest(req, deps)` from `Deno.serve` so tests inject authentication and
transaction dependencies without opening sockets.

- [ ] **Step 2: Run handler tests and verify red**

```bash
npx -y deno test supabase/functions/match-request-action/index.test.ts
```

Expected: FAIL because the router and handler do not exist.

- [ ] **Step 3: Implement one transaction per request**

Inside `sql.begin`, call `setTransactionJwtClaims(tx, actorId)`, dispatch the
command with `{tx, actorId, body}`, and return its `matchId`. Do not publish a
match-runtime event. Log action, actor, and normalized error code without
logging authorization tokens or full request bodies.

- [ ] **Step 4: Register the function configuration**

Add the matching `functions.match-request-action` section to
`supabase/config.toml`, following the repository's existing JWT verification
convention.

- [ ] **Step 5: Run all Edge tests**

```bash
npx -y deno test supabase/functions/match-request-action
npx -y deno test supabase/functions/cricket-match-action/commands/runtime_commands.test.ts
```

Expected: all tests pass.

- [ ] **Step 6: Commit the Edge boundary**

```bash
git add supabase/functions/match-request-action supabase/config.toml
git commit -m "feat: expose match request acceptance command"
```

---

### Task 4: Migrate Flutter from RPC to the Edge command

**Files:**
- Modify: `lib/features/matches/data/datasources/match_requests_remote_datasource.dart`
- Modify: `lib/features/matches/data/repositories/matches_repository_impl.dart`
- Modify: `lib/features/matches/data/repositories/match_pool_repository_impl.dart`
- Create: `test/features/matches/data/datasources/match_requests_remote_datasource_test.dart`
- Modify or create focused repository tests under: `test/features/matches/data/repositories/`

**Interfaces:**
- Consumes: Edge success `{ok:true, match_id:string}` and typed error envelope.
- Preserves: domain methods `acceptMatchChallenge(...)` and `acceptPoolApplication(...)`.
- Changes internal datasource return: challenge acceptance becomes non-nullable `Future<String>`.

- [ ] **Step 1: Write failing datasource contract tests**

Use the repository's Supabase HTTP/mock pattern to assert exact invocation:

```dart
expect(invocation.functionName, 'match-request-action');
expect(invocation.body, {
  'action': 'accept_challenge',
  'body': {
    'request_id': requestId,
    'to_team_xi': <String>[],
  },
});
```

Add the pool envelope, valid match ID extraction, malformed success payload,
401/403 authorization, 409 conflict, 422 validation, relay, and fetch failures.

- [ ] **Step 2: Run focused Flutter tests and verify red**

```bash
flutter test test/features/matches/data/datasources/match_requests_remote_datasource_test.dart
```

Expected: FAIL because the datasource still calls RPC.

- [ ] **Step 3: Implement Edge invocation and neutral error mapping**

Both methods call `match-request-action`; `_functionException` must use
operation-neutral messages. Return only a non-empty string `match_id` and throw
`ServerException` for every malformed success response.

- [ ] **Step 4: Preserve typed repository failures**

Remove the nullable challenge result branch. Ensure both repository
implementations map `UnauthorizedException`, `ConflictException`, and
`ServerException` consistently rather than collapsing all pool errors into a
generic `ServerFailure(e.toString())`.

- [ ] **Step 5: Run datasource and repository tests**

```bash
flutter test test/features/matches/data/datasources/match_requests_remote_datasource_test.dart test/features/matches/data/repositories
flutter analyze lib/features/matches/data
```

Expected: all focused tests pass and analysis reports no issues.

- [ ] **Step 6: Commit the Flutter migration**

```bash
git add lib/features/matches/data test/features/matches/data
git commit -m "refactor: route match acceptance through edge command"
```

---

### Task 5: Remove obsolete RPCs and finalize architecture documentation

**Files:**
- Create via CLI: the generated `supabase/migrations/*_remove_match_acceptance_rpcs.sql`
- Modify: `docs/database/MATCHDAY_MATCH_CRICKET_RUNTIME_ARCHITECTURE.md`
- Modify: `docs/database/MATCH_RUNTIME_ROLLOUT.md`
- Modify: `supabase/tests/match_creation_architecture_test.sql`

**Interfaces:**
- Consumes: deployed Edge boundary and migrated Flutter client from Tasks 3–4.
- Produces: database schema with neither acceptance RPC present or executable.

- [ ] **Step 1: Create the migration with the Supabase CLI**

```bash
supabase migration new remove_match_acceptance_rpcs
```

- [ ] **Step 2: Write the exact destructive cleanup**

The migration must revoke and drop only these signatures:

```sql
revoke all on function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
) from public, anon, authenticated;

drop function public.accept_match_request(
  uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid
);

revoke all on function public.accept_pool_application(uuid, text)
  from public, anon, authenticated;

drop function public.accept_pool_application(uuid, text);
```

Do not use `CASCADE`. A dependency failure must stop the migration for review.

- [ ] **Step 3: Rebuild the database and verify the removal test**

```bash
supabase db reset
supabase test db supabase/tests/match_creation_architecture_test.sql
```

Expected: reset succeeds and pgTAP confirms both routines are absent while
canonical participant and match-shape assertions remain green.

- [ ] **Step 4: Update architecture and rollout documentation**

Document the final ownership flow:

```text
Flutter → match-request-action → one Postgres transaction
                              → normalized aggregate
                              → canonical participant synchronizer
```

Remove statements implying that acceptance RPCs or database fallbacks remain.
Add deployment order: Edge Function first, Flutter build second, RPC-removal
migration last if deployed independently; for the current zero-client
development environment the changes may ship together.

- [ ] **Step 5: Run final verification**

```bash
git diff --check
flutter analyze lib
flutter test test/features/matches/data test/architecture/canonical_participant_materialization_test.dart
npx -y deno test supabase/functions/match-request-action
npx -y deno test supabase/functions/cricket-match-action/commands/runtime_commands.test.ts
supabase test db
supabase db lint --level warning
supabase migration list --local
```

Expected: application analysis, focused Flutter tests, all Edge tests, and all
pgTAP tests pass. Record unrelated pre-existing database-lint findings
separately; no new finding may reference the new migration or Edge workflow.

- [ ] **Step 6: Commit cleanup and documentation**

```bash
git add supabase/migrations supabase/tests docs/database
git commit -m "refactor: remove match acceptance RPCs"
```

---

### Task 6: Whole-change review and production handoff

**Files:**
- Review all files changed by Tasks 1–5.

**Interfaces:**
- Verifies the complete Flutter → Edge → PostgreSQL contract.
- Produces no new behavior unless review discovers a tested defect.

- [ ] **Step 1: Review for forbidden legacy paths**

```bash
rg -n "accept_match_request|accept_pool_application" lib supabase/functions supabase/migrations docs
rg -n "insert into public\.match_players|insert into public\.cricket_match_players" supabase/functions/match-request-action
```

Expected: acceptance RPC names appear only in historical migrations or explicit
removal/history documentation; the new Edge Function contains no manual
participant inserts.

- [ ] **Step 2: Review security boundaries**

Confirm every handler path authenticates before opening a transaction, every
transaction installs verified JWT claims, SQL is parameterized, RPCs are
absent, and logs exclude tokens/body contents.

- [ ] **Step 3: Verify clean repository state and summarize deployment needs**

```bash
git status --short
git log --oneline --max-count=8
```

Document that local implementation does not deploy production automatically.
Production requires the new Edge Function, Flutter build, and migration to be
deployed as one coordinated release.
