# Matchday Media Processing and Lightsail Design

**Status:** Approved direction; implementation pending
**Date:** 2026-09-29
**Branch:** `backend`

## Goal

Move post-image processing from the Vercel HTTP worker and Supabase PGMQ to the Nest worker on AWS Lightsail. BullMQ `media` becomes the only active media queue. Supabase PostgreSQL remains the durable job ledger and Supabase Storage remains the authoritative object store. Chat work stays paused until this pipeline is deployed and verified.

## End-to-end flow

1. Flutter calls `begin_post_publish`, uploads the client-preprocessed JPEG to private `post-media-staging`, then calls `mark_post_media_uploaded` as it does today.
2. The RPC verifies ownership and object existence and commits a `private.media_processing_jobs` feed job in the same PostgreSQL transaction. It no longer sends PGMQ messages or wakes a Vercel URL.
3. A Nest outbox relay claims available ledger rows with `FOR UPDATE SKIP LOCKED`, enqueues BullMQ jobs with deterministic ID `media:<job_id>`, then marks them dispatched. A crash between enqueue and acknowledgement is safe because BullMQ rejects the duplicate job ID.
4. The Nest media processor validates the versioned payload, claims the ledger job, downloads the staging object through the Storage API into a per-job scratch directory, runs Sharp, uploads immutable WebP variants, and commits the existing feed-ready/optimized database transitions.
5. Feed completion creates the optimize ledger row transactionally. The relay enqueues it. Optimization completion deletes the staging object through the Storage API and removes local scratch files in `finally`.

## Queue and delivery guarantees

- PostgreSQL `private.media_processing_jobs` is the durable outbox and audit ledger; Redis is not the source of truth.
- Delivery is at least once. Processing is idempotent by database `job_id`, BullMQ `jobId`, media stage, and pipeline version.
- One BullMQ queue named `media` carries named jobs `feed` and `optimize`; feed has higher priority.
- Permanent input failures use BullMQ `UnrecoverableError` and mark the media/job failed. Transient Storage, database, and process failures use bounded exponential retry.
- Job completion is acknowledged only after immutable objects and the corresponding database transition succeed.
- Recovery resets expired claims and republishes pending/expired jobs; it never creates a second logical job.

## Storage and scratch volume

- Supabase Storage buckets remain `post-media-staging` (private) and `post-media` (public).
- The worker uses a named Lightsail Docker volume mounted at `/var/lib/matchday-media` only for temporary per-job files.
- Scratch directories are UUID/job-ID scoped, opened without following caller-controlled paths, and removed after success, terminal failure, cancellation, or startup recovery.
- The volume has configurable byte and age limits. Readiness fails when it is not writable or has insufficient free space.
- Final variant paths remain immutable and pipeline-versioned to avoid CDN overwrite staleness. Storage operations use the Storage API, never direct writes to `storage.objects`.

## Image safety and resource bounds

- Preserve the current variants: feed-ready `1080.webp`, then `360.webp`, `540.webp`, `720.webp`, and max-edge `2048.webp`, plus BlurHash and existing database dimensions.
- Accept only the configured JPEG/PNG/WebP staging types and validate detected format rather than trusting extension or metadata.
- Enforce source byte, decoded pixel, dimension, frame/page, download/upload timeout, processing timeout, worker concurrency, and scratch-space limits.
- Strip metadata, auto-rotate once, never enlarge, and cap Sharp/libvips concurrency for the Lightsail CPU/RAM size.
- Do not log access tokens, service keys, signed URLs, object bodies, or full Storage error payloads.

## Security

- Flutter retains user-scoped Storage RLS and the authenticated publish RPC.
- Only the server receives `SUPABASE_SECRET_KEY`; it is never exposed to Flutter or a public image URL.
- Service-key Storage access is limited in application code to database-derived bucket/path pairs. No request payload may supply an arbitrary bucket or path.
- Existing security-definer functions remain explicitly revoked from `public`, `anon`, and `authenticated` unless they are intentional authenticated client commands.
- Any new private-schema functions have fixed `search_path`, explicit grants, and tests for unauthorized execution.

## Cutover

1. Deploy ledger/outbox compatibility changes while the old worker remains available but no longer receives newly committed jobs.
2. Deploy the Nest relay and media processor with processing disabled; verify claims and deterministic enqueue in staging.
3. Enable one worker at low concurrency, run fixture and real-device uploads, and reconcile every ledger row, object, and post state.
4. Exercise retry, worker crash, Redis restart, Storage timeout, corrupt image, disk pressure, and SIGTERM cases.
5. Remove PGMQ media queues, recovery cron, worker slots, Vault Vercel URL/secret, and `pg_net` wake behavior only after the rollback window.
6. Remove the standalone `media-worker/` project and its CI job only after production parity evidence is recorded.

## Explicit exclusions

- No Next.js or Vercel processing API.
- No chat endpoint, WebSocket, presence, notification, or Flutter chat migration.
- No authoritative image data on the Lightsail volume.
- No direct mutation of Supabase Storage metadata tables.
