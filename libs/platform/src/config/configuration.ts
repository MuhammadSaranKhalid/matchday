import type { Environment } from './environment.schema.js';

export interface PlatformConfiguration {
  readonly nodeEnvironment: Environment['NODE_ENV'];
  readonly appName: string;
  readonly port: number;
  readonly logLevel: Environment['LOG_LEVEL'];
  readonly corsOrigins: readonly string[];
  readonly bodyLimit: string;
  readonly throttle: Readonly<{ ttlMs: number; limit: number }>;
  readonly swaggerEnabled: boolean;
  readonly production: boolean;
}

export function buildConfiguration(environment: Environment): PlatformConfiguration {
  return Object.freeze({
    nodeEnvironment: environment.NODE_ENV,
    appName: environment.APP_NAME,
    port: environment.PORT,
    logLevel: environment.LOG_LEVEL,
    corsOrigins: environment.CORS_ORIGINS,
    bodyLimit: environment.BODY_LIMIT,
    throttle: Object.freeze({
      ttlMs: environment.THROTTLE_TTL_MS,
      limit: environment.THROTTLE_LIMIT,
    }),
    swaggerEnabled: environment.SWAGGER_ENABLED,
    production: environment.NODE_ENV === 'production',
  });
}
