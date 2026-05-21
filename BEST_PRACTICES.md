# Best Practices — Clean Architecture & Packages

Companion to `CLAUDE.md` (which defines *what* the architecture is) and `README.md` (which onboards humans). This document covers *how to work within the architecture well* — the disciplines and habits that keep the stack healthy as the codebase grows.

Organized by concern: architecture, then each major package, then cross-cutting workflow. Each item is one practice with a brief rationale.

---

## 1. Clean Architecture Discipline

**1.1 Apply the dependency rule on every PR.** Domain imports nothing from Data or Presentation. Data imports from Domain, never the other way. Presentation imports from Domain (entities, value objects, use cases) and from its own feature's Data only via providers — never directly from another feature's Data. If a new import would violate this, the design is wrong.

**1.2 Resist the urge to skip the use case "for trivial calls."** Even a use case that just delegates to a repository method has value: it's the contract for "what business operations exist." When a business rule is added later, it has a home. When usage analytics get added, you instrument one file. When permissions get enforced, the check goes there. Skipping the layer to save five lines costs you those affordances forever.

**1.3 One verb per use case.** `AddTodo`, not `TodoUseCases.add()`. Grouping verbs into a class encourages the class to grow into a service object, which encourages controllers to depend on the whole thing, which couples controllers to use cases they don't use. One file per verb keeps the dependency graph honest.

**1.4 Wrap any string with rules in a value object.** Email format, phone format, URL shape, OTP length, slug pattern, color hex, money amounts, percentages, dates with semantic constraints (must be in the future, must be a weekday) — all of these get a value object. The discipline pays off the third time you'd otherwise repeat the validation inline.

**1.5 DTOs never escape `data/`.** If a use case returns a DTO, the layer boundary leaked. If a controller imports a DTO, the layer boundary leaked. The mapper is `dto.toEntity()` and it's called in the repository.

**1.6 Repositories are the only place exceptions become Failures.** No `try/catch` in Domain. No `try/catch` in Presentation around use-case calls. If you find a `try/catch` outside a repository, it's a code smell — usually the data source is throwing something the repository didn't expect to handle, and the right fix is to add that exception type to the data source's `throw` set and the repository's `catch` chain.

**1.7 Don't add a layer to abstract a single concrete thing.** Clean Architecture is not "more layers is better." If a feature has one data source, no offline support, no real-time, no special caching — its repository implementation can be very thin. That's fine. Adding a "service" layer above the repository "in case we add more sources later" makes the codebase harder to read without buying anything until the second source actually exists.

**1.8 Cross-feature dependencies go through Domain.** If feature A needs to read from feature B, it imports B's domain entities and a B-feature use case via providers. It does NOT import B's data sources, B's controllers, or B's screens.

---

## 2. Riverpod 3.x

**2.1 Codegen only — no manual providers.** Every provider is declared with `@riverpod` or `@Riverpod(keepAlive: true)`. The manual constructors (`Provider`, `StateNotifierProvider`, `FutureProvider`) still exist but are legacy. Codegen gives you correct type inference, family parameter handling, and proper `Ref` typing without ceremony.

**2.2 Default to autodispose; use `keepAlive: true` deliberately.** Use cases and controllers are bare `@riverpod` (autodispose) so they tear down when no UI is listening. Long-lived dependencies — `SupabaseClient`, `AppDatabase`, data sources, repositories, `SyncService` — get `@Riverpod(keepAlive: true)`. The rule of thumb: anything that holds a connection, a stream subscription, or expensive state goes `keepAlive`; everything else doesn't.

**2.3 `ref.watch` in `build`, `ref.read` in handlers, `ref.listen` for side effects.** This is the single most common Riverpod mistake. Internalize it:
  - Inside a widget's `build()` or a controller's `build()` → `ref.watch(provider)` (subscribes, rebuilds on change)
  - Inside `onPressed`, `onChanged`, or any callback → `ref.read(provider)` (one-shot read, no subscription)
  - When you want navigation, snackbars, or dialogs as a *consequence* of state change without causing a rebuild → `ref.listen(provider, callback)`

