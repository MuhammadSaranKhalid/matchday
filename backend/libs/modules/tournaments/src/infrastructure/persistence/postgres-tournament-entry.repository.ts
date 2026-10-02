import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  EntrySnapshot,
  TournamentEntryRepository,
} from '../../application/ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';
import { assertExpectedRevision } from '../../domain/revision/assert-expected-revision.js';

interface EntryRow extends Record<string, unknown> {
  entry_id: string;
  tournament_id: string;
  team_id: string;
  registration_id: string | null;
  status: 'active' | 'withdrawn' | 'disqualified';
  entry_source: string;
  accepted_by: string | null;
  accepted_at: Date;
  withdrawn_at: Date | null;
  withdrawn_by: string | null;
  withdrawal_reason: string | null;
  squad_state: 'editable' | 'frozen';
  squad_revision: number;
  squad_frozen_at: Date | null;
}

function rowToEntrySnapshot(row: EntryRow): EntrySnapshot {
  return {
    entryId: row.entry_id,
    tournamentId: row.tournament_id,
    teamId: row.team_id,
    registrationId: row.registration_id,
    status: row.status,
    entrySource: row.entry_source,
    acceptedBy: row.accepted_by,
    acceptedAt: row.accepted_at,
    withdrawnAt: row.withdrawn_at,
    withdrawnBy: row.withdrawn_by,
    withdrawalReason: row.withdrawal_reason,
    squadState: row.squad_state,
    squadRevision: Number(row.squad_revision),
    squadFrozenAt: row.squad_frozen_at,
  };
}

const SELECT_COLUMNS = `
  entry_id, tournament_id, team_id, registration_id, status, entry_source,
  accepted_by, accepted_at, withdrawn_at, withdrawn_by, withdrawal_reason,
  squad_state, squad_revision, squad_frozen_at
`;

export class PostgresTournamentEntryRepository implements TournamentEntryRepository {
  async lockEntry(tx: CommandQueryExecutor, entryId: string): Promise<EntrySnapshot> {
    const result = await tx.query<EntryRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_entries
       WHERE entry_id = $1
       FOR UPDATE`,
      [entryId],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Entry ${entryId} not found`, { entryId });
    }
    return rowToEntrySnapshot(row);
  }

  async findEntry(
    tx: CommandQueryExecutor,
    entryId: string,
  ): Promise<EntrySnapshot | null> {
    const result = await tx.query<EntryRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_entries
       WHERE entry_id = $1`,
      [entryId],
    );
    const row = result.rows[0];
    return row ? rowToEntrySnapshot(row) : null;
  }

  async findActiveEntryByTeam(
    tx: CommandQueryExecutor,
    tournamentId: string,
    teamId: string,
  ): Promise<EntrySnapshot | null> {
    const result = await tx.query<EntryRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_entries
       WHERE tournament_id = $1 AND team_id = $2 AND status = 'active'`,
      [tournamentId, teamId],
    );
    const row = result.rows[0];
    return row ? rowToEntrySnapshot(row) : null;
  }

  async countActiveEntries(
    tx: CommandQueryExecutor,
    tournamentId: string,
  ): Promise<number> {
    const result = await tx.query<{ count: string }>(
      `SELECT count(*) AS count
       FROM public.tournament_entries
       WHERE tournament_id = $1 AND status = 'active'`,
      [tournamentId],
    );
    return Number(result.rows[0]?.count ?? 0);
  }

  async createEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly tournamentId: string;
      readonly teamId: string;
      readonly registrationId: string;
      readonly acceptedBy: string;
      readonly entrySource?: string;
    },
  ): Promise<EntrySnapshot> {
    const result = await tx.query<EntryRow>(
      `INSERT INTO public.tournament_entries
        (tournament_id, team_id, registration_id, accepted_by, entry_source, status,
         squad_state, squad_revision)
       VALUES ($1, $2, $3, $4, $5, 'active', 'editable', 1)
       RETURNING ${SELECT_COLUMNS}`,
      [
        params.tournamentId,
        params.teamId,
        params.registrationId,
        params.acceptedBy,
        params.entrySource ?? 'application',
      ],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Failed to create entry: no row returned');
    }
    return rowToEntrySnapshot(row);
  }

  async withdrawEntry(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly withdrawnBy: string;
      readonly withdrawalReason?: string;
    },
  ): Promise<EntrySnapshot> {
    const result = await tx.query<EntryRow>(
      `UPDATE public.tournament_entries
       SET status = 'withdrawn', withdrawn_by = $2, withdrawn_at = now(),
           withdrawal_reason = $3, updated_at = now()
       WHERE entry_id = $1
       RETURNING ${SELECT_COLUMNS}`,
      [params.entryId, params.withdrawnBy, params.withdrawalReason ?? null],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Entry ${params.entryId} not found for withdrawal`, {
        entryId: params.entryId,
      });
    }
    return rowToEntrySnapshot(row);
  }

  async bumpSquadRevision(
    tx: CommandQueryExecutor,
    params: { readonly entryId: string; readonly expectedRevision?: number },
  ): Promise<number> {
    const result = await tx.query<{ squad_revision: number; entry_id: string }>(
      `UPDATE public.tournament_entries
       SET squad_revision = squad_revision + 1, updated_at = now()
       WHERE entry_id = $1
       RETURNING squad_revision, entry_id`,
      [params.entryId],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Entry ${params.entryId} not found for squad revision bump`, {
        entryId: params.entryId,
      });
    }
    const newRevision = Number(row.squad_revision);
    if (params.expectedRevision !== undefined) {
      // After bump, new = expected + 1
      assertExpectedRevision(params.expectedRevision, newRevision - 1);
    }
    return newRevision;
  }

  async freezeSquad(
    tx: CommandQueryExecutor,
    params: { readonly entryId: string; readonly expectedRevision?: number },
  ): Promise<number> {
    const result = await tx.query<{ squad_revision: number }>(
      `UPDATE public.tournament_entries
       SET squad_state = 'frozen', squad_frozen_at = now(),
           squad_revision = squad_revision + 1, updated_at = now()
       WHERE entry_id = $1 AND squad_state = 'editable'
       RETURNING squad_revision`,
      [params.entryId],
    );
    const row = result.rows[0];
    if (!row) {
      // Either not found or already frozen — fetch to distinguish
      const existing = await this.findEntry(tx, params.entryId);
      if (!existing) {
        throw TournamentError.notFound(`Entry ${params.entryId} not found`, {
          entryId: params.entryId,
        });
      }
      throw TournamentError.invalidState(
        `Cannot freeze squad: entry squad is already frozen`,
        { entryId: params.entryId, squadState: existing.squadState },
      );
    }
    const newRevision = Number(row.squad_revision);
    if (params.expectedRevision !== undefined) {
      assertExpectedRevision(params.expectedRevision, newRevision - 1);
    }
    return newRevision;
  }
}
