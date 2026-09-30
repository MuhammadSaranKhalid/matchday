import { Injectable, Logger } from '@nestjs/common';
import {
  isAuthError,
  isAuthRetryableFetchError,
  type JwtPayload,
  type SupabaseClient,
} from '@supabase/supabase-js';
import { z } from 'zod';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import type { AuthConfiguration } from '../config/configuration.js';
import {
  TokenVerificationError,
  TokenVerifier,
} from './token-verifier.js';

export type ClaimsVerifier = Pick<SupabaseClient['auth'], 'getClaims'>;

const uuidPattern =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const uuidSchema = z.string().regex(uuidPattern, 'Invalid UUID');

@Injectable()
export class SupabaseTokenVerifierService extends TokenVerifier {
  private readonly logger = new Logger(SupabaseTokenVerifierService.name);

  constructor(
    private readonly auth: ClaimsVerifier,
    private readonly configuration: Readonly<AuthConfiguration>,
  ) {
    super();
  }

  async verify(accessToken: string): Promise<AuthenticatedPrincipal> {
    try {
      const { data, error } = await this.auth.getClaims(accessToken);

      if (error !== null) {
        this.logger.warn(`Supabase getClaims error: ${error.message} (${error.name})`);
        if (isAuthRetryableFetchError(error)) {
          throw new TokenVerificationError('verification_unavailable');
        }
        throw new TokenVerificationError('invalid_token');
      }

      if (data === null) {
        this.logger.warn('Supabase getClaims returned null data');
        throw new TokenVerificationError('invalid_token');
      }

      validateClaims(data.claims, this.configuration, this.logger);
      return principalFromClaims(data.claims);
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        throw error;
      }
      if (isAuthRetryableFetchError(error)) {
        this.logger.warn(`Supabase verification retryable failure: ${error.message}`);
        throw new TokenVerificationError('verification_unavailable');
      }
      if (isAuthError(error)) {
        this.logger.warn(`Supabase verification auth error: ${error.message} (${error.name})`);
        throw new TokenVerificationError('invalid_token');
      }
      this.logger.error(
        `Unexpected token verification error: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw error;
    }
  }
}

function validateClaims(
  claims: JwtPayload,
  configuration: AuthConfiguration,
  logger: Logger,
): void {
  const expectedIssuer = `${configuration.supabaseUrl.replace(/\/+$/, '')}/auth/v1`;
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];

  if (claims.iss !== expectedIssuer && claims.iss !== 'supabase') {
    logger.warn(`Token validation failed: issuer mismatch (received "${claims.iss}", expected "${expectedIssuer}")`);
    throw new TokenVerificationError('invalid_token');
  }
  if (!audiences.includes('authenticated')) {
    logger.warn(`Token validation failed: audience mismatch (received ${JSON.stringify(claims.aud)}, expected to include "authenticated")`);
    throw new TokenVerificationError('invalid_token');
  }
  if (claims.role !== 'authenticated') {
    logger.warn(`Token validation failed: role mismatch (received "${claims.role}", expected "authenticated")`);
    throw new TokenVerificationError('invalid_token');
  }
  if (claims.is_anonymous === true) {
    logger.warn('Token validation failed: anonymous Supabase user rejected');
    throw new TokenVerificationError('invalid_token');
  }
  if (typeof claims.sub !== 'string' || !uuidSchema.safeParse(claims.sub).success) {
    logger.warn(`Token validation failed: subject is not a valid UUID (received "${claims.sub}")`);
    throw new TokenVerificationError('invalid_token');
  }
  if (typeof claims.session_id !== 'string' || !uuidSchema.safeParse(claims.session_id).success) {
    logger.warn(`Token validation failed: session_id is not a valid UUID (received "${claims.session_id}")`);
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
    sessionId: claims.session_id as string,
    appMetadata,
  });
}

function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return (
    typeof value === 'object' && value !== null && !Array.isArray(value)
  );
}
