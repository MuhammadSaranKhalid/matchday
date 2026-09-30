import { Injectable } from '@nestjs/common';
import {
  isAuthError,
  isAuthRetryableFetchError,
  type JwtPayload,
  type SupabaseClient,
} from '@supabase/supabase-js';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import type { AuthConfiguration } from '../config/configuration.js';
import {
  TokenVerificationError,
  type TokenVerifier,
} from './token-verifier.js';

export interface SupabaseClaimsClient {
  readonly auth: Pick<SupabaseClient['auth'], 'getClaims'>;
}

@Injectable()
export class SupabaseTokenVerifierService implements TokenVerifier {
  constructor(
    private readonly client: SupabaseClaimsClient,
    private readonly configuration: Readonly<AuthConfiguration>,
  ) {}

  async verify(accessToken: string): Promise<AuthenticatedPrincipal> {
    try {
      const { data, error } = await this.client.auth.getClaims(accessToken);

      if (error !== null) {
        if (isAuthRetryableFetchError(error)) {
          throw new TokenVerificationError('verification_unavailable');
        }
        throw new TokenVerificationError('invalid_token');
      }

      if (data === null) {
        throw new TokenVerificationError('invalid_token');
      }

      validateClaims(data.claims, this.configuration);
      return principalFromClaims(data.claims);
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        throw error;
      }
      if (isAuthRetryableFetchError(error)) {
        throw new TokenVerificationError('verification_unavailable');
      }
      if (isAuthError(error)) {
        throw new TokenVerificationError('invalid_token');
      }
      throw error;
    }
  }
}

function validateClaims(
  claims: JwtPayload,
  configuration: AuthConfiguration,
): void {
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
  if (
    claims.iss !== configuration.issuer ||
    !audiences.includes(configuration.audience) ||
    typeof claims.exp !== 'number' ||
    claims.exp <= Math.floor(Date.now() / 1_000) ||
    typeof claims.sub !== 'string' ||
    !isUuid(claims.sub) ||
    claims.role !== 'authenticated'
  ) {
    throw new TokenVerificationError('invalid_token');
  }
}

function principalFromClaims(
  claims: JwtPayload,
): AuthenticatedPrincipal {
  const appMetadata = isRecord(claims.app_metadata)
    ? Object.freeze({ ...claims.app_metadata })
    : Object.freeze({});

  return Object.freeze({
    userId: claims.sub,
    role: 'authenticated' as const,
    sessionId: claims.session_id,
    appMetadata,
  });
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  );
}

function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return (
    typeof value === 'object' && value !== null && !Array.isArray(value)
  );
}
