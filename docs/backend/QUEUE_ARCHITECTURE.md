# Queue and Outbox Architecture

Status: proposed from Phase 0 findings; not implemented.

## Existing state

Chat persistence is synchronous in Supabase RPCs. PostgreSQL triggers then call Ably and `send-chat-push` through `pg_net`. General notifications use database queue functions, and the separate media worker consumes Supabase PGMQ through RPCs. `private.chat_sync_events` records some event fields but is not relayed and does not satisfy the requested retry/claim contract.

These paths must coexist until their workloads are migrated. Do not silently replace the media or notification queues during the chat foundation phases.

## Target queues

- `notifications`: FCM decision and delivery work.
- `media`: future consolidation only; keep the current media worker until explicitly migrated.
- `maintenance`: bounded scheduled cleanup/recovery.

Realtime publication is driven by the outbox relay and a dedicated publisher abstraction. It need not become a general BullMQ queue unless measurements or retry isolation justify it.

## Transactional outbox

An additive Supabase migration should eventually create an outbox with:

```text
id, event_type, aggregate_type, aggregate_id, payload,
occurred_at, attempt_count, processed_at, next_attempt_at, last_error
```

Message insert and `message.created.v1` outbox insert occur in one PostgreSQL transaction. Claims use bounded batches and `FOR UPDATE SKIP LOCKED`. A relay marks processed only after required publication/enqueue succeeds. Failed claims use capped exponential backoff and retain diagnostic state. A lease/locked-at field may be added if needed for crash recovery, but the final schema must be justified in its migration review.

## Delivery semantics

- Database transaction: exactly one durable message for one idempotency key.
- Outbox relay and BullMQ: at least once.
- Consumers: idempotent by outbox `eventId` or deterministic BullMQ `jobId`.
- Realtime clients: tolerate duplicates and recover gaps through HTTP.
- Notification failure never changes message durability.

## Notification flow

```text
message + outbox commit
  -> relay
  -> notifications job (jobId = eventId:recipientId)
  -> worker loads membership, blocks, mutes, preferences, devices
  -> worker checks Redis active-thread leases
  -> send FCM only when eligible
  -> record bounded outcome / invalidate permanently bad token
```

This preserves the existing preference and invalid-token behavior while moving exact-thread suppression to shared server state.

## Worker policies

- Application context only; no HTTP listener.
- Bounded concurrency per processor.
- Explicit attempts, timeout, exponential backoff with jitter, completion removal, and failed retention.
- Graceful SIGTERM stops new claims and waits for active jobs within a deadline.
- Logs carry `jobId`, `eventId`, `correlationId`, and safe resource IDs.
- Queue depth, failures, processing latency, retries, and outbox backlog are metrics.

## Producer cutover rule

Before Nest owns chat notifications or realtime, disable the equivalent legacy trigger for the migrated cohort/path or guarantee deterministic downstream deduplication. The current `trg_broadcast_message_to_ably` and `trg_dispatch_chat_push` make an ungated dual producer the largest duplication risk.
