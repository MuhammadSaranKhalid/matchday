import type {
  MatchBundle,
  Tx,
} from "../types.ts";
import { notFound } from "../domain/errors.ts";
import { jsonObject } from "../domain/cricket.ts";

export class MatchRepository {
  // Lock BOTH the generic parent and Cricket extension.
  //
  // Every command starts here. The row lock serializes state transitions such
  // as "record toss" vs "start match" so two phones cannot both validate an
  // old state and then overwrite each other.
  async lockCricketMatch(
    tx: Tx,
    matchId: string,
  ): Promise<MatchBundle> {
    const rows = await tx`
      select
        m.match_id,
        m.tournament_id,
        m.match_type::text as match_type,
        m.sport_id,
        m.status::text as status,
        m.team_a_id,
        m.team_b_id,
        m.created_by,
        m.venue,
        m.scheduled_start_time,
        m.actual_start_time,
        m.completed_at,
        m.winner_id,

        cm.phase::text as phase,
        cm.toss_won_by,
        cm.toss_decision::text as toss_decision,
        cm.toss_face,
        cm.toss_recorded_at,
        cm.rules_snapshot,
        cm.revised_conditions,
        cm.result

      from public.matches m
      join public.cricket_matches cm
        on cm.match_id = m.match_id

      where m.match_id = ${matchId}::uuid
        and m.sport_id = 'cricket'

      for update of m, cm
    `;

    if (rows.length === 0) {
      notFound("Cricket match not found");
    }

    const row = rows[0];

    return {
      matchId: row.match_id as string,
      tournamentId: row.tournament_id as string | null,
      matchType: row.match_type as string,
      sportId: row.sport_id as string,
      status: row.status,
      teamAId: row.team_a_id as string | null,
      teamBId: row.team_b_id as string | null,
      createdBy: row.created_by as string | null,
      venue: row.venue as string | null,
      scheduledStartTime:
        row.scheduled_start_time?.toISOString?.() ??
        row.scheduled_start_time ??
        null,
      actualStartTime:
        row.actual_start_time?.toISOString?.() ??
        row.actual_start_time ??
        null,
      completedAt:
        row.completed_at?.toISOString?.() ??
        row.completed_at ??
        null,
      winnerId: row.winner_id as string | null,

      phase: row.phase,
      tossWonBy: row.toss_won_by as string | null,
      tossDecision: row.toss_decision,
      tossFace: row.toss_face as string | null,
      tossRecordedAt:
        row.toss_recorded_at?.toISOString?.() ??
        row.toss_recorded_at ??
        null,
      rulesSnapshot: jsonObject(row.rules_snapshot),
      revisedConditions:
        row.revised_conditions == null
          ? null
          : jsonObject(row.revised_conditions),
      result:
        row.result == null
          ? null
          : jsonObject(row.result),
    };
  }
}
