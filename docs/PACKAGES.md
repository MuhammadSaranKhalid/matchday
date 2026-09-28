# Packages — Curated Recommendations

Companion to `CLAUDE.md`, `BEST_PRACTICES.md`, and `README.md`. Documents which packages belong in this stack and why, with explicit "avoid" calls so future agents don't reach for stale or wrong-fit choices.

Organized into four tiers:

1. **Currently in pubspec.yaml** — the chosen stack and why each earns its place
2. **Recommended for the foundation** — packages to add now (apply across all products)
3. **Per-product additions** — packages to add when a specific product needs them
4. **Avoid / replace** — what NOT to use even when tutorials recommend it

All versions listed are current stable as of the latest audit. Run the `version-auditor` subagent to refresh.

---

## Tier 1 — Currently in pubspec.yaml

### State management & DI

**`flutter_riverpod ^3.3.1`** + **`riverpod_annotation ^4.0.2`** + **`riverpod_generator ^4.0.3`** + **`riverpod_lint ^3.3.1`** + **`custom_lint ^0.6.7`**

The Riverpod ecosystem. Runtime is 3.x, codegen tooling is 4.x — intentional split, do not "fix." Codegen gives correct `Ref` typing, family parameter handling, and proper provider declarations without ceremony. The lint plugin catches the most common mistakes statically.

### Backend

**`supabase_flutter ^2.12.4`**

Postgres + Auth + Storage + Realtime + Edge Functions in one SDK. Built-in PKCE auth flow, RLS for client-safe access, real-time via WebSocket. Open-source, self-hostable. The architectural pattern in this project keeps Supabase isolated to the Data layer — swapping to a different backend would touch only `data/datasources/`.

### Auth (Google)

**`google_sign_in ^7.2.0`**

Native sign-in via Google's platform SDKs (Android One Tap, iOS system sheet). Returns ID token, which Supabase exchanges via `signInWithIdToken`. v7 API uses `GoogleSignIn.instance.authenticate()` — NOT the deprecated `signIn()` from v6. Initialize ONCE at app boot in `main.dart`.

### Local database

**`drift ^2.32.1`** + **`drift_flutter ^0.2.4`** + **`drift_dev ^2.32.1`** + **`sqlite3_flutter_libs ^0.5.26`** + **`path_provider ^2.1.5`**

SQLite + type-safe codegen. Reactive streams via `.watch()` (drives offline-first UI). Strong migration tooling. Active maintainer. Best-in-class relational option for Flutter today. Encryption available by swapping `sqlite3_flutter_libs` for `sqlcipher_flutter_libs` when needed.

### Routing

**`go_router ^16.2.0`**

Flutter's official routing solution. Deep link support, auth-aware redirects via `redirect:` callback, nested routes via `ShellRoute`. No good reason to use anything else.

### Connectivity

**`connectivity_plus ^6.1.0`**

Stream-based online/offline detection. Drives sync triggers in `lib/core/sync/sync_provider.dart`. Cross-platform, Google-maintained.

### IDs

**`uuid ^4.5.1`**

UUID v4 generation for client-side IDs. Critical for offline-first features — the same ID must survive offline → sync transition.

### Models & serialization

**`freezed_annotation ^3.0.0`** + **`freezed ^3.2.5`** + **`json_annotation ^4.9.0`** + **`json_serializable ^6.8.0`**

DTOs and sealed unions. Freezed 3.x permits `class X with _$X` and `abstract class X with _$X` — this project standardizes on `abstract class`. NOT used for domain entities (entities are pure Dart) or value objects (private constructor + factory pattern).

### Functional error handling

**`fpdart ^1.1.0`**

`Either<Failure, T>` for use case and repository return types. Pattern-match with Dart 3 `switch`, NOT `.fold` (except inside Domain transformations). Resist functional maximalism — Dart 3 features are usually clearer.

### Codegen

**`build_runner ^2.4.13`**

Drives `riverpod_generator`, `freezed`, `json_serializable`, `drift_dev`. Use `dart run build_runner watch --delete-conflicting-outputs` during development for sub-second feedback.

### Lints & testing

**`flutter_lints ^5.0.0`** + **`mocktail ^1.0.4`**

Mocktail (not mockito) — no codegen required, simpler API, better Dart 3 ergonomics.

---

## Tier 2 — Recommended for the foundation

