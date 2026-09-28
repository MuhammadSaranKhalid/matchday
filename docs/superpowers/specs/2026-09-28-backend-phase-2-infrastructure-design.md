# Matchday Backend Phase 2 Infrastructure Design

**Status:** Draft for written-spec review
**Date:** 2026-09-28
**Branch:** `backend`

## Purpose

Phase 2 gives the Nest API and worker production-shaped access to Supabase PostgreSQL, Supabase Auth, Redis, and BullMQ. It establishes shared infrastructure contracts, validated configuration, dependency-aware readiness, bounded resource ownership, and isolated integration tests before any chat behavior is moved.

Supabase remains authoritative for PostgreSQL, Auth, Storage, migrations, and existing application data. Redis is ephemeral coordination infrastructure. PostgreSQL is the only durable data store. Phase 2 must not create a competing migration system or silently bypass the authorization guarantees that existing RLS policies provide.

## Scope

Phase 2 includes:

- one bounded PostgreSQL pool per API or worker process;
- transaction helpers that distinguish user-authorized work from explicitly privileged system work;
- Redis connection ownership suitable for commands, BullMQ, and later Socket.IO adapter connections;
- BullMQ registration for `notifications`, `media`, and `maintenance`, with safe default job policies but no processors or producers;
- one Supabase access-token verifier reusable by future HTTP and Socket.IO adapters;
- PostgreSQL and Redis dependency checks in API readiness;
- worker startup checks and graceful resource shutdown;
- secret-safe, production-strict configuration;
- unit, architecture, integration, e2e, build, and container verification.

Phase 2 excludes:

- chat HTTP endpoints, commands, queries, repositories, or DTOs;
- Socket.IO gateways, rooms, protocol events, presence, or typing;
- notification delivery, FCM calls, outbox relay, or BullMQ processors;
- Flutter changes or Ably removal;
- Supabase schema migrations, Edge Function changes, RLS changes, or deployed-resource changes;
- production credential creation, rotation, linking, or deployment.

## Architectural placement

All implementation remains inside `backend/`:

```text
backend/
├── apps/
│   ├── api/src/api.module.ts
│   └── worker/src/worker.module.ts
├── libs/platform/src/
│   ├── auth/
│   │   ├── authenticated-principal.ts
│   │   ├── supabase-token-verifier.ts
│   │   └── auth.module.ts
│   ├── database/
│   │   ├── database.module.ts
│   │   ├── postgres-pool.service.ts
│   │   ├── postgres-health.indicator.ts
│   │   └── transaction-context.ts
│   ├── redis/
│   │   ├── redis.module.ts
│   │   ├── redis-connections.service.ts
│   │   └── redis-health.indicator.ts
│   ├── queue/
│   │   ├── queue.module.ts
│   │   ├── queue-names.ts
│   │   └── queue-defaults.ts
│   └── config/
└── test/
    ├── unit/platform/{auth,database,redis,queue}/
    ├── integration/platform/
    └── e2e/health.spec.ts
```

Exact filenames may be consolidated when a smaller unit has a clearer public API, but ownership and dependency direction must remain unchanged. Platform infrastructure must not import Flutter, Supabase Edge Function implementation code, website code, media-worker code, or future chat domain code.

## PostgreSQL connectivity

Use `pg` through a singleton `Pool` owned by `DatabaseModule`. The pool is created once per process, uses the configured connection string, and closes once during application shutdown. No HTTP request, socket, command, or job creates its own pool.

The preferred production connection for a long-running DigitalOcean process is Supabase's direct connection when the host has compatible IPv6 or the project has an IPv4 add-on. Shared-pooler session mode is the supported fallback for an IPv4-only host. Transaction-mode URLs are not the default because later user-authorized transactions need transaction-local role and claim state; if transaction mode is ever enabled, all state must remain inside one checked-out transaction and its limitations must be tested explicitly.

Configuration owns:

- `DATABASE_URL`;
- `DATABASE_POOL_MAX`;
- `DATABASE_CONNECTION_TIMEOUT_MS`;
- `DATABASE_IDLE_TIMEOUT_MS`;
- `DATABASE_STATEMENT_TIMEOUT_MS`;
- `DATABASE_SSL_MODE` with explicit `disable`, `require`, or `verify-full` values.

Production requires every field with conservative bounded defaults except the URL, which has no default. Errors name invalid fields without echoing credentials or connection strings. Logs may include a non-secret connection mode label but never host credentials, query parameters, or raw URLs.

The first health query is `select 1`. Phase 2 adds no application SQL and no migration.

### Authorization-preserving transaction boundary

Future user-scoped repositories must execute through one transaction helper that:

