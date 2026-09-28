import pino from 'pino';
import { describe, expect, it } from 'vitest';

import type { PlatformConfiguration } from '../../../libs/platform/src/config/configuration.js';
import { ExecutionContextService } from '../../../libs/platform/src/context/execution-context.service.js';
import {
  buildPinoOptions,
  sanitizeRequestUrl,
} from '../../../libs/platform/src/logging/logging.config.js';

const configuration: PlatformConfiguration = {
  nodeEnvironment: 'test',
  appName: 'matchday-test',
  port: 3000,
  logLevel: 'info',
  corsOrigins: ['http://localhost:3000'],
  bodyLimit: '1mb',
  throttle: { ttlMs: 60_000, limit: 100 },
  trustProxyHops: 0,
  swaggerEnabled: false,
  production: false,
  database: {
    url: 'postgresql://localhost/test', poolMax: 10, connectionTimeoutMs: 5_000,
    idleTimeoutMs: 30_000, statementTimeoutMs: 10_000, sslMode: 'disable',
  },
  redis: {
    url: 'redis://localhost', connectionTimeoutMs: 5_000, commandTimeoutMs: 2_000,
    maxRetriesPerRequest: 3, namespace: 'matchday',
  },
  auth: {
    supabaseUrl: 'http://localhost:54321', issuer: 'http://localhost:54321/auth/v1',
    audience: 'authenticated', mode: 'jwks', verificationTimeoutMs: 3_000,
    jwksCacheMaxAgeMs: 600_000, jwksCooldownMs: 30_000,
  },
  queue: {
    attempts: 5, backoffDelayMs: 1_000, removeOnCompleteCount: 1_000,
    removeOnFailCount: 5_000,
  },
};

describe('buildPinoOptions', () => {
  it('removes query strings from logged request URLs', () => {
    expect(sanitizeRequestUrl('/oauth/callback?code=secret&token=also-secret')).toBe(
      '/oauth/callback',
    );
  });
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
      databaseUrl: 'postgresql://user:database-secret@localhost/database',
      redisUrl: 'redis://default:redis-secret@localhost',
      SUPABASE_PUBLISHABLE_KEY: 'publishable-secret',
      nested: {
        accessToken: 'access-token-secret',
        refresh_token: 'refresh-token-secret',
        apiKey: 'api-key-secret',
      },
    });

    const serialized = lines[0] ?? '';
    expect(serialized).not.toContain('Bearer jwt');
    expect(serialized).not.toContain('session=secret');
    expect(serialized).not.toContain('private chat body');
    expect(serialized).not.toContain('password-secret');
    expect(serialized).not.toContain('supabase-secret');
    expect(serialized).not.toContain('fcm-secret');
    expect(serialized).not.toContain('database-secret');
    expect(serialized).not.toContain('redis-secret');
    expect(serialized).not.toContain('publishable-secret');
    expect(serialized).not.toContain('access-token-secret');
    expect(serialized).not.toContain('refresh-token-secret');
    expect(serialized).not.toContain('api-key-secret');
  });
});
