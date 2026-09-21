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
  optionalInteger,
  requiredInteger,
  requiredUuid,
} from "../domain/validation.ts";
import {
  battingSideForInnings,
  numberRule,
  oppositeSide,
} from "../domain/cricket.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

const innings =
  new InningsRepository();

export async function startInnings(
  ctx: CommandContext,
): Promise<CommandResult> {
  const inningsNumber =
    requiredInteger(
      ctx.body,
      "p_innings_number",
    );

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

  const bowlerId =
    requiredUuid(
      ctx.body,
      "p_bowler_id",
    );

  const target =
    optionalInteger(
      ctx.body,
      "p_target",
    );

  if (inningsNumber < 1) {
    unprocessable(
      "Innings number must be at least 1",
    );
  }

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
    match.status === "completed" ||
    match.status === "abandoned" ||
    match.status === "cancelled"
  ) {
    unprocessable(
      "This match is already finished",
    );
  }

  if (
    !(await authz.canScoreInnings(
      ctx.tx,
      match,
      inningsNumber,
      ctx.actorId,
    ))
  ) {
    forbidden(
      "This user is not allowed to score this innings",
    );
  }

  const battingSide =
    battingSideForInnings(
      match,
      inningsNumber,
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
      "Both batters must be in the batting XI",
    );
  }

  if (
    !(await innings.bowlerIsInXi(
      ctx.tx,
      ctx.matchId,
      bowlingSide,
      bowlerId,
    ))
  ) {
    unprocessable(
      "Bowler must be in the bowling XI",
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
        matchId: ctx.matchId,
        inningsNumber,
        battingSide,
        bowlingSide,
        oversAllocated,
      },
    );

  await innings.upsertLiveState(
    ctx.tx,
    {
      inningsId,
      matchId: ctx.matchId,
      inningsNumber,
      strikerId,
      nonStrikerId,
      bowlerId,
      target,
    },
  );

  await ctx.tx`
    update public.cricket_matches
    set
      phase = case
        when phase = 'super_over'
          then 'super_over'::public.cricket_match_phase
        else 'live'::public.cricket_match_phase
      end,
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'live',
      actual_start_time =
        coalesce(
          actual_start_time,
          now()
        ),
      completed_at = null,
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {
    inningsNumber,
  };
}
