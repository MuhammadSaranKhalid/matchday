import { Injectable, Logger } from '@nestjs/common';
import {
  createLocalJWKSet,
  decodeJwt,
  decodeProtectedHeader,
  jwtVerify,
  type JSONWebKeySet,
  type JWTPayload,
} from 'jose';

import type { AuthConfiguration } from '../config/configuration.js';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TokenVerificationError, type TokenVerifier } from './token-verifier.js';
type FetchImplementation = typeof fetch;

@Injectable()
export class SupabaseTokenVerifierService implements TokenVerifier {
  private readonly logger = new Logger(SupabaseTokenVerifierService.name);
  private jwks?: { readonly value: JSONWebKeySet; readonly expiresAt: number };

  constructor(
    private readonly configuration: Readonly<AuthConfiguration>,
    private readonly fetchImplementation: FetchImplementation = fetch,
  ) {}

  async verify(accessToken: string): Promise<AuthenticatedPrincipal> {
    try {
      if (this.configuration.mode === 'jwks') {
        const header = decodeProtectedHeader(accessToken);
        if (header.alg === 'HS256' && this.configuration.publishableKey !== undefined) {
          return await this.verifyRemotely(accessToken);
        }
        return await this.verifyWithJwks(accessToken);
      }
      return await this.verifyRemotely(accessToken);
    } catch (error) {
      try {
        const header = decodeProtectedHeader(accessToken);
        const payload = decodeJwt(accessToken);
        this.logger.warn(
          `Token verification failed [mode=${this.configuration.mode}]: ${error instanceof Error ? error.message : String(error)} | ` +
          `alg=${header.alg}, kid=${header.kid}, iss=${payload.iss} (expected ${this.configuration.issuer}), ` +
          `aud=${JSON.stringify(payload.aud)} (expected ${this.configuration.audience})`,
        );
      } catch (decodeError) {
        this.logger.warn(`Token verification failed: malformed token (${decodeError})`);
      }
      if (error instanceof TokenVerificationError) throw error;
      throw new TokenVerificationError('invalid_token');
    }
  }

  private async verifyWithJwks(accessToken: string): Promise<AuthenticatedPrincipal> {
    const header = decodeProtectedHeader(accessToken);
    if ((header.alg !== 'ES256' && header.alg !== 'RS256') || typeof header.kid !== 'string') {
      throw new TokenVerificationError('invalid_token');
    }

    let jwks = await this.getJwks(false);
    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(accessToken, createLocalJWKSet(jwks), {
        issuer: this.configuration.issuer,
        audience: this.configuration.audience,
        algorithms: ['ES256', 'RS256'],
      }));
    } catch (error) {
      if (!hasKid(jwks, header.kid)) {
        jwks = await this.getJwks(true);
        ({ payload } = await jwtVerify(accessToken, createLocalJWKSet(jwks), {
          issuer: this.configuration.issuer,
          audience: this.configuration.audience,
          algorithms: ['ES256', 'RS256'],
        }));
      } else {
        this.logger.error(`verifyWithJwks jwtVerify failed: ${error instanceof Error ? error.message : String(error)}`);
        throw error;
      }
    }
    return principalFromClaims(payload, this.logger);
  }

  private async verifyRemotely(accessToken: string): Promise<AuthenticatedPrincipal> {
    if (this.configuration.publishableKey === undefined) {
      throw new TokenVerificationError('verification_unavailable');
    }
    const response = await this.fetchWithTimeout(`${this.configuration.supabaseUrl}/auth/v1/user`, {
      headers: {
        authorization: `Bearer ${accessToken}`,
        apikey: this.configuration.publishableKey,
      },
    });
    if (!response.ok) {
      const body = await response.text().catch(() => '');
      this.logger.error(`verifyRemotely /auth/v1/user returned HTTP ${response.status}: ${body}`);
      throw new TokenVerificationError('invalid_token');
    }

    let user: unknown;
    try {
      user = await response.json();
    } catch {
      this.logger.error('verifyRemotely /auth/v1/user response was not valid JSON');
      throw new TokenVerificationError('invalid_token');
    }
    const payload = decodeJwt(accessToken);
    validateRegisteredClaims(payload, this.configuration, this.logger);
    if (!isRecord(user) || user.id !== payload.sub) {
      this.logger.error(`verifyRemotely user.id mismatch: user=${JSON.stringify(user)} vs sub=${payload.sub}`);
      throw new TokenVerificationError('invalid_token');
    }
    return principalFromClaims(payload, this.logger);
  }

  private async getJwks(forceRefresh: boolean): Promise<JSONWebKeySet> {
    if (!forceRefresh && this.jwks !== undefined && this.jwks.expiresAt > Date.now()) {
      return this.jwks.value;
    }
    const endpoint = `${this.configuration.issuer.replace(/\/$/, '')}/.well-known/jwks.json`;
    const response = await this.fetchWithTimeout(endpoint);
    if (!response.ok) throw new TokenVerificationError('verification_unavailable');
    let value: unknown;
    try {
      value = await response.json();
    } catch {
      throw new TokenVerificationError('verification_unavailable');
    }
    if (!isRecord(value) || !Array.isArray(value.keys) || !value.keys.every(isRecord)) {
      throw new TokenVerificationError('verification_unavailable');
    }
    const jwks: JSONWebKeySet = { keys: value.keys };
    this.jwks = { value: jwks, expiresAt: Date.now() + this.configuration.jwksCacheMaxAgeMs };
    return jwks;
  }

  private async fetchWithTimeout(input: string, init: RequestInit = {}): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.configuration.verificationTimeoutMs);
    try {
      return await this.fetchImplementation(input, { ...init, signal: controller.signal });
    } catch {
      throw new TokenVerificationError('verification_unavailable');
    } finally {
      clearTimeout(timeout);
    }
  }
}

