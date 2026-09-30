export interface AuthenticatedPrincipal {
  readonly userId: string;
  readonly role: 'authenticated';
  readonly sessionId?: string;
  readonly appMetadata: Readonly<Record<string, unknown>>;
}
