import type {
  CommandContext,
  CommandResult,
  TossDecision,
} from "../types.ts";
import {
  MatchRepository,
} from "../repositories/match_repository.ts";
import {
  AuthorizationRepository,
} from "../repositories/authorization_repository.ts";
import {
  requiredEnum,
} from "../domain/validation.ts";
import {
  teamIdForSide,
} from "../domain/cricket.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

export async function recordTossDecision(
  ctx: CommandContext,
): Promise<CommandResult> {
  const decision =
    requiredEnum<TossDecision>(
      ctx.body,
      "p_decision",
      ["bat", "bowl"],
    );

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  if (!match.tossWonBy) {
    unprocessable(
      "Record the toss winner before choosing bat or bowl",
    );
  }

  const tossWinnerTeamId =
    teamIdForSide(
      match,
      match.tossWonBy,
    );

  if (
    !(await authz.isSideCaptain(
      ctx.tx,
      match,
      tossWinnerTeamId,
      ctx.actorId,
    ))
  ) {
    forbidden(
      "Only the captain of the side that won the toss can choose to bat or bowl",
    );
  }

  if (
    match.phase !== "toss" &&
    match.phase !== "lineup"
  ) {
    unprocessable(
      "The toss decision can no longer be changed once the match has progressed",
    );
  }

  await ctx.tx`
    update public.cricket_matches
    set
      toss_decision =
        ${decision}::public.cricket_toss_decision,
      phase = 'lineup',
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {};
}
