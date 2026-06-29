---
name: edge-functions
description: Write Supabase Edge Functions (Deno) following this repo's established conventions. Use whenever creating or modifying anything under supabase/functions/ - new endpoints (e.g. list-open-challenges), changes to existing ones (search-teams, record-ball, send-push...), or shared utilities in _shared/.
---

# Edge functions in MatchDay

Nine functions exist (record-ball, search-teams, team-place-facets, send-push, send-match-request, list-my-chats, list-my-matches, list-follow-list, + _shared). READ at least one similar existing function fully before writing a new one - the conventions below are extracted from them, but the code is the source of truth.

## Layout & naming
- One kebab-case folder per function: `supabase/functions/<verb-noun>/index.ts`.
- Shared helpers live in `_shared/` (`http.ts`, `db.ts`, `scoring/`). Extend _shared rather than duplicating helpers.

## Request handling order (the record-ball bug rule)
1. **`corsPreflight()` FIRST, before any auth check.** An OPTIONS preflight carries no Authorization header - an auth gate at the top 401s it and breaks web. This exact bug already happened once.
2. Then auth, then input validation, then work.
3. Every response goes through `_shared/http.ts` `json(status, body)` so the CORS headers (`Access-Control-Allow-Origin: *`, allowed headers/methods) are always present.

## Two database access modes (_shared/db.ts) - choose deliberately
- **`userClient(authHeader)`** - supabase-js acting AS the caller (forwards their JWT). RLS + `auth.uid()` apply, so server-side rules like `_can_score_match()` see the real user. Use for authorization checks and user-scoped reads/writes.
- **`db()`** - pooled DIRECT postgres.js connection for real multi-statement TRANSACTIONS (lock -> check version -> write -> commit), which PostgREST cannot do. Bypasses RLS - every authorization decision must already have happened via userClient or explicit checks. Connection rules are encoded in db.ts and must not be "simplified": `prepare: false` (required for Supavisor transaction mode :6543), small pool (`max: 3`), idle/lifetime caps, `MATCH_DB_URL` env override, host-only logging (never credentials).

## Conventions
- Handler: `Deno.serve()` with standard web Request/Response (official pattern).
- Prefer Web APIs / Deno core over external deps (fetch, not axios). External deps only via pinned `npm:` / `jsr:` specifiers (e.g. `npm:postgres@3.4.5`) - never bare specifiers; `@ts-ignore` where Deno resolves at deploy.
- Functions must NOT import from each other - shared code goes in `_shared/` only (official Supabase rule).
- `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` are auto-injected env vars; custom secrets via `supabase secrets set` + `Deno.env.get(...)`. Never hardcode or log credentials.
- JWT verification is per-function config (`verify_jwt` in config.toml / `--no-verify-jwt`) - check what the existing functions use before adding a new one.
- Design short-lived and idempotent (edge runtime has CPU-time limits and cold starts); heavy work belongs in the database (RPC) or a worker, not the function.
- Validate inputs early; return `json(400, { error: ... })` with a stable error shape matching existing functions.
- List endpoints: keyset pagination (cursor on a stable sort key), never offset.
- Geo endpoints (search-teams, team-place-facets, future list-open-challenges): follow the geo-discovery skill - ST_DWithin prefilter, decay-blend ranking, facets from our own tables.

## Flutter side
The Dart remote data source calls functions via `supabase.functions.invoke('<name>', body: ...)`, throws raw exceptions on non-2xx, returns DTOs. Repository translates to Failures.

## Deploy & test
- Deploy is the user's call (Supabase CLI/MCP); provide the command, don't run unasked.
- After changing _shared/, list which functions consume the changed helper - they ALL redeploy together.
