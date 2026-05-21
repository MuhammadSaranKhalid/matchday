# Novex Clean Architecture — Project Guide

This file is the source of truth for how this codebase is structured. Any agent (Claude Code or otherwise) modifying this project MUST follow these rules without exception. When in doubt, prefer the conventions documented here over patterns found elsewhere on the internet.

The README.md is a human-readable overview of the same architecture. This file (CLAUDE.md) is the agent-readable contract.

---

## 1. What this codebase is

A **foundation** — not a product. It's a Flutter chassis built with Clean Architecture, Riverpod 3.x, Supabase, and offline-first persistence (drift + sync orchestrator + LWW conflict resolution). The actual product's features are unknown to this guide and will be decided by the team building on top.

The codebase ships with two pre-built features. They exist for different reasons:

**`auth` is real.** Every product needs authentication. The auth feature (email OTP + native Google OAuth) stays in any product built on this foundation. Adapt the UI, add more providers (Apple, Facebook, magic link variants), wire in profile creation — but the feature itself is permanent infrastructure.

**`todos` is a reference implementation, NOT part of the product.** It exists solely to demonstrate the offline-first pattern (local DB + pending ops queue + sync service + LWW + real-time mirror). The actual product's features will look completely different — they might be posts, messages, calendars, transactions, comments, profiles, documents, or anything else. The architectural patterns generalize to all of them; the specific entity called "Todo" does not.

What to do with the `todos` feature depends on the product:
- **Keep it indefinitely** as a learning reference for new team members.
- **Delete it** once the team has internalized the pattern and at least one real feature has been built using the same offline-first shape: `rm -rf lib/features/todos test/features/todos`, drop the `Todos` table from `lib/core/database/tables.dart`, remove it from `@DriftDatabase`, bump `schemaVersion` and add a migration that drops the table, remove todos references from `lib/router/app_router.dart`.
- **Replace it** with the first real offline-supported feature using the same shape.

When asked to add a new feature, follow Section 7 — it's a generic recipe that works for any feature regardless of domain. Do not assume the new feature should integrate with `todos`. Do not write code that imports from `lib/features/todos/` unless you're explicitly modifying todos itself.

---

## 2. The Architecture Rules (non-negotiable)

These rules are tested by the existence of the codebase. If a change you're about to make would violate any of them, the change is wrong — find a different approach.

### Rule 1 — Domain is pure Dart

Files in `lib/features/*/domain/` and `lib/core/usecase/`, `lib/core/error/` MUST NOT import:
- `package:flutter/*`
- `package:flutter_riverpod/*`
- `package:riverpod_annotation/*`
- `package:supabase_flutter/*`
- `package:supabase/*`
- `package:drift/*`
- `package:dio/*`
- `package:http/*`
- Any platform-specific package

Domain files may only import `dart:*`, `package:fpdart/*`, and other Domain files in the same feature (or shared Domain code in `lib/core/`). If a Domain file would need anything else, the dependency is wrong — invert it (define an abstract class in Domain, implement in Data).

### Rule 2 — Exceptions never cross the Domain boundary

Data sources may throw raw exceptions (`AuthException`, `PostgrestException`, `GoogleSignInException`, `DriftRemoteException`, etc.). Repository implementations are the **only** place these are caught. They are translated to `Failure` subtypes from `lib/core/error/failures.dart` and returned as `Left(Failure)` in an `Either<Failure, T>`.

Above the repository (Domain, Presentation), there are no `try/catch` blocks around domain-method calls. The compiler enforces handling because the return type is `Either<Failure, T>` or `Stream<T>`.

### Rule 3 — DTOs are never Entities

Each entity in `domain/entities/` has at least one corresponding DTO in `data/models/`. DTOs:
- Carry wire-format field names (snake_case via `@JsonKey`)
- Know how to deserialize from JSON / Supabase rows
- Have a `toEntity()` method that produces the Domain type

The Domain Entity has no `fromJson`, no `toJson`, no awareness of the wire format. Renaming a Supabase column changes only the mapper.

### Rule 4 — Value objects enforce invariants

Any string-like primitive that has validity rules (email format, phone format, OTP length, password strength, URL shape, etc.) MUST be wrapped in a value object in `domain/value_objects/`. The only constructor is `static Either<ValidationFailure, T> create(String input)`. Once you hold an instance, it is guaranteed valid.

Examples that ship: `Email`, `OtpCode`. If you find yourself doing input validation in a controller or a use case, that's a missing value object.

### Rule 5 — Riverpod only in Presentation (and Core providers)

Riverpod imports (`flutter_riverpod`, `riverpod_annotation`) are allowed in:
- `lib/core/*/*_provider*.dart` (DI for cross-cutting services)
- `lib/features/*/presentation/providers/`
- `lib/features/*/presentation/controllers/`
- `lib/features/*/data/datasources/*_datasource_providers.dart` (DI-only files)

Riverpod imports are FORBIDDEN in:
- Anything inside `domain/`
- Repository implementations, data sources, DTOs, mappers (these classes take plain constructor parameters; their providers are separate files)

### Rule 6 — Providers form a DAG

If adding a new provider would create an import cycle between files, split the provider definitions into a separate "providers-only" file (see `lib/features/todos/data/datasources/todos_datasource_providers.dart` for the pattern). Never use forward declarations, late initialization hacks, or `late final` workarounds.

### Rule 7 — For offline-first features: reads from local; writes write-through to local then enqueue

For any feature with offline support, the repository's read methods MUST read from the local DB. Write methods MUST write to the local DB synchronously, enqueue a pending operation, and then trigger sync (fire-and-forget). The UI never blocks on the network for either reads or writes.

For online-only features, the repository's read and write methods talk to the remote data source directly. No local DB involvement.

---

## 3. Folder Map

