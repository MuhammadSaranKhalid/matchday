// Golden-vector tests for the Slice-A scoring engine.
//
// Run: deno test supabase/functions/_shared/scoring/engine.test.ts
//
// Each case asserts the engine reproduces the deployed record_ball semantics
// for one delivery type. State uses readable ids ("S"=striker, "N"=non-striker,
// "B"=bowler) so strike rotation is obvious.

import { assertEquals } from "jsr:@std/assert";
import { applyBall } from "./engine.ts";
import type { BallInput, EngineContext, InningsState, MatchFormat } from "./types.ts";

const FORMAT: MatchFormat = {
  oversPerInnings: 20,
  playersPerTeam: 11,
  ballsPerOver: 6,
  maxOversPerBowler: 4,
  inningsPerSide: 1,
  ballType: "leather",
};

function state(over: Partial<InningsState> = {}): InningsState {
  return {
    strikerId: "S",
    nonStrikerId: "N",
    bowlerId: "B",
    legalBallCount: 0,
    totalRuns: 0,
    totalWickets: 0,
    totalExtras: 0,
    isAllOut: false,
    isDeclared: false,
    target: null,
    version: 1,
    ...over,
  };
}

function ball(over: Partial<BallInput> = {}): BallInput {
  return {
    isLegalDelivery: true,
    ballKind: "legal",
    runsScored: 0,
    extras: 0,
    isWicket: false,
    wicketType: null,
    batsmanId: "S",
    nonStrikerId: "N",
    bowlerId: "B",
    fielderId: null,
    commentary: null,
    ...over,
  };
}

const NO_CTX: EngineContext = { prevNonWideKind: null };

Deno.test("dot ball: counts, no swap, over not ended", () => {
  const r = applyBall(state(), FORMAT, ball(), NO_CTX);
  assertEquals(r.ok, true);
  assertEquals(r.newState!.legalBallCount, 1);
  assertEquals(r.newState!.totalRuns, 0);
  assertEquals(r.newState!.strikerId, "S");
  assertEquals(r.newState!.nonStrikerId, "N");
  assertEquals(r.ball!.overNumber, 0);
  assertEquals(r.ball!.ballInOver, 1);
  assertEquals(r.events!.overEnded, false);
});

Deno.test("single: striker and non-striker swap", () => {
  const r = applyBall(state(), FORMAT, ball({ runsScored: 1 }), NO_CTX);
  assertEquals(r.newState!.strikerId, "N");
  assertEquals(r.newState!.nonStrikerId, "S");
  assertEquals(r.newState!.totalRuns, 1);
});

Deno.test("two / four / six: no swap", () => {
  for (const runs of [2, 4, 6]) {
    const r = applyBall(state(), FORMAT, ball({ runsScored: runs }), NO_CTX);
    assertEquals(r.newState!.strikerId, "S", `runs=${runs}`);
    assertEquals(r.newState!.totalRuns, runs, `runs=${runs}`);
  }
});

Deno.test("wide: no legal ball counted, +1 extra, no swap (record_ball parity)", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ isLegalDelivery: false, ballKind: "wide", runsScored: 0, extras: 1 }),
    NO_CTX,
  );
  assertEquals(r.newState!.legalBallCount, 0);
  assertEquals(r.newState!.totalRuns, 1);
  assertEquals(r.newState!.totalExtras, 1);
  assertEquals(r.newState!.strikerId, "S");
  assertEquals(r.ball!.ballInOver, 0);
});

Deno.test("no-ball: +1 extra, not legal, sets up free hit for next delivery", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ isLegalDelivery: false, ballKind: "no_ball", extras: 1 }),
    NO_CTX,
  );
  assertEquals(r.newState!.legalBallCount, 0);
  assertEquals(r.newState!.totalRuns, 1);
  // free-hit is derived for the NEXT ball, via ctx.prevNonWideKind:
  const next = applyBall(state({ totalRuns: 1 }), FORMAT, ball(), {
    prevNonWideKind: "no_ball",
  });
  assertEquals(next.ball!.isFreeHit, true);
});

Deno.test("bye 1: legal ball, +1 extra, swap on odd byes", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ ballKind: "bye", runsScored: 0, extras: 1 }),
    NO_CTX,
  );
  assertEquals(r.newState!.legalBallCount, 1);
  assertEquals(r.newState!.totalExtras, 1);
  assertEquals(r.newState!.strikerId, "N"); // odd byes => swap
});

Deno.test("leg-bye 2: legal ball, no swap on even", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ ballKind: "leg_bye", runsScored: 0, extras: 2 }),
    NO_CTX,
  );
  assertEquals(r.newState!.totalExtras, 2);
  assertEquals(r.newState!.strikerId, "S");
});

Deno.test("wicket: striker cleared, wicket counted", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ isWicket: true, wicketType: "bowled" }),
    NO_CTX,
  );
  assertEquals(r.newState!.totalWickets, 1);
  assertEquals(r.newState!.strikerId, null);
  assertEquals(r.newState!.legalBallCount, 1);
});

Deno.test("end of over on a dot: bowler cleared, strikers swap", () => {
  const r = applyBall(state({ legalBallCount: 5 }), FORMAT, ball(), NO_CTX);
  assertEquals(r.newState!.legalBallCount, 6);
  assertEquals(r.events!.overEnded, true);
  assertEquals(r.newState!.bowlerId, null);
  assertEquals(r.newState!.strikerId, "N"); // over-end swap
});

Deno.test("end of over on a single: net no swap (ran 1, then changed ends)", () => {
  const r = applyBall(
    state({ legalBallCount: 5 }),
    FORMAT,
    ball({ runsScored: 1 }),
    NO_CTX,
  );
  assertEquals(r.events!.overEnded, true);
  assertEquals(r.newState!.bowlerId, null);
  assertEquals(r.newState!.strikerId, "S"); // ran a single AND swapped at over end
});

Deno.test("over/ball position derivation mid-over", () => {
  const r = applyBall(state({ legalBallCount: 8 }), FORMAT, ball(), NO_CTX);
  assertEquals(r.ball!.overNumber, 1); // floor(8/6)
  assertEquals(r.ball!.ballInOver, 3); // 8%6 + 1
});

Deno.test("validation: wicket without a type is rejected", () => {
  const r = applyBall(state(), FORMAT, ball({ isWicket: true }), NO_CTX);
  assertEquals(r.ok, false);
  assertEquals(r.error!.code, "wicket_type_required");
});

Deno.test("validation: wicket_type without isWicket is rejected", () => {
  const r = applyBall(
    state(),
    FORMAT,
    ball({ isWicket: false, wicketType: "caught" }),
    NO_CTX,
  );
  assertEquals(r.ok, false);
  assertEquals(r.error!.code, "wicket_type_unexpected");
});
