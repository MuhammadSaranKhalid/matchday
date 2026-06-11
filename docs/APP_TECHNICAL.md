# matchday — Technical Handoff

> **Audience:** an engineer (human or Claude) joining the codebase cold.
> **Goal:** in one read, know what this app is, how it is wired, what is built, and where to look next.
> **Last audited from source:** 2026-06-11. Branch: `fix/location-capture-locality`. Main: `main`.

---

## 1. What this app is

**matchday** is a mobile-first cricket app for amateur clubs and tournaments. The product is a single Flutter binary (Android + iOS) backed by Supabase. The repository name (`novex_clean_arch`) is the foundation library the app is built on; the user-facing brand is **matchday** (warm-paper UI, single earned red accent, "Seam ball" mark).

In the current build a signed-in user can:

- Sign in by email OTP or native Google OAuth, complete a first-run onboarding wizard (display name, username, city/geo, optional player profile).
- Browse a five-tab shell — **Home (feed) · Matches · Pavilion (workspace) · Messages · You (profile)** — that supports swipe between tabs and keeps each tab's nav stack alive.
- Create and manage teams (roster, jersey numbers, captain, unclaimed players, logo upload).
- Send and respond to friendly **match challenges**, materialise an accepted challenge as a real match, and run the **toss → lineup → live → completed** lifecycle.
- Score a match ball-by-ball with a server-authoritative engine that advances the on-field trio, computes the result, and broadcasts every change.
- Compose and view **posts** (text + ≤4 photos, BlurHash placeholders, keyset-paginated feed) and follow other users.
- Run a real **messages** inbox (1-to-1 and team chats) with realtime delivery, unread counts, pagination, drafts, and a local read-through cache.
- Receive **push notifications** (FCM) for match-state changes, follows, comments, likes, challenges, and new messages.
- Share a profile by `joinmatchday.com/u/<username>` deep link.

What is intentionally **not** built yet, but has design or schema in place: likes/comments/bookmarks persistence (UI is mocked), drafts/scheduling on posts, tournament authoring UI, the second-innings → completion side of the scoring engine, team/tournament posts authoring, native asset-link verification files hosted on the domain.

---

## 2. Tech stack snapshot

Lock the mental model to these versions (verified in `pubspec.yaml`):

| Concern | Package | Version |
|---|---|---|
| Flutter SDK / Dart | `flutter` / `sdk` | `>=3.27.0` / `^3.7.0` |
| State / DI | `flutter_riverpod` | `^3.3.1` |
| Codegen for Riverpod | `riverpod_annotation` | `^4.0.2` (4.x line is intentional) |
| Backend SDK | `supabase_flutter` | `^2.12.4` |
| Native Google sign-in | `google_sign_in` | `^7.2.0` |
| Local DB (scoped use) | `drift` | `^2.31.0` (pinned — see §11) |
| Routing | `go_router` | `^16.2.0` |
| Functional error type | `fpdart` | `^1.1.0` |
| Sealed data models | `freezed_annotation` / `freezed` | `^3.0.0` / `^3.2.5` |
| Realtime / fetch helpers | (built into Supabase) | — |
| Push | `firebase_core` + `firebase_messaging` + `flutter_local_notifications` | `^4.10` / `^16.3` / `^18.0` |
| Photo pipeline | `image_picker` + `image_cropper` + `flutter_image_compress` + `blurhash_dart` + `image` + `flutter_blurhash` + `cached_network_image` + `photo_view` | see pubspec |
| Location | `geolocator`, custom `places_remote_datasource` (Google Places New) | `^14.0.2` |
| Misc UI | `flutter_svg`, `intl`, `timeago`, `cached_network_image`, `share_plus`, `equatable` | see pubspec |
| Tests | `mocktail` | `^1.0.4` |

**Lint note:** `riverpod_lint` + `custom_lint` are temporarily **off**. There is a three-way analyzer version conflict (Flutter 3.41 `meta` pin caps analyzer `<10.0.2`, `drift_dev 2.32+` needs `analyzer >=10`, `riverpod_lint <=3.1.3` needs `analyzer ^9`). The architecture rules are enforced by review + the `architecture-reviewer` agent, not by lint. Re-enable when `riverpod_lint` ships analyzer-10 support.

---

## 3. Architectural rules (non-negotiable)

The project is a strict Clean Architecture stack. The full rules live in `CLAUDE.md` (read it once); the load-bearing ones are:

1. **Domain is pure Dart.** No Flutter, Riverpod, Supabase, drift, http, or platform imports in `lib/features/*/domain/` or `lib/core/error/`.
2. **Exceptions never cross the Domain boundary.** Data sources throw raw exceptions; repository implementations catch them once and translate to `Failure` subtypes returned in `Either<Failure, T>`. Above the repo: no `try/catch` around domain calls.
3. **DTOs are never Entities.** Every entity in `domain/entities/` has at least one DTO in `data/models/` with `toEntity()`. Renaming a Supabase column changes only the mapper.
4. **Value objects enforce invariants.** Any validated primitive (email, OTP code, username, city, message body, etc.) is a class in `domain/value_objects/` whose only constructor is `static Either<ValidationFailure, T> create(String input)`.
5. **Riverpod only in Presentation (and core providers).** Forbidden in `domain/`, repository impls, data sources, DTOs, mappers.
6. **Providers form a DAG.** No cycles — split a "providers-only" file if needed.
7. **Online-only by default.** No offline-first patterns. See §6.

Two amendments to the canonical Clean Architecture template apply here:

- **No use-case layer.** `domain/usecases/*.dart` was removed on 2026-05-29. Controllers depend on **repositories directly** via `ref.read(<feature>RepositoryProvider).method(...)`. Business rules and value-object validation live inside the repository implementation (`Either<ValidationFailure, T>` / `Either<DomainFailure, T>`). Form-level input validation may still happen in the controller before the repo call (e.g. `Username.create(...)`).
- **Online-only.** No sync service, no pending-ops queue, no LWW. Each repository talks to Supabase directly. **One exemption:** the `messages` feature has a drift-backed read-through cache for the inbox + threads + composer drafts (see §6.4). Writes still go to Supabase first; the cache is a cold-start / instant-paint optimisation. Do not extend the cache pattern to other features.

