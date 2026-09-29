# Matchday V1 Media Processing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy Vercel/PGMQ image pipeline with direct signed Supabase uploads, one NestJS `media` BullMQ queue, one idempotent image processor, and lightweight recovery on Lightsail.

**Architecture:** NestJS creates draft posts and exact staging paths, then returns two-hour Supabase signed upload tokens. Flutter uploads JPEG bytes directly and calls one publish command; the API verifies all expected objects and enqueues deterministic jobs. A separate NestJS worker generates all current UI variants, updates `post_media`, atomically publishes fully ready posts, and periodically requeues stale business state.

**Tech Stack:** Node.js 24, TypeScript 6, NestJS 12, `@nestjs/bullmq` 12, BullMQ 6, Redis 8, PostgreSQL/Supabase, Supabase Storage, Sharp/libvips, Flutter/Dart, Vitest, pgTAP/Supabase CLI

**Spec:** `docs/superpowers/specs/2026-09-29-media-processing-lightsail-design.md`

## Global Constraints

- Flutter uploads image bytes directly to Supabase Storage; NestJS must never proxy them.
- Use one queue, `media`, and one job name, `process-image`, with job ID `media-${mediaId}`.
- Add no upload-session, media-jobs, outbox, recovery-queue, or feed/optimize tables.
- Accept canonical single-frame JPEG input only, with no more than four images per post.
- Generate 360, 540, 720, 1080, and 2048 WebP variants plus BlurHash using the approved quality contract.
- Use Supabase Storage APIs for object changes; never mutate the internal `storage` schema.
- Keep Sharp work in the worker runtime and use job-scoped scratch files rather than whole-pipeline buffers.
- Pin new production dependencies exactly and consult their current official documentation before integration.

## Review Focus

- A repeated `POST /posts` with the same client command ID returns the same draft and fresh tokens rather than creating another post; Task 4 pins this.
- A partially successful multi-image enqueue returns retryable failure and a repeated publish safely schedules every unfinished image; Task 4 pins this.
- Redis loses an acknowledged job or a worker dies after claiming media; Task 7 pins stale-state recovery.
- A Storage object lies about MIME, is corrupt, multi-frame, or exceeds decoded-pixel limits; Task 6 pins byte-level rejection.
- An app restart encounters expired upload tokens or waits silently for processing completion; Task 5 pins token refresh and bounded status reconciliation.
- Zero-media text posts publish without Storage or Redis, while four-media posts publish only after all four are ready; Tasks 4 and 6 pin both boundaries, including concurrent final-media completion.

---

### Task 1: Freeze Current Image Contract and Add Media Dependencies

**Files:**
- Create: `backend/test/fixtures/media/oriented-source.jpg`
- Create: `backend/test/fixtures/media/small-source.jpg`
- Create: `backend/libs/media/src/domain/media-output-contract.ts`
- Create: `backend/test/unit/media/media-output-contract.spec.ts`
- Modify: `backend/package.json`
- Modify: `backend/pnpm-lock.yaml`

**Interfaces:**
- Consumes: current `media-worker` Sharp dimensions, WebP quality values, auto-orientation, and BlurHash behavior.
- Produces: `MEDIA_OUTPUT_CONTRACT` containing the five immutable names, resize modes, and quality values reused by `SharpImageTransformer` in Task 6.

- [ ] **Step 1: Write a failing contract test** asserting the exact 360/80, 540/80, 720/80, 1080/82, and max-edge-2048/84 entries, immutable `.webp` names, sequential execution policy, and no-enlargement flag.
- [ ] **Step 2: Run `cd backend && pnpm vitest run test/unit/media/media-output-contract.spec.ts`** and confirm failure because the contract does not exist.
- [ ] **Step 3: Add `MEDIA_OUTPUT_CONTRACT` and the two source fixtures, then check current official Sharp, BlurHash, and Supabase JavaScript documentation and add exact production versions of `sharp`, `blurhash`, and `@supabase/supabase-js` with `pnpm add --save-exact`.**
- [ ] **Step 4: Run the focused contract test, `pnpm install --frozen-lockfile`, and `pnpm lint`.** Expect success.
- [ ] **Step 5: Commit** with `test(media): freeze image output contract`.

