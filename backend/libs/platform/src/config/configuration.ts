import type { Environment } from './environment.schema.js';

export function buildConfiguration(environment: Environment) {
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

export type PlatformConfiguration = ReturnType<typeof buildConfiguration>;
export type DatabaseConfiguration = PlatformConfiguration['database'];
export type RedisConfiguration = PlatformConfiguration['redis'];
export type AuthConfiguration = PlatformConfiguration['auth'];
export type QueueConfiguration = PlatformConfiguration['queue'];
export type MediaStorageConfiguration = PlatformConfiguration['mediaStorage'];
