// Golden-vector tests for the scoring engine.
//
// Run: deno test --allow-read supabase/functions/_shared/scoring/engine.test.ts
//   (no local Deno? `docker run --rm -v "$PWD":/app -w /app denoland/deno:latest
//    test --allow-read --allow-net supabase/functions/_shared/scoring/engine.test.ts`)
//
// The cases themselves live in `vectors.json`, NOT here. That file is the
// executable specification of the engine, and it is deliberately language
// neutral so a second implementation — the Dart engine on the scoring screen —
// can be held to exactly the same expectations. Two implementations of cricket
// scoring are only safe while one spec governs both.
//
// This file is just the runner. To add a rule, add a vector; it will fail here
// and in every other implementation until each one satisfies it.

import { assertEquals } from "jsr:@std/assert";
import { applyBall } from "./engine.ts";
import type {
  BallInput,
  EngineContext,
  InningsState,
  MatchFormat,
} from "./types.ts";

// deno-lint-ignore no-explicit-any
type Json = Record<string, any>;

interface Vector {
  name: string;
  category: string;
  state?: Json;
  format?: Json;
  input?: Json;
  ctx?: Json;
  expect: {
    ok: boolean;
    error?: string;
    ball?: Json;
    newState?: Json;
    events?: Json;
  };
}

const suite = JSON.parse(
  await Deno.readTextFile(new URL("./vectors.json", import.meta.url)),
) as { defaults: Json; vectors: Vector[] };

const D = suite.defaults;

/** `expect` is a PARTIAL match: assert only the keys a vector names.
 *
 * Vectors stay additive this way — tightening one case never forces every
 * other case to spell out fields it does not care about. */
function assertSubset(actual: Json | null | undefined, expected: Json, where: string) {
  for (const [key, want] of Object.entries(expected)) {
    assertEquals(
      actual?.[key],
      want,
      `${where}.${key}: expected ${JSON.stringify(want)}, got ${JSON.stringify(actual?.[key])}`,
    );
  }
}

for (const v of suite.vectors) {
  Deno.test(`[${v.category}] ${v.name}`, () => {
    const state = { ...D.state, ...(v.state ?? {}) } as InningsState;
    const format = { ...D.format, ...(v.format ?? {}) } as MatchFormat;
    const input = { ...D.input, ...(v.input ?? {}) } as BallInput;
    const ctx = { ...D.ctx, ...(v.ctx ?? {}) } as EngineContext;

    const r = applyBall(state, format, input, ctx);

    assertEquals(r.ok, v.expect.ok, `ok: ${r.error?.code ?? ""} ${r.error?.message ?? ""}`);

    if (!v.expect.ok) {
      assertEquals(r.error?.code, v.expect.error, "error.code");
      return;
    }

    if (v.expect.ball) assertSubset(r.ball as Json, v.expect.ball, "ball");
    if (v.expect.newState) assertSubset(r.newState as Json, v.expect.newState, "newState");
    if (v.expect.events) assertSubset(r.events as Json, v.expect.events, "events");
  });
}

// A vector file that silently loses its contents would turn this whole suite
// green while asserting nothing at all.
Deno.test("[meta] the vector file is populated", () => {
  assertEquals(suite.vectors.length >= 30, true, `only ${suite.vectors.length} vectors`);
});

Deno.test("[meta] vector names are unique", () => {
  const names = suite.vectors.map((v) => v.name);
  assertEquals(new Set(names).size, names.length, "duplicate vector name");
});
