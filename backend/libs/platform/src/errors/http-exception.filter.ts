import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  type ExceptionFilter,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ThrottlerException } from '@nestjs/throttler';
import type { Response } from 'express';

import type { PlatformConfiguration } from '../config/configuration.js';
import type { ErrorResponse } from '../../../shared-kernel/src/contracts/error-response.js';
import { ExecutionContextService } from '../context/execution-context.service.js';
import { ApplicationError } from './application-error.js';

@Injectable()
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly production: boolean;
  private readonly logger: Pick<Logger, 'error'>;

  constructor(
    private readonly context: ExecutionContextService,
    private readonly config: ConfigService<PlatformConfiguration, true>,
  ) {
    this.production = typeof config?.get === 'function' ? config.get('production', { infer: true }) ?? false : Boolean(config);
    this.logger = new Logger(HttpExceptionFilter.name);
  }

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const errorResponse = this.mapException(exception);

    if (!(exception instanceof HttpException) && !(exception instanceof ApplicationError)) {
      const error = exception instanceof Error ? exception : new Error('Non-error exception');
      const safeContext = { ...this.context.get() };
      if (this.production) {
        this.logger.error('Unhandled request exception', safeContext);
      } else {
        this.logger.error('Unhandled request exception', error.stack, safeContext);
      }
    }

    response.status(errorResponse.status).json(errorResponse);
  }

  private mapException(exception: unknown): ErrorResponse {
    const correlationId = this.context.get().correlationId ?? 'unavailable';

    if (exception instanceof ApplicationError) {
      return compact({
        code: exception.code,
        message: exception.message,
        status: exception.status,
        correlationId,
        details: exception.details,
      });
    }

    if (exception instanceof ThrottlerException) {
      return {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Rate limit exceeded',
        status: HttpStatus.TOO_MANY_REQUESTS,
        correlationId,
      };
    }

    if (exception instanceof BadRequestException) {
      const payload = exception.getResponse();
      const messages =
        typeof payload === 'object' && payload !== null && 'message' in payload
          ? (payload as { message?: unknown }).message
          : undefined;
      if (Array.isArray(messages)) {
        return {
          code: 'VALIDATION_FAILED',
          message: 'Request validation failed',
          status: HttpStatus.BAD_REQUEST,
          correlationId,
          details: { validation: messages.map(String) },
        };
      }
    }

    if (exception instanceof HttpException) {
      const healthDetails = sanitizedHealthDetails(exception);
      return {
        code: healthDetails === undefined
          ? httpCode(exception.getStatus())
          : 'DEPENDENCY_UNAVAILABLE',
        message: safeHttpMessage(exception),
        status: exception.getStatus(),
        correlationId,
        ...(healthDetails === undefined ? {} : { details: healthDetails }),
      };
    }

    if (isPayloadTooLarge(exception)) {
      return {
        code: 'PAYLOAD_TOO_LARGE',
        message: 'Request body is too large',
        status: HttpStatus.PAYLOAD_TOO_LARGE,
        correlationId,
      };
    }

    return {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      correlationId,
    };
  }
}

function sanitizedHealthDetails(exception: HttpException): Record<string, { status: 'up' | 'down' }> | undefined {
  if (exception.getStatus() !== HttpStatus.SERVICE_UNAVAILABLE) return undefined;
  const payload = exception.getResponse();
  if (typeof payload !== 'object' || payload === null || !('details' in payload)) return undefined;
  const details = (payload as { details?: unknown }).details;
  if (typeof details !== 'object' || details === null) return undefined;

  const sanitized: Record<string, { status: 'up' | 'down' }> = {};
  for (const label of ['foundation', 'postgres', 'redis', 'queues']) {
    const value = (details as Record<string, unknown>)[label];
    if (typeof value !== 'object' || value === null || !('status' in value)) continue;
    sanitized[label] = {
      status: (value as { status?: unknown }).status === 'up' ? 'up' : 'down',
    };
  }
  return Object.keys(sanitized).length === 0 ? undefined : sanitized;
}

function isPayloadTooLarge(exception: unknown): boolean {
  return (
    typeof exception === 'object' &&
    exception !== null &&
    'status' in exception &&
    (exception as { status?: unknown }).status === HttpStatus.PAYLOAD_TOO_LARGE
  );
}

function compact(response: ErrorResponse): ErrorResponse {
  if (response.details === undefined) {
    const { details: _details, ...withoutDetails } = response;
    return withoutDetails;
  }
  return response;
}

function httpCode(status: number): string {
  if (status === HttpStatus.NOT_FOUND) return 'NOT_FOUND';
  if (status === HttpStatus.PAYLOAD_TOO_LARGE) return 'PAYLOAD_TOO_LARGE';
  if (status === HttpStatus.UNAUTHORIZED) return 'AUTH_UNAUTHENTICATED';
  if (status === HttpStatus.FORBIDDEN) return 'PERMISSION_DENIED';
  return 'HTTP_ERROR';
}

function safeHttpMessage(exception: HttpException): string {
  const payload = exception.getResponse();
  if (typeof payload === 'string') return payload;
  if (typeof payload === 'object' && payload !== null && 'message' in payload) {
    const message = (payload as { message?: unknown }).message;
    if (typeof message === 'string') return message;
  }
  return exception.message;
}
