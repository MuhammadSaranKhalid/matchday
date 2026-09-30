import {
  BadRequestException,
  type ArgumentsHost,
  HttpStatus,
} from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import { describe, expect, it } from 'vitest';

import { ExecutionContextService } from '../../../libs/platform/src/context/execution-context.service.js';
import { ApplicationError } from '@shared-kernel/errors/application-error.js';
import { HttpExceptionFilter } from '../../../libs/platform/src/http/http-exception.filter.js';

interface CapturedResponse {
  status?: number;
  body?: Record<string, unknown>;
}

function argumentsHost(captured: CapturedResponse): ArgumentsHost {
  const response = {
    status(status: number) {
      captured.status = status;
      return this;
    },
    json(body: Record<string, unknown>) {
      captured.body = body;
      return this;
    },
  };

  return {
    switchToHttp: () => ({ getResponse: () => response, getRequest: () => ({}), getNext: () => undefined }),
  } as unknown as ArgumentsHost;
}

function capture(
  exception: unknown,
  production = true,
  logger?: { error: (...values: unknown[]) => void },
): CapturedResponse {
  const context = new ExecutionContextService();
  const config = {
    get: () => production,
  } as unknown as ConfigService<PlatformConfiguration, true>;
  const filter = new HttpExceptionFilter(context, config);
  if (logger) {
    (filter as unknown as { logger: Pick<Logger, 'error'> }).logger = logger;
  }
  const captured: CapturedResponse = {};
  context.run(
    { requestId: 'request-id', correlationId: 'correlation-id' },
    () => filter.catch(exception, argumentsHost(captured)),
  );
  return captured;
}

describe('HttpExceptionFilter', () => {
  it('maps an application error to its stable envelope', () => {
    expect(capture(new ApplicationError('CHAT_BLOCKED', 'Blocked', 'forbidden'))).toEqual({
      status: 403,
      body: {
        code: 'CHAT_BLOCKED',
        message: 'Blocked',
        status: 403,
        correlationId: 'correlation-id',
      },
    });
  });

  it('maps validation messages into validation details', () => {
    const captured = capture(
      new BadRequestException({ message: ['name must be a string'], error: 'Bad Request' }),
    );

    expect(captured).toEqual({
      status: HttpStatus.BAD_REQUEST,
      body: {
        code: 'VALIDATION_FAILED',
        message: 'Request validation failed',
        status: HttpStatus.BAD_REQUEST,
        correlationId: 'correlation-id',
        details: { validation: ['name must be a string'] },
      },
    });
  });

  it('maps throttling to RATE_LIMIT_EXCEEDED', () => {
    expect(capture(new ThrottlerException()).body).toMatchObject({
      code: 'RATE_LIMIT_EXCEEDED',
      status: HttpStatus.TOO_MANY_REQUESTS,
      correlationId: 'correlation-id',
    });
  });

  it('hides unexpected stack and database details in production', () => {
    const logs: unknown[][] = [];
    const error = Object.assign(new Error('database connection secret'), {
      database: { detail: 'private row data' },
    });
    const captured = capture(error, true, { error: (...values) => logs.push(values) });
    const serialized = JSON.stringify(captured.body);

    expect(captured).toEqual({
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      body: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
        status: HttpStatus.INTERNAL_SERVER_ERROR,
        correlationId: 'correlation-id',
      },
    });
    expect(serialized).not.toContain('database connection secret');
    expect(serialized).not.toContain('private row data');
    expect(serialized).not.toContain('stack');
    expect(logs).toHaveLength(1);
    expect(JSON.stringify(logs)).not.toContain('database connection secret');
    expect(JSON.stringify(logs)).not.toContain('private row data');
  });
});