### Task 2: Replace the Legacy Database Media Lifecycle

**Files:**
- Create: `supabase/migrations/<supabase-cli-generated>_simplify_post_media_v1.sql`
- Create: `supabase/tests/post_media_v1_test.sql`

**Interfaces:**
- Produces: `post_media_status = pending_upload|uploaded|processing|ready|failed`; conditional `claimForProcessing`, `markReady`, `releaseForRetry`, `markFailed`, and `recoverStale` SQL operations; simplified columns from the spec.
- Consumes: existing `posts`, `post_media`, Auth/RLS helpers, and Storage buckets.

- [ ] **Step 1: Create the migration only with `supabase migration new simplify_post_media_v1`; never invent the timestamp.**
- [ ] **Step 2: Write failing pgTAP assertions** for the five enum values, removed legacy columns/functions, owner isolation, conditional claim, transient `processing -> uploaded` release with error/attempt metadata, permanent `processing -> failed`, stale recovery, idempotent ready, parent-post locking during concurrent final-media completion, atomic all-media publication, and text-only publication.
- [ ] **Step 3: Run `supabase db reset` and `supabase test db supabase/tests/post_media_v1_test.sql`.** Confirm the new assertions fail against the old lifecycle.
- [ ] **Step 4: Implement the migration** to convert the development schema, remove feed/optimization columns and media-only PGMQ/`pg_net` functions, update projections, and add fixed-`search_path`, least-privilege transition functions used by the server.
- [ ] **Step 5: Re-run the reset, pgTAP file, and `supabase db lint --local`.** Expect success with no new security warnings.
- [ ] **Step 6: Commit** with `feat(database): simplify post media lifecycle`.

### Task 3: Add Media Configuration and Supabase Storage Adapter

**Files:**
- Create: `backend/libs/media/src/domain/media-policy.ts`
- Create: `backend/libs/media/src/application/ports/media-object-storage.ts`
- Create: `backend/libs/media/src/infrastructure/supabase/supabase-media-storage.service.ts`
- Create: `backend/libs/media/src/media.module.ts`
- Create: `backend/test/unit/media/supabase-media-storage.service.spec.ts`
- Modify: `backend/libs/platform/src/config/environment.schema.ts`
- Modify: `backend/libs/platform/src/config/configuration.ts`
- Modify: `backend/test/unit/platform/environment.schema.spec.ts`

**Interfaces:**
- Produces: `MediaObjectStorage.createSignedUpload(path)`, `headStaging(path)`, `downloadStaging(path, destination)`, `uploadVariant(path, source)`, and `deleteStaging(path)`; typed limits and bucket names.
- Consumes: server-only `SUPABASE_URL` and `SUPABASE_SECRET_KEY`.

- [ ] **Step 1: Write failing environment and adapter tests** for production-required secrets, exact path forwarding, signed-token redaction, missing objects, no-upsert token creation, and server-derived bucket selection.
- [ ] **Step 2: Run the two focused Vitest files** and confirm missing schema/service failures.
- [ ] **Step 3: Implement the narrow adapter and configuration.** Do not expose a generic caller-selected bucket/path mutation API.
- [ ] **Step 4: Run `cd backend && pnpm test -- test/unit/platform/environment.schema.spec.ts test/unit/media/supabase-media-storage.service.spec.ts`.** Expect success.
- [ ] **Step 5: Commit** with `feat(media): add secure storage adapter`.

### Task 4: Implement Create and Publish Post Commands

