# Match Runtime Rollout

## Deployment order

Deploy in this order; do not release the new client against the old database
contract.

1. Apply the additive database migration and participant backfill.
2. Deploy `cricket-match-action` and `record-ball` Edge Functions.
3. Verify canonical snapshots and typed Ably publications.
4. Release the Flutter client with compatibility routes and repository methods
   intact.
5. Observe revision gaps, publish failures, lease conflicts, and command
   errors.
6. Remove legacy methods and database realtime triggers only after supported
   client adoption permits it.

The Saran XI versus Hyderabad Hawks friendly fixture is a known backfill
canary. Before deployment it is scheduled with zero `match_players`; after the
migration it must contain participants on both `team_a` and `team_b`.

## Release gates

Before the client rollout, verify:

- every non-tournament scheduled fixture has participant rows for both sides;
- tournament participants originate from tournament registration, not the
  mutable team roster;
- no backfilled row has `source = match_only`;
- adding a match-only unclaimed participant creates no `team_members` row;
- `start_match` rejects an incomplete or cross-side trio;
- repeating a command with the same idempotency key returns the same outcome;
- two clients converge after a missed event and canonical refresh;
- cancelling one channel lease leaves other consumers connected.

Read-only canary queries:

```sql
select m.match_id, m.status, mt.team_side, mt.team_name,
       count(mp.match_player_id) as participant_count
from matches m
join match_teams mt on mt.match_id = m.match_id
left join match_players mp
  on mp.match_id = mt.match_id and mp.team_side = mt.team_side
where lower(mt.team_name) in ('saran xi', 'hyderabad hawks')
group by m.match_id, m.status, mt.team_side, mt.team_name
order by m.match_id, mt.team_side;

select match_id, team_side, source, count(*)
from match_players
group by match_id, team_side, source
order by match_id, team_side, source;
```

## Observability

Track these dimensions by function version and client version:

| Signal | Meaning | Action threshold |
|---|---|---|
| `command_error` by code | Authorization, validation, or conflict failures | Investigate a sustained increase from baseline |
| `publish_failed` | Commit succeeded but notification failed | Alert; clients recover, but latency degrades |
| `revision_gap` | Client observed a non-contiguous revision | Confirm snapshot reconciliation succeeds |
| `snapshot_refresh_failed` | Correctness recovery could not reach PostgreSQL | Alert on repeated failure for one match |
| `channel_lease_underflow` | Release without a matching acquire | Treat as a client lifecycle defect |
| pending scoring age/count | Optimistic writes are not confirming | Alert before the scorer accumulates a long queue |

Database checks during rollout:

```sql
-- A live Cricket match must have a complete current trio.
select m.match_id
from matches m
join cricket_matches cm using (match_id)
left join cricket_match_innings_state s
  on s.match_id = m.match_id
where m.status = 'live'
  and (s.striker_id is null or s.non_striker_id is null or s.bowler_id is null);

-- Participant identity remains XOR.
select match_player_id
from match_players
where (profile_id is null) = (unclaimed_id is null);
```

Both queries must return zero rows after migration.

## Rollback matrix

| Layer | Safe rollback | Boundary |
|---|---|---|
| Flutter client | Roll back while compatibility routes/methods remain | Do not roll back to a client that cannot read participant provenance or revisions after removing compatibility |
| Edge Functions | Roll back only to a version that returns the canonical snapshot and understands current schema | Never restore a function that transitions live before committing the complete trio |
| Database | Keep additive columns, constraints, functions, provenance, revision data, and backfilled participants | Do not down-migrate after clients have written new provenance/revision data; use a forward corrective migration |
| Realtime | Ably publication may be disabled temporarily because snapshot recovery preserves correctness | Do not remove canonical snapshot reads or revision checks |

If command failures spike, stop the client rollout first. If notifications fail
but commands and snapshot reads remain healthy, keep the database migration and
functions deployed while repairing publication. Database rollback is not the
first response because new clients may already have written data using the new
contract.

## Post-release cleanup

Only after the minimum supported client version uses the Match Room protocol:

1. Prove no supported client subscribes to the legacy independent match/start
   streams.
2. Remove legacy repository methods and their dead controllers.
3. Drop redundant match-runtime `realtime.send` triggers in a new forward
   migration; retain unrelated Supabase Realtime publications.
4. Repeat the two-device convergence and missed-event recovery tests.
