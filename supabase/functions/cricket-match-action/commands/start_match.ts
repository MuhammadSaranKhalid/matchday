import type {
  CommandContext,
  CommandResult,
  MatchBundle,
  TeamSide,
  Tx,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { InningsRepository } from "../repositories/innings_repository.ts";
import { requiredUuid } from "../domain/validation.ts";
import {
  battingSideForInnings,
  numberRule,
  oppositeSide,
} from "../domain/cricket.ts";
import { badRequest, forbidden, unprocessable } from "../domain/errors.ts";

export interface StartMatchDependencies {
  lockMatch(tx: Tx, matchId: string): Promise<MatchBundle>;
  canScore(tx: Tx, match: MatchBundle, actorId: string): Promise<boolean>;
  hasActiveLease(tx: Tx, matchId: string, actorId: string): Promise<boolean>;
  bothBattersAreInXi(
    tx: Tx,
    matchId: string,
    side: TeamSide,
    strikerId: string,
    nonStrikerId: string,
  ): Promise<boolean>;
  bowlerIsInXi(
    tx: Tx,
    matchId: string,
    side: TeamSide,
    bowlerId: string,
  ): Promise<boolean>;
  existingTrioMatches(
    tx: Tx,
    matchId: string,
    strikerId: string,
    nonStrikerId: string,
    bowlerId: string,
  ): Promise<boolean>;
  commitStart(
    tx: Tx,
    args: {
      match: MatchBundle;
      strikerId: string;
      nonStrikerId: string;
      bowlerId: string;
    },
  ): Promise<number>;
}

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const innings = new InningsRepository();

const defaultDependencies: StartMatchDependencies = {
  lockMatch: (tx, matchId) => matches.lockCricketMatch(tx, matchId),
  canScore: (tx, match, actorId) =>
    authz.canScoreInnings(tx, match, 1, actorId),
  hasActiveLease: (tx, matchId, actorId) =>
    authz.hasActiveScorerLease(tx, matchId, actorId),
  bothBattersAreInXi: (tx, matchId, side, strikerId, nonStrikerId) =>
    innings.bothBattersAreInXi(tx, matchId, side, strikerId, nonStrikerId),
  bowlerIsInXi: (tx, matchId, side, bowlerId) =>
    innings.bowlerIsInXi(tx, matchId, side, bowlerId),
  async existingTrioMatches(tx, matchId, strikerId, nonStrikerId, bowlerId) {
    const rows = await tx`
      select exists (
        select 1
        from public.cricket_match_innings_state s
        where s.match_id = ${matchId}::uuid
          and s.innings_number = 1
          and s.striker_id = ${strikerId}::uuid
          and s.non_striker_id = ${nonStrikerId}::uuid
          and s.bowler_id = ${bowlerId}::uuid
      ) as matches
    `;
    return rows[0]?.matches === true;
  },
  async commitStart(tx, args) {
    const battingSide = battingSideForInnings(args.match, 1);
    const bowlingSide = oppositeSide(battingSide);
    const inningsId = await innings.upsertInnings(tx, {
      matchId: args.match.matchId,
      inningsNumber: 1,
      battingSide,
      bowlingSide,
      oversAllocated: numberRule(
        args.match.rulesSnapshot,
        "overs_per_innings",
        20,
      ),
    });

    await innings.upsertLiveState(tx, {
      inningsId,
      matchId: args.match.matchId,
      inningsNumber: 1,
      strikerId: args.strikerId,
      nonStrikerId: args.nonStrikerId,
      bowlerId: args.bowlerId,
      target: null,
    });

    const revisions = await tx`
      update public.cricket_matches
      set phase = 'live',
          state_revision = state_revision + 1,
          updated_at = now()
      where match_id = ${args.match.matchId}::uuid
      returning state_revision
    `;

    await tx`
      update public.matches
      set status = 'live',
          actual_start_time = coalesce(actual_start_time, now()),
          completed_at = null,
          updated_at = now()
      where match_id = ${args.match.matchId}::uuid
    `;

    return Number(revisions[0].state_revision);
  },
};

export async function startMatch(
  ctx: CommandContext,
  deps: StartMatchDependencies = defaultDependencies,
): Promise<CommandResult> {
  if (
    !ctx.body.p_striker_id ||
    !ctx.body.p_non_striker_id ||
    !ctx.body.p_bowler_id
  ) {
    badRequest("Striker, non-striker, and bowler are required");
  }

  const strikerId = requiredUuid(ctx.body, "p_striker_id");
  const nonStrikerId = requiredUuid(ctx.body, "p_non_striker_id");
  const bowlerId = requiredUuid(ctx.body, "p_bowler_id");

  if (strikerId === nonStrikerId) {
    unprocessable("Striker and non-striker must be different players");
  }

  const match = await deps.lockMatch(ctx.tx, ctx.matchId);

  if (match.status === "live") {
    if (
      await deps.existingTrioMatches(
        ctx.tx,
        ctx.matchId,
        strikerId,
        nonStrikerId,
        bowlerId,
      )
    ) {
      return {
        result: { duplicate: true },
        inningsNumber: 1,
        revision: match.stateRevision,
        events: [],
      };
    }
    unprocessable("This match has already started with a different lineup");
  }

  if (
    match.status !== "scheduled" || !["lineup", "ready"].includes(match.phase)
  ) {
    unprocessable("This match is not ready for its opening lineup");
  }

  if (!(await deps.canScore(ctx.tx, match, ctx.actorId))) {
    forbidden("This user is not allowed to score this match");
  }
  // Starting the fixture is still pre-live setup. The scorer lease begins
  // protecting concurrent live scoring after this atomic transition; making
  // it a prerequisite here deadlocked fresh Match Room sessions.

  const battingSide = battingSideForInnings(match, 1);
  const bowlingSide = oppositeSide(battingSide);
  if (
    !(await deps.bothBattersAreInXi(
      ctx.tx,
      ctx.matchId,
      battingSide,
      strikerId,
      nonStrikerId,
    ))
  ) {
    unprocessable("Both batters must be in the batting XI");
  }
  if (!(await deps.bowlerIsInXi(ctx.tx, ctx.matchId, bowlingSide, bowlerId))) {
    unprocessable("Bowler must be in the bowling XI");
  }

  const revision = await deps.commitStart(ctx.tx, {
    match,
    strikerId,
    nonStrikerId,
    bowlerId,
  });

  const occurredAt = new Date().toISOString();
  return {
    inningsNumber: 1,
    revision,
    events: [
      {
        eventId: crypto.randomUUID(),
        matchId: ctx.matchId,
        revision,
        eventType: "match_changed",
        inningsNumber: 1,
        occurredAt,
      },
      {
        eventId: crypto.randomUUID(),
        matchId: ctx.matchId,
        revision,
        eventType: "innings_changed",
        inningsNumber: 1,
        occurredAt,
      },
    ],
  };
}