**Files:**
- Create: `backend/libs/posts/src/application/create-post.service.ts`
- Create: `backend/libs/posts/src/application/publish-post.service.ts`
- Create: `backend/libs/posts/src/infrastructure/post-command.repository.ts`
- Create: `backend/libs/posts/src/http/posts.controller.ts`
- Create: `backend/libs/posts/src/http/post-command.dto.ts`
- Create: `backend/libs/posts/src/posts.module.ts`
- Create: `backend/test/unit/posts/create-post.service.spec.ts`
- Create: `backend/test/unit/posts/publish-post.service.spec.ts`
- Create: `backend/test/e2e/posts.spec.ts`
- Modify: `backend/apps/api/src/api.module.ts`
- Modify: `backend/libs/platform/src/queue/queue-names.ts`
- Modify: `backend/libs/platform/src/queue/queue.module.ts`

**Interfaces:**
- Produces: `POST /posts`, `POST /posts/:postId/publish`, and owner-scoped `GET /posts/:postId/status`; `CreatePostService.execute(principal, command)` and `PublishPostService.execute(principal, postId)`.
- Consumes: Task 2 SQL contract, Task 3 `MediaObjectStorage`, queue name `media`.

- [ ] **Step 1: Write failing unit/e2e tests** for authorization, zero-to-four ordering, five-image rejection, idempotent client command ID, same draft/media/path identities with freshly issued signed tokens on create retry, signed-token generation failure followed by safe retry, foreign drafts, missing/oversized/wrong-MIME objects, repeated publish, partial enqueue failure, zero-media publication without queue calls, and owner-scoped status reads returning processing/published/failed.
- [ ] **Step 2: Run the focused unit and e2e tests** and confirm missing module/controller failures.
- [ ] **Step 3: Implement DTO validation, repositories, services, controller, and API-only producer registration.** Queue data is exactly `{ schemaVersion: 1, mediaId }`; job options use the approved deterministic ID and bounded retry/backoff defaults.
- [ ] **Step 4: Run focused unit/e2e tests plus `pnpm test:architecture`.** Expect success and no worker-only dependency in the API graph.
- [ ] **Step 5: Commit** with `feat(posts): add signed media publish commands`.

### Task 5: Update Flutter to the Signed Upload Workflow

**Files:**
- Modify: `app/lib/features/posts/data/datasources/posts_remote_datasource.dart`
- Modify: `app/lib/features/posts/data/datasources/posts_local_datasource.dart`
- Modify: `app/lib/features/posts/data/repositories/post_command_repository_impl.dart`
- Modify: `app/lib/features/posts/domain/entities/pending_post.dart`
- Modify: `app/lib/features/posts/domain/entities/post_media.dart`
- Modify: `app/lib/features/posts/data/models/post_media_dto.dart`
- Modify: `app/lib/features/posts/data/models/post_media_dto.freezed.dart` through the repository generator
- Modify: `app/lib/features/posts/data/models/post_media_dto.g.dart` through the repository generator
- Modify: `app/test/features/posts/data/repositories/post_command_repository_impl_test.dart`
- Create: `app/test/features/posts/data/datasources/posts_remote_datasource_test.dart`

**Interfaces:**
- Consumes: Task 4 response containing post/media IDs, exact paths, replaceable signed tokens, final publish endpoint, and status read.
- Produces: `PostMediaStatus.pendingUpload|uploaded|processing|ready|failed`; direct `uploadToSignedUrl` calls; durable `clientCommandId`, post/media/path identity, and local pending progress; one publish call after all images upload; silent bounded completion reconciliation.

