# Migration SQL style

This project's layout follows the current [Supabase Postgres SQL style guide](https://supabase.com/docs/guides/ai-tools/ai-prompts/code-format-sql), with vertically aligned column types as a project preference. [SQLFluff's layout guidance](https://docs.sqlfluff.com/en/stable/configuration/layout.html) informs spacing, line breaks, and indentation. Sources reviewed on 2026-09-21.

SQL has multiple valid styles. These are the conventions we use consistently:

- Lowercase keywords and types; preserve identifiers and literal values.
- Two spaces per indentation level; spaces rather than tabs.
- Align each table's data types after its longest column name.
- Target 88 characters for executable SQL. Expand complex expressions instead of squeezing them onto one line. Long identifiers, literal strings, and explanatory comments can exceed the target.
- Separate foreign-key clauses, trigger clauses, and policy clauses onto their own lines.
- Put function parameters on separate lines. Keep function attributes at the same indentation as `create function`, and indent the body by its nesting depth.
- Keep small expressions compact, including `(select auth.uid())`. Expand nested calls and larger queries according to their structure.
- Use trailing commas, one blank line between statements, and consistent section dividers.
- Preserve explanatory comments. Place `comment on` beside the object it documents.

```sql
-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.example (
  id           uuid primary key,
  owner_id     uuid not null
    references auth.users (id)
    on delete cascade,
  display_name text not null,
  created_at   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "example_read_owner"
  on public.example
  for select
  to authenticated
  using ((select auth.uid()) = owner_id);
```

## Recommended order for new migrations

1. Header: purpose and dependencies.
2. Prerequisites: extensions, schemas, types, and helpers needed by table definitions.
3. Table definitions/alterations and constraints.
4. Enable row-level security on new tables in exposed schemas.
5. Indexes.
6. Functions: helpers before callers, including RPCs and trigger functions.
7. Triggers.
8. Policies: SELECT, INSERT, UPDATE, DELETE.
9. Permissions: table/sequence grants and revokes.
10. Integrations: Realtime publications, storage, and scheduled jobs.

Omit unused sections. Dependencies override the visual order:

- Functions used by defaults, generated columns, or constraints precede tables.
- Trigger and policy helpers precede their consumers.
- Keep function grants/revokes immediately beside their definition, especially for SECURITY DEFINER functions.
- Define views after their referenced objects, under `Views`.
- Label backfills and required reference-data inserts `Data changes`; document their placement relative to constraints and triggers.
- Preserve conditional DO blocks and replacement operations. Mixed blocks use `Dependency-ordered operations`.
- Storage bucket inserts use `Integrations`; storage policies use `Policies`.

## Historical migrations

Formatting preserves filenames, statement order, object names, literal values, and explanatory comments. It does not move RLS, grants, backfills, or function/trigger replacements. A section can recur when the existing execution sequence returns to it.

Use schema-qualified names for new SQL. Historical unqualified references remain unchanged because adding a schema could change name resolution. Applied files are history: changing their formatting does not reapply them to a deployed database. Consolidation and semantic changes require separate dependency review and database replay.

## Format and verify

Requirements: Node.js 20+, Python 3.9+, and the committed dependency lockfiles.

```sh
npm ci --prefix scripts/database --ignore-scripts
python3 -m venv /tmp/matchday-sql-format
/tmp/matchday-sql-format/bin/pip install -r scripts/database/requirements-format.txt

/tmp/matchday-sql-format/bin/python scripts/database/format_migrations.py
/tmp/matchday-sql-format/bin/python scripts/database/format_migrations.py --check
/tmp/matchday-sql-format/bin/python -m unittest discover -s scripts/database -p 'test_format_migrations.py'
flutter test test/supabase/migration_layout_test.dart
```

The wrapper uses pinned Prettier and [prettier-plugin-sql-cst](https://github.com/nene/prettier-plugin-sql-cst), configured in `scripts/database/sql-format.json`. Prettier provides structured line wrapping, including PL/pgSQL bodies. The wrapper adds table alignment, section dividers, declaration layout, and tested compatibility handling for PostgreSQL scalar-subquery policies and `unique nulls not distinct` constraints.

The plugin's PostgreSQL/PL/pgSQL support is experimental. **Run the Python wrapper, not an unguarded Prettier write over migrations.** Before writing anything, the wrapper compares PostgreSQL parse trees and routine-body tokens against the input, including literal values and quoted identifiers. It rejects unsupported formatting, changed semantics, and output that does not converge to a stable format. It also checks for concurrent migration edits before writing.

`--check` writes nothing and exits nonzero for formatting drift or a validation failure. It checks layout, not dependency order. For semantic changes, also replay migrations on a disposable local database and run the relevant database tests.

## Dependency references

- [Supabase migration workflow](https://supabase.com/docs/guides/deployment/database-migrations)
- [PostgreSQL CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html)
- [PostgreSQL CREATE POLICY](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [PostgreSQL CREATE FUNCTION](https://www.postgresql.org/docs/current/sql-createfunction.html)