```
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart                 # sealed Failure hierarchy
│   │   └── exceptions.dart               # raw exception types thrown by data sources
│   ├── usecase/
│   │   └── usecase.dart                  # base UseCase + StreamUseCase contracts + NoParams
│   ├── supabase/
│   │   └── supabase_client_provider.dart # SupabaseClient as a keepAlive provider
│   ├── database/
│   │   ├── tables.dart                   # drift table definitions (add new tables here)
│   │   ├── app_database.dart             # @DriftDatabase class (register new tables here)
│   │   └── database_provider.dart        # AppDatabase as a keepAlive provider
│   ├── connectivity/
│   │   └── connectivity_provider.dart    # Stream<bool> isOnline provider
│   └── sync/
│       ├── sync_service.dart             # offline-first orchestrator (replay + pull + LWW)
│       └── sync_provider.dart            # SyncService provider, watches connectivity
├── router/
│   └── app_router.dart                   # go_router with auth-aware redirect
├── app.dart                              # MaterialApp.router + bootstraps sync + DB clear on sign-out
├── main.dart                             # Supabase.initialize + GoogleSignIn.initialize + ProviderScope
└── features/
    ├── auth/                             # PERMANENT — every product needs auth
    ├── todos/                            # REFERENCE — delete or replace per Section 1
    └── <your_feature>/                   # whatever the product actually needs
        ├── domain/
        │   ├── entities/                 # plain Dart classes; manual equality
        │   ├── value_objects/            # Email-like wrappers with Either<Failure, T>.create
        │   ├── repositories/             # abstract classes returning Either<Failure, T> / Stream<T>
        │   └── usecases/                 # one verb per file, implements UseCase or StreamUseCase
        ├── data/
        │   ├── models/                   # freezed DTOs with toEntity()
        │   ├── datasources/
        │   │   ├── <feature>_remote_datasource.dart
        │   │   ├── <feature>_local_datasource.dart       # if offline support
        │   │   └── <feature>_datasource_providers.dart   # @Riverpod providers for the above
        │   └── repositories/
        │       └── <feature>_repository_impl.dart        # only place that catches raw exceptions
        └── presentation/
            ├── state/                    # sealed UI state union (one file per controller, only if needed)
            ├── controllers/              # Notifier / AsyncNotifier / StreamNotifier with @riverpod
            ├── screens/                  # ConsumerWidget / ConsumerStatefulWidget
            └── providers/                # @riverpod providers for repo + use cases

test/
└── features/<feature>/
    ├── domain/usecases/<name>_test.dart            # pure use case tests, no Flutter binding
    └── presentation/controllers/<name>_test.dart   # Notifier tests with ProviderContainer.test() + overrideWithValue
```

The shared `PendingOperations` table lives in `lib/core/database/tables.dart` so it can be reused by any offline-supported feature, not just todos. The `OpType` enum currently lists `create / update / toggle / delete`; if your feature needs different op verbs, extend the enum and handle the new variants in `lib/core/sync/sync_service.dart`'s `_executeOp` switch.

---

## 4. Tech Stack (current locked versions)

These versions are what `pubspec.yaml` declares. When asked to upgrade, verify the latest STABLE version on pub.dev (NOT pre-release / dev) and update both `pubspec.yaml` and this section.

```yaml
# Runtime
flutter_riverpod: ^3.3.1
riverpod_annotation: ^4.0.2          # NOTE: 4.0.3+ are pre-release; do not pin
supabase_flutter: ^2.12.4
google_sign_in: ^7.2.0               # v7+ API: GoogleSignIn.instance.authenticate()
drift: ^2.32.1
drift_flutter: ^0.2.4
sqlite3_flutter_libs: ^0.5.26
path_provider: ^2.1.5
connectivity_plus: ^6.1.0
uuid: ^4.5.1
fpdart: ^1.1.0
freezed_annotation: ^3.0.0
json_annotation: ^4.9.0
go_router: ^16.2.0

# Codegen (dev_dependencies)
build_runner: ^2.4.13
riverpod_generator: ^4.0.3           # NOTE: 4.0.4+ are pre-release
freezed: ^3.2.5
json_serializable: ^6.8.0
drift_dev: ^2.32.1

# Tooling (dev_dependencies)
riverpod_lint: ^3.3.1
custom_lint: ^0.6.7
flutter_lints: ^5.0.0
mocktail: ^1.0.4

# SDK
sdk: ^3.7.0
flutter: ">=3.27.0"
```

The Riverpod ecosystem has split versioning: the runtime (`flutter_riverpod`, `riverpod`) is on the 3.x line while the codegen tooling (`riverpod_annotation`, `riverpod_generator`) is on the 4.x line. This is intentional, not a mistake — do not "fix" it.

If a feature needs a dependency not listed here (e.g. file picker, image cropper, charts), add it via `flutter pub add <package>` and document it here with the chosen version and rationale.

---

## 5. Layer-by-Layer Specification

Code templates below use deliberately generic names (`Foo`, `Bar`) so they read as recipes rather than implementations. When applying them to a real feature, replace placeholders with your actual entity/feature names.

### 5.1 Domain Layer

#### Entity template (`domain/entities/foo.dart`)

```dart
// Pure Dart. No imports outside dart:* and other Domain files.
class Foo {
  const Foo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final FooId id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Foo copyWith({String? title, DateTime? updatedAt}) => Foo(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Foo &&
          other.id == id &&
          other.title == title &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
}

class FooId {
  const FooId(this.value);
  final String value;
  @override
  bool operator ==(Object other) => other is FooId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
```

Notes:
- Entities are plain Dart classes with manual `==`/`hashCode`. Do NOT use Freezed for entities — it pulls Domain into Data's serialization concerns.
- ID types are always wrapped (`FooId`, `UserId`, etc.), never raw `String`.
- Add `updatedAt` to any entity that will be synced offline (needed for LWW conflict resolution). Omit if the feature is online-only and the timestamp isn't business-relevant.
- Mutable transitions go through `copyWith`, never field reassignment.

#### Value object template (`domain/value_objects/email.dart`)

(Real example from the auth feature.)

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';

class Email {
  const Email._(this.value);
  final String value;

  static final _re = RegExp(r'^[\w.+\-]+@[\w-]+\.[\w.-]+$');

  static Either<ValidationFailure, Email> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Email is required'));
    }
    if (!_re.hasMatch(trimmed)) {
      return const Left(ValidationFailure('Email format is invalid'));
    }
    return Right(Email._(trimmed.toLowerCase()));
  }

  @override
  bool operator ==(Object other) =>
      other is Email && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
