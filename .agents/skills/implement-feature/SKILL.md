---
name: implement-feature
description: Implements an approved architecture plan for Match Day in strict accordance with Clean Architecture, Riverpod 3.x, and project invariants. Use when transforming an approved architectural specification into tested production code.
---

# Implement Feature Skill

Use this skill to implement an approved architectural design across the Clean Architecture layers in Match Day.

---

## Prerequisites
- An approved architecture review or implementation plan exists.
- The authoritative source of truth, layer boundaries, and database/Ably impacts are identified.

---

## Step-by-Step Implementation Sequence

### Step 1: Domain Layer (Pure Dart First)
Always start with Domain to establish the contract before building infrastructure:
1. **Value Objects (`lib/features/<feature>/domain/value_objects/`)**:
   - Wrap validated inputs (e.g., custom IDs, format constraints).
   - Use private constructor + `static Either<ValidationFailure, T> create(String raw)`.
2. **Entities (`lib/features/<feature>/domain/entities/`)**:
   - Pure Dart class extending `Equatable`.
   - No `fromJson`, no `toJson`, no framework dependencies.
3. **Repository Interface (`lib/features/<feature>/domain/repositories/`)**:
   - Abstract contract returning `Future<Either<Failure, T>>` or `Stream<T>`.
   - **REMINDER**: No use cases! Controllers talk to repositories directly.

### Step 2: Data Layer (Infrastructure & Persistence)
1. **Data Transfer Objects (`lib/features/<feature>/data/models/`)**:
   - Freezed class: `@freezed class MyDto with _$MyDto`.
   - Private constructor: `const MyDto._();` (mandatory for custom methods).
   - Factory `fromJson` with snake_case `@JsonKey(name: '...')`.
   - Instance method: `MyEntity toEntity() => MyEntity(...)`.
2. **Remote Data Source (`lib/features/<feature>/data/datasources/`)**:
   - Interacts with `SupabaseClient` or `AblyService`.
   - Throws raw exceptions (`PostgrestException`, `AuthException`, etc.).
   - Wire providers in `*_datasource_providers.dart` using `@Riverpod(keepAlive: true)`.
3. **Repository Implementation (`lib/features/<feature>/data/repositories/`)**:
   - Implements the domain repository contract.
   - Catches raw exceptions and maps to `Either<Failure, T>`.
   - Holds business rules, validation, and multi-call orchestration.
   - Declares provider in repository file: `@Riverpod(keepAlive: true)`.

### Step 3: Presentation Layer (UI & State)
1. **Controllers / Notifiers (`lib/features/<feature>/presentation/controllers/` or `providers/`)**:
   - Use `@riverpod` (autodispose by default).
   - Extend `_$MyController` using `AsyncNotifier` or `Notifier`.
   - Access repositories via `ref.read(<feature>RepositoryProvider)`.
2. **UI Widgets & Screens (`lib/features/<feature>/presentation/widgets/` & `screens/`)**:
   - Consume state via `ref.watch(provider)`.
   - Pattern-match `AsyncValue` using Dart 3 switch (`AsyncData`, `AsyncError`, `_`).
   - Trigger actions via `ref.read(provider.notifier).action()`.
   - Listen for side effects (navigation, snacks) via `ref.listen()`.
   - Adhere to design tokens: `CkColors`, warm-paper palette, earned red accent.
3. **Routing (`lib/router/app_router.dart`)**:
   - Register new routes with GoRouter if needed.
   - Use typed parameters or query params.

### Step 4: Run Code Generation
If Freezed or Riverpod annotations were modified:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 5: Execute Quality Gates
Verify that the implementation passes all quality gates:
1. `flutter analyze lib/`
2. `flutter test test/architecture_test.dart`
3. Domain purity check:
   ```bash
   grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/<feature>/domain/
   ```
4. Feature unit/widget tests under `test/features/<feature>/`.
