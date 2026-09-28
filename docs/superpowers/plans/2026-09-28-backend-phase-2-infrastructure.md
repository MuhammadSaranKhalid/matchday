# Matchday Backend Phase 2 Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add production-shaped PostgreSQL, Supabase token-verification, Redis, BullMQ, and dependency-readiness foundations to the Nest API and worker without introducing chat behavior or schema changes.

**Architecture:** `backend/libs/platform` owns typed configuration and singleton infrastructure resources. PostgreSQL access is available only through authorization-aware transaction executors, token verification supports explicit asymmetric JWKS or legacy remote modes, and Redis/BullMQ share validated connection settings while retaining lifecycle-safe connections. Test-only Compose services provide disposable PostgreSQL and Redis integration targets; production Compose continues to contain no competing PostgreSQL service.

**Tech Stack:** Node.js 24, TypeScript 6 strict ESM, NestJS 12.1, pnpm 9.15, Vitest 5, `pg` 8.23.0, `ioredis` 6.0.0, BullMQ 6.3.9, `@nestjs/bullmq` 12.0.0, `jose` 6.2.12, Supabase Auth/PostgreSQL, Docker Compose.

**Spec:** `docs/superpowers/specs/2026-09-28-backend-phase-2-infrastructure-design.md`

## Global Constraints

- Work on the existing `backend` branch in the primary checkout; do not merge, push, deploy, link, reset, or mutate a Supabase project.
- Preserve the user's staged root-document cleanup; every commit must use explicit Phase 2 pathspecs and must not include unrelated staged changes.
- All runtime implementation and tests belong under `backend/`; root changes are limited to CI and Phase 2 documentation.
- Add no Supabase migration, Edge Function change, RLS change, chat behavior, Socket.IO behavior, notification delivery, Flutter change, Ably removal, or media-worker integration.
- Supabase remains authoritative for PostgreSQL, Auth, Storage, and migrations; Redis is never a durable source of truth.
- Use one bounded PostgreSQL pool and one owned Redis command connection per process; never create a connection per request, socket, command, or job.
- Production credentials and network endpoints have no defaults and must never appear in validation errors, logs, snapshots, or committed fixtures.
- User-scoped SQL must run through a transaction-local verified-principal boundary; raw pools are not exported to feature modules.
- Authentication never trusts decoded-but-unverified claims, caller-supplied user IDs, or `user_metadata` for authorization.
- Use only the three Phase 2 queue names: `notifications`, `media`, and `maintenance`; create no producers, processors, schedules, or jobs.
- Integration tests use disposable test-only PostgreSQL and Redis containers and never start or alter the root Supabase project.
- Production `backend/docker-compose.yml` must not add PostgreSQL, Supabase, public Redis ports, or sibling-project build contexts.

## Review Focus

- A database callback that throws must roll back, release its pooled client, and leave no transaction-local identity for the next borrower; Task 2 pins all three outcomes.
- A token with a valid signature but wrong issuer/audience, missing UUID subject, expired lifetime, or untrusted algorithm must be rejected identically without leaking token data; Task 3 pins each class.
- PostgreSQL or Redis that accepts a TCP connection but fails or times out on the health command must produce bounded HTTP 503 readiness while `/health/live` remains 200; Task 6 pins both dependencies independently.
- Redis retry and BullMQ initialization must stop promptly during SIGTERM rather than extending beyond the 15-second Compose grace period; Tasks 4–6 pin bounded shutdown.
- Environment errors containing credential-shaped URLs, passwords, publishable keys, or bearer tokens must identify only field names; Task 1 pins redaction across every new field.

---

### Task 1: Pin Infrastructure Dependencies and Configuration Contracts

**Files:**
- Modify: `backend/package.json`
- Modify: `backend/pnpm-lock.yaml`
- Modify: `backend/libs/platform/src/config/environment.schema.ts`
- Modify: `backend/libs/platform/src/config/configuration.ts`
- Modify: `backend/libs/platform/src/logging/logging.config.ts`
- Modify: `backend/test/unit/platform/environment.schema.spec.ts`
- Modify: `backend/test/unit/platform/logging.config.spec.ts`