```

Notes:
- Private constructor `._()`. Only `create` produces instances.
- `create` returns `Either<ValidationFailure, T>`. Never throw from a value object.
- For sensitive values (passwords, secrets, API keys), override `toString()` to return a redacted placeholder.

#### Repository contract template (`domain/repositories/foo_repository.dart`)

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/foo.dart';

abstract class FooRepository {
  // Reads — request/response
  Future<Either<Failure, List<Foo>>> getAll();

  // Reads — stream (always reads from local DB if offline-first)
  Stream<List<Foo>> watchAll();

  // Writes
  Future<Either<Failure, Foo>> add(String title);
  Future<Either<Failure, Foo>> update(FooId id, {String? title});
  Future<Either<Failure, Unit>> delete(FooId id);
}
```

Notes:
- Repository methods speak Domain types in/out only (entities, value objects, Failures). No DTOs, no `Map<String, dynamic>`.
- `Future<Either<Failure, T>>` for one-shot ops. `Stream<T>` for reactive reads (errors propagate as stream errors).
- `Unit` from fpdart represents successful void returns.
- For online-only features, skip the `watchAll()` stream method — use only request/response.

#### Use case template (`domain/usecases/add_foo.dart`)

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/foo.dart';
import '../repositories/foo_repository.dart';

class AddFoo implements UseCase<Foo, AddFooParams> {
  const AddFoo(this._repo);
  final FooRepository _repo;

  @override
  Future<Either<Failure, Foo>> call(AddFooParams p) async {
    // Business rules live HERE, not in the controller or the repo.
    final title = p.title.trim();
    if (title.isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }
    if (title.length > 140) {
      return const Left(ValidationFailure('Title is too long (max 140)'));
    }
    return _repo.add(title);
  }
}

class AddFooParams {
  const AddFooParams(this.title);
  final String title;
}
```

Notes:
- One use case = one verb. `AddFoo`, `SignIn`, `VerifyEmailOtp`, `WatchFoos`, `DeleteAccount`.
- Use cases with no input use `NoParams` from `core/usecase/usecase.dart`.
- Reactive use cases implement `StreamUseCase<T, P>` instead of `UseCase<T, P>`.
- If a use case is a one-line delegate to a repository method AND has no business rules, write it anyway — consistency keeps the layer boundaries readable.

### 5.2 Data Layer

#### DTO template (`data/models/foo_dto.dart`)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/foo.dart';

part 'foo_dto.freezed.dart';
part 'foo_dto.g.dart';

@freezed
abstract class FooDto with _$FooDto {
  const factory FooDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _FooDto;

  // REQUIRED for any custom method (toEntity, computed getter, etc).
  // OMIT only when the DTO has zero custom methods.
  const FooDto._();

  factory FooDto.fromJson(Map<String, dynamic> json) =>
      _$FooDtoFromJson(json);

  Foo toEntity() => Foo(
        id: FooId(id),
        title: title,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
```

Freezed 3.x notes:
- `abstract class` is the project convention. Freezed 3.2+ technically permits plain `class` too, but stay consistent.
- `const X._()` private constructor is REQUIRED when the class has any instance method (`toEntity`, computed getters, validators). OMIT it for pure-data DTOs with no extra methods (see Section 6.3).
- Snake_case JSON keys via `@JsonKey(name: 'snake_case')` mapped to camelCase Dart fields.
- Dates come from Supabase as ISO 8601 strings; convert at the mapper boundary (`DateTime.parse(...)`).

#### Remote data source template (`data/datasources/foo_remote_datasource.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/foo_dto.dart';

class FooRemoteDataSource {
  FooRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'foos';

