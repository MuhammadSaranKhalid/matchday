# Matchday Repository Boundaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Flutter client into `app/` and the Nest platform into `backend/` while keeping Supabase, website, and media-worker as independent top-level projects with every existing gate operational.

**Architecture:** The repository root becomes an orchestrator. Each runnable project owns its manifest, source, tests, generated outputs, and local tooling; root CI and documentation invoke projects through explicit working directories. Supabase remains the single root-level owner of migrations and Edge Functions.

**Tech Stack:** Git, Flutter/Dart, Node 24, pnpm 9.15, NestJS 12, Docker Compose, Supabase CLI 2.109.1, GitHub Actions, Bash.

**Spec:** `docs/superpowers/specs/2026-09-28-repository-boundaries-design.md`

## Global Constraints

- Work on the existing `backend` branch in the primary checkout; do not merge or push without a new explicit request.
- Preserve `website/`, `media-worker/`, and `supabase/` as independent top-level projects.
- Make no schema, Edge Function behavior, application behavior, deployed-service, or secret changes.
- Use Git-aware moves for tracked files; do not copy-and-delete source trees or retain compatibility symlinks.
- Do not commit generated Flutter, Node, Docker, or Supabase runtime output.
- Active commands must run from the owning project directory; the root remains orchestration/documentation only.
- Phase 2 must not begin until this plan is green, reviewed, and committed.

## Review Focus

- A Flutter test that reads migrations after moving to `app/test/` must resolve the root `supabase/` directory instead of silently inspecting a nonexistent `app/supabase/`.
- Firebase/FlutterFire output paths must still target the moved Android, iOS, and Dart files under `app/`.
- Docker COPY paths and build context must remain valid when the Dockerfile and Node workspace move together under `backend/`.
- CI cache keys and commands must use project-local lockfiles and working directories rather than the former repository root.
- Architecture enforcement must reject accidental reintroduction of root-level Flutter/Nest sources without matching generated directories or historical prose.

---

### Task 1: Add Repository-Boundary Characterization

