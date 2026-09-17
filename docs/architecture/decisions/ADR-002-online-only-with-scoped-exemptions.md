# ADR-002: Online-Only Architecture with Scoped Local Exemptions

## Status
Accepted (2026-05-26, Amended 2026-06-07 and 2026-08-22)

## Context
The codebase originally launched with generic offline-first scaffolding: a `SyncService`, a `pending_operations` queue, Last-Write-Wins (LWW) resolution, and local Drift SQLite mirrors across domain entities.

In practice, full offline-first synchronization across relational entities (teams, rosters, roles, tournament brackets, challenges) created immense architectural friction:
- Merge conflict resolution in multi-tenant sports management is mathematically ambiguous.
- Clock skew across mobile devices broke LWW timestamp guarantees.
- Cognitive load and maintenance overhead of maintaining dual schemas (Postgres + Drift) for every single feature slowed delivery without user benefit.

## Decision
We decommissioned general offline-first sync and established **Online-Only by Default** as the core architecture. Repositories read and write directly against Supabase via remote data sources.

We allow **exactly two strictly scoped exemptions**:

### Exemption 1: `messages` Read-Through Cache (2026-06-07)
- Backed by Drift tables `messages_chats`, `messages_messages`, `messages_drafts`.
- Writes still go to Supabase first.
- The local database functions strictly as a cold-start read-through cache for instant inbox and thread painting.
- User sign-out wipes the cache via `AppDatabase.clear()`.

### Exemption 2: `matches` Live-Scoring Write Path (2026-08-22)
- Scored cricket deliveries require instant zero-latency feedback on the field where connectivity may be spotty.
- The cricket rules engine lives in pure Dart (`lib/features/matches/domain/scoring/`).
- Deliveries are appended to a Drift write-ahead log (`ScoringOps`) and drained asynchronously to the `record-ball` Edge Function with client-generated idempotency UUIDs.
- This applies **strictly to an already-started innings**. Match creation, toss, lineup selection, and completion remain online-only.

## Consequences
### Positive
- Massive reduction in code complexity: removed `SyncService`, LWW machinery, and local sync queues.
- Eliminated data inconsistency and merge conflicts.
- High developer velocity and straightforward debugging.

### Negative / Trade-offs
- Features outside messages and live scoring require an active internet connection to read or write data.
- Strict discipline required: AI agents and engineers must never re-introduce offline sync to other features.
