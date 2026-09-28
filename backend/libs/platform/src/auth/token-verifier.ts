import type { AuthenticatedPrincipal } from './authenticated-principal.js';

export const TOKEN_VERIFIER = Symbol('TokenVerifier');

export interface TokenVerifier {
  verify(accessToken: string): Promise<AuthenticatedPrincipal>;
}
