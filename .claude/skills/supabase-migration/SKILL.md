---
name: supabase-migration
description: Write Supabase/PostgreSQL migrations following this repo's conventions. Use whenever creating or editing files in supabase/migrations/, adding tables, RLS policies, RPCs, triggers, indexes, generated columns, or geo/PostGIS columns. Also use when designing schema for a new feature before any SQL is written.
---

# Writing migrations for MatchDay

## Before writing SQL
1. List `supabase/migrations/` and read the 2-3 most recent migrations plus any touching the same tables — match their naming, RLS phrasing, and trigger style exactly.
2. One concern per migration file. Filename: repo's timestamp+slug pattern (copy the latest file's format).

## Table template (adapt, don't paste blindly)
- `id uuid primary key default gen_random_uuid()`
- FKs with explicit `on delete` (cascade for owned children, restrict/set null where history matters)
- `created_at` / `updated_at timestamptz not null default now()` + the existing `set_updated_at` trigger helper
- `alter table ... enable row level security;` + policies immediately — a table without RLS never ships
- Write policies always include `with check`, not just `using`

## RLS conventions
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
- Verb_noun naming (`record_ball`). Validate inputs first, raise meaningful exceptions, keep them transactional. SECURITY DEFINER only with pinned `search_path`.

## Realtime / TTL
- If Flutter subscribes to the table, include the publication + realtime authorization changes (chats/messages precedent).
- Anything with expiry semantics follows the match-requests cron pattern.

## After writing
- Hand the migration to the user to apply (Supabase MCP/CLI); don't apply unasked.
- Recommend a `db-reviewer` agent pass for anything non-trivial.
- If the schema realizes a design-doc decision, note the Dn reference in a SQL comment.
