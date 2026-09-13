# Operations, security and verification

[Handbook](README.md) · [Platform configuration](catalogues.md) · [Migration workflow](migration-guide.md)

## Source versus running state

This handbook documents a successful empty replay of the checked-in migrations. It does not inspect or certify a hosted project's current schema, secrets, indexes under load, installed Edge Functions, bucket contents or queue backlog. Before diagnosing a hosted problem, establish project identity, migration history, actual function signature and client version. Compare those with the snapshot and source hashes. Editing an already-applied source file does not cause that file to run again on a hosted database.

## Security review boundaries

| Boundary | What to verify |
| --- | --- |
| Data API tables | Effective role/column grants plus RLS SELECT/INSERT/UPDATE/DELETE policies |
| RPC entry points | Exact signature, EXECUTE grants, search_path, actor checks, scoped authority and state validation |
| Service-role Edge Functions | Authentication and entity authorization before privileged SQL; no client exposure of service credentials |
| Private Broadcast | Realtime channel/topic authorization independently of public table visibility |
| Postgres Changes | Actual publication membership and applicable row visibility; avoid unnecessarily exposing payloads |
| Storage | Public download semantics, authenticated write policies, path ownership, MIME types and size limits |
| Scheduled worker | Wake authentication, queue visibility/retry behavior and provider outcome handling |

The final catalogue includes effective inherited rights. Review actual behavior as `anon`/`authenticated` with representative claims, rather than testing only as postgres/service_role. A privileged successful query cannot establish that RLS protects ordinary callers. Advisors are a useful static check, not a complete security proof.

## Scheduled work and queues

| Job | Current schedule | Responsibility |
| --- | --- | --- |
| abandon_stale_matches | `7 * * * *` | Evaluate stale unstarted fixtures; final SQL checks status/timing and lack of deliveries through the balls compatibility view |
| expire_stale_match_requests | `*/15 * * * *` | Expire eligible challenge/pool request workflows |
| notification-push-worker | `15 seconds` | Wake the push worker to process direct/bulk PGMQ queues |

