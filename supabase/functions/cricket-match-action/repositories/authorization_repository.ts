import type {
  MatchBundle,
  Tx,
} from "../types.ts";
import {
  battingTeamForInnings,
  teamIdForSide,
} from "../domain/cricket.ts";
import {
  forbidden,
  unprocessable,
} from "../domain/errors.ts";

const CRICKET_SETUP_PERMISSION =
  "cricket.match.setup";
const SCORE_PERMISSION =
  "match.score";
const CANCEL_PERMISSION =
  "match.cancel";

export class AuthorizationRepository {
  // Stable generic authorization primitive. The transaction injects the
  // verified caller into request.jwt.claims, so public.can(...) evaluates the
  // authenticated actor even though this Edge Function uses a trusted direct
  // Postgres connection.
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

  async canTeam(
    tx: Tx,
    teamId: string,
    permission: string,
  ): Promise<boolean> {
    return await this.can(
      tx,
      "team",
      teamId,
      permission,
    );
  }

  async canMatch(
    tx: Tx,
    matchId: string,
    permission: string,
  ): Promise<boolean> {
    return await this.can(
      tx,
      "match",
      matchId,
      permission,
    );
  }

  // -------------------------------------------------------------------------
  // Cricket setup authority
  // -------------------------------------------------------------------------

  // Toss stage:
  //
  // peer-to-peer Cricket fixture
  //   cricket_matches.setup_side
  //       -> match_teams.team_id
  //       -> team-scoped cricket.match.setup
  //
  // neutral/tournament Cricket fixture
  //   match-scoped cricket.match.setup
  //
  // Match scope is checked first so an explicitly assigned official can run a
  // fixture even if a setup side exists.
  async canRecordToss(
    tx: Tx,
    match: MatchBundle,
  ): Promise<boolean> {
    if (
      await this.canMatch(
        tx,
        match.matchId,
        CRICKET_SETUP_PERMISSION,
      )
    ) {
      return true;
    }

    if (!match.setupSide) {
      return false;
    }

    const setupTeamId =
      teamIdForSide(
        match,
        match.setupSide,
      );

    return await this.canTeam(
      tx,
      setupTeamId,
      CRICKET_SETUP_PERMISSION,
    );
  }

  async requireTossAuthority(
    tx: Tx,
    match: MatchBundle,
  ): Promise<void> {
    if (
      !(await this.canRecordToss(
        tx,
        match,
      ))
    ) {
      forbidden(
        "This user is not allowed to record the Cricket toss for this match",
      );
    }
  }

  // After the atomic toss is committed, setup authority moves to the batting
  // side. A match-scoped Cricket official still remains valid.
  async canManageBattingSetup(
    tx: Tx,
    match: MatchBundle,
    inningsNumber = 1,
  ): Promise<boolean> {
    if (
      await this.canMatch(
        tx,
        match.matchId,
        CRICKET_SETUP_PERMISSION,
      )
    ) {
      return true;
    }

    const battingTeamId =
      battingTeamForInnings(
        match,
        inningsNumber,
      );

    return await this.canTeam(
      tx,
      battingTeamId,
      CRICKET_SETUP_PERMISSION,
    );
  }

  async requireBattingSetup(
    tx: Tx,
    match: MatchBundle,
    inningsNumber = 1,
  ): Promise<string> {
    const battingTeamId =
      battingTeamForInnings(
        match,
        inningsNumber,
      );

    if (
      await this.canMatch(
        tx,
        match.matchId,
        CRICKET_SETUP_PERMISSION,
      )
    ) {
      return battingTeamId;
    }

    if (
      await this.canTeam(
        tx,
        battingTeamId,
        CRICKET_SETUP_PERMISSION,
      )
    ) {
      return battingTeamId;
    }

    forbidden(
      "This user is not allowed to manage the batting side's Cricket setup",
    );
  }

  // -------------------------------------------------------------------------
  // Scoring authority
  // -------------------------------------------------------------------------

  async canScoreInnings(
    tx: Tx,
    match: MatchBundle,
    inningsNumber: number,
    actorId: string,
  ): Promise<boolean> {
    // Keep the explicit practice self-score product rule separate from team
    // RBAC. Practice creation is not the same thing as normal team authority.
    if (
      match.matchType === "practice" &&
      match.createdBy === actorId
    ) {
      return true;
    }

    const battingTeamId =
      battingTeamForInnings(
        match,
        inningsNumber,
      );

    if (
      await this.canTeam(
        tx,
        battingTeamId,
        SCORE_PERMISSION,
      )
    ) {
      return true;
    }

    return await this.canMatch(
      tx,
      match.matchId,
      SCORE_PERMISSION,
    );
  }

  async canCompleteMatch(
    tx: Tx,
    match: MatchBundle,
  ): Promise<boolean> {
    if (
      await this.canMatch(
        tx,
        match.matchId,
        SCORE_PERMISSION,
      )
    ) {
      return true;
    }

    for (
      const teamId of
      [match.teamAId, match.teamBId]
    ) {
      if (
        teamId &&
        await this.canTeam(
          tx,
          teamId,
          SCORE_PERMISSION,
        )
      ) {
        return true;
      }
    }

    return false;
  }

  // Tournament-control operations remain tournament-organizer actions. They
  // are separate from Cricket Match Start setup authority.
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
            t.created_by =
              ${actorId}::uuid
            or ${actorId}::uuid =
              any(t.organizers)
          )
      ) as allowed
    `;

    if (rows[0]?.allowed !== true) {
      forbidden(
        "Only a tournament organizer can perform this action",
      );
    }
  }

  // -------------------------------------------------------------------------
  // Match cancellation
  // -------------------------------------------------------------------------

  /// Cancellation can come from:
  ///
  /// 1. explicit match-scoped match.cancel grant
  ///
  /// OR
  ///
  /// 2. match.cancel on either participating team.
  ///
  /// The default matrix grants the team permission to owner + manager.
  /// Captain may receive it through a team-specific override, but does not get
  /// it automatically.
  async canCancelMatch(
    tx: Tx,
    match: MatchBundle,
  ): Promise<boolean> {
    if (
      await this.canMatch(
        tx,
        match.matchId,
        CANCEL_PERMISSION,
      )
    ) {
      return true;
    }

    for (
      const teamId of
      [match.teamAId, match.teamBId]
    ) {
      if (!teamId) continue;

      if (
        await this.canTeam(
          tx,
          teamId,
          CANCEL_PERMISSION,
        )
      ) {
        return true;
      }
    }

    return false;
  }

  async requireCancelMatch(
    tx: Tx,
    match: MatchBundle,
  ): Promise<void> {
    if (
      !(
        await this.canCancelMatch(
          tx,
          match,
        )
      )
    ) {
      forbidden(
        "This user is not allowed to cancel this match",
      );
    }
  }
}
