import pino from 'pino';
import { describe, expect, it } from 'vitest';

import type { PlatformConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { ExecutionContextService } from '../../../libs/platform/src/context/execution-context.service.js';
import { buildPinoOptions } from '../../../libs/platform/src/logging/logging.config.js';

const configuration: PlatformConfiguration = {
  nodeEnvironment: 'test',
  appName: 'matchday-test',
  port: 3000,
  logLevel: 'info',
  corsOrigins: ['http://localhost:3000'],
  bodyLimit: '1mb',
  throttle: { ttlMs: 60_000, limit: 100 },
  swaggerEnabled: false,
  production: false,
};

describe('buildPinoOptions', () => {
  it('emits JSON with execution context identifiers', () => {
    const context = new ExecutionContextService();
    const lines: string[] = [];
    const logger = pino(buildPinoOptions(configuration, context), {
      write: (line) => lines.push(line),
    });

    context.run(
      {
        requestId: 'request-1',
        correlationId: 'correlation-1',
        userId: 'user-1',
        jobId: 'job-1',
      },
      () => logger.info('handled'),
    );

    const record = JSON.parse(lines[0] ?? '{}') as Record<string, unknown>;
    expect(record).toMatchObject({
      level: 30,
      name: 'matchday-test',
      msg: 'handled',
      requestId: 'request-1',
      correlationId: 'correlation-1',
      userId: 'user-1',
      jobId: 'job-1',
    });
  });

  it('redacts credentials, tokens, cookies, and request bodies', () => {
    const context = new ExecutionContextService();
    const lines: string[] = [];
    const logger = pino(buildPinoOptions(configuration, context), {
      write: (line) => lines.push(line),
    });

    logger.info({
      req: {
        headers: { authorization: 'Bearer jwt', cookie: 'session=secret' },
        body: { message: 'private chat body' },
      },
      password: 'password-secret',
      supabaseSecret: 'supabase-secret',
      fcmToken: 'fcm-secret',
    });

    const serialized = lines[0] ?? '';
    expect(serialized).not.toContain('Bearer jwt');
    expect(serialized).not.toContain('session=secret');
    expect(serialized).not.toContain('private chat body');
    expect(serialized).not.toContain('password-secret');
    expect(serialized).not.toContain('supabase-secret');
    expect(serialized).not.toContain('fcm-secret');
  });
});
