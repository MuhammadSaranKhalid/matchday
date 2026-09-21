import {
  badRequest,
} from "./errors.ts";
import type {
  Action,
  RequestEnvelope,
} from "../types.ts";

const ACTIONS = new Set<Action>([
  "record_toss",
  "submit_match_openers",
  "start_match_now",
  "cancel_match",
  "start_innings",
  "undo_last_ball",
  "complete_cricket_match",
  "tournament_reschedule_match",
  "tournament_abandon_match",
  "tournament_declare_walkover",
  "tournament_override_result",
  "tournament_revise_match_conditions",
  "tournament_trigger_super_over",
]);

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function parseEnvelope(
  raw: unknown,
): RequestEnvelope {
  if (
    !raw ||
    typeof raw !== "object" ||
    Array.isArray(raw)
  ) {
    badRequest(
      "Request body must be a JSON object",
    );
  }

  const body =
    raw as Record<string, unknown>;

  const action = body.action;

  if (
    typeof action !== "string" ||
    !ACTIONS.has(action as Action)
  ) {
    badRequest(
      `Unsupported action: ${String(action)}`,
    );
  }

  return {
    action: action as Action,
    matchId:
      requiredUuid(body, "p_match_id"),
    body,
  };
}

export function requiredString(
  body: Record<string, unknown>,
  key: string,
): string {
  const value = body[key];

  if (
    typeof value !== "string" ||
    value.trim() === ""
  ) {
    badRequest(`${key} is required`);
  }

  return value.trim();
}

export function optionalString(
  body: Record<string, unknown>,
  key: string,
): string | null {
  const value = body[key];

  if (value == null) return null;

  if (typeof value !== "string") {
    badRequest(
      `${key} must be a string`,
    );
  }

  const trimmed = value.trim();
  return trimmed === ""
    ? null
    : trimmed;
}

export function requiredUuid(
  body: Record<string, unknown>,
  key: string,
): string {
  const value =
    requiredString(body, key);

  if (!UUID_RE.test(value)) {
    badRequest(
      `${key} must be a valid UUID`,
    );
  }

  return value;
}

export function requiredInteger(
  body: Record<string, unknown>,
  key: string,
): number {
  const value = body[key];

  if (!Number.isInteger(value)) {
    badRequest(
      `${key} must be an integer`,
    );
  }

  return value as number;
}

export function optionalInteger(
  body: Record<string, unknown>,
  key: string,
): number | null {
  const value = body[key];

  if (value == null) return null;

  if (!Number.isInteger(value)) {
    badRequest(
      `${key} must be an integer`,
    );
  }

  return value as number;
}

export function requiredEnum<
  T extends string,
>(
  body: Record<string, unknown>,
  key: string,
  allowed: readonly T[],
): T {
  const value =
    requiredString(body, key);

  if (
    !(allowed as readonly string[])
      .includes(value)
  ) {
    badRequest(
      `${key} must be one of: ${allowed.join(", ")}`,
    );
  }

  return value as T;
}

export function requiredTimestamp(
  body: Record<string, unknown>,
  key: string,
): string {
  const value =
    requiredString(body, key);

  if (Number.isNaN(Date.parse(value))) {
    badRequest(
      `${key} must be a valid ISO timestamp`,
    );
  }

  return value;
}

export function optionalTimestamp(
  body: Record<string, unknown>,
  key: string,
): string | null {
  const value =
    optionalString(body, key);

  if (value == null) return null;

  if (Number.isNaN(Date.parse(value))) {
    badRequest(
      `${key} must be a valid ISO timestamp`,
    );
  }

  return value;
}
