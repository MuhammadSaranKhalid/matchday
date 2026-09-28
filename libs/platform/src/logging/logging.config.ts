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

function pinoTime(): string {
  return `,"time":"${new Date().toISOString()}"`;
}