  Future<List<FooDto>> list() async {
    try {
      final rows = await _supabase
          .from(_table)
          .select()
          .order('created_at', ascending: true);
      return rows.map((row) => FooDto.fromJson(row)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<FooDto> create({
    required String id,
    required String title,
    required DateTime createdAt,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException('Must be signed in');
      }
      final row = await _supabase
          .from(_table)
          .insert({
            'id': id,
            'user_id': userId,
            'title': title,
            'created_at': createdAt.toIso8601String(),
          })
          .select()
          .single();
      return FooDto.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  // ...update, delete...

  Stream<List<FooDto>> watch() {
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(FooDto.fromJson).toList());
  }
}
```

Notes:
- Data sources throw raw exceptions (`ServerException`, `UnauthorizedException`, `NotFoundException` from `core/error/exceptions.dart`). They do NOT return `Either`. Translation to `Failure` happens in the repository.
- Returns DTOs, never entities. Mapping is the repository's call.
- Supabase RLS is the auth filter. Don't manually add `WHERE user_id = ?` — the policy does it server-side.
- Accept client-side IDs (UUIDs) for offline-first features so the same ID survives the offline → sync transition.

#### Local data source template (`data/datasources/foo_local_datasource.dart`)

Only for offline-first features. The pattern is documented in `lib/features/todos/data/datasources/todos_local_datasource.dart` — read that file for the canonical implementation. Summarized:

```dart
class FooLocalDataSource {
  FooLocalDataSource(this._db);
  final AppDatabase _db;

  Stream<List<Foo>> watchAll() =>
      (_db.select(_db.foos)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch()
          .map((rows) => rows.map(_toEntity).toList());

  Future<void> upsert(Foo foo, {required String userId}) =>
      _db.into(_db.foos).insertOnConflictUpdate(
            FoosCompanion.insert(/* ... */),
          );

  Future<void> upsertManyLww(List<Foo> remoteFoos, {required String userId}) async {
    // For each remote: if local updatedAt is newer, skip; else upsert.
    // See todos_local_datasource.dart for the exact pattern.
  }

  Foo _toEntity(LocalFoo row) => Foo(/* ... */);
}
```

Notes:
- Local data sources expose ENTITIES to the repository (not drift's generated row types). The `_toEntity` mapper handles conversion at the boundary.
- Use `insertOnConflictUpdate` for upserts. Use `batch` for bulk operations.
- LWW conflict resolution compares `updatedAt` — local newer = skip, remote newer = overwrite.

#### Repository implementation templates (`data/repositories/foo_repository_impl.dart`)

**For online-only features:**

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/foo.dart';
import '../../domain/repositories/foo_repository.dart';
import '../datasources/foo_remote_datasource.dart';

class FooRepositoryImpl implements FooRepository {
  FooRepositoryImpl(this._remote);
  final FooRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Foo>>> getAll() async {
    try {
      final dtos = await _remote.list();
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  // ...other methods...
}
```

**For offline-first features (coordinator pattern):**

Pattern documented end-to-end in `lib/features/todos/data/repositories/todos_repository_impl.dart` — read that file when implementing offline-first. Shape:

```dart
class FooRepositoryImpl implements FooRepository {
  FooRepositoryImpl({
    required FooLocalDataSource local,
    required PendingOperationsDataSource pendingOps,
    required SyncService syncService,
    required SupabaseClient supabase,
    Uuid? uuid,
  }) : /* ... */;

  // Reads → local only
  @override Stream<List<Foo>> watchAll() => _local.watchAll();
  @override Future<Either<Failure, List<Foo>>> getAll() async { ... }

  // Writes → local first, enqueue, fire-and-forget sync
  @override
  Future<Either<Failure, Foo>> add(String title) async {
    try {
      final userId = _requireUserId();
      final now = DateTime.now();
      final foo = Foo(
        id: FooId(_uuid.v4()),
        title: title,
        createdAt: now,
        updatedAt: now,
      );
      await _local.upsert(foo, userId: userId);
      await _pending.enqueueCreate(/* ... */);
      unawaited(_sync.sync());
      return Right(foo);
    } on StateError catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
```

Notes:
- The repository is the ONLY place `try/catch` translates `*Exception` → `Failure`.
- For offline features, mutations always: (1) write local, (2) enqueue pending op, (3) `unawaited(_sync.sync())`. Never throw, never block on network.
- For online features, mutations make the network call and return the mapped result directly.

### 5.3 Presentation Layer

#### View state — when to use sealed unions vs `AsyncValue<T>`

**Use a hand-rolled sealed `<Feature>State` class** when the controller's lifecycle has multiple meaningful sub-states that aren't loading/error/data. Example: a sign-in flow with `AuthInitial → AuthSendingOtp → AuthOtpSent(email) → AuthVerifyingOtp → AuthAuthenticated | AuthFailed`. Multi-step wizards, payment flows, OTP entry — these need sealed states because the UI changes shape per state.

**Use `AsyncValue<T>` directly** (from a `StreamNotifier` or `AsyncNotifier`) when the controller's state is just "the data, possibly loading or errored". Simple CRUD lists, profile views, settings screens — these don't need a sealed wrapper; `AsyncValue<List<Foo>>` is enough.

**Don't** create a sealed state class just because you can. Extra wrapping is cost without value for simple states.

#### Sealed view state template (`presentation/state/foo_state.dart`)

```dart
import '../../../../core/error/failures.dart';
import '../../domain/entities/foo.dart';

sealed class FooState {
  const FooState();
}

class FooInitial extends FooState {
  const FooInitial();
}

class FooLoading extends FooState {
  const FooLoading();
}

class FooReady extends FooState {
  const FooReady(this.foo);
  final Foo foo;
}

class FooFailed extends FooState {
  const FooFailed(this.failure);
  final Failure failure;
}
```

#### Controller templates

**Notifier** (synchronous initial state, multi-step flow):

```dart
@riverpod
class FooController extends _$FooController {
  @override
  FooState build() => const FooInitial();

  Future<void> doSomething(String input) async {
    state = const FooLoading();
    final result = await ref.read(someUseCaseProvider).call(input);
    state = result.fold(
      FooFailed.new,
      FooReady.new,
    );
  }
}
```

**AsyncNotifier** (initial state is an async fetch):

```dart
@riverpod
class FooController extends _$FooController {
  @override
  Future<Foo> build() async {
    final result = await ref.read(getFooUseCaseProvider).call(const NoParams());
    return result.fold(
      (failure) => throw FailureWrapper(failure),
      (foo) => foo,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

**StreamNotifier** (build returns a Stream — common for offline-first reads):

```dart
@riverpod
class FoosController extends _$FoosController {
  @override
  Stream<List<Foo>> build() =>
      ref.watch(watchFoosUseCaseProvider).call(const NoParams());

  Future<Either<Failure, Foo>> add(String title) =>
      ref.read(addFooUseCaseProvider).call(AddFooParams(title));

  Future<void> refresh() => ref.read(syncServiceProvider).sync();
}
```

Notes:
- Use `@riverpod` annotation (codegen). Never write `final fooProvider = StateNotifierProvider(...)` manually.
- `ref` is the unified `Ref` type — no `FooControllerRef` subclasses (those were deprecated in Riverpod 3.x).
- Action methods on the controller either return `void` (state-only side effects) or `Either<Failure, T>` (so the widget can render per-action feedback like snackbars without polluting controller state).
- Validation at the controller boundary: convert raw input to value objects using `Email.create(...)` etc. and pattern-match on the result with Dart 3 `switch`.

#### Widget templates

Use `ConsumerWidget` for stateless, `ConsumerStatefulWidget` for stateful (forms with TextEditingControllers):

```dart
class FooScreen extends ConsumerWidget {
  const FooScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side effects (navigation, snackbars) via ref.listen
    ref.listen<FooState>(fooControllerProvider, (prev, next) {
      switch (next) {
        case FooReady():
          context.go('/next');
        case FooFailed(failure: final f):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          );
        case _:
          break;
      }
    });

    // ref.watch in build to rebuild on changes
    final state = ref.watch(fooControllerProvider);

    return Scaffold(
      body: switch (state) {
        FooLoading() => const Center(child: CircularProgressIndicator()),
        FooReady(foo: final foo) => _Body(foo: foo),
        _ => const _IdleView(),
      },
    );
  }
}
```

The three Riverpod ref methods, summarized:
- `ref.watch(provider)` — call inside `build`. Rebuilds the widget when the provider's state changes.
- `ref.read(provider)` — call inside event handlers (`onPressed`, etc.). Fire-and-forget read.
- `ref.read(provider.notifier).action()` — to invoke methods on the controller.
- `ref.listen(provider, callback)` — for side effects that should NOT cause a rebuild (navigation, snackbar, dialog).

#### Provider DI template (`presentation/providers/foo_providers.dart`)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/foo_datasource_providers.dart';
import '../../data/repositories/foo_repository_impl.dart';
import '../../domain/repositories/foo_repository.dart';
import '../../domain/usecases/add_foo.dart';
import '../../domain/usecases/get_foos.dart';
// ...other use cases

part 'foo_providers.g.dart';

@Riverpod(keepAlive: true)
FooRepository fooRepository(Ref ref) => FooRepositoryImpl(
      ref.watch(fooRemoteDataSourceProvider),
    );

@riverpod
GetFoos getFoosUseCase(Ref ref) => GetFoos(ref.watch(fooRepositoryProvider));

@riverpod
AddFoo addFooUseCase(Ref ref) => AddFoo(ref.watch(fooRepositoryProvider));

// ...one provider per use case
```

DI rules:
- `@Riverpod(keepAlive: true)` for long-lived dependencies: `SupabaseClient`, `AppDatabase`, data sources, repositories, sync service. They live for the app's lifetime.
- Bare `@riverpod` (autodispose) for use cases and controllers — they should clean up when no UI references them.
- The repository provider returns the ABSTRACT type (`FooRepository`), NOT the impl (`FooRepositoryImpl`). This is the linchpin of clean architecture — the consumer never sees the concrete class.
- Data source providers live in `data/datasources/<feature>_datasource_providers.dart` (their own file) to break import cycles between sync provider and repo provider. See `lib/features/todos/data/datasources/todos_datasource_providers.dart` for the pattern.

---

## 6. Cross-Cutting Patterns

### 6.1 Error Handling

`Failure` hierarchy in `lib/core/error/failures.dart`:
- `NetworkFailure` — no connectivity, DNS, socket errors
- `ServerFailure` — backend reachable, returned 5xx or unexpected payload
- `AuthFailure` — 401/403, invalid credentials, expired session
- `CacheFailure` — local DB read/write failure
- `ValidationFailure` — value object construction failed
- `NotFoundFailure` — 404 / row missing
- `UnknownFailure` — catch-all

Raw exceptions in `lib/core/error/exceptions.dart`:
- `ServerException`, `CacheException`, `UnauthorizedException`, `NotFoundException`

Mapping convention in repository implementations:

```dart
on UnauthorizedException catch (e) => Left(AuthFailure(e.message))
on ServerException catch (e)       => Left(ServerFailure(e.message))
on NotFoundException catch (e)     => Left(NotFoundFailure(e.message))
on CacheException catch (e)        => Left(CacheFailure(e.message))
on SocketException                 => Left(NetworkFailure())     // only if you handle network errors directly
catch (e)                          => Left(UnknownFailure(e.toString()))
```

The final `catch (e)` is the safety net. Never let a bare exception escape a repository method.

If you find your feature needs a `Failure` type that doesn't fit any of the above, add it to `lib/core/error/failures.dart` — don't invent it inside a feature folder.

### 6.2 Riverpod 3.x Provider DI

Patterns that ship in this codebase:
- All providers use the unified `Ref` parameter type. Do not use deprecated `FooRef` subclasses.
- `@Riverpod(keepAlive: true)` for app-lifetime services; bare `@riverpod` for autodispose.
- Stream providers return `AsyncValue<T>` in widgets. Access via `asyncValue.when(loading:, error:, data:)` or pattern match on `AsyncData / AsyncLoading / AsyncError`.
- `ref.invalidateSelf()` in a Notifier triggers a rebuild of `build()`. Prefer this over manually setting state for "refresh" operations.
- Tests override providers via `ProviderContainer.test(overrides: [...])` with `provider.overrideWithValue(...)`.

What NOT to do:
- Don't use `StateProvider`, `StateNotifierProvider`, or `ChangeNotifierProvider` — they're in `legacy.dart` for migration only.
- Don't use `.when` / `.map` on freezed sealed unions — use Dart 3 `switch` pattern matching instead.
- Don't manually instantiate dependencies inside a Notifier — get them via `ref.read(someProvider)`.

The `@mutation` API is **experimental** in 3.x. Do not adopt it for production code until it ships out of `package:flutter_riverpod/experimental/...` — when it does, replace the per-action `Either<Failure, T>` return pattern with `Mutation<T>` objects across all controllers in one sweep, then update this section.

### 6.3 Freezed 3.x Models

When to use freezed:
- DTOs (always — JSON serialization + value equality)
- Complex form state with `copyWith`
- Sealed unions where each variant needs `copyWith`

When NOT to use freezed:
- Domain entities (manual `==`/`hashCode` keeps Domain pure Dart)
- View state with sub-states that don't need `copyWith` (hand-rolled sealed classes are simpler)
- Value objects (private constructor + factory `create` is the pattern)

Syntax:

```dart
@freezed
abstract class FooDto with _$FooDto {
  // Factory constructor — always
  const factory FooDto({
    required String id,
    @JsonKey(name: 'snake_case') required String camelCase,
  }) = _FooDto;

  // Private constructor — REQUIRED if you have ANY custom method.
  // OMIT for pure data classes with no methods.
  const FooDto._();

  factory FooDto.fromJson(Map<String, dynamic> json) => _$FooDtoFromJson(json);

  // Custom methods go here, alongside the constructors.
  SomeEntity toEntity() => ...;
}
```

Sealed unions (multiple variants):

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.data(T value) = ResultData<T>;
  const factory Result.error(Failure failure) = ResultError<T>;
}
```

Match with `switch` expressions, NOT `.when`/`.map`:

```dart
final message = switch (result) {
  ResultData(:final value) => 'Got $value',
  ResultError(:final failure) => failure.message,
};
```

### 6.4 Offline-First Sync

The offline-first pattern is implemented end-to-end in `lib/core/sync/` plus the `todos` reference feature. When building any feature that needs offline support, mirror this structure.

Three storage primitives:
1. **Local DB (drift)** — source of truth for UI reads
2. **`pending_operations` table (drift)** — mutations made while offline. SHARED across features; do not create per-feature variants.
3. **Remote (Supabase)** — eventual source of truth; reconciled via sync

`SyncService` (`lib/core/sync/sync_service.dart`) orchestrates:
1. **Replay pending ops** in FIFO order. Each op pushes to Supabase. Success → delete from queue. Failure → bump `attempts`, record `lastError`, continue to next op.
2. **Pull remote** rows and merge into local using LWW: if local `updatedAt` is newer, skip; else upsert.
3. **Real-time mirror**: subscribe to `supabase.from(table).stream(...)` and write incoming row sets into local via the same LWW upsert.

Sync is triggered:
- On app boot if online (via `app.dart` → `ref.watch(syncServiceProvider)`)
- On offline → online transition (via `isOnlineProvider.listen` in `sync_provider.dart`)
- After every local mutation (`unawaited(_sync.sync())` in the repository)
- On pull-to-refresh in the UI (`controller.refresh()`)

Schema requirements for any synced table:
- UUID primary key (client-generated via `uuid` package)
- `user_id` column with RLS policy `auth.uid() = user_id`
- `updated_at timestamptz` with a `BEFORE UPDATE` trigger that sets it to `now()` on every change
- Table added to the `supabase_realtime` publication

**Extending sync to a new feature.** The current `SyncService._executeOp` switch handles `OpType.create / update / toggle / delete` for one entity type (currently todos). To support a new feature:

1. Either reuse the existing `OpType` enum if your verbs fit, OR extend it with new variants in `lib/core/database/tables.dart`.
2. Update the `entityType` column convention — currently `'todo'` is the only value; use a new string per feature (`'post'`, `'comment'`, etc.).
3. In `sync_service.dart`'s `_executeOp`, add a dispatch on `op.entityType` so the right data source handles each op type.
4. Inject your feature's remote data source into `SyncService` (currently only `TodosRemoteDataSource` is injected). At ≥3 synced features, refactor: have features register handlers with the sync service rather than the service knowing every data source.

When sign-out happens: `app.dart` listens to `currentUserStream` and calls `AppDatabase.clear()` to wipe ALL local data (todos, future offline features, pending ops). This prevents user A's data appearing for user B on the same device.

---

## 7. Adding a Feature (Step-by-Step)

Generic recipe — apply to ANY feature regardless of domain (posts, comments, profiles, messages, calendars, transactions, files, settings, anything).

Throughout the steps, `<feature>` is the snake_case feature name (e.g. `posts`), `<Feature>` is the PascalCase entity name (e.g. `Post`), and `<features>` is the Supabase table name (typically plural, e.g. `posts`).

Before you start, answer these three questions:
1. **Does this feature need offline support?** If yes, follow the offline-first variant of each step. If no, skip the local data source, pending ops, and sync extensions.
2. **Does the controller's UI lifecycle have meaningful sub-states (loading, multi-step flow, error with context)?** If yes, create a sealed `<Feature>State` class. If it's just "data, maybe loading, maybe errored" → skip the state file and use `AsyncValue<T>` directly.
3. **Are there any string primitives in this feature that have validity rules?** (Emails, phone numbers, slugs, URLs, color codes, etc.) Each gets a value object.

Then execute the recipe.

### Step 1 — Create the folder structure

```bash
mkdir -p lib/features/<feature>/{domain/{entities,value_objects,repositories,usecases},data/{models,datasources,repositories},presentation/{state,controllers,screens,providers}}
```

Omit `presentation/state` if you decided in question (2) above not to use a sealed state.

### Step 2 — Domain layer

Create in this order — each depends on the previous:

1. **Entities** (`domain/entities/<entity>.dart`) — one file per entity. Manual `==`/`hashCode`. Add `updatedAt` if the entity will be synced offline.
2. **Value objects** (`domain/value_objects/<name>.dart`) — one file per validated primitive identified in question (3) above. Skip if there are none.
3. **Repository contract** (`domain/repositories/<feature>_repository.dart`) — abstract class listing every read/write operation. For offline features, include a `Stream<List<Entity>> watchAll()` method.
4. **Use cases** (`domain/usecases/<verb>_<entity>.dart`) — one file per verb. Put business rules inside the use case's `call` method, not in the controller or repository.

After this step, the Domain layer should compile with `dart analyze` even if Data and Presentation don't exist yet.

### Step 3 — Data layer

1. **DTO** (`data/models/<entity>_dto.dart`) — freezed class with `fromJson` and `toEntity()`.
2. **Remote data source** (`data/datasources/<feature>_remote_datasource.dart`) — wraps `supabase.from('<features>')`. Throws raw exceptions.
3. **Local data source** (`data/datasources/<feature>_local_datasource.dart`) — ONLY if offline-supported. Wraps drift table access. Exposes entities (not drift rows).
4. **Data source providers** (`data/datasources/<feature>_datasource_providers.dart`) — `@Riverpod(keepAlive: true)` providers for steps 2 and 3.
5. **Repository implementation** (`data/repositories/<feature>_repository_impl.dart`) — implements the abstract from Domain. The ONLY place exceptions become Failures.

### Step 4 — Drift schema (offline features only)

1. Add a `<Features>` table class to `lib/core/database/tables.dart` following the existing `Todos` pattern (UUID id, `user_id`, `created_at`, `updated_at`, business columns).
2. Add the class to the `@DriftDatabase(tables: [...])` list in `lib/core/database/app_database.dart`.
3. Bump `schemaVersion` (`int get schemaVersion => 2;`).
4. Add an `onUpgrade` migration step:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(<features>);
        }
        // future migrations go here
      },
    );
```

5. Update `AppDatabase.clear()` to also delete from the new table on sign-out.

### Step 5 — Supabase schema

Run the following SQL (substitute `<features>` for the table name):

```sql
create table <features> (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  -- ...your business columns...
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table <features> enable row level security;

create policy "<features> are private to the owner"
  on <features> for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create trigger <features>_updated_at
  before update on <features>
  for each row execute function set_updated_at();
-- (the set_updated_at function should already exist from the todos table;
--  if not, define it once per project — see Section 12)

-- only if real-time / offline-sync needed:
alter publication supabase_realtime add table <features>;
```

For multi-tenant or shared-resource tables, the RLS policy will be more complex (joins against membership tables). Document the policy alongside the schema.

### Step 6 — Sync service (offline features only)

1. Extend `OpType` in `lib/core/database/tables.dart` if your feature needs verbs not already there.
2. Inject the new feature's remote data source into `SyncService`'s constructor (in `lib/core/sync/sync_service.dart` and `lib/core/sync/sync_provider.dart`).
3. Add a dispatch branch in `SyncService._executeOp` based on `op.entityType` so it knows which data source to call.
4. If you have ≥3 synced features, refactor: introduce a `SyncHandler` interface and have each feature register a handler with the sync service. Document the new pattern in this file.

### Step 7 — Presentation layer

1. **View state** (`presentation/state/<feature>_state.dart`) — sealed class. SKIP if you decided in question (2) to use `AsyncValue<T>` directly.
2. **Controller** (`presentation/controllers/<feature>_controller.dart`) — `@riverpod class FooController extends _$FooController { ... }`. Pick:
   - `Notifier` if you have a sealed state with synchronous initial value
   - `AsyncNotifier` if `build()` is a one-shot async fetch
   - `StreamNotifier` if `build()` returns a stream (typical for offline-first reads via `watchAll`)
3. **Screens** (`presentation/screens/<feature>_screen.dart`) — `ConsumerWidget` or `ConsumerStatefulWidget`.
4. **Providers** (`presentation/providers/<feature>_providers.dart`) — repository provider (returns abstract type) + one provider per use case.

### Step 8 — Routing

Add new routes to `lib/router/app_router.dart`. If the feature requires sign-in, the existing redirect logic already gates it — just don't list it under `/sign-in`.

### Step 9 — Tests

At minimum:
- One use case test per use case that has business rules (see Section 9).
- One controller test (verifies state transitions with mocked use cases).
- For offline-first features: one repository test (verifies offline writes enqueue pending ops + write local).

### Step 10 — Generate code, analyze, run

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

### Step 11 — Document

If you introduced a pattern not yet covered in this file (a new value object validation style, a new failure type, a new sync handler interface), add it to the relevant section in CLAUDE.md. The file should grow as the architecture grows.

---

## 8. Adding a Use Case to an Existing Feature

Much shorter:

1. Add the use case file in `domain/usecases/<verb>_<entity>.dart`.
2. Add a method to the repository contract if needed.
3. Implement the new repository method in the existing `*RepositoryImpl`.
4. Add a `@riverpod` provider for the use case in the existing `*_providers.dart`.
5. Wire it into the controller (action method).
6. Update the screen widget (button, dialog, whatever).
7. Run codegen.
8. Add a use case test if it has business rules.

---

## 9. Testing

Three test types, all in `test/features/<feature>/`:

### Use case test (pure Dart, fastest)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/core/error/failures.dart';
import 'package:novex_clean_arch/features/<feature>/domain/entities/foo.dart';
import 'package:novex_clean_arch/features/<feature>/domain/repositories/foo_repository.dart';
import 'package:novex_clean_arch/features/<feature>/domain/usecases/add_foo.dart';

class _MockFooRepo extends Mock implements FooRepository {}

void main() {
  late _MockFooRepo repo;
  late AddFoo useCase;

  setUp(() {
    repo = _MockFooRepo();
    useCase = AddFoo(repo);
  });

  test('rejects empty title without calling the repo', () async {
    final result = await useCase(const AddFooParams('   '));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repo.add(any()));
  });

