# Media Processing and Lightsail Implementation Plan

> **Superseded:** This plan targets the rejected ledger/outbox and feed/optimize architecture. Do not execute it. Replace it only after the V1 written specification has been reviewed and approved.

**Goal:** Make BullMQ `media` the production image pipeline on the Nest worker and prepare a verified AWS Lightsail deployment without starting chat work.

**Reference design:** `docs/superpowers/specs/2026-09-29-media-processing-lightsail-design.md`

## Task 1: Characterize and freeze existing behavior

- Add fixture-driven tests around the current Sharp variant dimensions, no-enlargement behavior, orientation, BlurHash, immutable paths, and corrupt-input classification.
- Record the exact `post_media`, `media_processing_jobs`, publish RPC, Storage bucket, PGMQ, cron, Vault, and Flutter upload contracts.
- Verify fixtures do not require the hosted Supabase project.

## Task 2: Add media configuration and scratch ownership

- Add production-strict Storage URL/secret, scratch path, byte/free-space/age limits, input limits, timeouts, Sharp concurrency, and media worker concurrency configuration.
- Implement a lifecycle-owned scratch workspace with startup recovery and path-containment tests.
- Mount a worker-only named volume at `/var/lib/matchday-media`; keep API and Redis off the volume.

## Task 3: Create the durable BullMQ outbox migration

- Create the migration through `supabase migration new`; do not invent its timestamp.
- Evolve `private.media_processing_jobs` with claim lease, enqueue acknowledgement, retry scheduling, and terminal metadata required by the Nest relay.
- Replace PGMQ dispatch inside publish/feed-ready transitions with durable ledger writes while preserving Flutter RPC responses.
- Add least-privilege private claim/ack/fail/recover functions with fixed `search_path` and explicit grants.
- Run local migration reset/tests and Supabase advisors before committing.

## Task 4: Implement the outbox relay and BullMQ producer

- Add a media application port and PostgreSQL relay adapter under a dedicated media library.
- Claim bounded batches, enqueue deterministic `media:<job_id>` jobs, and acknowledge only after Redis accepts them.
- Test crash windows, duplicate enqueue, expired leases, Redis outage, backoff, and graceful shutdown.

## Task 5: Implement Storage and image-processing adapters

- Add a narrow Supabase Storage adapter using pinned dependencies and bounded streaming I/O.
- Port Sharp/BlurHash behavior into backend-owned core code; do not import `media-worker/` sources.
- Process from job-scoped scratch files with byte/pixel/frame limits, metadata stripping, immutable outputs, and cleanup in `finally`.
- Add golden/metadata tests on x64 and ARM-compatible container builds.

## Task 6: Register the media processor

- Register a Nest `@Processor('media')`/`WorkerHost` only in the worker application.
- Dispatch by BullMQ job name, apply feed priority and bounded concurrency, update job progress, and classify permanent versus transient failures.
- Ensure SIGTERM stops taking jobs and awaits active work inside the Compose grace period or leaves it safely recoverable.

## Task 7: End-to-end verification and legacy cutover

- Run local Supabase + Redis + API/worker integration for upload acknowledgement through final variants and post activation.
- Test duplicate delivery, worker kill, Redis restart, Storage failure, corrupt image, full scratch volume, and staging cleanup.
- Deploy to Lightsail behind TLS, verify non-root UID, private Redis, volume permissions/capacity, health, metrics, logs, backup/restore assumptions, and rollback.
- After an observation window, remove PGMQ media objects, cron/wake/Vault integration, standalone Vercel worker, and its CI job in separately reviewable commits.

## Completion gate

- Every accepted upload reaches `feed_ready` or a stable actionable failure without manual queue repair.
- No job is lost across PostgreSQL commit, Redis outage, worker crash, or deployment restart.
- No service secret, signed URL, source image, or internal endpoint appears in client responses or logs.
- Supabase Storage is authoritative; scratch volume contains no stale job directory beyond the configured recovery age.
- Lightsail production evidence is recorded before chat Phase 3 starts.
