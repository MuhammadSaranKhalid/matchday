---
trigger: always_on
description: Mandatory Architecture-First Process and core engineering governance for Match Day.
---

# Match Day Engineering Governance

You are working on **Match Day**, a production Flutter application using **Supabase** as the backend system of record and **Ably** for real-time communication.

Your responsibility is not merely to implement requested functionality. You must preserve, defend, and improve the architecture of the system.

---

## Mandatory Architecture-First Process

For every non-trivial feature, bug fix, database change, real-time protocol change, authorization adjustment, or refactor, **DO NOT begin implementation immediately**.

First perform an architecture review.

### Phase 1 — Understand Existing Architecture
Before proposing changes:
1. **Inspect the relevant existing code**: Read related files in `lib/features/`, `lib/core/`, and `docs/`.
2. **Identify current feature boundaries and dependencies**: Understand what layers (`presentation`, `domain`, `data`) and what other features interact with this area.
3. **Trace the complete flow**: Map the request/event lifecycle from UI widgets/controllers -> domain contracts/entities -> repository implementations -> remote data sources -> external infrastructure.
4. **Inspect Supabase via MCP / Schema files**: Inspect the actual database schema, RLS policies, functions, triggers, migrations in `supabase/migrations/`, and relevant configuration rather than assuming their structure.
5. **Inspect Ably channel ownership**: Identify channel scopes (`chat:<id>`, `match:<id>`), event producers, event consumers, persistence boundaries, connection lifecycle, and failure/reconnection behavior.
6. **Identify existing implementations solving similar problems**: Prefer architectural consistency over inventing new patterns unnecessarily.
7. **Never invent database tables, columns, policies, RPCs, triggers, events, repositories, or services when they can be inspected**.

### Phase 2 — Architectural Feasibility
Before implementation, determine:
1. Whether the requested design fits the existing architecture.
2. Which layer should own the behavior.
3. Whether the requirement belongs in Flutter, Supabase/Postgres, an Edge Function, Ably, or another existing component.
4. Whether there is already an architectural primitive or routine that solves the problem.
5. Whether the proposed solution duplicates existing responsibility (e.g., duplicated triggers or redundant state).
6. Whether the design introduces coupling, race conditions, duplicated state, security holes, scalability bottlenecks, or unnecessary infrastructure.
7. **Do not assume the user's proposed implementation is automatically the correct architectural solution.** Treat the requested behavior as the requirement and independently determine the most appropriate implementation.

### Phase 3 — Compare Alternatives
For substantial architectural decisions, consider reasonable alternatives before implementation:
1. Compare alternatives based on:
   - Consistency with the current architecture
   - Correctness and edge-case resilience
   - Complexity and cognitive load
   - Maintainability and modularity
   - Scalability and cost (e.g., Ably CCU limits, Supabase real-time caps)
   - Security and authorization (RLS enforcement)
   - Real-time behavior and latency
   - Failure handling and offline/reconnection recovery
   - Developer experience and testability
2. Do not introduce another service, database object, abstraction, package, queue, event type, or architectural pattern unless it provides a clear benefit.
3. Prefer the simplest design that preserves architectural integrity.

### Phase 4 — Present the Implementation Plan
Before modifying code for a substantial change, produce a concise implementation plan containing:
- Existing behavior and context
- Architectural findings and trade-offs
- Recommended design
- Components and files affected
- Database impact (schema, migrations, triggers, RPCs)
- RLS and security impact
- Real-time impact (channels, events, presence, payload size)
- Important alternatives considered and why they were rejected
- Risks, edge cases, and failure recovery
- Verification strategy
For architecture-sensitive changes, wait for plan approval before implementation when running in planning or review mode.

---

## Clean Architecture Rules

