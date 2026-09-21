import type {
  Action,
  CommandContext,
  CommandResult,
} from "./types.ts";

import { recordToss } from "./commands/record_toss.ts";
import { submitMatchOpeners } from "./commands/submit_match_openers.ts";
import { startMatchNow } from "./commands/start_match_now.ts";
import { startInnings } from "./commands/start_innings.ts";
import { undoLastBall } from "./commands/undo_last_ball.ts";
import { completeCricketMatch } from "./commands/complete_cricket_match.ts";

import { tournamentRescheduleMatch } from "./commands/tournament_reschedule_match.ts";
import { tournamentAbandonMatch } from "./commands/tournament_abandon_match.ts";
import { tournamentDeclareWalkover } from "./commands/tournament_declare_walkover.ts";
import { tournamentOverrideResult } from "./commands/tournament_override_result.ts";
import { tournamentReviseMatchConditions } from "./commands/tournament_revise_match_conditions.ts";
import { tournamentTriggerSuperOver } from "./commands/tournament_trigger_super_over.ts";

export async function dispatchCommand(
  action: Action,
  ctx: CommandContext,
): Promise<CommandResult> {
  switch (action) {
    case "record_toss":
      return await recordToss(ctx);

    case "submit_match_openers":
      return await submitMatchOpeners(ctx);

    case "start_match_now":
      return await startMatchNow(ctx);

    case "start_innings":
      return await startInnings(ctx);

    case "undo_last_ball":
      return await undoLastBall(ctx);

    case "complete_cricket_match":
      return await completeCricketMatch(ctx);

    case "tournament_reschedule_match":
      return await tournamentRescheduleMatch(ctx);

    case "tournament_abandon_match":
      return await tournamentAbandonMatch(ctx);

    case "tournament_declare_walkover":
      return await tournamentDeclareWalkover(ctx);

    case "tournament_override_result":
      return await tournamentOverrideResult(ctx);

    case "tournament_revise_match_conditions":
      return await tournamentReviseMatchConditions(ctx);

    case "tournament_trigger_super_over":
      return await tournamentTriggerSuperOver(ctx);
  }
}
