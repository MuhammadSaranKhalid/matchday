import { Body, Controller, Get, Post, Version } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getQueueToken } from '@nestjs/bullmq';
import { IsString, MinLength } from 'class-validator';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { ApiModule } from '../../apps/api/src/api.module.js';
import { configureApi } from '../../apps/api/src/bootstrap/api-bootstrap.js';
import type { PlatformConfiguration } from '../../libs/platform/src/config/configuration.js';
import { QUEUE_NAMES } from '../../libs/platform/src/queue/queue-names.js';

class ProbeDto {
  @IsString()
  @MinLength(2)
  name!: string;
}

@Controller('probe')
class ProbeController {
  @Get()
  @Version('1')
  read(): { ok: true } {
    return { ok: true };
  }

  @Post()
  @Version('1')
  write(@Body() body: ProbeDto): ProbeDto {
    return body;
  }
}

const baseConfiguration: PlatformConfiguration = {
  nodeEnvironment: 'test',
  appName: 'matchday-test',
  port: 0,
  logLevel: 'silent',
  corsOrigins: ['https://allowed.example'],
  bodyLimit: '100b',
  throttle: { ttlMs: 60_000, limit: 2 },
  trustProxyHops: 1,
  swaggerEnabled: true,
  production: false,
};

function apiTestModule() {
  const builder = Test.createTestingModule({
    imports: [ApiModule],
    controllers: [ProbeController],
  });
  for (const name of QUEUE_NAMES) {
    builder.overrideProvider(getQueueToken(name)).useValue({ close: vi.fn(), waitUntilReady: vi.fn() });
  }
  return builder.compile();
}

describe('API bootstrap', () => {
  let app: INestApplication;

  beforeEach(async () => {
    process.env.NODE_ENV = 'test';
    process.env.APP_NAME = 'matchday-test';
    process.env.LOG_LEVEL = 'silent';
    process.env.CORS_ORIGINS = 'https://allowed.example';
    process.env.BODY_LIMIT = '100b';
    process.env.THROTTLE_TTL_MS = '60000';
    process.env.THROTTLE_LIMIT = '2';
    process.env.TRUST_PROXY_HOPS = '1';
    process.env.SWAGGER_ENABLED = 'true';

    const module = await apiTestModule();

    app = module.createNestApplication({ bodyParser: false });
    await configureApi(app, baseConfiguration);
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('serves business routes under the v1 API prefix with security headers', async () => {
    const response = await request(app.getHttpServer()).get('/api/v1/probe').expect(200);
    expect(response.body).toEqual({ ok: true });
    expect(response.headers['x-content-type-options']).toBe('nosniff');
    await request(app.getHttpServer()).get('/probe').expect(404);
  });

  it('allows only configured CORS origins', async () => {
    const allowed = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('origin', 'https://allowed.example');
    expect(allowed.headers['access-control-allow-origin']).toBe('https://allowed.example');

    const denied = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('origin', 'https://denied.example');
    expect(denied.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('returns validation failures in the stable envelope', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/probe')
      .send({ name: 'x', unexpected: true })
      .expect(400);
    expect(response.body).toMatchObject({
      code: 'VALIDATION_FAILED',
      status: 400,
      details: { validation: expect.any(Array) },
    });
  });

  it('returns an oversized body error in the stable envelope', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/probe')
      .set('content-type', 'application/json')
      .send({ name: 'a'.repeat(256) })
      .expect(413);
    expect(response.body).toMatchObject({ code: 'PAYLOAD_TOO_LARGE', status: 413 });
    expect(response.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    expect(response.headers['x-correlation-id']).toMatch(/^[0-9a-f-]{36}$/);
    expect(response.body.correlationId).toBe(response.headers['x-correlation-id']);
  });

  it('correlates malformed JSON before parser errors are handled', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/probe')
      .set('content-type', 'application/json')
      .send('{"name":')
      .expect(400);

    expect(response.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
    expect(response.body.correlationId).toBe(response.headers['x-correlation-id']);
  });

  it('uses the nearest trusted proxy hop when throttling clients', async () => {
    const first = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-forwarded-for', '203.0.113.1, 198.51.100.10');
    const second = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-forwarded-for', '203.0.113.2, 198.51.100.10');
    const spoofedThird = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-forwarded-for', '203.0.113.3, 198.51.100.10');
    const differentClient = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-forwarded-for', '203.0.113.3, 198.51.100.11');

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect(spoofedThird.status).toBe(429);
    expect(differentClient.status).toBe(200);
  });

  it('returns a stable rate-limit error after the configured allowance', async () => {
    await request(app.getHttpServer()).get('/api/v1/probe').expect(200);
    await request(app.getHttpServer()).get('/api/v1/probe').expect(200);
    const response = await request(app.getHttpServer()).get('/api/v1/probe').expect(429);
    expect(response.body).toMatchObject({ code: 'RATE_LIMIT_EXCEEDED', status: 429 });
  });

  it('echoes valid correlation IDs and replaces malformed identifiers', async () => {
    const valid = '178b9bce-1a9b-4398-9b24-e7867a9f8240';
    const preserved = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-correlation-id', valid);
    expect(preserved.headers['x-correlation-id']).toBe(valid);

    const replaced = await request(app.getHttpServer())
      .get('/api/v1/probe')
      .set('x-correlation-id', 'invalid');
    expect(replaced.headers['x-correlation-id']).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
  });

  it('exposes Swagger UI and JSON only when enabled', async () => {
    await request(app.getHttpServer()).get('/api/docs').expect(200);
    await request(app.getHttpServer()).get('/api/docs-json').expect(200);

    const module = await apiTestModule();
    const disabledApp = module.createNestApplication({ bodyParser: false });
    await configureApi(disabledApp, { ...baseConfiguration, swaggerEnabled: false });
    await disabledApp.init();
    await request(disabledApp.getHttpServer()).get('/api/docs').expect(404);
    await request(disabledApp.getHttpServer()).get('/api/docs-json').expect(404);
    await disabledApp.close();
  });
});
