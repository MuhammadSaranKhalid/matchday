/**
 * Canonical command result normalizer for the Tournament command pipeline.
 *
 * PURPOSE
 * -------
 * Guarantees that the value returned to the caller on first execution is
 * **semantically identical** to the value replayed from the receipt on
 * subsequent retries:
 *
 *   first  response.result === JSON.parse(JSON.stringify(canonicalResult))
 *   replay response.result === JSON.parse(JSON.stringify(canonicalResult))
 *
 * ALLOWED VALUE SPACE
 * -------------------
 *   null
 *   boolean
 *   finite number (NaN and ±Infinity are rejected)
 *   string
 *   array of JsonValue
 *   plain object (prototype === Object.prototype or null) with JsonValue values
 *
 * REJECTED VALUE SPACE (throws Error — internal programming contract violation)
 *   undefined          — top-level or nested; cannot survive JSON round-trip
 *   BigInt             — not JSON-serializable
 *   function / symbol  — not JSON-serializable
 *   NaN / ±Infinity    — not JSON-serializable
 *   Date               — handlers must use toISOString() explicitly
 *   Map / Set          — non-plain objects; lose identity through JSON
 *   class instances    — non-plain objects with prototype !== Object.prototype
 *   RegExp             — non-plain object
 *   typed arrays       — non-plain object
 *   circular graphs    — would cause JSON.stringify to throw
 *
 * ALLOWED: shared (non-circular) object references
 *   const child = { value: 1 };
 *   normalizeCommandResult({ a: child, b: child }); // OK — not circular
 *
 * CYCLE DETECTION
 * ---------------
 * Uses a recursion-STACK (Set) rather than a WeakSet accumulator.
 * Objects are added to the stack before descending and removed afterward.
 * This means a value that appears in two separate branches of the object
 * graph (shared reference) is not falsely reported as circular; only a
 * genuine ancestor-to-descendant back-edge triggers rejection.
 *
 * NORMALIZATION
 * -------------
 * The function returns the canonical value as a `JsonValue`.
 * For plain objects it produces a new object with keys sorted
 * deterministically (matching `canonicalJsonStringify` used for fingerprints).
 * This makes the persisted JSON representation stable across JS engines.
 *
 * NOTE: The key-sort normalization aligns with `canonicalJsonStringify` in
 * fingerprint.ts.  Both utilities reject the same non-JSON-domain values.
 * They are intentionally separate because fingerprint serialization produces
 * a canonical JSON string for hashing, while result normalization produces a
 * `JsonValue` for return and storage.
 */

/** Supported JSON-domain value type. */
export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

/**
 * Normalizes a command handler result into a canonical `JsonValue`.
 *
 * Throws an `Error` (not a `TournamentError`) if the value cannot be
 * safely serialized to JSON.  These are **internal programming contract
 * violations** — handlers must return JSON-domain values.
 *
 * @param value  - The raw value returned by a command handler.
 * @param _stack - Recursion stack used internally for cycle detection.
 *                 Callers must not pass this argument.
 */
export function normalizeCommandResult(
  value: unknown,
  _stack: Set<object> = new Set(),
): JsonValue {
  // ── null ──────────────────────────────────────────────────────────────────
  if (value === null) {
    return null;
  }

  // ── undefined ─────────────────────────────────────────────────────────────
  if (value === undefined) {
    throw new Error(
      'Command handler returned undefined; handlers must return an explicit JSON-domain value or null',
    );
  }

  // ── boolean ───────────────────────────────────────────────────────────────
  if (typeof value === 'boolean') {
    return value;
  }

  // ── number ────────────────────────────────────────────────────────────────
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) {
      throw new Error(
        `Command handler result contains non-finite number (${String(value)}); use null or a finite number`,
      );
    }
    return value;
  }

  // ── string ────────────────────────────────────────────────────────────────
  if (typeof value === 'string') {
    return value;
  }

  // ── bigint ────────────────────────────────────────────────────────────────
  if (typeof value === 'bigint') {
    throw new Error(
      'Command handler result contains BigInt; BigInt is not JSON-serializable — use a string or number',
    );
  }

  // ── function / symbol ─────────────────────────────────────────────────────
  if (typeof value === 'function' || typeof value === 'symbol') {
    throw new Error(
      `Command handler result contains ${typeof value}; ${typeof value} is not JSON-serializable`,
    );
  }

  // ── object branch (includes Array, Date, Map, Set, class instances, …) ───
  if (typeof value === 'object') {
    // Cycle detection: is this object an ancestor in the current recursion stack?
    if (_stack.has(value)) {
      throw new Error(
        'Command handler result contains a circular reference; JSON serialization would fail',
      );
    }

    // ── Date ────────────────────────────────────────────────────────────────
    if (value instanceof Date) {
      throw new Error(
        'Command handler result contains a Date object; handlers must return an ISO-8601 string instead of a Date instance',
      );
    }

    // ── Array ───────────────────────────────────────────────────────────────
    if (Array.isArray(value)) {
      _stack.add(value);
      try {
        return value.map((item, index) => {
          if (item === undefined) {
            throw new Error(
              `Command handler result contains undefined at array index ${index}; use null explicitly or omit the element`,
            );
          }
          return normalizeCommandResult(item, _stack);
        });
      } finally {
        _stack.delete(value);
      }
    }

    // ── Plain object check ───────────────────────────────────────────────────
    // Allowed: Object.prototype or null prototype (Object.create(null)).
    // Rejected: any class instance (Map, Set, RegExp, typed arrays, custom classes).
    const proto = Object.getPrototypeOf(value);
    if (proto !== null && proto !== Object.prototype) {
      const name = (value as object).constructor?.name ?? 'unknown';
      throw new Error(
        `Command handler result contains a non-plain object (${name}); only plain objects, arrays, and JSON primitives are allowed`,
      );
    }

    // ── Plain object normalization ───────────────────────────────────────────
    _stack.add(value);
    try {
      const record = value as Record<string, unknown>;
      const sortedKeys = Object.keys(record).sort();
      const normalized: Record<string, JsonValue> = {};

      for (const key of sortedKeys) {
        const val = record[key];
        if (val === undefined) {
          throw new Error(
            `Command handler result contains undefined property '${key}'; use null explicitly or omit the property`,
          );
        }
        normalized[key] = normalizeCommandResult(val, _stack);
      }

      return normalized;
    } finally {
      _stack.delete(value);
    }
  }

  // ── should be unreachable in TypeScript, but be defensive ─────────────────
  throw new Error(
    `Command handler result contains unsupported value type (${typeof value})`,
  );
}
