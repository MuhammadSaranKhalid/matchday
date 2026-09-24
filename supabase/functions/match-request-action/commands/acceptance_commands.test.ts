// Acceptance command unit tests with stateful fakes.
//
// Each test names the production defect it catches:
//   - "creation before authorization": match created before actor is verified
//   - "unguarded terminal transition": no conflict guard on status update
//   - "wrong counter actor": non-sender accepts a countered challenge
//   - "incomplete pool closure": competing applications not rejected

import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { CommandError } from "../domain/errors.ts";
import {
  acceptChallenge,
  type AcceptChallengeDependencies,
  type AcceptChallengeContext,
  type ChallengeRow,
} from "./accept_challenge.ts";
import {
  acceptPoolApplication,
  type AcceptPoolApplicationDependencies,
  type AcceptPoolApplicationContext,
  type ApplicationRow,
} from "./accept_pool_application.ts";
import type { AcceptChallengeInput, AcceptPoolApplicationInput } from "../types.ts";

// ---------------------------------------------------------------------------
// IDs
// ---------------------------------------------------------------------------

const ids = {
  request: "90000000-0000-4000-8000-000000000001",
  application: "99000000-0000-4000-8000-000000000001",
  fromTeam: "11000000-0000-4000-8000-000000000001",
  toTeam: "11000000-0000-4000-8000-000000000002",
  thirdTeam: "11000000-0000-4000-8000-000000000003",
  match: "13000000-0000-4000-8000-000000000001",
  actor: "00000000-0000-0000-0000-000000000002", // receiving manager
  sender: "00000000-0000-0000-0000-000000000001",
};

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

interface ChallengeOptions {
  status: "pending" | "countered" | "accepted" | "declined";
  toTeamId?: string | null;
  fromTeamId?: string;
}

class FakeChallengeDependencies implements AcceptChallengeDependencies {
  challengeStatus: string;
  createdMatches = 0;
  challengeUpdated = false;
  authorizedTeamId: string | null;

  private challenge: ChallengeRow;

  constructor(opts: ChallengeOptions) {
    this.challengeStatus = opts.status;
    this.authorizedTeamId = null;

    this.challenge = {
      requestId: ids.request,
      fromTeamId: opts.fromTeamId ?? ids.fromTeam,
      toTeamId: opts.toTeamId !== undefined ? opts.toTeamId : ids.toTeam,
      status: opts.status,
      proposedFormatCode: "t20",
      proposedFormat: { overs_per_innings: 20 },
      proposedStartTime: null,
      proposedVenue: null,
      counteredFormatCode: null,
      counteredFormat: null,
      counteredStartTime: null,
      counteredVenue: null,
      requestedBy: ids.sender,
    };
  }

  async lockChallenge(_tx: unknown, _requestId: string): Promise<ChallengeRow> {
    if (this.challengeStatus === "accepted" || this.challengeStatus === "declined") {
      const { conflict } = await import("../domain/errors.ts");
      conflict(`Request is no longer actionable (status: ${this.challengeStatus})`);
    }
    return { ...this.challenge, status: this.challengeStatus as ChallengeRow["status"] };
  }

  async isTeamManager(_tx: unknown, teamId: string): Promise<boolean> {
    return teamId === this.authorizedTeamId;
  }

  async validateTeamCaptain(_tx: unknown, teamId: string): Promise<void> {
    // always valid in tests
    void teamId;
  }

  async createFriendlyCricketMatch(_tx: unknown, _input: unknown): Promise<string> {
    this.createdMatches++;
    return ids.match;
  }

  async acceptChallenge(
    _tx: unknown,
    _requestId: string,
    _observedStatus: string,
    _matchId: string,
    _actorId: string,
    _note: string | null,
    _toTeamId: string,
  ): Promise<number> {
    this.challengeUpdated = true;
    this.challengeStatus = "accepted";
    return 1;
  }
}

class FakePoolDependencies implements AcceptPoolApplicationDependencies {
  appStatus: string;
  challengeStatus: string;
  createdMatches = 0;
  appAccepted = false;
  competitorsRejected = 0;
  challengeAccepted = false;
  hostTeamId: string;
  authorizedAsHost: boolean;

  private app: ApplicationRow;

