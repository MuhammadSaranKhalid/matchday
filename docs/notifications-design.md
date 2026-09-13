# Notifications — catalogue, SVG presentation, and delivery

Implementation updated 2026-09-12. The canonical source schema and Flutter
client use the new catalogue. The hosted Matchday database inspected on this
date still used the legacy enum schema. These source edits are not a hosted
upgrade or a deployment.

## Data model

| Object | Responsibility |
|---|---|
| notification_categories | User-facing preference groups |
| notification_icons | Immutable Storage path, pinned upstream commit, MIT license, SHA-256 |
| notification_types | Copy/route templates, icon, independent tone, urgency, default channels, grouping window |
| notifications | Recipient inbox with rendered copy, presentation snapshots, read state, group count and expiry |
| notification_preferences | Per-user category/channel overrides; absent means use type defaults |
| notification_mutes | Per-user entity mute/snooze, including the follow bell |
| notification_deliveries | Actual per-device/per-revision outcomes, never a pre-send claim |
| pgmq queues | Durable work and visibility leases; separate direct and bulk queues |

`notify()` is the server-only entry point. It validates the type, removes the
actor and suppressed recipients, renders once, inserts or folds an unread row,
and transactionally enqueues one job per current device. No device produces a
`no_token` audit outcome. Push opt-out produces `skipped_pref` without a queue
job. A mute or in-app opt-out prevents the inbox row itself.

Types with `user_configurable=false` bypass category overrides and entity mutes;
their push default still determines whether push is sent. This is reserved for
required notices, not a way to override users' choices for ordinary activity.

The engine locks competing recipient/group pairs in a stable order. When a
window expires it releases the old row's collapse key without marking it read.
The next event starts a new group. Reading a row also releases its unique unread
slot. Group counts represent events, not distinct people or source-event dedup.

## Presentation

The row snapshots `icon_path`, `tone`, and `tier` alongside title/body/route. This
is a deliberate snapshot policy: Supabase `realtime.send` can carry custom joined
JSON, so copying catalogue fields is not imposed by Realtime. Catalogue edits
apply to future notifications (or later group updates); existing routes and
presentation do not change without an explicit backfill.

SVGs live in public bucket `notification-icons`, e.g. `v1/cricket.svg`. The 14
initial Tabler Outline assets are pinned to the commit recorded in the catalogue
and bundled with their MIT license. Run `python3 scripts/upload_notification_icons.py
--check` to validate checksums and supported SVG elements. Trusted uploads use
`--upload` with `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` in the environment.
The script never overwrites an existing version with different bytes. Publish
new artwork under a new versioned path.

Flutter resolves only validated relative paths against this project's bucket,
uses flutter_svg's in-memory loader cache, and displays a bundled bell while
loading or on failure. No persistent inbox cache was introduced. Icon selection and semantic color are independent *columns*, so either can
change without the other. They are not uncorrelated in practice: 0491 seeds
`tone` from `icon` in a trailing UPDATE, so the shipped catalogue pairs them.
Unknown tones fall back to neutral ink.

| Tone | Existing theme token | Hex |
|---|---|---|
| neutral | ink2 | #4A4339 |
| brand / danger | redInk | #B23A22 |
| success | greenInk | #276B34 |
| warning / achievement | amberInk | #8A6E2E |

All four exceed 3:1 against paper2. Urgency remains separately represented by
now/week/fyi. This mechanism controls inbox icons, not OS notification icons.

## Inbox and settings

The private user channel is subscribed before hydration. Insert/update/delete
signals invalidate a bounded inbox window; an event during fetching marks that
window dirty and triggers another reconciliation. Reconnection fetches again.
Pages use `(created_at, notification_id)` cursors. The badge uses a database
count across the entire inbox, not the number of unread rows already loaded.
The user can load older pages and change category/channel settings from the
inbox. Settings apply to future production and are checked again before sending
queued pushes. The follow bell writes notification_mutes through an authenticated
RPC, so no second notification-enabled column remains in the source schema.

RLS restricts recipients. Column grants permit only `is_read` updates. The
catalogue is read-only to app clients; engine/audience and queue RPCs are not
callable by authenticated users. Operational delivery errors remain server-only.

## Worker

`send-push` is now a scheduled consumer, not an endpoint accepting arbitrary
notification IDs. It requires a dedicated `x-worker-secret` header. The cron
wake reads `notification_worker_secret` and `supabase_url` from Vault. Configure
the same secret as `NOTIFICATION_WORKER_SECRET` in Edge Functions, along with
`FCM_PROJECT_ID` and `FCM_SERVICE_ACCOUNT`. `verify_jwt=false` is intentional;
manual secret authentication is mandatory and fails closed when unset.

