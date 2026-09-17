# ADR-001: Adoption of Ably for Real-Time Transport

## Status
Accepted (2026-09-14)

## Context
Match Day requires real-time capabilities across two high-frequency domains:
1. **Live Match Ball Broadcast**: Delivering ball-by-ball updates to hundreds of spectators in sub-second latency while a match is in progress.
2. **Chat & Team Messaging**: Direct messaging and team chat with typing indicators and unread counts.
3. **Live Audience Presence**: Displaying active viewers currently watching a live match.

Previously, relying solely on Supabase Realtime (listening to PostgreSQL WAL changes) created potential bottlenecks:
- High ball frequency caused excessive database WAL replication churn.
- Presence tracking consumed PostgreSQL connection pool slots.
- Supabase free/starter tier caps concurrent client connections.

## Decision
We adopt **Ably Realtime** as the dedicated real-time event broker for live match broadcasts, chat messaging, and audience presence:
1. **Separation of Concerns**: Ably is strictly an ephemeral transport layer; Supabase PostgreSQL remains the single authoritative system of record.
2. **Token Authentication via Edge Function**: The client obtains a scoped `TokenRequest` via the `ably-auth` Supabase Edge Function using its existing Supabase JWT. No root Ably API keys are ever shipped in the client.
3. **Channel Namespaces**:
   - `chat:<chat_id>` for messaging and thread presence.
   - `match:<match_id>` for ball updates and spectator presence.
4. **Connection Budget Preservation (200 CCU)**:
   - `AblyService` hooks into `WidgetsBindingObserver`.
   - The WebSocket connection is closed when the mobile app is paused/backgrounded, and reconnected when the app returns to the foreground.

## Consequences
### Positive
- Sub-second latency for live ball broadcasts and chat without generating database read spikes.
- Native Presence API tracks active spectators effortlessly.
- Predictable connection budgeting under the 200 CCU tier.

### Negative / Trade-offs
- Two cloud infrastructure vendors (Supabase + Ably).
- Clients must handle reconnection reconciliation: when returning from background or network drops, state must be verified against Supabase.