**2.4 The provider's lifecycle is the dependency's lifecycle.** When the provider is disposed, its `ref.onDispose(...)` callbacks run. Stream subscriptions, timers, controllers — register their disposal in `onDispose`, not in widget `dispose` methods. This makes the disposal logic colocated with the resource.

**2.5 Refresh via `ref.invalidateSelf()`, not by setting state.** In an `AsyncNotifier`, when the user pulls to refresh, call `ref.invalidateSelf()` (then `await future` if you need to know when it's done). This re-runs `build()` cleanly, including disposal of the old state. Manually setting `state = AsyncLoading()` is a workaround for missing knowledge of this method.

**2.6 Stream providers expose `AsyncValue<T>`, not `T`.** When you `ref.watch(someStreamProvider)`, the value is `AsyncValue<T>` — loading, error, or data. Pattern-match it with Dart 3 `switch`:
```dart
final state = ref.watch(todosControllerProvider);
return switch (state) {
  AsyncData(:final value) => _List(value),
  AsyncError(:final error) => _Error(error.toString()),
  _ => const Center(child: CircularProgressIndicator()),
};
```
Don't use the legacy `.when` / `.map` extensions — they predate Dart 3 patterns.

**2.7 Provider DI graph is acyclic. Hard rule.** If two providers depend on each other, split one into a "providers-only" file (see the `todos_datasource_providers.dart` split in this codebase for the canonical fix). Forward declarations and `late final` workarounds are not architectural solutions; they're warnings that the graph is broken.

**2.8 Test with `ProviderContainer.test()`.** This is the Riverpod 3.x test API — it disposes correctly, handles overrides predictably, and is the only path that works with codegen. Add `addTearDown(container.dispose)` every time. Override with `provider.overrideWithValue(mockInstance)` for plain providers; use `provider.overrideWith((ref) => mockNotifier)` for Notifiers.

**2.9 Don't subscribe to streams inside widgets.** Wrap every `Stream<T>` in a stream provider so subscription lifetime is managed and tested. `StreamBuilder` directly in a widget tree bypasses the provider system and creates subscription-leak risk on widget rebuild.

**2.10 Run `riverpod_lint` and treat its warnings as errors.** It catches misuses statically — wrong `ref` usage, missing `ref.watch`, etc. Configure `analysis_options.yaml` to treat its findings as errors so CI fails on them.

---

## 3. Supabase

**3.1 RLS on every user-owned table. Always. No exceptions.** A row without RLS is a row that any authenticated client can read. The convention is `using (auth.uid() = user_id) with check (auth.uid() = user_id)` — but the policy must exist. Never disable RLS "temporarily for testing" on a deployed project; create a service-role client for admin operations instead.

**3.2 Use PKCE auth flow, not implicit.** PKCE (Proof Key for Code Exchange) is the v2 default and is mandatory for mobile-grade security. The codebase initializes Supabase with `authFlowType: AuthFlowType.pkce` — don't change it to `implicit` to "make deep links easier." Make the deep links work correctly instead.

**3.3 Postgres functions for atomic multi-row operations.** When a single user action requires updating multiple rows or tables together (transfer money between accounts, accept an invite which both deletes the invite and creates a membership), write a Postgres function and call it via `supabase.rpc('function_name', params: {...})`. Doing it as separate REST calls from the client opens you to partial-failure states.

**3.4 Real-time subscriptions are state, not events.** When you subscribe to `supabase.from('table').stream(primaryKey: ['id'])`, you get a `Stream<List<Row>>` that emits the full current state of the matching rows each time anything changes. It is not an event log — you can't "miss" a row that was deleted because the next emission won't include it. Build UIs around the current-state model, not event handlers.

**3.5 Real-time has limits — design within them.** Supabase's default plan caps concurrent real-time connections and message rate. For an app with thousands of concurrent users on the free tier, scoped real-time channels (per-user, per-conversation, per-document) will hit limits before global table subscriptions do. Design real-time access as narrowly as possible.

**3.6 Store `updated_at` server-side via a trigger, never client-side.** The client clock is unreliable for LWW. Every synced table gets a `BEFORE UPDATE` trigger that sets `updated_at = now()`. The client passes `created_at` (for the initial insert) but never sets `updated_at` after.

**3.7 Use deep link callbacks that match your bundle ID exactly.** Misconfigured `redirectTo` URLs are the #1 cause of "OAuth seemed to work but the user never came back to the app." Follow the format `<reverse-domain-scheme>://<host>/<path>` (e.g. `studio.novex.app://login-callback`) and register the scheme in both Supabase Dashboard (Auth → URL Configuration) and iOS Info.plist / Android intent-filter.

**3.8 Idempotent `Supabase.initialize()`.** Recent supabase_flutter versions made `initialize()` idempotent. Don't rely on this in tests by calling it many times — call it once at app boot and structure tests to use mocked SupabaseClient instead.

**3.9 Use the new publishable/secret key format if starting fresh.** As of 2026, Supabase has rolled out `sb_publishable_*` / `sb_secret_*` keys, replacing the older anon/service_role. Old keys still work through 2026 but new projects should use the new format. The dart-define name in this codebase is `SUPABASE_ANON_KEY` — when you upgrade, rename to `SUPABASE_PUBLISHABLE_KEY` for clarity.

**3.10 Never put `service_role` / secret keys in the client.** Ever. They bypass RLS. Anything that needs admin-level access goes in an Edge Function or your own backend; the client only ever sees publishable/anon keys.

---

## 4. Drift (Local SQLite)

**4.1 Bump `schemaVersion` AND write the migration, every schema change.** Adding a column, adding a table, renaming a column — each is a schema change that requires `schemaVersion++` and a step in `onUpgrade`. Forgetting either breaks app upgrades silently (existing users get crashes; fresh installs work). Test migrations by manually downgrading an install.

**4.2 Companion objects, not raw insert maps.** `TodosCompanion.insert(...)` gives you compile-time checking of required vs optional fields. Raw `insert({'id': ..., 'title': ...})` doesn't. Use companions always.

**4.3 Transactions for multi-row operations.** `db.transaction(() async { ... })` wraps multiple writes in one atomic unit. Use it whenever a single user action touches multiple rows or multiple tables. Don't rely on individual statement atomicity to protect invariants.

**4.4 Streams for UI; futures for one-shots.** `select(table).watch()` returns a `Stream<List<Row>>` that re-emits whenever the underlying data changes. This is what powers reactive UIs. `select(table).get()` returns a `Future<List<Row>>` for one-shot reads (in tests, in sync logic, in non-UI contexts).

**4.5 Index every column you `WHERE`, `ORDER BY`, or `JOIN` on.** SQLite without indexes does full table scans. With a few thousand rows you won't notice; with a few hundred thousand the UI will stutter. Add indexes proactively to the table definition:
```dart
@DataClassName('LocalTodo')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  // ...
  @override
  List<Set<Column>> get uniqueKeys => [{id}];
  // Add indexes for foreign keys and order columns:
  // (drift supports `customIndex` and `Indexes` annotations)
}
```

**4.6 IDs are generated in the repository, not the database.** This codebase passes client-generated UUIDs (`Uuid().v4()`) from the repository into both local writes and remote pushes. Auto-increment local IDs that differ from the server's IDs create reconciliation nightmares. UUID-first means the offline-created row's ID survives the sync.

**4.7 LWW is manual.** `insertOnConflictUpdate` does NOT compare `updated_at` — it always overwrites on conflict. If you need LWW (last-write-wins by timestamp), implement it explicitly: for each incoming row, check the local `updated_at`, skip if local is newer, upsert otherwise. The codebase's `TodosLocalDataSource.upsertManyLww` is the canonical pattern.

**4.8 Don't expose drift row types past the data source.** The local data source's job is to wrap drift's generated classes (`LocalTodo`) and return Domain entities (`Todo`). The repository sees only entities. This keeps the rest of the codebase oblivious to drift, so swapping local storage stays a one-file change.

**4.9 Encryption when needed.** If a future product handles PII, health data, or financial records, swap `sqlite3_flutter_libs` for `sqlcipher_flutter_libs` and pass a passphrase to `NativeDatabase`. The drift API stays identical. Source the passphrase from `flutter_secure_storage` so it's not derivable from the binary.

**4.10 Don't `close()` the database in widget `dispose`.** The database is a `keepAlive` provider — its lifecycle is the app's. Closing it on widget dispose breaks every other widget. If you genuinely need to close it (sign-out flow that wipes data, then re-opens fresh), do it from a controller after `AppDatabase.clear()` and re-open via the provider.

---

## 5. Freezed 3.x

**5.1 DTOs and complex form state get Freezed. Entities and value objects do not.** Freezed for Data layer types (DTOs need JSON, equality, copyWith). Manual classes for Domain entities (keeps Domain free of `package:freezed_annotation`) and value objects (private constructor + factory create is the pattern).

**5.2 Add `const ClassName._()` the moment you add a custom method.** Without the private constructor, your `toEntity()` method exists but the analyzer can't see it. Add it eagerly even if the DTO has no methods yet — you'll add one eventually.

**5.3 Use `@JsonKey(name: 'snake_case')` at the field level.** Not at the class level via a global `fieldRename` setting. Per-field annotations are explicit and survive future refactors better.

**5.4 Sealed unions for `Result`-like patterns.** Use `@freezed sealed class Result<T>` when you want pattern matching across distinct shapes (`ResultData(value)` vs `ResultError(failure)`). Don't reach for `Either` if the shape is application-specific; reach for `Either` (fpdart) when the shape is exactly success-or-failure and you want functional composition (`.fold`, `.map`).

**5.5 Don't use `.when` / `.map` extensions.** They're legacy. Dart 3 `switch` patterns with destructuring are cleaner, exhaustively checked, and don't require maintaining a position-based parameter contract:
```dart
final message = switch (state) {
  AuthAuthenticated(user: final u) => 'Hello, ${u.email}',
  AuthFailed(failure: final f) => f.message,
  _ => 'Loading...',
};
```

**5.6 `equatable` is unnecessary.** Freezed generates `==` / `hashCode`; entities use manual `==` / `hashCode`. There's no reason to add the `equatable` package to this stack.

---

## 6. fpdart / Either

**6.1 `Either<Failure, T>` is the standard return for use cases and repository methods.** This is the project convention; don't introduce alternatives like wrapping success in nullable types (`T?` with implicit error semantics) or throwing inside use cases.

**6.2 Pattern-match `Either` with `switch`, not `.fold` when in a controller.** Dart 3:
```dart
final result = await ref.read(addTodoUseCaseProvider).call(params);
switch (result) {
  case Left(value: final failure):
    state = TodosFailed(failure);
  case Right(value: final todo):
    // success path
}
```
Reserve `.fold` for transformations within Domain logic where you want to map both arms inline.

**6.3 Don't import fpdart into Presentation widget code.** Widgets work with controller state (sealed unions, `AsyncValue`). The `Either` lives at the use-case / controller boundary; the widget shouldn't know about it.

**6.4 `Option<T>` is for "intentionally absent" values, not for "potentially null."** Use `T?` for the latter (Dart's native nullable types). Reach for `Option<T>` only when you specifically want fpdart's combinators (`getOrElse`, `fold`, etc.) and the absence is semantically meaningful (not just an uninitialized value).

**6.5 Resist fpdart maximalism.** Dart 3's switch patterns, nullable types, and async/await are usually clearer than `TaskEither.tryCatch(...).chain(...).run()`. Use fpdart for the specific things it does well (`Either` for failure paths, `Option` for semantic absence). Don't rewrite Dart in a functional dialect.

---

## 7. google_sign_in v7

**7.1 Initialize once at app boot.** `GoogleSignIn.instance.initialize(...)` belongs in `main.dart` alongside `Supabase.initialize`. NOT inside `signInWithGoogle()`. This is the most common v7 mistake — the v6 API was different.

**7.2 `authenticate()` is the user-facing sign-in.** Not `signIn()` (that was v6). The v7 method opens the platform sign-in sheet. Check `supportsAuthenticate()` first if you target web — web requires a rendered button via `google_sign_in_web`.

**7.3 Scopes via `authorizationClient.authorizationForScopes(scopes) ?? authorizeScopes(scopes)`.** The first call returns the existing grant if any; the second prompts. Skipping the fallback breaks cold-install flow because `authorizationForScopes` returns null when no grant exists yet.

**7.4 Pass both `serverClientId` and `clientId`.** `serverClientId` (your Supabase project's Google OAuth web client ID) is required for the ID token Supabase needs. `clientId` is the iOS client ID; required on iOS, optional on Android (Android uses the SHA-1 fingerprint registered in Google Cloud Console).

**7.5 Handle `GoogleSignInException` distinctly.** User cancellation, no network, and OAuth misconfig are all `GoogleSignInException` with different `code` values. Map them to user-facing messages — "Sign-in cancelled" is different from "Network error" is different from "Configuration error, please contact support."

---

## 8. go_router

**8.1 Auth redirects via `redirect`, not via `refreshListenable` + manual checks.** The router's top-level `redirect: (context, state) { ... }` callback runs on every navigation. Check auth state there, return `'/sign-in'` if redirecting unauthenticated users, `'/home'` if redirecting authenticated users from auth screens, or `null` to continue.

**8.2 Make `redirect` a function of state, not side effects.** Pure decision logic in the redirect; never trigger navigation, snackbars, or other side effects from there. Side effects go in `ref.listen(currentUserStreamProvider, ...)` at the screen level.

**8.3 `refreshListenable` connects auth changes to the router.** When the user signs in or out, `router.refresh()` must be called so the redirect logic re-evaluates. This codebase wires it via `Listenable` adapters around the auth stream provider. If you change the auth state shape, verify the listenable still fires.

**8.4 Typed routes via `go_router_builder` are optional.** They add type safety to navigation calls (`HomeRoute().go(context)` instead of `context.go('/home')`) at the cost of an extra codegen step. Worth it for apps with many parameterized routes; overkill for simple route trees. This codebase uses string-based routing — fine for a foundation.

**8.5 `ShellRoute` for persistent UI shells (bottom nav, side menu).** Don't manually manage a single Scaffold with nested navigators — `StatefulShellRoute.indexedStack` handles it correctly with state preservation per branch.

---

## 9. Testing

**9.1 The test pyramid for this stack:**
  - **Use case tests** (~60% of test count): pure Dart, fastest, target business rules in `domain/usecases/`.
  - **Controller tests** (~25%): with provider overrides, target state transitions in `presentation/controllers/`.
  - **Repository tests** (~10%): with mocked data sources, target exception-to-Failure translation and (for offline-first) the "write local + enqueue + nudge sync" contract.
  - **Widget tests** (~5%): for screens with non-trivial layout logic or critical interactions. Don't widget-test every screen.
  - **Integration tests** (sparse): one happy-path E2E per critical user flow (sign-in, primary CRUD). Run in CI but not on every commit.

**9.2 Mock with mocktail, not mockito.** No codegen, simpler API, better Dart 3 ergonomics. `class _MockRepo extends Mock implements Repo {}` and you're done.

**9.3 Register fallback values once per file.** For any value type used in `any()` matchers, register a fallback in `setUpAll`. Skipping this causes confusing "missing stub" errors at runtime.

**9.4 Don't test generated code.** Freezed's `copyWith`, Riverpod's provider plumbing, json_serializable's serializers — these are tested by their respective packages. Write tests for your code, not theirs.

**9.5 Don't test Supabase or drift directly.** Mock the data source interfaces. There's no value in a test that verifies "drift writes to drift correctly" or "Supabase returns what we sent it" — those are integration concerns and they belong in a one-off integration test, not a unit test.

**9.6 Goldens for design system components, not for screens.** Screen layouts change frequently and break goldens constantly. Component-level golden tests (a single button, a single card) are durable and catch real visual regressions.

**9.7 `flutter test --coverage` then `genhtml` for readable reports.** Aim for ~70-80% coverage on Domain (use cases, value objects) and Data (repositories), lower on Presentation (controllers can be ~60%, screens often uncovered). Coverage targets are floors, not ceilings — chasing 100% drives tests that don't catch real bugs.

---

## 10. Security

**10.1 Secrets via `--dart-define`, not in code.** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` are passed at build time. Don't commit them; don't read them from `.env` files bundled into the app (that's the same as committing them). Build pipelines inject them at compile.

**10.2 Anon keys are not "secret."** They're public-by-design; their security comes from RLS. The "secret" thing in your Supabase project is the service-role key, which never leaves your backend. If you find yourself thinking "should I hide the anon key?", the answer is no — RLS is doing the work.

**10.3 `flutter_secure_storage` for actually-sensitive small values.** If a future product stores a passphrase, an API key for a third-party service, or anything else genuinely confidential at rest on the device, `flutter_secure_storage` (Keychain on iOS, Keystore on Android) is the answer. Not shared_preferences, not the database without SQLCipher.

**10.4 Verify deep links.** Anyone can register a URL scheme with the same name as yours on the same device (with effort). For OAuth callbacks, the security comes from PKCE — the auth code is bound to the device that started the flow. As long as you use PKCE (Supabase v2 default), an attacker intercepting the callback URL can't complete the exchange.

**10.5 Disable debug-mode-only features in release builds.** Test users, mock data, "skip auth" toggles, debug overlay — wrap them in `if (kDebugMode)` so they never ship to release. Better: gate them behind a build flavor (`--flavor debug` vs `--flavor production`).

**10.6 Audit your RLS policies the same way you'd audit a permissions matrix.** Write a checklist: for each table, can user A read user B's rows? Can user A insert with user B's user_id? Can a deleted user's rows still be read? Test each manually with two accounts before shipping a new feature.

**10.7 No PII in logs.** `print(user)` is fine in development; in production it's a data leak. Use a logger (`package:logging`) and configure release logging to strip user identifiers, emails, tokens, and request bodies.

---

## 11. Performance

**11.1 Profile before optimizing.** Flutter DevTools' Performance tab shows you what's actually slow. Optimizing imagined hotspots is wasted effort; the real ones are almost always not where you'd guess.

**11.2 `const` constructors aggressively.** Every widget that doesn't depend on runtime values should have a `const` constructor. The analyzer's `prefer_const_constructors` lint catches missed opportunities. `const` widgets are reused across rebuilds with no allocations.

**11.3 `ListView.builder` for any list past ~30 items.** `ListView(children: [...])` builds every child up front. `ListView.builder` builds only visible children. The rendering difference at 1000 items is night-and-day.

**11.4 Image caching matters.** Network images without caching reload on every rebuild. `cached_network_image` is the standard package. For local assets, Flutter caches automatically.

**11.5 Stream providers that fan out to many widgets: select.** `ref.watch(provider.select((s) => s.specificField))` rebuilds only when that field changes, not when the whole state object changes. This is the cheapest performance win in the Riverpod toolkit.

**11.6 Database operations off the UI isolate for large data.** Drift can run in a background isolate (`driftDatabase(name: ..., isolate: true)`). For most apps the main isolate is fine; for apps doing bulk imports or large queries (10k+ rows), the isolate split keeps the UI thread free.

**11.7 Build modes matter for measurement.** Debug builds are 10x slower than release builds at rendering. Always profile in profile mode (`flutter run --profile`) — debug numbers are meaningless and release builds disable the profiler.

---

## 12. Workflow & Tooling

**12.1 `analysis_options.yaml` is the project's coding standard.** Enable `flutter_lints` as a base, add `riverpod_lint` and `custom_lint` for Riverpod-specific rules, then add strict additions (`prefer_relative_imports`, `require_trailing_commas`, `avoid_print`) to match team preferences. Treat lints as errors in CI.

**12.2 Generated files (`*.g.dart`, `*.freezed.dart`) are gitignored.** They're regenerated locally and in CI. Committing them creates merge conflicts on every codegen run and bloats the diff.

**12.3 `dart run build_runner watch` during development.** Saves you from running `build` manually after every model change. Closes the codegen loop to <1 second per save.

**12.4 Pre-commit hook: format + analyze.** A two-line hook (`dart format . --set-exit-if-changed && flutter analyze`) catches 90% of "should have caught this locally" PR comments. Use `lefthook` or git's built-in hooks.

**12.5 CI runs: pubspec resolves, codegen, format check, analyze, test, build.** Every PR. The build step (release build for the primary platform) catches dart-define issues and dependency conflicts that don't show up in `flutter test`.

**12.6 Dependency upgrades via `flutter pub upgrade --major-versions`, monthly.** Don't accumulate version drift. Major version bumps are easier to handle one-at-a-time than ten-at-once. Read changelogs; don't blindly accept upgrades.

**12.7 Lock the Flutter SDK version.** Use `fvm` (Flutter Version Management) or a `.tool-versions` file. Pin to a specific Flutter stable. Don't let team members or CI drift onto different Flutter versions — that's a debugging nightmare waiting to happen.

**12.8 Feature flags via a single source.** When you need to gate a feature behind a flag (A/B test, gradual rollout, internal-only), centralize the flag definitions in one file with typed accessors. Don't sprinkle `if (env == 'production')` checks across the codebase.

**12.9 Conventional commits.** `feat:`, `fix:`, `refactor:`, `chore:`, `docs:` — this convention makes changelogs auto-generatable and PR scope obvious. Enforce via commitlint if multiple humans contribute.

**12.10 Update CLAUDE.md when the architecture evolves.** When you add a pattern (a new failure type, a new value object validation style, a new sync handler interface), document it in CLAUDE.md the same PR. The document is only valuable if it stays current.

---

## 13. Anti-patterns to never adopt

Quick reference for things that *seem* reasonable but degrade the architecture:

- **A "services" folder for cross-cutting business logic.** This is where Clean Architecture goes to die. Use cases ARE the services — adding another layer above them creates duplication and confusion about where to put new logic.
- **Singleton instances of repositories or data sources.** Riverpod IS your DI; static `instance` accessors bypass it and break testability.
- **`Provider.of<Repository>(context)` style.** That's Provider package syntax, not Riverpod. Don't mix the two.
- **Domain entities with methods that call repositories.** "Active Record" pattern — entity calls back to its store. This couples Domain to Data; instead, the use case orchestrates.
- **Catching every exception type defensively.** Catching `Exception` or `Object` and re-throwing as `UnknownFailure` hides bugs. Only catch the specific exception types you know how to translate.
- **A "BLoC for state, Riverpod for DI" split.** Pick one. The codebase uses Riverpod for both, and that's the right call — two state-management libraries is a maintenance tax with no upside.
- **Custom widget base classes.** `MyAppWidget extends StatelessWidget` with shared behavior in the base class — sounds DRY, becomes inheritance hell. Use composition (helper functions, builder widgets) instead.
- **Premature generic abstraction.** A `BaseRepository<T>` with generic CRUD methods sounds elegant until the third feature needs a method that doesn't fit the generic shape. Concrete repositories per feature are simpler and more honest.

---

## 14. The single most important practice

When you don't know which way to jump, **optimize for the person reading the code six months from now**. They'll forget why a pattern was chosen, but they'll find your file by its name in the folder map, read it without context, and need to understand it.

Boring, consistent, predictable code wins. Cleverness loses. The architecture in this codebase is deliberately unsurprising — three layers, one verb per use case, one provider per dependency, one pattern per problem. Stay boring.
