import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { requiredString } from "../domain/validation.ts";
import { forbidden } from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();

export async function completeCricketMatch(
  ctx: CommandContext,
): Promise<CommandResult> {
  const description =
    requiredString(ctx.body, "p_description");

  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  const isCaptain =
    await authz.isAnyMatchCaptain(
      ctx.tx,
      match,
      ctx.actorId,
    );

  const hasMatchScoreGrant =
    await authz.can(
      ctx.tx,
      "match",
      ctx.matchId,
      "match.score",
    );

  if (!isCaptain && !hasMatchScoreGrant) {
    forbidden(
      "This user is not allowed to complete the match",
    );
  }

  const result = {
    winner_team_id: null,
    win_type: "manual",
    description,
    summary: description,
  };

  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'complete',
      result = ${ctx.tx.json(result)},
      result_summary =
        ${ctx.tx.json({ description })},
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'completed',
      winner_id = null,
      completed_at = now(),
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
