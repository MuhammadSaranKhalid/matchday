import { createParamDecorator, type ExecutionContext } from '@nestjs/common';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import type { AuthenticatedRequest } from './supabase-auth.guard.js';

export const CurrentPrincipal = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthenticatedPrincipal | undefined => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.user;
  },
);
