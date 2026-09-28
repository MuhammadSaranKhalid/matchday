import { Injectable } from '@nestjs/common';
import {
  createLocalJWKSet,
  decodeJwt,
  decodeProtectedHeader,
  jwtVerify,
  type JSONWebKeySet,
  type JWTPayload,
} from 'jose';

import type { AuthConfiguration } from '../config/configuration.js';
import type { AuthenticatedPrincipal } from './authenticated-principal.js';
import type { TokenVerifier } from './token-verifier.js';

type VerificationFailureCode = 'invalid_token' | 'verification_unavailable';
type FetchImplementation = typeof fetch;

export class TokenVerificationError extends Error {
  constructor(readonly code: VerificationFailureCode) {
    super(`Access token verification failed: ${code}`);
    this.name = 'TokenVerificationError';
  }
}

@Injectable()
export class SupabaseTokenVerifierService implements TokenVerifier {
  private jwks?: { readonly value: JSONWebKeySet; readonly expiresAt: number };

  constructor(
    private readonly configuration: Readonly<AuthConfiguration>,
    private readonly fetchImplementation: FetchImplementation = fetch,
  ) {}

  async verify(accessToken: string): Promise<AuthenticatedPrincipal> {
    try {
      return this.configuration.mode === 'jwks'
        ? await this.verifyWithJwks(accessToken)
        : await this.verifyRemotely(accessToken);
    } catch (error) {
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
        throw error;
      }
    }
    return principalFromClaims(payload);
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
    if (!response.ok) throw new TokenVerificationError('invalid_token');

    let user: unknown;
    try {
      user = await response.json();
    } catch {
      throw new TokenVerificationError('invalid_token');
    }
    const payload = decodeJwt(accessToken);
    validateRegisteredClaims(payload, this.configuration);
    if (!isRecord(user) || user.id !== payload.sub) {
      throw new TokenVerificationError('invalid_token');
    }
    return principalFromClaims(payload);
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

function validateRegisteredClaims(payload: JWTPayload, configuration: AuthConfiguration): void {
  const audiences = Array.isArray(payload.aud) ? payload.aud : [payload.aud];
  if (
    payload.iss !== configuration.issuer ||
    !audiences.includes(configuration.audience) ||
    typeof payload.exp !== 'number' ||
    payload.exp <= Math.floor(Date.now() / 1_000)
  ) {
    throw new TokenVerificationError('invalid_token');
  }
}

function principalFromClaims(payload: JWTPayload): AuthenticatedPrincipal {
  if (
    typeof payload.sub !== 'string' ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(payload.sub) ||
    payload.role !== 'authenticated'
  ) {
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
