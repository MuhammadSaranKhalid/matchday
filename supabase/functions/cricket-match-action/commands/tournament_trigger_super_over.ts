import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { requiredUuid } from "../domain/validation.ts";
import {
  booleanRule,
  jsonObject,
} from "../domain/cricket.ts";
import { unprocessable } from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();

export async function tournamentTriggerSuperOver(
  ctx: CommandContext,
): Promise<CommandResult> {
  const batsFirstId =
    requiredUuid(
      ctx.body,
      "p_bats_first_id",
    );

  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  await authz.requireTournamentOrganizer(
    ctx.tx,
    match,
    ctx.actorId,
  );

  const result = jsonObject(match.result);

  if (
    match.status !== "completed" ||
    result.win_type !== "tie"
  ) {
    unprocessable(
      "A super over needs a completed tied Cricket result",
    );
  }

  if (
    batsFirstId !== match.teamAId &&
    batsFirstId !== match.teamBId
  ) {
    unprocessable(
      "Choose one of the two sides to bat first",
    );
  }

  if (
    !booleanRule(
      match.rulesSnapshot,
      "super_over_enabled",
      true,
    )
  ) {
    unprocessable(
      "Super overs are disabled for this tournament",
    );
  }

  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'super_over',
      result =
        coalesce(result, '{}'::jsonb)
        || jsonb_build_object(
          'super_over',
          jsonb_build_object(
            'triggered_at',
              now(),
            'triggered_by',
              ${ctx.actorId}::uuid,
            'bats_first_id',
              ${batsFirstId}::uuid
          )
        ),
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'live',
      winner_id = null,
      completed_at = null,
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