Packages every product built on this foundation should have. Add them once, configure for the agency's standard practices, inherit across products.

### Observability

**`sentry_flutter ^9.x`** — Error tracking + performance monitoring + structured logging + feature flags. Free tier covers most apps under 5k MAU; paid tiers are reasonable. Use this OR Firebase Crashlytics, not both — Sentry is more flexible (works without Firebase setup) and offers better Flutter-specific instrumentation.

Setup pattern:
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 0.2; // 20% of transactions
    options.profilesSampleRate = 0.2;
    options.environment = const String.fromEnvironment('FLAVOR');
  },
  appRunner: () => runApp(const ProviderScope(child: NovexApp())),
);
```

Wrap the existing `runApp` call. Use `Sentry.captureException(e, stackTrace: st)` in repository fall-through `catch(e)` blocks instead of swallowing them.

### Logging

**`talker ^4.x`** + **`talker_flutter ^4.x`**

Structured logging with screen-overlay debug console (perfect for QA), built-in Riverpod observer, Supabase/Dio logging adapters. The console UI is invaluable during development — tap the floating widget to see all logs, network calls, exceptions in one place.

Forwarder pattern routes logs to Sentry in release:
```dart
class _SentryTalkerObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    Sentry.captureException(err.error, stackTrace: err.stackTrace);
    super.onError(err);
  }
}
```

Better than `package:logger` because of the UI overlay and platform-specific integrations.

### Secure storage

**`flutter_secure_storage ^9.x`**

iOS Keychain + Android Keystore wrapper. Use for: tokens that need separate storage from Supabase's session (rare — Supabase already uses secure-by-default storage), encryption passphrases (for SQLCipher), third-party API keys at rest, sensitive user-provided strings.

NOT a database. Small values only. Use alongside drift, not instead of it.

### Build environment

**`flutter_dotenv ^5.x`** OR **`envied ^1.x`** (pick one)

- **flutter_dotenv** — runtime .env file loading. Simpler. Values are strings; you parse them yourself. Less safe (a debugger or reverse-engineer can extract values from the asset bundle).
- **envied** — codegen-based, `--dart-define` integration, supports obfuscation. Safer. Slightly more setup.

Recommendation: **envied** for the foundation. Use `--dart-define` for build-time secrets (Supabase URL, anon key, Sentry DSN, Google client IDs) and let envied generate type-safe accessors. Avoids the runtime parsing footgun and the "I forgot to .gitignore .env" disaster.

### Internationalization

**`intl ^0.20.x`** + Flutter's built-in `flutter_localizations`

Even if your first product is English-only, set up i18n scaffolding from day one — retrofitting strings is painful. Use `.arb` files + `gen_l10n` (built into Flutter, no extra package). The `intl` package handles plurals, dates, numbers.

Add to `pubspec.yaml`:
```yaml
flutter:
  generate: true
