import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { InningsRepository } from "../repositories/innings_repository.ts";
import { unprocessable } from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const innings = new InningsRepository();

export async function startMatchNow(
  ctx: CommandContext,
): Promise<CommandResult> {
  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  await authz.requireBattingCaptain(
    ctx.tx,
    match,
    1,
    ctx.actorId,
  );

  if (match.phase !== "ready") {
    unprocessable(
      "Openers must be locked before starting the match",
    );
  }

  if (
    !(await innings.hasLockedOpeners(
      ctx.tx,
      ctx.matchId,
      1,
    ))
  ) {
    unprocessable(
      "Openers must be locked before starting the match",
    );
  }

  // Cricket state and generic lifecycle change together in ONE transaction.
  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'live',
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'live',
      actual_start_time =
        coalesce(actual_start_time, now()),
      completed_at = null,
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {
    inningsNumber: 1,
  };
}