  test('forwards a trimmed valid title', () async {
    final created = Foo(
      id: const FooId('f1'),
      title: 'Hello',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => repo.add(any())).thenAnswer((_) async => Right(created));
    final result = await useCase(const AddFooParams('  Hello  '));
    expect(result, equals(Right<Failure, Foo>(created)));
    verify(() => repo.add('Hello')).called(1);
  });
}
```

### Controller test (with provider overrides)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novex_clean_arch/features/<feature>/domain/usecases/add_foo.dart';
import 'package:novex_clean_arch/features/<feature>/presentation/controllers/foo_controller.dart';
import 'package:novex_clean_arch/features/<feature>/presentation/providers/foo_providers.dart';

class _MockAddFoo extends Mock implements AddFoo {}

void main() {
  late _MockAddFoo addFoo;

  setUpAll(() {
    registerFallbackValue(const AddFooParams('x'));
  });

  setUp(() => addFoo = _MockAddFoo());

  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [addFooUseCaseProvider.overrideWithValue(addFoo)],
      );

  test('state transitions on success', () async {
    // ... setup mock + assertions ...
  });
}
```

Notes:
- `ProviderContainer.test()` is the Riverpod 3.x test API. Do not use the deprecated `ProviderContainer()` constructor directly in tests.
- Always `addTearDown(container.dispose)`.
- Use `mocktail` (not `mockito`) — no codegen needed.
- For value-object parameters, register a fallback once in `setUpAll`.