```
And create `l10n.yaml` at project root.

### Image caching

**`cached_network_image ^3.x`**

The standard for network images. Memory + disk caching, placeholder + error widgets, progress callbacks. Has wide adoption and is stable; v4 has been "in development" for years — v3 is what production apps run.

---

## Tier 3 — Per-product additions

Packages that depend on what the specific product does. Add to per-product `pubspec.yaml`, not to the foundation.

### When the product needs forms

**`reactive_forms ^17.x`** — declarative reactive forms with validators, async validators, cross-field validation. Pairs well with value objects: the form-level validator calls `Email.create(input)` and surfaces the `Left(ValidationFailure)`. Better than vanilla `TextEditingController` + `setState` for forms with more than ~3 fields.

Alternative: **`flutter_form_builder ^9.x`** + **`form_builder_validators ^11.x`** — less reactive, more widget-style. Pick one; don't mix.

### When the product needs analytics

**Firebase Analytics** (via `firebase_analytics ^11.x`) OR **PostHog** (via `posthog_flutter ^4.x`)

- Firebase if you're already on Firebase for other reasons
- PostHog if you want product-analytics features (funnels, retention, session replay) without Firebase

Don't add both. Don't write a generic "analytics abstraction" until you've actually swapped providers once.

### When the product handles files / media

- **`image_picker ^1.x`** — picking photos/videos from gallery or camera
- **`file_picker ^8.x`** — picking arbitrary files
- **`flutter_image_compress ^2.x`** — client-side image compression before upload
- **Supabase Storage** (built into `supabase_flutter`) — for uploads
- **`mime ^2.x`** — MIME type detection

### When the product needs push notifications

- **`firebase_messaging ^15.x`** — FCM for cross-platform push (default choice)
- **`flutter_local_notifications ^18.x`** — for showing local-only notifications

Combine: FCM delivers the payload, local_notifications renders it on Android (FCM's auto-display on Android has limitations).

### When the product needs maps

- **`google_maps_flutter ^2.x`** — Google Maps SDK
- **`mapbox_maps_flutter ^2.x`** — Mapbox alternative

For non-map geo (geocoding, routing), check OpenStreetMap-based packages first — they're often free where Google charges.

### When the product needs charts

- **`fl_chart ^0.69.x`** — most popular, actively maintained, supports line/bar/pie/radar/scatter
- **`syncfusion_flutter_charts`** — commercial-grade (free for revenue under $1M/year), much more chart types

### When the product needs payments

- **`pay ^3.x`** — Google Pay / Apple Pay UI
- **`stripe_payment` / `flutter_stripe ^11.x`** — Stripe integration
- Server-side: Edge Functions in Supabase to talk to Stripe API (never the secret key on the client)

### When the product needs biometric auth

- **`local_auth ^2.x`** — Face ID / Touch ID / Android biometric

Pair with `flutter_secure_storage` for biometric-gated secret access.

### When the product needs deep links beyond OAuth callbacks

- **`app_links ^6.x`** — universal link handling (replaces older `uni_links`)
- **`url_launcher ^6.x`** — outbound links

### When the product needs in-app purchases

- **`in_app_purchase ^3.x`** — official Flutter team package
- **`purchases_flutter ^8.x`** (RevenueCat) — much easier developer experience, cross-platform abstractions

RevenueCat is worth its cost for any product with subscriptions.

### When the product needs ML / AI

- **`google_mlkit_*`** — on-device ML (text recognition, face detection, barcode, etc.)
- **`tflite_flutter ^0.11.x`** — TensorFlow Lite for custom models
- Cloud LLM calls → Edge Functions in Supabase (not direct from client)

### When the product needs WebView

- **`webview_flutter ^4.x`** — official Flutter team package
- **`flutter_inappwebview ^6.x`** — much richer API (JS bridges, cookies, downloads)

---

## Tier 4 — Avoid / replace

Packages that show up in tutorials but should NOT be in your stack.

### State management alternatives — don't add a second one

- **`provider`** — predecessor to Riverpod. Don't mix with Riverpod. Tutorials still show `Provider.of(context)` syntax; this is NOT Riverpod.
- **`flutter_bloc`** — capable but redundant with Riverpod. Pick one state management library; "BLoC for state, Riverpod for DI" is two libraries doing similar work.
- **`get` (GetX)** — combines state, DI, routing, and a dozen other things. Anti-pattern: encourages tight coupling between UI and logic. Avoid.
- **`mobx`** — works fine but the ecosystem has consolidated around Riverpod; you'll find fewer examples and answers.

### DI alternatives — Riverpod IS your DI

- **`get_it`** — service locator. Don't add it. Riverpod's providers do this with type safety and lifecycle management.
- **`injectable`** — codegen DI for `get_it`. Same reason.
- **`kiwi`** — same reason.

### Local DB alternatives — drift wins

- **`isar`** (original, maintainer-abandoned) — AVOID. Migrate to `isar_community` (v3 bug-fix mode) or `isar_plus` (v4 fork) only if you've already committed; for new code, use drift.
- **`hive`** (original, in maintenance mode) — AVOID for primary database. Use `hive_ce` only if you have a specific case for an embedded NoSQL key-value store.
- **`sqflite`** — bare SQLite without codegen. You'd reinvent drift.
- **`objectbox`** — proprietary core. Marginal at best for Supabase-shaped data.
- **`realm`** — vendor-locked to MongoDB Atlas. Wrong backend.
- **`sembast`** — pure-Dart NoSQL document store. Niche use case (very small apps that don't want native deps).

### Network HTTP — Supabase covers it

- **`dio`** — full HTTP client. Add ONLY if the product has REST endpoints outside Supabase (third-party APIs). Not for talking to Supabase.
- **`chopper`** — Retrofit-style codegen HTTP. Same.
- **`http` (Dart's official)** — useful occasionally for simple GET; not for production REST.

If you do need an HTTP client, prefer `dio` for interceptors (auth headers, logging, retry, error mapping). Pair with `talker_dio_logger` for instrumentation.

### Equality / immutability

- **`equatable`** — pre-Dart 3 helper. Manual `==`/`hashCode` is now idiomatic. Don't add equatable; entities in this project don't use it.
- **`built_value`** — older immutability codegen. Freezed has won; don't add both.

### Routing alternatives

- **`auto_route ^9.x`** — typed routes via codegen, declarative. Competitive with go_router. Pick go_router unless you have a strong reason — it's Flutter's official direction.
- **`fluro`** — older, less actively maintained.

### Date / time

- **`jiffy ^6.x`** — moment.js-style API. Add only if your team strongly prefers that style; `intl` + Dart's `DateTime` handles most cases.
- **`time ^2.x`** — sugar like `5.minutes.fromNow`. Add only if you write a lot of date arithmetic.

### Animations / UI helpers

- **`flutter_hooks`** — React-style hooks. Works with Riverpod (`hooks_riverpod`), but adds a mental model and dependency. Skip unless the team already uses it.
- **`animations`** (Flutter team) — material motion. Add per-product when needed.
- **`shimmer`** — loading placeholders. Per-product.

### Anything that wraps `print`

The Dart `print` function is fine for development logs. For production, use `talker` (Tier 2 recommendation). Avoid:
- **`logger`** — fine but lacks the UI overlay and ecosystem
- **`logging`** — Google's official package; minimal, no Flutter-specific features

---

## Recommended `pubspec.yaml` template — full stack

For a NEW product built on this foundation, copy the project's `pubspec.yaml` and add the Tier 2 packages. Final shape:

```yaml
name: <your_product>
description: <description>
publish_to: "none"
version: 0.1.0+1

