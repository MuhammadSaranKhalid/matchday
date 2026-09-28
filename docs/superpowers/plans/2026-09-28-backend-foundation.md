# Matchday Backend Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Phase 1 NestJS 12 modular-monolith foundation with API and worker applications, validated configuration, structured logging, health endpoints, secure API bootstrap, Docker, CI, Vitest, oxlint, and dependency-direction architecture tests—without implementing chat or database infrastructure.

**Architecture:** Add a Nest native workspace beside the existing Flutter, Supabase, website, and media-worker code. `apps/api` is an HTTP application; `apps/worker` is a standalone application context. Cross-cutting foundation code lives in narrowly scoped `libs/platform` packages and stable contracts in `libs/shared-kernel`; no chat module, PostgreSQL client, Redis client, Socket.IO gateway, BullMQ queue, or schema migration is introduced in this phase.

**Tech Stack:** Node.js 24 active LTS, pnpm, ESM, strict TypeScript, NestJS 12.1.x, Nest CLI 12.0.x, `@nestjs/config`, `@nestjs/terminus`, `@nestjs/swagger`, `@nestjs/throttler`, `nestjs-pino`/Pino, Helmet, class-validator/class-transformer, Zod, Vitest 5, oxlint 1.x, Docker, Docker Compose.

**Spec:** `docs/backend/ARCHITECTURE.md` with companion constraints in `docs/backend/DEPLOYMENT.md`, `docs/backend/IMPLEMENTATION_STATUS.md`, and the user-provided phase gates.

## Global Constraints

- Phase 1 only: no chat feature, PostgreSQL integration, Supabase token verification, Redis integration, BullMQ, Socket.IO, presence, typing, outbox, notification worker, or Flutter change.
- Use NestJS native workspace metadata with `apps/api` and `apps/worker`; do not create a parallel standalone backend repository.
- Use Node.js 24 because it is Active LTS on 2026-09-28 and satisfies Nest 12's Node requirement; set `engines.node` to `>=24 <25` and `.nvmrc` to `24`.
- Use ESM and TypeScript strict mode. Pin exact direct versions and commit `pnpm-lock.yaml`.
- Use oxlint for linting and Vitest for tests; do not add Jest or ESLint.
- Keep domain code framework-independent and enforce domain/application dependency rules with filesystem architecture tests.
- Do not create application-wide `src/controllers`, `src/services`, `src/repositories`, `common`, `utils`, or `helpers` dumping grounds.
- API bootstrap must include environment validation, `/api` prefix, URI version `v1`, global validation, stable exception mapping, JSON logging, correlation/request IDs, CORS allowlist, security headers, body limits, throttling, shutdown hooks, Swagger, and no production stack traces.
- Worker starts through `NestFactory.createApplicationContext`, opens no HTTP listener, and supports graceful shutdown.
- Phase 1 health readiness represents initialized foundation state only; PostgreSQL and Redis indicators are added in Phase 2.
- Docker images are multi-stage, run as non-root, contain production runtime artifacts, and respond correctly to SIGTERM. Redis is compose-private and not host-published.
- Preserve all existing user changes in the dirty worktree. Do not commit unrelated files.

## Review Focus

- Invalid or missing production environment values must stop startup with field-specific errors and never log secret values; Task 2 owns these tests.
- A caller-supplied malformed request/correlation ID must be replaced with a generated UUID while a valid value is preserved; Task 2 owns these tests.
- Validation, throttling, unknown-route, and unexpected exceptions must all use the same machine-readable error envelope without production stacks; Task 3 owns these tests.
- Readiness must remain false until application initialization completes, while liveness remains independent of future third-party services; Task 4 owns these tests.
- API and worker containers must terminate cleanly and must not run as root or expose Redis publicly; Task 6 owns static and smoke tests.

---

## File Structure

Create or modify only these foundation surfaces:

