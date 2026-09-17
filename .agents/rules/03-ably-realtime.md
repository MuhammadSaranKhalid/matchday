---
trigger: model_decision
description: Rules for Ably Realtime integration, channel lifecycle, CCU preservation, and event transport.
---

# Ably Realtime Engineering Rules

Match Day uses **Ably Realtime** for high-frequency live match updates, chat messaging, and presence. Follow these rules to ensure scalability, reliability, and cost control.

---

## 1. Transport vs. Source of Truth

- **Ably is an Ephemeral Transport Layer, NOT a Database**:
  - Persistent business state (messages, match scores, team rosters, notifications) lives in **Supabase PostgreSQL**.
  - Ably distributes events to connected clients in sub-second latency.
  - Real-time events synchronize clients with authoritative state; they do not replace database persistence.
- **Persistence First for Durable Actions**:
  - When an event represents a persistent business action (e.g., sending a chat message), the message must be written to Supabase Postgres (either via client repository or Edge Function trigger), and then broadcast via Ably.
  - Clients must be able to reconstruct complete state from Supabase on cold start or after prolonged disconnection.

---

## 2. Channel Scoping & Taxonomy

- Always scope channels as narrowly as possible. Never broadcast to global or multi-tenant channels when a entity-scoped channel exists:
  - **Match Events**: `match:<match_id>` (live ball broadcasts, score updates, innings status)
  - **Chat Messages**: `chat:<chat_id>` (1-on-1 and team chat messages, typing indicators)
  - **User Updates**: `user:<user_id>` (direct notifications or personal triggers)
- Channel names must be uniform and generated via centralized constants or helpers in `lib/core/realtime/`.

---

## 3. CCU Preservation (200 CCU Budget)

The project operates under a **200 Concurrent Connection Unit (CCU)** budget on the free tier:
1. **Background Socket Suspension**:
   - `AblyService` implements `WidgetsBindingObserver`.
   - When the app is paused/backgrounded (`AppLifecycleState.paused`), close the connection (`connection.close()`).
   - When the app resumes (`AppLifecycleState.resumed`), reconnect (`connection.connect()`).
2. **Channel Teardown**:
   - Always release channels when the viewing widget or screen unmounts (`releaseChannel(channelName)`).
   - Never hold open channel subscriptions in background providers that remain alive for the entire session if the user is not viewing that screen.

---

## 4. Authentication via Supabase Edge Function

- **Zero Hardcoded Ably Keys**: Never store Ably API keys or root secrets in the Flutter client.
- **Token Request Flow**:
  - `AblyService` configures `authCallback` on `ClientOptions`.
  - When a token is needed, it calls the Supabase Edge Function `ably-auth` passing the user's Supabase JWT access token.
  - `ably-auth` validates the caller's session, assigns appropriate channel capabilities, and signs an Ably `TokenRequest`.

---

## 5. Reconnection & Idempotency

- **Idempotent Consumers**:
  - Network jitter can cause duplicate message delivery. Event payloads must carry a unique ID (e.g., `message_id`, `delivery_id`, or client idempotency UUID).
  - Consumers must reject or deduplicate events already processed.
- **Reconciliation on Reconnect**:
  - After a disconnect or app resumption, do not assume missed events will all be replayed cleanly.
  - The feature repository should fetch the latest authoritative snapshot from Supabase, then resume listening to the live Ably stream.
