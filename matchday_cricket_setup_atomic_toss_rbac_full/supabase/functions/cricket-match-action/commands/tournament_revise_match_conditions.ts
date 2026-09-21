import type {
  CommandContext,
  CommandResult,
} from "../types.ts";
import {
  MatchRepository,
} from "../repositories/match_repository.ts";
import {
  AuthorizationRepository,
} from "../repositories/authorization_repository.ts";
import {
  optionalInteger,
  optionalString,
  requiredEnum,
  requiredInteger,
} from "../domain/validation.ts";
import {
  normalizeCricketRules,
  numberRule,
} from "../domain/cricket.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

export async function tournamentReviseMatchConditions(
  ctx: CommandContext,
): Promise<CommandResult> {
  const revisedOvers =
    requiredInteger(
      ctx.body,
      "p_revised_overs",
    );

  const bowlerQuota =
    requiredInteger(
      ctx.body,
      "p_bowler_quota",
    );

  const revisedTarget =
    optionalInteger(
      ctx.body,
      "p_revised_target",
    );

  const method =
    requiredEnum(
      ctx.body,
      "p_method",
      [
        "run_rate",
        "dls",
        "custom",
        "none",
      ] as const,
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
    match.status === "completed" ||
    match.status === "abandoned" ||
    match.status === "cancelled"
  ) {
    unprocessable(
      "This match is already finished",
    );
  }

  if (revisedOvers < 5) {
    unprocessable(
      "A result needs at least 5 overs per side",
    );
  }

  if (bowlerQuota < 1) {
    unprocessable(
      "Each bowler needs at least one over",
    );
  }

  const originalOvers =
    numberRule(
      match.rulesSnapshot,
      "overs_per_innings",
      20,
    );

  if (
    revisedOvers >
    originalOvers
  ) {
    unprocessable(
      "Overs can only be reduced, not extended",
    );
  }

  const originalQuota =
    numberRule(
      match.rulesSnapshot,
      "max_overs_per_bowler",
      4,
    );

  const rules =
    normalizeCricketRules({
      ...match.rulesSnapshot,
      overs_per_innings:
        revisedOvers,
      max_overs_per_bowler:
        bowlerQuota,
    });

  const revisedConditions = {
    applied_at:
      new Date().toISOString(),
    applied_by:
      ctx.actorId,
    original_overs:
      originalOvers,
    revised_overs:
      revisedOvers,
    original_quota:
      originalQuota,
    revised_quota:
      bowlerQuota,
    revised_target:
      revisedTarget,
    method,
    reason,
  };

  await ctx.tx`
    update public.cricket_matches
    set
      rules_snapshot =
        ${ctx.tx.json(rules)},
      revised_conditions =
        ${ctx.tx.json(
          revisedConditions,
        )},
      updated_at = now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {};
}
