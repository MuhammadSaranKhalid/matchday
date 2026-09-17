---
name: debug-feature
description: Investigates, diagnoses, and resolves bugs across Flutter, Supabase, Ably, and local caching in Match Day. Use when tracking down regressions, unexpected state, RLS authorization failures, or real-time event drops.
---

# Debug Feature Skill

Use this skill to systematically isolate, diagnose, and fix bugs in Match Day without causing architectural drift or unintended side effects.

---

## Workflow Steps

### Step 1: Characterize & Reproduce
1. Gather exact symptoms:
   - What was the user action?
   - What was expected vs. what actually occurred?
   - Is there a stack trace, Postgrest error code (e.g., `42501` RLS violation), Ably error, or Flutter crash log?
2. Reproduce through a focused unit/widget test or by tracing deterministic state inputs.

### Step 2: Trace Through the Architecture Layers
Trace the bug layer-by-layer starting from the UI down to the infrastructure:

1. **Presentation Layer**:
   - Is the controller's `build()` or state notifier emitting `AsyncError`?
   - Is a widget rebuilding improperly due to incorrect `ref.watch` vs `ref.read`?
   - Is `ref.listen` missing or firing duplicate side effects?
2. **Repository Layer**:
   - What `Failure` subtype was returned in the `Left` of `Either<Failure, T>`?
   - Did the repository catch an unexpected exception type that escaped to the UI?
   - Is a business rule validation rejecting valid inputs?
3. **Data Source Layer**:
   - Was the Supabase query malformed (wrong column, missing join)?
   - Was an Ably channel detached or uninitialized?
4. **Backend (Supabase / Postgres)**:
   - **RLS Denial**: Does the query return an empty list `[]` when rows exist? This almost always means the RLS policy evaluated to false for `auth.uid()`.
   - **Trigger / RPC Failure**: Inspect `docs/database/routines.md` or live Postgres logs for constraint violations or exceptions raised in plpgsql.
5. **Real-Time (Ably)**:
   - Was the socket closed due to app backgrounding?
   - Was the event name misspelled or sent to the wrong channel scope?
   - Did the client fail to obtain a token via `ably-auth`?

### Step 3: Isolate Root Cause vs. Symptom
- Distinguish between the failure location (e.g., UI crash on null) and the root cause (e.g., repository mapping null entity on RLS denial).
- Never apply quick band-aids (like disabling RLS or adding `try/catch` in UI) to hide root-cause problems in underlying layers.

### Step 4: Apply Minimal Surgical Fix
1. Fix the bug at its true architectural owner:
   - Database/RLS issue -> create a fix migration in `supabase/migrations/`.
   - Data source / mapper issue -> fix DTO mapping or exception handling in repository.
   - UI / state issue -> fix controller logic or provider lifecycle.
2. Maintain layer boundaries: Domain remains pure Dart; DTOs do not leak.
3. Do not perform unrelated refactorings while fixing a bug.

### Step 5: Verify & Prevent Regressions
1. Write or update a test covering the bug condition.
2. Run `flutter analyze lib/` to ensure no lint regressions.
3. Run `flutter test test/architecture_test.dart` to ensure no architectural violations were introduced.
4. Document the root cause and resolution in the completion report.
