// TeamRepository — team authority and roster validation via database helpers.
//
// All methods MUST be called AFTER setTransactionJwtClaims has installed the
// verified actor identity so that public.is_team_manager() sees auth.uid().

import type { Tx } from "../types.ts";
import { forbidden, unprocessable } from "../domain/errors.ts";

export class TeamRepository {
  /**
   * Returns true if the current transaction actor manages the given team.
   * Delegates to public.is_team_manager(team_id) which uses auth.uid().
   */
  async isTeamManager(tx: Tx, teamId: string): Promise<boolean> {
    const rows = await tx`
      select public.is_team_manager(${teamId}::uuid) as result
    `;
    return rows[0]?.result === true;
  }

  /**
   * Validates that all players in `xi` are active squad members of `teamId`.
   * Throws RULE_VIOLATION (422) if any player is invalid.
   */
  async validateTeamXi(tx: Tx, teamId: string, xi: string[]): Promise<void> {
    if (xi.length === 0) return;
    await tx`
      select public._validate_team_xi(${teamId}::uuid, ${xi}::uuid[])
    `;
  }

  /**
   * Validates that the team has a current captain or owner.
   * Throws RULE_VIOLATION (422) if absent.
   */
  async validateTeamCaptain(tx: Tx, teamId: string): Promise<void> {
    const rows = await tx`
      select public._team_current_captain(${teamId}::uuid) as captain
    `;
    if (rows[0]?.captain == null) {
      unprocessable(
        `Team ${teamId} must have a captain or owner before a match can be created`,
      );
    }
  }

  /**
   * Asserts the actor manages the team. Throws FORBIDDEN (403) if not.
   */
  async requireTeamManager(tx: Tx, teamId: string, message: string): Promise<void> {
    if (!(await this.isTeamManager(tx, teamId))) {
      forbidden(message);
    }
  }
}
