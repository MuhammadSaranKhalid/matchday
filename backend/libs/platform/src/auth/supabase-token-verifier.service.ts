import { Injectable, Logger } from '@nestjs/common';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import type { AuthConfiguration } from '../config/configuration.js';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TokenVerificationError, type TokenVerifier } from './token-verifier.js';

type FetchImplementation = typeof fetch;

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isSupabaseClient(value: unknown): value is SupabaseClient {
  return (
    typeof value === 'object' &&
    value !== null &&
    'auth' in value &&
    typeof (value as { auth?: { getClaims?: unknown } }).auth?.getClaims === 'function'
  );
}

function fetchWithTimeout(
  input: string | URL | Request,
  init: RequestInit | undefined,
  timeoutMs: number,
  fetchImpl: FetchImplementation = fetch,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  return fetchImpl(input, { ...init, signal: controller.signal }).finally(() => clearTimeout(timer));
}

function isUnavailableError(error: unknown): boolean {
  if (error instanceof Error) {
    if (
      error.name === 'AbortError' ||
      error.name === 'TimeoutError' ||
      error.name === 'AuthRetryableFetchError'
    ) {
      return true;
    }
    const message = error.message.toLowerCase();
    if (
      message.includes('abort') ||
      message.includes('timeout') ||
      message.includes('econnrefused') ||
      message.includes('network')
    ) {
      return true;
    }
  }
  return false;
}

@Injectable()
export class SupabaseTokenVerifierService implements TokenVerifier {
  private readonly logger = new Logger(SupabaseTokenVerifierService.name);
  private readonly client: SupabaseClient;
  private readonly configuration?: Readonly<AuthConfiguration>;

  constructor(
    clientOrConfig: SupabaseClient | Readonly<AuthConfiguration>,
    configurationOrFetch?: Readonly<AuthConfiguration> | FetchImplementation,
    maybeFetch?: FetchImplementation,
  ) {
    if (isSupabaseClient(clientOrConfig)) {
      this.client = clientOrConfig;
      this.configuration = configurationOrFetch as Readonly<AuthConfiguration> | undefined;
    } else {
      const config = clientOrConfig;
      this.configuration = config;
      const fetchImpl =
        typeof configurationOrFetch === 'function'
          ? configurationOrFetch
          : (maybeFetch ?? fetch);
      const key = config.publishableKey && config.publishableKey.trim() !== ''
        ? config.publishableKey
        : 'sb_publishable_verification';
      this.client = createClient(config.supabaseUrl, key, {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
        global: {
          fetch: (input, init) =>
            fetchWithTimeout(input, init, config.verificationTimeoutMs, fetchImpl),
        },
      });
    }
  }

  async verify(accessToken: string): Promise<AuthenticatedPrincipal> {
    if (typeof accessToken !== 'string' || accessToken.trim() === '') {
      throw new TokenVerificationError('invalid_token');
    }

    this.rejectUnsignedOrInvalidHeader(accessToken);

    try {
      const { data, error } = await this.client.auth.getClaims(accessToken);
      if (error || !data?.claims) {
        const isJsonSyntaxError =
          error?.name === 'AuthRetryableFetchError' &&
          (error.message.includes('JSON') ||
            error.message.includes('Unexpected token') ||
            error.message.includes('Expected property'));

        if (
          !isJsonSyntaxError &&
          error &&
          (error.status === 503 ||
            error.status === 500 ||
            error.name === 'AuthRetryableFetchError' ||
            (error as unknown as { code?: string }).code === 'ECONNREFUSED' ||
            (error as unknown as { code?: string }).code === 'ETIMEDOUT')
        ) {
          this.logger.warn(`Token verification unavailable: ${error.message}`);
          throw new TokenVerificationError('verification_unavailable');
        }
        this.logger.warn(`Token verification failed: ${error?.message ?? 'missing claims'}`);
        throw new TokenVerificationError('invalid_token');
      }

      return this.principalFromClaims(data.claims as Record<string, unknown>);
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        throw error;
      }
      if (isUnavailableError(error)) {
        this.logger.warn(
          `Token verification unavailable: ${error instanceof Error ? error.message : String(error)}`,
        );
        throw new TokenVerificationError('verification_unavailable');
      }
      this.logger.warn(
        `Token verification failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      throw new TokenVerificationError('invalid_token');
    }
  }

  private rejectUnsignedOrInvalidHeader(accessToken: string): void {
    const [headerB64] = accessToken.split('.');
    if (!headerB64) {
      throw new TokenVerificationError('invalid_token');
    }
    try {
      const header = JSON.parse(Buffer.from(headerB64, 'base64url').toString('utf8'));
      if (
        !header ||
        typeof header !== 'object' ||
        !header.alg ||
        header.alg === 'none'
      ) {
        throw new TokenVerificationError('invalid_token');
      }
      if (
        this.configuration?.mode === 'jwks' &&
        header.alg !== 'ES256' &&
        header.alg !== 'RS256'
      ) {
        throw new TokenVerificationError('invalid_token');
      }
    } catch {
      throw new TokenVerificationError('invalid_token');
    }
  }

  private principalFromClaims(claims: Record<string, unknown>): AuthenticatedPrincipal {
    if (this.configuration) {
      if (this.configuration.audience && claims['aud']) {
        const audiences = Array.isArray(claims['aud']) ? claims['aud'] : [claims['aud']];
        if (!audiences.includes(this.configuration.audience)) {
          this.logger.warn(
            `principalFromClaims: audience mismatch: ${JSON.stringify(claims['aud'])} vs ${this.configuration.audience}`,
          );
          throw new TokenVerificationError('invalid_token');
        }
      }
      if (this.configuration.issuer && claims['iss']) {
        const normalize = (url?: string) => url?.replace(/\/+$/, '');
        const issuerMatches =
          claims['iss'] === this.configuration.issuer ||
          normalize(String(claims['iss'])) === normalize(this.configuration.issuer) ||
          claims['iss'] === 'supabase';
        if (!issuerMatches) {
          this.logger.warn(
            `principalFromClaims: issuer mismatch: ${claims['iss']} vs ${this.configuration.issuer}`,
          );
          throw new TokenVerificationError('invalid_token');
        }
      }
    }

    if (
      typeof claims['sub'] !== 'string' ||
      !UUID_REGEX.test(claims['sub']) ||
      claims['role'] !== 'authenticated'
    ) {
      this.logger.warn(
        `principalFromClaims: invalid claims: sub=${claims['sub']}, role=${claims['role']}`,
      );
      throw new TokenVerificationError('invalid_token');
    }

    const appMetadata = isRecord(claims['app_metadata'])
      ? Object.freeze({ ...claims['app_metadata'] })
      : Object.freeze({});

    return Object.freeze({
      userId: claims['sub'],
      role: 'authenticated' as const,
      ...(typeof claims['session_id'] === 'string' ? { sessionId: claims['session_id'] } : {}),
      appMetadata,
    });
  }
}