**Interfaces:**
- Consumes: existing `parseEnvironment(input: NodeJS.ProcessEnv): Environment` and `buildConfiguration(environment: Environment): PlatformConfiguration`.
- Produces: immutable `PlatformConfiguration.database`, `.redis`, `.auth`, and `.queue` sections consumed by Tasks 2–6.

- [ ] **Step 1: Write failing environment-contract tests**

Add table-driven tests proving:

- production requires `DATABASE_URL`, `REDIS_URL`, `SUPABASE_URL`, `SUPABASE_AUTH_ISSUER`, and `SUPABASE_AUTH_MODE`;
- `SUPABASE_PUBLISHABLE_KEY` is required only when mode is `remote`;
- auth mode accepts only `jwks` and `remote`;
- audience defaults to `authenticated`;
- pool maximum and every timeout are positive bounded integers;
- SSL mode accepts only `disable`, `require`, and `verify-full`;
- the Redis namespace is nonempty and contains only `[a-z0-9:_-]`;
- errors contain invalid field names but none of the candidate secret values.

- [ ] **Step 2: Run configuration tests to verify RED**

Run: `cd backend && corepack pnpm vitest run test/unit/platform/environment.schema.spec.ts test/unit/platform/logging.config.spec.ts`

Expected: FAIL because the new environment fields and redaction paths do not exist.

- [ ] **Step 3: Add exact dependencies and refresh the frozen lockfile**

Add exact runtime versions:

```text
@nestjs/bullmq 12.0.0
bullmq 6.3.9
ioredis 6.0.0
jose 6.2.12
pg 8.23.0
```

Add exact development dependency `@types/pg` 8.23.1. Use pnpm so `backend/pnpm-lock.yaml` is the only Node lockfile changed.

- [ ] **Step 4: Extend the typed configuration interfaces**

Define these readonly shapes in `configuration.ts`:

```ts
interface DatabaseConfiguration {
  url: string;
  poolMax: number;
  connectionTimeoutMs: number;
  idleTimeoutMs: number;
  statementTimeoutMs: number;
  sslMode: 'disable' | 'require' | 'verify-full';
}

interface RedisConfiguration {
  url: string;
  connectionTimeoutMs: number;
  commandTimeoutMs: number;
  maxRetriesPerRequest: number;
  namespace: string;
}

interface AuthConfiguration {
  supabaseUrl: string;
  issuer: string;
  audience: string;
  mode: 'jwks' | 'remote';
  publishableKey?: string;
  verificationTimeoutMs: number;
  jwksCacheMaxAgeMs: number;
  jwksCooldownMs: number;
}

interface QueueConfiguration {
  attempts: number;
  backoffDelayMs: number;
  removeOnCompleteCount: number;
  removeOnFailCount: number;
}
```

Use development/test defaults only for local synthetic endpoints. Production requires explicit URLs/issuer/mode and no credential defaults. Freeze nested configuration values.

- [ ] **Step 5: Extend logging redaction**

Redact the new environment property names, authorization headers, Redis/PostgreSQL URLs, publishable key, and nested token/key fields. Tests must serialize representative nested objects and assert secret values are absent.

- [ ] **Step 6: Run Task 1 verification**

Run:

```sh
cd backend
corepack pnpm install --frozen-lockfile
corepack pnpm vitest run test/unit/platform/environment.schema.spec.ts test/unit/platform/logging.config.spec.ts
corepack pnpm lint
corepack pnpm build
```

Expected: all pass and no untracked lockfile appears outside `backend/`.

- [ ] **Step 7: Commit Task 1 using explicit paths**

```sh
git commit -m "feat(platform): validate infrastructure configuration" -- \
  backend/package.json backend/pnpm-lock.yaml \
  backend/libs/platform/src/config backend/libs/platform/src/logging/logging.config.ts \
  backend/test/unit/platform/environment.schema.spec.ts \
  backend/test/unit/platform/logging.config.spec.ts
```

