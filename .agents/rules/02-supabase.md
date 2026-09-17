---
trigger: model_decision
description: Rules for Supabase Postgres schemas, migrations, RLS policies, RPC functions, triggers, and Edge Functions.
---

# Supabase Engineering Rules

Match Day uses **Supabase PostgreSQL** as its authoritative relational system of record. Follow these rules for all database, migration, and backend integration tasks.

---

## 1. Inspection Pass Before Mutation (Mandatory)

Before proposing or writing any SQL, schema change, trigger, or Edge Function:
1. **Inspect the real schema via MCP or files**:
   - Check existing migrations in `supabase/migrations/`.
   - Check documented routines in `docs/database/routines.md`.
   - Check foreign keys and relationships in `docs/database/relationships.md`.
   - Check table catalogues in `docs/database/catalogues.md`.
2. **Never assume table structure or column names**:
   - Check whether a column or table already exists before creating a duplicate.
   - For example, `match_deliveries` carries one column per fact (`runs_off_bat`, `delivery_type`, `recorded_by`). Aliases like `runs_scored` or `ball_type` were intentionally eliminated.
3. **Check for existing triggers and functions** before writing new ones to avoid duplicate execution cycles.

---

## 2. Row-Level Security (RLS) is Non-Negotiable

Every single table in the `public` schema must have RLS enabled and tested:
```sql
alter table <name> enable row level security;
```

### Policy Rules:
- Every table must have explicit policies for operations (`select`, `insert`, `update`, `delete`).
- `using` controls SELECT, UPDATE, DELETE visibility.
- `with check` controls what rows may be INSERTed or what new values may be written during UPDATE.
- **Always scope to `auth.uid()`**:
  ```sql
  create policy "<name> are private to owner"
    on <name> for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
  ```
- **Never disable RLS** to "test" or "make a query work".
- **Never rely solely on client-side filtering**: Do not add manual `.eq('user_id', currentUserId)` in Flutter as a substitute for server-side RLS.

---

## 3. Atomic Multi-Row Operations (Postgres Functions / RPC)

Whenever a single business action requires modifying multiple rows or tables (e.g., accepting an invite, recording an innings handover, creating a team with default roles):
- **DO NOT** execute multiple sequential REST calls from Flutter. Network drops or app backgrounding will cause orphaned, corrupted state.
- **DO** write a Postgres function (`security definer` or `security invoker` as appropriate) in `supabase/migrations/` and invoke it via:
  ```dart
  await supabase.rpc('function_name', params: {...});
  ```
- If using `security definer`, always validate that `auth.uid()` is authorized to perform the action inside the function body.

---

## 4. Timestamps & Triggers

- `created_at` defaults to `now()`.
- `updated_at` **MUST** be set server-side via a trigger:
  ```sql
  create trigger <name>_updated_at
    before update on <name>
    for each row execute function set_updated_at();
  ```
- Flutter clients must **never** set or update `updated_at`.

---

## 5. Client Security & Credentials

- **Publishable / Anon key ONLY in Flutter**: The client binary must only ever hold `SUPABASE_ANON_KEY` / `SUPABASE_PUBLISHABLE_KEY`.
- **`service_role` is strictly forbidden in client code**: It bypasses RLS and grants full database ownership. Admin-level operations belong strictly in Edge Functions (`supabase/functions/`) behind JWT authentication.
- **Mobile Auth Flow**: Mobile apps must use PKCE (`authFlowType: AuthFlowType.pkce`). Never revert to implicit flow.

---

## 6. Migration Standards

- Every schema change must be a timestamped migration file in `supabase/migrations/YYYYMMDDHHMMSS_<description>.sql`.
- Migrations must be idempotent where possible (`if not exists`, `drop trigger if exists`).
- **Backward Compatibility**: Production mobile clients in the wild may not update immediately. Migrations must not break older versions of the app (prefer additive changes, default values, or migration windows).
- Update relevant documentation in `docs/database/` when schema changes are introduced.
