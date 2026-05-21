# Novex Clean Architecture — Flutter + Riverpod 3.x + Supabase + Offline-first

A reference Flutter app demonstrating Clean Architecture with Riverpod 3.3.1, Supabase, and **offline-first persistence via drift**. Two features — **Auth** (email OTP + Google OAuth, online-only) and **Todos** (full offline CRUD with sync) — exercising every layer.

## Architecture in one sentence

Three layers — **Presentation → Domain ← Data**. The Domain repository contract didn't change when we added Supabase, and didn't change again when we added offline support. That's the test of whether the architecture is paying off.

```
Presentation (Flutter + Riverpod)                         ─┐
                                                           ├──> Domain (pure Dart)
Data (Supabase + drift + connectivity + sync orchestrator)─┘
```

## Project documentation

This project ships with five documents, each playing a different role:

| File | Audience | Purpose |
|---|---|---|
| `README.md` (this file) | Humans onboarding | What is this, how do I run it, architecture overview |
| `CLAUDE.md` | Claude Code (agent contract) | Rules + templates + the feature-building recipe |
| `BEST_PRACTICES.md` | Developers writing the code | The disciplines that make this stack healthy |
| `PACKAGES.md` | Anyone adding dependencies | Curated package recommendations + what to avoid |
| `.claude/agents/*.md` | Claude Code (specialized subagents) | Focused workers Claude Code delegates to |

### Claude Code subagents

The `.claude/agents/` directory contains seven project-scoped subagents Claude Code uses for delegated work:

- `architecture-reviewer` — read-only review against CLAUDE.md rules
- `feature-builder` — implements new features end-to-end per CLAUDE.md Section 7
- `test-writer` — generates the test pyramid for a feature
- `riverpod-specialist` — state management deep expertise
- `supabase-specialist` — RLS, auth, real-time, schema
- `drift-specialist` — local DB, migrations, offline-first patterns
- `version-auditor` — periodic dependency hygiene

See `.claude/agents/README.md` for how Claude Code uses them and how to extend the set.

## Folder map

```
lib/
├── core/
│   ├── error/                  # Failure, exception types
│   ├── usecase/                # base UseCase + StreamUseCase
│   ├── supabase/               # Supabase client provider
│   ├── database/               # drift schema + AppDatabase + provider
│   ├── connectivity/           # online/offline stream provider
│   └── sync/                   # SyncService + sync_provider
├── router/                     # go_router with auth-aware redirect
├── app.dart                    # MaterialApp + bootstraps sync + clears DB on sign-out
├── main.dart                   # Supabase.initialize + ProviderScope
└── features/
    ├── auth/
    │   ├── domain/             # User, Email/OtpCode VOs, repo contract, use cases
    │   ├── data/               # UserDto, AuthRemoteDataSource, RepositoryImpl
    │   └── presentation/       # Sealed AuthState, AuthController, SignInScreen
    └── todos/
        ├── domain/             # Todo entity (with updatedAt), repo contract, CRUD + stream use cases
        ├── data/
        │   ├── models/         # TodoDto (with updated_at)
        │   ├── datasources/
        │   │   ├── todos_local_datasource.dart        # drift cache
        │   │   ├── pending_operations_datasource.dart # sync queue
        │   │   ├── todos_remote_datasource.dart       # Supabase
        │   │   └── todos_datasource_providers.dart    # shared DI for the above
        │   └── repositories/
        │       └── todos_repository_impl.dart         # coordinator
        └── presentation/
            ├── controllers/    # TodosController (StreamNotifier, thin actions)
            ├── screens/        # TodosScreen + TodosRealtimeScreen
            └── providers/      # repo + use case DI
```

## Setup

### 1. Supabase

Create a project; copy URL + anon key.

### 2. Schema, RLS, real-time, and `updated_at` trigger

In the Supabase SQL editor:

```sql
-- Table
create table todos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  title       text not null check (length(title) between 1 and 140),
  completed   boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- RLS: owners only
alter table todos enable row level security;
create policy "todos are private to the owner"
  on todos for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- updated_at trigger: bumps on every row change
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger todos_updated_at
  before update on todos
  for each row execute function set_updated_at();

-- Real-time
alter publication supabase_realtime add table todos;
```

The trigger is what makes LWW conflict resolution work: every server-side update bumps `updated_at`, and the client compares timestamps to decide which side wins.

### 3. Auth providers

`Authentication → Providers` — enable Email (for OTP) and Google. For Google, paste the **web client ID and secret** from Google Cloud Console; the Android/iOS OAuth clients are configured on-device via `google_sign_in`.

### 4. Build & run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run \
  --dart-define=SUPABASE_URL=https://YOURPROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com