  constructor(opts: {
    appStatus?: string;
    challengeStatus?: string;
    hostTeamId?: string;
    authorizedAsHost?: boolean;
  } = {}) {
    this.appStatus = opts.appStatus ?? "pending";
    this.challengeStatus = opts.challengeStatus ?? "pending";
    this.hostTeamId = opts.hostTeamId ?? ids.fromTeam;
    this.authorizedAsHost = opts.authorizedAsHost ?? true;

    this.app = {
      applicationId: ids.application,
      requestId: ids.request,
      applicantTeamId: ids.toTeam,
      status: "pending",
    };
  }

  async lockApplication(_tx: unknown, _applicationId: string): Promise<ApplicationRow> {
    if (this.appStatus !== "pending") {
      const { conflict } = await import("../domain/errors.ts");
      conflict(`Application is no longer pending (status: ${this.appStatus})`);
    }
    return { ...this.app, status: this.appStatus as ApplicationRow["status"] };
  }

  async lockChallengeForApp(
    _tx: unknown,
    _requestId: string,
  ): Promise<{ requestId: string; fromTeamId: string; status: string; proposedFormatCode: string; proposedFormat: Record<string, unknown>; proposedStartTime: string | null; proposedVenue: string | null }> {
    if (this.challengeStatus !== "pending") {
      const { conflict } = await import("../domain/errors.ts");
      conflict(`Open challenge is no longer active (status: ${this.challengeStatus})`);
    }
    return {
      requestId: ids.request,
      fromTeamId: this.hostTeamId,
      status: this.challengeStatus,
      proposedFormatCode: "t20",
      proposedFormat: { overs_per_innings: 20 },
      proposedStartTime: null,
      proposedVenue: null,
    };
  }

  async isTeamManager(_tx: unknown, teamId: string): Promise<boolean> {
    return this.authorizedAsHost && teamId === this.hostTeamId;
  }

  async validateTeamXi(_tx: unknown, _teamId: string, _xi: string[]): Promise<void> {}

  async validateTeamCaptain(_tx: unknown, _teamId: string): Promise<void> {}

  async createFriendlyCricketMatch(_tx: unknown, _input: unknown): Promise<string> {
    this.createdMatches++;
    return ids.match;
  }

  async acceptApplication(_tx: unknown, _applicationId: string, _note: string | null): Promise<void> {
    this.appAccepted = true;
    this.appStatus = "accepted";
  }

  async rejectCompetingApplications(_tx: unknown, _requestId: string, _selectedApplicationId: string): Promise<number> {
    this.competitorsRejected++;
    return 1;
  }

  async acceptChallengeForPool(
    _tx: unknown,
    _requestId: string,
    _matchId: string,
    _actorId: string,
    _note: string | null,
    _toTeamId: string,
  ): Promise<number> {
    this.challengeAccepted = true;
    this.challengeStatus = "accepted";
    return 1;
  }
}

// ---------------------------------------------------------------------------
// Helper builders
// ---------------------------------------------------------------------------

function ctx(input: AcceptChallengeInput): AcceptChallengeContext {
  return { tx: {}, actorId: ids.actor, input };
}

function ctxPool(input: AcceptPoolApplicationInput): AcceptPoolApplicationContext {
  return { tx: {}, actorId: ids.actor, input };
}

const baseChallenge: AcceptChallengeInput = {
  requestId: ids.request,
  decisionNote: null,
  toTeamId: null,
};

const basePool: AcceptPoolApplicationInput = {
  applicationId: ids.application,
  decisionNote: null,
};

// ===========================================================================
// accept_challenge tests
// ===========================================================================

Deno.test("receiving manager accepts a targeted pending challenge", async () => {
  // Production defect caught: creation must only happen after authorization succeeds.
  const deps = new FakeChallengeDependencies({ status: "pending", toTeamId: ids.toTeam });
  deps.authorizedTeamId = ids.toTeam; // actor manages the receiving team

  const out = await acceptChallenge(ctx({ ...baseChallenge }), deps);

  assertEquals(out.matchId, ids.match);
  assertEquals(deps.createdMatches, 1, "must create exactly one match");
  assertEquals(deps.challengeStatus, "accepted", "challenge must be closed atomically");
  assertEquals(deps.challengeUpdated, true);
});