- [ ] **Step 1: Write failing Flutter tests** proving no publishing RPC or per-image completion call occurs, signed tokens are used for direct Storage upload, two concurrent uploads remain bounded, the client command ID is persisted before/reused across create attempts, app restart before upload and expired-token recovery repeat `POST /posts` with that ID, refreshed tokens retain the same post/media/path identities, create retry after token-generation failure creates no duplicate, text-only posts publish immediately, and final publish happens once after all media succeed.
- [ ] **Step 2: Write failing status-reconciliation tests** proving publish acceptance keeps the optimistic post visible without a processing banner, bounded background status checks remove local files on `published`, expose Retry/Discard on `failed`, and resume after app restart without duplicate publication.
- [ ] **Step 3: Run the focused Flutter tests** and confirm they fail against the RPC workflow.
- [ ] **Step 4: Implement the REST, signed-upload refresh, five-state media mapping, and silent status-reconciliation flow while preserving existing local pending-post semantics.** Regenerate Freezed/JSON code; do not edit generated files manually.
- [ ] **Step 5: Run `cd app && flutter test test/features/posts`, `flutter analyze`, and the repository's Dart formatter check.** Expect success.
- [ ] **Step 6: Commit** with `feat(app): publish posts through signed uploads`.

### Task 6: Implement the Idempotent Sharp Media Processor

**Files:**
- Create: `backend/libs/media/src/application/process-image.service.ts`
- Create: `backend/libs/media/src/application/ports/image-transformer.ts`
- Create: `backend/libs/media/src/application/ports/media-repository.ts`
- Create: `backend/libs/media/src/infrastructure/postgres/postgres-media.repository.ts`
- Create: `backend/libs/media/src/infrastructure/sharp/sharp-image-transformer.ts`
- Create: `backend/libs/media/src/infrastructure/scratch/scratch-workspace.service.ts`
- Create: `backend/apps/worker/src/media/media.processor.ts`
- Create: `backend/test/unit/media/process-image.service.spec.ts`
- Create: `backend/test/unit/media/sharp-image-transformer.spec.ts`
- Create: `backend/test/unit/media/scratch-workspace.service.spec.ts`
- Modify: `backend/apps/worker/src/worker.module.ts`

**Interfaces:**
- Produces: `ProcessImageService.execute(mediaId, attempt)`, `SharpImageTransformer.transform(source, workspace)`, and `@Processor('media') MediaProcessor`.
- Consumes: Tasks 1-3 contracts and Task 2 claim/ready/fail transitions.

- [ ] **Step 1: Write failing fixture-driven transformer tests** for JPEG detection, one-frame enforcement, byte/pixel/dimension caps, orientation, BlurHash, all five variants, no enlargement, sequential bounded processing, and corrupt/decompression-risk inputs.
- [ ] **Step 2: Write failing orchestration tests** for ready no-op, conditional claim, immutable v1 paths, transient failure releasing `processing` back to `uploaded` before throwing, permanent error persistence before `UnrecoverableError`, retry after a failure that already uploaded 360/540 outputs, four-image atomic publication, two final media completing concurrently with exactly one published result, upload-before-database ordering, staging-delete-after-commit, and scratch cleanup in `finally`.
- [ ] **Step 3: Run the focused media tests** and confirm missing implementation failures.
- [ ] **Step 4: Implement repository, scratch, transformer, orchestration, and worker processor.** Configure Sharp/libvips and worker concurrency from validated settings; never process inside the API.
- [ ] **Step 5: Run all media unit tests, architecture tests, lint, and build.** Expect success.
- [ ] **Step 6: Commit** with `feat(worker): process post images with sharp`.

### Task 7: Add Stale-Media Recovery and Operational Readiness

**Files:**
- Create: `backend/apps/worker/src/media/media-recovery.service.ts`
- Create: `backend/test/unit/media/media-recovery.service.spec.ts`
- Modify: `backend/libs/platform/src/config/environment.schema.ts`
- Modify: `backend/libs/platform/src/queue/queue-defaults.ts`
- Modify: `backend/libs/platform/src/queue/queue.module.ts`
- Modify: `backend/libs/platform/src/health/readiness.service.ts`
- Modify: `backend/apps/worker/src/worker-lifecycle.service.ts`
- Modify: `backend/apps/worker/src/worker.module.ts`
- Modify: `backend/docker-compose.yml`
- Modify: `backend/test/architecture/container-foundation.spec.ts`
- Modify: `backend/test/unit/platform/queue/queue-defaults.spec.ts`
- Modify: `backend/test/unit/platform/queue/queue.module.spec.ts`
- Modify: `backend/test/integration/platform/process-lifecycle.integration.spec.ts`

