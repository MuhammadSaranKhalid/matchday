import {
  type CanActivate,
  type ExecutionContext,
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import {
  TokenVerificationError,
  TokenVerifier,
} from './token-verifier.js';

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedPrincipal;
}

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(SupabaseAuthGuard.name);

  constructor(
    private readonly verifier: TokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers['authorization'];
    const match = /^Bearer ([^\s]+)$/i.exec(authorization ?? '');
    if (match?.[1] === undefined) {
      this.logger.warn(`Authorization header missing or not Bearer: "${authorization}"`);
      throw new UnauthorizedException('Authentication required');
    }

    try {
      const principal = await this.verifier.verify(match[1]);
      request.user = principal;
      return true;
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        this.logger.warn(`Token verification rejected: code=${error.code}, message=${error.message}`);
        if (error.code === 'verification_unavailable') {
          throw new ServiceUnavailableException('Authentication service unavailable');
        }
        throw new UnauthorizedException('Invalid access token');
      }
      throw error;
    }
  }
}
