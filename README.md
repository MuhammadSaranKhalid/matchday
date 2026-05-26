# Novex Clean Architecture — Flutter + Riverpod 3.x + Supabase (online-only)

A Flutter chassis built with Clean Architecture, Riverpod 3.x, and Supabase. Online-only — every feature reads and writes directly against Supabase. The codebase is the foundation for **matchday** (a cricket app), but the architectural patterns generalize to any product.

> Historical note: this codebase originally shipped with an offline-first stack (drift cache + sync service + pending-ops queue + LWW). All of that was removed on 2026-05-26. The `drift` package is retained only for the `WizardDrafts` table (transient multi-step form state).

## Architecture in one sentence

Three layers — **Presentation → Domain ← Data**. Domain is pure Dart; presentation depends on Domain through use-case providers; data implements Domain abstractions and talks to Supabase.

```
Presentation (Flutter + Riverpod)  ─┐
                                    ├──> Domain (pure Dart)
Data (Supabase remote data sources)─┘
```

## Project documentation

| File | Audience | Purpose |
|---|---|---|
| `README.md` (this file) | Humans onboarding | What is this, how do I run it, how do I read the code |
| `CLAUDE.md` | Claude Code (agent contract) | Rules + templates + the feature-building recipe |
| `BEST_PRACTICES.md` | Developers writing the code | The disciplines that keep the stack healthy |
| `.claude/agents/*.md` | Claude Code (specialized subagents) | Focused workers Claude Code delegates to |

### Claude Code subagents

The `.claude/agents/` directory contains project-scoped subagents Claude Code uses for delegated work:

- `architecture-reviewer` — read-only review against CLAUDE.md rules
- `feature-builder` — implements new features end-to-end per CLAUDE.md §7
- `test-writer` — generates the test pyramid for a feature
- `riverpod-specialist` — state management deep expertise
- `supabase-specialist` — RLS, auth, real-time, schema
- `drift-specialist` — only relevant if/when local storage is reintroduced
- `version-auditor` — periodic dependency hygiene

## Folder map

```
lib/
├── core/
│   ├── error/                  # Failure hierarchy + raw exception types
│   ├── usecase/                # base UseCase + StreamUseCase + NoParams
│   ├── supabase/               # SupabaseClient provider (keepAlive)
│   ├── database/               # drift schema (ONLY WizardDrafts) + AppDatabase
│   ├── connectivity/           # online/offline stream (informational)
│   ├── theme/                  # CkColors / CkType tokens + buildCirckTheme
│   └── widgets/                # shared feature-agnostic UI (button, text field, ...)
├── router/                     # go_router with auth-aware redirect
├── app.dart                    # MaterialApp.router + clears wizard drafts on sign-out
├── main.dart                   # Supabase.initialize + GoogleSignIn.initialize + ProviderScope
└── features/
    ├── auth/                   # PERMANENT — email OTP + native Google OAuth
    ├── onboarding/             # PERMANENT — first-run profile (username, display name, city, player)
    ├── shell/                  # PERMANENT — authenticated 5-tab shell
    ├── home/                   # Home feed
    ├── teams/                  # Teams (create, hub, manage); canonical online-only feature with realtime streams
    ├── matches/                # Match setup + scoring lifecycle
    ├── posts/                  # Feed posts (text + ≤4 photos with BlurHash)
    ├── pavilion/               # PAVILION profile hub (composition of other features)
    ├── profile/                # Profile view + edit
    ├── messages/               # (presentation only)
    ├── notifications/          # (presentation only)
    └── location/               # Places autocomplete + GPS fallback
```

Each product feature follows the same shape: `domain/` (entities, value objects, repositories abstract, use cases) + `data/` (DTOs, remote data source, repository impl) + `presentation/` (controllers, screens, providers, optional state).

## Reading the codebase

The architecture is consistent enough that you can read any feature top-down without surprises. For "where does this data come from?" questions, walk the call stack from the screen:

1. **Screen** → what does it `ref.watch`? That's its only input.
2. **Controller** → its `build()` shows what providers it composes.
3. **Provider file** (`presentation/providers/*.dart`) → each `*Provider` resolves to a `@riverpod`-annotated function/class in the same file (codegen adds the `Provider` suffix to the symbol in the `.g.dart` file).
4. **Use case** → one verb, usually ~10 lines. The repository call inside is the meaningful line.
5. **Repository impl** (`data/repositories/`) → only descend here if you're chasing a specific bug; the abstract contract in `domain/repositories/` usually tells you enough.

