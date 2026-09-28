import { Injectable, type NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

import { normalizeCorrelationId } from '@shared-kernel/identifiers/correlation-id.js';
import { ExecutionContextService } from './execution-context.service.js';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor(private readonly context: ExecutionContextService) {}

  use(request: Request, response: Response, next: NextFunction): void {
    const requestId = normalizeCorrelationId(request.headers['x-request-id']);
    const correlationId = normalizeCorrelationId(request.headers['x-correlation-id']);

    response.setHeader('x-request-id', requestId);
    response.setHeader('x-correlation-id', correlationId);
    this.context.run({ requestId, correlationId }, next);
  }
}
