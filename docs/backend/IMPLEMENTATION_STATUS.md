# Matchday Backend Implementation Status

Last updated: 2026-09-29.

## Current gate

Phase 2 — infrastructure: complete and verified locally. The next gate is the image-processing migration to the Nest worker and AWS Lightsail deployment; chat remains paused until that milestone passes.

## Phase status

| Phase | Status |
|---|---|
| 0 Audit | Complete |
| 1 Backend foundation | Complete; review gate |
| 2 Infrastructure | Complete; local verification passed |
| 3 Media processing + Lightsail | Next gated phase |
| 4 Chat read model | Not started |
| 5 Chat write model | Not started |
| 6 Realtime | Not started |
| 7 Presence + typing | Not started |
| 8 Outbox + notifications | Not started |
| 9 Flutter chat migration | Not started |
| 10 Load test | Not started |
| 11 Cutover | Not started |

## Phase 2 delivered

- Singleton PostgreSQL transaction boundary with user/system authorization separation.
- Supabase access-token verification in explicit JWKS and remote modes.
- Lifecycle-owned ioredis connections with bounded health checks and deterministic cleanup.
- BullMQ registration for `notifications`, `media`, and `maintenance`, with bounded exponential retry and retention defaults and no processors yet.
- PostgreSQL/Redis/queue-aware API readiness and fail-fast worker startup.
- Ordered worker shutdown: queues, Redis, then PostgreSQL.
- Disposable PostgreSQL/Redis integration harness and CI integration gate.
- Production Compose wiring for private Redis and externally supplied Supabase configuration; no production PostgreSQL container.

Phase 2 database changes: none. Deployment changes: none. Flutter, Supabase migrations/functions, website, and the existing standalone media worker were not modified.

## Phase 1 delivered

- NestJS 12 workspace under `backend/` on Node 24 with separate API and worker applications, strict TypeScript/ESM, pinned pnpm, Vitest, and oxlint.
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

- Workspace/tooling: `backend/.dockerignore`, `backend/.nvmrc`, `backend/Dockerfile`, `backend/docker-compose.yml`, `backend/nest-cli.json`, `backend/oxlint.json`, `backend/package.json`, `backend/pnpm-lock.yaml`, `backend/pnpm-workspace.yaml`, `backend/tsconfig.build.json`, `backend/tsconfig.json`, `backend/vitest.config.ts`.
- API: `backend/apps/api/src/api.module.ts`, `backend/apps/api/src/bootstrap/api-bootstrap.ts`, `backend/apps/api/src/main.ts`, `backend/apps/api/tsconfig.app.json`.
- Worker: `backend/apps/worker/src/main.ts`, `backend/apps/worker/src/worker-lifecycle.service.ts`, `backend/apps/worker/src/worker.module.ts`, `backend/apps/worker/tsconfig.app.json`.
- Platform library: all files under `backend/libs/platform/src/config`, `backend/libs/platform/src/context`, `backend/libs/platform/src/errors`, `backend/libs/platform/src/health`, and `backend/libs/platform/src/logging`.
- Shared kernel: `backend/libs/shared-kernel/src/contracts/error-response.ts`, `backend/libs/shared-kernel/src/identifiers/correlation-id.ts`.
- Tests: `backend/test/architecture/backend-dependencies.spec.ts`, `backend/test/architecture/container-foundation.spec.ts`, both files under `backend/test/e2e`, all six backend unit-spec files under `backend/test/unit/platform` and `backend/test/unit/worker`.
- Documentation: `docs/backend/ARCHITECTURE.md`, `docs/backend/CHAT_MIGRATION.md`, `docs/backend/DEPLOYMENT.md`, `docs/backend/QUEUE_ARCHITECTURE.md`, `docs/backend/REALTIME_PROTOCOL.md`, and `docs/superpowers/plans/2026-09-28-backend-foundation.md`.

Files changed:

- `.gitignore` — backend build/editor artifacts.
- `.github/workflows/ci.yml` — additive backend gate; existing Flutter and media-worker jobs retained.
- `docs/backend/IMPLEMENTATION_STATUS.md` — this evidence report.

Files deleted: none.

Database changes: none. No migration, function, trigger, policy, table, index, or seed changed.

Flutter production changes: none.

## Verification evidence

Phase 2 local gate on 2026-09-29:

