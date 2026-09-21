import type {
  CommandContext,
  CommandResult,
  TossDecision,
} from "../types.ts";
import {
  MatchRepository,
} from "../repositories/match_repository.ts";
import {
  AuthorizationRepository,
} from "../repositories/authorization_repository.ts";
import {
  optionalString,
  requiredEnum,
  requiredUuid,
} from "../domain/validation.ts";
import {
  teamSideFor,
} from "../domain/cricket.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

// Atomic physical-toss recording.
//
// The teams perform the coin toss in person. The controlling Cricket setup side/official
// asks the winner whether they choose to bat or bowl, then submits BOTH facts
// together. There is intentionally no "winner known, decision pending" state.
export async function recordToss(
  ctx: CommandContext,
): Promise<CommandResult> {
  const wonByTeamId =
    requiredUuid(
      ctx.body,
      "p_won_by",
    );

  const decision =
    requiredEnum<TossDecision>(
      ctx.body,
      "p_decision",
      ["bat", "bowl"],
    );

  const face =
    optionalString(
      ctx.body,
      "p_face",
    );

  const match =
    await matches.lockCricketMatch(
      ctx.tx,
      ctx.matchId,
    );

  // A fresh toss may be recorded exactly once through this command.
  //
  // Corrections should be a separate explicit command because changing the
  // toss after lineups are locked can invalidate batting-side state.
  if (
    match.status !== "scheduled" ||
    match.phase !== "toss"
  ) {
    unprocessable(
      "The toss can only be recorded while the match is scheduled and still in the toss phase",
    );
  }

  if (
    match.tossWonBy != null ||
    match.tossDecision != null ||
    match.tossRecordedAt != null
  ) {
    unprocessable(
      "The toss has already been recorded",
    );
  }

  await authz.requireTossAuthority(
    ctx.tx,
    match,
  );

  // Flutter sends a concrete team UUID for ergonomics. Persist the canonical
  // match-local side identity.
  const winningSide =
    teamSideFor(
      match,
      wonByTeamId,
    );

  await ctx.tx`
    update public.cricket_matches
    set
      toss_won_by =
        ${winningSide},
      toss_decision =
        ${decision}::public.cricket_toss_decision,
      toss_face =
        ${face},
      toss_recorded_by =
        ${ctx.actorId}::uuid,
      toss_recorded_at =
        now(),
      phase =
        'lineup',
      updated_at =
        now()
    where match_id =
            ${ctx.matchId}::uuid
  `;

  return {};
}