---

### Task 2: Add Authorization-Preserving PostgreSQL Transactions

**Files:**
- Create: `backend/libs/platform/src/database/database.types.ts`
- Create: `backend/libs/platform/src/database/postgres-pool.service.ts`
- Create: `backend/libs/platform/src/database/database-executor.service.ts`
- Create: `backend/libs/platform/src/database/postgres-health.indicator.ts`
- Create: `backend/libs/platform/src/database/database.module.ts`
- Create: `backend/test/unit/platform/database/postgres-pool.service.spec.ts`
- Create: `backend/test/unit/platform/database/database-executor.service.spec.ts`
- Create: `backend/test/unit/platform/database/postgres-health.indicator.spec.ts`
- Create: `backend/test/integration/docker-compose.yml`
- Create: `backend/test/integration/platform/database.integration.spec.ts`
- Create: `backend/scripts/run-infrastructure-integration.sh`
- Modify: `backend/tsconfig.json`
- Modify: `backend/oxlint.json`

**Interfaces:**
- Consumes: `PlatformConfiguration.database` from Task 1 and `AuthenticatedPrincipal` structurally defined here until Task 3 supplies the canonical type.
- Produces: `DatabaseExecutor.withUserTransaction<T>(principal, work): Promise<T>`, `DatabaseExecutor.withSystemTransaction<T>(work): Promise<T>`, and `PostgresHealthIndicator.isHealthy(key): Promise<HealthIndicatorResult>`.

- [ ] **Step 1: Write failing pool and executor unit tests**

Test that one pool is constructed from bounded settings, health uses `select 1`, shutdown calls `pool.end()` once, and driver errors are wrapped without URLs/passwords. For `withUserTransaction`, assert exact order: `BEGIN`, transaction-local role/claims setup with parameterized values, callback, `COMMIT`, release. Assert callback failure produces `ROLLBACK` and release. Assert setup failure also rolls back and releases.

- [ ] **Step 2: Write the failing database integration test**

Against disposable PostgreSQL, assert:

- concurrent executor calls reuse a pool whose active clients never exceed configured `poolMax`;
- a failed callback leaves no persisted write;
- `current_setting('request.jwt.claims', true)` is visible inside a user transaction and absent for the next system transaction;
- a timed-out acquisition/query fails within the configured bound;
- all clients can be closed and the process exits cleanly.

- [ ] **Step 3: Run database tests to verify RED**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/database
bash scripts/run-infrastructure-integration.sh --test database.integration.spec.ts
```

Expected: FAIL because the database module and integration harness do not exist.

- [ ] **Step 4: Implement focused database types and services**

Define:

```ts
interface QueryExecutor {
  query<T extends QueryResultRow = QueryResultRow>(
    queryTextOrConfig: string | QueryConfig,
    values?: readonly unknown[],
  ): Promise<QueryResult<T>>;
}

interface TransactionPrincipal {
  userId: string;
  role: 'authenticated';
  sessionId?: string;
  appMetadata: Readonly<Record<string, unknown>>;
}

type TransactionWork<T> = (database: QueryExecutor) => Promise<T>;
```

`PostgresPoolService` owns the raw `pg.Pool` but does not export it. `DatabaseExecutorService` sets role and claims with transaction-local, parameterized `set_config` calls; it never interpolates claims into SQL. `withSystemTransaction` is explicitly named and performs no user claim setup.

- [ ] **Step 5: Implement test-only Compose orchestration**

`backend/test/integration/docker-compose.yml` contains disposable PostgreSQL and Redis services with health checks and host-assigned loopback ports. It has no named production volume. `run-infrastructure-integration.sh` derives a collision-resistant Compose project name, traps cleanup, waits with `docker compose up -d --wait`, discovers assigned ports with `docker compose port`, exports synthetic environment values, runs the selected Vitest integration target, and calls `docker compose down` without `--volumes` against unrelated projects.

- [ ] **Step 6: Run Task 2 verification**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/database
bash scripts/run-infrastructure-integration.sh --test database.integration.spec.ts
corepack pnpm test:architecture
corepack pnpm lint
corepack pnpm build
```

