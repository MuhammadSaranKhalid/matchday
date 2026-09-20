import type {
  MatchBundle,
  TeamSide,
  Tx,
} from "../types.ts";
import {
  battingTeamForInnings,
  teamSideFor,
} from "../domain/cricket.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

export class AuthorizationRepository {
  isMatchCreator(
    match: MatchBundle,
    actorId: string,
  ): boolean {
    return match.createdBy != null && match.createdBy === actorId;
  }

  // "Match captain" is historical match state first, current team role second.
  //
  // This mirrors the old DB helper semantics without making Cricket commands
  // depend on _is_match_side_captain().
  async isSideCaptain(
    tx: Tx,
    match: MatchBundle,
    teamId: string,
    actorId: string,
  ): Promise<boolean> {
    const side = teamSideFor(match, teamId);

    const rows = await tx`
      select
        exists (
          select 1
          from public.match_players mp
          join public.cricket_match_players cmp
            on cmp.match_player_id = mp.match_player_id
           and cmp.match_id = mp.match_id
          where mp.match_id = ${match.matchId}::uuid
            and mp.user_id = ${actorId}::uuid
            and mp.team_side = ${side}
            and cmp.is_captain = true
        ) as lineup_captain,

        (
          coalesce(
            (
              select tm.user_id
              from public.team_members tm
              join public.team_member_roles tmr
                on tmr.membership_id = tm.membership_id
              where tm.team_id = ${teamId}::uuid
                and tmr.role_key = 'captain'
                and tm.status = 'active'
                and tm.user_id is not null
              order by tm.joined_at asc
              limit 1
            ),
            (
              select tm.user_id
              from public.team_members tm
              join public.team_member_roles tmr
                on tmr.membership_id = tm.membership_id
              where tm.team_id = ${teamId}::uuid
                and tmr.role_key = 'owner'
                and tm.status = 'active'
                and tm.user_id is not null
              order by tm.joined_at asc
              limit 1
            )
          ) = ${actorId}::uuid
        ) as current_team_captain
    `;

    return rows[0]?.lineup_captain === true ||
      rows[0]?.current_team_captain === true;
  }

  async isAnyMatchCaptain(
    tx: Tx,
    match: MatchBundle,
    actorId: string,
  ): Promise<boolean> {
    const checks: Promise<boolean>[] = [];

    if (match.teamAId) {
      checks.push(
        this.isSideCaptain(
          tx,
          match,
          match.teamAId,
          actorId,
        ),
      );
    }

    if (match.teamBId) {
      checks.push(
        this.isSideCaptain(
          tx,
          match,
          match.teamBId,
          actorId,
        ),
      );
    }

    const results = await Promise.all(checks);
    return results.some(Boolean);
  }

  // Stable generic authorization primitive.
  //
  // We KEEP public.can(...). It is infrastructure shared by the whole product,
  // not a Cricket workflow command. request.jwt.claims is injected at the
  // beginning of the transaction, so auth.uid() inside can(...) is the verified
  // caller.
  async can(
    tx: Tx,
    scope: "team" | "match",
    entityId: string,
    permission: string,
  ): Promise<boolean> {
    const rows = await tx`
      select public.can(
        ${scope},
        ${entityId}::uuid,
        ${permission}
      ) as allowed
    `;
    return rows[0]?.allowed === true;
  }

  async canScoreInnings(
    tx: Tx,
    match: MatchBundle,
    inningsNumber: number,
    actorId: string,
  ): Promise<boolean> {
    const battingTeamId =
      battingTeamForInnings(match, inningsNumber);

    // Practice creator may self-score.
    if (
      match.matchType === "practice" &&
      match.createdBy === actorId
    ) {
      return true;
    }

    if (
      await this.isSideCaptain(
        tx,
        match,
        battingTeamId,
        actorId,
      )
    ) {
      return true;
    }

    if (
      await this.can(
        tx,
        "team",
        battingTeamId,
        "match.score",
      )
    ) {
      return true;
    }

    return await this.can(
      tx,
      "match",
      match.matchId,
      "match.score",
    );
  }

  async requireTournamentOrganizer(
    tx: Tx,
    match: MatchBundle,
    actorId: string,
  ): Promise<void> {
    if (!match.tournamentId) {
      unprocessable(
        "This operation is only available for tournament matches",
      );
    }

    const rows = await tx`
      select exists (
        select 1
        from public.tournaments t
        where t.tournament_id =
              ${match.tournamentId}::uuid
          and (
            t.created_by = ${actorId}::uuid
            or ${actorId}::uuid = any(t.organizers)
          )
      ) as allowed
    `;

    if (rows[0]?.allowed !== true) {
      forbidden(
        "Only a tournament organizer can perform this action",
      );
    }
  }

  async requireBattingCaptain(
    tx: Tx,
    match: MatchBundle,
    inningsNumber: number,
    actorId: string,
  ): Promise<string> {
    const battingTeamId =
      battingTeamForInnings(match, inningsNumber);

    if (
      !(await this.isSideCaptain(
        tx,
        match,
        battingTeamId,
        actorId,
      ))
    ) {
      forbidden(
        "Only the batting side captain can perform this action",
      );
    }

    return battingTeamId;
  }
}