```text
package.json                 # pnpm scripts, exact backend dependency pins
pnpm-workspace.yaml          # root workspace packages
pnpm-lock.yaml               # reproducible dependency graph
.nvmrc                       # Node 24
nest-cli.json                # native Nest applications/libraries metadata
tsconfig.json                # strict ESM baseline
tsconfig.build.json          # production build exclusions
vitest.config.ts             # unit/integration discovery and aliases
oxlint.json                  # lint policy
.dockerignore
Dockerfile
docker-compose.yml
apps/api/src/
  main.ts
  api.module.ts
  bootstrap/api-bootstrap.ts
apps/worker/src/
  main.ts
  worker.module.ts
libs/platform/src/
  config/{configuration.ts,environment.schema.ts,platform-config.module.ts}
  context/{execution-context.service.ts,request-context.middleware.ts}
  logging/{logging.module.ts,logging.config.ts}
  errors/{application-error.ts,http-exception.filter.ts}
  health/{health.module.ts,health.controller.ts,readiness.service.ts}
libs/shared-kernel/src/
  contracts/error-response.ts
  identifiers/correlation-id.ts
test/architecture/backend-dependencies.spec.ts
test/unit/platform/**/*.spec.ts
test/e2e/api-bootstrap.spec.ts
test/e2e/health.spec.ts
.github/workflows/ci.yml       # add backend job without weakening Flutter gates
docs/backend/IMPLEMENTATION_STATUS.md
```

Each folder receives an `index.ts` only when two or more external consumers need a stable public surface; avoid barrel files that introduce cycles.

### Task 1: Native Nest Workspace and Architecture Guardrails

**Files:**
- Create: `package.json`
- Create: `pnpm-workspace.yaml`
- Create: `pnpm-lock.yaml`
- Create: `.nvmrc`
- Create: `nest-cli.json`
- Create: `tsconfig.json`
- Create: `tsconfig.build.json`
- Create: `vitest.config.ts`
- Create: `oxlint.json`
- Create: `apps/api/tsconfig.app.json`
- Create: `apps/worker/tsconfig.app.json`
- Create: `apps/api/src/main.ts`
- Create: `apps/api/src/api.module.ts`
- Create: `apps/worker/src/main.ts`
- Create: `apps/worker/src/worker.module.ts`
- Create: `test/architecture/backend-dependencies.spec.ts`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: none.
- Produces: `ApiModule`, `WorkerModule`, root aliases `@app/*`, `@platform/*`, `@shared-kernel/*`, and scripts `build`, `build:api`, `build:worker`, `lint`, `test`, `test:architecture`, `test:e2e`, `start:api`, `start:worker`.

- [ ] **Step 1: Write the architecture test**

Create Vitest cases that recursively scan first-party TypeScript source and assert:

1. Files under any `domain/` do not import Nest, Redis, PostgreSQL, BullMQ, Socket.IO, Supabase SDK, `infrastructure/`, or `presentation/`.
2. Files under any `application/` do not import `infrastructure/` or `presentation/`.
3. No `src/controllers`, `src/services`, `src/repositories`, `common`, `utils`, or `helpers` directory exists in the backend workspace.
4. No backend file imports from Flutter `lib/`, `website/`, or the legacy `media-worker/`.
5. Both Nest project names and roots exist in `nest-cli.json`.

- [ ] **Step 2: Run the architecture test to verify it fails**

Run: `corepack pnpm vitest run test/architecture/backend-dependencies.spec.ts`

Expected: FAIL because the workspace metadata and application roots do not exist.

- [ ] **Step 3: Create the pnpm/Nest/TypeScript workspace**

Pin these audited direct versions: `@nestjs/common`, `@nestjs/core`, and `@nestjs/platform-express` 12.1.0; `@nestjs/cli` 12.0.7; `reflect-metadata` 0.2.2; `rxjs` 7.8.2; TypeScript `~6.0.2`; Vitest 5.0.2; oxlint 1.85.0; `tsx` 4.23.15. Add only packages used by Tasks 2–4 when creating the lockfile. Configure `module`/`moduleResolution` for Node ESM, `strict: true`, decorators, metadata, source maps, and `noUncheckedIndexedAccess: true`.

