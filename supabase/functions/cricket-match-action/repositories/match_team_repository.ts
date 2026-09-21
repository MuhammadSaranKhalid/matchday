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

  // Propagate a completed knockout winner into future bracket slots.
  //
  // Changing the canonical slot is only half the job: the target fixture also
  // needs a fresh participant snapshot so its lineup/start UI is immediately
  // usable. All of this remains inside the same command transaction.
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
        delete from public.match_players
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;

      await tx`
        update public.match_teams
        set team_id =
              ${winnerTeamId}::uuid
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;

      await this.materializeSide(
        tx,
        target.match_id as string,
        side,
        winnerTeamId,
      );
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
        delete from public.match_players
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;

      await tx`
        update public.match_teams
        set team_id = null
        where match_id =
                ${target.match_id}::uuid
          and team_side = ${side}
      `;
    }
  }

  // Direct-SQL participant materialization for a resolved bracket slot.
  // Tournament registration squad wins when present; otherwise active team
  // squad members are snapshotted. Cricket role flags are copied from the team
  // authority model, but future Cricket behavior remains in Edge commands.
  private async materializeSide(
    tx: Tx,
    matchId: string,
    side: TeamSide,
    teamId: string,
  ): Promise<void> {
    await tx`
      insert into public.match_players (
        match_id,
        team_side,
        user_id,
        unclaimed_id,
        display_name,
        jersey_number
      )
      select
        ${matchId}::uuid,
        ${side},
        tm.user_id,
        tm.unclaimed_id,
        coalesce(
          pr.display_name,
          up.display_name,
          'Player'
        ),
        tm.jersey_number
      from public.team_members tm
      join public.matches m
        on m.match_id = ${matchId}::uuid
      left join public.tournament_teams tt
        on tt.tournament_id = m.tournament_id
       and tt.team_id = ${teamId}::uuid
       and tt.status = 'approved'
      left join public.profiles pr
        on pr.user_id = tm.user_id
      left join public.unclaimed_players up
        on up.unclaimed_id = tm.unclaimed_id
      where tm.team_id = ${teamId}::uuid
        and tm.status = 'active'
        and tm.in_squad = true
        and (
          m.tournament_id is null
          or coalesce(cardinality(tt.squad), 0) = 0
          or tm.user_id = any(tt.squad)
          or tm.unclaimed_id = any(tt.squad)
        )
    `;

    await tx`
      insert into public.cricket_match_players (
        match_player_id,
        match_id,
        is_captain,
        is_vice_captain,
        is_wicket_keeper
      )
      select
        mp.match_player_id,
        mp.match_id,
        coalesce(
          mp.user_id =
            public._team_current_captain(
              ${teamId}::uuid
            ),
          false
        ),
        false,
        false
      from public.match_players mp
      join public.matches m
        on m.match_id = mp.match_id
      where mp.match_id = ${matchId}::uuid
        and mp.team_side = ${side}
        and m.sport_id = 'cricket'
    `;
  }
}