environment:
  sdk: ^3.7.0
  flutter: ">=3.27.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # --- Foundation (from this template) ---
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  supabase_flutter: ^2.12.4
  google_sign_in: ^7.2.0
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

  # --- Tier 2: production essentials ---
  sentry_flutter: ^9.0.0           # error tracking + perf monitoring
  talker_flutter: ^4.0.0           # structured logging + dev overlay
  flutter_secure_storage: ^9.0.0   # encrypted small values
  envied: ^1.0.0                   # type-safe env vars
  intl: ^0.20.0                    # i18n
  cached_network_image: ^3.4.0     # image caching

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner: ^2.4.13
  riverpod_generator: ^4.0.3
  freezed: ^3.2.5
  json_serializable: ^6.8.0
  drift_dev: ^2.32.1
  envied_generator: ^1.0.0

  riverpod_lint: ^3.3.1
  custom_lint: ^0.6.7
  flutter_lints: ^5.0.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  generate: true        # enables gen_l10n for i18n
```

---

## Decision criteria — when adding a new package

Before adding any package to `pubspec.yaml`, verify:

1. **Active maintenance**: last release within ~6 months. Check pub.dev → "Versions" tab. If the latest is older than a year and the package isn't trivially small, it's a maintenance risk.
2. **Pub.dev score above 130** (out of 160). Lower scores indicate missing docs, examples, or platform support.
3. **Likes / popularity reasonable**: not absolute but a signal. <100 likes for a package that should be common is a yellow flag.
4. **No known forks** competing for maintenance attention (Isar's situation — original abandoned, two community forks splitting users).
5. **Compatible with current Dart / Flutter SDK constraints**.
6. **No license restrictions** that conflict with commercial use. Check the LICENSE — MIT, BSD, Apache 2.0 are fine. GPL is a problem.
7. **Doesn't duplicate existing functionality** in the stack. Adding `get_it` when you have Riverpod, adding `equatable` when you have manual `==`, etc.

When in doubt: ask the `version-auditor` subagent. It knows the current state of every package in this list.

---

## Updating this document

This list grows as the agency takes on more products with different needs. When you add a package to a real product:

1. Decide which tier it belongs in:
   - Used in 2+ products → bump to Tier 2 (foundation)
   - Specific to one product → stays in Tier 3
2. Add it to the right section with a one-line "why this and not alternatives" rationale.
3. If you considered alternatives and rejected them, add to Tier 4 with the reasoning.

The document only stays useful if it reflects actual practice. Stale recommendations are worse than no recommendations.