The minimal application entrypoints expose `bootstrapApi(): Promise<void>` and `bootstrapWorker(): Promise<INestApplicationContext>` so later tasks can replace bootstrap internals without changing scripts.

- [ ] **Step 4: Install and verify the workspace**

Run: `corepack pnpm install --frozen-lockfile=false && corepack pnpm test:architecture && corepack pnpm build`

Expected: dependency installation succeeds, architecture suite passes, and both applications compile.

- [ ] **Step 5: Commit the coherent workspace foundation**

Stage only Task 1 files and commit with `build(backend): add Nest workspace foundation`.

### Task 2: Validated Configuration, Execution Context, and Structured Logging

**Files:**
- Create: `libs/platform/src/config/environment.schema.ts`
- Create: `libs/platform/src/config/configuration.ts`
- Create: `libs/platform/src/config/platform-config.module.ts`
- Create: `libs/platform/src/context/execution-context.service.ts`
- Create: `libs/platform/src/context/request-context.middleware.ts`
- Create: `libs/platform/src/logging/logging.config.ts`
- Create: `libs/platform/src/logging/logging.module.ts`
- Create: `libs/shared-kernel/src/identifiers/correlation-id.ts`
- Create: `test/unit/platform/environment.schema.spec.ts`
- Create: `test/unit/platform/execution-context.service.spec.ts`
- Create: `test/unit/platform/logging.config.spec.ts`
- Modify: `apps/api/src/api.module.ts`
- Modify: `apps/worker/src/worker.module.ts`

**Interfaces:**
- Consumes: Nest modules from Task 1.
- Produces: `parseEnvironment(input: NodeJS.ProcessEnv): Environment`, `buildConfiguration(environment: Environment): PlatformConfiguration`, `ExecutionContextService.run<T>(context: ExecutionContextValues, callback: () => T): T`, `ExecutionContextService.get(): Readonly<ExecutionContextValues>`, `normalizeCorrelationId(value: unknown): string`, and redacted JSON logger configuration shared by both apps.

- [ ] **Step 1: Write failing environment tests**

Test development defaults and production rejection for missing `APP_NAME`, invalid `PORT`, wildcard/invalid `CORS_ORIGINS`, unsupported `NODE_ENV`, and malformed `LOG_LEVEL`. Assert error messages name fields but do not echo candidate secret values. Define `Environment` with `NODE_ENV`, `APP_NAME`, `PORT`, `LOG_LEVEL`, `CORS_ORIGINS`, `BODY_LIMIT`, `THROTTLE_TTL_MS`, `THROTTLE_LIMIT`, and `SWAGGER_ENABLED` only.

- [ ] **Step 2: Run environment tests to verify failure**

Run: `corepack pnpm vitest run test/unit/platform/environment.schema.spec.ts`

Expected: FAIL because `parseEnvironment` is missing.

- [ ] **Step 3: Implement configuration parsing and Nest config module**

Use Zod 4.6.5 for one startup parse. Convert comma-delimited CORS origins into normalized URL origins, reject `*` in production, parse positive integer limits, and expose an immutable typed configuration object through `@nestjs/config` 12.0.1. Do not add Supabase, database, Redis, or queue variables in Phase 1.

- [ ] **Step 4: Run environment tests**

Run: `corepack pnpm vitest run test/unit/platform/environment.schema.spec.ts`

Expected: PASS.

- [ ] **Step 5: Write failing execution-context tests**

Test nested async calls preserve `requestId` and `correlationId`, concurrent promises do not leak context, valid UUID correlation IDs are preserved, malformed IDs are replaced by UUIDs, and optional `userId`, `socketId`, `eventId`, and `jobId` fields are supported.

