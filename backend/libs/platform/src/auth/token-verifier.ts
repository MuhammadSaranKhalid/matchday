import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';

export type VerificationFailureCode = 'invalid_token' | 'verification_unavailable';

export class TokenVerificationError extends Error {
  constructor(readonly code: VerificationFailureCode) {
    super(`Access token verification failed: ${code}`);
    this.name = 'TokenVerificationError';
  }
}

export abstract class TokenVerifier {
  abstract verify(accessToken: string): Promise<AuthenticatedPrincipal>;
}
