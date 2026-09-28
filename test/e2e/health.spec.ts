import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { ApiModule } from '../../apps/api/src/api.module.js';
import { configureApi } from '../../apps/api/src/bootstrap/api-bootstrap.js';
import type { PlatformConfiguration } from '../../libs/platform/src/config/configuration.js';
import { ReadinessService } from '../../libs/platform/src/health/readiness.service.js';

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

  beforeEach(async () => {
    process.env.NODE_ENV = 'test';
    process.env.APP_NAME = 'matchday-test';
    process.env.LOG_LEVEL = 'silent';
    process.env.SUPABASE_SECRET_KEY = 'must-not-leak';

    const module = await Test.createTestingModule({ imports: [ApiModule] }).compile();
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
    const response = await request(app.getHttpServer()).get('/health/ready').expect(200);
    expect(response.body).toMatchObject({ status: 'ok' });
    expect(JSON.stringify(response.body)).not.toContain('must-not-leak');
  });

  it('keeps health routes outside the versioned business prefix', async () => {
    await request(app.getHttpServer()).get('/api/v1/health/live').expect(404);
    await request(app.getHttpServer()).get('/api/v1/health/ready').expect(404);
  });
});