- [ ] **Step 6: Implement AsyncLocalStorage context and middleware**

Use `AsyncLocalStorage<ExecutionContextValues>` and Node `randomUUID()`. The HTTP middleware reads `x-request-id` and `x-correlation-id`, normalizes them, writes both response headers, and runs the downstream handler inside the context.

- [ ] **Step 7: Write and satisfy structured-logging tests**

Test that logger configuration emits JSON, mixes context IDs into records, and redacts `authorization`, cookies, passwords, Supabase secrets, FCM token fields, and request bodies. Implement with `nestjs-pino` 5.2.1 and Pino 10.3.1; message bodies are absent by default rather than post-processed.

- [ ] **Step 8: Run the task suite and build**

Run: `corepack pnpm vitest run test/unit/platform && corepack pnpm build && corepack pnpm lint`

Expected: all task tests pass; build and oxlint exit zero.

- [ ] **Step 9: Commit**

Stage only Task 2 files and commit with `feat(platform): add validated config and execution context`.

### Task 3: Secure API Bootstrap and Stable Error Contract

**Files:**
- Create: `apps/api/src/bootstrap/api-bootstrap.ts`
- Create: `libs/shared-kernel/src/contracts/error-response.ts`
- Create: `libs/platform/src/errors/application-error.ts`
- Create: `libs/platform/src/errors/http-exception.filter.ts`
- Create: `test/e2e/api-bootstrap.spec.ts`
- Create: `test/unit/platform/http-exception.filter.spec.ts`
- Modify: `apps/api/src/main.ts`
- Modify: `apps/api/src/api.module.ts`

**Interfaces:**
- Consumes: typed configuration, logger, request context, and `ApiModule`.
- Produces: `configureApi(app: INestApplication, config: PlatformConfiguration): Promise<void>`, `ApplicationError(code: string, message: string, status: number, details?: unknown)`, and `ErrorResponse { code; message; status; correlationId; details? }`.

- [ ] **Step 1: Write failing error-filter tests**

Assert consistent envelopes for `ApplicationError`, `BadRequestException` validation details, `ThrottlerException` as `RATE_LIMIT_EXCEEDED`, unknown errors as `INTERNAL_ERROR`, and production omission of stack/database error data. Every response must include the context correlation ID.

- [ ] **Step 2: Run filter tests to verify failure**

Run: `corepack pnpm vitest run test/unit/platform/http-exception.filter.spec.ts`

Expected: FAIL because the error types/filter do not exist.

- [ ] **Step 3: Implement the error contract and global filter**

Map validation errors into `details.validation`, never expose raw error objects, and log unexpected errors once with safe context.

- [ ] **Step 4: Write failing API bootstrap e2e tests**

Create an in-memory Nest app and assert:

- `/api/v1/...` URI versioning and global prefix behavior.
- Whitelisted CORS origin accepted and an unlisted origin rejected.
- Helmet headers exist.
- JSON body over configured limit returns 413 in the stable envelope.
- Unknown property/invalid DTO returns 400 with validation details.
- Repeated requests cross the configured throttle and return code `RATE_LIMIT_EXCEEDED`.
- Valid incoming correlation ID is echoed; malformed ID is replaced.
- `/api/docs` and OpenAPI JSON are available only when configured.

- [ ] **Step 5: Run e2e tests to verify failure**

Run: `corepack pnpm vitest run test/e2e/api-bootstrap.spec.ts`

Expected: FAIL because `configureApi` is missing.

- [ ] **Step 6: Implement API bootstrap**

Use `ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true })`, URI versioning with default `1`, prefix `api`, Helmet 8.3.0, Express JSON/urlencoded limits, `@nestjs/throttler` 6.7.1, Swagger 12.0.2 bearer auth, Pino logger, shutdown hooks, and the global filter. Do not add auth guards or chat routes.

- [ ] **Step 7: Run API tests, lint, and build**

