import { z } from 'zod';

const nodeEnvironmentSchema = z.enum(['development', 'test', 'production']);
const logLevelSchema = z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']);

export interface Environment {
  readonly NODE_ENV: 'development' | 'test' | 'production';
  readonly APP_NAME: string;
  readonly PORT: number;
  readonly LOG_LEVEL: z.infer<typeof logLevelSchema>;
  readonly CORS_ORIGINS: readonly string[];
  readonly BODY_LIMIT: string;
  readonly THROTTLE_TTL_MS: number;
  readonly THROTTLE_LIMIT: number;
  readonly TRUST_PROXY_HOPS: number;
  readonly SWAGGER_ENABLED: boolean;
  readonly DATABASE_URL: string;
  readonly DATABASE_POOL_MAX: number;
  readonly DATABASE_CONNECTION_TIMEOUT_MS: number;
  readonly DATABASE_IDLE_TIMEOUT_MS: number;
  readonly DATABASE_STATEMENT_TIMEOUT_MS: number;
  readonly DATABASE_SSL_MODE: 'disable' | 'require' | 'verify-full';
  readonly REDIS_URL: string;
  readonly REDIS_CONNECTION_TIMEOUT_MS: number;
  readonly REDIS_COMMAND_TIMEOUT_MS: number;
  readonly REDIS_MAX_RETRIES_PER_REQUEST: number;
  readonly REDIS_NAMESPACE: string;
  readonly SUPABASE_URL: string;
  readonly SUPABASE_SECRET_KEY: string;
  readonly SUPABASE_AUTH_ISSUER: string;
  readonly SUPABASE_AUTH_AUDIENCE: string;
  readonly SUPABASE_AUTH_MODE: 'jwks' | 'remote';
  readonly SUPABASE_PUBLISHABLE_KEY?: string;
  readonly SUPABASE_AUTH_VERIFICATION_TIMEOUT_MS: number;
  readonly SUPABASE_JWKS_CACHE_MAX_AGE_MS: number;
  readonly SUPABASE_JWKS_COOLDOWN_MS: number;
  readonly QUEUE_ATTEMPTS: number;
  readonly QUEUE_BACKOFF_DELAY_MS: number;
  readonly QUEUE_REMOVE_ON_COMPLETE_COUNT: number;
  readonly QUEUE_REMOVE_ON_FAIL_COUNT: number;
}

function positiveInteger(defaultValue: number, maximum = 120_000) {
  return z.coerce.number().int().positive().max(maximum).default(defaultValue);
}

function booleanValue(defaultValue: boolean) {
  return z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((value) => value === true || value === 'true')
    .default(defaultValue);
}

function normalizeOrigins(raw: string, production: boolean): readonly string[] {
  const candidates = raw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  if (candidates.length === 0 || (production && candidates.includes('*'))) {
    throw new Error('Invalid environment: CORS_ORIGINS');
  }

  return candidates.map((candidate) => {
    if (candidate === '*') return candidate;
    try {
      const url = new URL(candidate);
      if (!['http:', 'https:'].includes(url.protocol)) throw new Error('unsupported protocol');
      return url.origin;
    } catch {
      throw new Error('Invalid environment: CORS_ORIGINS');
    }
  });
}

export function parseEnvironment(input: NodeJS.ProcessEnv): Environment {
  const nodeEnvironment = nodeEnvironmentSchema.safeParse(input.NODE_ENV ?? 'development');
  if (!nodeEnvironment.success) throw new Error('Invalid environment: NODE_ENV');

  const production = nodeEnvironment.data === 'production';
  const requiredInProduction = (developmentDefault: string) =>
    production ? z.string().trim().min(1) : z.string().trim().min(1).default(developmentDefault);
  const schema = z.object({
    APP_NAME: production ? z.string().trim().min(1) : z.string().trim().min(1).default('matchday'),
    PORT: positiveInteger(3000).pipe(z.number().max(65_535)),
    LOG_LEVEL: logLevelSchema.default('info'),
    CORS_ORIGINS: z.string().default('http://localhost:3000'),
    BODY_LIMIT: z.string().regex(/^\d+(?:b|kb|mb)$/i).default('1mb'),
    THROTTLE_TTL_MS: positiveInteger(60_000),
    THROTTLE_LIMIT: positiveInteger(100),
    TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(10).default(0),
    SWAGGER_ENABLED: booleanValue(!production),
    DATABASE_URL: requiredInProduction(
      'postgresql://matchday:matchday@127.0.0.1:5432/matchday',
    ),
    DATABASE_POOL_MAX: positiveInteger(10, 100),
    DATABASE_CONNECTION_TIMEOUT_MS: positiveInteger(5_000),
    DATABASE_IDLE_TIMEOUT_MS: positiveInteger(30_000),
    DATABASE_STATEMENT_TIMEOUT_MS: positiveInteger(10_000),
    DATABASE_SSL_MODE: z.enum(['disable', 'require', 'verify-full']).default('disable'),
    REDIS_URL: requiredInProduction('redis://127.0.0.1:6379'),
    REDIS_CONNECTION_TIMEOUT_MS: positiveInteger(5_000),
    REDIS_COMMAND_TIMEOUT_MS: positiveInteger(2_000),
    REDIS_MAX_RETRIES_PER_REQUEST: positiveInteger(3, 100),
    REDIS_NAMESPACE: z.string().regex(/^[a-z0-9:_-]+$/).default('matchday'),
    SUPABASE_URL: requiredInProduction('http://127.0.0.1:54321'),
    SUPABASE_SECRET_KEY: requiredInProduction('local-supabase-secret-key'),
    SUPABASE_AUTH_ISSUER: requiredInProduction('http://127.0.0.1:54321/auth/v1'),
    SUPABASE_AUTH_AUDIENCE: z.string().trim().min(1).default('authenticated'),
    SUPABASE_AUTH_MODE: production
      ? z.enum(['jwks', 'remote'])
      : z.enum(['jwks', 'remote']).default('jwks'),
    SUPABASE_PUBLISHABLE_KEY: z.string().trim().min(1).optional(),
    SUPABASE_AUTH_VERIFICATION_TIMEOUT_MS: positiveInteger(3_000),
    SUPABASE_JWKS_CACHE_MAX_AGE_MS: positiveInteger(600_000, 86_400_000),
    SUPABASE_JWKS_COOLDOWN_MS: positiveInteger(30_000),
    QUEUE_ATTEMPTS: positiveInteger(5, 100),
    QUEUE_BACKOFF_DELAY_MS: positiveInteger(1_000),
    QUEUE_REMOVE_ON_COMPLETE_COUNT: positiveInteger(1_000, 100_000),
    QUEUE_REMOVE_ON_FAIL_COUNT: positiveInteger(5_000, 100_000),
  }).superRefine((environment, context) => {
    if (environment.SUPABASE_AUTH_MODE === 'remote' && !environment.SUPABASE_PUBLISHABLE_KEY) {
      context.addIssue({
        code: 'custom',
        path: ['SUPABASE_PUBLISHABLE_KEY'],
        message: 'required for remote authentication',
      });
    }
  });

  const result = schema.safeParse(input);
  if (!result.success) {
    const fields = [...new Set(result.error.issues.map((issue) => String(issue.path[0] ?? 'environment')))];
    throw new Error(`Invalid environment: ${fields.join(', ')}`);
  }

  return Object.freeze({
    NODE_ENV: nodeEnvironment.data,
    ...result.data,
    CORS_ORIGINS: Object.freeze(normalizeOrigins(result.data.CORS_ORIGINS, production)),
  });
}
