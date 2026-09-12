---
name: supabase-migration
description: Write Supabase/PostgreSQL migrations following this repo's conventions. Use whenever creating or editing files in supabase/migrations/, adding tables, RLS policies, RPCs, triggers, indexes, generated columns, or geo/PostGIS columns. Also use when designing schema for a new feature before any SQL is written.
---

# Writing migrations for MatchDay

## Before writing SQL
1. Read `CLAUDE.md` §12.0, list `supabase/migrations/`, and read the canonical table file plus its dependencies before editing.
2. This project is pre-production: edit the source declaration rather than append schema patches. Each table has exactly one `CREATE TABLE` across the directory, in its own `number_table_name.sql` file. Never declare multiple tables in a file or repeat a declaration in a later `DO` block.
3. Keep columns, indexes, constraints, triggers, RLS policies and grants with their table. Zero-table files are allowed for shared helpers and integration that must follow both related tables. Document genuine cycles that require a deferred FK, policy or lifecycle trigger; keep the table declaration and independent objects in the table file, and enable RLS there immediately.
4. All enums live in `20260101000000_shared_helpers.sql`; edit their value lists there rather than append `ALTER TYPE ... ADD VALUE` migrations.

## Table template (adapt, don't paste blindly)
- `id uuid primary key default gen_random_uuid()`
- FKs with explicit `on delete` (cascade for owned children, restrict/set null where history matters)
- `created_at` / `updated_at timestamptz not null default now()` + the existing `set_updated_at` trigger helper
- `alter table ... enable row level security;` + policies immediately — a table without RLS never ships
- Write policies always include `with check`, not just `using`
- Every policy names its roles: `to authenticated`, or `to anon, authenticated`
  only when an anonymous user can actually satisfy a branch of the expression
- Index every FK column — Postgres does not do it for you (advisor 0001)

## RLS conventions
- `(select auth.uid())`, NEVER a bare `auth.uid()` — the subquery is an InitPlan
  evaluated once per statement instead of once per row (advisor 0003). Wrap
  SECURITY DEFINER helpers the same way: `(select public.is_team_manager(id))`.
- Owner-private: `auth.uid() = user_id` for all.
- Team-scoped: membership subquery against `team_members` (copy the existing pattern, don't reinvent).
- World-readable rows only when a design doc says so (e.g. open+active match-pool listings) and only for `select`.

## Geo (PostGIS) — the project recipe (docs/search-feature-design.md)
- Store `location jsonb` (place fields) + a generated `location_point geography(point, 4326)` STORED column.
- Index: `create index ... using gist (location_point);`
- Query proximity with `ST_DWithin`; rank with distance decay — never a hard radius cutoff when a text query is present.
- Text search: normalized generated column `search_name` (lower + unaccent) with a `gin (search_name gin_trgm_ops)` index; match with `word_similarity` / `<%`, not plain `similarity`.

## JSON validation
- Use `pg_jsonschema` check constraints for structured jsonb (match-format precedent); pair with STORED generated columns for hot fields.

## RPCs
- Verb_noun naming (`record_ball`). Validate inputs first, raise meaningful exceptions, keep them transactional. SECURITY DEFINER only with pinned `search_path` (`set search_path = public, pg_temp`) — advisor 0011.
- End every function with `revoke all on function ... from public;` then grant to
  `authenticated` (and `anon` only with a recorded reason). Postgres grants
  EXECUTE to PUBLIC automatically and anon holds PUBLIC, so a SECURITY DEFINER
  function is anon-callable — and therefore RLS-bypassing — unless you revoke
  (advisors 0028/0029).
- Views: `create or replace view ... with (security_invoker = on)`. Without it a
  view runs as its owner and ignores the base table's RLS (advisor 0010). The
  option is not inherited by a later `create or replace` — restate it.

## Realtime / TTL
- If Flutter subscribes to the table, include the publication + realtime authorization changes (chats/messages precedent).
- Anything with expiry semantics follows the match-requests cron pattern.

## Ordering
- Migration numbers encode DEPENDENCY order, not dates. Referenced objects must
  exist earlier in the same file or in a lower-numbered file. Renumber rather
  than add a late schema patch. Use a documented zero-table integration file
  only when the relationship must follow both declarations.
- PL/pgSQL can defer relation checks until execution. A clean `supabase db reset`
  verifies replay order and definitions checked at CREATE time; it does not
  exercise uncalled RPCs or triggers. Run affected paths as separate checks.
- `CREATE INDEX CONCURRENTLY` is unavailable: the CLI wraps each migration in a
  transaction.

## After writing
- Run `flutter test test/supabase/migration_layout_test.dart` to guard table ownership and filenames.
- Run `supabase db reset`, then `supabase/snippets/advisors.sql`, using a disposable local database if existing data must be preserved. Check affected RPC and trigger paths too.
- Hand the migration to the user to apply (Supabase MCP/CLI); don't apply unasked.
- Recommend a `db-reviewer` agent pass for anything non-trivial.
- If the schema realizes a design-doc decision, note the Dn reference in a SQL comment.
