# Migration SQL style

Migrations live in `supabase/migrations/`. Use lowercase SQL keywords, two-space
indentation, snake_case names, schema-qualified object references, one column or
function parameter per line, and a blank line between statements. Align table
column data types vertically: pad names with spaces to the longest column name
in that table. Use spaces, not tabs. Keep comments
that explain intent and dependencies. Place `comment on` statements beside the
object they describe. Do not rename existing objects to satisfy style rules.

```sql
create table public.example (
  id           uuid primary key,
  display_name text,
  created_at   timestamptz not null default now()
);
```

## Recommended order for new migrations

1. Header: purpose and dependencies.
2. Prerequisites: extensions, schemas, types, and helpers used by table definitions.
3. Table definitions/alterations and constraints.
4. Enable row-level security on newly created tables in exposed schemas.
5. Indexes.
6. Functions: helpers before callers, including RPCs and trigger functions.
7. Triggers.
8. Policies: SELECT, INSERT, UPDATE, DELETE.
9. Permissions: table/sequence grants and revokes.
10. Integrations: Realtime publications, storage, and scheduled jobs.

Omit sections that are not needed. Dependencies always override this order:

- Functions used by defaults, generated columns, or constraints precede tables.
- Trigger and policy helpers must exist before their consumers.
- Keep function grants/revokes immediately beside the function definition,
  especially for SECURITY DEFINER functions. Do not postpone privilege hardening
  merely to put it under a later heading.
- Define views after their referenced objects. Label them `Views`.
- Label backfills and required reference-data inserts `Data changes`. Position
  them deliberately relative to constraints and triggers; document the reason.
- Keep conditional DO blocks and replacement operations together. The formatter
  labels mixed blocks `Dependency-ordered operations` because their contents can
  span multiple categories.
- Storage bucket inserts belong under `Integrations`; security objects on storage
  tables still belong under their corresponding security sections.

## Historical migrations

The formatting pass preserves filenames, SQL statement order, identifiers,
literal values, and existing comments. It does not move RLS, grants, backfills,
or function/trigger replacements in historical files. Existing unqualified
references are preserved because adding a schema can change name resolution.

Sections use `-- Section: <category>` consistently. A category may recur with
`(continued)` when the existing execution sequence returns to it. These labels
describe the SQL rather than instructing an automatic sort. Original descriptive
subheadings and dependency explanations remain.

Applied migrations are history. Reordering, consolidating, or changing SQL is a
separate schema change that requires dependency review and database replay.
Formatting an applied file does not reapply it to a deployed database.

## Formatter and check

Use [pgFormatter 5.11](https://github.com/darold/pgFormatter/releases/tag/v5.11)
and Python 3.9+ with the pinned PostgreSQL parser:

```sh
python3 -m venv /tmp/matchday-sql-format
/tmp/matchday-sql-format/bin/pip install -r scripts/database/requirements-format.txt

# Install pgFormatter 5.11 using its upstream instructions, then:
export PG_FORMAT=/path/to/pgFormatter-5.11/pg_format
/tmp/matchday-sql-format/bin/python scripts/database/format_migrations.py
/tmp/matchday-sql-format/bin/python scripts/database/format_migrations.py --check
/tmp/matchday-sql-format/bin/python -m unittest discover -s scripts/database -p 'test_format_migrations.py'
flutter test test/supabase/migration_layout_test.dart
```

The wrapper pins the formatter version and ignores personal pgFormatter config.
It supplies lowercase keyword/type, two-space indentation, and vertical table
column alignment settings, lays out
function parameters, and creates section labels without sorting statements.
Embedded dollar-quoted SQL and multiline literals are protected from reformatting.
Formatting must converge to repeatable output before any file is written.

Before writing any file, it compares PostgreSQL parse trees for every migration.
It also compares routine-body tokens, including literal values and quoted names.
Only source positions, whitespace, comments, and unquoted token case are ignored.
Any mismatch aborts the entire pass before writing. `--check` writes nothing and
exits nonzero for drift or a semantic mismatch. It enforces formatting and section
labels, not dependency order; dependency review remains required for SQL changes.

For semantic changes, additionally replay migrations on a disposable local
database and run the applicable database tests. Parser equivalence is appropriate
for a formatting-only pass; it does not validate runtime authorization or data.

## References

- [Supabase migration workflow](https://supabase.com/docs/guides/deployment/database-migrations)
- [PostgreSQL CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html)
- [PostgreSQL CREATE POLICY](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [PostgreSQL CREATE FUNCTION](https://www.postgresql.org/docs/current/sql-createfunction.html)