1. **Dependencies must point inward**: Domain knows nothing about Data or Presentation.
2. **Presentation must not contain persistence or infrastructure logic**: Widgets and controllers delegate business operations to repositories.
3. **Domain is pure Dart**: No imports of `flutter`, `flutter_riverpod`, `riverpod_annotation`, `supabase_flutter`, `supabase`, `drift`, `dio`, `http`, or platform-specific packages.
4. **No Use Case layer (2026-05-29 amendment)**: Controllers depend on repositories directly via `ref.read(<feature>RepositoryProvider)`. Business rules live inside the repository implementation.
5. **External systems accessed through boundaries**: Data sources interact with Supabase, Ably, or Firebase; repository implementations catch raw exceptions and return `Either<Failure, T>`.
6. **Do not bypass repository boundaries** merely because directly calling an SDK requires less code.
7. **Do not create abstractions with no meaningful architectural purpose**.
8. **Follow existing project conventions** unless there is a documented architectural reason to change them.

---

## Source-of-Truth Rules

1. **Persistent business state must have one authoritative source of truth**: For Match Day, that source of truth is **Supabase PostgreSQL** (with the single exception of active-innings live scoring computed on-device and drained via the write-ahead log).
2. **Do not maintain independent conflicting versions of the same business state** across Flutter, Supabase, and Ably.
3. **Treat real-time transport and persistent business state as separate concerns**: Ably transports messages, score broadcasts, and presence; it is NOT a database.
4. **When an event represents a persistent business action**, ensure the underlying authoritative state transition is committed even if real-time delivery fails or a client reconnects.
5. **Real-time events should synchronize clients with authoritative state, not become an accidental second database.**

---

## Supabase Rules

1. **Before changing anything related to Supabase**:
   - Inspect the real schema through MCP or migrations in `supabase/migrations/`.
   - Inspect existing RLS policies and table grants.
   - Inspect triggers and functions already attached to affected tables (`docs/database/routines.md`).
   - Inspect related foreign keys and indexes (`docs/database/relationships.md`).
2. **Never weaken RLS simply to make a query work**.
3. **Never expose privileged/service credentials to Flutter**.
4. **Authorization must be enforced server-side/database-side where appropriate**, not merely hidden in the UI.
5. **Multi-row mutations must be atomic**: Use Postgres functions (RPC) or transactions; never issue sequential independent REST calls that leave orphaned state on network failure.
6. **After database changes**, review security and performance implications and verify behavior.

---

## Real-Time Rules (Ably)

1. **Before introducing an Ably event**:
   - Determine who produces it and who may subscribe.
   - Define the channel scope (prefer scoped channels `match:<id>`, `chat:<id>` over global broadcasts).
   - Define authorization requirements (authenticated via `ably-auth` Edge Function).
   - Determine whether the event is ephemeral (typing indicator, active viewer count) or represents persistent state (new chat message, ball bowled).
   - Define reconnection/recovery behavior.
   - Prevent duplicated processing with idempotency keys.
2. **Preserve Connection Capacity (CCU)**:
   - Match Day operates under free-tier limits (200 CCU cap).
   - The connection must pause/disconnect when the app enters the background and reconnect when resumed (`WidgetsBindingObserver` in `AblyService`).
3. **Do not publish duplicate events from multiple layers for the same state transition** without an explicit architectural reason.

---

## Change Discipline

1. **Modify the smallest coherent architectural surface**: Keep edits localized to the relevant feature.
2. **Do not perform unrelated refactors** while implementing a feature unless they are necessary for correctness.
3. **Do not silently change established architecture**.
4. **Preserve documentation integrity**: Retain existing comments, docstrings, and headers unless specifically asked to revise them.
5. **If the requested implementation conflicts with existing architectural principles**, explain the conflict and propose the better design before writing code.

---

## Verification Discipline

Implementation is incomplete until verified:
1. **Static Analysis**: Run `flutter analyze lib/` (must pass with zero issues).
2. **Architecture Tests**: Run `flutter test test/architecture_test.dart` (must pass).
3. **Domain Purity**: Ensure `lib/features/*/domain/` contains zero framework imports.
4. **Diff Inspection**: Audit the final git diff for architectural violations, leftover debug code, and unintended file modifications.
5. **Report**:
   - What changed
   - Why this architecture was chosen
   - How it was verified
   - Remaining risks or follow-up work

**The objective is not maximum code generation. The objective is correct, maintainable architecture with the minimum necessary complexity.**
