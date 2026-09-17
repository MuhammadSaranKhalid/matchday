---
name: database-change
description: Guides the design, creation, and verification of Supabase PostgreSQL schema changes, migrations, RLS policies, triggers, and RPC functions. Use whenever database tables, columns, indexes, policies, or functions are being added or modified.
---

# Database Change Skill

Use this skill when modifying or extending the Supabase Postgres database for Match Day.

---

## Workflow Steps

### Step 1: Pre-Change Inspection Pass (Mandatory)
Before writing any SQL:
1. Inspect existing schema and related tables via Supabase MCP or migrations in `supabase/migrations/`.
2. Inspect existing routines in `docs/database/routines.md` to avoid duplicating functions or triggers.
3. Check table relationships in `docs/database/relationships.md` to understand foreign key constraints and cascades.
4. Verify column naming conventions (e.g., snake_case, UUID identifiers, `created_at`/`updated_at`).

### Step 2: Design Schema, Security & Atomicity
1. **Table Structure**:
   - Primary key: `id uuid primary key default gen_random_uuid()`
   - Foreign keys: `references auth.users on delete cascade` or domain references
   - Timestamps: `created_at timestamptz not null default now()`, `updated_at timestamptz not null default now()`
2. **Row-Level Security (RLS)**:
   - Mandatory: `alter table <name> enable row level security;`
   - Define granular policies (`for select`, `for insert`, `for update`, `for delete`) or owner policy (`for all`).
   - Use `auth.uid() = user_id` for ownership; use `exists (select 1 from ...)` for membership-based access.
   - Always include `with check` on insert/update policies.
3. **Multi-Row Transactions**:
   - If an action updates more than one row or table, design a Postgres function (`create or replace function ... returns ... language plpgsql`).
   - Use `security definer` only if bypassing RLS is required, and explicitly validate caller authorization inside the function.
4. **Triggers & Indexes**:
   - Attach the standard `set_updated_at()` trigger.
   - Add indexes on foreign keys, tenant IDs, and filtered query columns.

### Step 3: Author Timestamped Migration File
Create a new file under `supabase/migrations/`:
Format: `supabase/migrations/YYYYMMDDHHMMSS_<descriptive_name>.sql`

Template:
```sql
-- Migration: <descriptive_name>
-- Description: <summary of changes>

-- 1. Table definition
create table if not exists public.<table_name> (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  -- domain columns...
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Indexes
create index if not exists idx_<table_name>_user_id on public.<table_name>(user_id);

-- 3. Row-Level Security
alter table public.<table_name> enable row level security;

create policy "<table_name> are viewable by owner"
  on public.<table_name> for select
  using (auth.uid() = user_id);

create policy "<table_name> are insertable by owner"
  on public.<table_name> for insert
  with check (auth.uid() = user_id);

create policy "<table_name> are updatable by owner"
  on public.<table_name> for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "<table_name> are deletable by owner"
  on public.<table_name> for delete
  using (auth.uid() = user_id);

-- 4. Triggers
create trigger <table_name>_updated_at
  before update on public.<table_name>
  for each row execute function public.set_updated_at();

-- 5. Realtime Publication (only if client listens to table changes)
-- alter publication supabase_realtime add table public.<table_name>;
```

### Step 4: Verification Queries
Provide copy-pasteable SQL queries for the user to verify the changes:
1. Verify table and column creation:
   ```sql
   select column_name, data_type, is_nullable
   from information_schema.columns
   where table_name = '<table_name>';
   ```
2. Verify RLS is enabled and active:
   ```sql
   select tablename, rowsecurity from pg_tables where tablename = '<table_name>';
   select policyname, cmd, qual, with_check from pg_policies where tablename = '<table_name>';
   ```
3. Test permission boundaries under simulated user identity.

### Step 5: Update Repository Documentation
Update the corresponding documentation under `docs/database/` (e.g., `relationships.md`, `routines.md`, or `catalogues.md`).
