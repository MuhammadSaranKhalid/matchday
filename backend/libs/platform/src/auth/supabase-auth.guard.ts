import {
  type CanActivate,
  type ExecutionContext,
  Inject,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';

import type { AuthenticatedPrincipal } from './authenticated-principal.js';
import {
  TOKEN_VERIFIER,
  TokenVerificationError,
  type TokenVerifier,
} from './token-verifier.js';

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedPrincipal;
}

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(
    @Inject(TOKEN_VERIFIER) private readonly verifier: TokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers['authorization'];
    const match = /^Bearer ([^\s]+)$/i.exec(authorization ?? '');
    if (match?.[1] === undefined) {
      throw new UnauthorizedException('Authentication required');
    }

    try {
      const principal = await this.verifier.verify(match[1]);
      request.user = principal;
      return true;
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        if (error.code === 'verification_unavailable') {
          throw new ServiceUnavailableException('Authentication service unavailable');
        }
        throw new UnauthorizedException('Invalid access token');
      }
      throw error;
    }
  }
}