**Files:**
- Create: `scripts/verify_repository_boundaries.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: the approved target layout from the design spec.
- Produces: `scripts/verify_repository_boundaries.sh`, a root-level zero-output-on-success structural gate used locally and by CI.

- [ ] **Step 1: Capture clean baselines before moving files**

Run:

```sh
flutter analyze lib/
flutter test test/architecture_test.dart
corepack pnpm lint
corepack pnpm test
corepack pnpm test:architecture
corepack pnpm test:e2e
corepack pnpm build
npm --prefix media-worker ci
npm --prefix media-worker run build
supabase --workdir . --version
```

Expected: all existing gates pass. Record exact counts and any pre-existing failures before the first move.

- [ ] **Step 2: Write the failing boundary script**

Create an executable Bash script that asserts:

- `app/pubspec.yaml`, `app/lib/main.dart`, `app/test/architecture_test.dart`, and every Flutter platform directory exist;
- `backend/package.json`, `backend/apps/api`, `backend/apps/worker`, `backend/libs/platform`, and backend test roots exist;
- `supabase/config.toml`, `website/package.json`, and `media-worker/package.json` remain at the repository root;
- root `pubspec.yaml`, `lib`, Flutter platform directories, `package.json`, `apps`, `libs`, `Dockerfile`, and `docker-compose.yml` do not exist;
- root generated paths and project-local generated paths remain ignored.

The script must derive the repository root from its own location so callers may run it from any directory.

- [ ] **Step 3: Run the script to verify RED**

Run: `bash scripts/verify_repository_boundaries.sh`

Expected: FAIL because `app/` and `backend/` do not exist yet.

- [ ] **Step 4: Generalize ignore rules for nested projects**

Update `.gitignore` so Flutter and Node generated paths are ignored beneath `app/` and `backend/` without ignoring tracked source. Retain all existing secret, backup, and worktree protections.

- [ ] **Step 5: Commit the characterization gate**

```sh
git add scripts/verify_repository_boundaries.sh .gitignore
git commit -m "test: characterize repository boundaries"
```

---

### Task 2: Move the Flutter Application

**Files:**
- Move to `app/`: `lib/`, `assets/`, `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`
- Move to `app/`: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `devtools_options.yaml`, `.metadata`, `.firebaserc`, `firebase.json`, `config/`, `tool/`
- Move to `app/test/`: all Flutter/Dart tests currently under `test/`, excluding the backend TypeScript suites named in Task 3
- Move to `app/scripts/`: `scripts/check_domain_purity.sh`, `scripts/verify_architecture.sh`
- Modify: `app/firebase.json`
- Modify: `app/test/supabase/migration_layout_test.dart`
- Modify: other moved Dart tests returned by `rg -l "supabase/" app/test --glob '*.dart'`
- Modify: `.vscode/launch.json`

**Interfaces:**
- Consumes: root `supabase/` fixtures and the current Flutter package contract.
- Produces: a self-contained Flutter package runnable with `cd app && flutter ...`.

- [ ] **Step 1: Reserve backend tests, then move Flutter files with Git history**

Create `backend/test/` temporarily and move these backend-owned paths before moving the remaining test tree:

- `test/unit/platform/`;
- `test/unit/worker/`;
- `test/e2e/`;
- `test/architecture/backend-dependencies.spec.ts`;
- `test/architecture/container-foundation.spec.ts`.

Then move the remaining `test/` directory to `app/test/` and move all other Flutter-owned paths listed above into `app/`.

- [ ] **Step 2: Update Flutter-owned relative paths**

Adjust Firebase outputs to `android/`, `ios/`, and `lib/` relative to `app/firebase.json`. Update migration-layout and fixture tests to derive the repository root and read `../supabase/`. Update moved shell scripts so their root is `app/` and make no assumptions about the caller's current directory.

- [ ] **Step 3: Update editor launch configuration**

Point Flutter launch entries to `app/lib/main.dart` and set the Flutter working directory to `app/`. Preserve unrelated editor settings.

- [ ] **Step 4: Verify Flutter from its new package root**

Run:

```sh
cd app
flutter pub get
flutter analyze lib/
flutter test test/architecture_test.dart
bash scripts/check_domain_purity.sh
flutter test test/supabase/migration_layout_test.dart
flutter test test/features/posts/
```

Expected: the same behavior and counts as the baseline; migration tests read the root Supabase project.

- [ ] **Step 5: Commit the Flutter move**

Stage only Flutter moves and their direct path repairs, then commit:

```sh
git commit -m "refactor(app): move Flutter client into app"
```

---

### Task 3: Move the Nest Backend

**Files:**
- Move to `backend/`: `apps/`, `libs/`, `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`; retain the backend tests already reserved at `backend/test/` by Task 2
- Move to `backend/`: `nest-cli.json`, `oxlint.json`, `tsconfig.json`, `tsconfig.build.json`, `vitest.config.ts`, `.nvmrc`
- Move to `backend/`: `Dockerfile`, `docker-compose.yml`, `.dockerignore`
- Modify: `backend/test/architecture/backend-dependencies.spec.ts`
- Modify: `backend/test/architecture/container-foundation.spec.ts`
- Modify: `backend/Dockerfile`
- Modify: `backend/docker-compose.yml`
- Modify: backend status/deployment documentation paths under `docs/backend/`

**Interfaces:**
- Consumes: backend-local Node manifests, source, tests, and container context.
- Produces: a self-contained Nest workspace runnable with `cd backend && corepack pnpm ...` and `docker compose -f backend/docker-compose.yml --project-directory backend ...`.

- [ ] **Step 1: Move the backend workspace with Git history**

Move every backend-owned path listed above beneath `backend/`. Ensure the previously reserved backend tests land at `backend/test/` rather than a nested duplicate.

- [ ] **Step 2: Repair root calculations and dependency guards**

Update backend architecture tests so `process.cwd()` means the backend root. Guards must explicitly reject imports resolving into `../app`, `../website`, `../media-worker`, or `../supabase/functions`, while allowing shared protocol documentation only through data/contracts intentionally added in later phases.

- [ ] **Step 3: Repair container contexts and static assertions**

Keep Docker COPY paths backend-local. Compose builds must use the `backend/` project directory when invoked from the repository root, and static architecture tests must assert that behavior. No Docker instruction may copy the Flutter app, root Supabase project, website, or media worker.

- [ ] **Step 4: Verify the backend from its new workspace root**

Run:

```sh
cd backend
corepack pnpm install --frozen-lockfile
corepack pnpm lint
corepack pnpm test
corepack pnpm test:architecture
corepack pnpm test:e2e
corepack pnpm build
docker compose config
```

Expected: all gates and compiled runtime imports pass with the same or greater test counts.

- [ ] **Step 5: Build and smoke-test moved containers**

From `backend/`, build both targets, start API and worker, assert API liveness, UID 1000 for both processes, and shutdown inside the configured grace period. Run `docker compose down` without deleting unrelated volumes.

- [ ] **Step 6: Commit the backend move**

```sh
git commit -m "refactor(backend): move Nest platform into backend"
```

---

### Task 4: Rewire Root Orchestration and Documentation

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `BEST_PRACTICES.md`
- Modify: `.gitignore`
- Modify: root scripts that execute Flutter/backend commands
- Modify: active documents returned by scoped path searches
- Test: `scripts/verify_repository_boundaries.sh`

**Interfaces:**
- Consumes: `app/`, `backend/`, root `supabase/`, `website/`, and `media-worker/` project entrypoints.
- Produces: root CI/documentation that orchestrates each project without owning runtime files.

- [ ] **Step 1: Rewire GitHub Actions**

Set Flutter steps to `working-directory: app` and update Flutter cache paths. Set backend steps to `working-directory: backend` and cache `backend/pnpm-lock.yaml`. Keep media-worker at `media-worker/`. Add the root boundary script as an early job/step. Do not add deployment or credentials.

- [ ] **Step 2: Rewrite active root command documentation**

Update the root README to describe the multi-project layout and show explicit project commands. Update active repository instructions and architecture references from `lib/...` to `app/lib/...`, Flutter `test/...` to `app/test/...`, and backend `apps|libs|test` to `backend/...` where the paths are repository-relative.

Historical status evidence may retain command output as history, but clickable file references and commands presented as current must be valid.

- [ ] **Step 3: Repair cross-project scripts**

Update root-maintained scripts such as notification-icon validation to resolve `app/assets/` and root `supabase/` independently. Verify scripts work regardless of current directory.

- [ ] **Step 4: Run structural and stale-path scans**

Run:

```sh
bash scripts/verify_repository_boundaries.sh
rg -n "working-directory: (app|backend)|cache-dependency-path: (app|backend)/" .github/workflows
rg -n "flutter (analyze|test|pub)|corepack pnpm|docker compose" README.md CLAUDE.md BEST_PRACTICES.md docs scripts
```

Review every match that still assumes the old root. Exclude only clearly labeled historical evidence, generated output, and the migration plan/spec themselves.

- [ ] **Step 5: Verify independent projects remain independent**

Run:

```sh
npm --prefix media-worker ci
npm --prefix media-worker run build
npm --prefix website run build
supabase --workdir . --version
test -f supabase/config.toml
```

Expected: media-worker and website builds pass; Supabase CLI resolves the unchanged root project.

- [ ] **Step 6: Commit orchestration changes**

```sh
git commit -m "ci: orchestrate separated project roots"
```

---

### Task 5: Final Compatibility Gate and Status

**Files:**
- Modify: `docs/backend/IMPLEMENTATION_STATUS.md`
- Modify: `docs/superpowers/specs/2026-09-28-repository-boundaries-design.md`
- Test: all project and container gates

**Interfaces:**
- Consumes: every relocated project and root orchestration path.
- Produces: an evidence-backed clean boundary migration and the safe starting point for the separate Phase 2 design.

- [ ] **Step 1: Run the complete Flutter gate**

From `app/`, run frozen/resolved dependencies, `flutter analyze lib/`, architecture tests, domain purity, migration-layout tests, and the selected CI feature tests.

- [ ] **Step 2: Run the complete backend gate**

From `backend/`, run frozen pnpm install, lint, unit, architecture, e2e, compiled builds/import verification, Compose config, target image builds, non-root identity, health, and SIGTERM smoke.

- [ ] **Step 3: Run independent-project and Supabase checks**

Build `website/` and `media-worker/`. Use the installed CLI's discovered `--workdir` flag to confirm the root Supabase project configuration is found. Do not start, reset, link, push, or mutate a Supabase project for this path-only change.

- [ ] **Step 4: Inspect the final repository**

Run:

```sh
bash scripts/verify_repository_boundaries.sh
git diff --check
git status --short
git diff --stat f47d932..HEAD
git diff --summary f47d932..HEAD
```

Expected: Git recognizes moves where content is unchanged, no generated outputs are tracked, and only boundary-related source/config/documentation changes appear after the Phase 1 foundation.

- [ ] **Step 5: Update status evidence**

Record the final tree, exact verification commands/results, no database changes, no deployed-service changes, remaining path risks, and Phase 2 as the next unstarted gated design. Change the structure spec status to implemented only after all evidence exists.

- [ ] **Step 6: Commit completion evidence**

```sh
git commit -m "docs: record repository boundary migration"
```

## Self-Review Record

- Spec coverage: project ownership, physical moves, commands, CI, Docker, Firebase, Supabase fixture paths, documentation, dependency boundaries, and phase sequencing each have an owning task.
- Step scan: each step performs one move, path repair, verification group, or commit-sized result; no implementation body is prescribed beyond the structural assertions.
- Type/path consistency: `app/`, `backend/`, root `supabase/`, `website/`, and `media-worker/` are named identically throughout.
- Review-focus coverage: Supabase fixture resolution is in Task 2; Docker contexts in Task 3; CI/cache paths and Firebase in Tasks 2/4; boundary regression is in Tasks 1/4/5.
- Proportion: the plan is detailed because the migration crosses five toolchains, but it does not combine Phase 2 implementation with the path move.