Run: `corepack pnpm vitest run test/unit/platform/http-exception.filter.spec.ts test/e2e/api-bootstrap.spec.ts && corepack pnpm lint && corepack pnpm build:api`

Expected: tests pass and both commands exit zero.

- [ ] **Step 8: Commit**

Stage Task 3 files and commit with `feat(api): add secure versioned bootstrap`.

### Task 4: Foundation Health and Worker Lifecycle

**Files:**
- Create: `libs/platform/src/health/readiness.service.ts`
- Create: `libs/platform/src/health/health.controller.ts`
- Create: `libs/platform/src/health/health.module.ts`
- Create: `test/e2e/health.spec.ts`
- Create: `test/unit/platform/readiness.service.spec.ts`
- Create: `test/unit/worker/worker-bootstrap.spec.ts`
- Modify: `apps/api/src/api.module.ts`
- Modify: `apps/worker/src/main.ts`
- Modify: `apps/worker/src/worker.module.ts`

**Interfaces:**
- Consumes: config/logging modules and API bootstrap.
- Produces: `GET /health/live`, `GET /health/ready`, `ReadinessService.markReady()`, `ReadinessService.markStopping()`, and `bootstrapWorker(): Promise<INestApplicationContext>`.

- [ ] **Step 1: Write failing readiness unit tests**

Assert initial not-ready, ready after `markReady`, and not-ready after `markStopping`; transitions are idempotent.

- [ ] **Step 2: Implement readiness state**

Keep it process-local for Phase 1. Phase 2 will compose PostgreSQL and Redis Terminus indicators without changing endpoint shapes.

- [ ] **Step 3: Write failing health e2e tests**

Assert `/health/live` returns 200 while readiness is false, `/health/ready` returns 503 before initialization and 200 after readiness, both are outside the `/api/v1` business prefix, and responses contain no environment secrets.

- [ ] **Step 4: Implement health endpoints**

Use `@nestjs/terminus` 12.1.0. Liveness checks only application responsiveness. Readiness checks `ReadinessService` only in this phase.

- [ ] **Step 5: Write failing worker lifecycle tests**

Mock `NestFactory.createApplicationContext` and assert the worker does not call an HTTP `listen`, uses buffered logging, flushes logs, enables shutdown hooks where supported, marks ready after initialization, and marks stopping/closes on SIGTERM through a testable shutdown coordinator.

- [ ] **Step 6: Implement worker bootstrap and graceful shutdown**

Keep `WorkerModule` free of processors and queue providers. Return the application context for smoke tests and future Phase 2 infrastructure wiring.

- [ ] **Step 7: Run health/worker tests and builds**

Run: `corepack pnpm vitest run test/unit/platform/readiness.service.spec.ts test/e2e/health.spec.ts test/unit/worker/worker-bootstrap.spec.ts && corepack pnpm build`

Expected: all tests pass and both applications compile.

- [ ] **Step 8: Commit**

Stage Task 4 files and commit with `feat(platform): add health and worker lifecycle`.

### Task 5: Production Containers and Local Compose

**Files:**
- Create: `.dockerignore`
- Create: `Dockerfile`
- Create: `docker-compose.yml`
- Create: `test/architecture/container-foundation.spec.ts`

**Interfaces:**
- Consumes: `dist/apps/api/main.js`, `dist/apps/worker/main.js`, Node 24, and validated environment variables.
- Produces: Docker targets/images `api` and `worker`; Compose services `api`, `worker`, and private `redis`.

- [ ] **Step 1: Write failing container architecture tests**

Statically assert multi-stage builds, Node 24 runtime, non-root `USER`, separate API/worker commands, production install from frozen lockfile, `init: true`, stop grace periods, healthcheck for API, and no Redis `ports` mapping. Assert Compose does not add PostgreSQL or local Supabase.

- [ ] **Step 2: Run container test to verify failure**

Run: `corepack pnpm vitest run test/architecture/container-foundation.spec.ts`