### Repository test (with mocked data sources)

Same pattern as the controller test but with `Mock` classes for the data sources. Useful for verifying exception-to-Failure translation and (for offline-first features) that mutations correctly write local + enqueue pending ops + nudge sync.

---

## 10. Common Pitfalls (DON'Ts)

### Architecture
- **Don't** put Supabase / drift / Riverpod imports in `domain/` — Domain breaks.
- **Don't** catch exceptions outside the repository — they should never reach Presentation as raw exceptions.
- **Don't** return DTOs from a use case or a repository's public method — only Entities/Failures/Streams.
- **Don't** use `Map<String, dynamic>` in Domain — always use Entities.
- **Don't** wrap your own raw `String` in business logic — use a value object.
- **Don't** import from `lib/features/todos/` when building a new feature unless you're modifying todos itself. The todos feature is a reference implementation, not shared infrastructure.

### Riverpod
- **Don't** call `ref.watch` inside an event handler (`onPressed`). Use `ref.read`.
- **Don't** call `ref.read` inside `build()`. Use `ref.watch`.
- **Don't** mutate state from `build()`. Mutate from action methods only.
- **Don't** use `late final Ref ref` workarounds — use the inherited `ref` from `_$ControllerName`.
- **Don't** wrap controllers in legacy `StateNotifier`. Use `@riverpod` codegen + `Notifier` / `AsyncNotifier` / `StreamNotifier`.
- **Don't** use `.when` / `.map` extensions on freezed unions — use Dart `switch` patterns.

