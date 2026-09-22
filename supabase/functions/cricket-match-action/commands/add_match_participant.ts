import type {
  CommandContext,
  CommandResult,
  MatchBundle,
  TeamSide,
  Tx,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import {
  type CreatedParticipant,
  ParticipantRepository,
} from "../repositories/participant_repository.ts";
import { requiredEnum, requiredString } from "../domain/validation.ts";
import { forbidden, unprocessable } from "../domain/errors.ts";

export interface AddParticipantDependencies {
  lockMatch(tx: Tx, matchId: string): Promise<MatchBundle>;
  canScore(tx: Tx, match: MatchBundle, actorId: string): Promise<boolean>;
  hasActiveLease(tx: Tx, matchId: string, actorId: string): Promise<boolean>;
  findByIdempotencyKey(
    tx: Tx,
    matchId: string,
    key: string,
  ): Promise<Record<string, unknown> | null>;
  createMatchParticipant(
    tx: Tx,
    args: {
      matchId: string;
      side: TeamSide;
      displayName: string;
      idempotencyKey: string;
      actorId: string;
    },
  ): Promise<CreatedParticipant>;
}

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const participants = new ParticipantRepository();

const defaultDependencies: AddParticipantDependencies = {
  lockMatch: (tx, matchId) => matches.lockCricketMatch(tx, matchId),
  canScore: (tx, match, actorId) =>
    authz.canScoreInnings(tx, match, 1, actorId),
  hasActiveLease: (tx, matchId, actorId) =>
    authz.hasActiveScorerLease(tx, matchId, actorId),
  findByIdempotencyKey: (tx, matchId, key) =>
    participants.findByIdempotencyKey(tx, matchId, key),
  createMatchParticipant: (tx, args) =>
    participants.createMatchParticipant(tx, args),
};

export async function addMatchParticipant(
  ctx: CommandContext,
  deps: AddParticipantDependencies = defaultDependencies,
): Promise<CommandResult> {
  const side = requiredEnum<TeamSide>(ctx.body, "p_team_side", [
    "team_a",
    "team_b",
  ]);
  const displayName = requiredString(ctx.body, "p_display_name");
  const idempotencyKey = requiredString(ctx.body, "p_idempotency_key");

  if (displayName.length > 80) {
    unprocessable("Player name must be 80 characters or fewer");
  }

  const match = await deps.lockMatch(ctx.tx, ctx.matchId);
  if (["completed", "abandoned", "cancelled"].includes(match.status)) {
    unprocessable("Players cannot be added to a finished match");
  }
  if (!(await deps.canScore(ctx.tx, match, ctx.actorId))) {
    forbidden("This user is not allowed to score this match");
  }
  // V1 authorizes the scorer identity through match.score. The legacy lease
  // RPC is not a command prerequisite because the client has no durable,
  // trusted device identifier yet; claiming device isolation here would lock
  // out valid scorers without actually distinguishing their devices.

  const existing = await deps.findByIdempotencyKey(
    ctx.tx,
    ctx.matchId,
    idempotencyKey,
  );
  if (existing) {
    return {
      result: existing,
      revision: match.stateRevision,
      events: [],
    };
  }

  const created = await deps.createMatchParticipant(
    ctx.tx,
    {
      matchId: ctx.matchId,
      side,
      displayName,
      idempotencyKey,
      actorId: ctx.actorId,
    },
  );

  return {
    result: created.participant,
    revision: created.revision,
    events: [{
      eventId: crypto.randomUUID(),
      matchId: ctx.matchId,
      revision: created.revision,
      eventType: "participants_changed",
      occurredAt: new Date().toISOString(),
    }],
  };
}
