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
  HistoryRepository,
} from "../repositories/history_repository.ts";
import {
  optionalString,
} from "../domain/validation.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches = new MatchRepository();
const authz = new AuthorizationRepository();
const history = new HistoryRepository();

/// Cancel a confirmed non-tournament match.
///
/// This command is intentionally separate from:
///
///   cricket.match.setup
///
/// because cancelling a fixture is administrative authority, while
/// Cricket Match Start is sporting/match-day authority.
///
/// Valid lifecycle:
///
///   scheduled -> cancelled
///
/// Note that the generic `matches.status` remains `scheduled` throughout
/// Cricket toss/lineup/ready. That means cancellation is still possible after
/// a toss was recorded but BEFORE the match becomes live.
///
/// Tournament matches are rejected. Tournament lifecycle is controlled by the
/// tournament organizer command family.
export async function cancelMatch(
  ctx: CommandContext,
): Promise<CommandResult> {
  const reason = optionalString(
    ctx.body,
    "p_reason",
  );

  // Serialize against toss/start/etc so two competing commands cannot both
  // commit against the same stale match state.
  const match = await matches.lockCricketMatch(
    ctx.tx,
    ctx.matchId,
  );

  if (
    match.tournamentId != null ||
    match.matchType === "tournament"
  ) {
    unprocessable(
      "Tournament matches must be managed by a tournament organizer",
    );
  }

  if (match.status !== "scheduled") {
    unprocessable(
      "Only a scheduled match can be cancelled",
    );
  }

  // Effective generic RBAC.
  //
  // This is NOT:
  //   created_by
  //   captain name
  //   hardcoded manager check
  await authz.requireCancelMatch(
    ctx.tx,
    match,
  );

  const description = reason
    ? `Match cancelled: ${reason}`
    : "Match cancelled";

  const result = {
    winner_side: null,
    win_type: "cancelled",
    description,
  };

  // Keep an append-only audit record before changing the current snapshot.
  await history.recordResultTransition(
    ctx.tx,
    {
      matchId: ctx.matchId,
      previousStatus: match.status,
      newStatus: "cancelled",
      resultPayload: result,
      reason,
      actorId: ctx.actorId,
    },
  );

  // Cricket-specific workflow becomes terminal.
  //
  // We intentionally keep existing toss/openers audit data instead of deleting
  // it. The match is cancelled, not erased.
  await ctx.tx`
    update public.cricket_matches
    set
      phase        = 'complete',
      result       = ${ctx.tx.json(result)},
      result_summary = ${description},
      updated_at   = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  // Generic sporting-event lifecycle.
  await ctx.tx`
    update public.matches
    set
      status     = 'cancelled',
      winner_side = null,
      updated_at  = now()
    where match_id = ${ctx.matchId}::uuid
  `;

  return {};
}
