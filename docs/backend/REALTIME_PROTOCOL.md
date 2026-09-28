# Realtime Protocol — Proposed v1

Status: audit-derived contract for review; not implemented.

## Connection and identity

Flutter supplies a Supabase access token in the Socket.IO handshake. The API verifies signature, expiration, issuer, and subject with one reusable auth service. The verified subject is the only user identity. The gateway joins `user:{userId}` automatically and authorizes `channel:{channelId}` joins through application policy.

Prefer WebSocket-only transport after Flutter compatibility tests. Socket.IO Redis adapter coordinates API replicas. No durable state depends on one API process.

## Envelope

```json
{
  "v": 1,
  "eventId": "uuid",
  "event": "message.created",
  "occurredAt": "2026-09-28T00:00:00.000Z",
  "correlationId": "uuid",
  "data": {}
}
```

Durable events use the transactional outbox ID as `eventId`. Ephemeral events also receive an ID for traceability but are not replayed.

## Initial commands and events

Implement only when their phase is reached:

- Client commands with ACK: `message.send`, `message.edit`, `message.delete`, `message.read`, `reaction.add`, `reaction.remove`, `typing.start`, `typing.stop`, `channel.join`, `channel.leave`.
- Server events: `message.created`, `message.updated`, `message.deleted`, `message.read`, `message.delivered`, `reaction.added`, `reaction.removed`, `typing.start`, `typing.stop`, `presence.changed`, `channel.updated`, `sync.required`, `error`.

The current legacy names are `message.edited`, `reaction.updated`, `receipt.read`, `receipt.delivered`, and `typing`. The Flutter transport adapter owns legacy-to-v1 translation during dual-run; Drift ingestion should consume one canonical internal event model.

## ACK contract

Successful durable command ACKs include the canonical resource and ordering values. For `message.send`:

```json
{
  "ok": true,
  "correlationId": "uuid",
  "data": {
    "messageId": "client-generated-uuid",
    "channelId": "uuid",
    "sequence": 12345,
    "version": 1,
    "createdAt": "2026-09-28T00:00:00.000Z"
  }
}
```

A repeated send with the same authenticated sender, channel, and message ID returns the same canonical message. It never creates another row.

Errors use `code`, `message`, `status`, `correlationId`, and optional `details`. Payload user IDs are ignored or rejected where identity is implied by authentication.

## Rooms and delivery

- `user:{userId}`: inbox and user-targeted events.
- `channel:{channelId}`: open-thread events.
- Sender ACK is not proof that every participant received realtime delivery; it proves durable commit.
- Outbox consumers publish after commit and may publish more than once. Flutter deduplicates by `eventId` and resource/version; HTTP sync repairs omissions.

## Reconnect

1. Reauthenticate and rejoin required rooms.
2. Reconcile inbox over HTTP.
3. For each active/relevant channel, request messages after the Drift `newestSyncedMessageSeq`.
4. Request mutation ledger entries after `newestAppliedChangeSeq` until a bounded page returns fewer than the limit.
5. Apply messages/changes and cursor advancement in one Drift transaction.
6. Resume live ingestion.

`sync.required` is an optimization signal, not a durable data carrier.

## Presence and typing

Presence is a Redis set/zset-style lease per user and socket with heartbeat TTL. Aggregated user state is online while any socket lease remains. Disconnect performs best-effort removal; expiry handles crashes.

Typing is keyed by channel and user/socket with a short TTL. `typing.start` refreshes the lease, `typing.stop` removes it, and expiry emits/derives the stopped state. It is never written to PostgreSQL, BullMQ, or FCM.

## Security and limits

- Validate DTO size and version before command dispatch.
- Apply per-user, per-socket, and sensitive-command throttles using shared Redis state.
- Bound room joins, catch-up page sizes, message body sizes, and attachment metadata.
- Never log tokens or message bodies by default.
