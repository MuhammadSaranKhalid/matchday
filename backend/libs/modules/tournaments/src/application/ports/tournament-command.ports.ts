import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';

export interface CommandQueryExecutor {
  query<T extends Record<string, unknown> = Record<string, unknown>>(
    sql: string,
    params?: readonly unknown[],
  ): Promise<{ rows: T[]; rowCount?: number | null }>;
}

export interface TournamentCommandContext {
  readonly tx: CommandQueryExecutor;
  readonly principal: AuthenticatedPrincipal;
  readonly commandId: string;
}

export interface TournamentCommandExecutionResult<T = unknown> {
  readonly result: T;
  readonly status: 'executed' | 'replayed';
}

export interface TournamentCommandHandler<C, R> {
  execute(
    context: TournamentCommandContext,
    command: C,
  ): Promise<R>;
}

export const TOURNAMENT_TRANSACTION_EXECUTOR = Symbol('TOURNAMENT_TRANSACTION_EXECUTOR');

export interface TournamentTransactionExecutor {
  withCommandTransaction<T>(
    principal: AuthenticatedPrincipal,
    work: (tx: CommandQueryExecutor) => Promise<T>,
  ): Promise<T>;
}