The cron wakes every 15 seconds. Each wake claims up to 50 jobs from the direct
queue and 100 from the bulk queue, with a 120-second visibility lease — about
200 and 400 pushes per minute respectively. Batch size is per-queue policy
inside `read_notification_jobs`, so the worker carries no knowledge of it.

These replace an initial 10-per-queue at one wake per minute (~20 pushes/min),
which left a 50-person team announcement ~7 minutes behind, a 5,000-follower
tournament over twelve hours behind, and — worse — delayed an *urgent* match
challenge by minutes, where the per-row pg_net trigger this design replaces
delivered instantly. Several wakes may be in flight at once; that is safe
because pg_net is async and the visibility lease gives each invocation disjoint
messages. Raise further against the FCM send rate, not just queue depth. The worker rechecks
preferences, mutes, token ownership and group revision before sending. Outdated
revisions are superseded. Per-device successes survive retries of other devices.
Only explicit FCM UNREGISTERED errors delete the matching device token; HTTP 400
alone does not. Provider error codes are retained without response bodies/tokens.

Retryable errors remain queued, with at most five reads/attempts. Actual results
are persisted before archiving. A failed archive can safely repeat a recorded
terminal decision. A crash after FCM accepts but before the ledger is saved can
still duplicate a push: no SQL ledger can make FCM and Postgres atomic. Stable
Android notification tags / APNs collapse ids mitigate repeats; they do not
promise exactly-once external delivery. Archives retain terminal jobs for review.
The legacy per-row HTTP trigger and orphaned chat dispatch path are removed.

## Validation

### What was actually run (2026-09-12, local)

| Check | Result |
|---|---|
| `supabase db reset` — full replay from zero | **pass**, clean on first run |
| `supabase/snippets/advisors.sql` | **pass** — only `spatial_ref_sys` and `get_follow_list` |
| `supabase/tests/notifications_test.sql` (pgTAP) | **pass, 23/23** — after a fix, see below |
| `flutter test` (whole suite) | **651 passed / 10 failed** — the 10 pre-date this work (scoring-test drift), baseline was 647/10 |
| `flutter analyze lib` | **pass**, no issues |
| `test/supabase/migration_layout_test.dart` | **pass** |
| `relrowsecurity` on `realtime.messages` | **`t`** — Supabase enables it; see the header of 0810 |
| Sub-minute cron registers | **yes** — `notification-push-worker` at `15 seconds`, active |
| Batch size takes effect | **yes** — 60 queued jobs, first claim 50, second claim 10 |

**The pgTAP suite needed fixing.** Every assertion counted `notifications`
table-wide, so it passed only against an empty database and failed on a standard
`supabase db reset` (which seeds 9 notifications — the suite saw 10 where it
wanted 1, then errored on a single-row subquery). Assertions are now scoped to
the suite's own recipient. A test that only passes on a pristine database is not
a test anyone will keep running.

### Not run

- `deno check` and `deno test worker_test.ts` — **deno is not installed on this
  machine.** The worker's TypeScript is therefore unverified by tooling; it has
  been read, and `processJob` is structured for exactly these tests, but nobody
  has executed them here. Install deno before trusting the worker.
- A real FCM/device smoke test — required before release, in all three app
  states (foreground / background / killed).

## Rollout

The repository edits migrations at source. Replaying these against an existing
hosted schema is not an upgrade strategy. For a data-preserving hosted rollout:
export/backup first; add and backfill the new fields/catalogue; migrate false
`follows.notifications_enabled` values into permanent mutes; coordinate app and
worker versions; remove the legacy push trigger only when the queue path is
ready. Older installed clients require a compatibility period before removing
`type` and the follow toggle column. Do not reset a populated hosted project to
apply this work. Upload SVG assets and configure the worker before enabling its
schedule in the destination. A real FCM/device smoke test remains part of release.

## Remaining product work

Several catalogue types still have no producer: chat events, upcoming-match
scheduling, some team/registration/official events and milestones. Adding these
requires the corresponding product event, not more type switches. Quiet hours,
action resolution/expiry UI, post-detail routes, retention policy and durable
source-event deduplication remain separate product work. A new type alone does
not create its producer or a route an older app understands.

## Current references

- [Supabase Queues](https://supabase.com/docs/guides/queues)
- [Supabase Broadcast](https://supabase.com/docs/guides/realtime/broadcast)
- [Column-level privileges](https://supabase.com/docs/guides/database/postgres/column-level-security)
- [Storage serving](https://supabase.com/docs/guides/storage/serving/downloads)
- [FCM error codes](https://firebase.google.com/docs/cloud-messaging/error-codes)
- [Tabler SVG assets and license](https://github.com/tabler/tabler-icons)
