# Match Day — Data Ownership & Source of Truth Matrix

In a distributed mobile architecture combining Supabase PostgreSQL, Edge Functions, local SQLite (Drift), and Ably Realtime, clear data ownership is essential to prevent conflicting state, race conditions, and accidental data duplication.

This document defines the authoritative system of record for every domain entity in Match Day.

---

## 1. Domain Authority Matrix

| Domain Area | Authoritative Source | Transport Layer | Client Mirror / Cache | Concurrency & Conflict Strategy |
|---|---|---|---|---|
| **User Identity & Auth** | Supabase Auth (`auth.users`) | HTTPS (PKCE) | In-memory session | JWT session token with auto-refresh |
| **User Profiles** | PostgreSQL (`profiles`, `player_profiles`) | HTTPS / PostgREST | In-memory Riverpod state | Last write wins on server with `updated_at` |
| **Unclaimed Players** | PostgreSQL (`unclaimed_players`) | HTTPS / PostgREST | In-memory Riverpod state | Claim workflow reconciles via Postgres RPC |
| **Teams & Membership** | PostgreSQL (`teams`, `team_members`, `team_member_roles`) | HTTPS / PostgREST | In-memory Riverpod state | Postgres RPC for invites, claims, succession |
| **Tournament Brackets** | PostgreSQL (`tournaments`, `tournament_fixtures`, `standings`) | HTTPS / PostgREST | In-memory Riverpod state | Server-authoritative draw and standings calculation |
| **Scheduled Matches** | PostgreSQL (`matches`, `match_teams`, `match_players`) | HTTPS / PostgREST | In-memory Riverpod state | Challenge negotiation via Postgres RPC |
| **Live Scoring (Active)** | **Local Dart Engine** (`lib/features/matches/domain/scoring/`) | HTTPS via `record-ball` Edge Function | Drift WAL (`ScoringOps`, `ScoringSnapshots`) | Single writer per innings; append-only queue with client idempotency UUID |
| **Match Deliveries (Durable)** | PostgreSQL (`match_deliveries`, `match_innings_state`) | HTTPS via `record-ball` Edge Function | Drift WAL | Ledger of facts; scorecard derived client-side; total runs generated |
| **Live Match Broadcast** | Ably (`match:<id>`) | WebSockets | In-memory Riverpod state | Ephemeral stream for viewers; reconciled from Postgres on reconnect |
| **Chat Messages** | PostgreSQL (`messages_chats`, `messages_messages`) | Ably (`chat:<id>`) + HTTPS | Drift read-through cache (`messages_*`) | Writes go to Supabase; cache is cold-start instant-paint; wiped on sign-out |
| **Social Posts & Media** | PostgreSQL (`posts`, `post_media`, `media_processing_jobs`, PGMQ) | HTTPS RPCs + Storage API | In-memory `PostStore` (session) + Outbox (staging uploads) | Server read projections + desired-state RPC commands; media job ledger via PGMQ |
| **Notifications** | PostgreSQL (`notification_inbox`, PGMQ) | FCM Push + PostgREST | In-memory Riverpod state | Server queue leases jobs; client marks read |
| **Presence & Typing** | Ably Realtime | WebSockets | In-memory UI state | Ephemeral presence sets; auto-expired on socket disconnect |

---

## 2. In-Depth Domain Ownership Policies

### 2.1 Identity and Team Roles
- `auth.users` holds authentication credentials.
- `profiles` holds application identity (display name, username, avatar).
- `player_profiles` holds cricket-specific attributes (batting style, bowling style).
- `unclaimed_players` represents players on team rosters who have not yet registered an account.
- **Rule**: Never fabricate an `auth.users` entry for an unclaimed player. When an unclaimed player registers, reconcile using the claim RPC.

### 2.2 The Live Scoring Dual-Authority Model
Live match scoring has a unique, deliberate division of authority:
1. **The Active Scoring Device is the Authority on Arithmetic**:
   - The cricket rules engine lives in **pure Dart** (`lib/features/matches/domain/scoring/`).
   - The scoring device computes runs, wickets, extras, striker rotation, and innings totals immediately on-device.
   - Deliveries are logged to a Drift write-ahead log (`ScoringOps`) and displayed to the scorer without waiting for network acknowledgment.
2. **The `record-ball` Edge Function is the Authority on Ingestion**:
   - Deliveries drain asynchronously from the client outbox to `record-ball`.
   - `record-ball` verifies scorer authorization, rejects duplicate deliveries using the client-generated idempotency UUID, persists the delivery row to `match_deliveries`, and updates `match_innings_state`.
   - It does **not** recompute cricket arithmetic.
3. **The Scorecard is Derived from the Ledger**:
   - `match_deliveries` stores immutable delivery facts.
   - There are no separate batsman/bowler summary tables in PostgreSQL; summaries are derived from the delivery ledger.
   - **Scope Boundary**: This local-first write path applies **strictly to recording deliveries in an active innings**. Match setup, toss, lineup selection, and match finalization remain online-only operations.

### 2.3 Messages and Chat Caching
- **Postgres is Authoritative**: Every chat message must be inserted into PostgreSQL.
- **Drift is Read-Through**: The messages feature caches threads locally in SQLite for instant startup paint.
- **Cache Invalidation**: Signing out of the application executes `AppDatabase.clear()`, completely wiping local SQLite storage to prevent cross-user data leakage.

### 2.4 Ephemeral Presence
- Active viewer counts for a match, user online status, and typing indicators live in **Ably Realtime**.
- These values are ephemeral: they are never written to PostgreSQL tables or stored in Drift.
- When an Ably client disconnects, its presence entry automatically clears.

### 2.5 Social Posts & Media Publishing Pipeline
- **Canonical Store**: PostgreSQL is the single source of truth for all published posts, engagement counts, viewer interactions, and media metadata.
- **CQRS Read Projections**: Feeds, profiles, saved posts, and post details are served via dedicated read model RPCs (`get_home_feed`, `get_profile_posts`, `get_saved_posts`, `get_post_detail`).
- **Normalized Client Session**: In Flutter, `PostStore` acts as the normalized L1 session cache (`Map<PostId, Post>`), while query controllers (`FeedController`, `SavedPostsController`) manage membership lists (`List<PostId>`) and keyset pagination cursors.
- **Publishing Outbox**: A client-side publishing outbox stages multi-photo uploads to Supabase Storage before queueing the backend media job. Once published, the local record is purged and PostgreSQL becomes canonical. No offline feeds, offline likes, or offline comments exist.
- **Durable Media Processing**: Media derivative generation (1080p WebP, BlurHash, multi-resolution variants) is orchestrated asynchronously via a PostgreSQL job ledger and PGMQ queues, processed by the Vercel media worker. Direct client mutations to `posts` and `post_media` are revoked.

