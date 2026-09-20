import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import { MatchRepository } from "../repositories/match_repository.ts";
import { AuthorizationRepository } from "../repositories/authorization_repository.ts";
import { HistoryRepository } from "../repositories/history_repository.ts";
import {
  optionalString,
  requiredUuid,
} from "../domain/validation.ts";
import { unprocessable } from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const history = new HistoryRepository();

export async function tournamentDeclareWalkover(
  ctx: CommandContext,
): Promise<CommandResult> {
  const winnerTeamId =
    requiredUuid(
      ctx.body,
      "p_winner_team_id",
    );
  const reason =
    optionalString(ctx.body, "p_reason");

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
        winner_team_id: winnerTeamId,
      },
      reason,
      actorId: ctx.actorId,
    },
  );

  const result = {
    winner_team_id: winnerTeamId,
    win_type: "walkover",
    win_margin: null,
    description: "Won by walkover",
    summary: "Won by walkover",
  };

  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'complete',
      result = ${ctx.tx.json(result)},
      result_summary =
        ${ctx.tx.json({
          description: "Won by walkover",
        })},
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  // Write generic winner explicitly. Do not depend on a command RPC/trigger to
  // project it for us.
  await ctx.tx`
    update public.matches
    set
      status = 'completed',
      winner_id =
        ${winnerTeamId}::uuid,
      completed_at = now(),
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
