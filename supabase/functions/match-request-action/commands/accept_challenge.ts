// accept_challenge command — supports three flows:
//
//   1. Targeted pending challenge: receiving team manager accepts.
//   2. Countered challenge: original sender accepts the counter terms.
//   3. Open challenge claim: any authorized team manager claims for their team.
//
// Order: lock → authorize → derive agreed terms → validate captains → create aggregate →
//         guarded terminal transition.
//
// INVARIANT: Acceptance materializes the exact agreed terms without overrides.
// If terms need adjustment, the counter-proposal flow must be used instead.

import {
  badRequest,
  forbidden,
  unprocessable,
} from "../domain/errors.ts";
import type { AcceptChallengeInput } from "../types.ts";
import {
  ChallengeRepository,
  type ChallengeRow,
} from "../repositories/challenge_repository.ts";
import { TeamRepository } from "../repositories/team_repository.ts";
import {
  MatchCreationRepository,
  type CreateMatchInput,
} from "../repositories/match_creation_repository.ts";
import type { Tx } from "../types.ts";

// ---------------------------------------------------------------------------
// Dependency interface — injected in production, faked in tests.
// ---------------------------------------------------------------------------

export type { ChallengeRow };

export interface AcceptChallengeContext {
  tx: Tx;
  actorId: string;
  input: AcceptChallengeInput;
}

export interface AcceptChallengeDependencies {
  lockChallenge(tx: Tx, requestId: string): Promise<ChallengeRow>;
  isTeamManager(tx: Tx, teamId: string): Promise<boolean>;
  validateTeamCaptain(tx: Tx, teamId: string): Promise<void>;
  createFriendlyCricketMatch(tx: Tx, input: CreateMatchInput): Promise<string>;
  acceptChallenge(
    tx: Tx,
    requestId: string,
    observedStatus: string,
    matchId: string,
    actorId: string,
    note: string | null,
    toTeamId: string,
  ): Promise<number>;
}

// ---------------------------------------------------------------------------
// Default production dependencies
// ---------------------------------------------------------------------------

const challengeRepo = new ChallengeRepository();
const teamRepo = new TeamRepository();
const matchRepo = new MatchCreationRepository();

const defaultDeps: AcceptChallengeDependencies = {
  lockChallenge: (tx, id) => challengeRepo.lockChallenge(tx, id),
  isTeamManager: (tx, teamId) => teamRepo.isTeamManager(tx, teamId),
  validateTeamCaptain: (tx, teamId) => teamRepo.validateTeamCaptain(tx, teamId),
  createFriendlyCricketMatch: (tx, input) =>
    matchRepo.createFriendlyCricketMatch(tx, input),
  acceptChallenge: (tx, requestId, observedStatus, matchId, actorId, note, toTeamId) =>
    challengeRepo.acceptChallenge(tx, requestId, observedStatus, matchId, actorId, note, toTeamId),
};

// ---------------------------------------------------------------------------
// Command
// ---------------------------------------------------------------------------

export async function acceptChallenge(
  ctx: AcceptChallengeContext,
  deps: AcceptChallengeDependencies = defaultDeps,
): Promise<{ matchId: string }> {
  const { tx, actorId, input } = ctx;

  // ── 1. Lock the challenge row ─────────────────────────────────────────────
  const row = await deps.lockChallenge(tx, input.requestId);

  // ── 2. Authorize and derive exact agreed match terms ──────────────────────
  let toTeamId: string;
  let effectiveFormatCode: string;
  let effectiveFormat: Record<string, unknown>;
  let effectiveStartTime: string | null;
  let effectiveVenue: string | null;

  if (row.status === "countered") {
    // Only the original sender may accept countered terms.
    if (!(await deps.isTeamManager(tx, row.fromTeamId))) {
      forbidden("Only the original sender can accept countered terms");
    }
    toTeamId = row.toTeamId!;
    effectiveFormatCode = row.counteredFormatCode ?? row.proposedFormatCode;
    effectiveFormat = row.counteredFormat ?? row.proposedFormat;
    effectiveStartTime = row.counteredStartTime ?? row.proposedStartTime;
    effectiveVenue = row.counteredVenue ?? row.proposedVenue;

  } else if (row.toTeamId != null) {
    // Targeted challenge: only the receiving team manager may accept.
    if (!(await deps.isTeamManager(tx, row.toTeamId))) {
      forbidden("Only managers of the receiving team can accept");
    }
    toTeamId = row.toTeamId;
    effectiveFormatCode = row.proposedFormatCode;
    effectiveFormat = row.proposedFormat;
    effectiveStartTime = row.proposedStartTime;
    effectiveVenue = row.proposedVenue;

  } else {
    // Open challenge claim: caller must supply and manage the claiming team.
    if (input.toTeamId == null) {
      badRequest("Open challenges require a to_team_id to claim");
    }
    if (input.toTeamId === row.fromTeamId) {
      unprocessable("A team cannot accept its own challenge");
    }
    if (!(await deps.isTeamManager(tx, input.toTeamId))) {
      forbidden("You can only claim an open challenge on behalf of a team you manage");
    }
    toTeamId = input.toTeamId;
    effectiveFormatCode = row.proposedFormatCode;
    effectiveFormat = row.proposedFormat;
    effectiveStartTime = row.proposedStartTime;
    effectiveVenue = row.proposedVenue;
  }

  // ── 3. Validate captains on both teams ────────────────────────────────────
  await deps.validateTeamCaptain(tx, row.fromTeamId);
  await deps.validateTeamCaptain(tx, toTeamId);

  // ── 4. Create the normalised match aggregate ──────────────────────────────
  const matchId = await deps.createFriendlyCricketMatch(tx, {
    venue: effectiveVenue,
    scheduledStartTime: effectiveStartTime,
    formatCode: effectiveFormatCode,
    rules: effectiveFormat,
    teamAId: row.fromTeamId,
    teamBId: toTeamId,
    actorId,
  });

  // ── 5. Guarded terminal transition ────────────────────────────────────────
  await deps.acceptChallenge(
    tx,
    input.requestId,
    row.status,
    matchId,
    actorId,
    input.decisionNote,
    toTeamId,
  );

  return { matchId };
}
