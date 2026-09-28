# Chat Migration from Ably to NestJS

Status: Phase 0 migration map; no cutover performed.

## Behavior to preserve

- Direct, group, team, match, tournament, and broadcast channel shapes.
- Pending DM requests and the single-message request limit.
- Capability checks, channel policies, blocks, member restrictions, and membership periods.
- Text/media messages, replies, optimistic edits/deletes, reactions, drafts, pagination, receipts, presence, and typing.
- Globally monotonic `message_seq`, `chat_changes.change_seq`, read/delivery high-water marks, and bounded queries.
- Drift as the Flutter UI source of truth; sign-out clears account-scoped local data.
- Client-generated UUID message IDs and the local outgoing-operation queue.
- Foreground/background notification behavior and notification preferences/mutes.

## Current paths

Read path: Flutter calls `list_my_chats`, table queries, and `chat_changes`; results are mapped into DTOs and committed to Drift.

Write path: Flutter creates optimistic Drift state and an account-scoped local operation, then `OutboxProcessor` invokes Supabase RPCs. PostgreSQL triggers update channel projections, publish Ably events through `pg_net`, and wake chat push processing.

Realtime path: `RealtimeIngestor` subscribes to `user:<userId>:chat` and an open `chat:<channelId>` channel. It handles `channel.updated`, `message.created`, `message.edited`, `message.deleted`, `reaction.updated`, `receipt.read`, `receipt.delivered`, and `typing`. Presence is entered only for active memberships. Typing expires locally.

Recovery path: `CatchUpScheduler` fetches messages after `newestSyncedMessageSeq` and mutations after `newestAppliedChangeSeq`, then advances Drift cursors transactionally.

## Target mapping

| Existing capability | Initial Nest owner | Durable source |
|---|---|---|
| `list_my_chats()` | Chat query handler | Existing RPC/view logic |
| Message/history queries | Chat query handlers | Existing tables and RLS semantics |
| Chat mutation RPCs | Command handlers through repository ports | Existing tables, initially existing RPCs where safest |
| Ably channel events | Socket.IO gateway + outbox consumers | PostgreSQL outbox |
| Ably presence/typing | Redis-backed realtime service | Ephemeral Redis keys |
| `pg_net` chat push wake | Notification BullMQ producer/worker | Outbox + BullMQ |
| Flutter Ably dependency | `ChatRealtimeTransport` adapter | Ably and Socket.IO adapters during dual-run |
| Drift reconciliation | Preserve | Existing local tables/cursors |

## Safe migration sequence

1. Freeze characterization tests for RPC parameters, returned DTO shapes, event names, request-chat behavior, receipt horizons, and reconnection.
2. Add the Nest foundation without chat code.
3. Add PostgreSQL/Redis/auth/queue infrastructure.
4. Move reads behind Nest HTTP while comparing responses with current Supabase reads.
5. Move writes one command at a time. Preserve the same UUID and canonical SQL behavior.
6. Add Socket.IO delivery sourced from durable committed events.
7. Add Redis presence and typing with multi-socket TTL semantics.
8. Replace direct chat push dispatch with outbox-to-BullMQ processing.
9. Add a Flutter transport interface. Run Ably and Socket.IO adapters under controlled flags; only one path mutates Drift for a given cohort, or deduplicate strictly by event/message ID.
10. Test process death, duplicate commands/events, token refresh, reconnect gaps, multi-device receipts, pending requests, blocks, and notification suppression.
11. Measure load and failure recovery.
12. Cut over by cohort, retain rollback, and remove Ably only after parity evidence.

## Dual-run controls

- Feature flags must identify the realtime transport and write owner independently.
- During read migration, writes and Ably triggers remain unchanged.
- During write migration, do not enable both Nest and PostgreSQL trigger publication for the same event without deterministic consumer deduplication.
- Every target event carries `eventId`, and message events carry the existing `message_id` and `message_seq`.
- Rollback means routing the client back to existing RPC/Ably behavior; therefore migrations before cutover must be additive and backward compatible.

## Exact current files to adapt later

Flutter transport and sync:

- `lib/core/realtime/ably_service.dart`
- `lib/core/realtime/ably_provider.dart`
- `lib/features/messages/data/sync/realtime_ingestor.dart`
- `lib/features/messages/data/sync/chat_local_first_engine.dart`
- `lib/features/messages/data/sync/chat_sync_coordinator.dart`
- `lib/features/messages/data/sync/catch_up_scheduler.dart`
- `lib/features/messages/data/sync/outbox_processor.dart`
- `lib/features/messages/data/datasources/chat_remote_data_source.dart`
- `lib/features/messages/data/repositories/chat_repository_impl.dart`

Server-side legacy producers:

- `supabase/migrations/20260101000814_chat_lifecycle.sql`
- `supabase/migrations/20260101000815_chat_realtime_broadcast.sql`
- `supabase/functions/ably-auth/index.ts`
- `supabase/functions/send-chat-push/`

Do not modify these in Phases 1–3 except for separately approved correctness fixes.

## Pre-Phase-4 decisions

- Whether initial Nest commands call existing RPCs or issue equivalent parameterized SQL in explicit transactions. Calling RPCs gives safer parity first; direct SQL gives the required message+outbox transaction but must reproduce auth context and capability checks exactly.
- The additive outbox schema and producer switch strategy.
- The stable HTTP/Socket DTOs and how legacy `message.edited` maps to target `message.updated` during dual-run.
- Whether current client UUID `message_id` remains the public `clientMessageId` or gains an explicit alias in transport contracts. The audit recommends retaining it.