For specific patterns, the canonical references are:

| Pattern | Best file to read |
|---|---|
| Online-only repository (one-shot + stream reads, exception translation) | `lib/features/matches/data/repositories/matches_repository_impl.dart` |
| Online-only repository with Supabase realtime stream reads | `lib/features/teams/data/repositories/teams_repository_impl.dart` |
| Remote data source talking to Supabase | `lib/features/matches/data/datasources/matches_remote_datasource.dart` |
| AsyncNotifier composing cross-feature providers | `lib/features/teams/presentation/controllers/teams_list_controller.dart` |
| Provider DI shape | `lib/features/teams/presentation/providers/teams_providers.dart` |
| Sealed view state | `lib/features/auth/presentation/state/auth_state.dart` |
| Value object with `Either<ValidationFailure, T> create(...)` | `lib/features/auth/domain/value_objects/email.dart` |

## Setup

### 1. Supabase

Create a project; copy URL + anon (publishable) key. The schema is defined in `supabase/migrations/`; either apply those migrations to your project or use the Supabase CLI to link your local project.

### 2. Auth providers

`Authentication → Providers` — enable Email (for OTP) and Google. For Google, paste the **web client ID and secret** from Google Cloud Console; the Android/iOS OAuth clients are configured on-device via `google_sign_in`.

### 3. Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Copy the template, then fill in your real values.
cp dart_define.example.json dart_define.json

flutter run --dart-define-from-file=dart_define.json
```

`dart_define.json` holds the compile-time config (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`). The real file is gitignored; commit only `dart_define.example.json`. Changing the file requires a full restart (hot reload won't pick up `--dart-define`s). VS Code users can pick a launch config from `.vscode/launch.json`, which already passes the flag.

## Conventions

**Domain is pure Dart.** No Supabase, no drift, no Flutter, no Riverpod imports in `domain/`. The compiler enforces it because those packages simply aren't imported.

**Exceptions never cross the Domain boundary.** Data sources throw raw exceptions (`AuthException`, `PostgrestException`, etc.). Repository implementations are the only place those are caught and translated to `Failure` subtypes returned as `Left(Failure)` in `Either<Failure, T>`.

**Online-only by default.** Every feature's repository talks to Supabase directly. There is no local cache for domain data. Reads are either one-shot `Future<Either<Failure, T>>` or a Supabase real-time stream wrapped in a `Stream<T>`. Writes call the remote and translate exceptions.

**One verb per use case.** `AddTeam`, `VerifyEmailOtp`, `WatchMyTeams`. Even thin delegate use cases stay — they're the contract for "what operations exist" and the home for future business rules (see CLAUDE.md §1.2 and the rationale section in BEST_PRACTICES.md).

**Providers form a DAG, not a cycle.** Data source providers live in their own file (`*_datasource_providers.dart`) so cross-cutting providers can depend on them without cycles.

## Riverpod 3.x notes

Unified `Ref` type — every provider uses `(Ref ref)`. Long-lived dependencies get `@Riverpod(keepAlive: true)` — `SupabaseClient`, `AppDatabase`, data sources, repositories. Use cases and controllers are bare `@riverpod` (autodispose). State of streamed reads is `AsyncValue<T>`; pattern-match it with Dart 3 `switch`, never `.when` / `.map`.

## Testing

```bash
flutter test
```

The test pyramid emphasis is on **use case tests** (pure Dart, fastest, business rules) and **controller tests** (using `ProviderContainer.test()` with provider overrides). Mocking is done with `mocktail`, never `mockito`. See BEST_PRACTICES.md §9 for the full pyramid breakdown.

## What's deliberately omitted

- **Offline-first / local caching for domain data** — removed 2026-05-26. The current scope is online-only until further notice.
- **Background sync** — irrelevant without offline mode.
- **End-to-end encryption** — Supabase TLS + Vault is sufficient for current scope.
- **`riverpod_lint` / `custom_lint`** — temporarily disabled due to an analyzer constraint conflict (see CLAUDE.md §4 "The analyzer constraint conflict").
