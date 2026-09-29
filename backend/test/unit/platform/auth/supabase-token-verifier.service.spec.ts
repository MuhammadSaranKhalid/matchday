import { exportJWK, generateKeyPair, SignJWT, type KeyLike } from 'jose';
import { beforeAll, describe, expect, it, vi } from 'vitest';

import type { AuthConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import {
  SupabaseTokenVerifierService,
} from '../../../../libs/platform/src/auth/supabase-token-verifier.service.js';
import { TokenVerificationError } from '../../../../libs/platform/src/auth/token-verifier.js';

const issuer = 'https://project.supabase.co/auth/v1';
const userId = '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac';
let esPrivateKey: KeyLike;
let esPublicJwk: Record<string, unknown>;
let rsPrivateKey: KeyLike;
let rsPublicJwk: Record<string, unknown>;

beforeAll(async () => {
  const es = await generateKeyPair('ES256');
  esPrivateKey = es.privateKey;
  esPublicJwk = { ...(await exportJWK(es.publicKey)), kid: 'es-key', alg: 'ES256' };
  const rs = await generateKeyPair('RS256');
  rsPrivateKey = rs.privateKey;
  rsPublicJwk = { ...(await exportJWK(rs.publicKey)), kid: 'rs-key', alg: 'RS256' };
});

const configuration: AuthConfiguration = {
  supabaseUrl: 'https://project.supabase.co', issuer, audience: 'authenticated', mode: 'jwks',
  verificationTimeoutMs: 200, jwksCacheMaxAgeMs: 60_000, jwksCooldownMs: 10,
};

async function token(
  key: KeyLike,
  kid: string,
  algorithm: 'ES256' | 'RS256',
  claims: Record<string, unknown> = {},
) {
  const { iss = issuer, aud = 'authenticated', sub = userId, ...payload } = claims;
  return new SignJWT({ role: 'authenticated', app_metadata: { tier: 'pro' }, session_id: 'session-1', ...payload })
    .setProtectedHeader({ alg: algorithm, kid })
    .setIssuer(String(iss)).setAudience(aud as string | string[]).setSubject(String(sub))
    .setIssuedAt().setExpirationTime('5m').sign(key);
}

function verifier(keys: Record<string, unknown>[]) {
  const fetchImplementation = vi.fn(async () => new Response(JSON.stringify({ keys }), {
    status: 200, headers: { 'content-type': 'application/json' },
  }));
  return { service: new SupabaseTokenVerifierService(configuration, fetchImplementation), fetchImplementation };
}

describe('SupabaseTokenVerifierService JWKS mode', () => {
  it.each([
    ['ES256', () => esPrivateKey, 'es-key', () => esPublicJwk],
    ['RS256', () => rsPrivateKey, 'rs-key', () => rsPublicJwk],
  ] as const)('verifies %s and maps an immutable principal', async (algorithm, privateKey, kid, publicJwk) => {
    const { service } = verifier([publicJwk()]);
    const principal = await service.verify(await token(privateKey(), kid, algorithm));
    expect(principal).toEqual({ userId, role: 'authenticated', sessionId: 'session-1', appMetadata: { tier: 'pro' } });
    expect(Object.isFrozen(principal)).toBe(true);
    expect(Object.isFrozen(principal.appMetadata)).toBe(true);
  });

  it('caches known keys and refreshes when a new kid appears', async () => {
    let keys = [esPublicJwk];
    const fetchImplementation = vi.fn(async () => new Response(JSON.stringify({ keys }), { status: 200 }));
    const service = new SupabaseTokenVerifierService(configuration, fetchImplementation);
    await service.verify(await token(esPrivateKey, 'es-key', 'ES256'));
    await service.verify(await token(esPrivateKey, 'es-key', 'ES256'));
    expect(fetchImplementation).toHaveBeenCalledTimes(1);
    keys = [esPublicJwk, rsPublicJwk];
    await service.verify(await token(rsPrivateKey, 'rs-key', 'RS256'));
    expect(fetchImplementation).toHaveBeenCalledTimes(2);
  });

  it.each([
    ['wrong issuer', () => token(esPrivateKey, 'es-key', 'ES256', { iss: 'https://attacker.invalid' })],
    ['wrong audience', () => token(esPrivateKey, 'es-key', 'ES256', { aud: 'other' })],
    ['expired token', async () => new SignJWT({ role: 'authenticated' }).setProtectedHeader({ alg: 'ES256', kid: 'es-key' }).setIssuer(issuer).setAudience('authenticated').setSubject(userId).setExpirationTime(1).sign(esPrivateKey)],
    ['missing subject', async () => new SignJWT({ role: 'authenticated' }).setProtectedHeader({ alg: 'ES256', kid: 'es-key' }).setIssuer(issuer).setAudience('authenticated').setExpirationTime('5m').sign(esPrivateKey)],
    ['non-UUID subject', () => token(esPrivateKey, 'es-key', 'ES256', { sub: 'not-a-uuid' })],
    ['non-authenticated role', () => token(esPrivateKey, 'es-key', 'ES256', { role: 'anon' })],
  ])('fails closed for %s', async (_case, buildToken) => {
    const { service } = verifier([esPublicJwk]);
    await expect(service.verify(await buildToken())).rejects.toMatchObject({ code: 'invalid_token' });
  });

  it('rejects a bad signature and never exposes token or claims', async () => {
    const accessToken = await token(esPrivateKey, 'es-key', 'ES256', { email: 'private@example.com' });
    const { service } = verifier([rsPublicJwk]);
    const error = await service.verify(accessToken).catch((caught: unknown) => caught) as TokenVerificationError;
    expect(error.code).toBe('invalid_token');
    expect(String(error)).not.toContain(accessToken);
    expect(String(error)).not.toContain('private@example.com');
  });

  it('rejects unsupported algorithms before requesting keys', async () => {
    const unsupported = await new SignJWT({ role: 'authenticated' })
      .setProtectedHeader({ alg: 'HS256', kid: 'legacy' }).setSubject(userId)
      .setIssuer(issuer).setAudience('authenticated').setExpirationTime('5m')
      .sign(new TextEncoder().encode('a-synthetic-secret-that-is-long-enough'));
    const { service, fetchImplementation } = verifier([esPublicJwk]);
    await expect(service.verify(unsupported)).rejects.toMatchObject({ code: 'invalid_token' });
    expect(fetchImplementation).not.toHaveBeenCalled();
  });

  it('rejects unsigned tokens before requesting keys', async () => {
    const unsigned = 'eyJhbGciOiJub25lIiwia2lkIjoibm9uZSJ9.e30.';
    const { service, fetchImplementation } = verifier([esPublicJwk]);
    await expect(service.verify(unsigned)).rejects.toMatchObject({ code: 'invalid_token' });
    expect(fetchImplementation).not.toHaveBeenCalled();
  });

  it('fails with an unavailable category when JWKS fetch times out', async () => {
    const stalledFetch = vi.fn((_url: string | URL | Request, init?: RequestInit) => new Promise<Response>((_resolve, reject) => {
      init?.signal?.addEventListener('abort', () => reject(new DOMException('aborted', 'AbortError')));
    }));
    const service = new SupabaseTokenVerifierService({ ...configuration, verificationTimeoutMs: 10 }, stalledFetch);
    await expect(service.verify(await token(esPrivateKey, 'es-key', 'ES256'))).rejects.toMatchObject({ code: 'verification_unavailable' });
  });
});
