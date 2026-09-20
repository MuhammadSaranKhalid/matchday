import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import {
  requiredUuid,
  optionalString,
} from "../domain/validation.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();

export async function recordTossWinner(
  ctx: CommandContext,
): Promise<CommandResult> {
  const wonBy = requiredUuid(ctx.body, "p_won_by");
  const face = optionalString(ctx.body, "p_face");

  // 1. Lock current authoritative state.
  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  // 2. Command authority: match creator records the observed toss winner.
  if (!authz.isMatchCreator(match, ctx.actorId)) {
    forbidden(
      "Only the match creator can record the toss winner",
    );
  }

  // 3. Domain validation.
  if (
    wonBy !== match.teamAId &&
    wonBy !== match.teamBId
  ) {
    unprocessable(
      "The toss winner must be one of the two teams in this match",
    );
  }

  if (
    match.phase !== "toss" &&
    match.phase !== "lineup"
  ) {
    unprocessable(
      "The toss can no longer be changed once the match has progressed",
    );
  }

  // 4. Persist ONLY Cricket-owned state.
  // The generic parent remains `scheduled`.
  await ctx.tx`
    update public.cricket_matches
    set
      toss_won_by = ${wonBy}::uuid,
      toss_decision = null,
      toss_face = coalesce(
        ${face},
        toss_face
      ),
      toss_recorded_at = now(),
      phase = 'toss',
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
