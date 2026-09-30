import {
  createServer,
  type Server,
} from 'node:http';
import {
  createClient,
} from '@supabase/supabase-js';
import {
  afterEach,
  describe,
  expect,
  it,
} from 'vitest';

import type { AuthConfiguration } from '../../../libs/platform/src/config/configuration.js';
import {
  SupabaseTokenVerifierService,
} from '../../../libs/platform/src/auth/supabase-token-verifier.service.js';

const publishableKey = 'synthetic-publishable-key';
const userId = '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac';
const sessionId = '51c521bb-a829-4d6d-a6b7-5aa57e6092c4';
const servers: Server[] = [];

function encode(
  value: object,
): string {
  return Buffer
    .from(JSON.stringify(value))
    .toString('base64url');
}

function accessToken(
  issuer: string,
): string {
  const now = Math.floor(
    Date.now() / 1_000,
  );
  const header = encode({
    alg: 'HS256',
    typ: 'JWT',
  });
  const payload = encode({
    iss: issuer,
    aud: 'authenticated',
    sub: userId,
    role: 'authenticated',
    aal: 'aal1',
    session_id: sessionId,
    iat: now,
    exp: now + 300,
    app_metadata: {
      tier: 'test',
    },
  });
  const signature = Buffer.from(
    'synthetic-signature',
  ).toString('base64url');

  return [
    header,
    payload,
    signature,
  ].join('.');
}

async function fixture(
  handler: Parameters<
    typeof createServer
  >[0],
): Promise<string> {
  const server = createServer(handler);
  servers.push(server);
  await new Promise<void>(
    (resolve) => server.listen(
      0,
      '127.0.0.1',
      resolve,
    ),
  );
  const address = server.address();
  if (
    address === null ||
    typeof address === 'string'
  ) {
    throw new Error(
      'server did not bind',
    );
  }
  return (
    `http://127.0.0.1:` +
    address.port
  );
}

function configuration(
  url: string,
): AuthConfiguration {
  return {
    supabaseUrl: url,
    publishableKey,
    issuer: `${url}/auth/v1`,
    audience: 'authenticated',
  };
}

afterEach(
  async () =>
    Promise.all(
      servers
        .splice(0)
        .map(
          (server) =>
            new Promise<void>(
              (resolve) =>
                server.close(
                  () => resolve(),
                ),
            ),
        ),
    ),
);

describe(
  'Supabase token verification integration',
  () => {
    it(
      'delegates symmetric JWT verification to Supabase Auth',
      async () => {
        let capturedHeaders:
          typeof import(
            'node:http'
          ).IncomingHttpHeaders = {};
        const url = await fixture(
          (
            request,
            response,
          ) => {
            capturedHeaders =
              request.headers;
            response.setHeader(
              'content-type',
              'application/json',
            );
            response.end(
              JSON.stringify({
                id: userId,
                aud: 'authenticated',
                role: 'authenticated',
                email:
                  'test@example.com',
                app_metadata: {},
                user_metadata: {},
                created_at:
                  new Date()
                    .toISOString(),
              }),
            );
          },
        );

        const token = accessToken(
          `${url}/auth/v1`,
        );
        const client = createClient(
          url,
          publishableKey,
          {
            auth: {
              autoRefreshToken: false,
              detectSessionInUrl: false,
              persistSession: false,
            },
          },
        );
        const service =
          new SupabaseTokenVerifierService(
            client,
            configuration(url),
          );

        const principal =
          await service.verify(
            token,
          );

        expect(
          capturedHeaders.authorization,
        ).toBe(
          `Bearer ${token}`,
        );
        expect(
          capturedHeaders.apikey,
        ).toBe(
          publishableKey,
        );
        expect(
          principal,
        ).toMatchObject({
          userId,
          role: 'authenticated',
          sessionId,
        });
      },
    );

    it(
      'fails closed when Supabase Auth rejects the token',
      async () => {
        const url = await fixture(
          (
            _request,
            response,
          ) => {
            response.statusCode = 401;
            response.setHeader(
              'content-type',
              'application/json',
            );
            response.end(
              JSON.stringify({
                message:
                  'invalid token',
              }),
            );
          },
        );

        const token = accessToken(
          `${url}/auth/v1`,
        );
        const client = createClient(
          url,
          publishableKey,
          {
            auth: {
              autoRefreshToken: false,
              detectSessionInUrl: false,
              persistSession: false,
            },
          },
        );
        const service =
          new SupabaseTokenVerifierService(
            client,
            configuration(url),
          );

        await expect(
          service.verify(token),
        ).rejects.toMatchObject({
          code: 'invalid_token',
        });
      },
    );
  },
);