1. checks out a client;
2. begins a transaction;
3. sets transaction-local authenticated role and verified JWT claims;
4. executes the callback;
5. commits or rolls back;
6. always releases the client.

The helper accepts only the immutable principal produced by the token verifier. It never accepts a caller-supplied user ID. Transaction-local settings prevent identity leakage when a pooled connection is reused. A separate, explicitly named system transaction entrypoint is reserved for worker infrastructure that genuinely requires elevated access. Infrastructure callers cannot accidentally obtain a raw pool through dependency injection; the module exports narrow executor and health contracts.

No authorization decision may use `user_metadata`. Future capability checks may consume trusted `app_metadata`, but resource authorization remains in application/domain logic and PostgreSQL policy primitives.

## Supabase access-token verification

One `SupabaseTokenVerifier` validates tokens for future HTTP and WebSocket presentation adapters. Phase 2 exposes the service and tests it but does not add protected business routes.

Verification mode is explicit:

- `jwks`: verify asymmetric tokens locally using the project's `iss` URL plus `/auth/v1/.well-known/jwks.json`;
- `remote`: validate legacy shared-secret tokens through `GET /auth/v1/user` using the configured publishable key, then validate the decoded registered claims before constructing a principal.

There is no silent fallback between modes. Production startup rejects missing settings for the selected mode. This prevents an asymmetric-key outage or configuration error from quietly switching every request to a slower remote path.

Configuration owns:

- `SUPABASE_URL`;
- `SUPABASE_AUTH_ISSUER`;
- `SUPABASE_AUTH_AUDIENCE`, defaulting to `authenticated`;
- `SUPABASE_AUTH_MODE`, either `jwks` or `remote`;
- `SUPABASE_PUBLISHABLE_KEY`, required only for `remote` mode;
- bounded verification/JWKS request timeout and cache/cooldown settings.

The verifier validates signature through the selected trusted mechanism, exact issuer, allowed audience, expiration, and a UUID subject. It accepts only authenticated user tokens for the user-principal API. It returns an immutable principal containing the verified user ID, role, optional session ID, and trusted application metadata. It never returns the original token and never logs tokens or claims containing personal data.

JWKS caching is bounded and honors key IDs and rotation. Tests cover known-key success, rotated-key refresh, bad signature, unsupported algorithm, wrong issuer/audience, expiration, missing or malformed subject, timeout, and error redaction. Remote-mode tests use a local fake Auth endpoint; they never call a real Supabase project.

## Redis connectivity

Use `ioredis`, which is also the Redis client expected by BullMQ. `RedisModule` owns process-wide connections and shuts them down gracefully.

Connections are separated by behavior:

- a general command connection for health and future ephemeral state;
- BullMQ-managed connections configured from the same validated Redis settings;
- later Socket.IO publisher and subscriber duplicates, which are explicitly deferred until the realtime phase.

No subscriber/blocking behavior shares the general command connection. Phase 2 does not create presence, typing, cache, or active-thread keys.

Configuration owns `REDIS_URL`, connection timeout, command timeout, retry limit, and key namespace. Production requires TLS when the URL scheme or deployment contract requires it. Retry behavior is bounded during startup so an unavailable Redis cannot hang shutdown or readiness indefinitely. Passwords and URLs are redacted from errors and logs.

Redis health uses a bounded `PING`. Redis loss makes readiness fail but does not alter liveness and cannot affect durable PostgreSQL data.

## BullMQ foundation

Use `@nestjs/bullmq` and BullMQ with exactly three queue names:

- `notifications`;
- `media`;
- `maintenance`.

Queue names are constants and use the configured Matchday namespace. Default job options include bounded attempts, exponential backoff, deterministic job IDs when a producer supplies an idempotency key, removal of a bounded number of completed jobs, and bounded failed-job retention. Individual later jobs may narrow these defaults but may not silently disable retry/idempotency requirements.

Phase 2 registers queue infrastructure only. It does not enqueue jobs, process jobs, schedule repeatable jobs, or move the independent `media-worker/` into Nest. Empty queues do not imply readiness by themselves; Redis connectivity and successful module initialization do.

## Lifecycle and readiness

`/health/live` remains a process-only probe and does not call external services.

`/health/ready` returns success only when:

- application initialization completed;
- shutdown has not begun;
- PostgreSQL responds within its health timeout;
- Redis responds within its health timeout;
- required queue modules initialized.

The response uses stable component labels and contains no addresses, usernames, stack traces, or secrets. A failed dependency returns HTTP 503 through Terminus while liveness remains HTTP 200.