Expected: unit/integration tests pass; architecture tests still prohibit `pg` outside platform infrastructure.

- [ ] **Step 7: Commit Task 2 using explicit paths**

```sh
git commit -m "feat(platform): add PostgreSQL transaction boundary" -- \
  backend/libs/platform/src/database backend/test/unit/platform/database \
  backend/test/integration backend/scripts/run-infrastructure-integration.sh \
  backend/tsconfig.json backend/oxlint.json
```

---

### Task 3: Add Supabase Token Verification

**Files:**
- Create: `backend/libs/platform/src/auth/authenticated-principal.ts`
- Create: `backend/libs/platform/src/auth/token-verifier.ts`
- Create: `backend/libs/platform/src/auth/supabase-token-verifier.service.ts`
- Create: `backend/libs/platform/src/auth/auth.module.ts`
- Create: `backend/test/unit/platform/auth/supabase-token-verifier.service.spec.ts`
- Create: `backend/test/integration/platform/auth-verification.integration.spec.ts`
- Modify: `backend/libs/platform/src/database/database.types.ts`
- Modify: `backend/libs/platform/src/database/database-executor.service.ts`
- Modify: `backend/test/unit/platform/database/database-executor.service.spec.ts`

**Interfaces:**
- Consumes: `PlatformConfiguration.auth` from Task 1 and the transaction principal shape from Task 2.
- Produces: canonical `AuthenticatedPrincipal` and `TokenVerifier.verify(accessToken: string): Promise<AuthenticatedPrincipal>` for future HTTP/WebSocket adapters and the database executor.

- [ ] **Step 1: Write failing verifier unit tests**

Use locally generated asymmetric keys and injected fetch/JWKS fixtures. Test valid ES256 and RS256 tokens, cached known keys, refresh on a rotated `kid`, and immutable principal mapping. Reject bad signature, `none`/unsupported algorithm, wrong issuer, wrong audience, expired token, missing subject, non-UUID subject, non-authenticated role, and fetch timeout. Assert every public failure uses a stable category and contains no token or claim values.

- [ ] **Step 2: Write failing remote-mode integration tests**

Use an in-process fake Auth endpoint. Assert `Authorization: Bearer` and `apikey` are sent, HTTP 200 plus valid registered claims returns a principal, and 401/timeout/malformed response fails closed. Assert the publishable key and access token never appear in thrown messages or captured logs.

- [ ] **Step 3: Run auth tests to verify RED**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/auth
corepack pnpm vitest run test/integration/platform/auth-verification.integration.spec.ts
```

Expected: FAIL because the auth module does not exist.

- [ ] **Step 4: Implement the canonical principal and verifier port**

Define:

```ts
interface AuthenticatedPrincipal {
  readonly userId: string;
  readonly role: 'authenticated';
  readonly sessionId?: string;
  readonly appMetadata: Readonly<Record<string, unknown>>;
}

interface TokenVerifier {
  verify(accessToken: string): Promise<AuthenticatedPrincipal>;
}
```

Export a symbol token for `TokenVerifier`; do not export the concrete verifier as the future presentation contract.

- [ ] **Step 5: Implement explicit JWKS and remote verification modes**

Use `jose` for registered-claim and algorithm validation. JWKS mode derives the discovery endpoint from the configured issuer and uses bounded cache/cooldown/timeout behavior. Remote mode calls `${SUPABASE_URL}/auth/v1/user` with the publishable key, requires a successful user response, then validates issuer, audience, expiry, UUID subject, and authenticated role before mapping. Do not silently fall back between modes and do not retain the original token.

- [ ] **Step 6: Replace the temporary transaction principal type**

Make the database executor consume `AuthenticatedPrincipal` from `auth/` without creating a database-to-concrete-auth dependency. Architecture tests must allow the stable principal contract while continuing to reject concrete presentation/infrastructure leakage into future domain/application code.

- [ ] **Step 7: Run Task 3 verification**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/auth test/unit/platform/database
corepack pnpm vitest run test/integration/platform/auth-verification.integration.spec.ts
corepack pnpm test:architecture
corepack pnpm lint
corepack pnpm build
```

