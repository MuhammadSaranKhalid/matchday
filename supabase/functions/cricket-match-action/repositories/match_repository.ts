import type { MatchBundle, Tx } from "../types.ts";
import { jsonObject } from "../domain/cricket.ts";
import { notFound } from "../domain/errors.ts";

export class MatchRepository {
  // Lock the complete authoritative Cricket command context:
  //
  //   matches                         generic event shell
  //   match_teams(team_a/team_b)      generic competitor slots
  //   cricket_matches                 Cricket workflow/rules/result
  //
  // This keeps sport-neutral identity and Cricket behavior separate while
  // still serializing competing Match Start commands correctly.
  async lockCricketMatch(
    tx: Tx,
    matchId: string,
  ): Promise<MatchBundle> {
    const rows = await tx`
      select
        m.match_id,
        m.tournament_id,
        m.match_type::text
          as match_type,
        m.sport_id,
        m.status::text
          as status,
        m.created_by,
        m.venue,
        m.scheduled_start_time,
        m.actual_start_time,
        m.completed_at,
        m.winner_side,

        team_a.team_id
          as team_a_id,
        team_a.team_name
          as team_a_name,
        team_b.team_id
          as team_b_id,
        team_b.team_name
          as team_b_name,

        cm.setup_side,
        cm.phase::text
          as phase,
        cm.toss_won_by,
        cm.toss_decision::text
          as toss_decision,
        cm.toss_face,
        cm.toss_recorded_at,
        cm.toss_recorded_by,
        cm.rules_snapshot,
        cm.revised_conditions,
        cm.result
        ,cm.state_revision
        ,cm.roster_frozen_at

      from public.matches m

      join public.match_teams team_a
        on team_a.match_id = m.match_id
       and team_a.team_side = 'team_a'

      join public.match_teams team_b
        on team_b.match_id = m.match_id
       and team_b.team_side = 'team_b'

      join public.cricket_matches cm
        on cm.match_id = m.match_id

      where m.match_id =
              ${matchId}::uuid
        and m.sport_id = 'cricket'

      for update of
        m,
        team_a,
        team_b,
        cm
    `;

    if (rows.length === 0) {
      notFound(
        "Cricket match not found",
      );
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
      teamAName: row.team_a_name as string | null,
      teamBName: row.team_b_name as string | null,

      createdBy: row.created_by as string | null,
      venue: row.venue as string | null,

      scheduledStartTime: row.scheduled_start_time
        ?.toISOString?.() ??
        row.scheduled_start_time ??
        null,

      actualStartTime: row.actual_start_time
        ?.toISOString?.() ??
        row.actual_start_time ??
        null,

      completedAt: row.completed_at
        ?.toISOString?.() ??
        row.completed_at ??
        null,

      winnerSide: row.winner_side,

      setupSide: row.setup_side,

      phase: row.phase,

      tossWonBy: row.toss_won_by,

      tossDecision: row.toss_decision,

      tossFace: row.toss_face as string | null,

      tossRecordedAt: row.toss_recorded_at
        ?.toISOString?.() ??
        row.toss_recorded_at ??
        null,

      tossRecordedBy: row.toss_recorded_by as string | null,

      rulesSnapshot: jsonObject(
        row.rules_snapshot,
      ),

      revisedConditions: row.revised_conditions == null ? null : jsonObject(
        row.revised_conditions,
      ),

      result: row.result == null ? null : jsonObject(
        row.result,
      ),
      stateRevision: Number(row.state_revision ?? 0),
      rosterFrozenAt: row.roster_frozen_at
        ?.toISOString?.() ??
        row.roster_frozen_at ??
        null,
    };
  }
}