function validateRegisteredClaims(payload: JWTPayload, configuration: AuthConfiguration, logger?: Logger): void {
  const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
  const normalize = (url?: string) => url?.replace(/\/+$/, '');
  const issuerMatches =
    payload.iss === configuration.issuer ||
    normalize(payload.iss) === normalize(configuration.issuer) ||
    payload.iss === 'supabase';
  if (!issuerMatches) {
    logger?.error(`validateRegisteredClaims: issuer mismatch! token.iss=${payload.iss} vs expected=${configuration.issuer}`);
    throw new TokenVerificationError('invalid_token');
  }
  if (!audiences.includes(configuration.audience)) {
    logger?.error(`validateRegisteredClaims: audience mismatch! token.aud=${JSON.stringify(payload.aud)} vs expected=${configuration.audience}`);
    throw new TokenVerificationError('invalid_token');
  }
  if (typeof payload.exp !== 'number' || payload.exp <= Math.floor(Date.now() / 1_000)) {
    logger?.error(`validateRegisteredClaims: token is EXPIRED! exp=${payload.exp}, now=${Math.floor(Date.now() / 1_000)} (expired ${Math.floor(Date.now() / 1_000) - (payload.exp ?? 0)}s ago)`);
    throw new TokenVerificationError('invalid_token');
  }
}

function principalFromClaims(payload: JWTPayload, logger?: Logger): AuthenticatedPrincipal {
  if (
    typeof payload.sub !== 'string' ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(payload.sub) ||
    payload.role !== 'authenticated'
  ) {
    logger?.error(`principalFromClaims: invalid claims! sub=${payload.sub}, role=${payload.role}`);
    throw new TokenVerificationError('invalid_token');
  }
  const appMetadata = isRecord(payload.app_metadata) ? Object.freeze({ ...payload.app_metadata }) : Object.freeze({});
  return Object.freeze({
    userId: payload.sub,
    role: 'authenticated' as const,
    ...(typeof payload.session_id === 'string' ? { sessionId: payload.session_id } : {}),
    appMetadata,
  });
}

function hasKid(jwks: JSONWebKeySet, kid: string): boolean {
  return jwks.keys.some((key) => key.kid === kid);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
