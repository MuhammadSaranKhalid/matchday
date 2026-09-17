---
name: architecture-review
description: Conducts an in-depth architecture review before implementing non-trivial features, bug fixes, database changes, real-time protocols, or refactors. Use when analyzing architectural feasibility, mapping dependencies, inspecting Supabase schema via MCP, and comparing design alternatives without modifying code.
---

# Architecture Review Skill

Use this skill to evaluate a proposed requirement, map dependencies, inspect existing backend and client structures, compare alternatives, and produce an architectural decision before touching any code.

---

## Workflow Steps

### Step 1: Discover & Map Existing Code
1. Locate the feature directory under `lib/features/<feature>/`.
2. Trace the full flow:
   - **Presentation**: Screen widgets (`presentation/screens/`), component widgets (`presentation/widgets/`), and controllers/providers (`presentation/controllers/`, `presentation/providers/`).
   - **Domain**: Entities (`domain/entities/`), value objects (`domain/value_objects/`), and repository interfaces (`domain/repositories/`). Verify no use-case layer exists.
   - **Data**: DTOs (`data/models/`), remote data sources (`data/datasources/`), and repository implementations (`data/repositories/`).
3. Check for existing similar implementations in the codebase (e.g., how other features handle pagination, image uploads, real-time streams, or authorization) to ensure architectural consistency.

### Step 2: Inspect Backend via Supabase MCP / Schema
1. Inspect affected database tables:
   - Check column definitions, nullability, foreign keys, and indexes.
   - Inspect existing migrations in `supabase/migrations/`.
   - Inspect routines in `docs/database/routines.md` and relationships in `docs/database/relationships.md`.
2. Inspect Row-Level Security (RLS) policies on the target tables.
3. Check for existing database triggers and functions to prevent redundant triggers or conflicting state updates.
4. If an Edge Function is involved, inspect `supabase/functions/<function_name>/index.ts`.

### Step 3: Inspect Real-Time & Communication Layer
1. If real-time updates are needed:
   - Check whether the requirement is ephemeral (presence, typing) or persistent (chat, score updates).
   - Check Ably channel taxonomy (`chat:<id>`, `match:<id>`).
   - Confirm how channel subscriptions are scoped and when they are released (`releaseChannel`).
   - Verify that connection lifecycle rules (pause on background, resume on foreground) are respected.

### Step 4: Evaluate Architectural Feasibility & Trade-Offs
1. **Layer Ownership**: Does this logic belong in the Flutter presentation controller, repository implementation, a Postgres trigger, an atomic RPC function, an Edge Function, or Ably?
2. **State Authority**: Which system is the single authoritative source of truth for this state?
3. **Formulate Alternatives**:
   - Compare at least two distinct approaches (e.g., Client-side orchestration vs. Atomic Postgres RPC; Ably broadcast vs. Supabase table stream).
   - Evaluate trade-offs: complexity, network roundtrips, database load, Ably CCU impact, error recovery, offline resilience.
4. **Identify Risks**: Race conditions, duplicate events, unauthorized reads/writes, offline desync.

### Step 5: Deliver Architecture Review Artifact
Produce an architectural design summary (or Implementation Plan) containing:
1. **Problem Context & Requirements**
2. **Current System State & Findings** (code & DB schema inspected)
3. **Proposed Architectural Design**
4. **Alternatives Considered & Trade-Off Analysis**
5. **Component Breakdown**:
   - Domain layer (entities, value objects, repo contract)
   - Data layer (DTOs, remote data source, repo impl)
   - Presentation layer (providers, controllers, UI)
   - Backend / Database (migrations, RLS, functions, triggers)
   - Real-time (Ably channels & event contracts)
6. **Verification & Quality Strategy**

**DO NOT write or modify application code until this architecture review is approved.**
