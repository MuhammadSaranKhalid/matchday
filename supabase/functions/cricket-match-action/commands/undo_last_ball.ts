import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import {
  MatchRepository,
} from "../repositories/match_repository.ts";
import {
  MatchTeamRepository,
} from "../repositories/match_team_repository.ts";
import {
  AuthorizationRepository,
} from "../repositories/authorization_repository.ts";
import {
  InningsRepository,
} from "../repositories/innings_repository.ts";
import {
  requiredInteger,
} from "../domain/validation.ts";
import {
  conflict,
  forbidden,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const teams =
  new MatchTeamRepository();

const authz =
  new AuthorizationRepository();

const innings =
  new InningsRepository();

export async function undoLastBall(
  ctx: CommandContext,
): Promise<CommandResult> {
  const inningsNumber =
    requiredInteger(
      ctx.body,
      "p_innings_number",
    );

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

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

  const state =
    await innings.lockState(
      ctx.tx,
      ctx.matchId,
      inningsNumber,
    );

  if (!state) {
    conflict(
      `Innings ${inningsNumber} has not been started`,
    );
  }

  const deleted =
    await innings.deleteLatestDelivery(
      ctx.tx,
      ctx.matchId,
      inningsNumber,
    );

  if (!deleted) {
    return {
      result: false,
      inningsNumber,
      ballsResync: false,
    };
  }

  await innings.recomputeStateAfterUndo(
    ctx.tx,
    {
      matchId: ctx.matchId,
      inningsNumber,
      deleted,
    },
  );

  if (
    match.status === "completed" ||
    match.phase === "innings_break" ||
    match.phase === "complete"
  ) {
    if (match.winnerSide) {
      await teams.clearAdvancedWinner(
        ctx.tx,
        ctx.matchId,
      );
    }

    await ctx.tx`
      update public.cricket_matches
      set
        result = null,
        result_summary = null,
        phase = 'live',
        updated_at = now()
      where match_id =
              ${ctx.matchId}::uuid
    `;

    await ctx.tx`
      update public.matches
      set
        status = 'live',
        winner_side = null,
        completed_at = null,
        updated_at = now()
      where match_id =
              ${ctx.matchId}::uuid
    `;
  }

  return {
    result: true,
    inningsNumber,
    ballsResync: true,
  };
}
