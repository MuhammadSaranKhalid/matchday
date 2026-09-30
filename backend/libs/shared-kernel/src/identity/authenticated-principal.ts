export interface AuthenticatedPrincipal {
  readonly userId: string;
  readonly sessionId: string;
  readonly appMetadata: Readonly<Record<string, unknown>>;
}
