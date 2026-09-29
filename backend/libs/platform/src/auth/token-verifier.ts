import type { AuthenticatedPrincipal } from './authenticated-principal.js';

export const TOKEN_VERIFIER = Symbol('TokenVerifier');

export type VerificationFailureCode = 'invalid_token' | 'verification_unavailable';

export class TokenVerificationError extends Error {
  constructor(readonly code: VerificationFailureCode) {
    super(`Access token verification failed: ${code}`);
    this.name = 'TokenVerificationError';
  }
}

export interface TokenVerifier {
  verify(accessToken: string): Promise<AuthenticatedPrincipal>;
}