Expected: FAIL because container files do not exist.

- [ ] **Step 3: Implement Docker and Compose foundation**

Use one multi-stage Dockerfile with named API/worker targets or a shared runtime target parameterized by command. Copy production dependencies and compiled artifacts only. Add Compose defaults suitable for local health testing; Redis exists for future phases but no application code connects to it yet.

- [ ] **Step 4: Verify container structure and images**

Run: `corepack pnpm vitest run test/architecture/container-foundation.spec.ts && docker compose config && docker build --target api -t matchday-api:phase1 . && docker build --target worker -t matchday-worker:phase1 .`

Expected: test passes, Compose configuration validates, and both images build.

- [ ] **Step 5: Smoke test runtime identity and liveness**

Run containers through Compose, assert the API health endpoint returns 200, inspect that API/worker run as non-root, send SIGTERM, and confirm both exit within the configured grace period. Stop services without deleting unrelated volumes.

- [ ] **Step 6: Commit**

Stage Task 5 files and commit with `build(backend): add production containers`.

### Task 6: CI Gates and Phase Completion Report

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `docs/backend/IMPLEMENTATION_STATUS.md`
- Test: all backend tests and existing required Flutter architecture gates.

**Interfaces:**
- Consumes: all Phase 1 scripts and artifacts.
- Produces: a backend CI job and evidence-backed Phase 1 status report.

- [ ] **Step 1: Add the backend CI job**

Use Node 24 and Corepack/pnpm cache. Run frozen install, oxlint, architecture tests, unit/e2e tests, and both builds. Keep the existing Flutter and media-worker jobs intact. Do not add deployment or database credentials.

- [ ] **Step 2: Run the complete backend gate locally**

Run:

```sh
corepack pnpm install --frozen-lockfile
corepack pnpm lint
corepack pnpm test
corepack pnpm test:architecture
corepack pnpm test:e2e
corepack pnpm build
docker compose config
```

Expected: every command exits zero with zero failing tests.

- [ ] **Step 3: Run repository compatibility gates**

Run:

```sh
flutter analyze lib/
flutter test test/architecture_test.dart
v=$(grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/*/domain 2>/dev/null || true); test -z "$v"
```

Expected: Flutter analysis reports zero issues, architecture tests pass, and domain purity output is empty. If a pre-existing dirty-worktree failure occurs, record it precisely and prove the backend changes did not touch the failing file; do not claim the gate passed.

- [ ] **Step 4: Inspect the final diff**

Run: `git diff --check && git status --short && git diff --stat && git diff -- . ':!docs/tournament/**' ':!lib/core/widgets/modals/comments_sheet.dart' ':!lib/features/safety/presentation/widgets/safety_menu.dart' ':!test/features/tournaments/baseline_safety_characterization_test.dart'`

Expected: no whitespace errors; only Phase 0/1 backend files and the intended CI/status changes appear in the scoped diff.

- [ ] **Step 5: Update implementation status**

Record files added/changed/deleted, database changes (`none`), exact commands and results, build result, architecture-test result, container result, remaining risks, and Phase 2 as the next gated phase. Do not mark Phase 2 started.

- [ ] **Step 6: Commit**

Stage only CI and backend status changes and commit with `ci: verify backend foundation`.

## Self-Review Record

- Spec coverage: every Phase 1 deliverable is owned by Tasks 1–6; chat and infrastructure work from later phases is explicitly excluded.
- Step scan: each step creates one test, implementation surface, verification, or commit-sized result.
- Type consistency: `PlatformConfiguration`, `ExecutionContextValues`, `ReadinessService`, `configureApi`, `bootstrapApi`, and `bootstrapWorker` have single owning tasks and stable consumers.
- Review-focus coverage: environment rejection, correlation normalization, error envelopes, readiness transitions, and container lifecycle each have an owning test.
- Proportion: the plan describes exact boundaries and externally visible behavior without supplying implementation bodies.
