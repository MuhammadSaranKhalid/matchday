import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { HistoryRepository } from "../repositories/history_repository.ts";
import {
  requiredString,
  requiredUuid,
} from "../domain/validation.ts";
import { jsonObject } from "../domain/cricket.ts";
import { unprocessable } from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const history = new HistoryRepository();

export async function tournamentOverrideResult(
  ctx: CommandContext,
): Promise<CommandResult> {
  const winnerTeamId =
    requiredUuid(
      ctx.body,
      "p_winner_team_id",
    );
  const reason =
    requiredString(ctx.body, "p_reason");

  if (reason.length < 10) {
    unprocessable(
      "An override requires a reason of at least 10 characters",
    );
  }

  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  await authz.requireTournamentOrganizer(
    ctx.tx,
    match,
    ctx.actorId,
  );

  if (
    winnerTeamId !== match.teamAId &&
    winnerTeamId !== match.teamBId
  ) {
    unprocessable(
      "Winner must be one of the two teams in this fixture",
    );
  }

  await history.recordResultTransition(
    ctx.tx,
    {
      matchId: ctx.matchId,
      previousStatus: match.status,
      newStatus: "completed",
      resultPayload: {
        ...jsonObject(match.result),
        overridden_to: winnerTeamId,
      },
      reason,
      actorId: ctx.actorId,
    },
  );

  // Use DB now() for the audit timestamp so all writes in the transaction share
  // the database clock.
  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'complete',
      result =
        coalesce(result, '{}'::jsonb)
        || jsonb_build_object(
          'winner_team_id',
            ${winnerTeamId}::uuid,
          'win_type',
            'override',
          'description',
            'Result overridden by tournament organizer',
          'overridden',
            true,
          'override_reason',
            ${reason},
          'overridden_by',
            ${ctx.actorId}::uuid,
          'overridden_at',
            now()
        ),
      result_summary =
        jsonb_build_object(
          'description',
          'Result overridden by tournament organizer'
        ),
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'completed',
      winner_id =
        ${winnerTeamId}::uuid,
      completed_at =
        coalesce(completed_at, now()),
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