Expected: all pass with no internet or real Supabase credentials.

- [ ] **Step 8: Commit Task 3 using explicit paths**

```sh
git commit -m "feat(platform): verify Supabase access tokens" -- \
  backend/libs/platform/src/auth backend/libs/platform/src/database/database.types.ts \
  backend/libs/platform/src/database/database-executor.service.ts \
  backend/test/unit/platform/auth backend/test/unit/platform/database \
  backend/test/integration/platform/auth-verification.integration.spec.ts
```

---

### Task 4: Add Lifecycle-Safe Redis Connectivity

**Files:**
- Create: `backend/libs/platform/src/redis/redis.types.ts`
- Create: `backend/libs/platform/src/redis/redis-connections.service.ts`
- Create: `backend/libs/platform/src/redis/redis-health.indicator.ts`
- Create: `backend/libs/platform/src/redis/redis.module.ts`
- Create: `backend/test/unit/platform/redis/redis-connections.service.spec.ts`
- Create: `backend/test/unit/platform/redis/redis-health.indicator.spec.ts`
- Create: `backend/test/integration/platform/redis.integration.spec.ts`

**Interfaces:**
- Consumes: `PlatformConfiguration.redis` from Task 1 and the Task 2 integration harness.
- Produces: `RedisConnections.command: Redis`, `RedisConnections.duplicate(purpose): Redis`, `RedisHealthIndicator.isHealthy(key): Promise<HealthIndicatorResult>`, and idempotent lifecycle shutdown.

- [ ] **Step 1: Write failing Redis unit tests**

Assert lazy connection uses parsed URL plus bounded connect/command/retry settings, the general connection is singleton-scoped, `duplicate(purpose)` creates a distinct owned connection, health uses bounded `PING`, error messages redact URL/password, and shutdown quits/disconnects every owned connection exactly once even after partial startup.

- [ ] **Step 2: Write failing Redis integration tests**

Assert `PING`, namespaced set/get, duplicate isolation, bounded failure after Redis becomes unavailable, readiness recovery after restart, and shutdown with no active handles.

- [ ] **Step 3: Run Redis tests to verify RED**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/redis
bash scripts/run-infrastructure-integration.sh --test redis.integration.spec.ts
```

Expected: FAIL because Redis infrastructure does not exist.

- [ ] **Step 4: Implement Redis ownership and health**

Use `ioredis` with `lazyConnect`, bounded `connectTimeout`, `commandTimeout`, `maxRetriesPerRequest`, and no unbounded offline queue for readiness-sensitive paths. Track duplicates by purpose for deterministic cleanup. Use the configured namespace helper rather than ad hoc key prefixes; do not create any product keys in this phase.

- [ ] **Step 5: Run Task 4 verification**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/redis
bash scripts/run-infrastructure-integration.sh --test redis.integration.spec.ts
corepack pnpm lint
corepack pnpm build
```

Expected: all pass and the integration command leaves no running test containers.

- [ ] **Step 6: Commit Task 4 using explicit paths**

```sh
git commit -m "feat(platform): add Redis connection lifecycle" -- \
  backend/libs/platform/src/redis backend/test/unit/platform/redis \
  backend/test/integration/platform/redis.integration.spec.ts
```

---

### Task 5: Register the BullMQ Queue Foundation

**Files:**
- Create: `backend/libs/platform/src/queue/queue-names.ts`
- Create: `backend/libs/platform/src/queue/queue-defaults.ts`
- Create: `backend/libs/platform/src/queue/queue.module.ts`
- Create: `backend/test/unit/platform/queue/queue-defaults.spec.ts`
- Create: `backend/test/unit/platform/queue/queue.module.spec.ts`
- Create: `backend/test/integration/platform/queue.integration.spec.ts`
- Modify: `backend/test/architecture/backend-dependencies.spec.ts`

