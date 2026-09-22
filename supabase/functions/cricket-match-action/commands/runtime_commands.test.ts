import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { CommandError } from "../domain/errors.ts";
import { startMatch, type StartMatchDependencies } from "./start_match.ts";
import {
  addMatchParticipant,
  type AddParticipantDependencies,
} from "./add_match_participant.ts";
import type { CommandContext, MatchBundle } from "../types.ts";

const ids = {
  match: "13000000-0000-4000-8000-000000000001",
  actor: "10000000-0000-4000-8000-000000000001",
  striker: "15000000-0000-4000-8000-000000000001",
  nonStriker: "15000000-0000-4000-8000-000000000002",
  bowler: "15000000-0000-4000-8000-000000000003",
};

function match(overrides: Partial<MatchBundle> = {}): MatchBundle {
  return {
    matchId: ids.match,
    tournamentId: null,
    matchType: "friendly",
    sportId: "cricket",
    status: "scheduled",
    teamAId: "11000000-0000-4000-8000-000000000001",
    teamBId: "11000000-0000-4000-8000-000000000002",
    teamAName: "Alpha",
    teamBName: "Bravo",
    createdBy: ids.actor,
    venue: null,
    scheduledStartTime: null,
    actualStartTime: null,
    completedAt: null,
    winnerSide: null,
    setupSide: "team_a",
    phase: "lineup",
    tossWonBy: "team_a",
    tossDecision: "bat",
    tossFace: null,
    tossRecordedAt: "2026-09-21T00:00:00Z",
    tossRecordedBy: ids.actor,
    rulesSnapshot: { overs_per_innings: 20 },
    revisedConditions: null,
    result: null,
    stateRevision: 4,
    rosterFrozenAt: "2026-09-21T00:00:00Z",
    ...overrides,
  };
}

function context(body: Record<string, unknown>): CommandContext {
  return {
    tx: {},
    actorId: ids.actor,
    matchId: ids.match,
    body: { p_match_id: ids.match, ...body },
  };
}

function startBody(overrides: Record<string, unknown> = {}) {
  return {
    p_striker_id: ids.striker,
    p_non_striker_id: ids.nonStriker,
    p_bowler_id: ids.bowler,
    ...overrides,
  };
}

class FakeStartDependencies implements StartMatchDependencies {
  current = match();
  authorized = true;
  lease = true;
  battersValid = true;
  bowlerValid = true;
  trioAlreadyMatches = false;
  transitionCount = 0;

  async lockMatch(): Promise<MatchBundle> {
    return this.current;
  }

  async canScore(): Promise<boolean> {
    return this.authorized;
  }

  async hasActiveLease(): Promise<boolean> {
    return this.lease;
  }

  async bothBattersAreInXi(): Promise<boolean> {
    return this.battersValid;
  }

  async bowlerIsInXi(): Promise<boolean> {
    return this.bowlerValid;
  }

  async existingTrioMatches(): Promise<boolean> {
    return this.trioAlreadyMatches;
  }

  async commitStart(): Promise<number> {
    this.transitionCount += 1;
    this.current = match({ status: "live", phase: "live", stateRevision: 5 });
    this.trioAlreadyMatches = true;
    return 5;
  }
}

Deno.test("start_match rejects an incomplete trio", async () => {
  const deps = new FakeStartDependencies();
  await assertRejects(
    () => startMatch(context(startBody({ p_bowler_id: null })), deps),
    CommandError,
    "Striker, non-striker, and bowler are required",
  );
});

Deno.test("start_match rejects the same player at both batting ends", async () => {
  const deps = new FakeStartDependencies();
  await assertRejects(
    () =>
      startMatch(
        context(startBody({ p_non_striker_id: ids.striker })),
        deps,
      ),
    CommandError,
    "different players",
  );
});

Deno.test("start_match rejects a bowler outside the bowling XI", async () => {
  const deps = new FakeStartDependencies();
  deps.bowlerValid = false;
  await assertRejects(
    () => startMatch(context(startBody()), deps),
    CommandError,
    "Bowler must be in the bowling XI",
  );
});

Deno.test("start_match requires scoring permission before live lease ownership", async () => {
  const withoutPermission = new FakeStartDependencies();
  withoutPermission.authorized = false;
  await assertRejects(
    () => startMatch(context(startBody()), withoutPermission),
    CommandError,
    "not allowed",
  );

  const withoutLease = new FakeStartDependencies();
  withoutLease.lease = false;
  const started = await startMatch(context(startBody()), withoutLease);
  assertEquals(started.revision, 5);
});

Deno.test("two start attempts produce one canonical transition", async () => {
  const deps = new FakeStartDependencies();
  const first = await startMatch(context(startBody()), deps);
  const second = await startMatch(context(startBody()), deps);

  assertEquals(first.revision, 5);
  assertEquals(second.revision, 5);
  assertEquals(second.result, { duplicate: true });
  assertEquals(deps.transitionCount, 1);
});

class FakeAddDependencies implements AddParticipantDependencies {
  current = match();
  authorized = true;
  lease = true;
  teamMemberInsertCount = 0;
  creates: Array<{ side: string; name: string; key: string }> = [];
  byKey = new Map<string, Record<string, unknown>>();

  async lockMatch(): Promise<MatchBundle> {
    return this.current;
  }

  async canScore(): Promise<boolean> {
    return this.authorized;
  }

  async hasActiveLease(): Promise<boolean> {
    return this.lease;
  }

  async findByIdempotencyKey(
    _tx: unknown,
    _matchId: string,
    key: string,
  ) {
    return this.byKey.get(key) ?? null;
  }

  async createMatchParticipant(
    _tx: unknown,
    args: {
      side: "team_a" | "team_b";
      displayName: string;
      idempotencyKey: string;
    },
  ) {
    const { side, displayName: name, idempotencyKey: key } = args;
    this.creates.push({ side, name, key });
    const participant = {
      match_player_id: crypto.randomUUID(),
      team_side: side,
      display_name: name,
      source: "match_added",
    };
    this.byKey.set(key, participant);
    this.current = match({ stateRevision: this.current.stateRevision + 1 });
    return { participant, revision: this.current.stateRevision };
  }
}

for (const side of ["team_a", "team_b"] as const) {
  Deno.test(`add_match_participant creates a match-only player for ${side}`, async () => {
    const deps = new FakeAddDependencies();
    const out = await addMatchParticipant(
      context({
        p_team_side: side,
        p_display_name: "  New Player  ",
        p_idempotency_key: `add-${side}`,
      }),
      deps,
    );

    assertEquals((out.result as Record<string, unknown>).source, "match_added");
    assertEquals(deps.creates[0].name, "New Player");
    assertEquals(deps.teamMemberInsertCount, 0);
  });
}

Deno.test("add_match_participant is idempotent", async () => {
  const deps = new FakeAddDependencies();
  const body = {
    p_team_side: "team_b",
    p_display_name: "Replacement Bowler",
    p_idempotency_key: "same-command",
  };

  const first = await addMatchParticipant(context(body), deps);
  const second = await addMatchParticipant(context(body), deps);

  assertEquals(second.result, first.result);
  assertEquals(deps.creates.length, 1);
});

Deno.test("add_match_participant requires scoring authority", async () => {
  const deps = new FakeAddDependencies();
  deps.authorized = false;
  await assertRejects(
    () =>
      addMatchParticipant(
        context({
          p_team_side: "team_a",
          p_display_name: "Guest",
          p_idempotency_key: "unauthorized",
        }),
        deps,
      ),
    CommandError,
    "not allowed",
  );
});
