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
  requiredUuid,
} from "../domain/validation.ts";
import {
  booleanRule,
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

export async function tournamentTriggerSuperOver(
  ctx: CommandContext,
): Promise<CommandResult> {
  const batsFirstId =
    requiredUuid(
      ctx.body,
      "p_bats_first_id",
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

  const result =
    jsonObject(
      match.result,
    );

  if (
    match.status !== "completed" ||
    result.win_type !== "tie"
  ) {
    unprocessable(
      "A super over needs a completed tied Cricket result",
    );
  }

  const batsFirstSide =
    teamSideFor(
      match,
      batsFirstId,
    );

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

  if (match.winnerSide) {
    await teams.clearAdvancedWinner(
      ctx.tx,
      ctx.matchId,
    );
  }

  const revisions = await ctx.tx`
    update public.cricket_matches
    set
      phase = 'super_over',
      result =
        coalesce(
          result,
          '{}'::jsonb
        )
        || jsonb_build_object(
          'winner_side',
            null,
          'super_over',
          jsonb_build_object(
            'triggered_at',
              now(),
            'triggered_by',
              ${ctx.actorId}::uuid,
            'bats_first_side',
              ${batsFirstSide}
          )
        ),
      state_revision = state_revision + 1,
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
    returning state_revision
  `;

  await ctx.tx`
    update public.matches
    set
      status = 'live',
      winner_side = null,
      completed_at = null,
      updated_at = now()
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