**Interfaces:**
- Consumes: `PlatformConfiguration.queue` and Redis settings from Task 1.
- Produces: `QUEUE_NAMES`, `buildQueueDefaultJobOptions(configuration): DefaultJobOptions`, and `QueueModule` registering only `notifications`, `media`, and `maintenance`.

- [ ] **Step 1: Write failing queue-contract tests**

Assert the exact three names, namespaced physical queue names, bounded attempts, exponential backoff, bounded completed/failed retention, and no repeat/schedule/processor/provider. Assert all queues share validated Redis connection options without receiving the general command connection object.

- [ ] **Step 2: Write failing queue integration tests**

Resolve all three Nest queue tokens against disposable Redis, verify queue clients become ready, assert no jobs exist or are produced, and close the Nest context with no active BullMQ/Redis handles. Stop Redis during initialization and assert failure remains within the configured startup bound.

- [ ] **Step 3: Run queue tests to verify RED**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/queue
bash scripts/run-infrastructure-integration.sh --test queue.integration.spec.ts
```

Expected: FAIL because QueueModule does not exist.

- [ ] **Step 4: Implement queue constants, defaults, and module**

Register BullMQ asynchronously from immutable configuration. Queue defaults use configured attempts and exponential delay, numeric bounded `removeOnComplete`/`removeOnFail` counts, and permit deterministic `jobId` on future producers. Do not register processors, schedulers, repeatable jobs, or flows.

- [ ] **Step 5: Extend architecture enforcement**

Add negative fixtures proving `pg`, `ioredis`, `bullmq`, and `@nestjs/bullmq` imports fail from any future `domain/` or `application/` path while platform infrastructure remains allowed.

- [ ] **Step 6: Run Task 5 verification**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/queue
bash scripts/run-infrastructure-integration.sh --test queue.integration.spec.ts
corepack pnpm test:architecture
corepack pnpm lint
corepack pnpm build
```

Expected: all pass; architecture suite count increases with concrete negative fixtures.

- [ ] **Step 7: Commit Task 5 using explicit paths**

```sh
git commit -m "feat(platform): establish BullMQ queues" -- \
  backend/libs/platform/src/queue backend/test/unit/platform/queue \
  backend/test/integration/platform/queue.integration.spec.ts \
  backend/test/architecture/backend-dependencies.spec.ts
```

---

### Task 6: Wire Dependency Readiness and Process Lifecycles

**Files:**
- Modify: `backend/libs/platform/src/health/health.module.ts`
- Modify: `backend/libs/platform/src/health/health.controller.ts`
- Modify: `backend/libs/platform/src/health/readiness.service.ts`
- Modify: `backend/apps/api/src/api.module.ts`
- Modify: `backend/apps/api/src/bootstrap/api-bootstrap.ts`
- Modify: `backend/apps/worker/src/worker.module.ts`
- Modify: `backend/apps/worker/src/worker-lifecycle.service.ts`
- Modify: `backend/apps/worker/src/main.ts`
- Modify: `backend/docker-compose.yml`
- Modify: `backend/test/unit/platform/readiness.service.spec.ts`
- Modify: `backend/test/unit/worker/worker-bootstrap.spec.ts`
- Modify: `backend/test/e2e/health.spec.ts`
- Modify: `backend/test/architecture/container-foundation.spec.ts`
- Create: `backend/test/integration/platform/process-lifecycle.integration.spec.ts`
- Create: `backend/test/integration/app-smoke.compose.yml`

**Interfaces:**
- Consumes: Database, Auth, Redis, and Queue modules from Tasks 2–5.
- Produces: API readiness composed from initialization/PostgreSQL/Redis/queue state and worker fail-fast startup plus bounded shutdown.

- [ ] **Step 1: Write failing readiness and lifecycle tests**

E2e cases must assert:

