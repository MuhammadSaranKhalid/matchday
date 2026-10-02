import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  ProposalMemberSnapshot,
  SquadMemberSnapshot,
  TournamentSquadRepository,
} from '../../application/ports/tournament-repository.ports.js';
import type { ProposedSquadMember } from '../../domain/command/participation-commands.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

interface SquadMemberRow extends Record<string, unknown> {
  squad_member_id: string;
  entry_id: string;
  tournament_id: string;
  user_id: string | null;
  unclaimed_id: string | null;
  membership_status: 'active' | 'removed';
  added_by: string | null;
  added_at: Date;
  removed_by: string | null;
  removed_at: Date | null;
  removal_reason: string | null;
}

function rowToSquadMemberSnapshot(row: SquadMemberRow): SquadMemberSnapshot {
  return {
    squadMemberId: row.squad_member_id,
    entryId: row.entry_id,
    tournamentId: row.tournament_id,
    userId: row.user_id,
    unclaimedId: row.unclaimed_id,
    membershipStatus: row.membership_status,
    addedBy: row.added_by,
    addedAt: row.added_at,
    removedBy: row.removed_by,
    removedAt: row.removed_at,
    removalReason: row.removal_reason,
  };
}

const SELECT_COLUMNS = `
  squad_member_id, entry_id, tournament_id, user_id, unclaimed_id,
  membership_status, added_by, added_at, removed_by, removed_at, removal_reason
`;

