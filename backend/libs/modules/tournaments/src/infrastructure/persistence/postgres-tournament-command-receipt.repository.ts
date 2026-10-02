import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  TournamentCommandReceiptRecord,
  TournamentCommandReceiptRepository,
} from '../../application/ports/tournament-repository.ports.js';

interface ReceiptRow extends Record<string, unknown> {
  command_id: string;
  actor_id: string;
  action: string;
  tournament_id: string | null;
  request_fingerprint: string;
  response_payload: unknown;
  created_at: Date;
  completed_at: Date;
}

export class PostgresTournamentCommandReceiptRepository
  implements TournamentCommandReceiptRepository
{
  async findReceipt(
    tx: CommandQueryExecutor,
    commandId: string,
  ): Promise<TournamentCommandReceiptRecord | null> {
    const result = await tx.query<ReceiptRow>(
      `SELECT
        command_id,
        actor_id,
        action,
        tournament_id,
        request_fingerprint,
        response_payload,
        created_at,
        completed_at
      FROM private.tournament_command_receipts
      WHERE command_id = $1`,
      [commandId],
    );

    const row = result.rows[0];
    if (!row) {
      return null;
    }

    return {
      commandId: row.command_id,
      actorId: row.actor_id,
      action: row.action,
      tournamentId: row.tournament_id,
      requestFingerprint: row.request_fingerprint,
      responsePayload: row.response_payload,
      createdAt: new Date(row.created_at),
      completedAt: new Date(row.completed_at),
    };
  }

  async saveReceipt(
    tx: CommandQueryExecutor,
    receipt: {
      readonly commandId: string;
      readonly actorId: string;
      readonly action: string;
      readonly tournamentId?: string | null;
      readonly requestFingerprint: string;
      readonly responsePayload: unknown;
    },
  ): Promise<void> {
    await tx.query(
      `INSERT INTO private.tournament_command_receipts (
        command_id,
        actor_id,
        action,
        tournament_id,
        request_fingerprint,
        response_payload,
        created_at,
        completed_at
      ) VALUES ($1, $2, $3, $4, $5, $6, now(), now())`,
      [
        receipt.commandId,
        receipt.actorId,
        receipt.action,
        receipt.tournamentId ?? null,
        receipt.requestFingerprint,
        JSON.stringify(receipt.responsePayload),
      ],
    );
  }
}
