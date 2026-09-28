# Matchday Repository Boundaries Design

**Status:** Implemented and verified
**Date:** 2026-09-28  
**Branch:** `backend`

## Purpose

Make the Matchday repository express its real product boundaries. The Flutter client and Nest backend currently share the repository root, which makes ownership, commands, CI, and tooling ambiguous. The target layout gives the Flutter app, backend platform, and Supabase project explicit homes while preserving the independently owned website and media worker.

This restructuring did not change application behavior, database behavior, deployed services, or secrets. The layout and compatibility gates were completed on 2026-09-28; Phase 2 infrastructure remains a separate, unstarted gated design.

## Target layout

```text
matchday/
├── app/            # Flutter client and Flutter-owned tooling
├── backend/        # Nest API/worker workspace and backend containers
├── supabase/       # authoritative migrations, functions, seeds, CLI config
├── website/        # existing independent Next.js website
├── media-worker/   # existing independent media worker
├── docs/           # repository-wide product and architecture documentation
├── scripts/        # genuinely cross-project/database maintenance scripts
├── .github/        # repository-wide CI orchestration
└── README.md       # repository entry point and project command map
```

The repository root is an orchestrator, not an application runtime. Historical design artifacts may remain at the root; the migration does not delete unrelated material merely to make the tree look smaller.

## Ownership

### Flutter application

`app/` owns:

- `lib/`, Flutter `test/`, and `assets/`;
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`;
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `devtools_options.yaml`, and `.metadata`;
- Firebase/FlutterFire configuration and Flutter environment configuration;
- Flutter-specific `tool/` content and scripts whose only consumers are the client.

The Flutter package remains a single package. It is not converted into a Dart workspace.

### Nest backend

`backend/` owns:

- Nest `apps/` and `libs/`;
- backend unit, architecture, integration, and e2e tests;
- `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, and Node runtime metadata;
- TypeScript, Nest, Vitest, and oxlint configuration;
- Dockerfile, Compose configuration, and backend container ignore rules;
- backend-local build and dependency outputs, which remain ignored.

The backend remains one pnpm/Nest workspace. TypeScript aliases, emitted paths, container entrypoints, and architecture tests become relative to `backend/`.

### Supabase

`supabase/` remains at the repository root and remains authoritative for migrations, Edge Functions, seeds, snippets, local CLI configuration, and database tests already stored there. It is neither copied into nor nested beneath the client or backend.

Flutter tests that inspect Supabase artifacts must address `../supabase/` from the `app/` package. The backend may consume database contracts in later phases but must not import Edge Function implementation code.

### Independent projects and shared files

`website/` remains the Next.js website. `media-worker/` remains an independent Node service. Neither is folded into the Nest workspace.

`.github/`, `docs/`, repository instructions, and genuinely cross-project scripts remain at the root. Existing database-support scripts stay in place unless they are already inseparable from one project; relocating or redesigning those tools is outside this migration.

## Command model

Project commands run from their owning directory:

```sh
cd app && flutter pub get
cd app && flutter analyze lib/
cd app && flutter test test/architecture_test.dart

cd backend && corepack pnpm install --frozen-lockfile
cd backend && corepack pnpm lint
cd backend && corepack pnpm test
cd backend && corepack pnpm build

supabase --workdir . status
docker compose -f backend/docker-compose.yml --project-directory backend config
```

Repository documentation may show equivalent subshell forms. No symlinks, duplicate manifests, or compatibility copies remain at the root.

## Path migration

Moves use Git-aware operations so history remains traceable. All active path consumers must be updated in the same migration:

- CI working directories and cache dependency paths;
- Docker build contexts, COPY sources, Compose paths, and static container tests;
- Firebase output paths and FlutterFire launch configuration;
- VS Code Flutter program paths and working directories;
- repository scripts and architecture checks;
- Flutter tests that read `supabase/` or other repository-level fixtures;
- backend tests that calculate the repository or backend root;
- live documentation links and runnable command examples;
- ignore patterns for generated Flutter and backend artifacts.

Historical prose that intentionally describes the old state may remain unchanged when editing it would rewrite history. Active instructions, status documents, and runnable commands must use the new layout.

## Dependency boundaries

Automated architecture tests enforce these invariants:

- Flutter production code lives under `app/lib/` and cannot import backend, website, or media-worker implementation files.
- Nest production code lives under `backend/apps/` and `backend/libs/` and cannot import Flutter, website, media-worker, or Supabase Edge Function implementation files.
- `supabase/` is the only owner of migration and Edge Function source.
- `website/` and `media-worker/` remain independent package roots.
- project manifests and lockfiles exist only in their owning project, except for intentionally independent nested tooling already present.

## Compatibility and failure handling

The restructuring is one dedicated implementation sequence and commit series before Phase 2. If a move breaks a gate, the failure is fixed within the structure work; Phase 2 does not begin against a partially migrated tree.

No generated directory is committed. No database migration is created. No environment secret is moved into source control. No deployed resource is changed. No symlink masks an unresolved path dependency.

## Verification

The migration is complete only when the following pass from the new layout:

### Flutter

- `flutter pub get`;
- `flutter analyze lib/`;
- `flutter test test/architecture_test.dart`;
- the domain-purity script/gate;
- the existing selected feature tests used by CI;
- migration-layout or fixture tests that inspect root `supabase/` paths.

### Backend

- frozen pnpm install;
- oxlint;
- all unit, architecture, and e2e tests;
- API and worker builds plus compiled runtime-import verification;
- Compose configuration validation;
- API/worker image builds;
- non-root runtime identity, API liveness, and bounded SIGTERM shutdown.

### Other projects and repository

- media-worker dependency install/build remains green;
- the Supabase CLI finds `supabase/config.toml` from the repository root;
- repository scans find no active command or configuration that assumes the former root-level Flutter or Nest locations;
- `git diff --check` passes and the worktree is clean after commit.

## Sequencing into Phase 2

The repository-boundary migration and Phase 2 infrastructure are separate architectural deliverables.

After this migration is green and committed, Phase 2 receives a separate design and implementation plan for validated Supabase/PostgreSQL server connectivity, Redis/BullMQ foundations, dependency-aware readiness, secret-safe configuration, bounded pools/retries, and integration tests.

Phase 2 does not include chat endpoints, Socket.IO behavior, notification delivery, Flutter transport migration, or silent schema changes. Any required database migration triggers its own explicit design gate.
