import type { CommandQueryExecutor } from '../../application/ports/tournament-command.ports.js';
import type {
  PaymentSnapshot,
  TournamentPaymentRepository,
} from '../../application/ports/tournament-repository.ports.js';
import { TournamentError } from '../../domain/errors/tournament-error-codes.js';

interface PaymentRow extends Record<string, unknown> {
  payment_id: string;
  entry_id: string;
  tournament_id: string;
  amount: string | number;
  payment_channel: string;
  payment_reference: string | null;
  notes: string | null;
  recorded_by: string | null;
  recorded_at: Date;
  is_void: boolean;
  voided_at: Date | null;
  voided_by: string | null;
  void_reason: string | null;
}

function rowToPaymentSnapshot(row: PaymentRow): PaymentSnapshot {
  return {
    paymentId: row.payment_id,
    entryId: row.entry_id,
    tournamentId: row.tournament_id,
    amount: Number(row.amount),
    paymentChannel: row.payment_channel,
    paymentReference: row.payment_reference,
    notes: row.notes,
    recordedBy: row.recorded_by,
    recordedAt: row.recorded_at,
    isVoid: Boolean(row.is_void),
    voidedAt: row.voided_at,
    voidedBy: row.voided_by,
    voidReason: row.void_reason,
  };
}

const SELECT_COLUMNS = `
  payment_id, entry_id, tournament_id, amount, payment_channel, payment_reference,
  notes, recorded_by, recorded_at, is_void, voided_at, voided_by, void_reason
`;

export class PostgresTournamentPaymentRepository implements TournamentPaymentRepository {
  async lockPayment(
    tx: CommandQueryExecutor,
    paymentId: string,
  ): Promise<PaymentSnapshot> {
    const result = await tx.query<PaymentRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_entry_payments
       WHERE payment_id = $1
       FOR UPDATE`,
      [paymentId],
    );
    const row = result.rows[0];
    if (!row) {
      throw TournamentError.notFound(`Payment ${paymentId} not found`, { paymentId });
    }
    return rowToPaymentSnapshot(row);
  }

  async findPayment(
    tx: CommandQueryExecutor,
    paymentId: string,
  ): Promise<PaymentSnapshot | null> {
    const result = await tx.query<PaymentRow>(
      `SELECT ${SELECT_COLUMNS}
       FROM public.tournament_entry_payments
       WHERE payment_id = $1`,
      [paymentId],
    );
    const row = result.rows[0];
    return row ? rowToPaymentSnapshot(row) : null;
  }

  async getEntryNonVoidedTotal(
    tx: CommandQueryExecutor,
    entryId: string,
  ): Promise<number> {
    const result = await tx.query<{ total: string }>(
      `SELECT coalesce(sum(amount), 0) AS total
       FROM public.tournament_entry_payments
       WHERE entry_id = $1 AND is_void = false`,
      [entryId],
    );
    return Number(result.rows[0]?.total ?? 0);
  }

  async createPayment(
    tx: CommandQueryExecutor,
    params: {
      readonly entryId: string;
      readonly tournamentId: string;
      readonly amount: number;
      readonly paymentChannel: string;
      readonly paymentReference?: string;
      readonly notes?: string;
      readonly recordedBy: string;
    },
  ): Promise<string> {
    const result = await tx.query<{ payment_id: string }>(
      `INSERT INTO public.tournament_entry_payments
        (entry_id, tournament_id, amount, payment_channel, payment_reference,
         notes, recorded_by, is_void)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false)
       RETURNING payment_id`,
      [
        params.entryId,
        params.tournamentId,
        params.amount,
        params.paymentChannel,
        params.paymentReference ?? null,
        params.notes ?? null,
        params.recordedBy,
      ],
    );
    const row = result.rows[0];
    if (!row) {
      throw new Error('Failed to create payment: no row returned');
    }
    return row.payment_id;
  }

  async voidPayment(
    tx: CommandQueryExecutor,
    params: {
      readonly paymentId: string;
      readonly voidedBy: string;
      readonly voidReason: string;
    },
  ): Promise<void> {
    await tx.query(
      `UPDATE public.tournament_entry_payments
       SET is_void = true, voided_by = $2, voided_at = now(), void_reason = $3, updated_at = now()
       WHERE payment_id = $1`,
      [params.paymentId, params.voidedBy, params.voidReason],
    );
  }
}
