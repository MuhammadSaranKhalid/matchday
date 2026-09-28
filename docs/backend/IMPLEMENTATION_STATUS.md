# Matchday Backend Implementation Status

Last updated: 2026-09-28.

## Current gate

Phase 0 — audit: complete, awaiting review. Phase 1 has not started.

## Completed in Phase 0

- Inspected Git state, repository instructions, Flutter/package versions, CI, and the existing Node media worker.
- Inspected all first-party chat domain, DTO, repository, remote/local data source, local-first engine, sync, outbox, catch-up, receipt, realtime, provider, screen, and test files.
- Inspected Ably client/auth integration and chat database broadcast triggers.
- Inspected chat tables, constraints, indexes, RLS policies, capability functions, lifecycle RPCs, change ledger, receipt model, storage policies, and domain-sync triggers.
- Inspected FCM client handling, chat push preparation/delivery, device token schema, notification preferences/mutes, and general notification queue APIs.
- Inspected Supabase Auth initialization and session/token usage.
- Documented current architecture, target mapping, protocol, queues/outbox, deployment, risks, affected files, and confirmed target tree.

## Reusable assets

- Mature PostgreSQL chat schema and authorization model.
- Existing RPC behavior and `list_my_chats()` projection.
- Global server ordering via `messages.message_seq`.
- Durable mutation recovery via `chat_changes.change_seq`.
- High-water-mark receipts on `channel_members`.
- Flutter Drift projections and transactional cursor advancement.
- Client UUID message identity and account-scoped local outgoing operations.
- Existing notification preferences, channel mutes, blocks, device-token invalidation, and FCM payload routing.
- Current tests are useful characterization baselines.

## Legacy or migration-only assets

- Ably client/service, auth Edge Function, and PostgreSQL-to-Ably triggers remain required until cutover.
- `pg_net` chat push dispatch remains required until notification-worker parity.
- `private.chat_sync_events` is not sufficient as the target outbox and should not become a second source of truth.
- The standalone media worker remains independent until a later explicit consolidation decision.

## Blockers before Phase 1

- Human review/approval of the Phase 0 audit and proposed in-repository architecture.
- Confirm whether the Nest workspace should live at repository root as documented. This is recommended because migrations and Flutter contracts must evolve atomically.
- Verify current NestJS 12/Node active-LTS compatibility and package versions from official sources at Phase 1 start; Phase 0 intentionally installed nothing.

## Risks requiring characterization

- Flutter-to-RPC parameter mismatches for group creation and message editing.
- Duplicate retry reconciliation for `send_channel_message`.
- Dual publication/push while Ably and Nest coexist.
- Preservation of RLS/capability semantics when a server database connection is introduced.
- Pending DM request rules, blocks, membership periods, media upload ordering, and optimistic rollback.
- Server-side active-thread suppression does not yet exist.

## Phase status

| Phase | Status |
|---|---|
| 0 Audit | Complete; review gate |
| 1 Backend foundation | Not started |
| 2 Infrastructure | Not started |
| 3 Chat read model | Not started |
| 4 Chat write model | Not started |
| 5 Realtime | Not started |
| 6 Presence + typing | Not started |
| 7 Outbox + queues | Not started |
| 8 Notifications | Not started |
| 9 Flutter migration | Not started |
| 10 Load test | Not started |
| 11 Cutover | Not started |

## Phase 0 change report

Files added:

- `docs/backend/ARCHITECTURE.md`
- `docs/backend/CHAT_MIGRATION.md`
- `docs/backend/REALTIME_PROTOCOL.md`
- `docs/backend/QUEUE_ARCHITECTURE.md`
- `docs/backend/DEPLOYMENT.md`
- `docs/backend/IMPLEMENTATION_STATUS.md`

Files changed: none outside the added audit documents.

Files deleted: none.

Database changes: none.

Production code changes: none.

## Verification commands

Phase 0 documentation verification:

```sh
git diff --check
git status --short
Review `docs/backend` for unresolved markers and incomplete sections.
```

Phase 1 must add and run backend install, build, lint, unit, and architecture-test commands. Existing Flutter gates remain:

```sh
flutter analyze lib/
flutter test test/architecture_test.dart
```

They are not required to prove a documentation-only audit, but the repository's pre-existing dirty changes mean Phase 1 should record a clean baseline before scaffolding.

## Next phase

After approval only: Phase 1 creates the Nest 12 workspace, API/worker shells, platform config/logging/health, Docker foundation, CI, Vitest, oxlint, strict TypeScript/ESM, and architecture tests. It must not implement chat.
