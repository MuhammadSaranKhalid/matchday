import {
  AuthInvalidJwtError,
  AuthRetryableFetchError,
  type JwtPayload,
} from '@supabase/supabase-js';
import {
  describe,
  expect,
  it,
  vi,
} from 'vitest';

import type { AuthConfiguration } from '../../../../libs/platform/src/config/configuration.js';
import {
  type SupabaseClaimsClient,
  SupabaseTokenVerifierService,
} from '../../../../libs/platform/src/auth/supabase-token-verifier.service.js';

const issuer = 'https://project.supabase.co/auth/v1';
const userId = '7c50bd47-dfaf-4ad0-97d8-10b9b908f7ac';
const sessionId = '51c521bb-a829-4d6d-a6b7-5aa57e6092c4';

const configuration: AuthConfiguration = {
  supabaseUrl: 'https://project.supabase.co',
  publishableKey: 'sb_publishable_test',
  issuer,
  audience: 'authenticated',
};

function claims(
  overrides: Partial<JwtPayload> = {},
): JwtPayload {
  const now = Math.floor(Date.now() / 1_000);
  return {
    iss: issuer,
    sub: userId,
    aud: 'authenticated',
    exp: now + 300,
    iat: now,
    role: 'authenticated',
    aal: 'aal1',
    session_id: sessionId,
    app_metadata: {
      tier: 'pro',
    },
    ...overrides,
  };
}

function verifiedResult(
  payload: JwtPayload = claims(),
) {
  return {
    data: {
      claims: payload,
      header: {
        alg: 'ES256' as const,
        kid: 'test-key',
        typ: 'JWT',
      },
      signature: new Uint8Array([1, 2, 3]),
    },
    error: null,
  };
}

function verifierWith(
  result: unknown,
) {
  const getClaims = vi.fn().mockResolvedValue(result);
  const client = {
    auth: {
      getClaims,
    },
  } as unknown as SupabaseClaimsClient;

  return {
    service: new SupabaseTokenVerifierService(
      client,
      configuration,
    ),
    getClaims,
  };
}

describe(
  'SupabaseTokenVerifierService',
  () => {
    it(
      'verifies through Supabase getClaims and maps an immutable principal',
      async () => {
        const {
          service,
          getClaims,
        } = verifierWith(
          verifiedResult(),
        );

        const principal = await service.verify(
          'valid-access-token',
        );

        expect(getClaims)
          .toHaveBeenCalledOnce();
        expect(getClaims)
          .toHaveBeenCalledWith(
            'valid-access-token',
          );
        expect(principal).toEqual({
          userId,
          role: 'authenticated',
          sessionId,
          appMetadata: {
            tier: 'pro',
          },
        });
        expect(
          Object.isFrozen(principal),
        ).toBe(true);
        expect(
          Object.isFrozen(
            principal.appMetadata,
          ),
        ).toBe(true);
      },
    );

    it(
      'maps rejected Supabase JWTs to invalid_token',
      async () => {
        const { service } = verifierWith({
          data: null,
          error: new AuthInvalidJwtError(
            'Invalid JWT',
          ),
        });

        await expect(
          service.verify('bad-token'),
        ).rejects.toMatchObject({
          code: 'invalid_token',
        });
      },
    );

    it(
      'maps retryable Supabase failures to verification_unavailable',
      async () => {
        const { service } = verifierWith({
          data: null,
          error: new AuthRetryableFetchError(
            'network unavailable',
            0,
          ),
        });

        await expect(
          service.verify('token'),
        ).rejects.toMatchObject({
          code: 'verification_unavailable',
        });
      },
    );

    it.each([
      [
        'wrong issuer',
        {
          iss: 'https://attacker.invalid/auth/v1',
        },
      ],
      [
        'wrong audience',
        {
          aud: 'other',
        },
      ],
      [
        'expired token',
        {
          exp: 1,
        },
      ],
      [
        'invalid subject',
        {
          sub: 'not-a-uuid',
        },
      ],
      [
        'non-authenticated role',
        {
          role: 'anon',
        },
      ],
    ])(
      'fails closed for %s',
      async (
        _case,
        overrides,
      ) => {
        const { service } = verifierWith(
          verifiedResult(
            claims(overrides),
          ),
        );

        await expect(
          service.verify('token'),
        ).rejects.toMatchObject({
          code: 'invalid_token',
        });
      },
    );

    it(
      'does not convert unexpected programming failures into authentication failures',
      async () => {
        const failure = new Error(
          'unexpected failure',
        );
        const getClaims = vi.fn().mockRejectedValue(
          failure,
        );
        const client = {
          auth: {
            getClaims,
          },
        } as unknown as SupabaseClaimsClient;

        const service = new SupabaseTokenVerifierService(
          client,
          configuration,
        );

        await expect(
          service.verify('token'),
        ).rejects.toThrow(
          failure,
        );
      },
    );
  },
);
