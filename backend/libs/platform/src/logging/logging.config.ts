import type { LoggerOptions } from 'pino';

import type { PlatformConfiguration } from '../config/configuration.js';
import type { ExecutionContextService } from '../context/execution-context.service.js';

const redactedPaths = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.body',
  'password',
  '*.password',
  'supabaseSecret',
  'supabaseSecretKey',
  'SUPABASE_SECRET_KEY',
  'fcmToken',
  'fcm_token',
  '*.fcmToken',
  '*.fcm_token',
  'databaseUrl',
  '*.databaseUrl',
  'DATABASE_URL',
  '*.DATABASE_URL',
  'redisUrl',
  '*.redisUrl',
  'REDIS_URL',
  '*.REDIS_URL',
  'SUPABASE_PUBLISHABLE_KEY',
  '*.SUPABASE_PUBLISHABLE_KEY',
  'publishableKey',
  '*.publishableKey',
  'accessToken',
  '*.accessToken',
  'access_token',
  '*.access_token',
  'refreshToken',
  '*.refreshToken',
  'refresh_token',
  '*.refresh_token',
  'apiKey',
  '*.apiKey',
  'api_key',
  '*.api_key',
  'token',
  '*.token',
  'uploadToken',
  '*.uploadToken',
  'signedUrl',
  '*.signedUrl',
  'signedURL',
  '*.signedURL',
  'key',
  '*.key',
];

export function buildPinoOptions(
  configuration: PlatformConfiguration,
  context: ExecutionContextService,
): LoggerOptions {
  return {
    name: configuration.appName,
    level: configuration.logLevel,
    base: undefined,
    timestamp: pinoTime,
    mixin: () => ({ ...context.get() }),
    redact: {
      paths: redactedPaths,
      censor: '[Redacted]',
    },
  };
}

export function sanitizeRequestUrl(rawUrl: string | undefined): string | undefined {
  if (rawUrl === undefined) return undefined;
  return rawUrl.split('?', 1)[0];
}

function pinoTime(): string {
  return `,"time":"${new Date().toISOString()}"`;
}
