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
  HistoryRepository,
} from "../repositories/history_repository.ts";
import {
  requiredString,
  requiredUuid,
} from "../domain/validation.ts";
import {
  jsonObject,
  teamSideFor,
} from "../domain/cricket.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const teams =
  new MatchTeamRepository();

const authz =
  new AuthorizationRepository();

const history =
  new HistoryRepository();

export async function tournamentOverrideResult(
  ctx: CommandContext,
): Promise<CommandResult> {
  const winnerTeamId =
    requiredUuid(
      ctx.body,
      "p_winner_team_id",
    );

  const reason =
    requiredString(
      ctx.body,
      "p_reason",
    );

  if (reason.length < 10) {
    unprocessable(
      "An override requires a reason of at least 10 characters",
    );
  }

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  await authz.requireTournamentOrganizer(
    ctx.tx,
    match,
    ctx.actorId,
  );

  const winnerSide =
    teamSideFor(
      match,
      winnerTeamId,
    );

  await history.recordResultTransition(
    ctx.tx,
    {
      matchId: ctx.matchId,
      previousStatus:
        match.status,
      newStatus: "completed",
      resultPayload: {
        ...jsonObject(
          match.result,
        ),
        overridden_to_side:
          winnerSide,
      },
      reason,
      actorId: ctx.actorId,
    },
  );

  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'complete',
      result =
        coalesce(
          result,
          '{}'::jsonb
        )
        || jsonb_build_object(
          'winner_side',
            ${winnerSide},
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
        'Result overridden by tournament organizer',
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'completed',
      winner_side =
        ${winnerSide},
      completed_at =
        coalesce(
          completed_at,
          now()
        ),
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  await teams.advanceWinner(
    ctx.tx,
    ctx.matchId,
    winnerSide,
  );

  return {};
}