- `/health/live` remains 200 before readiness, with PostgreSQL down, with Redis down, and during dependency-reported failure;
- `/health/ready` is 503 before initialization, 200 only with both dependencies healthy, 503 when either health command rejects/times out, and 503 once shutdown starts;
- failure bodies use stable `foundation`, `postgres`, `redis`, and `queues` labels with no endpoints or secrets;
- concurrent readiness calls finish within the configured health deadline.

Worker tests must assert failed dependency startup closes partially initialized resources and exits nonzero, while SIGTERM closes queues, Redis, then PostgreSQL within 15 seconds.

- [ ] **Step 2: Run lifecycle tests to verify RED**

Run:

```sh
cd backend
corepack pnpm vitest run test/unit/platform/readiness.service.spec.ts test/unit/worker/worker-bootstrap.spec.ts test/e2e/health.spec.ts
bash scripts/run-infrastructure-integration.sh --test process-lifecycle.integration.spec.ts
```

Expected: FAIL because modules are not wired and readiness is foundation-only.

- [ ] **Step 3: Compose platform modules in API and worker**

Import `DatabaseModule`, `AuthModule`, `RedisModule`, and `QueueModule` explicitly. Keep Auth available to API consumers without adding a guard or route. The worker initializes Database/Redis/Queue resources but no HTTP server or processor.

- [ ] **Step 4: Implement dependency-aware readiness**

Run PostgreSQL and Redis indicators through Terminus with bounded independent checks. `ReadinessService` continues owning initialization/stopping state and adds queue-module initialization state; it does not cache successful network checks. Preserve existing endpoint paths and version-neutral behavior.

- [ ] **Step 5: Implement worker fail-fast startup and ordered shutdown**

Before marking initialized, perform bounded PostgreSQL and Redis checks and resolve required queue providers. On failure, close the Nest context and rethrow for nonzero process exit. During shutdown, mark stopping first, then close queue resources, Redis, and PostgreSQL idempotently.

- [ ] **Step 6: Update production Compose configuration without adding secrets**

Pass required environment variable names through to API/worker without literal credentials. Keep Redis private and add dependency ordering/health only where it does not falsely imply application readiness. Do not add PostgreSQL/Supabase services or sibling contexts. Extend static tests to enforce these rules.

Create `test/integration/app-smoke.compose.yml` as a test-only overlay. It adds disposable PostgreSQL, injects synthetic production-shaped database/auth settings, and connects API/worker to the overlay PostgreSQL plus the base private Redis service. The production Compose file remains PostgreSQL-free.

- [ ] **Step 7: Run Task 6 verification**

Run:

```sh
cd backend
corepack pnpm test
corepack pnpm test:e2e
bash scripts/run-infrastructure-integration.sh --test process-lifecycle.integration.spec.ts
corepack pnpm test:architecture
corepack pnpm lint
corepack pnpm build
bash scripts/run-infrastructure-integration.sh --app-compose-config
```

Expected: unit/e2e/integration/architecture gates pass and Compose contains no literal secret values.

- [ ] **Step 8: Commit Task 6 using explicit paths**

```sh
git commit -m "feat(platform): gate readiness on infrastructure" -- \
  backend/apps backend/libs/platform/src/health backend/docker-compose.yml \
  backend/test/unit/platform/readiness.service.spec.ts backend/test/unit/worker \
  backend/test/e2e/health.spec.ts backend/test/architecture/container-foundation.spec.ts \
  backend/test/integration/platform/process-lifecycle.integration.spec.ts \
  backend/test/integration/app-smoke.compose.yml
```

---

### Task 7: Add CI Integration Gate and Final Evidence

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `backend/test/architecture/container-foundation.spec.ts`
- Modify: `docs/backend/ARCHITECTURE.md`
- Modify: `docs/backend/DEPLOYMENT.md`
- Modify: `docs/backend/IMPLEMENTATION_STATUS.md`
- Modify: `docs/superpowers/specs/2026-09-28-backend-phase-2-infrastructure-design.md`

**Interfaces:**
- Consumes: all Phase 2 runtime modules, integration harness, and existing repository-boundary gate.
- Produces: CI enforcement and evidence that Phase 2 is complete without schema or deployed-service changes.

