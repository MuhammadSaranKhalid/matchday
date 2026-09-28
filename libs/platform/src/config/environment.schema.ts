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
  readonly SWAGGER_ENABLED: boolean;
}

function positiveInteger(defaultValue: number) {
  return z.coerce.number().int().positive().default(defaultValue);
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
  const schema = z.object({
    APP_NAME: production ? z.string().trim().min(1) : z.string().trim().min(1).default('matchday'),
    PORT: positiveInteger(3000).pipe(z.number().max(65_535)),
    LOG_LEVEL: logLevelSchema.default('info'),
    CORS_ORIGINS: z.string().default('http://localhost:3000'),
    BODY_LIMIT: z.string().regex(/^\d+(?:b|kb|mb)$/i).default('1mb'),
    THROTTLE_TTL_MS: positiveInteger(60_000),
    THROTTLE_LIMIT: positiveInteger(100),
    SWAGGER_ENABLED: booleanValue(!production),
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
