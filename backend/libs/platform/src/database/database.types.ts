import type { QueryConfig, QueryResult, QueryResultRow } from 'pg';

export interface QueryExecutor {
  query<T extends QueryResultRow = QueryResultRow>(
    queryTextOrConfig: string | QueryConfig,
    values?: readonly unknown[],
  ): Promise<QueryResult<T>>;
}

export interface TransactionPrincipal {
  readonly userId: string;
  readonly role: 'authenticated';
  readonly sessionId?: string;
  readonly appMetadata: Readonly<Record<string, unknown>>;
}

export type TransactionWork<T> = (database: QueryExecutor) => Promise<T>;
