import {
  type ExecutionContext,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { describe, expect, it, vi } from 'vitest';

import {
  TokenVerificationError,
  type TokenVerifier,
} from '../../../../libs/platform/src/auth/token-verifier.js';
import {
  type AuthenticatedRequest,
  SupabaseAuthGuard,
} from '../../../../libs/platform/src/auth/supabase-auth.guard.js';

function mockContext(headers: Record<string, string | undefined>): {
  context: ExecutionContext;
  request: AuthenticatedRequest;
} {
  const request = { headers } as AuthenticatedRequest;
  const context = {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
  } as unknown as ExecutionContext;
  return { context, request };
}

describe('SupabaseAuthGuard', () => {
  it('throws 401 when authorization header is missing', async () => {
    const verifier: TokenVerifier = { verify: vi.fn() };
    const guard = new SupabaseAuthGuard(verifier);
    const { context } = mockContext({});

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(verifier.verify).not.toHaveBeenCalled();
  });

  it('throws 401 when authorization format is not Bearer', async () => {
    const verifier: TokenVerifier = { verify: vi.fn() };
    const guard = new SupabaseAuthGuard(verifier);
    const { context } = mockContext({ authorization: 'Basic dXNlcjpwYXNz' });

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(verifier.verify).not.toHaveBeenCalled();
  });

  it('attaches verified principal and returns true on valid Bearer token', async () => {
    const principal = {
      userId: '10000000-0000-4000-8000-000000000001',
      role: 'authenticated',
      appMetadata: {},
    };
    const verifier: TokenVerifier = {
      verify: vi.fn().mockResolvedValue(principal),
    };
    const guard = new SupabaseAuthGuard(verifier);
    const { context, request } = mockContext({ authorization: 'Bearer valid.jwt.token' });

    const result = await guard.canActivate(context);

    expect(result).toBe(true);
    expect(request.user).toEqual(principal);
    expect(verifier.verify).toHaveBeenCalledWith('valid.jwt.token');
  });

  it('translates invalid_token to 401 UnauthorizedException', async () => {
    const verifier: TokenVerifier = {
      verify: vi.fn().mockRejectedValue(new TokenVerificationError('invalid_token')),
    };
    const guard = new SupabaseAuthGuard(verifier);
    const { context } = mockContext({ authorization: 'Bearer expired.jwt.token' });

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('translates verification_unavailable to 503 ServiceUnavailableException', async () => {
    const verifier: TokenVerifier = {
      verify: vi.fn().mockRejectedValue(new TokenVerificationError('verification_unavailable')),
    };
    const guard = new SupabaseAuthGuard(verifier);
    const { context } = mockContext({ authorization: 'Bearer remote.jwt.token' });

    await expect(guard.canActivate(context)).rejects.toThrow(ServiceUnavailableException);
  });

  it('propagates unexpected errors', async () => {
    const failure = new Error('unexpected runtime crash');
    const verifier: TokenVerifier = {
      verify: vi.fn().mockRejectedValue(failure),
    };
    const guard = new SupabaseAuthGuard(verifier);
    const { context } = mockContext({ authorization: 'Bearer token' });

    await expect(guard.canActivate(context)).rejects.toThrow(failure);
  });
});