- [ ] **Step 1: Write failing CI/container static assertions**

Assert CI invokes the disposable infrastructure script from `backend/`, uses `backend/pnpm-lock.yaml`, and runs after unit/architecture gates. Assert production Compose still has no PostgreSQL/Supabase service, no public Redis port, and only `backend/` build contexts.

- [ ] **Step 2: Run static assertions to verify RED**

Run: `cd backend && corepack pnpm vitest run test/architecture/container-foundation.spec.ts`

Expected: FAIL because CI does not yet run the integration harness.

- [ ] **Step 3: Add the CI infrastructure integration gate**

Run `bash scripts/run-infrastructure-integration.sh` from the backend working directory on the existing Docker-capable Ubuntu runner after frozen install, lint, unit, and architecture tests. Preserve Flutter and media-worker jobs. Add no credentials or deployment step.

- [ ] **Step 4: Run the complete local Phase 2 gate**

Run:

```sh
bash scripts/verify_repository_boundaries.sh

cd backend
corepack pnpm install --frozen-lockfile
corepack pnpm lint
corepack pnpm test
corepack pnpm test:architecture
corepack pnpm test:e2e
bash scripts/run-infrastructure-integration.sh
corepack pnpm build
bash scripts/run-infrastructure-integration.sh --production-smoke
```

`--production-smoke` builds the production API/worker targets, composes `docker-compose.yml` with the test-only `app-smoke.compose.yml`, waits for liveness/readiness, checks both UIDs are 1000, sends SIGTERM, and tears down only its collision-resistant Compose project.

Expected: every gate passes; both UIDs are 1000; shutdown completes within 15 seconds; only this smoke project's disposable containers/network are removed.

- [ ] **Step 5: Confirm non-backend boundaries are unchanged**

Run:

```sh
git diff --check
git diff --name-only c979463..HEAD -- app supabase website media-worker
supabase --workdir . --version
git status --short
```

Expected: no Phase 2 diff under `app/`, `supabase/`, `website/`, or `media-worker/`; Supabase CLI discovers the root project without starting or mutating it. Pre-existing user-staged cleanup remains visibly separate and uncommitted by Phase 2 commits.

- [ ] **Step 6: Update documentation and evidence**

Record exact dependency versions, configuration contract, final test counts, Docker evidence, files changed, database changes (`none`), deployed-service changes (`none`), security boundaries, remaining risks, and Phase 3 as the next unstarted gate. Change the Phase 2 spec status to implemented only after every command is green.

- [ ] **Step 7: Commit Task 7 using explicit paths**

```sh
git commit -m "docs: record backend phase 2 infrastructure" -- \
  .github/workflows/ci.yml backend/test/architecture/container-foundation.spec.ts \
  docs/backend/ARCHITECTURE.md docs/backend/DEPLOYMENT.md \
  docs/backend/IMPLEMENTATION_STATUS.md \
  docs/superpowers/specs/2026-09-28-backend-phase-2-infrastructure-design.md
```

## Self-Review Record

- Spec coverage: configuration, database pooling and authorization, auth verification, Redis ownership, BullMQ registration, readiness, lifecycle, isolated integration tests, CI, documentation, and phase exclusions each have an owning task.
- Step scan: each task has a failing test, explicit implementation interface, verification command, and path-scoped commit; no step delegates an unresolved architectural choice.
- Type consistency: `AuthenticatedPrincipal`, `TokenVerifier.verify`, `DatabaseExecutor.withUserTransaction`, Redis ownership, queue names, and health interfaces are introduced once and consumed by later tasks under the same names.
- Review-focus coverage: rollback/client release/identity isolation belongs to Task 2; token failure classes to Task 3; bounded Redis shutdown to Task 4; queue shutdown to Task 5; dependency health/timeouts to Task 6; secret redaction to Task 1.
- Proportion: seven reviewable tasks separate configuration, database, auth, Redis, queues, lifecycle, and final orchestration without splitting files that must change together.
