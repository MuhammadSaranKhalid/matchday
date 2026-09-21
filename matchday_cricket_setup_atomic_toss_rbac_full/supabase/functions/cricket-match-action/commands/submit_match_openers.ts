import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import {
  MatchRepository,
} from "../repositories/match_repository.ts";
import {
  AuthorizationRepository,
} from "../repositories/authorization_repository.ts";
import {
  InningsRepository,
} from "../repositories/innings_repository.ts";
import {
  requiredUuid,
} from "../domain/validation.ts";
import {
  battingSideForInnings,
  numberRule,
  oppositeSide,
} from "../domain/cricket.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

const innings =
  new InningsRepository();

export async function submitMatchOpeners(
  ctx: CommandContext,
): Promise<CommandResult> {
  const strikerId =
    requiredUuid(
      ctx.body,
      "p_striker_id",
    );

  const nonStrikerId =
    requiredUuid(
      ctx.body,
      "p_non_striker_id",
    );

  if (strikerId === nonStrikerId) {
    unprocessable(
      "Striker and non-striker must be different players",
    );
  }

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  if (
    !match.tossWonBy ||
    !match.tossDecision
  ) {
    unprocessable(
      "The toss must be completed before selecting openers",
    );
  }

  if (
    match.status !== "scheduled" ||
    (
      match.phase !== "lineup" &&
      match.phase !== "ready"
    )
  ) {
    unprocessable(
      "Openers can only be managed during the scheduled lineup/ready phase",
    );
  }

  // Authorization is Cricket-capability-based, not captain-name-based.
  await authz.requireBattingSetup(
    ctx.tx,
    match,
    1,
  );

  const battingSide =
    battingSideForInnings(
      match,
      1,
    );

  const bowlingSide =
    oppositeSide(
      battingSide,
    );

  if (
    !(await innings.bothBattersAreInXi(
      ctx.tx,
      ctx.matchId,
      battingSide,
      strikerId,
      nonStrikerId,
    ))
  ) {
    unprocessable(
      "Both openers must be in the batting XI",
    );
  }

  const oversAllocated =
    numberRule(
      match.rulesSnapshot,
      "overs_per_innings",
      20,
    );

  const inningsId =
    await innings.upsertInnings(
      ctx.tx,
      {
        matchId:
          ctx.matchId,
        inningsNumber:
          1,
        battingSide,
        bowlingSide,
        oversAllocated,
      },
    );

  await innings.upsertOpenersState(
    ctx.tx,
    {
      inningsId,
      matchId:
        ctx.matchId,
      inningsNumber:
        1,
      strikerId,
      nonStrikerId,
    },
  );

  await ctx.tx`
    update public.cricket_matches
    set
      phase =
        'ready',
      openers_submitted_by =
        ${ctx.actorId}::uuid,
      openers_submitted_at =
        now(),
      updated_at =
        now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {
    inningsNumber: 1,
  };
}
