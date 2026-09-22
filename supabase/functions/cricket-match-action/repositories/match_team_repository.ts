import type {
  TeamSide,
  Tx,
} from "../types.ts";
import {
  conflict,
  notFound,
} from "../domain/errors.ts";

export class MatchTeamRepository {
  async teamIdForSide(
    tx: Tx,
    matchId: string,
    side: TeamSide,
  ): Promise<string> {
    const rows = await tx`
      select team_id
      from public.match_teams
      where match_id =
              ${matchId}::uuid
        and team_side = ${side}
      limit 1
    `;

    const teamId =
      rows[0]?.team_id as string | null | undefined;

    if (!teamId) {
      notFound(
        `${side} is not resolved to a team`,
      );
    }

    return teamId;
  }

  // Propagate a completed knockout winner by resolving the canonical slot.
  // The match_teams trigger is the sole owner of participant materialization;
  // it snapshots the registered tournament squad inside this transaction.
  async advanceWinner(
    tx: Tx,
    sourceMatchId: string,
    winnerSide: TeamSide,
  ): Promise<void> {
    const winnerTeamId =
      await this.teamIdForSide(
        tx,
        sourceMatchId,
        winnerSide,
      );

    const targets = await tx`
      select
        m.match_id,
        m.status::text as status,
        case
          when m.prev_match_a_id =
                 ${sourceMatchId}::uuid
            then 'team_a'
          when m.prev_match_b_id =
                 ${sourceMatchId}::uuid
            then 'team_b'
        end as target_side
      from public.matches m
      where m.prev_match_a_id =
              ${sourceMatchId}::uuid
         or m.prev_match_b_id =
              ${sourceMatchId}::uuid
      for update
    `;

    for (const target of targets) {
      const side =
        target.target_side as TeamSide | null;

      if (!side) continue;

      if (target.status !== "scheduled") {
        conflict(
          "Cannot change a bracket slot after the target match has started",
        );
      }

      await tx`
        update public.match_teams
        set team_id =
              ${winnerTeamId}::uuid
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;
    }
  }

  // Used by undo/reschedule when an earlier winner is no longer final.
  async clearAdvancedWinner(
    tx: Tx,
    sourceMatchId: string,
  ): Promise<void> {
    const targets = await tx`
      select
        m.match_id,
        m.status::text as status,
        case
          when m.prev_match_a_id =
                 ${sourceMatchId}::uuid
            then 'team_a'
          when m.prev_match_b_id =
                 ${sourceMatchId}::uuid
            then 'team_b'
        end as target_side
      from public.matches m
      where m.prev_match_a_id =
              ${sourceMatchId}::uuid
         or m.prev_match_b_id =
              ${sourceMatchId}::uuid
      for update
    `;

    for (const target of targets) {
      const side =
        target.target_side as TeamSide | null;

      if (!side) continue;

      if (target.status !== "scheduled") {
        conflict(
          "Cannot reopen a feeder result after the dependent match has started",
        );
      }

      await tx`
        update public.match_teams
        set team_id = null
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;
    }
  }
}
