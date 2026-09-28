import type { QueryConfig, QueryResult, QueryResultRow } from 'pg';

export interface QueryExecutor {
  query<T extends QueryResultRow = QueryResultRow>(
    queryTextOrConfig: string | QueryConfig,
    values?: readonly unknown[],
  ): Promise<QueryResult<T>>;
}

export type TransactionWork<T> = (database: QueryExecutor) => Promise<T>;
