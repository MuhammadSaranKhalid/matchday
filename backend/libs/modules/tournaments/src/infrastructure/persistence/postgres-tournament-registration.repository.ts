import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  ProposalMemberSnapshot,
  RegistrationSnapshot,
  TournamentRegistrationRepository,
} from '../../application/ports/tournament-repository.ports.js';
import type { ProposedSquadMember } from '../../domain/command/participation-commands.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

interface RegistrationRow extends Record<string, unknown> {
  registration_id: string;
  tournament_id: string;
  team_id: string;
  registered_by: string | null;
  registered_at: Date;
  status: 'pending' | 'approved' | 'rejected' | 'withdrawn';
  message: string | null;
  decision_reason: string | null;
  decided_by: string | null;
  decided_at: Date | null;
  withdrawn_at: Date | null;
  withdrawn_by: string | null;
  withdrawal_reason: string | null;
}

interface ProposalMemberRow extends Record<string, unknown> {
  proposal_member_id: string;
  registration_id: string;
  tournament_id: string;
  team_id: string;
  user_id: string | null;
  unclaimed_id: string | null;
}

function rowToRegistrationSnapshot(row: RegistrationRow): RegistrationSnapshot {
  return {
    registrationId: row.registration_id,
    tournamentId: row.tournament_id,
    teamId: row.team_id,
    registeredBy: row.registered_by,
    registeredAt: row.registered_at,
    status: row.status,
    message: row.message,
    decisionReason: row.decision_reason,
    decidedBy: row.decided_by,
    decidedAt: row.decided_at,
    withdrawnAt: row.withdrawn_at,
    withdrawnBy: row.withdrawn_by,
    withdrawalReason: row.withdrawal_reason,
  };
}

function rowToProposalMemberSnapshot(row: ProposalMemberRow): ProposalMemberSnapshot {
  return {
    proposalMemberId: row.proposal_member_id,
    registrationId: row.registration_id,
    tournamentId: row.tournament_id,
    teamId: row.team_id,
    userId: row.user_id,
    unclaimedId: row.unclaimed_id,
  };
}

export class PostgresTournamentRegistrationRepository
  implements TournamentRegistrationRepository
{
  async lockRegistration(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<RegistrationSnapshot> {
    const result = await tx.query<RegistrationRow>(
      `SELECT
        registration_id, tournament_id, team_id, registered_by, registered_at,
        status, message, decision_reason, decided_by, decided_at,
        withdrawn_at, withdrawn_by, withdrawal_reason
       FROM public.tournament_registrations
       WHERE registration_id = $1
       FOR UPDATE`,
      [registrationId],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Registration ${registrationId} not found`, {
        registrationId,
      });
    }
    return rowToRegistrationSnapshot(row);
  }

  async findRegistration(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<RegistrationSnapshot | null> {
    const result = await tx.query<RegistrationRow>(
      `SELECT
        registration_id, tournament_id, team_id, registered_by, registered_at,
        status, message, decision_reason, decided_by, decided_at,
        withdrawn_at, withdrawn_by, withdrawal_reason
       FROM public.tournament_registrations
       WHERE registration_id = $1`,
      [registrationId],
    );
    const row = result.rows[0];
    return row ? rowToRegistrationSnapshot(row) : null;
  }

  async hasPendingRegistration(
    tx: CommandQueryExecutor,
    tournamentId: string,
    teamId: string,
  ): Promise<boolean> {
    const result = await tx.query<{ exists: boolean }>(
      `SELECT EXISTS(
        SELECT 1 FROM public.tournament_registrations
        WHERE tournament_id = $1 AND team_id = $2 AND status = 'pending'
      ) as "exists"`,
      [tournamentId, teamId],
    );
    return Boolean(result.rows[0]?.exists);
  }

  async findTeamPendingRegistration(
    tx: CommandQueryExecutor,
    tournamentId: string,
    teamId: string,
  ): Promise<RegistrationSnapshot | null> {
    const result = await tx.query<RegistrationRow>(
      `SELECT
        registration_id, tournament_id, team_id, registered_by, registered_at,
        status, message, decision_reason, decided_by, decided_at,
        withdrawn_at, withdrawn_by, withdrawal_reason
       FROM public.tournament_registrations
       WHERE tournament_id = $1 AND team_id = $2 AND status = 'pending'`,
      [tournamentId, teamId],
    );
    const row = result.rows[0];
    return row ? rowToRegistrationSnapshot(row) : null;
  }

  async createRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly tournamentId: string;
      readonly teamId: string;
      readonly registeredBy: string;
      readonly message?: string;
    },
  ): Promise<string> {
    const result = await tx.query<{ registration_id: string }>(
      `INSERT INTO public.tournament_registrations
        (tournament_id, team_id, registered_by, message, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING registration_id`,
      [params.tournamentId, params.teamId, params.registeredBy, params.message ?? null],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Failed to create registration: no row returned');
    }
    return row.registration_id;
  }

  async createProposalMembers(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly tournamentId: string;
      readonly teamId: string;
      readonly submittedBy: string;
      readonly members: readonly ProposedSquadMember[];
    },
  ): Promise<void> {
    if (params.members.length === 0) return;

    const valuePlaceholders: string[] = [];
    const queryParams: unknown[] = [
      params.registrationId,
      params.tournamentId,
      params.teamId,
      params.submittedBy,
    ];

    let pi = 5; // $1–$4 are fixed params above
    for (const member of params.members) {
      valuePlaceholders.push(`($1, $2, $3, $4, $${pi}, $${pi + 1})`);
      queryParams.push(member.userId ?? null, member.unclaimedId ?? null);
      pi += 2;
    }

    await tx.query(
      `INSERT INTO public.tournament_registration_squad_members
        (registration_id, tournament_id, team_id, submitted_by, user_id, unclaimed_id)
       VALUES ${valuePlaceholders.join(', ')}`,
      queryParams,
    );
  }

  async getProposalMembers(
    tx: CommandQueryExecutor,
    registrationId: string,
  ): Promise<readonly ProposalMemberSnapshot[]> {
    const result = await tx.query<ProposalMemberRow>(
      `SELECT proposal_member_id, registration_id, tournament_id, team_id, user_id, unclaimed_id
       FROM public.tournament_registration_squad_members
       WHERE registration_id = $1
       ORDER BY submitted_at ASC`,
      [registrationId],
    );
    return result.rows.map(rowToProposalMemberSnapshot);
  }

  async resolveRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly status: 'approved' | 'rejected';
      readonly decidedBy: string;
      readonly decisionReason?: string;
    },
  ): Promise<void> {
    await tx.query(
      `UPDATE public.tournament_registrations
       SET status = $2, decided_by = $3, decided_at = now(), decision_reason = $4, updated_at = now()
       WHERE registration_id = $1`,
      [params.registrationId, params.status, params.decidedBy, params.decisionReason ?? null],
    );
  }

  async withdrawRegistration(
    tx: CommandQueryExecutor,
    params: {
      readonly registrationId: string;
      readonly withdrawnBy: string;
      readonly withdrawalReason?: string;
    },
  ): Promise<void> {
    await tx.query(
      `UPDATE public.tournament_registrations
       SET status = 'withdrawn', withdrawn_by = $2, withdrawn_at = now(), withdrawal_reason = $3, updated_at = now()
       WHERE registration_id = $1`,
      [params.registrationId, params.withdrawnBy, params.withdrawalReason ?? null],
    );
  }
}
