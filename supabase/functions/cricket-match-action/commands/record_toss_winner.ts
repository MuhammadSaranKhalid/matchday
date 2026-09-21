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
  optionalString,
  requiredUuid,
} from "../domain/validation.ts";
import {
  teamSideFor,
} from "../domain/cricket.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

export async function recordTossWinner(
  ctx: CommandContext,
): Promise<CommandResult> {
  // Flutter supplies the concrete team UUID. Convert it to the stable match-side
  // identity before persisting Cricket state.
  const wonByTeamId =
    requiredUuid(
      ctx.body,
      "p_won_by",
    );

  const face =
    optionalString(
      ctx.body,
      "p_face",
    );

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  if (
    !authz.isMatchCreator(
      match,
      ctx.actorId,
    )
  ) {
    forbidden(
      "Only the match creator can record the toss winner",
    );
  }

  const winningSide =
    teamSideFor(
      match,
      wonByTeamId,
    );

  if (
    match.phase !== "toss" &&
    match.phase !== "lineup"
  ) {
    unprocessable(
      "The toss can no longer be changed once the match has progressed",
    );
  }

  await ctx.tx`
    update public.cricket_matches
    set
      toss_won_by = ${winningSide},
      toss_decision = null,
      toss_face = coalesce(
        ${face},
        toss_face
      ),
      toss_recorded_at = now(),
      phase = 'toss',
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {};
}