### Freezed
- **Don't** forget `const X._()` when adding a custom method to a DTO — the analyzer won't see the method.
- **Don't** use Freezed for Domain entities — Domain must be pure Dart.
- **Don't** mix `class X with _$X` and `abstract class X with _$X` styles in the same project. This project uses `abstract class`.

### Supabase
- **Don't** add manual `WHERE user_id = ?` filters — RLS does it server-side.
- **Don't** call `Supabase.initialize` more than once.
- **Don't** subscribe to `.stream()` from a widget directly. Wrap it in a provider so it's testable and respects keepAlive.
- **Don't** use `signInWithOAuth` for Google on mobile — use the native flow via `google_sign_in` + `signInWithIdToken`.
- **Don't** use the deprecated `Provider` enum — it's `OAuthProvider` in v2.

### Drift
- **Don't** generate UUIDs inside the DB layer — generate in the repository (via `uuid` package) so the DTO has the same ID when pushed to Supabase.
- **Don't** assume `insertOnConflictUpdate` handles LWW — it doesn't; you must compare `updatedAt` manually for that.
- **Don't** forget to bump `schemaVersion` and add a migration step when adding tables.

### google_sign_in v7
- **Don't** call `initialize()` per sign-in. Call it once in `main.dart`.
- **Don't** use `signIn()` — that was the v6 API. Use `authenticate()`.
- **Don't** skip `authorizationClient.authorizeScopes(scopes)` — `authorizationForScopes` returns null on first sign-in.