---

## 4. App entry + routing

### Boot order (`lib/main.dart`)

```
WidgetsFlutterBinding.ensureInitialized()
Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)    // for FCM
FirebaseMessaging.onBackgroundMessage(_fbMessagingBgHandler)
Supabase.initialize(url, anonKey, authFlowType: pkce)             // PKCE on mobile
GoogleSignIn.instance.initialize(serverClientId, clientId)         // v7 — once at boot
runApp(ProviderScope(child: NovexApp()))
```

`NovexApp` (`lib/app.dart`) is a `ConsumerWidget`:

- Listens to `currentUserStreamProvider` and calls `appDatabase.clear()` on sign-out so user A's local cache cannot leak to user B on the same device.
- `ref.watch(pushRegistrarProvider)` activates the FCM token registrar for the session.
- Returns `MaterialApp.router(theme: buildCirckTheme(), routerConfig: appRouterProvider)`.

### Router (`lib/router/app_router.dart`)

`go_router`, `keepAlive`, redirect-based auth gating, refresh-listenable wired to the auth + onboarding-status streams. Behaviour:

- `!signedIn` → `/sign-in`.
- `signedIn && onboarded == null` (status pending) → no redirect; the refresh listener will re-evaluate.
- `signedIn && !onboarded` → `/onboarding`.
- `signedIn && onboarded` on `/sign-in` or `/onboarding` → `/home`.

Routes (current):

| Path | Screen | Notes |
|---|---|---|
| `/sign-in` | `SignInScreen` | OTP + Google |
| `/onboarding` | `OnboardingScreen` | first-run wizard |
| `/home` | `HomeFeedScreen` | tab 0 — branch root |
| `/matches` | `MatchesV2Screen` | tab 1 — Live · Upcoming · Recent · Browse |
| `/pavilion` | `PavilionV2Screen` | tab 2 — Matches/Teams/Tournaments lanes |
| `/pavilion/my-matches` | `MyMatchesScreen` | nested under tab 2; root-navigator |
| `/pavilion/match/:id` | `PavilionMatchDetailScreen` | match detail |
| `/messages` | `InboxScreen` | tab 3 |
| `/messages/:chatId` | `MessageThreadScreen` | thread; root-navigator |
| `/profile` | `ProfileScreen(isTab: true)` | tab 4 (self) |
| `/u/:username` | `ProfileScreen(username:)` | public profile; deep-link landing |
| `/teams`, `/teams/create`, `/teams/:teamId`, `/teams/:teamId/manage`, `/teams/:teamId/add-unclaimed` | Teams flows | full-screen over shell |
| `/matches/:matchId/start` | `MatchStartScreen` | toss + opener pick |
| `/matches/:matchId/score?innings=N` | `ScoringScreen` | live scoring |
| `/matches/:matchId/innings-break` | `InningsBreakScreen` | between innings |
| `/matches/:matchId/scorecard` | `ScorecardScreen` | spectator |
| `/matches/:matchId/result` | `ResultScreen` | post-match |
| `/challenge`, `/teams/:teamId/challenge` | `ChallengeSendScreen` | send match request |
| `/challenges/:requestId` | `ChallengeDetailScreen` | accept / counter / decline |
| `/challenges/:requestId/sent` | `ChallengeSentScreen` | post-send confirm + share code |
| `/notifications` | `NotificationsScreen` | bell drawer |

The challenge **counter** route (`/challenges/:requestId/counter`) is temporarily disabled at the router level; import + route are commented out for easy restore.

The 5-tab shell is a `StatefulShellRoute` whose container is `SwipeableBranchView` — a `PageView` of branch navigators with `preload: true` on each branch so swipe-between-tabs lands on real content. Header bell on every primary tab opens `NotificationsScreen` over the root navigator.

---

## 5. Folder map (current state)

```
lib/
├── core/
│   ├── connectivity/          — informational `isOnline` stream
│   ├── database/              — drift: WizardDrafts + messages cache tables
│   ├── error/                 — Failure + Exception hierarchies + FailureWrapper
│   ├── push/                  — FCM service + provider
│   ├── supabase/              — SupabaseClient keepAlive provider + currentUser ext
│   ├── theme/                 — CkColors, CkType (variable fonts), CkRadii, buildCirckTheme()
│   └── widgets/               — feature-agnostic UI
│       ├── ck_*               — original kit (button, text field, bottom nav, scaffold, brand)
│       └── v2/                — v2 IA kit (CkFeedImage, CkShimmer, v2_kit, v2_modals)
├── router/                    — go_router + StatefulShellRoute + auth refresh
├── app.dart                   — MaterialApp.router + sign-out wipe + push registrar
├── main.dart                  — Firebase + Supabase + GoogleSignIn init + runApp
└── features/
    ├── auth/                  ⭐ full layered      (OTP + Google)
    ├── onboarding/            ⭐ full layered      (wizard + draft persistence)
    ├── shell/                 — presentation-only (5-tab shell + swipe)
    ├── home/                  — presentation-only (composes posts providers)
    ├── pavilion/              — presentation-only (aggregation view)
    ├── profile/               — presentation-only (self + by-username + edit)
    ├── messages/              ⭐ full layered      (online + read-through cache exemption)
    ├── notifications/         ⭐ full layered      (inbox + push registrar)
    ├── location/              ⭐ full layered      (Places + GPS)
    ├── follows/               ⭐ full layered      (follow/unfollow + lists)
    ├── teams/                 ⭐ full layered      (canonical realtime online-only)
    ├── matches/               ⭐ full layered      (lifecycle + scoring + requests)
    └── posts/                 ⭐ full layered      (feed + photo composer)

supabase/
├── migrations/                — timestamp-epoch SQL (50+ migrations)
├── functions/                 — edge functions (record-ball, list-my-matches, list-my-chats, list-follow-list, send-match-request, send-push)
└── seed*.sql                  — dev seed data

test/
└── features/                  — 9 test files (auth, matches, onboarding, posts, teams)
```

Per-feature layout (full-layered):

