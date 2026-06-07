# Novex Clean Architecture — Project Guide

> **🟥 ARCHITECTURAL CONSTRAINT (2026-05-26, AMENDED 2026-06-07): This codebase is ONLINE-ONLY with one narrow exemption.**
> The offline-first patterns described in some sections below (Rule 7, §6.4 Offline-First Sync, the offline variant of §5.2 / §7) are **NOT in use**. The `todos` reference feature, `lib/core/sync/` infrastructure, `pending_operations` queue, `TeamsLocalDataSource`, and all LWW machinery have been removed.
>
> **EXEMPTION (2026-06-07, ticket #23) — `messages` feature only.** Messages has a drift-backed **read-through cache** for the inbox (`messages_chats`) and threads (`messages_messages`), plus a tiny **composer drafts** table (`messages_drafts`). Writes still go to Supabase first; the cache is a cold-start / instant-paint optimisation. There is **still** NO pending-ops queue, NO sync service, NO LWW. Sign-out wipes everything via `AppDatabase.clear()`. The exemption is scoped to messages; other features (teams / posts / matches / pavilion / profile) remain online-only.
>
> When adding ANY OTHER feature: follow the **online-only** variant. Repositories talk to Supabase directly via a remote data source; reads return `Future<Either<Failure, T>>` or wrap a Supabase real-time stream; writes call the remote and translate exceptions. No drift table (except `WizardDrafts` + the messages cache tables above), no pending ops, no SyncService.
>
> Do NOT generalise the messages cache to other features without explicit user agreement. Do NOT propose offline-first patterns "for resilience" or "for faster reads" in any other feature. This restriction holds until explicitly lifted.

> **🟥 ARCHITECTURAL CONSTRAINT (2026-05-29): NO USE-CASE LAYER.**
> The Use Case / Interactor layer described in §5.1 (`domain/usecases/<verb>.dart`), §7 Step 2.4, §8, and §9, plus `lib/core/usecase/usecase.dart` (the `UseCase` / `StreamUseCase` / `NoParams` contracts), have been **removed from this codebase**. Controllers and presentation providers depend on **repositories directly** via `ref.read(<feature>RepositoryProvider).method(...)`. Business rules and value-object validation live inside the repository implementation (so the controller hands raw inputs to the repo, which returns `Either<ValidationFailure, T>` or `Either<DomainFailure, T>`). Form-level input validation may still happen in the controller before the repo call (e.g. `Username.create(...)`).
>
> Do NOT generate, propose, or reinstate `domain/usecases/*.dart` files or `*UseCaseProvider` providers. This restriction holds until explicitly lifted.

This file is the source of truth for how this codebase is structured. Any agent (Claude Code or otherwise) modifying this project MUST follow these rules without exception. When in doubt, prefer the conventions documented here over patterns found elsewhere on the internet.

The README.md is a human-readable overview of the same architecture. This file (CLAUDE.md) is the agent-readable contract.

---

## 1. What this codebase is

A **foundation** — not a product. It's a Flutter chassis built with Clean Architecture, Riverpod 3.x, and Supabase. As of 2026-05-26 it is **online-only** — every feature reads/writes directly against Supabase. The drift package is retained ONLY for the `WizardDrafts` table (transient multi-step form persistence); no other local DB usage exists.

History note: the codebase originally shipped with offline-first scaffolding (a `todos` reference feature, a `SyncService`, a `pending_operations` queue, LWW upserts, and a local mirror of teams). All of that was removed on 2026-05-26 per a deliberate architectural decision. Sections in this doc that describe offline-first patterns are kept as historical reference but are NOT applicable to new code — see the banner at the top.

The auth feature (email OTP + native Google OAuth) is permanent infrastructure for any product built on this foundation.

When asked to add a new feature, follow Section 7 — it's a generic recipe that works for any online-only feature regardless of domain.

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

### Rule 7 — All features are online-only

> **🟥 SUPERSEDED 2026-05-26.** The original Rule 7 described a split between offline-first and online-only features. As of 2026-05-26 there is no offline-first capability in this codebase. Every repository's read and write methods talk to the remote data source directly. No drift tables (except `WizardDrafts`), no pending ops, no sync service. The matches feature is the canonical online-only shape; teams was converted to match it.

---

## 3. Folder Map

```
lib/
├── core/
│   ├── error/
│   │   ├── failures.dart                 # sealed Failure hierarchy
│   │   └── exceptions.dart               # raw exception types thrown by data sources
│   ├── supabase/
│   │   └── supabase_client_provider.dart # SupabaseClient as a keepAlive provider
│   ├── database/
│   │   ├── tables.dart                   # ONLY WizardDrafts (transient form state — not domain data)
│   │   ├── app_database.dart             # @DriftDatabase class
│   │   ├── wizard_draft_store.dart       # best-effort local persistence for multi-step wizard drafts
│   │   └── database_provider.dart        # appDatabase + wizardDraftStore keepAlive providers
│   ├── connectivity/
│   │   └── connectivity_provider.dart    # Stream<bool> isOnline provider (informational only)
│   ├── push/
│   │   ├── push_messaging_service.dart   # FCM: token, foreground heads-up, tap deep-link
│   │   └── push_provider.dart            # keepAlive provider for the messaging service
│   ├── theme/
│   │   └── circk_theme.dart              # CkColors / CkType / CkRadii tokens + buildCirckTheme()
│   ├── util/                             # small pure-Dart helpers
│   └── widgets/                          # shared, feature-agnostic UI (no Riverpod, no domain)
│       ├── ck_button.dart                # CkButton: primary / secondary / ghost (+ busy spinner)
│       ├── ck_text_field.dart            # labelled themed input with inline error/helper
│       ├── ck_bottom_nav.dart            # 5-tab HOME · MATCH · PAVILION · MESSAGES · PROFILE bar
│       ├── ck_screen_scaffold.dart       # paper Scaffold + top bar (matchday wordmark / title / bell / avatar)
│       └── v2/                           # v2 IA kit — feed/profile/composer widgets, CkFeedImage, shimmer
├── router/
│   └── app_router.dart                   # go_router; auth redirect + StatefulShellRoute (5-tab shell)
├── app.dart                              # MaterialApp.router + DB clear on sign-out + push registrar
├── main.dart                             # Supabase.initialize + GoogleSignIn.initialize + ProviderScope
└── features/
    ├── auth/                             # PERMANENT — email OTP + native Google OAuth (full layered)
    ├── onboarding/                       # PERMANENT — first-run profile wizard (full layered)
    ├── shell/                            # PERMANENT — authenticated 5-tab shell (presentation-only)
    ├── home/                             # PRESENTATION-ONLY — feed tab (composes posts providers)
    ├── pavilion/                         # PRESENTATION-ONLY — profile workspace hub
    ├── profile/                          # PRESENTATION-ONLY — profile detail view
    ├── messages/                         # PRESENTATION-ONLY — messages tab
    ├── location/                         # FULL — Places autocomplete + GPS for profile geo
    ├── notifications/                    # FULL — match-event feed + bell badge
    ├── teams/                            # FULL — online-only teams (create/hub/manage)
    ├── matches/                          # FULL — online-only match setup + live scoring
    ├── posts/                            # FULL — online-only feed + photo composer
    └── <your_feature>/                   # online-only by default; see §7

# Per-feature layout (for full-layered features):
lib/features/<feature>/
├── domain/
│   ├── entities/                         # plain Dart classes extending Equatable
│   ├── value_objects/                    # Email-like wrappers with Either<ValidationFailure, T>.create
│   └── repositories/                     # abstract classes returning Either<Failure, T> / Stream<T>
├── data/
│   ├── models/                           # freezed DTOs with toEntity()
│   ├── datasources/
│   │   ├── <feature>_remote_datasource.dart
│   │   └── <feature>_datasource_providers.dart   # @Riverpod providers for the above
│   └── repositories/
│       └── <feature>_repository_impl.dart        # only place that catches raw exceptions + business validation
└── presentation/
    ├── state/                            # sealed UI state union (only if controller needs sub-states)
    ├── controllers/                      # Notifier / AsyncNotifier / StreamNotifier — call repos directly via ref.read(<feature>RepositoryProvider)
    ├── screens/                          # ConsumerWidget / ConsumerStatefulWidget
    ├── widgets/                          # feature-local extracted widgets (flat; promote to subdir at ~3 files)
    └── providers/                        # @riverpod repository provider + intermediate stream/future views

supabase/
└── migrations/                           # timestamp-epoch SQL (e.g. 20260101000100_profiles.sql)

test/
└── features/<feature>/
    └── presentation/controllers/<name>_test.dart   # Notifier tests with ProviderContainer.test() + overrideWithValue
```

The only drift table in this codebase is `WizardDrafts` (transient form state for multi-step wizards). All domain data lives in Supabase; no domain entity is mirrored locally.

---

## 4. Tech Stack (current locked versions)

These versions are what `pubspec.yaml` declares. When asked to upgrade, verify the latest STABLE version on pub.dev (NOT pre-release / dev) and update both `pubspec.yaml` and this section.

```yaml
# Runtime
flutter_riverpod: ^3.3.1
riverpod_annotation: ^4.0.2          # NOTE: 4.0.3+ are pre-release; do not pin
supabase_flutter: ^2.12.4
google_sign_in: ^7.2.0               # v7+ API: GoogleSignIn.instance.authenticate()
drift: ^2.31.0                       # pinned to 2.31 line — see analyzer note below
drift_flutter: ^0.2.4
sqlite3_flutter_libs: ^0.5.26
path_provider: ^2.1.5
connectivity_plus: ^6.1.0
uuid: ^4.5.1
fpdart: ^1.1.0
freezed_annotation: ^3.0.0
json_annotation: ^4.9.0
go_router: ^16.2.0
flutter_svg: ^2.3.0                  # render brand vector assets (Google "G", pitch motif) faithfully
intl: ^0.20.2                        # date/number formatting (scorecards, timestamps)
timeago: ^3.7.1                      # relative timestamps ("3h ago") in feeds/notifications
# Push notifications (FCM). device_tokens table + send-push edge fn already
# deployed; the client obtains the token and registers it. See lib/core/push/
# + features/notifications PushRegistrar. Firebase project: matchday-44ed4.
firebase_core: ^4.10.0               # Firebase init (firebase_options.dart via flutterfire configure)
firebase_messaging: ^16.3.0          # FCM token + foreground/background/tap messages
flutter_local_notifications: ^18.0.1 # display FOREGROUND push as a heads-up (OS only auto-shows background/killed)
# Posts / photo pipeline (feature: posts). See §15.
image_picker: ^1.2.2                 # pick photos from gallery/camera (composer)
image_cropper: ^12.2.1               # crop/adjust step (ratio presets + zoom) before upload
flutter_image_compress: ^2.4.0       # resize ≤1080px + JPEG encode on-device before upload
cached_network_image: ^3.4.1         # disk+memory cached feed images (memCacheWidth = sized decode)
blurhash_dart: ^1.2.1                # encode BlurHash on-device from the resized bytes
image: ^4.8.0                        # decode pixels for BlurHash encoding
flutter_blurhash: ^0.9.1             # render the BlurHash placeholder (blur → sharp fade)
photo_view: ^0.15.0                  # full-screen pinch-zoom photo viewer
# NOTE: google_fonts was removed in favour of bundled variable fonts. The
# Inter / Inter Tight / JetBrains Mono TTFs live in assets/fonts/ and are
# declared under `flutter: fonts:` in pubspec.yaml. This keeps the app
# offline-first: fonts never fetch from fonts.gstatic.com at runtime.
# CkType (lib/core/theme/circk_theme.dart) uses plain TextStyle(fontFamily:).

# Codegen (dev_dependencies)
build_runner: ^2.4.13
riverpod_generator: ^4.0.3           # NOTE: 4.0.4+ are pre-release
freezed: ^3.2.5
json_serializable: ^6.8.0
drift_dev: ">=2.31.0 <2.32.0"        # capped: 2.32+ requires analyzer >=10 (see note below)

# Tooling (dev_dependencies)
# riverpod_lint and custom_lint are TEMPORARILY DISABLED due to an ecosystem
# constraint conflict (see below). Do NOT add them back until verified.
# riverpod_lint: ^3.1.3
# custom_lint: ^0.8.0
flutter_lints: ^5.0.0
mocktail: ^1.0.4

# SDK
sdk: ^3.7.0
flutter: ">=3.27.0"
```

### Riverpod ecosystem versioning

The Riverpod ecosystem has split versioning across multiple independent lines: the runtime (`flutter_riverpod`) is on 3.x, the codegen tooling (`riverpod_annotation`, `riverpod_generator`) is on 4.x, and the lint package (`riverpod_lint`) is on its own 3.1.x line. None of these track each other. This split is intentional — do not "fix" it by trying to align them. Always check pub.dev for each package's actual current stable version.

Note: with `flutter_riverpod: ^3.3.1`, pub resolves the `riverpod` runtime to **3.2.1** (not 3.3.1). The `AsyncValue` API in 3.2.1 exposes `value` (null-safe) and `requireValue` — there is **no** `valueOrNull` getter. Use `.value`.

### The analyzer constraint conflict (why drift is pinned and the lint tools are off)

Under Flutter 3.41.x, the bundled SDK pins `meta` to `1.17.0`, which caps `analyzer` below `10.0.2`. Two demands then collide:

- `drift_dev` 2.32+ requires `analyzer >=10`.
- The entire **stable** Riverpod tooling line (`riverpod_generator` ≤4.0.3, `riverpod_lint` ≤3.1.3) requires `analyzer ^9`.

No single `analyzer` version satisfies both, so they cannot coexist. The resolution:

1. **Pin drift to the 2.31 line** (`analyzer >=8.1.0 <11.0.0`), which overlaps the Riverpod tooling's `^9`. This keeps `riverpod_generator` (required for codegen) working.
2. **Remove `riverpod_lint` + `custom_lint`.** Even on the 2.31 drift line they'd resolve analyzer-wise, but `riverpod_lint` 3.1.3 hard-pins `riverpod: 3.2.1`; more importantly the lints are a dev-only nicety, not required to build.

Re-enable both (drift 2.32+ and `riverpod_lint`) once `riverpod_generator`/`riverpod_lint` ship a stable release supporting `analyzer >=10`, OR once the project moves to a Flutter version whose `meta` pin allows `analyzer >=10.0.2`. Verify with `flutter pub get` before committing.

### Why riverpod_lint and custom_lint are disabled

As of the latest Flutter stable (3.41.x, Dart 3.7.x), there is a three-way constraint conflict that cannot be resolved:

- `riverpod_lint <=3.1.3` (latest stable) requires `analyzer ^9.x`
- `drift_dev ^2.32.1` requires `analyzer >=10.x`
- Flutter 3.41.x pins `meta 1.17.0`, which transitively requires `analyzer <10.0.2`

There is no overlap in these ranges, so `pub get` fails when all three are present. The lint package is dev-only (it does not affect runtime behavior), so the practical fix is to remove it temporarily.

**Criterion for re-enabling**: when a stable `riverpod_lint` release supports `analyzer >=10`, restore both packages in `pubspec.yaml` and uncomment the `plugins: - custom_lint` line in `analysis_options.yaml`. Verify with `flutter pub get` followed by `dart run custom_lint`. Until then, the watch/read/listen and provider-DAG rules are enforced by `architecture-reviewer` agent review and by the patterns documented in this file, NOT by an automated lint.

If a feature needs a dependency not listed here (e.g. file picker, image cropper, charts), add it via `flutter pub add <package>` and document it here with the chosen version and rationale.

---

## 5. Layer-by-Layer Specification

Code templates below use deliberately generic names (`Foo`, `Bar`) so they read as recipes rather than implementations. When applying them to a real feature, replace placeholders with your actual entity/feature names.

### 5.1 Domain Layer

#### Entity template (`domain/entities/foo.dart`)

```dart
// Pure Dart. No imports outside dart:*, `package:equatable/equatable.dart`,
// and other Domain files.
import 'package:equatable/equatable.dart';

class Foo extends Equatable {
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
  List<Object?> get props => [id, title, createdAt, updatedAt];
}

class FooId extends Equatable {
  const FooId(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value;
}
```

Notes:
- Entities are plain Dart classes that `extends Equatable` and expose a `List<Object?> get props => [...]` getter for value equality. Equatable is pure-Dart (no codegen, no serialization concerns) — it keeps Domain pure while removing the risk of forgetting a field when manually rolling `==`/`hashCode`. Do NOT use Freezed for entities — it pulls Domain into Data's serialization concerns.
- ID types are always wrapped (`FooId`, `UserId`, etc.), never raw `String`. They also `extends Equatable` so `==` on the wrapper works as expected.
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

#### Folder layout — what goes where

The presentation layer has five subfolders. Each has a precise role; do not collapse them.

| Folder | What goes in it |
|---|---|
| `state/`       | Immutable types describing what the screen sees. Three legitimate shapes — see below |
| `controllers/` | `@riverpod` `Notifier` / `AsyncNotifier` / `StreamNotifier` classes — the view-model behaviour (the Riverpod community treats the Notifier *as* the view model; there is no separate ViewModel class) |
| `screens/`     | One file per route. Top-level `ConsumerWidget` / `ConsumerStatefulWidget` |
| `widgets/`     | Reusable widgets extracted from THIS feature's screens. Flat by default |
| `providers/`   | Repository + use-case DI providers. Nothing else (controller/notifier providers are generated from `@riverpod` and live with the controller) |

##### `state/` — three legitimate patterns, one folder

A `state/` file is always an immutable type describing what the controller exposes. There are three distinct shapes, all valid:

1. **Sealed lifecycle state** — `sealed class FooState` with discrete sub-states (`Initial`, `SendingOtp`, `OtpSent(email)`, `Verifying`, `Authenticated`, `Failed`). Use when the UI itself changes shape per state (OTP flow, payment flow). Hand-rolled (NOT freezed) to keep `switch`-pattern matching simple. Reference: `lib/features/auth/presentation/state/auth_state.dart`.
2. **Form / wizard state** — `@freezed` class with many fields and `copyWith` for step-by-step mutation. Use for multi-step wizards. References: `onboarding_state.dart`, `team_create_state.dart`, `match_setup_state.dart`.
3. **View-model struct** — immutable class composing multiple data sources into one screen-ready shape. Use when the controller's `build()` returns a derived value (not raw entities) — typically because the screen needs data from several features (teams + matches + currentUser → `MyTeamsView`). This is Uncle Bob's original "ViewModel": a passive data struct, not behaviour. Reference: `lib/features/teams/presentation/state/my_teams_view.dart`.

**Skip `state/` entirely** if the controller returns `AsyncValue<List<Foo>>` or `AsyncValue<Foo>` directly — no wrapping for the sake of wrapping. Simple CRUD lists, profile views, settings screens don't need a state file.

##### `controllers/` — the view-model behaviour

The `@riverpod` Notifier IS the view model. It owns the state, exposes action methods, and reads use cases via `ref.read`. Pick:
- `Notifier` when initial state is synchronous (multi-step flow seeded from defaults).
- `AsyncNotifier` when `build()` awaits an async fetch (composing data sources, restoring wizard drafts).
- `StreamNotifier` when `build()` returns a `Stream` directly — uncommon here; the prevailing pattern is an intermediate `@riverpod Stream<T>` free-function provider in `providers/` that the controller `await`s via `.future`.

##### `screens/` — one file per route

Each screen file owns one route. **Keep it monolithic until ~800 LOC, or until a sub-widget is reused by another screen.** Premature splitting fragments the screen across many files and forces readers to jump around. Extraction is a response to size or reuse, not the starting layout. (`team_page_screen.dart` at 3,142 LOC and `team_create_screen.dart` at 2,798 LOC are past the threshold — both have decomposed into `widgets/team_page/` and `widgets/team_create/`.)

##### `widgets/` — flat by default

Place feature-local extracted widgets flat in `widgets/` (e.g. `post_card.dart`, `ball_pill.dart`, `circk_brand.dart`). Promote to a `widgets/<screen_name>/` sub-folder ONLY when a single screen's extractions exceed ~3 files (`widgets/team_page/`, `widgets/team_create/`, `widgets/my_teams/`). Do not use a feature's `widgets/` for cross-feature shared widgets — those live in `lib/core/widgets/`.

##### `providers/` — DI only

Repository provider (returning the abstract type) and one provider per use case. Intermediate `@riverpod Stream<T>` fan-out providers (e.g. `myTeamsProvider`, `ballsProvider`) also live here — they wrap a use case so multiple consumers share one subscription. Controller providers are generated automatically by `@riverpod`; do not declare them by hand.

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
- Domain entities (use `extends Equatable` + `props` to keep Domain pure Dart while still getting safe value equality)
- View state with sub-states that don't need `copyWith` (hand-rolled sealed classes are simpler)
- Value objects (private constructor + factory `create` is the pattern; `extends Equatable` for the equality)

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

### 6.4 Offline-First Sync — REMOVED 2026-05-26

> **🟥 SUPERSEDED.** The offline-first machinery (sync service, pending ops queue, LWW upserts, real-time mirror, todos reference) was removed from this codebase on 2026-05-26. New features must NOT reintroduce any of it. The text below is preserved as historical documentation of what the pattern looked like; it does NOT apply to current code.

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

**The pending-ops queue lives in core.** `PendingOperationsDataSource` is at `lib/core/sync/pending_operations_datasource.dart` (provider in `pending_operations_provider.dart`) — it's shared infrastructure, NOT owned by any feature. It exposes a generic `enqueue({opType, entityType, entityId, payload})` plus todos convenience wrappers. New features call `enqueue(...)` directly. Do NOT import a feature's data layer to reach the queue.

**Extending sync to a new feature.** `SyncService._executeOp` dispatches on `op.entityType` and currently handles `todo` + the three teams types (`team`, `team_member`, `unclaimed_player`). To support a new feature:

1. Reuse the existing `OpType` enum if your verbs fit (teams reused `create/update/delete`).
2. Pick a new `entityType` string per table (`'post'`, `'comment'`, …).
3. In `sync_service.dart`, add a branch in `_executeOp`'s `switch (op.entityType)` and extend `_pullAndMerge` + `startRealtimeMirror` with your feature's list/stream calls.
4. Inject your feature's local + remote data sources into `SyncService` (constructor + `sync_provider.dart`).

> ⚠️ **Handler refactor is now due.** SyncService already hard-codes two features (todos + teams) and teams spans three entity types. The NEXT synced feature should trigger the §6.4 `SyncHandler` interface refactor (features register a handler that owns their `_executeOp`/pull/realtime), rather than adding a fourth `entityType` branch. A flag comment marks this in `sync_service.dart`.

When sign-out happens: `app.dart` listens to `currentUserStream` and calls `AppDatabase.clear()` to wipe ALL local data (todos, teams, pending ops, wizard drafts). This prevents user A's data appearing for user B on the same device.

When sign-out happens: `app.dart` listens to `currentUserStream` and calls `AppDatabase.clear()` to wipe ALL local data (todos, future offline features, pending ops). This prevents user A's data appearing for user B on the same device.

### 6.5 Wizard draft persistence

Multi-step wizards (onboarding, and later team-create / match-setup) autosave their in-progress form state so a killed app can resume. This is **transient presentation state, not domain data**, so it deliberately does NOT go through a domain repository / use case:

- Backed by the shared `WizardDrafts` drift table (`lib/core/database/tables.dart`) — keyed by a caller string (e.g. `'onboarding'`), payload is the controller's JSON-encoded draft. Never synced, no `user_id`/`updated_at`, no pending op. Wiped by `AppDatabase.clear()` on sign-out (so a constant key is safe).
- Accessed via `WizardDraftStore` (`lib/core/database/wizard_draft_store.dart`) — best-effort: reads/writes swallow errors (a lost draft is a minor annoyance, never an `Either<Failure,_>`).
- A `@riverpod` **controller may depend on `wizardDraftStoreProvider` directly** (it's in `lib/core/database/`), the same way the todos controller reaches for `syncServiceProvider`. This is the one sanctioned case of a controller touching a `core/database/` class without a use case in between — justified because drafts aren't domain data. Do NOT extend this to actual domain reads/writes.

The `wizardDraftStore` provider lives in `database_provider.dart` (not in the store's own file) to honour Rule 5's `lib/core/*/*_provider*.dart` convention.

### 6.6 Cross-feature dependencies

Features compose. When feature A genuinely builds on feature B (e.g. `matches` builds on `teams` — a match is a contest between two teams), these cross-feature references are PERMITTED, but only in specific directions:

- **Domain → Domain.** A's domain may reference B's domain *entities/value objects* when the relationship is intrinsic to the model. Example: `Match` holds `TeamId` (from `teams/domain`). Do NOT duplicate the id type. Both sides stay pure Dart, so Rule 1 still holds.
- **Presentation → Presentation providers.** A's *screen* may `ref.watch` B's *providers* to read B's data (e.g. the match-setup Pick-XI step watches `rosterProvider`; the opponent step watches `allTeamsProvider`). Read B through its `presentation/providers`, never B's data sources/DTOs/repository impls.
- **FORBIDDEN:** importing another feature's `data/` layer (data sources, DTOs, repository impls) or its `domain/repositories` abstract. If you need B's behaviour, go through a B use-case provider.

These are the only sanctioned cross-feature seams.

**Presentation-only features.** A feature may have only a `presentation/` folder (no `domain/`/`data/`) when it is purely an aggregation view that derives everything by watching other features' providers through the seam above — e.g. `pavilion` (profile hub) and `notifications` (a match-event feed derived from `myMatches`). Don't invent a domain entity that just duplicates another feature's (`Notification` would duplicate `Match`+`MatchStatus`). The moment such a feature gains its OWN backend (push tokens, unread state, settings), promote it to a full feature with domain + data layers.

**Computed-draft objects in the Domain.** A controller sometimes needs to hand the repository a structured *computed* value (not a persisted entity yet) — e.g. `BallDraft` (matches): the controller assembles the inputs and `MatchesRepository.recordBall(BallDraft)` computes the delivery's numbers + resulting strike rotation, validates, and persists in one call. Place such drafts in the **entity layer** (alongside the entity they relate to), so both the controller (input) and the repository contract (input) can reference them without a cross-layer import cycle. They're pure Dart like any entity.

Player IDs are intentionally raw `String` across `teams` (`TeamMember.playerId`) and `matches` (`Match.teamASquad`/`teamACaptain`) because they are polymorphic (a `profiles.user_id` OR an `unclaimed_id`); a single wrapper can't express that without a union. This is a deliberate, documented exception to the "wrap all IDs" rule (§5.1).

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
mkdir -p lib/features/<feature>/{domain/{entities,value_objects,repositories},data/{models,datasources,repositories},presentation/{state,controllers,screens,widgets,providers}}
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

# Run with all required compile-time config.
# Real values live in dart_define.json (gitignored); the committed
# dart_define.example.json is the template. Copy it once and fill in values:
#   cp dart_define.example.json dart_define.json
flutter run --dart-define-from-file=dart_define.json

# (Equivalent long form, still valid — flags merge with the file:)
# flutter run \
#   --dart-define=SUPABASE_URL=https://YOURPROJECT.supabase.co \
#   --dart-define=SUPABASE_ANON_KEY=eyJ... \
#   --dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com \
#   --dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com

# Watch mode for codegen during development
dart run build_runner watch --delete-conflicting-outputs

# Static analysis
flutter analyze

# Tests
flutter test
```

> Note: `dart run custom_lint` (riverpod_lint rules) is currently NOT runnable — riverpod_lint + custom_lint are removed from pubspec due to the analyzer constraint conflict documented in §4. The watch/read/listen and provider-DAG rules are enforced by review and by the patterns in this file until the lint packages can be re-enabled.

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
- File upload / Supabase Storage (beyond the `post-media` bucket described in §15)
- Background sync (workmanager)
- Multi-tenant data sharing (RLS policies sketched in Section 12 but no full feature reference)
- Profile editing with separate `profiles` table
- Pagination for large lists (beyond posts' keyset pagination)
- Internationalization (i18n)
- Analytics / event tracking

When any of these come up for the first time, follow Section 13's guidance: extend an existing pattern, document the extension here, flag it in your output.

---

## 14. Online-only reference features — quick map

The `todos` reference feature and all offline-first wiring were removed on 2026-05-26. The current canonical online-only references are `matches` (one-shot reads + real-time streams for live data) and `teams` (real-time stream reads + direct write-through). When you need to see how a pattern is implemented in this codebase:

| Concern | Where to look |
|---|---|
| Online-only repository (one-shot + stream reads, direct writes, exception translation, **inlined business validation**) | `lib/features/matches/data/repositories/matches_repository_impl.dart` |
| Real-time stream reads via Supabase | `lib/features/teams/data/repositories/teams_repository_impl.dart` (`watch*` methods) |
| Remote data source pattern | `lib/features/matches/data/datasources/matches_remote_datasource.dart` |
| AsyncNotifier composing cross-feature providers (calls `matchesRepositoryProvider` directly) | `lib/features/teams/presentation/controllers/teams_list_controller.dart` |
| Provider DI shape (no use-case providers — just `<feature>Repository` + intermediate `Stream`/`Future` views) | `lib/features/teams/presentation/providers/teams_providers.dart`, `lib/features/matches/presentation/providers/matches_providers.dart` |
| Controller calling repo directly with value-object validation inlined | `lib/features/onboarding/presentation/controllers/onboarding_controller.dart` (`submit`), `lib/features/teams/presentation/controllers/add_unclaimed_player_controller.dart` (`submit`) |
| Wizard draft persistence (the only drift use) | `lib/core/database/wizard_draft_store.dart` + `lib/core/database/tables.dart` |
---

## 15. Posts feature + image/media spec

The `posts` feature (`lib/features/posts/`) is the feed. It is **online-only** (no offline-first — same posture as `matches`, Rule 7): the repository talks to Supabase directly; there is no drift table, pending-ops queue, or SyncService involvement.

**Backend (already deployed).** The `posts` table lives in `supabase/migrations/` under the timestamp-epoch convention (look for the `*_posts*.sql` files). The schema includes a `media jsonb` column (`[{url, blurhash, width, height}]`, ≤4) alongside `post_has_content`. The `post-media` storage bucket is public; **insert the row before uploading media** (storage RLS `is_post_author`). Paths are deterministic (`<post_id>/<i>.jpg`) so public URLs are computed up front and written to `media`/`media_urls` at insert.

**Per-image storage (resize-before-upload → ONE file per image).** On device: crop → resize to **≤1080px long edge, JPEG q75**; compute BlurHash + width/height. Then 1 file at `post-media/<post_id>/<i>.jpg` + 1 metadata object `{url, blurhash, width, height}` in `posts.media` (≤4). 1080 is the display max (Instagram-style); the same file serves feed + zoom. There is no separate thumbnail file.

**Read/scroll performance.** Feed = single query (media is jsonb on the post, no joins) + keyset pagination (`created_at` cursor on the `posts_status_created` index). `FeedController` is an `AsyncNotifier` with `loadMore`/`refresh`/`prepend`. The feed/profile are virtualized `ListView.builder`s; photos render via `CkFeedImage` (`lib/core/widgets/v2/ck_feed_image.dart`): `cached_network_image` with `memCacheWidth = slotPx × devicePixelRatio` (sized decode), a BlurHash placeholder, and an `AspectRatio` box to avoid reflow. Shared post UI is `FeedPostCard` + `PostMediaGrid` (`lib/core/widgets/v2/post_card.dart`).

**Composer.** `lib/features/posts/presentation/screens/composer_screen.dart` (launched from the Profile FAB + Pavilion Create→Post). Photo pipeline: `data/datasources/photo_processor.dart` (image_picker → image_cropper → flutter_image_compress → blurhash_dart/image). `CreatePost` validates text-or-≥1-photo, ≤2000 chars, ≤4 photos. MVP composes `author_context='personal'` only.

**Deferred (not yet built):** likes/comments/bookmarks persistence (schema + mock UI exist), drafts/scheduling/visibility-sheet/preview/Success (post-flow design), team/tournament authoring, auto post types, realtime feed, a `blurhash`-per-row already covered by `media`, avatar uploads.

---

## 16. Push notifications (FCM)

Push is wired end-to-end as of 2026-06-06. Firebase project: `matchday-44ed4`. Android app id: `com.matchday.app` (ready). iOS requires the Push Notifications capability + APNs key in Xcode before tokens will issue.

**Where things live:**
- `lib/core/push/push_messaging_service.dart` — wraps `FirebaseMessaging`: token retrieval, foreground / background / terminated message handlers, tap → deep-link.
- `lib/core/push/push_provider.dart` — `@Riverpod(keepAlive: true)` for the service. Initialized via `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in `main.dart` (the `firebase_options.dart` file is produced by `flutterfire configure`).
- `features/notifications/.../push_registrar.dart` — the **registrar**. On every sign-in, requests the FCM token from the service and upserts it into the `device_tokens` Supabase table. On sign-out the token row is deleted.
- `flutter_local_notifications` displays foreground pushes as heads-up notifications (the OS auto-shows background/killed pushes).

**Backend:** the `device_tokens` table + a `send-push` edge function are already deployed. Notifications (match events, etc.) call `send-push` server-side with the target `user_id`; the edge function looks up that user's tokens and dispatches via FCM.

**Tap handling:** Push payloads include a `route` field. `PushMessagingService` listens for tap events and forwards the route to the router; the router validates and navigates. Don't navigate from the service directly — go through go_router so the auth-redirect logic still applies.

**Routing requests through push.** Anything that would have wanted a real-time subscription on a request-shaped table (e.g. `match_requests`) should instead piggyback on the existing notifications broadcast — the state-change signal is already there. Do not add request tables to `supabase_realtime`.
