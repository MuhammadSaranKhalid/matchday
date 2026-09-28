import { createServer, type Server } from 'node:http';
import { SignJWT } from 'jose';
import { afterEach, describe, expect, it } from 'vitest';

import type { AuthConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { SupabaseTokenVerifierService } from '../../../libs/platform/src/auth/supabase-token-verifier.service.js';

const publishableKey = 'synthetic-publishable-key';
const jwtSecret = new TextEncoder().encode('synthetic-legacy-jwt-secret-with-32-bytes');
const userId = '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac';
const servers: Server[] = [];

async function accessToken(issuer: string) {
  return new SignJWT({ role: 'authenticated', app_metadata: { tier: 'test' }, session_id: 'remote-session' })
    .setProtectedHeader({ alg: 'HS256' }).setIssuer(issuer).setAudience('authenticated')
    .setSubject(userId).setIssuedAt().setExpirationTime('5m').sign(jwtSecret);
}

async function fixture(handler: Parameters<typeof createServer>[0]) {
  const server = createServer(handler);
  servers.push(server);
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  if (address === null || typeof address === 'string') throw new Error('server did not bind');
  return `http://127.0.0.1:${address.port}`;
}

function configuration(url: string): AuthConfiguration {
  return {
    supabaseUrl: url, issuer: `${url}/auth/v1`, audience: 'authenticated', mode: 'remote',
    publishableKey, verificationTimeoutMs: 50, jwksCacheMaxAgeMs: 60_000, jwksCooldownMs: 10,
  };
}

afterEach(async () => Promise.all(servers.splice(0).map((server) => new Promise<void>((resolve) => server.close(() => resolve())))));

describe('Supabase remote token verification', () => {
  it('sends required credentials and returns the verified principal', async () => {
    let capturedHeaders: typeof import('node:http').IncomingHttpHeaders = {};
    const url = await fixture((request, response) => {
      capturedHeaders = request.headers;
      response.setHeader('content-type', 'application/json');
      response.end(JSON.stringify({ id: userId }));
    });
    const token = await accessToken(`${url}/auth/v1`);
    const principal = await new SupabaseTokenVerifierService(configuration(url)).verify(token);
    expect(capturedHeaders.authorization).toBe(`Bearer ${token}`);
    expect(capturedHeaders.apikey).toBe(publishableKey);
    expect(principal).toMatchObject({ userId, role: 'authenticated', sessionId: 'remote-session' });
  });

  it.each(['unauthorized', 'malformed', 'timeout'] as const)('fails closed for %s responses without leaking credentials', async (scenario) => {
    const url = await fixture((_request, response) => {
      if (scenario === 'timeout') return;
      response.statusCode = scenario === 'unauthorized' ? 401 : 200;
      response.end(scenario === 'malformed' ? '{' : 'denied');
    });
    const token = await accessToken(`${url}/auth/v1`);
    const error = await new SupabaseTokenVerifierService(configuration(url)).verify(token).catch((caught: unknown) => caught);
    expect(String(error)).not.toContain(token);
    expect(String(error)).not.toContain(publishableKey);
    expect(error).toMatchObject({ code: scenario === 'timeout' ? 'verification_unavailable' : 'invalid_token' });
  });
});
