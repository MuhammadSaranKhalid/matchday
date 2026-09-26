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
  requiredString,
} from "../domain/validation.ts";
import {
  forbidden,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const teams =
  new MatchTeamRepository();

const authz =
  new AuthorizationRepository();

export async function completeCricketMatch(
  ctx: CommandContext,
): Promise<CommandResult> {
  const description =
    requiredString(
      ctx.body,
      "p_description",
    );

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  if (
    !(await authz.canCompleteMatch(
      ctx.tx,
      match,
    ))
  ) {
    forbidden(
      "This user is not allowed to complete the match",
    );
  }

  if (match.winnerSide) {
    await teams.clearAdvancedWinner(
      ctx.tx,
      ctx.matchId,
    );
  }

  const result = {
    winner_side:
      null,
    win_type:
      "manual",
    description,
    summary:
      description,
  };

  const revisions = await ctx.tx`
    update public.cricket_matches
    set
      phase =
        'complete',
      result =
        ${ctx.tx.json(result)},
      result_summary =
        ${description},
      state_revision =
        state_revision + 1,
      updated_at =
        now()
    where match_id =
            ${ctx.matchId}::uuid
    returning state_revision
  `;

  await ctx.tx`
    update public.matches
    set
      status =
        'completed',
      winner_side =
        null,
      completed_at =
        now(),
      updated_at =
        now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  const revision = Number(revisions[0]?.state_revision ?? 0);
  return {
    revision,
    events: [{
      eventId: crypto.randomUUID(),
      matchId: ctx.matchId,
      revision,
      eventType: "match_changed",
      occurredAt: new Date().toISOString(),
    }],
  };
}