### Features
- **Don't** assume the next feature is anything specific. The product can ship any combination of features. CLAUDE.md teaches patterns; the team decides which features to build.
- **Don't** integrate new features with the `todos` demo (e.g. "show todos on the post screen"). Todos is reference code, not product code.

---

## 11. Commands & Workflows

```bash
# Initial setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Add Android/iOS platform folders (one-time, after unzipping a reference)
flutter create . --org studio.novex --project-name novex_clean_arch

# Run with all required dart-defines
flutter run \
  --dart-define=SUPABASE_URL=https://YOURPROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com

# Watch mode for codegen during development
dart run build_runner watch --delete-conflicting-outputs

# Static analysis
flutter analyze

# Tests
flutter test

# Lint with riverpod_lint rules
dart run custom_lint
```

After ANY change to a `@riverpod`, `@freezed`, `@JsonSerializable`, or drift table: run `dart run build_runner build --delete-conflicting-outputs`. The `*.g.dart` and `*.freezed.dart` files are gitignored and regenerated locally.

---

## 12. Supabase Schema Conventions

Every user-owned table follows this template:

```sql
create table <table_name> (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  -- ...domain columns...
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table <table_name> enable row level security;

create policy "<table_name> are private to the owner"
  on <table_name> for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- updated_at trigger (uses shared function — define once per project)
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger <table_name>_updated_at
  before update on <table_name>
  for each row execute function set_updated_at();

-- Required only for tables that need real-time / offline-sync:
alter publication supabase_realtime add table <table_name>;
```

Conventions:
- All IDs are UUIDs. Generate client-side with `Uuid().v4()` for offline-first features.
- All tables that belong to a user have `user_id uuid` with the RLS policy above.
- `updated_at` is set by the trigger, never by the client.
- Tables that need real-time push MUST be in the `supabase_realtime` publication.
- Many-to-many join tables follow the same pattern with composite primary keys.

For multi-tenant tables (shared with other users), the RLS policy gets more interesting — typically a join against a membership table:

```sql
create policy "members can read shared <table_name>"
  on <table_name> for select
  using (
    exists (
      select 1 from <table_name>_members
      where <table_name>_id = <table_name>.id
        and user_id = auth.uid()
    )
  );
```

Document the policy clearly when you add it.

---

## 13. When You're Stuck

If you (Claude Code or future agent) encounter a situation that doesn't fit any of the patterns above, **don't invent a new pattern silently**. Instead:

1. Identify which existing pattern is closest.
2. Implement the change using that pattern's structure even if it feels slightly forced.
3. Document the new variation in this file (CLAUDE.md) — describe what was different and why the existing pattern needed extension.
4. Flag it in your output so the human reviewer knows you stretched a pattern.

This is how the architecture stays consistent over many features and many sessions. The cost of one slightly-forced fit is much lower than the cost of architectural drift.

Patterns that are intentionally NOT yet covered here (because they haven't shipped):
- File upload / Supabase Storage
- Push notifications
- Background sync (workmanager)
- Multi-tenant data sharing (RLS policies sketched in Section 12 but no full feature reference)
- Profile editing with separate `profiles` table
- Pagination for large lists
- Image caching
- Internationalization (i18n)
- Analytics / event tracking

When any of these come up for the first time, follow Section 13's guidance: extend an existing pattern, document the extension here, flag it in your output.

---

## 14. The todos reference feature — quick reference

This section exists so Claude Code can look up how a specific offline-first detail is implemented in the todos reference without re-reading every file. Use it as a map, not as a template (the templates are in Section 5).

| Concern | File |
|---|---|
| Offline-first repository coordinator pattern | `lib/features/todos/data/repositories/todos_repository_impl.dart` |
| Local data source with LWW upsert | `lib/features/todos/data/datasources/todos_local_datasource.dart` |
| Pending operations queue accessor | `lib/features/todos/data/datasources/pending_operations_datasource.dart` |
| Remote data source with Supabase + real-time stream | `lib/features/todos/data/datasources/todos_remote_datasource.dart` |
| StreamNotifier-based controller (thin actions) | `lib/features/todos/presentation/controllers/todos_controller.dart` |
| AsyncValue.when in screen with pull-to-refresh | `lib/features/todos/presentation/screens/todos_screen.dart` |
| Provider DAG split (datasource providers separate file) | `lib/features/todos/data/datasources/todos_datasource_providers.dart` |
| Sync service orchestration | `lib/core/sync/sync_service.dart` |
| Sync triggers (boot, connectivity, listen) | `lib/core/sync/sync_provider.dart` |
| Drift schema + PendingOperations table | `lib/core/database/tables.dart` |
| `OpType` enum (extend if new verbs needed) | `lib/core/database/tables.dart` |

When the todos feature is deleted from a product, update this section to point at whichever real feature now demonstrates each concern (or remove the section entirely if the patterns are sufficiently internalized by the team).
