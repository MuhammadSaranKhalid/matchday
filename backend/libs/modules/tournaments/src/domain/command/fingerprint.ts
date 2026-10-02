import { createHash } from 'node:crypto';
import { TournamentError } from '../errors/tournament-error-codes.js';
import type { TournamentCommand } from './tournament-command.js';

export function canonicalJsonStringify(value: unknown): string {
  if (value === null) {
    return 'null';
  }
  if (typeof value === 'boolean') {
    return value ? 'true' : 'false';
  }
  if (typeof value === 'number') {
    if (Number.isNaN(value) || !Number.isFinite(value)) {
      throw TournamentError.badRequest('Non-finite numbers (NaN/Infinity) are not allowed in command payload');
    }
    return JSON.stringify(value);
  }
  if (typeof value === 'string') {
    return JSON.stringify(value);
  }
  if (typeof value === 'bigint') {
    throw TournamentError.badRequest('BigInt values are not allowed in command payload');
  }
  if (typeof value === 'function' || typeof value === 'symbol' || value === undefined) {
    throw TournamentError.badRequest(`Unsupported value (${typeof value}) in command payload`);
  }
  if (value instanceof Date) {
    throw TournamentError.badRequest('Date objects are not allowed in command payload; use ISO-8601 strings');
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => canonicalJsonStringify(item)).join(',')}]`;
  }
  if (typeof value === 'object') {
    const proto = Object.getPrototypeOf(value);
    if (proto !== null && proto !== Object.prototype) {
      throw TournamentError.badRequest('Non-plain objects are not allowed in command payload');
    }
    const record = value as Record<string, unknown>;
    const sortedKeys = Object.keys(record).sort();
    const entries: string[] = [];

    for (const key of sortedKeys) {
      const val = record[key];
      if (val === undefined) {
        throw TournamentError.badRequest(`Undefined property '${key}' is not allowed in command payload`);
      }
      entries.push(`${JSON.stringify(key)}:${canonicalJsonStringify(val)}`);
    }

    return `{${entries.join(',')}}`;
  }

  throw TournamentError.badRequest('Unsupported value type in command payload');
}

export function computeRequestFingerprint(
  command: Pick<TournamentCommand, 'action' | 'resources' | 'expectedRevision' | 'payload'>,
): string {
  const normalized = {
    action: command.action,
    expectedRevision: command.expectedRevision ?? null,
    payload: command.payload ?? null,
    resources: command.resources ?? {},
  };

  const canonicalJson = canonicalJsonStringify(normalized);
  return createHash('sha256').update(canonicalJson, 'utf8').digest('hex');
}

