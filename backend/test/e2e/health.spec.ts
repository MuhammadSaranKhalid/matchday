import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { ApiModule } from '../../apps/api/src/api.module.js';
import { configureApi } from '../../apps/api/src/bootstrap/api-bootstrap.js';
import type { PlatformConfiguration } from '../../libs/platform/src/config/configuration.js';
import { ReadinessService } from '../../libs/platform/src/health/readiness.service.js';
import { PostgresHealthIndicator } from '../../libs/platform/src/database/postgres-health.indicator.js';
import { RedisHealthIndicator } from '../../libs/platform/src/redis/redis-health.indicator.js';
import { MEDIA_QUEUE_NAME } from '@modules/media';

const configuration: PlatformConfiguration = {
  nodeEnvironment: 'test',
  appName: 'matchday-test',
  port: 0,
  logLevel: 'silent',
  corsOrigins: ['http://localhost:3000'],
  bodyLimit: '1mb',
  throttle: { ttlMs: 60_000, limit: 100 },
  trustProxyHops: 0,
  swaggerEnabled: false,
  production: false,
};

describe('health endpoints', () => {
  let app: INestApplication;
  let readiness: ReadinessService;
  const postgresHealth = { isHealthy: vi.fn(async () => ({ postgres: { status: 'up' as const } })) };
  const redisHealth = { isHealthy: vi.fn(async () => ({ redis: { status: 'up' as const } })) };

  beforeEach(async () => {
    postgresHealth.isHealthy.mockResolvedValue({ postgres: { status: 'up' as const } });
    redisHealth.isHealthy.mockResolvedValue({ redis: { status: 'up' as const } });
    process.env.NODE_ENV = 'test';
    process.env.APP_NAME = 'matchday-test';
    process.env.LOG_LEVEL = 'silent';
    process.env.SUPABASE_SECRET_KEY = 'must-not-leak';

    const builder = Test.createTestingModule({ imports: [ApiModule] })
      .overrideProvider(PostgresHealthIndicator).useValue(postgresHealth)
      .overrideProvider(RedisHealthIndicator).useValue(redisHealth);
    builder.overrideProvider(getQueueToken(MEDIA_QUEUE_NAME)).useValue({ close: vi.fn(), waitUntilReady: vi.fn() });
    const module = await builder.compile();
    app = module.createNestApplication({ bodyParser: false });
    await configureApi(app, configuration);
    await app.init();
    readiness = app.get(ReadinessService);
  });

  afterEach(async () => {
    await app.close();
    delete process.env.SUPABASE_SECRET_KEY;
  });

  it('keeps liveness independent from readiness', async () => {
    const response = await request(app.getHttpServer()).get('/health/live').expect(200);
    expect(response.body).toMatchObject({ status: 'ok' });
    expect(JSON.stringify(response.body)).not.toContain('must-not-leak');
  });

  it('reports not ready before initialization completes and ready afterward', async () => {
    await request(app.getHttpServer()).get('/health/ready').expect(503);
    readiness.markReady();
    readiness.markQueuesInitialized();
    const response = await request(app.getHttpServer()).get('/health/ready').expect(200);
    expect(response.body).toMatchObject({ status: 'ok' });
    expect(JSON.stringify(response.body)).not.toContain('must-not-leak');
  });

  it('keeps health routes outside the versioned business prefix', async () => {
    await request(app.getHttpServer()).get('/api/v1/health/live').expect(404);
    await request(app.getHttpServer()).get('/api/v1/health/ready').expect(404);
  });

  it.each([
    ['postgres', postgresHealth, { postgres: { status: 'down' as const } }],
    ['redis', redisHealth, { redis: { status: 'down' as const } }],
  ])('keeps liveness up while %s makes readiness fail', async (label, indicator, result) => {
    readiness.markQueuesInitialized();
    readiness.markReady();
    indicator.isHealthy.mockResolvedValueOnce(result as never);

    await request(app.getHttpServer()).get('/health/live').expect(200);
    const response = await request(app.getHttpServer()).get('/health/ready').expect(503);
    expect(JSON.stringify(response.body)).toContain(label);
    expect(JSON.stringify(response.body)).not.toContain('must-not-leak');
  });

  it('removes readiness as soon as shutdown begins', async () => {
    readiness.markQueuesInitialized();
    readiness.markReady();
    readiness.markStopping();

    const response = await request(app.getHttpServer()).get('/health/ready').expect(503);
    expect(response.body.details).toMatchObject({ foundation: { status: 'down' } });
  });
});
