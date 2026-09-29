# Matchday V1 Media Processing on Lightsail

**Status:** Approved in conversation; awaiting written-spec review
**Date:** 2026-09-29
**Branch:** `backend`

## Goal

Move post-image processing from the standalone Vercel worker to the NestJS worker on AWS Lightsail while keeping the first version deliberately small. Flutter uploads image bytes directly to Supabase Storage. NestJS owns post commands, allocates exact object paths, issues signed upload tokens, verifies uploaded objects, and schedules processing. One BullMQ queue and one processor generate the complete image output.

Chat work remains out of scope until this pipeline is implemented and verified.

## V1 decisions

- `POST /posts` creates the draft post and its `post_media` rows; there is no upload-session table.
- NestJS generates every staging path and a Supabase signed upload token for that exact path.
- Flutter uploads each JPEG directly to Supabase Storage; image bytes never pass through NestJS.
- Flutter makes one `POST /posts/:postId/publish` call after all uploads complete.
- There is no per-image upload-completed endpoint.
- `post_media` is the durable business state; V1 adds no `media_processing_jobs` or outbox table.
- One BullMQ queue named `media` carries one named job, `process-image`.
- One worker invocation generates every required variant for one image.
- There is no feed/optimize queue split, PGMQ dispatch, `pg_net` wake call, worker-slot protocol, or Next.js/Vercel processing endpoint.

## System boundary

```text
Flutter                       NestJS API
   |                              |
   | POST /posts                  |
   |----------------------------->|
   |                              | create draft post + post_media
   | paths + signed tokens        |
   |<-----------------------------|
   |
   | JPEG bytes
   |------------------------------------------> Supabase Storage
   |
   | POST /posts/:postId/publish  |
   |----------------------------->|
   |                              | verify expected objects
   |                              | mark media uploaded
   |                              | enqueue deterministic jobs
   |<-----------------------------|
                                  |
                                  v
                             Redis / BullMQ
                                  |
                                  v
                             NestJS Worker
                                  |
                                  +--> Supabase Storage
                                  +--> Supabase PostgreSQL
                                  +--> temporary scratch disk
```

Supabase continues to provide Auth, PostgreSQL, and Storage. The Lightsail deployment initially contains the reverse proxy, NestJS API, NestJS worker, and Redis as separate containers/processes.

## Create-post command

`POST /posts` is authenticated with the user's Supabase access token. The request contains post metadata and an ordered media manifest of at most four images. It does not contain arbitrary storage paths.

In one PostgreSQL transaction, NestJS:

1. Validates the post command and media count.
2. Creates a non-visible draft post owned by the authenticated user.
3. Creates ordered `post_media` rows with server-generated UUIDs.
4. Assigns immutable staging paths under the private `post-media-staging` bucket.

After the transaction, NestJS creates a signed upload token for each server-generated path and returns the post ID, ordered media IDs, paths, and tokens. Supabase currently documents signed upload URLs as valid for two hours; V1 treats that duration as provider-defined rather than implementing another expiry model.

The command must be safe against accidental client retries by using the platform's request-idempotency mechanism or a client command ID. A retry must return the existing draft rather than create another post.

## Direct upload contract

Flutter keeps the existing local pending-post behavior and image preprocessing:

- crop as selected by the user;
- encode a canonical JPEG;
- limit the long edge to 2048 pixels;
- use the existing quality setting;
- upload at most the existing bounded concurrency.

Flutter uploads directly with the signed token to the exact private staging path returned by NestJS. It does not need general Storage insert authority for this flow. V1 does not permit overwrite when creating the token; retry behavior must treat an already-existing object at the expected path explicitly rather than silently replacing it.

## Publish command

`POST /posts/:postId/publish` is the only completion command. It is authenticated, owner-scoped, and idempotent.

NestJS loads the server-owned draft and expected media rows, then verifies every expected staging object through the Supabase Storage API. It checks object existence, exact server-generated path, preliminary byte limit, and declared content type. These metadata checks are not considered authoritative image validation.

When all expected objects are present, NestJS marks each media row `uploaded` and the post `processing`. It then adds one BullMQ job for every image:

```ts
queue: 'media'
name: 'process-image'
jobId: `media-${mediaId}`
data: {
  schemaVersion: 1,
  mediaId,
}
```

BullMQ custom job IDs must not contain `:`. The deterministic ID suppresses duplicate queue entries while that ID remains in the queue. It is an additional safeguard, not the worker's idempotency guarantee.

PostgreSQL and Redis cannot participate in one atomic transaction in this V1 design. The API therefore attempts all deterministic enqueues before returning success. If any enqueue fails, it returns a retryable error and does not treat publication scheduling as complete. A repeated publish call re-verifies state and attempts any required deterministic enqueue again.

This is a conscious V1 tradeoff: there is no transactional outbox. Redis persistence reduces loss risk, but does not provide the same guarantee as a PostgreSQL job ledger. The state model and API must leave a safe route to retry scheduling.

## Business states

The minimum states are:

```text
Post:       draft -> processing -> published
                \-> failed

Post media: pending_upload -> uploaded -> processing -> ready
                                     \-> failed
```

State transitions are conditional and owner-scoped where invoked from the API. The worker atomically claims an eligible media row before processing. A duplicate job returns successfully when the media is already `ready`; an active non-expired claim is not processed concurrently.

A post becomes `published` atomically only when every ordered media row is `ready`. A terminal media failure keeps the post unpublished and records a safe, machine-readable error suitable for a later retry command.

## Worker processing

The separate NestJS worker consumes `process-image` jobs using `@nestjs/bullmq`, `@Processor('media')`, and `WorkerHost`. Sharp processing never runs inside the HTTP API process.

