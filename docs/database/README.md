# Matchday database handbook

This handbook explains the database implemented by this checkout: its structure, ownership boundaries, authorization, workflows, and migration conventions. Start here when onboarding or preparing a database change.

**Evidence:** an empty, disposable Supabase database successfully replayed all **84 migration files** for this review. Its final PostgreSQL catalogue contains **52 application tables, 2 compatibility views, 161 application functions and 37 public enums**. Generated references include final definitions after later function replacements. This is a source-schema reference, **not a claim that a hosted project has these migrations deployed**. Exact capture date, PostgreSQL version and migration SHA-256 hashes are in [the snapshot](schema-snapshot.json).

## Reading order

1. [Architecture and workflow diagrams](architecture.md): why the tables exist and how requests move through the system.
2. [Foreign-key diagrams](relationships.md): seven focused, database-derived relationship graphs and the complete editable graph.
3. [Migration rules and change workflow](migration-guide.md): the project conventions, dependency ordering and concrete change recipes.
4. [Operations and verification](operations.md): security, queues, storage, deletion, debugging and rollout checks.
5. Use the detailed reference below for the exact objects involved in a change.

## Complete reference

| Area | Tables and purpose |
| --- | --- |
| [Identity and teams](tables-identity.md) | Accounts, player identities, teams, memberships, invitations and claims |
| [Authorization](tables-authorization.md) | Roles, exclusions, permissions, defaults, overrides and direct grants |
| [Competition](tables-competition.md) | Venues, tournaments, entries, standings and format presets |
| [Matches and scoring](tables-matches.md) | Fixtures, lineups, innings, deliveries, wickets, officials and results |
| [Social](tables-social.md) | Posts, comments, likes, bookmarks and follows |
| [Messaging](tables-messaging.md) | Chats, members, messages and direct-message identity |
| [Notifications](tables-notifications.md) | Type/icon catalogues, inbox, preferences, mutes, push ledger and devices |
| [Routines and views](routines.md) | Every final application function signature, execution grants and source locations; compatibility view SQL |
| [Catalogues and platform objects](catalogues.md) | All enums, seeded configuration, extensions, storage policies/buckets, Realtime authorization, publications and schedules |
| [Migration inventory](migrations.md) | Every ordered migration, declared objects and source hash |
| [Machine-readable snapshot](schema-snapshot.json) | Full function bodies and structured metadata supporting the reference |

Each table reference includes columns, types, defaults, nullability, constraints, foreign-key delete actions, indexes, triggers, RLS policies and effective API-role grants. The snapshot excludes extension-owned public objects and does not attempt to document Supabase's internal Auth/Storage implementation. It includes their application-facing boundaries. Ordinary user/business rows and Vault secret values are not exported.

## Source authority and maintenance

The SQL under [supabase/migrations](../../supabase/migrations/) is implementation authority. [CLAUDE.md §12](../../CLAUDE.md#12-supabase-schema-conventions) defines this repository's migration rules. This handbook explains both; generated pages describe the final replay. Older design documents capture intent and may precede the implementation. In a disagreement, inspect the final replayed definition and its actual callers rather than copying an old SQL example.

After changing migrations, replay them in an isolated database, exercise affected runtime paths, then refresh the snapshot and generated pages using [the documented procedure](migration-guide.md#refreshing-this-handbook). Update architecture prose whenever behavior changes. CI or a reviewer can run:

```sh
python3 scripts/database/generate_docs.py --check
```

This detects migration/source drift and manual changes to generated pages. It does not certify the correctness of human-authored prose or prove that runtime workflows work.

## Verification for this edition

- All 84 migrations replayed successfully in a disposable database with user fixtures disabled.
- All 52 tables are mapped exactly once in the generated domain reference.
- 15 embedded Mermaid diagrams and the complete graph of 133 foreign keys passed Mermaid syntax parsing.
- Local documentation links resolve; generation/hash drift checks and whitespace checks passed.
- Repository advisors returned only the documented `spatial_ref_sys` and `get_follow_list` exceptions.
- No hosted schema changes were made for this documentation task. Application workflow tests were not rerun for these documentation-only edits; replay and static advisors do not replace those tests.

## Vocabulary

| Term | Meaning here |
| --- | --- |
| Canonical migration | The source file owning a table declaration and its dependency-independent objects |
| Integration migration | Objects that require multiple already-created tables, without another table declaration |
| RPC | A PostgreSQL function exposed through the API; execution grants and internal authorization both matter |
| RLS | Row-level security deciding which rows a caller can read or modify |
| Definer function | A function executed with its owner's privileges; caller checks must be explicit |
| Catalogue | Seeded product configuration such as role definitions or notification types |
| Snapshot | Either persisted match state for fast reads or the documentation metadata export; context distinguishes them |
| Lease | Temporary exclusive ownership/visibility, not permanent completion or exactly-once delivery |
| Source replay | Building an empty database from this checkout, distinct from upgrading an existing deployment |
