import { describe, expect, it } from 'vitest';

import { parseEnvironment } from '../../../libs/platform/src/config/environment.schema.js';

describe('parseEnvironment', () => {
  it('applies safe development defaults', () => {
    expect(parseEnvironment({})).toEqual({
      NODE_ENV: 'development',
      APP_NAME: 'matchday',
      PORT: 3000,
      LOG_LEVEL: 'info',
      CORS_ORIGINS: ['http://localhost:3000'],
      BODY_LIMIT: '1mb',
      THROTTLE_TTL_MS: 60_000,
      THROTTLE_LIMIT: 100,
      TRUST_PROXY_HOPS: 0,
      SWAGGER_ENABLED: true,
      DATABASE_URL: 'postgresql://matchday:matchday@127.0.0.1:5432/matchday',
      DATABASE_POOL_MAX: 10,
      DATABASE_CONNECTION_TIMEOUT_MS: 5_000,
      DATABASE_IDLE_TIMEOUT_MS: 30_000,
      DATABASE_STATEMENT_TIMEOUT_MS: 10_000,
      DATABASE_SSL_MODE: 'disable',
      REDIS_URL: 'redis://127.0.0.1:6379',
      REDIS_CONNECTION_TIMEOUT_MS: 5_000,
      REDIS_COMMAND_TIMEOUT_MS: 2_000,
      REDIS_MAX_RETRIES_PER_REQUEST: 3,
      REDIS_NAMESPACE: 'matchday',
      SUPABASE_URL: 'http://127.0.0.1:54321',
      SUPABASE_AUTH_ISSUER: 'http://127.0.0.1:54321/auth/v1',
      SUPABASE_AUTH_AUDIENCE: 'authenticated',
      SUPABASE_AUTH_MODE: 'jwks',
      SUPABASE_AUTH_VERIFICATION_TIMEOUT_MS: 3_000,
      SUPABASE_JWKS_CACHE_MAX_AGE_MS: 600_000,
      SUPABASE_JWKS_COOLDOWN_MS: 30_000,
      QUEUE_ATTEMPTS: 5,
      QUEUE_BACKOFF_DELAY_MS: 1_000,
      QUEUE_REMOVE_ON_COMPLETE_COUNT: 1_000,
      QUEUE_REMOVE_ON_FAIL_COUNT: 5_000,
    });
  });

  const productionEnvironment = {
    NODE_ENV: 'production',
    APP_NAME: 'matchday',
    DATABASE_URL: 'postgresql://service:secret@database.internal:5432/matchday',
    REDIS_URL: 'rediss://default:secret@redis.internal:6379',
    SUPABASE_URL: 'https://project.supabase.co',
    SUPABASE_AUTH_ISSUER: 'https://project.supabase.co/auth/v1',
    SUPABASE_AUTH_MODE: 'jwks',
  } as const;

  it.each([
    'DATABASE_URL',
    'REDIS_URL',
    'SUPABASE_URL',
    'SUPABASE_AUTH_ISSUER',
    'SUPABASE_AUTH_MODE',
  ])('requires %s in production', (field) => {
    const input = { ...productionEnvironment } as Record<string, string>;
    delete input[field];
    expect(() => parseEnvironment(input)).toThrow(field);
  });

  it('requires a publishable key only for remote verification', () => {
    expect(() =>
      parseEnvironment({ ...productionEnvironment, SUPABASE_AUTH_MODE: 'remote' }),
    ).toThrow('SUPABASE_PUBLISHABLE_KEY');
    expect(() => parseEnvironment(productionEnvironment)).not.toThrow();
  });

  it('accepts only explicit supported auth and database SSL modes', () => {
    expect(() => parseEnvironment({ SUPABASE_AUTH_MODE: 'offline' })).toThrow(
      'SUPABASE_AUTH_MODE',
    );
    expect(() => parseEnvironment({ DATABASE_SSL_MODE: 'prefer' })).toThrow(
      'DATABASE_SSL_MODE',
    );
    expect(parseEnvironment({ SUPABASE_AUTH_MODE: 'remote', SUPABASE_PUBLISHABLE_KEY: 'key' }))
      .toMatchObject({ SUPABASE_AUTH_MODE: 'remote' });
    expect(parseEnvironment({ DATABASE_SSL_MODE: 'verify-full' })).toMatchObject({
      DATABASE_SSL_MODE: 'verify-full',
    });
  });

  it.each([
    'DATABASE_POOL_MAX',
    'DATABASE_CONNECTION_TIMEOUT_MS',
    'DATABASE_IDLE_TIMEOUT_MS',
    'DATABASE_STATEMENT_TIMEOUT_MS',
    'REDIS_CONNECTION_TIMEOUT_MS',
    'REDIS_COMMAND_TIMEOUT_MS',
    'REDIS_MAX_RETRIES_PER_REQUEST',
    'SUPABASE_AUTH_VERIFICATION_TIMEOUT_MS',
    'SUPABASE_JWKS_CACHE_MAX_AGE_MS',
    'SUPABASE_JWKS_COOLDOWN_MS',
    'QUEUE_ATTEMPTS',
    'QUEUE_BACKOFF_DELAY_MS',
    'QUEUE_REMOVE_ON_COMPLETE_COUNT',
    'QUEUE_REMOVE_ON_FAIL_COUNT',
  ])('rejects non-positive or unbounded %s', (field) => {
    expect(() => parseEnvironment({ [field]: '0' })).toThrow(field);
    expect(() => parseEnvironment({ [field]: '999999999' })).toThrow(field);
  });

  it.each(['', 'Matchday', 'matchday tenant', 'matchday/tenant']) (
    'rejects invalid Redis namespace %j',
    (namespace) => expect(() => parseEnvironment({ REDIS_NAMESPACE: namespace })).toThrow('REDIS_NAMESPACE'),
  );

  it('normalizes comma-delimited CORS origins', () => {
    const environment = parseEnvironment({
      CORS_ORIGINS: ' https://app.matchday.example/path,https://admin.matchday.example/ ',
    });

    expect(environment.CORS_ORIGINS).toEqual([
      'https://app.matchday.example',
      'https://admin.matchday.example',
    ]);
  });

  it.each([
    [{ NODE_ENV: 'production' }, 'APP_NAME'],
    [{ PORT: '0' }, 'PORT'],
    [{ PORT: 'not-a-number' }, 'PORT'],
    [{ ...productionEnvironment, CORS_ORIGINS: '*' }, 'CORS_ORIGINS'],
    [{ CORS_ORIGINS: 'not a url' }, 'CORS_ORIGINS'],
    [{ NODE_ENV: 'preview' }, 'NODE_ENV'],
    [{ LOG_LEVEL: 'verbose' }, 'LOG_LEVEL'],
    [{ TRUST_PROXY_HOPS: '-1' }, 'TRUST_PROXY_HOPS'],
    [{ TRUST_PROXY_HOPS: 'all' }, 'TRUST_PROXY_HOPS'],
  ])('rejects invalid environment input %o', (input, expectedField) => {
    expect(() => parseEnvironment(input)).toThrow(expectedField);
  });

  it('does not include unknown secret values in validation errors', () => {
    const candidateSecret = 'do-not-echo-this-secret';

    try {
      parseEnvironment({
        NODE_ENV: 'production',
        APP_NAME: '',
        DATABASE_URL: candidateSecret,
        REDIS_URL: candidateSecret,
        SUPABASE_URL: candidateSecret,
        SUPABASE_AUTH_ISSUER: candidateSecret,
        SUPABASE_AUTH_MODE: 'remote',
        SUPABASE_PUBLISHABLE_KEY: candidateSecret,
        SUPABASE_SECRET_KEY: candidateSecret,
      });
      throw new Error('expected validation to fail');
    } catch (error) {
      expect(String(error)).toContain('APP_NAME');
      expect(String(error)).not.toContain(candidateSecret);
    }
  });
});
