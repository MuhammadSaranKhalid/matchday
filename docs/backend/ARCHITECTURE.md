# Matchday Backend Architecture — Phase 0 Audit

Status: proposed architecture, not implemented. Audit date: 2026-09-28.

## Executive decision

Add a NestJS modular-monolith workspace to this repository while preserving Supabase PostgreSQL, Auth, Storage, and the existing migration history as authoritative. Run two independently deployable processes from the same codebase: a stateless HTTP/WebSocket API and a worker application context. Redis coordinates Socket.IO, ephemeral presence/typing, throttling, and BullMQ. PostgreSQL remains the only durable chat source of truth.

This is the lowest-risk path because the current Flutter client and database already implement most chat semantics. A separate backend repository would weaken atomic review of Flutter contracts and Supabase migrations; a thin serverless replacement would not provide the requested long-lived WebSocket and worker model.

## Current repository

- Flutter 0.4.9+10, Dart `^3.7.0`, Flutter `>=3.27.0`.
- Supabase Flutter 2.17.2, Ably Flutter 1.2.44, Drift 2.31.x, Riverpod 3.3.1.
- Firebase Messaging 16.7.0 and local notifications 22.3.1.
- Existing Node media worker uses Node 22, npm, CommonJS, Supabase PGMQ RPCs, and Vercel. It is not a reusable Nest foundation, though its job contracts, retry outcomes, and storage adapters are useful migration inputs.
- CI currently validates Flutter architecture and builds the media worker. No Nest, pnpm, Vitest, oxlint, Docker Compose, or backend architecture gates exist.
- The working tree was dirty before this audit. Existing tournament, comments, and safety changes were not modified.

## Existing chat architecture

The UI reads from Drift, not directly from realtime payloads. `ChatRepositoryImpl` coordinates `ChatLocalDataSource`, `ChatRemoteDataSource`, `ChatSyncCoordinator`, `CatchUpScheduler`, `OutboxProcessor`, `ReceiptCoordinator`, and `RealtimeIngestor`. Supabase RPCs persist commands; Ably transports events; catch-up queries Supabase to repair gaps.

The current flow is already close to the target local-first shape:

```text
Supabase RPC/query ----\
                       -> local-first services -> Drift -> Riverpod -> UI
Ably events ----------/
```

The transport seam is incomplete because `ChatLocalFirstEngine`, `ChatSyncCoordinator`, and `RealtimeIngestor` refer directly to Ably concepts. Phase 9 should introduce a transport port while keeping Drift and repository contracts stable.

## Existing durable model to preserve

- `chat_channels`: universal channel root and context links.
- `channel_members`: membership, role, status, mute/archive/pin state, and read/delivery high-water marks.
- `channel_membership_periods`: historical access windows.
- `channel_role_permissions`, `channel_policies`, `channel_member_restrictions`: capability and policy model.
- `messages`: UUID primary key plus a database-generated, globally monotonic `message_seq`.
- `message_attachments`, `message_reactions`, `message_user_state`.
- `chat_changes`: durable per-channel mutation ledger with monotonic `change_seq` for catch-up.
- `private.chat_sync_events`: an unpublished event table that resembles an early outbox but lacks the required claiming/retry lifecycle.
- `channel_receipt_events`: receipt history; current read state is stored efficiently on `channel_members`.

Global `message_seq` is sufficient for `afterSequence` within a channel even though it is not gap-free per channel. Do not add a per-channel counter unless measured query or product requirements demand it.

Client-generated `message_id` currently acts as the idempotency key. The primary key prevents duplicate rows, but `send_channel_message` does not reconcile a duplicate retry to the existing row. Nest must preserve the UUID and make retries return the canonical row. A new `client_message_id` column is not justified by the audit.

## Proposed bounded contexts

```text
apps/
  api/src/{main.ts,api.module.ts,bootstrap/}
  worker/src/{main.ts,worker.module.ts}
libs/
  chat/src/
    domain/{entities,value-objects,events,errors,policies}/
    application/{commands,queries,ports,services}/
    infrastructure/{persistence/postgres,realtime,queue,outbox}/
    presentation/{http,websocket}/
    {chat.module.ts,chat-api.module.ts,chat-worker.module.ts}
  notifications/src/{application,infrastructure,processors}/
  platform/src/{auth,config,database,redis,queue,realtime,health,logging,observability}/
  shared-kernel/src/{identifiers,pagination,errors,contracts}/
test/{architecture,integration,e2e,load}/
supabase/migrations/
```

Keep `website/`, `media-worker/`, Flutter `lib/`, and Supabase functions in place during migration. Phase 0 does not decide whether the existing media worker is later folded into `apps/worker`; that requires a dedicated parity plan.

## Dependency and runtime rules

- Domain is framework-independent.
- Application depends on domain and owns ports.
- Infrastructure implements ports.
- Presentation maps transports to commands/queries and contains no persistence logic.
- API and worker import the same feature libraries.
- PostgreSQL pools, Redis clients, and queue connections are process singletons with bounded settings.
- AsyncLocalStorage carries request, correlation, user, socket, event, and job identifiers.
- All persistent writes remain in Supabase migrations; no ORM migration system is permitted.
- Direct SQL repositories must set the authenticated user context or implement equivalent server-side authorization; using a service credential without resource authorization would bypass current RLS guarantees.

## Initial HTTP mapping

- `GET /api/v1/chats` maps to the existing `list_my_chats()` projection.
- `GET /api/v1/chats/:channelId` composes channel and participant data already queried by Flutter.
- `GET /api/v1/chats/:channelId/messages?afterSequence=` maps to the current delta query on `messages.message_seq`.
- History pagination uses `beforeSequence` and a bounded limit.
- `GET /api/v1/chats/sync` should return inbox changes plus per-channel cursors; it must be designed around current `chat_changes` and Drift cursor fields rather than inventing a second sync ledger.

## Known current defects and risks

1. `ChatRemoteDataSource.createGroupChannel` sends `p_member_user_ids`, while the SQL RPC declares `p_initial_member_ids`.
2. `ChatRemoteDataSource.editChannelMessage` sends `p_body`, while the SQL RPC declares `p_new_body`.
3. Message UUID uniqueness rejects duplicate retries but does not return the prior message, so server idempotency is incomplete.
4. Database triggers call Ably and the chat push Edge Function after insert. A Nest dual-run could duplicate realtime and push unless producer ownership is explicitly gated.
5. Push suppression for an actively viewed chat is currently client-side for foreground notifications. The server still dispatches FCM; the target Redis active-thread policy does not exist.
6. `private.chat_sync_events` is not a production transactional outbox: no `next_attempt_at`, `last_error`, safe claim, or proven relay exists.
7. Ably typing expiry is device-process timer state. It does not provide distributed TTL semantics.
8. Existing Ably auth grants publish on chat channels for typing. Socket.IO must derive identity from the verified handshake, never from payload fields.
9. The repository contains historical documentation that describes chat differently from the current implementation; code and migrations are authoritative.
10. The Node media worker is npm/CommonJS/Node 22 while the target backend is pnpm/ESM and must use the currently compatible active LTS. Integration requires deliberate boundaries, not copying its runtime setup.

## Architecture acceptance gate

Phase 1 may start only after this audit and the companion documents are reviewed. No production or schema changes were made in Phase 0.
