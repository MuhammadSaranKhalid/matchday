export interface ErrorResponse {
  readonly code: string;
  readonly message: string;
  readonly status: number;
  readonly correlationId: string;
  readonly details?: unknown;
}