For each media ID, the worker:

1. Loads `post_media` and returns successfully if it is already ready.
2. Atomically claims an eligible row and records processing state/attempt information.
3. Creates a job-scoped scratch directory.
4. Downloads the staging JPEG through the Storage API to scratch disk.
5. Validates the actual bytes before transformation.
6. Generates the complete required output set.
7. Uploads outputs to immutable, pipeline-versioned paths.
8. Commits media dimensions, BlurHash, final paths, and `ready` state.
9. Publishes the post in the same database operation when all sibling media are ready.
10. Deletes the staging object only after durable success.
11. Removes scratch files in `finally`.

Initial output parity is:

| Object | Transformation | WebP quality |
|---|---|---:|
| `360.webp` | width 360, without enlargement | 80 |
| `540.webp` | width 540, without enlargement | 80 |
| `720.webp` | width 720, without enlargement | 80 |
| `1080.webp` | width 1080, without enlargement | 82 |
| `2048.webp` | maximum edge 2048, without enlargement | 84 |

The worker also preserves automatic orientation, source/display dimensions, metadata stripping, and BlurHash behavior. Variants are initially generated sequentially to bound memory and CPU usage on a small Lightsail instance.

Final object paths are immutable:

```text
post-media/<userId>/<postId>/<mediaId>/v1/360.webp
post-media/<userId>/<postId>/<mediaId>/v1/540.webp
post-media/<userId>/<postId>/<mediaId>/v1/720.webp
post-media/<userId>/<postId>/<mediaId>/v1/1080.webp
post-media/<userId>/<postId>/<mediaId>/v1/2048.webp
```

## Validation and security

V1 accepts the canonical JPEG produced by Flutter. Neither the filename nor Storage metadata is trusted. Before Sharp transformation the worker enforces:

- detected JPEG format and valid JPEG structure;
- exactly one image/frame;
- configured byte, dimension, and decoded-pixel limits;
- safe orientation and metadata handling;
- download, processing, and upload timeouts;
- server-derived bucket and object paths only.

All Storage mutations use the Supabase Storage API. Application code never writes directly to the internal `storage` schema.

Only server processes receive the Supabase secret key. Flutter receives a path-specific signed upload token, never the secret. Logs must exclude JWTs, secret keys, signed tokens/URLs, object bytes, and credential-bearing Storage error bodies.

## Retries and cleanup

BullMQ owns execution attempts and exponential backoff with jitter.

- Transient Storage, PostgreSQL, Redis, network, and temporary filesystem failures are retried within a bounded policy.
- Corrupt input, unsafe dimensions, invalid server state, and unsupported schema/pipeline versions are permanent failures.
- Permanent failure is recorded in PostgreSQL before the job becomes terminal.
- Processing remains idempotent across worker crashes and duplicate delivery.
- Staging deletion occurs after final uploads and the successful database transition. A cleanup failure creates an orphan, not data loss.
- Periodic maintenance removes expired drafts, orphaned staging objects, and abandoned scratch directories after a safe retention interval.

## Redis and deployment

Redis runs privately on the Lightsail Docker network with:

- AOF persistence and `appendfsync everysec`;
- a persistent Docker volume;
- `maxmemory-policy noeviction`;
- no public port;
- fail-fast producer connection settings;
- persistent worker reconnection settings.

The worker starts with concurrency one. It uses `/var/lib/matchday-media` as temporary scratch space, checks writability and minimum free space for readiness, and receives a measured 60-120 second graceful-shutdown allowance. Readiness is disabled before new work is stopped and active processing is drained.

## Observability

Structured logs correlate `requestId`, `postId`, `mediaId`, BullMQ job ID, attempt, state, and download/processing/upload/database durations. Metrics cover queue depth, failures, retries, publish-to-ready latency, Redis availability, worker activity, Sharp pressure, and scratch capacity.

Liveness reports process health. Readiness separately reports required PostgreSQL, Redis, Storage, and scratch-volume dependencies for each runtime.

## Verification

Implementation uses test-driven development and covers:

- post creation, authorization, ordering, and idempotency;
- exact server-generated paths and signed upload tokens;
- publish ownership, object verification, and retry behavior;
- deterministic enqueue and partial enqueue failures;
- worker claiming, duplicate delivery, retries, and terminal errors;
- fixture parity for dimensions, orientation, BlurHash, formats, and quality settings;
- corrupt, oversized, multi-frame, and decompression-risk inputs;
- multi-image atomic publication;
- Redis restart and worker termination behavior;
- scratch cleanup, disk-pressure readiness, and graceful shutdown;
- end-to-end behavior with real PostgreSQL and Redis containers plus a controlled Storage adapter.

## Cutover

1. Freeze the current Vercel worker's output behavior with fixtures.
2. Add the V1 post API, Storage adapter, media state transitions, queue producer, and worker behind deployment controls.
3. Validate signed uploads and processing end to end in a non-production environment.
4. Exercise retries, duplicate publish, Redis interruption, worker crash, corrupt input, Storage failure, disk pressure, and SIGTERM.
5. Route new posts to the NestJS path and observe a defined rollback window.
6. Remove media PGMQ, `pg_net` wake logic, worker slots, Vault Vercel worker values, and the standalone `media-worker/` only after parity and recovery evidence is recorded.

## Explicit exclusions

- No upload-session table.
- No media job/outbox table in V1.
- No per-image upload-completed endpoint.
- No NestJS image-byte proxy.
- No feed/optimize queue split.
- No authoritative media stored on Lightsail disk.
- No chat endpoints, WebSockets, presence, or Flutter chat migration.
- No direct mutation of Supabase Storage metadata tables.
