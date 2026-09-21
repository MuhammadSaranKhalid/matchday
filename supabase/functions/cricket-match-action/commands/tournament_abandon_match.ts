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
  HistoryRepository,
} from "../repositories/history_repository.ts";
import {
  optionalString,
  optionalTimestamp,
  requiredEnum,
} from "../domain/validation.ts";
import {
  jsonObject,
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

const innings =
  new InningsRepository();

const history =
  new HistoryRepository();

export async function tournamentAbandonMatch(
  ctx: CommandContext,
): Promise<CommandResult> {
  const mode =
    requiredEnum(
      ctx.body,
      "p_mode",
      [
        "reschedule",
        "no_result",
      ] as const,
    );

  const rescheduleTo =
    optionalTimestamp(
      ctx.body,
      "p_reschedule_to",
    );

  const reason =
    optionalString(
      ctx.body,
      "p_reason",
    );

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

  if (
    mode === "reschedule" &&
    !rescheduleTo
  ) {
    unprocessable(
      "A new date is required to reschedule the match",
    );
  }

  const previousResult =
    jsonObject(
      match.result,
    );

  const newStatus =
    mode === "reschedule"
      ? "scheduled"
      : "abandoned";

  await history.recordResultTransition(
    ctx.tx,
    {
      matchId: ctx.matchId,
      previousStatus:
        match.status,
      newStatus,
      resultPayload: {
        ...previousResult,
        abandon_mode: mode,
      },
      reason,
      actorId: ctx.actorId,
    },
  );

  if (match.winnerSide) {
    await teams.clearAdvancedWinner(
      ctx.tx,
      ctx.matchId,
    );
  }

  if (mode === "reschedule") {
    await innings.deleteAllForMatch(
      ctx.tx,
      ctx.matchId,
    );

    await ctx.tx`
      update public.cricket_matches
      set
        phase = 'toss',
        result = null,
        result_summary = null,
        revised_conditions = null,
        toss_won_by = null,
        toss_decision = null,
        toss_face = null,
        toss_recorded_at = null,
        openers_submitted_by = null,
        openers_submitted_at = null,
        player_of_the_match_id = null,
        updated_at = now()
      where match_id =
              ${ctx.matchId}::uuid
    `;

    await ctx.tx`
      update public.matches
      set
        status = 'scheduled',
        scheduled_start_time =
          ${rescheduleTo}::timestamptz,
        actual_start_time = null,
        completed_at = null,
        winner_side = null,
        updated_at = now()
      where match_id =
              ${ctx.matchId}::uuid
    `;

    return {};
  }

  const description =
    reason ??
    "Match abandoned — no result";

  const result = {
    winner_side: null,
    win_type: "no_result",
    description,
  };

  await ctx.tx`
    update public.cricket_matches
    set
      phase = 'complete',
      result =
        ${ctx.tx.json(result)},
      result_summary =
        ${description},
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'abandoned',
      winner_side = null,
      completed_at = now(),
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {};
}
