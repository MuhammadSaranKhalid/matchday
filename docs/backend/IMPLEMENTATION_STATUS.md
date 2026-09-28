# Matchday Backend Implementation Status

Last updated: 2026-09-28.

## Current gate

Phase 1 — backend foundation: complete and verified. Phase 2 has not started and remains gated on review of this report.

## Phase status

| Phase | Status |
|---|---|
| 0 Audit | Complete |
| 1 Backend foundation | Complete; review gate |
| 2 Infrastructure | Not started |
| 3 Chat read model | Not started |
| 4 Chat write model | Not started |
| 5 Realtime | Not started |
| 6 Presence + typing | Not started |
| 7 Outbox + queues | Not started |
| 8 Notifications | Not started |
| 9 Flutter migration | Not started |
| 10 Load test | Not started |
| 11 Cutover | Not started |

## Phase 1 delivered

- Root NestJS 12 workspace on Node 24 with separate API and worker applications, strict TypeScript/ESM, pinned pnpm, Vitest, and oxlint.
- Validated, immutable, fail-fast environment configuration with production-safe defaults, CORS validation, and bounded trusted-proxy hops.
- AsyncLocalStorage execution context with normalized request/correlation IDs.
- Structured Pino logging covering parser failures and unknown routes, with sensitive-field redaction, query-string omission, and request correlation.
- Stable application/HTTP error envelopes that do not expose production internals.
- Versioned `/api/v1` business surface with Helmet, body limits, CORS, validation, proxy-aware throttling, graceful shutdown, and configurable Swagger that defaults off in production.
- Unversioned `/health/live` and `/health/ready` probes with explicit startup and shutdown readiness transitions.
- Non-HTTP worker bootstrap with buffered logging, tested lifecycle ownership, and graceful shutdown.
- Multi-stage, non-root Node 24 API/worker images plus local Compose services and private Redis for later phases.
- Backend CI gates for frozen install, lint, architecture tests, unit tests, e2e tests, and both application builds.
- Dependency-direction architecture tests preventing domain/framework coupling and cross-project leakage.

No chat feature, PostgreSQL client, Redis client, queue processor, WebSocket gateway, Supabase service integration, or Flutter migration was introduced in Phase 1.

## Change report

Files added:

- Workspace/tooling: `.dockerignore`, `.nvmrc`, `Dockerfile`, `docker-compose.yml`, `nest-cli.json`, `oxlint.json`, `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, `tsconfig.build.json`, `tsconfig.json`, `vitest.config.ts`.
- API: `apps/api/src/api.module.ts`, `apps/api/src/bootstrap/api-bootstrap.ts`, `apps/api/src/main.ts`, `apps/api/tsconfig.app.json`.
- Worker: `apps/worker/src/main.ts`, `apps/worker/src/worker-lifecycle.service.ts`, `apps/worker/src/worker.module.ts`, `apps/worker/tsconfig.app.json`.
- Platform library: all files under `libs/platform/src/config`, `libs/platform/src/context`, `libs/platform/src/errors`, `libs/platform/src/health`, and `libs/platform/src/logging`.
- Shared kernel: `libs/shared-kernel/src/contracts/error-response.ts`, `libs/shared-kernel/src/identifiers/correlation-id.ts`.
- Tests: `test/architecture/backend-dependencies.spec.ts`, `test/architecture/container-foundation.spec.ts`, both files under `test/e2e`, all six backend unit-spec files under `test/unit/platform` and `test/unit/worker`.
- Documentation: `docs/backend/ARCHITECTURE.md`, `docs/backend/CHAT_MIGRATION.md`, `docs/backend/DEPLOYMENT.md`, `docs/backend/QUEUE_ARCHITECTURE.md`, `docs/backend/REALTIME_PROTOCOL.md`, and `docs/superpowers/plans/2026-09-28-backend-foundation.md`.

Files changed:

- `.gitignore` — backend build/editor artifacts.
- `.github/workflows/ci.yml` — additive backend gate; existing Flutter and media-worker jobs retained.
- `docs/backend/IMPLEMENTATION_STATUS.md` — this evidence report.

Files deleted: none.

Database changes: none. No migration, function, trigger, policy, table, index, or seed changed.

Flutter production changes: none.

## Verification evidence

Complete backend gate on 2026-09-28:

```sh
corepack pnpm install --frozen-lockfile  # passed; lockfile unchanged
corepack pnpm lint                       # passed; zero diagnostics
corepack pnpm test                       # passed; 6 files, 32 tests
corepack pnpm test:architecture          # passed; 2 files, 8 tests
corepack pnpm test:e2e                   # passed; 2 files, 12 tests
corepack pnpm build                      # passed; API/worker compiled and runtime imports verified
docker compose config                    # passed
```

Container verification:

```sh
docker build --target api -t matchday-api:phase1 .
docker build --target worker -t matchday-worker:phase1 .
docker compose up -d --build api worker
curl --fail http://localhost:3000/health/live
docker compose exec -T api id -u
docker compose exec -T worker id -u
docker compose stop api worker
```

Both images built. API liveness returned HTTP 200. API and worker ran as UID 1000. Both remained running until signalled and stopped in under one second, within the 15-second grace period. Compose resources created for the smoke test were removed afterward; no volumes were deleted.

Repository compatibility gates:

```sh
flutter analyze lib/                     # passed; no issues
flutter test test/architecture_test.dart # passed; 6 tests
grep domain-package purity gate          # passed; no violating paths
```

The original Phase 1 baseline architecture suite also passed before backend scaffolding (6 tests), so the foundation preserved the existing Flutter dependency rules.

## Remaining risks and explicit deferrals

- Health readiness is intentionally process-local. PostgreSQL and Redis dependency indicators belong to Phase 2.
- The worker uses one inert lifecycle-owned interval until Phase 2 queue consumers provide active handles; shutdown clears it.
- TypeScript compilation preserves the shared source tree beneath each application output. Runtime commands are verified against those emitted paths; switching to a bundler will require updating them.
- Container bases use the Node 24 major tag. Production release hardening should pin an approved digest.
- The bounded `TRUST_PROXY_HOPS` setting must match the controlled production proxy topology; Compose uses one hop.
- No database connection, RLS-preserving server access strategy, Redis connection, BullMQ topology, or secret-provider wiring exists yet.
- Ably, `pg_net` push delivery, existing Flutter chat synchronization, and the standalone media worker remain unchanged.
- The Phase 0 characterization risks remain: RPC parameter compatibility, retry reconciliation, dual publication, pending-DM/block semantics, membership periods, media ordering, optimistic rollback, and active-thread notification suppression.

## Next gated phase

Phase 2 is the next candidate: PostgreSQL/Supabase server connectivity, Redis/BullMQ foundation, dependency-aware readiness, secret handling, and infrastructure tests. It must begin only after Phase 1 review approval. Chat read/write behavior remains out of scope until the later gated phases documented in `CHAT_MIGRATION.md`.
