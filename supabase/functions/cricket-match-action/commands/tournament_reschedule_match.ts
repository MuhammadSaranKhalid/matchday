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
  optionalString,
  requiredTimestamp,
} from "../domain/validation.ts";
import {
  unprocessable,
} from "../domain/errors.ts";

const matches =
  new MatchRepository();

const authz =
  new AuthorizationRepository();

export async function tournamentRescheduleMatch(
  ctx: CommandContext,
): Promise<CommandResult> {
  const start =
    requiredTimestamp(
      ctx.body,
      "p_start",
    );

  const venue =
    optionalString(
      ctx.body,
      "p_venue",
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

  if (match.status !== "scheduled") {
    unprocessable(
      "Use the abandon/reschedule flow once a match has started",
    );
  }

  const revisions = await ctx.tx`
    update public.cricket_matches
    set
      state_revision = state_revision + 1,
      updated_at = now()
    where match_id = ${ctx.matchId}::uuid
    returning state_revision
  `;

  await ctx.tx`
    update public.matches
    set
      scheduled_start_time =
        ${start}::timestamptz,
      venue = coalesce(
        ${venue},
        venue
      ),
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
