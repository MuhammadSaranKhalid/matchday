# Matchday

Matchday is a multi-project cricket platform. The repository root coordinates five independent runtime boundaries; it does not own application source or package manifests.

## Repository layout

| Directory | Owner | Primary tooling |
|---|---|---|
| `app/` | Flutter mobile and web client | Flutter, Dart, Riverpod |
| `backend/` | NestJS API and background worker | Node 24, pnpm, NestJS |
| `supabase/` | PostgreSQL migrations and Edge Functions | Supabase CLI, Deno |
| `website/` | Standalone Next.js website | Node, npm |
| `media-worker/` | Standalone media-processing service | Node 22, npm |
| `scripts/`, `docs/`, `.github/` | Cross-project governance | Bash, GitHub Actions |

The website and media worker are not backend packages. Supabase remains the only owner of database migrations and Edge Functions.

## Quick start

### Flutter app

```sh
cd app
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

VS Code launch configurations set `app/` as the Flutter working directory automatically.

### Nest backend

```sh
cd backend
corepack enable
corepack pnpm install --frozen-lockfile
corepack pnpm build
docker compose up --build
```

The Compose project contains the API, worker, and a private Redis service. It does not start Supabase or either website.

### Supabase

```sh
supabase --workdir . status
supabase --workdir . db reset
```

Run Supabase commands from the repository root so the CLI uses `supabase/config.toml`.

### Website and media worker

```sh
npm --prefix website ci
npm --prefix website run build

npm --prefix media-worker ci
npm --prefix media-worker run build
```

## Quality gates

Run the structural contract first:

```sh
bash scripts/verify_repository_boundaries.sh
```

Then run project-local gates from the owning project directory:

```sh
cd app
flutter analyze lib/
flutter test test/architecture_test.dart
bash scripts/check_domain_purity.sh
flutter test test/supabase/migration_layout_test.dart
flutter test test/features/posts/
```

```sh
cd backend
corepack pnpm lint
corepack pnpm test
corepack pnpm test:architecture
corepack pnpm test:e2e
corepack pnpm build
docker compose config
```

## Architecture notes

The Flutter app follows Presentation → Domain ← Data. Its detailed rules are in `CLAUDE.md` and `BEST_PRACTICES.md`; paths such as `lib/` and `test/` in those app-specific documents are relative to `app/`.

The backend architecture, deployment model, protocol contracts, and current implementation status are under `docs/backend/`. Repository boundary decisions and their implementation plan are under `docs/superpowers/`.

Database schema changes belong only in `supabase/migrations/`. A migration should remain immutable after deployment and normally own one table. Follow `docs/database/migration-style.md` for formatting and validation.