```

All four `--dart-define`s are consumed only by `main.dart` (Supabase init + GoogleSignIn.initialize). No data source carries client IDs.

## Offline-first model

The Data layer has four collaborators, with the repository as coordinator:

| Component | Lives in | Responsibility |
|---|---|---|
| `TodosLocalDataSource` | `data/datasources/` | drift-backed cache; source of truth for reads |
| `PendingOperationsDataSource` | `data/datasources/` | FIFO queue of unsynced mutations |
| `TodosRemoteDataSource` | `data/datasources/` | Supabase Postgrest CRUD + real-time stream |
| `SyncService` | `core/sync/` | Pushes pending ops, pulls remote, mirrors real-time → local |
| `TodosRepositoryImpl` | `data/repositories/` | Coordinates the four above |

**Reads** always go to the local drift DB. `watchAll()` returns a drift stream that emits whenever a local row changes — whether the change came from the user, the sync service replaying a pending op, or a Supabase real-time push.

**Writes** always go to the local DB first. The repo:
1. Generates a UUID v4 (or uses an existing one for updates).
2. Writes to the local DB (UI sees the change instantly via the stream).
3. Enqueues a pending operation row.
4. Nudges the sync service to push immediately. If offline, the nudge is a no-op until connectivity returns.

**Conflict resolution: last-write-wins by `updated_at`.** When sync pulls from remote, it compares each remote row's `updated_at` against the local copy. If local is newer (offline edit pending), the remote row is skipped and the pending op pushes the local version up. If remote is newer, local is overwritten. The `updated_at` trigger guarantees the server's value is always fresh on every mutation.

**Sync triggers:**
- App startup (if online)
- Offline → online transition (watched by the connectivity provider)
- After every local mutation (immediate push when online)
- Pull-to-refresh (`controller.refresh()`)

**Real-time integration.** When online, the sync service subscribes to Supabase's `.stream()` for the `todos` table. Incoming row sets are written into the local DB via the same LWW upsert that the manual sync uses. The UI is watching the local DB, so server pushes appear in the UI within milliseconds.

**Sign-out wipes the local DB.** `app.dart` listens to `currentUserStream` and calls `AppDatabase.clear()` on the authenticated → unauthenticated transition. This prevents user B on the same device from seeing user A's cached todos.

## Known limitations (deliberate, easy to fix later)

**Delete propagation via real-time is imperfect.** Supabase's `.stream()` builder emits the full current row set on every change; when a row is deleted server-side, the new set omits it. The LWW upsert doesn't currently delete local rows missing from the new set (because they might be local-only creates that haven't synced yet). Workarounds: pull-to-refresh, or switch to per-event channels (`.channel().onPostgresChanges(event: DELETE)`) for explicit delete events.

**No squashing of pending ops.** Toggling a todo three times quickly enqueues three ops. The sync service replays all three in order. A more sophisticated queue would coalesce ops on the same entity. Easy to add to `PendingOperationsDataSource`.

**Permanently-failing pending ops aren't escalated.** `attempts` and `lastError` are recorded but the sync service doesn't have a max-retries policy. A real product would surface ops with `attempts > N` to the user.

## Two transports for Todos

**Default (CRUD).** Screens consume `todosControllerProvider` (a `StreamNotifier<List<Todo>>`). Stream comes from the local DB; mutations go through the repo. This is what `TodosScreen` uses.

**Opt-in (raw stream).** `todosStreamProvider` is the same stream without the controller layer — useful when you just want a read-only view with no mutation surface.

Both are backed by the same local DB stream. The "real-time" feel comes from the sync service mirroring Supabase real-time pushes into local, not from the UI subscribing to a websocket directly.

## Testing

```bash
flutter test
```

Tests:
- `verify_email_otp_test.dart` — pure use case test
- `auth_controller_test.dart` — Notifier test with provider overrides
- `add_todo_test.dart` — business rule validation

For full coverage you'd add: a SyncService test (mock the data sources, push a pending op, assert it gets replayed), and a TodosRepositoryImpl test (mock the local + remote + sync, assert an offline add writes local + enqueues op + tries to sync).

## Conventions

**Domain is pure Dart.** No Supabase, no drift, no Flutter. The `Todo` entity has an `updatedAt` field because last-modification is a real business attribute the UI may surface, not because sync needs it (though it does use it).

**Exceptions never cross the Domain boundary.** Data sources throw `AuthException` / `PostgrestException` / drift exceptions. Repository impls catch them and return `Left(Failure)`.

**Reads stream from local. Writes write-through to local then enqueue.** This is the offline-first contract; once you've internalized it, every feature you add follows the same pattern.

**Providers form a DAG, not a cycle.** Data source providers live in their own file so both `sync_provider` and `todos_providers` can depend on them without cycling.

## Riverpod 3.x notes

The unified `Ref` type; every provider uses `(Ref ref)`. Long-lived deps get `@Riverpod(keepAlive: true)`. The `AppDatabase`, `SupabaseClient`, data sources, repository, and sync service are all keepAlive. Use cases and controllers autodispose.

## What's deliberately omitted

- **Schema migrations** — drift has migration tooling, but the schema here is v1.
- **Background sync (workmanager / android jobs)** — sync only runs while the app is in the foreground. Adding background sync is a separate concern that doesn't change the architecture.
- **End-to-end encryption** — Supabase TLS + Vault is sufficient for most apps; client-side E2EE would add a crypto layer above the data sources.

## Version audit (v0.4.0)

All package versions pinned to current stable releases as of May 2026. Pre-release pins (riverpod_annotation ^4.0.3-dev.*, riverpod_generator ^4.0.4-dev.*) have been dropped in favor of stable (4.0.2 / 4.0.3 respectively). Significant upgrades from earlier project iterations: drift 2.20.3 → 2.32.1, supabase_flutter 2.8 → 2.12.4, go_router 14.6 → 16.2, google_sign_in 7.1 → 7.2. `GoogleSignIn.instance.initialize(...)` is now called once at boot in `main.dart` (per the google_sign_in v7 docs) rather than per sign-in — a bug from the initial Supabase integration. Freezed 3.x lets you write classes either `class X with _$X` or `abstract class X with _$X`; this project standardizes on `abstract class` for consistency.