```
lib/features/<feature>/
├── domain/
│   ├── entities/              — pure Dart, extends Equatable
│   ├── value_objects/         — Either<ValidationFailure, T>.create only
│   └── repositories/          — abstract; returns Either<Failure, T> / Stream<T>
├── data/
│   ├── models/                — freezed DTOs with toEntity()
│   ├── datasources/
│   │   ├── *_remote_datasource.dart
│   │   └── *_datasource_providers.dart   — @Riverpod DI
│   └── repositories/
│       └── *_repository_impl.dart        — only place exceptions become Failures
└── presentation/
    ├── state/                 — sealed/freezed view-models (skip when AsyncValue<T> suffices)
    ├── controllers/           — @riverpod Notifier / AsyncNotifier / StreamNotifier
    ├── screens/               — ConsumerWidget / ConsumerStatefulWidget
    ├── widgets/               — feature-local extractions (flat until ~3 files)
    └── providers/             — @riverpod repository + intermediate Future/Stream views
```

---

## 6. Cross-cutting infrastructure

### 6.1 Error model (`lib/core/error/`)

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure    extends Failure { /* ... */ }
class ServerFailure     extends Failure { /* ... */ }
class AuthFailure       extends Failure { /* ... */ }
class CacheFailure      extends Failure { /* ... */ }
class ValidationFailure extends Failure { /* ... */ }
class NotFoundFailure   extends Failure { /* ... */ }
class PermissionFailure extends Failure { /* ... */ }
class ConflictFailure   extends Failure { /* ... */ }  // optimistic-lock / 409
class UnknownFailure    extends Failure { /* ... */ }