Deno.test("only the original sender can accept a countered challenge", async () => {
  // Production defect caught: wrong counter actor — non-sender must be rejected.
  const deps = new FakeChallengeDependencies({ status: "countered", toTeamId: ids.toTeam });
  // actor manages the receiving team, NOT the sending team → must be forbidden
  deps.authorizedTeamId = ids.toTeam;

  await assertRejects(
    () => acceptChallenge(ctx({ ...baseChallenge }), deps),
    CommandError,
    "Only the original sender",
  );
  assertEquals(deps.createdMatches, 0, "no match created on authorization failure");
});

Deno.test("sender successfully accepts a countered challenge", async () => {
  const deps = new FakeChallengeDependencies({ status: "countered", toTeamId: ids.toTeam });
  // actor manages the sending team — allowed to accept a counter
  deps.authorizedTeamId = ids.fromTeam;

  const out = await acceptChallenge(ctx({ ...baseChallenge }), deps);
  assertEquals(out.matchId, ids.match);
  assertEquals(deps.challengeStatus, "accepted");
});

Deno.test("open challenge requires an authorized claiming team", async () => {
  // Production defect caught: open-claim without a to_team_id must be rejected.
  const deps = new FakeChallengeDependencies({ status: "pending", toTeamId: null });
  deps.authorizedTeamId = ids.toTeam;

  await assertRejects(
    () => acceptChallenge(ctx({ ...baseChallenge, toTeamId: null }), deps),
    CommandError,
    "Open challenges require a to_team_id",
  );
  assertEquals(deps.createdMatches, 0);
});

Deno.test("open challenge: actor must manage the claiming team", async () => {
  const deps = new FakeChallengeDependencies({ status: "pending", toTeamId: null });
  // actor not authorized for the claiming team
  deps.authorizedTeamId = null;

  await assertRejects(
    () => acceptChallenge(ctx({ ...baseChallenge, toTeamId: ids.toTeam }), deps),
    CommandError,
  );
  assertEquals(deps.createdMatches, 0);
});

Deno.test("terminal challenge conflicts before match creation", async () => {
  // Production defect caught: unguarded terminal transition — must detect stale state.
  const deps = new FakeChallengeDependencies({ status: "accepted" });
  deps.authorizedTeamId = ids.toTeam;

  await assertRejects(
    () => acceptChallenge(ctx({ ...baseChallenge }), deps),
    CommandError,
    "no longer actionable",
  );
  assertEquals(deps.createdMatches, 0, "match must not be created for a terminal request");
});

// ===========================================================================
// accept_pool_application tests
// ===========================================================================

Deno.test("host accepts one pool application and rejects competitors", async () => {
  // Production defect caught: incomplete pool closure — competitors must be rejected atomically.
  const deps = new FakePoolDependencies({ authorizedAsHost: true });

  const out = await acceptPoolApplication(ctxPool({ ...basePool }), deps);

  assertEquals(out.matchId, ids.match);
  assertEquals(deps.createdMatches, 1, "exactly one match created");
  assertEquals(deps.appAccepted, true, "selected application accepted");
  assertEquals(deps.competitorsRejected, 1, "competing applications rejected");
  assertEquals(deps.challengeAccepted, true, "parent challenge closed");
});

Deno.test("non-host manager is forbidden from accepting pool applications", async () => {
  // Production defect caught: non-host accepting applications is a forbidden actor.
  const deps = new FakePoolDependencies({ authorizedAsHost: false });

  await assertRejects(
    () => acceptPoolApplication(ctxPool({ ...basePool }), deps),
    CommandError,
    "Only managers of the host team",
  );
  assertEquals(deps.createdMatches, 0);
  assertEquals(deps.appAccepted, false);
});

Deno.test("terminal application conflicts before match creation", async () => {
  // Production defect caught: unguarded terminal transition on pool application.
  const deps = new FakePoolDependencies({ appStatus: "accepted" });

  await assertRejects(
    () => acceptPoolApplication(ctxPool({ ...basePool }), deps),
    CommandError,
    "no longer pending",
  );
  assertEquals(deps.createdMatches, 0);
});

Deno.test("terminal parent challenge conflicts before match creation", async () => {
  // Production defect caught: unguarded terminal transition on parent challenge.
  const deps = new FakePoolDependencies({ challengeStatus: "accepted" });

  await assertRejects(
    () => acceptPoolApplication(ctxPool({ ...basePool }), deps),
    CommandError,
    "no longer active",
  );
  assertEquals(deps.createdMatches, 0);
});
