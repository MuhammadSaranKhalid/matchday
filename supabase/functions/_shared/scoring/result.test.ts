// Golden-vector tests for computeResult.
// Run: deno test supabase/functions/_shared/scoring/result.test.ts

import { assertEquals } from "jsr:@std/assert";
import { computeResult, type InningsLine } from "./result.ts";
import type { MatchFormat } from "./types.ts";

const T20: MatchFormat = {
  oversPerInnings: 20,
  playersPerTeam: 11,
  ballsPerOver: 6,
  maxOversPerBowler: 4,
  inningsPerSide: 1,
  ballType: "leather",
};

function inns(
  n: number,
  teamId: string,
  runs: number,
  wickets: number,
  isAllOut = false,
): InningsLine {
  return { inningsNumber: n, battingTeamId: teamId, runs, wickets, legalBalls: 0, isAllOut };
}

Deno.test("win by runs (defending side)", () => {
  const r = computeResult(
    [inns(1, "A", 180, 8), inns(2, "B", 157, 10, true)],
    T20,
  );
  assertEquals(r.winnerTeamId, "A");
  assertEquals(r.winType, "runs");
  assertEquals(r.winMargin, 23);
  assertEquals(r.description, "Won by 23 runs");
});

Deno.test("win by wickets (chasing side)", () => {
  const r = computeResult(
    [inns(1, "A", 150, 9), inns(2, "B", 151, 5)],
    T20,
  );
  assertEquals(r.winnerTeamId, "B");
  assertEquals(r.winType, "wickets");
  assertEquals(r.winMargin, 5); // 10 all-out - 5 down = 5 in hand
  assertEquals(r.description, "Won by 5 wickets");
});

Deno.test("tie", () => {
  const r = computeResult(
    [inns(1, "A", 160, 7), inns(2, "B", 160, 10, true)],
    T20,
  );
  assertEquals(r.winnerTeamId, null);
  assertEquals(r.winType, "tie");
  assertEquals(r.description, "Match tied");
});

Deno.test("win-by-wickets margin scales with team size (6-a-side)", () => {
  const sixes: MatchFormat = { ...T20, playersPerTeam: 6 }; // all-out at 5
  const r = computeResult(
    [inns(1, "A", 40, 4), inns(2, "B", 41, 2)],
    sixes,
  );
  assertEquals(r.winnerTeamId, "B");
  assertEquals(r.winType, "wickets");
  assertEquals(r.winMargin, 3); // 5 - 2
});

Deno.test("singular margins read naturally", () => {
  const byRun = computeResult([inns(1, "A", 100, 6), inns(2, "B", 99, 10, true)], T20);
  assertEquals(byRun.description, "Won by 1 run");
  const byWkt = computeResult([inns(1, "A", 100, 5), inns(2, "B", 101, 9)], T20);
  assertEquals(byWkt.description, "Won by 1 wicket");
});

Deno.test("drawn match (Test)", () => {
  const test: MatchFormat = { ...T20, oversPerInnings: 0, inningsPerSide: 2 };
  const r = computeResult(
    [inns(1, "A", 400, 10, true), inns(2, "B", 250, 10, true)],
    test,
    { drawn: true },
  );
  assertEquals(r.winType, "draw");
  assertEquals(r.description, "Match drawn");
});

Deno.test("no result with fewer than two innings", () => {
  const r = computeResult([inns(1, "A", 180, 4)], T20);
  assertEquals(r.winnerTeamId, null);
  assertEquals(r.winType, null);
  assertEquals(r.description, "No result");
});