class FailureWrapper implements Exception {            // carries Failure through Streams
  const FailureWrapper(this.failure);
  final Failure failure;
}
```

Raw exceptions (`exceptions.dart`): `ServerException`, `CacheException`, `UnauthorizedException`, `NotFoundException`. Translated to `Failure` inside `data/repositories/*_impl.dart` exclusively.

### 6.2 Supabase access (`lib/core/supabase/`)

- `supabase_client_provider.dart` — `@Riverpod(keepAlive: true) SupabaseClient supabaseClient(...)` returning `Supabase.instance.client`.
- `current_user_x.dart` — `requireUid()` extension on `SupabaseClient` used widely to assert sign-in inside data sources before a network call (throws `UnauthorizedException` if absent).

### 6.3 Theme (`lib/core/theme/circk_theme.dart`)

matchday Brand Sheet implemented as design tokens:

- **Ink ramp:** `ink #29251E`, `ink2 #4A4339`, `muted #8A8170`, `soft #B9B1A2`.
- **Paper surfaces:** `paper #FBFAF6`, `paper2 #F3F0E9`, `surface #FFFFFF`.
- **Lines:** `line #E6E2D9`, `hairline #EEEBE3`.
- **Earned accents:** `red #DC4D32` (Cricket Red), `cream #F4ECDD` (Seam), plus functional `green`/`amber`.
- **Radii:** `sm 8`, `md 14`, `lg 20`, `xl 28`.
- **Type:** `CkType.display` ("Inter Tight"), `CkType.body` ("Inter"), `CkType.mono` ("JetBrains Mono"). All bundled as **variable TTFs** in `assets/fonts/` — no network font fetch. `letterSpacing` for `display` and `mono` is multiplied by `fontSize` internally; pass the raw em value (e.g. `-0.02`), NOT pre-multiplied. (Documented warning in memory; verify when editing typography.)
- `buildCirckTheme()` returns the `MaterialApp.router` theme: M3 light scheme, paper scaffold, ink filled buttons, paper outlined buttons, ink snackbar, red text-button accent.

### 6.4 Local database (`lib/core/database/`)

`AppDatabase` (drift, `schemaVersion: 6`) currently holds:

| Table | Purpose | Notes |
|---|---|---|
| `wizard_drafts` | transient multi-step form state (onboarding etc.) | keyed by caller string; never synced; cleared on sign-out |
| `chats` | inbox row mirror (messages feature exemption) | denormalised; mirrors `list-my-chats` edge function shape |
| `messages` | thread message mirror | one row per remote message; not LWW |
| `message_drafts` | one composer draft per chat | survives app restart |

Indexes (created in `_createMessagesIndexes`): `idx_chats_last_message_at` (DESC), `idx_messages_chat_created`.

`AppDatabase.clear()` wipes all four tables on sign-out via `app.dart`.

**WizardDraftStore** (`wizard_draft_store.dart`) is a best-effort read/write API for the wizard drafts table — errors are swallowed (a lost draft is a minor annoyance, never a `Failure`). It is the one sanctioned exception to "controllers don't reach into core/database" — the `OnboardingController` reads `wizardDraftStoreProvider` directly.

### 6.5 Connectivity (`lib/core/connectivity/`)

`isOnlineProvider` is informational only — no business decision depends on it. The architecture is online-only; offline UX is "let the call fail, show the failure."

### 6.6 Push (`lib/core/push/`)

`PushMessagingService` wraps `FirebaseMessaging`:

- Retrieves the FCM token.
- Foreground messages → `flutter_local_notifications` heads-up.
- Background / terminated → OS notification (the top-level `_firebaseMessagingBackgroundHandler` in `main.dart` is a required no-op handler).
- Tap on a notification → reads the `route` field from the payload and forwards it through go_router (so the auth-redirect still applies — never navigate from the service directly).

`pushRegistrarProvider` (in `features/notifications/.../push_registrar.dart`) is the **session-scoped registrar**: on sign-in it upserts the device's FCM token to the `device_tokens` Supabase table; on sign-out it deletes the row. Activated by `ref.watch(pushRegistrarProvider)` in `app.dart`.

Backend: the `notifications_invoke_send_push` trigger (migration 0900) calls the `send-push` edge function whenever a notification row is inserted; the function looks up the recipient's tokens and dispatches FCM.

---

## 7. Feature inventory (current state)

Conventions used below:

- **Status:** `full layered` = `domain/` + `data/` + `presentation/`. `presentation-only` = aggregation view that composes other features.
- **Backed by:** which Supabase tables / edge functions the feature touches.
- **Repository contract:** the abstract method list (the source of truth for what is implemented).
- **Wired or mocked:** whether the screens are wired to real data or still rendering mock copy.

### 7.1 `auth` — full layered

- **Status:** stable.
- **Backed by:** Supabase Auth (email OTP + native Google OAuth via `signInWithIdToken`).
- **Domain:**
  - `User` entity (UserId wrapper).
  - Value objects: `Email`, `OtpCode`.
  - Contract: `AuthRepository` — `sendEmailOtp`, `verifyEmailOtp`, `signInWithGoogle`, `signOut`, `getCurrentUser`, `watchCurrentUser`.
- **Presentation:** `SignInScreen`, `AuthController` (`Notifier<AuthState>` sealed: Initial, SendingOtp, OtpSent, Verifying, Authenticated, Failed). `currentUserStreamProvider` is the canonical auth-state observable used by the router refresh-listenable and `app.dart` sign-out wipe.
- **Special:** `GoogleSignIn.instance.initialize()` must be called once in `main.dart` (not per sign-in). Mobile uses native flow + `signInWithIdToken`; no `signInWithOAuth`.

### 7.2 `onboarding` — full layered

- **Status:** wired end-to-end; wizard supports resume from killed app.
- **Backed by:** `profiles` + `player_profiles` Supabase tables + `avatars` Storage bucket.
- **Domain:**
  - `Profile`, `PlayerProfile` entities.
  - Value objects: `Username`, `DisplayName`, `City`.
  - Contract: `ProfileRepository` — `getMyProfile`, `getByUsername`, `isUsernameAvailable`, `completeOnboarding(...)`, `updateProfile(...)`.
- **Presentation:** `OnboardingScreen` (Notifier + freezed `OnboardingState`), `onboardingStatusProvider` (drives router redirect), draft persistence via `WizardDraftStore`.
- **Geo:** captures `placeId`, `latitude`, `longitude`, `countryCode`, `city`, `district`, `province`, `postcode` — stored on the profile row as structured geo for future "teams near you" features.

### 7.3 `shell` — presentation-only

- `AppShell` — the 5-tab bottom nav + header bell.
- `SwipeableBranchView` — `PageView` that hosts the `StatefulShellRoute` branch navigators with finger-tracking swipe between tabs.
- `ComingSoonScreen` — generic placeholder for inactive surfaces.

### 7.4 `home` — presentation-only

- `HomeFeedScreen` (`ConsumerStatefulWidget`) — watches `feedControllerProvider` (the posts feature's `AsyncNotifier`), renders posts via `FeedPostCard`, pulls-to-refresh, infinite scroll via keyset pagination.
- Two visual surfaces are flagged off today: the live-match cards rail (`_kShowLiveCards = false`, ticket #1) and the feed filter chips (`_kShowFeedFilters = false`, ticket #2). The widgets are still defined for flip-back-on.

### 7.5 `pavilion` — presentation-only

- `PavilionV2Screen` is the "your workspace" hub: segmented (Matches · Teams · Tournaments) with calendar + lanes.
- Wired to real providers: `myMatchesViewProvider`, `myTeams`, `myProfileProvider`. Tournaments lane is mock (no Flutter feature yet).
- Drill-downs: `MyMatchesScreen` (`/pavilion/my-matches`) and `PavilionMatchDetailScreen` (`/pavilion/match/:id`) — rendered full-screen over the shell via the root navigator but URL-nested for refresh-restore.
- Account header reads from `myProfileProvider`; Pavilion is the canonical example of CLAUDE.md §6.6 cross-feature aggregation.

### 7.6 `profile` — presentation-only

- `ProfileScreen` has **three modes**:
  - `isTab: true` (the "You" tab) → `myProfileProvider`. Edit button + Share + compose FAB.
  - `username: "<handle>"` (`/u/:username`) → `profileByUsernameProvider`. Follow / Message / Share, back chevron, no FAB. Unknown handle → not-found state.
  - Legacy spectator demo (mock copy) reached from the feed demo path.
- Follow counts via `followCountsProvider`, posts via `authorPostsProvider` (both autodispose, keyed by user id).
- `ProfileEditScreen` + `ProfileEditController` — updates display name, bio, city/geo, optional avatar upload. Username change is server-enforced 30-day cooldown.

### 7.7 `messages` — full layered (with local cache exemption)

- **Status:** complete and polished — many recent commits (#5–#48) have refined RLS, pagination, realtime, drafts, unread badge, scroll behaviour.
- **Backed by:** `chats`, `chat_members`, `messages` Supabase tables; `list-my-chats` and `mark_chat_read` (SECURITY DEFINER RPC); realtime broadcast channels `chat:<id>:messages` (per-thread) and the inbox per-user channel.
- **Local cache (only exempted feature):** drift `Chats`, `Messages`, `MessageDrafts`. Read-through pattern: inbox + last-50 thread messages render from cache instantly, then realtime + initial fetch hydrate.
- **Domain contract:** `MessagesRepository` — `watchMyChats()`, `watchMessages(chatId)`, `loadOlderMessages(chatId)`, `sendMessage`, `markRead`, plus `readDraft / saveDraft / deleteDraft` (raw `String` for drafts — intentional, since drafts may be partial).
- **Value object:** `MessageBody` (rejects empty/whitespace, enforces max length).
- **Presentation:** `InboxScreen` (renamed from `MessagesScreen` per #45), `MessageThreadScreen`, `MessageThreadController` (handles send + draft debounce + pagination on scroll-up).
- **Pagination:** initial 50 messages; older pages on demand via keyset pagination on `(created_at, message_id)`.
- **Unread badge:** capped at "99+" at 100 (#37).
- **Filters:** inbox All/Teams/DMs tabs hidden (#15); single combined list.

### 7.8 `notifications` — full layered

- **Status:** core working; bell badge counts unread; broadcast realtime updates land instantly.
- **Backed by:** `notifications` table + `device_tokens` table + `user:<uid>:notifications` broadcast channel + `send-push` edge function (server-side trigger).
- **Domain:** `AppNotification` entity, `NotificationsRepository` — `listMine`, `watchMine`, `markRead`, `markAllRead`, `registerDeviceToken`, `revokeDeviceToken`.
- **Presentation:** `NotificationsScreen` opens over the root navigator via the header bell on every primary tab.
- **PushRegistrar:** session-scoped, runs on every sign-in.
- **Routing:** request-shaped tables (e.g. match_requests) are **not** added to `supabase_realtime` — the notifications broadcast already carries the state-change signal. Do not propose adding them.

### 7.9 `location` — full layered

- **Status:** wired for onboarding + profile-edit geo capture.
- **Backed by:** Google Places API New (autocomplete + place details + geocode) and device GPS via `geolocator`.
- **Domain:** `GeoPlace`, `PlaceSuggestion`, `LocationRepository` — `autocomplete(query, sessionToken)`, `placeDetails(placeId, sessionToken)`, `currentLocation()` (GPS + reverse-geocode), `geocode(query)`.
- **Failures:** `PermissionFailure` returned when GPS access denied or service off.
- **Where used:** onboarding city step + `ProfileEditScreen`. Output is stored as structured geo on `profiles.location` (jsonb) and discrete columns.

### 7.10 `follows` — full layered

- **Status:** wired end-to-end (PRs #49/#51/#53).
- **Backed by:** `follows` table (polymorphic targets: user/team/tournament) + `list-follow-list` edge function.
- **Domain:** `Follow`, `FollowCounts`, `FollowDirection`, `FollowListEntry`. `FollowsRepository` — `follow(target)`, `unfollow(target)`, `isFollowing(target)`, `getFollowList(userId, direction, limit, offset)`, `getFollowCounts(userId)`.
- **Presentation:** `FollowersListScreen` (paginated, shows "FOLLOWS YOU" tag + tri-state button), `FollowToggleController` (used by profile + team page).
- **Edge function `list-follow-list`** exists because `follows.target_id` is polymorphic (no FK to `profiles`) — PostgREST can't join the following direction; the edge function does the EXISTS subqueries for the caller's relationship.

### 7.11 `teams` — full layered (canonical realtime online-only)

- **Status:** mature; the reference implementation for realtime streams.
- **Backed by:** `teams`, `team_members`, `unclaimed_players`, `claim_requests`, `team_invites` Supabase tables + `team-logos` Storage bucket.
- **Domain:**
  - Entities: `Team`, `TeamMember`, `UnclaimedPlayer`, `RosterMember`, `PlayerSkills`, `TeamRelationship`.
  - Value objects: `TeamName`, `JerseyNumber`, `PlayerDisplayName`.
  - Contract: `TeamsRepository` (see §7.11 method list below).
- **Repository methods:** `watchMyTeams(userId)`, `watchAllTeams()`, `watchTeam(id)`, `getTeam(id)`, `watchRoster(teamId)`, `createTeam(...)`, `uploadTeamLogo(...)`, `addUnclaimedPlayer(...)`, `removeMember(id)`, `setJerseyNumber(id, jersey)`, `setMemberRole(id, role)`.
- **Presentation:** `TeamsListScreen`, `TeamCreateScreen` (multi-step + draft state), `TeamPageScreen` (mostly read; team hub), `TeamManageScreen`, `AddUnclaimedPlayerScreen` (validated wizard). All wired to realtime streams.
- **Teams list controller** (`TeamsListController`) composes cross-feature: it watches `matchesRepositoryProvider` to derive "your next match" per team — canonical example of allowed cross-feature dependency (§CLAUDE.md §6.6).

### 7.12 `matches` — full layered (most surface area)

- **Status:** lifecycle is wired through innings 1; second-innings → completion is partly server-side but the UI handoff is the next milestone.
- **Backed by:** `matches`, `match_players`, `match_officials`, `match_innings_state`, `balls`, `match_requests`, `match_result_history`, `format_presets`, `tournaments`, plus edge functions `list-my-matches`, `send-match-request`, `record-ball`. The `record-ball` edge function is the **scoring orchestrator** (see §9).
- **Domain entities:** `Match`, `Ball`, `MatchPlayer`, `MatchInningsState`, `InningsSummary`, `MatchRequest`, `MatchRole`, `FormatPreset`. `BallDraft` is the controller's computed draft (CLAUDE.md §6.6 "computed-draft object").
- **Repository contract:** 20+ methods grouped as:
  - Setup: `listFormatPresets`, `getMatch`, `listMyMatches`, `listInningsForMatches`, `watchMatch`.
  - Start: `recordMatchToss`, `submitMatchOpeners`, `startMatchNow`, `startInnings`.
  - Live scoring: `recordBall(BallDraft)`, `undoLastBall`, `watchBalls`, `getMatchInningsState`, `watchMatchInningsState`.
  - Players: `listMatchPlayers`.
  - Completion: `completeMatch`.
  - Challenges: `sendMatchChallenge`, `acceptMatchChallenge`, `counterMatchChallenge`, `declineMatchChallenge`, `withdrawMatchChallenge`, `getMatchChallenge`, `listMyMatchChallenges`, `findMatchChallengeByCode`.
- **Presentation:** `MatchesV2Screen` (tab), `MatchStartScreen` (toss + lineup pick), `ScoringScreen` (3,353 LOC — the live scoring console), `InningsBreakScreen`, `ScorecardScreen`, `ResultScreen`, plus the challenge flow screens (`ChallengeSendScreen`, `ChallengeDetailScreen`, `ChallengeSentScreen`, `ChallengeCounterScreen` (commented out)).
- **My-matches scoping:** the `matches` table is `RLS USING true` (world-readable so spectators can browse). "My matches" is computed by the `list-my-matches` edge function — see §9.

### 7.13 `posts` — full layered

- **Status:** feed + composer wired; engagement (likes/comments/bookmarks) is mocked in UI, schema in place.
- **Backed by:** `posts` table (`media jsonb`, ≤4) + `post-media` public Storage bucket. Engagement tables exist (`post_likes`, `comments`, `comment_likes`, `bookmarks`) but the client doesn't persist yet.
- **Domain:** `Post`, `PostDraft`, `PostMedia`. Contract: `getFeed({limit, before})`, `getAuthorPosts(authorId, {limit, before})`, `createPost(PostDraft)`, `deletePost(id)`.
- **Photo pipeline (composer):** `PhotoProcessor` data source: `image_picker` → `image_cropper` → resize ≤1080 long-edge + JPEG q75 (`flutter_image_compress`) → `blurhash_dart` + `image` for the BlurHash hash. One file per image at `post-media/<post_id>/<i>.jpg`; metadata jsonb on the row.
- **Feed render:** `FeedPostCard` + `PostMediaGrid` + `CkFeedImage` (`memCacheWidth = slotPx × devicePixelRatio`, BlurHash placeholder, `AspectRatio` to avoid reflow).
- **Pagination:** keyset on `posts_status_created` index by `created_at`; controller exposes `loadMore` / `refresh` / `prepend`.

---

## 8. Supabase schema (current state)

29 tables across 50+ migrations under `supabase/migrations/`. All tables follow:

- UUID PK (`gen_random_uuid()` server-side, or client-generated UUID for offline-required tables — none today).
- `user_id` (or per-feature owner) with RLS `auth.uid() = user_id` for owner-scoped tables.
- `created_at` + `updated_at` (`updated_at` set by `set_updated_at()` trigger).
- Tables that need realtime are added to `supabase_realtime` publication. Most realtime today flows through **per-topic broadcast channels** (not table replication) for surgical authorization control — see migration `20260101000810_realtime_authorization.sql`.

### 8.1 Table inventory (grouped)

| Group | Tables |
|---|---|
| Identity | `profiles`, `player_profiles`, `unclaimed_players` |
| Teams | `teams`, `team_members`, `claim_requests`, `team_invites` |
| Tournaments | `tournaments`, `tournament_teams`, `tournament_standings` |
| Matches | `matches`, `match_players`, `match_officials`, `match_innings_state`, `balls`, `match_requests`, `match_result_history` |
| Posts | `posts`, `post_likes`, `comments`, `comment_likes`, `bookmarks` |
| Social | `follows` |
| Messaging | `chats`, `chat_members`, `messages` |
| Notifications | `notifications`, `device_tokens` |
| Catalog | `format_presets` |

### 8.2 Caller-facing RPCs (selected)

Most server-side logic lives in **edge functions** during dev phase (see §10). Stable RPCs that the client calls via `supabase.rpc`:

| RPC | Purpose |
|---|---|
| `start_match_now`, `submit_match_openers`, `record_match_toss`, `start_innings`, `undo_last_ball`, `submit_match_result`, `complete_match` (← name varies; see migration) | Match lifecycle write paths |
| `record_ball` | Used as a fallback / direct-DB scoring writer (the typical write path is the `record-ball` edge function) |
| `accept_match_request`, `counter_match_request`, `decline_match_request`, `cancel_match_request`, `find_match_request_by_code` | Match request handshake |
| `mark_chat_read` (SECURITY DEFINER) | Sets `chat_members.last_read_at = now()` for the caller (#39 fix) |
| `delete_user`, `leave_team`, `accept_team_invite`, `approve_claim_request` | Identity / team lifecycle |
| `generate_round_robin_fixtures`, `generate_knockout_fixtures`, `generate_tournament_fixtures`, `recalculate_standings` | Tournament fixturing (UI not yet built) |

Internal predicates (used by RLS and triggers, not exposed): `_can_score_match`, `_can_score_innings`, `_is_match_captain`, `_team_current_captain`, `_match_batting_team`, `_batting_first_team`, `_innings_runs`, `_innings_overs`, `_validate_team_xi`, `_format_presets_validate`, `_validate_request_format`, `_validate_match_request_keeper`.

Broadcast triggers (do not call directly): `broadcast_new_ball`, `broadcast_innings_state`, `broadcast_match_state`, `broadcast_new_message`, `broadcast_new_notification`, `broadcast_new_comment`, `broadcast_comment_updated`, `broadcast_comment_deleted`, `broadcast_ball_deleted`, `broadcast_notification_updated`, `broadcast_standings_change`. The `_after_match_complete` trigger handles knockout bracket advance + standings recalc.

### 8.3 RLS posture

- **Owner-scoped tables** (most): `auth.uid() = user_id` (or equivalent).
- **`matches`:** `matches_read_public USING (true)` — anyone signed in can read any match (spectator browse). "Mine" filtering is in the `list-my-matches` edge function. **Do not** add a manual `WHERE user_id` filter at the client.
- **`profiles`:** read-public (`profiles_read_public` with `account_status = 'active'`) so `/u/:username` can resolve without a server hop.
- **`posts`:** public read for active posts; engagement tables have per-table RLS.
- **`chat_members`:** strict — managed by triggers (`chat_members_role_trigger` (#42 fix), `prevent_chat_member_role_escalation`) to block role escalation.
- **`follows`:** read public; insert/delete only as `auth.uid() = follower_id`.
- **`balls`:** insert only via `record_ball` RPC / edge function (RLS gates the direct path with `_can_score_innings`).

### 8.4 Edge functions

| Function | Why it exists |
|---|---|
| `record-ball` | The scoring orchestrator. Identifies caller → authorizes with `_can_score_match` (run AS the user) → opens a single Postgres transaction over a direct connection → `FOR UPDATE` lock the innings → run the **TypeScript scoring engine** (`_shared/scoring/engine.ts`) → insert ball + update innings state → if innings ended, transition match (innings_break or completed with computed result) → commit. Returns `{ ok: true, ball, events, transition }`. |
| `list-my-matches` | Computes "matches I participate in" (creator OR member of either team OR owner/manager of either team OR assigned official). Cannot be done at RLS because `matches` is world-readable. |
| `list-my-chats` | One round-trip inbox: chat header + last message + unread count + team join. Replaces what PostgREST embedded selects can't express. |
| `list-follow-list` | Followers/following list with `you_follow` + `they_follow_you` flags computed for the caller. Required because `follows.target_id` is polymorphic — no FK to `profiles`. |
| `send-match-request` | Mirrors the `send_match_request` PG function in TypeScript for iteration speed during the dev phase. Authorises caller is manager of `from_team`, validates XI, mints share code, inserts row with expiry. PG function stays as fallback. |
| `send-push` | Server-side FCM dispatcher. Called by the `notifications_invoke_send_push` trigger. Reads `FCM_PROJECT_ID` + `FCM_SERVICE_ACCOUNT` secrets, looks up the recipient's `device_tokens`, fans out the FCM payload. |

`supabase/functions/_shared/scoring/` contains the pure TypeScript scoring engine (`engine.ts`, `result.ts`, `types.ts`) plus tests (`engine.test.ts`, `result.test.ts`). The engine is pure — call it with `(state, format, delivery)`, it returns the new state. The `record-ball` orchestrator is the only place it is wired to the DB.

---

## 9. Scoring engine architecture (server-authoritative)

This is the single most complex subsystem. The decision (recorded in memory) is **split architecture**:

```
┌────────────────────────────────┐     ┌────────────────────────────────┐
│  CLIENT (ScoringScreen)         │     │  EDGE (record-ball)            │
│                                 │     │                                │
│  user taps "1 run"              │     │  1. identify caller (JWT)      │
│   ↓ ref.read(matchesRepo)       │ →   │  2. authorize via              │
│      .recordBall(BallDraft)     │     │     _can_score_match (AS user) │
│                                 │     │  3. BEGIN tx                   │
│  optimistic UI from realtime    │     │  4. SELECT ... FOR UPDATE on   │
│  stream (watchBalls)            │     │     match_innings_state        │
│                                 │     │  5. pure engine.ts computes    │
│                                 │     │     new state                  │
│                                 │     │  6. INSERT balls + UPDATE      │
│                                 │     │     match_innings_state        │
│                                 │     │  7. if innings ended → flip    │
│                                 │     │     match status; if game      │
│                                 │     │     ended → compute result     │
│                                 │     │  8. COMMIT                     │
│                                 │     │  9. triggers fire → broadcast  │
│                                 │     │     channels emit (balls,      │
│                                 │     │     innings_state, match_state)│
└────────────────────────────────┘     └────────────────────────────────┘
                                                     │
                                                     ▼
                                          CLIENT receives realtime ev →
                                          updates ScoringScreen UI
```

- The **engine** (`supabase/functions/_shared/scoring/engine.ts`) is pure TypeScript — `(state, format, delivery) → newState + events`.
- The **writer** is a thin atomic Postgres transaction over a direct connection (not PostgREST) because PostgREST has no transactions and the row lock is essential.
- The **client** uses optimistic UI via the broadcast streams; it never tries to compute the score itself.
- All formats are supported by the engine; format gating lives in `format_presets` + `_format_presets_validate`.

Who has the lock to score? **The team currently batting** — its managers. The predicate is `_can_score_innings` server-side and a UI gate in `scoring_screen.dart` client-side. The lock switches at innings break.

Status today: innings 1 + transition to innings 2 are wired. Innings 2 → completion is **server-side complete** (the engine + transition code handle it; `_after_match_complete` advances brackets / recalculates standings) but the client handoff (`InningsBreakScreen` → second innings → `ResultScreen`) needs another integration pass. See memory entry "Match engine architecture" for the latest status.

---

## 10. Conventions and the "no-X" rules

These come up in code review repeatedly. Internalise them before writing anything:

1. **Dev-phase choice: edge functions over RPCs.** New server-side logic ships as edge functions during the dev phase (no DB migrations per change). Promote to SQL RPC once the shape settles. The current "edge for now" candidates: `list-my-chats`, `list-my-matches`, `list-follow-list`, `record-ball`, `send-match-request`.
2. **No use-case layer.** Controllers call repositories directly.
3. **No offline-first.** One exemption: messages cache. Don't propose it for other features.
4. **No request-shaped realtime tables.** Don't add `match_requests`-shaped tables to `supabase_realtime`; let the notifications broadcast carry the state-change signal.
5. **Discuss design before opening a ticket** for any non-trivial change (state, control flow, edge cases). Multi-choice "ship X" answers are direction, not execution.
6. **Verify pub.dev + canonical docs** before recommending any pubspec add/swap.
7. **Strict schema nullability.** If a DTO-vs-DB null-cast crashes for a value that "should always exist," fix the schema (backfill + NOT NULL + seed) — do not make the model nullable. Recent example: `team_members.added_by` (migration `20260609000000_team_members_added_by_not_null.sql`, untracked seed).
8. **Don't pre-split screens** into many widget files; keep monolithic until ≥800 LOC or a real reuse case (CLAUDE.md §5.3). The biggest screens today reflect this — `team_page_screen.dart` (3,233), `scoring_screen.dart` (3,353), `team_create_screen.dart` (2,798), `profile_screen.dart` (2,150) — each has its own `widgets/<screen_name>/` sub-folder.
9. **Controller action return shape:**
   - Stateful controllers (returning `T`/`State`): `Future<void>` with `state.submitError` for failure surfacing.
   - Stateless action coordinators (`build` returns `void`): `Future<Either<Failure, T>>` and widget uses `.fold(...)`. Do NOT pattern-match with `switch` — that leaks fpdart import.
10. **`CkType` letterSpacing is per-em.** Display/mono multiply `letterSpacing × fontSize` internally — pass the raw em value (`-0.02`), not pre-multiplied.

---

## 11. Build + run

```bash
# 1. Install deps
flutter pub get

# 2. Generate code (must run after any @riverpod / @freezed / @JsonSerializable / drift change)
dart run build_runner build --delete-conflicting-outputs

# 3. Run (compile-time secrets via --dart-define-from-file)
cp dart_define.example.json dart_define.json   # then fill in values
flutter run --dart-define-from-file=dart_define.json

# Static analysis + tests
flutter analyze
flutter test
```

`dart_define.json` (gitignored) supplies:

- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`

Firebase: `lib/firebase_options.dart` is checked in (produced by `flutterfire configure`). Project: `matchday-44ed4`. Android app id: `com.matchday.app`. iOS still needs the Push Notifications capability + APNs key set up in Xcode before tokens issue.

App icon: `assets/brand/appicon_1024.png` (regenerate via `dart run flutter_launcher_icons` after editing the brand SVGs).

Fonts: bundled variable TTFs in `assets/fonts/` (`Inter.ttf`, `InterTight.ttf`, `JetBrainsMono.ttf`) — declared under `flutter: fonts:` in pubspec. No `google_fonts` runtime fetch.

---

## 12. Deep links

- Host: `joinmatchday.com`. Shareable route: `/u/<username>`.
- **In-app:** the share button in `ProfileScreen._shareProfile` opens the OS share sheet with `https://joinmatchday.com/u/<username>`. The `/u/:username` route is registered in `app_router.dart` and renders `ProfileScreen(username: ...)`.
- **Native config (in-repo):** `AndroidManifest.xml` has the App Links intent filter + `flutter_deeplinking_enabled` meta-data; iOS `Info.plist` has `FlutterDeepLinkingEnabled` and `Runner.entitlements` declares `applinks:joinmatchday.com`.
- **External steps (NOT in-repo):** the domain must serve `/.well-known/assetlinks.json` (Android release SHA-256) and `/.well-known/apple-app-site-association` (Apple Team ID + bundle id). Until both files are hosted, sharing still works — the link just opens the browser.

---

## 13. Tests

Current test footprint (`flutter test`):

```
test/features/auth/presentation/controllers/auth_controller_test.dart
test/features/matches/domain/entities/match_test.dart
test/features/onboarding/domain/value_objects/username_test.dart
test/features/onboarding/presentation/controllers/onboarding_controller_test.dart
test/features/onboarding/presentation/state/onboarding_state_test.dart
test/features/posts/data/repositories/posts_repository_impl_test.dart
test/features/teams/domain/entities/team_relationship_test.dart
test/features/teams/presentation/controllers/team_create_controller_test.dart
test/features/teams/presentation/controllers/teams_list_controller_test.dart
```

Total ~880 LOC. Test pyramid target per CLAUDE.md: 60% controller, 25% repository, 10% widget — current coverage skews to controller + entity tests. Pattern: `ProviderContainer.test(overrides: [...repoProvider.overrideWithValue(mock)])` + `mocktail`. No mockito; no generated mocks.

Server-side: `supabase/functions/_shared/scoring/engine.test.ts` + `result.test.ts` cover the pure scoring engine (run with `deno test` inside Supabase Functions).

---

## 14. Known gaps and next priorities (audit-time view)

This is a snapshot — read `git log` for the live picture.

- **Scoring innings-2 → completion UI** is the largest in-flight surface. Server is ready; client handoff after `InningsBreakScreen` needs the second-innings opener pick + chase target ribbon + result transition.
- **Posts engagement persistence** (likes, comments, bookmarks). Tables exist; UI is mocked. Schema for `comments` is single-level (enforced by `enforce_comment_single_level`).
- **Tournament authoring UI** — `tournaments`, `tournament_teams`, `tournament_standings`, fixturing RPCs (`generate_*_fixtures`) are all server-side. No Flutter feature folder yet.
- **Challenge counter flow** — route and screen are commented out in the router (`challenge_counter_screen.dart` still exists). v1 ships counter as receive-only; sender accept-or-decline.
- **Deep link verification files** — hosted assetlinks/AASA. Until then `/u/<username>` opens in browser, not app.
- **Profile follow / message** on `/u/<username>` profile mode — buttons are placeholders. Follow toggle should hook into `follow_toggle_controller`; message should open / create a 1-1 chat.
- **Live cards + feed filters on Home** — flagged off (#1, #2).
- **DB audit follow-ups** — `db_review/SCHEMA_AUDIT.md` and `db_review/DB_ARCHITECTURE_ASSESSMENT.md` exist with 4 criticals identified (dual scoring path, anon PII, client-callable internal fns, no career-stats rollup). **Nothing applied yet.**
- **Tests** — coverage of matches (especially scoring), posts repo, messages cache layer is thin.

---

## 15. Where to look for things (one-line map)

| If you want to… | Look at |
|---|---|
| Add a new feature, end-to-end | `CLAUDE.md` §7, follow `matches` as the reference shape |
| Add a new use case to an existing feature | `CLAUDE.md` §8; add a method to the repo contract + impl + a `@riverpod` view in `presentation/providers/` |
| Understand a screen's data flow | Start at the screen → controller `build()` → providers → repo contract → impl |
| Wire realtime | `teams_repository_impl.dart::watch*` + `matches_remote_datasource.dart::watch*` (broadcast channels) |
| Translate Postgres errors | `*_repository_impl.dart` catch blocks (`PostgrestException` → `ServerFailure`/`ConflictFailure`, `AuthException` → `AuthFailure`, etc.) |
| Add a Failure type | `lib/core/error/failures.dart` (always) |
| Add a value object | `lib/features/<feature>/domain/value_objects/` with private constructor + `Either<ValidationFailure, T>.create` |
| Add a Supabase table | Migration under `supabase/migrations/` (timestamp epoch); see §12 of CLAUDE.md for the boilerplate |
| Ship server-side write logic during dev | Edge function (TypeScript), not RPC. Stash pure helpers in `supabase/functions/_shared/` |
| Change the theme | `lib/core/theme/circk_theme.dart` only (tokens + `buildCirckTheme()`) |
| Adjust the bottom nav / tabs | `lib/router/app_router.dart` + `features/shell/.../app_shell.dart` |
| Wipe local state on sign-out | `AppDatabase.clear()` (covers all drift tables) — called from `app.dart` listener |
| Run codegen | `dart run build_runner build --delete-conflicting-outputs` after any annotation change |
| Re-issue the app icon | `dart run flutter_launcher_icons` |

---

## 16. Agent contract

This repository is set up for Claude Code with specialised subagents in `.claude/agents/`:

- `architecture-reviewer` — read-only review against CLAUDE.md rules. Run after any change in `lib/`.
- `feature-builder` — implements new features end-to-end per CLAUDE.md §7.
- `test-writer` — generates the test pyramid for a feature.
- `riverpod-specialist`, `supabase-specialist`, `drift-specialist` — focused experts.
- `version-auditor` — periodic dependency hygiene (run monthly).

For new sessions, the loadout is: read `CLAUDE.md` (the agent contract), then this doc for the audit-current map, then dive into the specific feature folder. Memory entries in `~/.claude/projects/.../memory/` carry persistent preferences (online-only, no-use-cases, dev-phase edge functions, design-fidelity, schema-strict-nullability, etc.).

If a pattern you need is not documented above, follow CLAUDE.md §13: identify the closest existing pattern, apply it even if forced, then document the extension in `CLAUDE.md` and flag it for review. Do not invent new patterns silently.
