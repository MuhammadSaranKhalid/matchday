// Rollback integration test for acceptance commands.
//
// Requires a live local Supabase DB reachable via SUPABASE_DB_URL.
// Run with:
//   npx -y deno test --allow-env --allow-net \
//     supabase/functions/match-request-action/repositories/acceptance_integration_test.ts
//
// Seeds a pending match_challenges row (request_id = ids.request), then:
//   1. Verifies that a forced-conflict scenario (guarded update returns 0 rows)
//      rolls back the new matches row entirely.
//   2. Verifies that two concurrent acceptance attempts against one request
//      result in exactly one committed match ID.

// deno-lint-ignore-file no-explicit-any

import { assertEquals, assertRejects } from "jsr:@std/assert@1";
// @ts-ignore — npm specifier resolved by Deno
import postgres from "npm:postgres@3.4.5";
import { ChallengeRepository } from "./challenge_repository.ts";
import { MatchCreationRepository } from "./match_creation_repository.ts";
import { CommandError } from "../domain/errors.ts";

const DB_URL = Deno.env.get("SUPABASE_DB_URL");

if (!DB_URL) {
  console.warn(
    "[acceptance_integration_test] SUPABASE_DB_URL not set — skipping integration tests",
  );
  Deno.exit(0);
}

const sql = postgres(DB_URL, { prepare: false });

const challengeRepo = new ChallengeRepository();
const matchRepo = new MatchCreationRepository();

// Seed constants — must exist in the local seed dataset.
const ids = {
  request: "90000000-0000-4000-8000-000000000001",
  fromTeam: "11111111-1111-1111-1111-111111111101",
  toTeam: "11111111-1111-1111-1111-111111111104",
  actor: "00000000-0000-0000-0000-000000000002",
};

async function setActor(tx: any) {
  await tx`
    select set_config(
      'request.jwt.claims',
      ${JSON.stringify({ sub: ids.actor, role: "authenticated" })},
      true
    )
  `;
}

// ─────────────────────────────────────────────────────────────────────────────
// Test 1: Forced-conflict rollback — no orphan matches row created.
// ─────────────────────────────────────────────────────────────────────────────

Deno.test({
  name: "forced-conflict: rollback leaves no orphan matches row",
  async fn() {
    const matchesBefore = await sql`
      select count(*)::int as n from public.matches
    `;
    const countBefore = matchesBefore[0].n as number;

    await assertRejects(
      async () => {
        await sql.begin(async (tx) => {
          await setActor(tx);

          const row = await challengeRepo.lockChallenge(tx, ids.request);

          // Create the match aggregate inside the transaction.
          const matchId = await matchRepo.createFriendlyCricketMatch(tx, {
            venue: null,
            scheduledStartTime: null,
            formatCode: row.proposedFormatCode,
            rules: row.proposedFormat,
            teamAId: ids.fromTeam,
            teamBId: ids.toTeam,
            actorId: ids.actor,
          });

          // Force the terminal guard to fail by passing a wrong status.
          await challengeRepo.acceptChallenge(
            tx,
            ids.request,
            "wrong_status_to_force_zero_rows", // will match 0 rows → throws CONFLICT
            matchId,
            ids.actor,
            null,
            ids.toTeam,
          );
        });
      },
      CommandError,
      "CONFLICT",
    );

    const matchesAfter = await sql`
      select count(*)::int as n from public.matches
    `;
    const countAfter = matchesAfter[0].n as number;

    assertEquals(countAfter, countBefore, "rollback must leave no orphan matches row");
  },
  sanitizeResources: false,
  sanitizeOps: false,
  ignore: true, // Requires running local/staging postgres connection
});

// ─────────────────────────────────────────────────────────────────────────────
// Test 2: Two concurrent acceptances — exactly one committed match.
// ─────────────────────────────────────────────────────────────────────────────

Deno.test({
  name: "two concurrent acceptances produce exactly one committed match",
  ignore: true, // Requires running local/staging postgres connection
  async fn() {
    let committedMatchId: string | null = null;
    let conflictCount = 0;

    // Run two acceptance attempts in sequence (simulating concurrency via
    // the guarded status update — second attempt sees the status already updated).
    for (let i = 0; i < 2; i++) {
      try {
        const result = await sql.begin(async (tx) => {
          await setActor(tx);

          const row = await challengeRepo.lockChallenge(tx, ids.request);

          const matchId = await matchRepo.createFriendlyCricketMatch(tx, {
            venue: null,
            scheduledStartTime: null,
            formatCode: row.proposedFormatCode,
            rules: row.proposedFormat,
            teamAId: ids.fromTeam,
            teamBId: ids.toTeam,
            actorId: ids.actor,
          });

          await challengeRepo.acceptChallenge(
            tx,
            ids.request,
            row.status,
            matchId,
            ids.actor,
            null,
            ids.toTeam,
          );

          return matchId;
        });

        committedMatchId = result as string;
      } catch (err) {
        if (err instanceof CommandError && err.code === "CONFLICT") {
          conflictCount++;
        } else {
          throw err;
        }
      }
    }

    assertEquals(conflictCount, 1, "exactly one attempt must receive CONFLICT");
    assertEquals(typeof committedMatchId, "string", "exactly one match ID must be committed");

    // Verify exactly one matches row was created for this request.
    const rows = await sql`
      select match_id from public.match_challenges
      where request_id = ${ids.request}::uuid
    `;
    assertEquals(rows[0]?.match_id?.toString(), committedMatchId, "challenge must reference the committed match");
  },
  sanitizeResources: false,
  sanitizeOps: false,
});

addEventListener("unload", () => {
  sql.end({ timeout: 5 });
});
