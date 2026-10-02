import { describe, expect, it } from 'vitest';
import {
  canonicalJsonStringify,
  computeRequestFingerprint,
} from '../../../libs/modules/tournaments/src/domain/command/fingerprint.js';

describe('Tournament command fingerprinting', () => {
  it('serializes JSON deterministically with sorted object keys', () => {
    const obj1 = { b: 2, a: 1 };
    const obj2 = { a: 1, b: 2 };
    expect(canonicalJsonStringify(obj1)).toBe(canonicalJsonStringify(obj2));
    expect(canonicalJsonStringify(obj1)).toBe('{"a":1,"b":2}');
  });

  it('recursively sorts keys of nested objects while preserving array order', () => {
    const obj1 = {
      nested: { z: 10, y: 20 },
      list: [3, 2, 1],
    };
    const obj2 = {
      list: [3, 2, 1],
      nested: { y: 20, z: 10 },
    };
    expect(canonicalJsonStringify(obj1)).toBe(canonicalJsonStringify(obj2));
    expect(canonicalJsonStringify(obj1)).toBe('{"list":[3,2,1],"nested":{"y":20,"z":10}}');

    // Array order difference must produce different string
    const obj3 = {
      list: [1, 2, 3],
      nested: { y: 20, z: 10 },
    };
    expect(canonicalJsonStringify(obj1)).not.toBe(canonicalJsonStringify(obj3));
  });

  it('produces identical SHA-256 fingerprint for semantically equivalent commands with reordered keys', () => {
    const cmd1 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1', stageId: 'stage-1' },
      expectedRevision: 3,
      payload: { b: 2, a: 1 },
    };
    const cmd2 = {
      action: 'publish_draw',
      resources: { stageId: 'stage-1', tournamentId: 'tourn-1' },
      expectedRevision: 3,
      payload: { a: 1, b: 2 },
    };

    const fp1 = computeRequestFingerprint(cmd1);
    const fp2 = computeRequestFingerprint(cmd2);

    expect(fp1).toBe(fp2);
    expect(fp1).toHaveLength(64); // SHA-256 hex string
  });

  it('produces different fingerprints when payload values differ', () => {
    const cmd1 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: { a: 1 },
    };
    const cmd2 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: { a: 2 },
    };

    expect(computeRequestFingerprint(cmd1)).not.toBe(computeRequestFingerprint(cmd2));
  });

  it('produces different fingerprints when resource identifiers differ', () => {
    const cmd1 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: {},
    };
    const cmd2 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-2' },
      expectedRevision: 1,
      payload: {},
    };

    expect(computeRequestFingerprint(cmd1)).not.toBe(computeRequestFingerprint(cmd2));
  });

  it('produces different fingerprints when expectedRevision differs', () => {
    const cmd1 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: {},
    };
    const cmd2 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 2,
      payload: {},
    };

    expect(computeRequestFingerprint(cmd1)).not.toBe(computeRequestFingerprint(cmd2));
  });

  it('produces different fingerprints when action differs', () => {
    const cmd1 = {
      action: 'publish_draw',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: {},
    };
    const cmd2 = {
      action: 'create_stage',
      resources: { tournamentId: 'tourn-1' },
      expectedRevision: 1,
      payload: {},
    };

    expect(computeRequestFingerprint(cmd1)).not.toBe(computeRequestFingerprint(cmd2));
  });

  it('Requirement 26: ignores key ordering at any nesting depth while preserving array order', () => {
    const complex1 = {
      payload: {
        a: 1,
        nested: {
          x: 1,
          y: 2,
          deep: { beta: 'two', alpha: 'one' },
        },
      },
    };
    const complex2 = {
      payload: {
        nested: {
          deep: { alpha: 'one', beta: 'two' },
          y: 2,
          x: 1,
        },
        a: 1,
      },
    };

    expect(canonicalJsonStringify(complex1)).toBe(canonicalJsonStringify(complex2));
  });

  it('Requirement 27: correctly handles null, booleans, finite numbers, strings, arrays', () => {
    const valid = {
      n: null,
      b1: true,
      b2: false,
      num: 123.456,
      str: 'hello',
      arr: [1, 'two', null, false],
    };
    expect(() => canonicalJsonStringify(valid)).not.toThrow();
  });

  it('Requirement 27: rejects unsupported non-JSON values (undefined, BigInt, Date, function, NaN, Infinity)', () => {
    expect(() => canonicalJsonStringify({ val: undefined })).toThrow(/undefined/i);
    expect(() => canonicalJsonStringify({ val: 10n })).toThrow(/BigInt/i);
    expect(() => canonicalJsonStringify({ val: new Date() })).toThrow(/Date/i);
    expect(() => canonicalJsonStringify({ val: () => {} })).toThrow(/function/i);
    expect(() => canonicalJsonStringify({ val: Number.NaN })).toThrow(/Non-finite/i);
    expect(() => canonicalJsonStringify({ val: Number.POSITIVE_INFINITY })).toThrow(/Non-finite/i);
  });
});