The worker remains a non-HTTP Nest application context. It performs bounded PostgreSQL and Redis startup checks before marking itself initialized. If required infrastructure cannot be reached during startup, it exits nonzero rather than idling as a false-healthy worker. On SIGTERM, both applications reject readiness, stop accepting new work, close queue resources, close Redis connections, close the PostgreSQL pool, and exit within the existing Compose grace period.

## Configuration and secrets

Configuration is parsed once and exposed as immutable typed values. Development and test environments may use explicit safe local defaults supplied by test harnesses. Production has no defaults for credentials or network endpoints.

Secret fields are registered with the logging redaction policy. Validation errors identify field names only. Test fixtures use synthetic credentials. No `.env` file, connection string, JWT secret, database password, Redis password, Supabase secret key, or service-role key is committed.

The API and worker consume the same configuration schema, while process-specific modules request only the sections they own.

## Isolated integration-test environment

Integration tests use a test-only Compose file under `backend/test/integration/` with disposable PostgreSQL and Redis services. It is not imported by `backend/docker-compose.yml`, does not expose a production topology, and never starts or mutates the root Supabase project.

The integration harness:

- uses random or collision-resistant project/port allocation;
- waits on container health rather than fixed sleeps;
- injects synthetic URLs through process environment;
- proves pool reuse, bounded concurrent acquisition, rollback, client release, transaction-local identity isolation, dependency health transitions, Redis reconnect bounds, and graceful shutdown;
- removes only its own containers and network, without deleting unrelated volumes.

JWT tests use locally generated asymmetric keys and an in-process JWKS/Auth fixture. They do not require internet access or real project credentials.

CI runs unit and architecture tests without Docker, then runs the infrastructure integration suite on a Docker-capable runner. Container smoke tests continue to build the production API and worker images using `backend/` as their only context.

## Error handling and observability

Infrastructure errors are translated into stable internal categories such as configuration invalid, database unavailable, database timeout, Redis unavailable, auth token invalid, and auth verification unavailable. Raw driver errors, URLs, credentials, tokens, and JWT payloads are not returned to clients or emitted to ordinary logs.

Operational logs include component, event, duration, attempt number, and existing correlation/job context when available. Phase 2 adds no metrics backend, tracing vendor, or dashboard. The event names and health labels remain stable so observability can be added later without changing business APIs.

## Dependency rules

Every new dependency has one concrete owner:

- `pg`: PostgreSQL pool and transactions;
- `ioredis`: Redis and BullMQ-compatible connections;
- `bullmq` and `@nestjs/bullmq`: named queue infrastructure;
- `jose`: JWT and JWKS verification.

No ORM, Supabase JavaScript client, cache abstraction, general retry library, schema migration library, Socket.IO package, or testcontainers framework is added in this phase. Docker Compose and small Vitest fixtures are sufficient for integration orchestration.

Architecture tests continue enforcing that domain and application code cannot import these concrete infrastructure packages. Platform modules expose narrow contracts rather than raw clients wherever authorization or lifecycle correctness depends on the wrapper.

## Verification and acceptance

Phase 2 is complete only when all of the following pass:

- frozen dependency installation and exact lockfile review;
- oxlint, TypeScript builds, unit, architecture, and e2e suites;
- environment validation and secret-redaction tests;
- local JWKS and remote Auth-mode token-verification tests;
- disposable PostgreSQL/Redis integration tests;
- API readiness transitions for healthy database/Redis, either dependency failing, and shutdown;
- worker startup failure and bounded SIGTERM tests;
- production API and worker image builds, UID 1000 checks, liveness/readiness probes, and graceful shutdown;
- root repository-boundary verification;
- confirmation that `supabase/`, `app/`, `website/`, and `media-worker/` behavior and tracked contents are unchanged.

The implementation report records exact commands, test counts, container evidence, dependency additions, files changed, and explicit confirmation that no migration or deployed service changed.

## Rollout and failure boundaries

This phase is foundation-only and is not deployed or connected to production by the implementation work. Supplying production credentials and deploying the resulting containers are separate operational actions.

PostgreSQL or Redis failure removes readiness and may prevent worker startup, but never changes liveness semantics. Redis loss cannot lose durable application data. Authentication verification failure rejects authentication; it never trusts decoded-but-unverified claims. Queue initialization failure cannot block or roll back a PostgreSQL business transaction because no business flow uses queues in Phase 2.

## Sequencing after Phase 2

The next gated phase may add the audited chat read model using the database transaction boundary and authenticated principal established here. Chat writes, outbox migrations, Socket.IO, presence/typing, notification delivery, Flutter transport migration, and Ably removal remain separate later phases. Any required Supabase schema change receives its own explicit design and migration review.
