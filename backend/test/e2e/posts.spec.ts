import type { INestApplication } from '@nestjs/common';
import { StandardSchemaValidationPipe, VersioningType } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TOKEN_VERIFIER, TokenVerificationError } from '../../libs/platform/src/auth/token-verifier.js';
import { CreatePostService } from '../../libs/modules/posts/src/application/create-post.service.js';
import { PublishPostService } from '../../libs/modules/posts/src/application/publish-post.service.js';
import { PostsController } from '../../libs/modules/posts/src/presentation/http/posts.controller.js';

const principal: AuthenticatedPrincipal = {
  userId: '10000000-0000-4000-8000-000000000001',
  role: 'authenticated',
  appMetadata: {},
};
const postId = '30000000-0000-4000-8000-000000000001';
const validCommand = {
  clientCommandId: '20000000-0000-4000-8000-000000000001',
  publisherType: 'user',
  publisherId: principal.userId,
  postKind: 'standard',
  text: 'Matchday',
  media: [],
};

describe('post commands', () => {
  let app: INestApplication;
  const verifier = { verify: vi.fn().mockResolvedValue(principal) };
  const create = { execute: vi.fn() };
  const publish = { execute: vi.fn(), status: vi.fn() };

  beforeEach(async () => {
    verifier.verify.mockResolvedValue(principal);
    create.execute.mockResolvedValue({ postId, status: 'draft', media: [] });
    publish.execute.mockResolvedValue({ status: 'published' });
    publish.status.mockResolvedValue({ status: 'processing' });
    const module = await Test.createTestingModule({
      controllers: [PostsController],
      providers: [
        { provide: TOKEN_VERIFIER, useValue: verifier },
        { provide: CreatePostService, useValue: create },
        { provide: PublishPostService, useValue: publish },
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new StandardSchemaValidationPipe());
    await app.init();
  });

  afterEach(async () => app.close());

  it('requires a valid bearer token for every post command', async () => {
    await request(app.getHttpServer()).post('/api/v1/posts').send(validCommand).expect(401);
    await request(app.getHttpServer()).post(`/api/v1/posts/${postId}/publish`).expect(401);
    await request(app.getHttpServer()).get(`/api/v1/posts/${postId}/status`).expect(401);
    expect(create.execute).not.toHaveBeenCalled();
  });

  it.each([
    ['invalid_token', 401],
    ['verification_unavailable', 503],
  ] as const)('maps %s without exposing verifier internals', async (code, status) => {
    verifier.verify.mockRejectedValueOnce(new TokenVerificationError(code));
    const response = await request(app.getHttpServer())
      .post('/api/v1/posts')
      .set('authorization', 'Bearer rejected-token')
      .send(validCommand)
      .expect(status);
    expect(JSON.stringify(response.body)).not.toContain('rejected-token');
    expect(create.execute).not.toHaveBeenCalled();
  });

  it('creates through the authenticated principal and rejects five images', async () => {
    const authorized = request(app.getHttpServer()).post('/api/v1/posts').set('authorization', 'Bearer access-token');
    await authorized.send(validCommand).expect(201, { postId, status: 'draft', media: [] });
    expect(verifier.verify).toHaveBeenCalledWith('access-token');
    expect(create.execute).toHaveBeenCalledWith(principal, validCommand);

    await request(app.getHttpServer())
      .post('/api/v1/posts')
      .set('authorization', 'Bearer access-token')
      .send({
        ...validCommand,
        media: Array.from({ length: 5 }, () => ({
          width: 100,
          height: 100,
          bytes: 100,
          mimeType: 'image/jpeg',
        })),
      })
      .expect(400);
  });

  it.each(['processing', 'published', 'failed'] as const)(
    'returns owner-scoped %s status',
    async (status) => {
      publish.status.mockResolvedValueOnce({ status });
      await request(app.getHttpServer())
        .get(`/api/v1/posts/${postId}/status`)
        .set('authorization', 'Bearer access-token')
        .expect(200, { status });
      expect(publish.status).toHaveBeenCalledWith(principal, postId);
    },
  );

  it('publishes through the single completion endpoint', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/posts/${postId}/publish`)
      .set('authorization', 'Bearer access-token')
      .expect(201, { status: 'published' });
    expect(publish.execute).toHaveBeenCalledWith(principal, postId);
  });
});