export class PostgresTournamentSquadRepository implements TournamentSquadRepository {
  async lockSquadMember(
    tx: CommandQueryExecutor,
    squadMemberId: string,
  ): Promise<SquadMemberSnapshot> {
    const result = await tx.query<SquadMemberRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_squad_members
       WHERE squad_member_id = $1
       FOR UPDATE`,
      [squadMemberId],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Squad member ${squadMemberId} not found`, {
        squadMemberId,
      });
    }
    return rowToSquadMemberSnapshot(row);
  }

  async findSquadMember(
    tx: CommandQueryExecutor,
    squadMemberId: string,
  ): Promise<SquadMemberSnapshot | null> {
    const result = await tx.query<SquadMemberRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_squad_members
       WHERE squad_member_id = $1`,
      [squadMemberId],
    );
    const row = result.rows[0];
    return row ? rowToSquadMemberSnapshot(row) : null;
  }

  async isPlayerInActiveTeamRoster(
    tx: CommandQueryExecutor,
    teamId: string,
    player: ProposedSquadMember,
  ): Promise<boolean> {
    if (player.userId) {
      const result = await tx.query<{ exists: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM public.team_members
           WHERE team_id = $1 AND user_id = $2 AND status = 'active'
         ) AS exists`,
        [teamId, player.userId],
      );
      return Boolean(result.rows[0]?.exists);
    } else if (player.unclaimedId) {
      const result = await tx.query<{ exists: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM public.team_members
           WHERE team_id = $1 AND unclaimed_id = $2 AND status = 'active'
         ) AS exists`,
        [teamId, player.unclaimedId],
      );
      return Boolean(result.rows[0]?.exists);
    }
    return false;
  }

  async isPlayerInActiveTournamentSquad(
    tx: CommandQueryExecutor,
    tournamentId: string,
    player: ProposedSquadMember,
    excludeEntryId?: string,
  ): Promise<boolean> {
    if (player.userId) {
      const result = await tx.query<{ exists: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM public.tournament_squad_members
           WHERE tournament_id = $1 AND user_id = $2 AND membership_status = 'active'
             AND ($3::uuid IS NULL OR entry_id != $3::uuid)
         ) AS exists`,
        [tournamentId, player.userId, excludeEntryId ?? null],
      );
      return Boolean(result.rows[0]?.exists);
    } else if (player.unclaimedId) {
      const result = await tx.query<{ exists: boolean }>(
        `SELECT EXISTS (
           SELECT 1 FROM public.tournament_squad_members
           WHERE tournament_id = $1 AND unclaimed_id = $2 AND membership_status = 'active'
             AND ($3::uuid IS NULL OR entry_id != $3::uuid)
         ) AS exists`,
        [tournamentId, player.unclaimedId, excludeEntryId ?? null],
      );
      return Boolean(result.rows[0]?.exists);
    }
    return false;
  }

  async materializeSquadFromProposal(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly teamId: string;
      readonly addedBy: string;
      readonly proposalMembers: readonly ProposalMemberSnapshot[];
    },
  ): Promise<void> {
    if (params.proposalMembers.length === 0) return;

    const valuePlaceholders: string[] = [];
    const queryParams: unknown[] = [
      params.entryId,
      params.tournamentId,
      params.addedBy,
    ];

    let pi = 4;
    for (const member of params.proposalMembers) {
      valuePlaceholders.push(`($1, $2, $3, $${pi}, $${pi + 1})`);
      queryParams.push(member.userId ?? null, member.unclaimedId ?? null);
      pi += 2;
    }

    await tx.query(
      `INSERT INTO public.tournament_squad_members
        (entry_id, tournament_id, added_by, user_id, unclaimed_id, membership_status)
       VALUES ${valuePlaceholders.join(', ')}
       ON CONFLICT DO NOTHING`,
      queryParams,
    );
  }

  async addOrReactivateSquadMember(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly player: ProposedSquadMember;
      readonly addedBy: string;
    },
  ): Promise<string> {
    // Try to reactivate a previously removed member first
    const userId = params.player.userId ?? null;
    const unclaimedId = params.player.unclaimedId ?? null;

    if (userId) {
      const reactivated = await tx.query<{ squad_member_id: string }>(
        `UPDATE public.tournament_squad_members
         SET membership_status = 'active', removed_by = NULL, removed_at = NULL,
             removal_reason = NULL, added_by = $3, added_at = now(), updated_at = now()
         WHERE entry_id = $1 AND user_id = $2 AND membership_status = 'removed'
         RETURNING squad_member_id`,
        [params.entryId, userId, params.addedBy],
      );
      if (reactivated.rows[0]) return reactivated.rows[0].squad_member_id;
    } else if (unclaimedId) {
      const reactivated = await tx.query<{ squad_member_id: string }>(
        `UPDATE public.tournament_squad_members
         SET membership_status = 'active', removed_by = NULL, removed_at = NULL,
             removal_reason = NULL, added_by = $3, added_at = now(), updated_at = now()
         WHERE entry_id = $1 AND unclaimed_id = $2 AND membership_status = 'removed'
         RETURNING squad_member_id`,
        [params.entryId, unclaimedId, params.addedBy],
      );
      if (reactivated.rows[0]) return reactivated.rows[0].squad_member_id;
    }

    // Insert fresh
    const result = await tx.query<{ squad_member_id: string }>(
      `INSERT INTO public.tournament_squad_members
        (entry_id, tournament_id, added_by, user_id, unclaimed_id, membership_status)
       VALUES ($1, $2, $3, $4, $5, 'active')
       RETURNING squad_member_id`,
      [params.entryId, params.tournamentId, params.addedBy, userId, unclaimedId],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Failed to add squad member: no row returned');
    }
    return row.squad_member_id;
  }

  async removeSquadMember(
    tx: CommandQueryExecutor,
    params: {
      readonly squadMemberId: string;
      readonly removedBy: string;
      readonly removalReason?: string;
    },
  ): Promise<void> {
    await tx.query(
      `UPDATE public.tournament_squad_members
       SET membership_status = 'removed', removed_by = $2, removed_at = now(),
           removal_reason = $3, updated_at = now()
       WHERE squad_member_id = $1`,
      [params.squadMemberId, params.removedBy, params.removalReason ?? null],
    );
  }

  async removeAllActiveMembersForEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly removedBy: string;
      readonly removalReason: string;
    },
  ): Promise<void> {
    await tx.query(
      `UPDATE public.tournament_squad_members
       SET membership_status = 'removed', removed_by = $2, removed_at = now(),
           removal_reason = $3, updated_at = now()
       WHERE entry_id = $1 AND membership_status = 'active'`,
      [params.entryId, params.removedBy, params.removalReason],
    );
  }
}
