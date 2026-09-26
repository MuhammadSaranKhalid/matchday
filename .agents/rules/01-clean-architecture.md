---
trigger: always_on
description: Clean Architecture standards and constraints for Match Day Dart code. Always active.
---

# Clean Architecture — Match Day Invariants

This rule defines the non-negotiable architectural constraints for all Dart code under `lib/`.

---

## 1. Domain is Pure Dart (Rule 1)

Files in `lib/features/*/domain/` and `lib/core/error/` **MUST NOT** import:
- `package:flutter/*`
- `package:flutter_riverpod/*`
- `package:riverpod_annotation/*`
- `package:supabase_flutter/*`
- `package:supabase/*`
- `package:drift/*`
- `package:dio/*`
- `package:http/*`
- Any platform-specific or UI package

Domain files may **only** import:
- `dart:*`
- `package:fpdart/*`
- `package:equatable/*`
- Other domain files in the same feature (or shared domain contracts in `lib/core/`)

If a domain file requires an external system, invert the dependency: define an abstract repository/service interface in `domain/repositories/` and implement it in `data/repositories/`.

---

## 2. No Use-Case Layer (Amendment 2026-05-29)

**DO NOT generate, propose, or reinstate `domain/usecases/*.dart` files or `*UseCaseProvider` providers.**

- Presentation controllers and notifiers depend on **repositories directly**:
  ```dart
  final repo = ref.read(matchesRepositoryProvider);
  final result = await repo.getMatchDetails(matchId);
  ```
- Business rules, validation logic, and multi-step data coordination live inside the **repository implementation** (`data/repositories/*_repository_impl.dart`).
- UI form-level input validation may still occur in the controller using Value Objects before invoking the repository.

---

## 3. Online-Only by Default (Amendment 2026-05-26 & 2026-08-22)

The codebase is **online-only by default**. There is no general offline sync, no LWW (Last-Write-Wins), and no global `SyncService`.

### Only Three Scoped Exemptions:
1. **`messages` Read-Through Cache (2026-06-07)**:
   - Drift-backed read-through cache for inbox (`messages_chats`) and message history (`messages_messages`), plus local drafts (`messages_drafts`).
   - Writes go to Supabase first; cache is strictly a cold-start instant-paint optimization.
   - User sign-out wipes the cache via `AppDatabase.clear()`.
2. **`matches` Live-Scoring Write Path (2026-08-22)**:
   - Ball-by-ball scoring is computed locally on-device by the pure Dart scoring engine (`lib/features/matches/domain/scoring/`).
   - Deliveries append to a drift-backed write-ahead log (`ScoringOps`, `ScoringSnapshots`) and drain asynchronously to Supabase via `record-ball` Edge Function with client-generated idempotency UUIDs.
   - Scoped strictly to scoring an already-started innings.
3. **`posts` Publishing Outbox (2026-09-26)**:
   - Client-side outbox for multi-photo post uploads surviving process death and network drops during staging.
   - Strictly scoped to unfinished local uploads; no offline Home feed mirror, no offline likes/comments.

**Do NOT generalize Drift caching, WALs, or offline queues to any other feature** (teams, tournaments, profiles, social posts, explore). Repositories must read and write directly to Supabase.

---

## 4. DTOs are Never Entities (Rule 3)

- **DTOs (`data/models/*_dto.dart`)**:
  - Implemented using `@freezed`
  - Carry `@JsonKey(name: 'snake_case')` field annotations for Supabase wire compatibility
  - Include a private constructor `const MyDto._();` to allow methods
  - Provide a `toEntity()` method that converts the DTO into a Domain Entity
  - DTOs **never escape the `data/` layer**. Controllers and domain contracts never accept or return DTOs.
- **Entities (`domain/entities/*.dart`)**:
  - Extend `Equatable`
  - Have no `fromJson`, no `toJson`, and zero knowledge of the database or wire format
  - Renaming a Supabase column affects only the DTO and its `toEntity()` mapper.

---

## 5. Value Objects Enforce Invariants (Rule 4)

Any primitive that has business validation rules (email, username, phone, match score, overs, team name, currency) must be encapsulated in a Value Object under `domain/value_objects/`:
- Private constructor
- Only public factory: `static Either<ValidationFailure, T> create(String input)`
- Once an instance exists, its internal invariant is guaranteed valid throughout the system.

---

## 6. Exception Boundary Discipline (Rule 2)

- **Data Sources**: May throw raw platform and SDK exceptions (`PostgrestException`, `AuthException`, `StorageException`, `FunctionException`, `HttpException`).
- **Repository Implementations**: The **ONLY** layer where raw exceptions are caught. They translate exceptions into typed `Failure` subclasses from `lib/core/error/failures.dart` and return `Either<Failure, T>`.
- **Presentation & Domain**: **NEVER** use `try/catch` around repository method invocations. Handled functionally via `result.fold((failure) => ..., (data) => ...)`.

---

## 7. Riverpod 3.x Discipline (Rule 5)

- **Codegen Only**: All providers use `@riverpod` or `@Riverpod(keepAlive: true)`. No manual `ChangeNotifierProvider` or legacy `StateNotifierProvider`.
- **Allowed Locations**: Riverpod is permitted ONLY in:
  - `lib/core/*/*_provider*.dart` (cross-cutting DI)
  - `lib/features/*/presentation/providers/`
  - `lib/features/*/presentation/controllers/`
  - `lib/features/*/data/datasources/*_datasource_providers.dart` (DI wiring only)
- **Lifecycle & Scope**:
  - UI controllers and screen state: default autodispose (`@riverpod`).
  - Singletons, repositories, and long-lived connections (`SupabaseClient`, `AblyService`): `@Riverpod(keepAlive: true)`.
- **Access Patterns**:
  - In `build()`: `ref.watch(provider)` (subscribes & rebuilds).
  - In event handlers / callbacks: `ref.read(provider)` (one-shot action).
  - For navigation, toasts, side effects: `ref.listen(provider, (prev, next) => ...)`.
  - Pattern match `AsyncValue` using Dart 3 `switch (state)` (`AsyncData`, `AsyncError`, `_`).
- **Acyclic Graph**: Provider dependencies must form a Directed Acyclic Graph (DAG). Never introduce circular provider references.

---

## 8. Cross-Feature Boundaries

- When Feature A needs functionality from Feature B:
  - It imports Feature B's **Domain Entities** or **Public Presentation Providers**.
  - It **MUST NOT** import Feature B's `data/datasources/` or private data classes directly.
  - Enforced by `test/architecture_test.dart`.
