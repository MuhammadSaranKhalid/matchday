// accept_pool_application command.
//
// Flow: lock application → lock parent challenge → authorize host manager →
//        validate rosters → create aggregate → accept application →
//        reject competitors → guarded close of parent challenge.
//
// Locking order: application first, then challenge. Consistent locking order
// prevents deadlocks from concurrent pool acceptance attempts.
//
// NOTE: The handler parses the envelope once. Commands receive typed inputs directly.

import { forbidden } from "../domain/errors.ts";
import {
  ChallengeRepository,
  type ApplicationRow,
  type LockedChallengeForPool,
} from "../repositories/challenge_repository.ts";
import { TeamRepository } from "../repositories/team_repository.ts";
import {
  MatchCreationRepository,
  type CreateMatchInput,
} from "../repositories/match_creation_repository.ts";
import type { AcceptPoolApplicationInput, Tx } from "../types.ts";

// ---------------------------------------------------------------------------
// Dependency interface
// ---------------------------------------------------------------------------

export type { ApplicationRow };

export interface AcceptPoolApplicationContext {
  tx: Tx;
  actorId: string;
  input: AcceptPoolApplicationInput;
}

export interface AcceptPoolApplicationDependencies {
  lockApplication(tx: Tx, applicationId: string): Promise<ApplicationRow>;
  lockChallengeForApp(
    tx: Tx,
    requestId: string,
  ): Promise<LockedChallengeForPool>;
  isTeamManager(tx: Tx, teamId: string): Promise<boolean>;
  validateTeamXi(tx: Tx, teamId: string, xi: string[]): Promise<void>;
  validateTeamCaptain(tx: Tx, teamId: string): Promise<void>;
  createFriendlyCricketMatch(tx: Tx, input: CreateMatchInput): Promise<string>;
  acceptApplication(
    tx: Tx,
    applicationId: string,
    note: string | null,
  ): Promise<void>;
  rejectCompetingApplications(
    tx: Tx,
    requestId: string,
    selectedApplicationId: string,
  ): Promise<number>;
  acceptChallengeForPool(
    tx: Tx,
    requestId: string,
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

const defaultDeps: AcceptPoolApplicationDependencies = {
  lockApplication: (tx, id) => challengeRepo.lockApplication(tx, id),
  lockChallengeForApp: (tx, requestId) =>
    challengeRepo.lockChallengeForApp(tx, requestId),
  isTeamManager: (tx, teamId) => teamRepo.isTeamManager(tx, teamId),
  validateTeamXi: (tx, teamId, xi) => teamRepo.validateTeamXi(tx, teamId, xi),
  validateTeamCaptain: (tx, teamId) => teamRepo.validateTeamCaptain(tx, teamId),
  createFriendlyCricketMatch: (tx, input) =>
    matchRepo.createFriendlyCricketMatch(tx, input),
  acceptApplication: (tx, id, note) =>
    challengeRepo.acceptApplication(tx, id, note),
  rejectCompetingApplications: (tx, requestId, selectedId) =>
    challengeRepo.rejectCompetingApplications(tx, requestId, selectedId),
  acceptChallengeForPool: (tx, requestId, matchId, actorId, note, toTeamId) =>
    challengeRepo.acceptChallengeForPool(tx, requestId, matchId, actorId, note, toTeamId),
};

// ---------------------------------------------------------------------------
// Command
// ---------------------------------------------------------------------------

export async function acceptPoolApplication(
  ctx: AcceptPoolApplicationContext,
  deps: AcceptPoolApplicationDependencies = defaultDeps,
): Promise<{ matchId: string }> {
  const { tx, actorId, input } = ctx;

  // ── 1. Lock application (must be pending) ────────────────────────────────
  const app = await deps.lockApplication(tx, input.applicationId);

  // ── 2. Lock parent challenge (must be pending) ───────────────────────────
  const req = await deps.lockChallengeForApp(tx, app.requestId);

  // ── 3. Authorize: only the host team manager may accept ──────────────────
  if (!(await deps.isTeamManager(tx, req.fromTeamId))) {
    forbidden("Only managers of the host team can accept pool applications");
  }

  // ── 4. Validate both rosters ──────────────────────────────────────────────
  await deps.validateTeamXi(tx, req.fromTeamId, req.fromTeamXi);
  await deps.validateTeamXi(tx, app.applicantTeamId, app.applicantXi);
  await deps.validateTeamCaptain(tx, req.fromTeamId);
  await deps.validateTeamCaptain(tx, app.applicantTeamId);

  // ── 5. Create the normalised match aggregate ──────────────────────────────
  const normalizedFormat = MatchCreationRepository.normalizeFormat(
    req.proposedFormat,
  );

  const matchId = await deps.createFriendlyCricketMatch(tx, {
    venue: req.proposedVenue,
    scheduledStartTime: req.proposedStartTime,
    format: normalizedFormat,
    teamAId: req.fromTeamId,
    teamBId: app.applicantTeamId,
    teamAKeeperId: req.fromTeamKeeperId,
    teamBKeeperId: app.applicantKeeperId,
    actorId,
  });

  // ── 6. Accept selected application ───────────────────────────────────────
  await deps.acceptApplication(tx, input.applicationId, input.decisionNote);

  // ── 7. Reject competing pending applications ──────────────────────────────
  await deps.rejectCompetingApplications(tx, app.requestId, input.applicationId);

  // ── 8. Guarded close of parent challenge ─────────────────────────────────
  await deps.acceptChallengeForPool(
    tx,
    app.requestId,
    matchId,
    actorId,
    input.decisionNote,
    app.applicantTeamId,
  );

  return { matchId };
}
