# Scoring — server side

There is **no scoring engine here any more**, and that is deliberate.

`engine.ts` and `engine.test.ts` were deleted on 2026-08-22. They were a second
implementation of the rules of cricket, alongside the Dart engine on the scoring
device and (until the same day) a third in a Postgres trigger. The three
disagreed silently and the scorecard was the casualty.

The rules now live in exactly one place:
**`lib/features/matches/domain/scoring/scoring_engine.dart`**.

## What is still here

| File | Why it survives |
|---|---|
| `vectors.json` | **The specification of the rules of cricket** — the only complete written statement of them in this project. Executed by `test/features/matches/domain/scoring/engine_vectors_test.dart`. A change to scoring rules is a change to these vectors *first*. |
| `types.ts` | Shared wire shapes. `result.ts` needs `MatchFormat`. |
| `result.ts` | Match **result** computation — who won, by how much. This stays server-side on purpose: a device may show an innings as complete, but it may **never** declare a winner (design doc §19.4). A score can be provisional; a result cannot. |

## Before you add anything to this directory

`record-ball` authorizes the writer, rejects duplicates by idempotency key,
stores the delivery the device computed, and re-sums the innings from the
ledger. It has no opinion about whether a delivery was a wide.

🟥 If you are about to add per-delivery cricket arithmetic here or in a database
trigger, stop — that is the bug this directory exists to document. See
`docs/offline-scoring-design.md` (D10, D11, D13) and the exemption 2 banner in
`CLAUDE.md`.