Schedules are configuration, not guarantees of prompt completion. Check job activity and execution results if behavior is delayed. For notifications, distinguish no inbox row, no queued job, leased/retrying job, provider rejection, stale token and device-side display. Current worker limits are described in [architecture](architecture.md#notification-catalogue-icons-and-delivery).

An empty replay can install the cron without having the Vault URL/secret and Edge/provider credentials needed for successful sends. Configure those through the established deployment process; do not commit values to migrations or this snapshot. A queue visibility timeout must cover realistic work duration. A timed-out lease permits another consumer to retry; increasing concurrency without considering this can increase duplicates.

Do not blindly re-enqueue completed jobs or erase the delivery ledger to clear a backlog. Inspect the notification revision, job read count and per-device outcome first. Provider acceptance is not evidence that a user read or even saw a push.

## Storage and icon operations

The schema creates six public buckets: avatars, team logos, tournament logos, tournament banners, post media and notification icons. [Catalogues](catalogues.md#storage-buckets) gives exact byte limits and MIME types. Public download is intentional configuration; write access still depends on Storage policies.

Bucket definitions do not upload the corresponding bytes. Verify required icon objects separately after deploying configuration. Preserve file path conventions used by policies and clients. For post media, the repository workflow creates the post row before upload because Storage authorization checks post ownership. Database row deletion and object deletion are separate concerns unless an explicit workflow handles both.

Keep SVG assets controlled and lightweight. Database catalogue metadata provides reusable icon identity/presentation; Storage serves the SVG. A new asset path, changed color contract or renamed icon key requires checking rendering fallbacks and existing notification types.

## Deletion, historical data and retention

Read ON DELETE from the exact table constraints; never infer CASCADE from naming. Inspect both the relational graph and logical references. Account/team changes can invoke succession, membership cleanup, chat lifecycle, notification production and other triggers within the initiating transaction.

Before changing deletion behavior, trace:

1. The direct FK children and their CASCADE, SET NULL, RESTRICT or NO ACTION rules.
2. Current ownership, singleton role and account-required role invariants.
3. Historical match lineups, results and unclaimed identity references that must remain interpretable.
4. Polymorphic entity UUIDs, organizer arrays, JSON payloads and scoped grants.
5. Storage objects, queue payloads, device tokens and external provider state.
6. Auth/session consequences and the user-facing result after a partial external failure.

The snapshot is a schema reference, not a data backup. This handbook does not assert a deployed backup/PITR policy or comprehensive automated retention job. Before production, define retention periods for inbox rows, delivery history, archived queue messages, chat/media and audit-relevant records; implement and test deletion in batches with appropriate indexes. Confirm restore procedures separately from schema replay.

## Performance and concurrency

FK indexes support integrity operations; application reads need indexes matching their predicates and order. Check partial index predicates, leading composite columns and duplicate indexes before adding another. Use EXPLAIN with realistic data and caller context for a performance change; an empty replay cannot supply representative plans or timing.

Feed/inbox pagination should preserve a stable tie-breaker, usually the unique ID alongside a timestamp. Changing ordering without changing cursor comparison can skip or duplicate rows. Review RLS helper cost alongside query indexes. Match scoring and workflow locks protect shared invariants; do not replace those RPCs with multiple independent client writes.

Notification coalescing/revisions and per-device outcomes support retries but do not make FCM transactional. Scorer leases and queue leases solve different forms of temporary ownership. Both require testing expiry and competing callers.

## Useful read-only inspection SQL

Run against an explicitly identified environment with appropriate privileges. These inspect configuration, not secret values:

```sql
-- Current application tables and RLS flags.
select relname, relrowsecurity, relforcerowsecurity
from pg_class
where relnamespace = 'public'::regnamespace and relkind in ('r', 'p')
order by relname;

-- Policies attached to a table under investigation.
select policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'notifications';

-- Exact overloads and effective definition, including definer configuration.
select p.oid::regprocedure, p.prosecdef, p.proconfig,
       pg_get_functiondef(p.oid)
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'notify';

-- Current scheduled configuration and publication membership.
select jobname, schedule, active from cron.job order by jobname;
select pubname, schemaname, tablename
from pg_publication_tables order by pubname, schemaname, tablename;

-- Child constraints and exact delete actions.
select conrelid::regclass as child, conname, pg_get_constraintdef(oid)
from pg_constraint
where contype = 'f' and confrelid = 'public.profiles'::regclass;
```

Function definitions can contain sensitive literals in a poorly configured environment; review before exporting them. The checked-in snapshot is intentionally produced from empty source replay.

## Known documentation and design boundaries

- [The older matches specification](../matches-schema-architecture.md) is historical. It describes removed SQL scoring/statistics designs. Use the final routine reference and current record-ball implementation.
- `balls` and `format_presets` remain real compatibility views. Their presence is not evidence that removed tables or reducers still exist.
- Tournaments retain their organizer-specific permissions alongside the newer team authorization catalogue.
- Eight application tables currently belong to `supabase_realtime`; Broadcast does not imply that Postgres Changes has been entirely removed.
- No automatic documentation check can prove an unexecuted PL/pgSQL path works. Workflow tests are required after behavioral changes.
- Broad legacy/default grants visible in the reference require separate security judgment; documentation records them rather than silently changing them.

## Official platform references

Use these to interpret platform behavior; the repository rules above are project-specific choices:

- [Supabase database migrations](https://supabase.com/docs/guides/deployment/database-migrations)
- [Row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Database functions](https://supabase.com/docs/guides/database/functions)
- [Realtime authorization](https://supabase.com/docs/guides/realtime/authorization)
- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Supabase Queues](https://supabase.com/docs/guides/queues)
- [Supabase Cron](https://supabase.com/docs/guides/cron)

Consult the current official documentation when changing platform configuration; the snapshot pins source metadata, not future Supabase behavior.
