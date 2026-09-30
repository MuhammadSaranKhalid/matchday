export type ApplicationErrorKind =
  | 'validation'
  | 'not_found'
  | 'forbidden'
  | 'conflict'
  | 'unavailable';

export class ApplicationError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly kind: ApplicationErrorKind,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = 'ApplicationError';
  }
}