**Interfaces:**
- Produces: bounded periodic reconciliation of stale `uploaded`/`processing` rows, scratch readiness, and graceful media-worker shutdown.
- Consumes: deterministic producer from Task 4 and conditional recovery transitions from Task 2.

- [ ] **Step 1: Write failing tests** for separate runtime queue policies: API producers retain bounded `maxRetriesPerRequest` with offline queue disabled, while worker consumers use `maxRetriesPerRequest: null` and persistent reconnect behavior; neither runtime may reuse one undifferentiated connection builder.
- [ ] **Step 2: Write failing tests** for the one-minute schedule, enqueue grace, expired processing claim reset, bounded batches, concurrent reconciler safety, duplicate queue IDs, low-disk readiness, abandoned scratch cleanup, and SIGTERM drain ordering.
- [ ] **Step 3: Run focused unit/integration tests** and confirm missing runtime-specific queue, recovery, and readiness behavior.
- [ ] **Step 4: Implement distinct producer/worker BullMQ connection configuration, recovery, and lifecycle behavior.** Configure Redis AOF, persistent volume, `noeviction`, private networking, worker scratch volume, and 60-120 second stop grace.
- [ ] **Step 5: Run focused tests and `pnpm test:architecture`.** Expect success.
- [ ] **Step 6: Commit** with `feat(media): recover stale processing safely`.

### Task 8: End-to-End Cutover Verification

**Files:**
- Create: `backend/test/integration/media/media-pipeline.integration.spec.ts`
- Modify: `backend/test/integration/docker-compose.yml`
- Modify: `backend/scripts/run-infrastructure-integration.sh`
- Modify: `backend/README.md` or the existing backend operations document
- Delete after parity tests pass: `media-worker/`
- Modify: legacy `media-worker` CI/deployment references

**Interfaces:**
- Consumes: complete API, database, Storage adapter, Redis queue, worker, and Flutter contracts.
- Produces: reproducible verification and development cutover instructions.

- [ ] **Step 1: Write the failing integration scenario** covering create, signed upload stub/emulator, publish, processing, variants, post publication, duplicate publish, Redis restart, worker kill, corrupt input, Storage timeout, low scratch space, and stale recovery.
- [ ] **Step 2: Run `cd backend && ./scripts/run-infrastructure-integration.sh`** and confirm the new scenario fails before wiring.
- [ ] **Step 3: Complete Compose/harness wiring and operational documentation.** The old `media-worker/` source may remain only as a fixture/reference until verification; it is not an active fallback. Remove its source/configuration and remaining media-only Vercel deployment references in the final cutover commit because Task 2 has already removed the old database pipeline.
- [ ] **Step 4: Run the full backend suite:** `pnpm lint`, `pnpm test`, `pnpm test:e2e`, `pnpm test:architecture`, integration harness, and `pnpm build`.
- [ ] **Step 5: Run the affected Flutter post tests and analyzer.** Expect success.
- [ ] **Step 6: Commit** with `chore(media): complete Lightsail pipeline cutover`.

## Final Review Gate

- [ ] Compare every implemented behavior with the approved spec and this plan.
- [ ] Run Supabase database tests/advisors, the complete backend verification matrix, and affected Flutter tests from clean processes.
- [ ] Review the full `backend` branch diff for secrets, direct `storage` schema mutation, generic caller-controlled paths, API-side Sharp imports, obsolete feed/optimize code, and unrelated changes.
- [ ] Record the exact commands and results before claiming completion or beginning deployment.