```sh
bash scripts/verify_repository_boundaries.sh             # passed
cd backend
corepack pnpm lint                                       # passed; zero diagnostics
corepack pnpm test                                       # passed; 14 files, 90 tests
corepack pnpm test:architecture                          # passed; 2 files, 13 tests
corepack pnpm test:e2e                                   # passed; 2 files, 15 tests
bash scripts/run-infrastructure-integration.sh            # passed; 5 files, 14 tests
corepack pnpm build                                      # passed; API/worker imports verified
bash scripts/run-infrastructure-integration.sh --app-compose-config # passed
```

The disposable integration project is removed after every run. The separate production Compose Redis service remained healthy and private at `6379/tcp`. No Supabase project, database migration, or deployed service was changed.

Complete backend gate after the repository move on 2026-09-28:

```sh
cd backend
corepack pnpm install --frozen-lockfile  # passed; lockfile unchanged
corepack pnpm lint                       # passed; zero diagnostics
corepack pnpm test                       # passed; 6 files, 32 tests
corepack pnpm test:architecture          # passed; 2 files, 9 tests
corepack pnpm test:e2e                   # passed; 2 files, 12 tests
corepack pnpm build                      # passed; API/worker compiled and runtime imports verified
docker compose config                    # passed
```

Container verification:

```sh
cd backend
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
cd app
flutter analyze lib/                     # passed; no issues
flutter test test/architecture_test.dart # passed; 6 tests
grep domain-package purity gate          # passed; no violating paths
```

The original Phase 1 baseline architecture suite also passed before backend scaffolding (6 tests), so the foundation preserved the existing Flutter dependency rules.

## Repository boundary migration

The repository now has explicit project roots:

```text
app/           Flutter client, tests, platforms, assets, and client tooling
backend/       Nest API/worker workspace, tests, manifests, and containers
supabase/      authoritative migrations, Edge Functions, seeds, and CLI config
website/       independent static/Next-compatible website project
media-worker/  independent media-processing service
```

The root owns documentation, CI, and cross-project scripts only. `website/` and `media-worker/` were not folded into the backend, and Supabase was neither copied nor moved.

Final compatibility evidence on 2026-09-28:

```sh
bash scripts/verify_repository_boundaries.sh                         # passed

cd app
flutter pub get                                                      # passed
flutter analyze lib/                                                 # no issues
flutter test test/architecture_test.dart                             # 6 passed
bash scripts/check_domain_purity.sh                                  # passed
flutter test test/supabase/migration_layout_test.dart                # 3 passed
flutter test test/features/posts/                                    # 32 passed

cd ../backend
corepack pnpm install --frozen-lockfile                              # passed
corepack pnpm lint                                                    # passed
corepack pnpm test                                                    # 32 passed
corepack pnpm test:architecture                                       # 9 passed
corepack pnpm test:e2e                                                # 12 passed
corepack pnpm build                                                   # API/worker build and imports passed
docker compose config                                                 # passed
docker compose build api worker                                      # passed
docker compose up -d api worker                                      # passed
```

The container smoke returned HTTP 200 from `/health/live`, both runtime users were UID 1000, and both processes stopped in 0.273 seconds before `docker compose down` removed only this Compose project's containers and network. The website's dependency-free `npm run build` passed. The media worker's `npm ci && npm run build` passed; its existing Node 22 engine requirement and npm audit findings remain unchanged. Supabase CLI 2.109.1 found the root `supabase/config.toml` through `--workdir .`; no Supabase service was started, reset, linked, pushed, or otherwise mutated.

No migration, Edge Function, database object, deployed service, secret, Flutter behavior, or backend behavior changed. Generated Flutter, Node, Docker, website, and Supabase outputs remain untracked.

Remaining path risks are limited to historical documents that intentionally preserve old command evidence and external tooling that assumes the former root package locations. The structural gate and CI now reject reintroduction of root Flutter/Nest sources. The website has no lockfile because it currently has no dependencies; adding dependencies must include a lockfile before changing its build to `npm ci`.

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

Image processing is next. The reusable Sharp transformation behavior will move from the standalone Vercel worker into the Nest worker, BullMQ `media` becomes the first active queue, Supabase Storage remains authoritative, and a bounded Lightsail-mounted volume provides temporary processing workspace. The old HTTP-triggered worker is retired only after end-to-end production parity. Chat work begins afterward.
