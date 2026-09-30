import type { Environment } from './environment.schema.js';

export interface DatabaseConfiguration {
  readonly url: string;
  readonly poolMax: number;
  readonly connectionTimeoutMs: number;
  readonly idleTimeoutMs: number;
  readonly statementTimeoutMs: number;
  readonly sslMode: 'disable' | 'require' | 'verify-full';
}

export interface RedisConfiguration {
  readonly url: string;
  readonly connectionTimeoutMs: number;
  readonly commandTimeoutMs: number;
  readonly maxRetriesPerRequest: number;
  readonly namespace: string;
}

export interface AuthConfiguration {
  readonly supabaseUrl: string;
  readonly publishableKey: string;
  readonly issuer: string;
  readonly audience: string;
}

export interface QueueConfiguration {
  readonly attempts: number;
  readonly backoffDelayMs: number;
  readonly removeOnCompleteCount: number;
  readonly removeOnFailCount: number;
}

export interface MediaStorageConfiguration {
  readonly supabaseUrl: string;
  readonly secretKey: string;
}

export interface PlatformConfiguration {
  readonly nodeEnvironment: Environment['NODE_ENV'];
  readonly appName: string;
  readonly port: number;
  readonly logLevel: Environment['LOG_LEVEL'];
  readonly corsOrigins: readonly string[];
  readonly bodyLimit: string;
  readonly throttle: Readonly<{ ttlMs: number; limit: number }>;
  readonly trustProxyHops: number;
  readonly swaggerEnabled: boolean;
  readonly production: boolean;
  readonly database: Readonly<DatabaseConfiguration>;
  readonly redis: Readonly<RedisConfiguration>;
  readonly auth: Readonly<AuthConfiguration>;
  readonly mediaStorage: Readonly<MediaStorageConfiguration>;
  readonly queue: Readonly<QueueConfiguration>;
}

export function buildConfiguration(environment: Environment): PlatformConfiguration {
  const supabaseUrl = environment.SUPABASE_URL.replace(/\/+$/, '');
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
    trustProxyHops: environment.TRUST_PROXY_HOPS,
    swaggerEnabled: environment.SWAGGER_ENABLED,
    production: environment.NODE_ENV === 'production',
    database: Object.freeze({
      url: environment.DATABASE_URL,
      poolMax: environment.DATABASE_POOL_MAX,
      connectionTimeoutMs: environment.DATABASE_CONNECTION_TIMEOUT_MS,
      idleTimeoutMs: environment.DATABASE_IDLE_TIMEOUT_MS,
      statementTimeoutMs: environment.DATABASE_STATEMENT_TIMEOUT_MS,
      sslMode: environment.DATABASE_SSL_MODE,
    }),
    redis: Object.freeze({
      url: environment.REDIS_URL,
      connectionTimeoutMs: environment.REDIS_CONNECTION_TIMEOUT_MS,
      commandTimeoutMs: environment.REDIS_COMMAND_TIMEOUT_MS,
      maxRetriesPerRequest: environment.REDIS_MAX_RETRIES_PER_REQUEST,
      namespace: environment.REDIS_NAMESPACE,
    }),
    auth: Object.freeze({
      supabaseUrl,
      publishableKey: environment.SUPABASE_PUBLISHABLE_KEY,
      issuer: `${supabaseUrl}/auth/v1`,
      audience: 'authenticated',
    }),
    mediaStorage: Object.freeze({
      supabaseUrl,
      secretKey: environment.SUPABASE_SECRET_KEY,
    }),
    queue: Object.freeze({
      attempts: environment.QUEUE_ATTEMPTS,
      backoffDelayMs: environment.QUEUE_BACKOFF_DELAY_MS,
      removeOnCompleteCount: environment.QUEUE_REMOVE_ON_COMPLETE_COUNT,
      removeOnFailCount: environment.QUEUE_REMOVE_ON_FAIL_COUNT,
    }),
  });
}
