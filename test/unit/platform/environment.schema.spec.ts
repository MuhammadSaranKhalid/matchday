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
      SWAGGER_ENABLED: true,
    });
  });

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
    [{ NODE_ENV: 'production', APP_NAME: 'matchday', CORS_ORIGINS: '*' }, 'CORS_ORIGINS'],
    [{ CORS_ORIGINS: 'not a url' }, 'CORS_ORIGINS'],
    [{ NODE_ENV: 'preview' }, 'NODE_ENV'],
    [{ LOG_LEVEL: 'verbose' }, 'LOG_LEVEL'],
  ])('rejects invalid environment input %o', (input, expectedField) => {
    expect(() => parseEnvironment(input)).toThrow(expectedField);
  });

  it('does not include unknown secret values in validation errors', () => {
    const candidateSecret = 'do-not-echo-this-secret';

    try {
      parseEnvironment({
        NODE_ENV: 'production',
        APP_NAME: '',
        SUPABASE_SECRET_KEY: candidateSecret,
      });
      throw new Error('expected validation to fail');
    } catch (error) {
      expect(String(error)).toContain('APP_NAME');
      expect(String(error)).not.toContain(candidateSecret);
    }
  });
});
