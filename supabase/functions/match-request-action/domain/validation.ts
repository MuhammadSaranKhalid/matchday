// Parsing and validation for match-request-action envelopes.
//
// Rules:
//   - Outer envelope must be a non-null, non-array object with a valid action.
//   - body must be a non-null, non-array object.
//   - Optional empty strings are normalised to null.
//   - UUID format: RFC 4122 lower-/upper-case hex.
//   - Timestamps: validated via Date.parse (RFC-compatible).
//   - XI arrays: all items must be valid UUIDs.
//   - Keeper must appear inside the picked XI when XI is non-empty.
//   - format must be a plain object when present.

import { badRequest } from "./errors.ts";
import type {
  AcceptChallengeInput,
  AcceptPoolApplicationInput,
  Action,
  RequestEnvelope,
} from "../types.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const ACTIONS = new Set<Action>([
  "accept_challenge",
  "accept_pool_application",
]);

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isValidUuid(value: string): boolean {
  return UUID_RE.test(value);
}

function optStr(
  body: Record<string, unknown>,
  key: string,
): string | null {
  const v = body[key];
  if (v == null) return null;
  if (typeof v !== "string") badRequest(`${key} must be a string`);
  const trimmed = (v as string).trim();
  return trimmed === "" ? null : trimmed;
}

function reqUuid(
  body: Record<string, unknown>,
  key: string,
): string {
  const v = body[key];
  if (v == null || (typeof v === "string" && (v as string).trim() === "")) {
    badRequest(`${key} is required`);
  }
  if (typeof v !== "string") badRequest(`${key} must be a string`);
  const trimmed = (v as string).trim();
  if (!isValidUuid(trimmed)) badRequest(`${key} must be a valid UUID`);
  return trimmed;
}

function optUuid(
  body: Record<string, unknown>,
  key: string,
): string | null {
  const v = optStr(body, key);
  if (v == null) return null;
  if (!isValidUuid(v)) badRequest(`${key} must be a valid UUID`);
  return v;
}

function optTimestamp(
  body: Record<string, unknown>,
  key: string,
): string | null {
  const v = optStr(body, key);
  if (v == null) return null;
  if (Number.isNaN(Date.parse(v))) {
    badRequest(`${key} must be a valid ISO timestamp`);
  }
  return v;
}

function optUuidArray(
  body: Record<string, unknown>,
  key: string,
): string[] {
  const v = body[key];
  if (v == null) return [];
  if (!Array.isArray(v)) badRequest(`${key} must be an array`);
  const arr = v as unknown[];
  for (const item of arr) {
    if (typeof item !== "string" || !isValidUuid(item)) {
      badRequest(`${key} items must be valid UUIDs`);
    }
  }
  return arr as string[];
}

function optObject(
  body: Record<string, unknown>,
  key: string,
): Record<string, unknown> | null {
  const v = body[key];
  if (v == null) return null;
  if (typeof v !== "object" || Array.isArray(v)) {
    badRequest(`${key} must be a JSON object`);
  }
  return v as Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Envelope parser
// ---------------------------------------------------------------------------

export function parseEnvelope(raw: unknown): RequestEnvelope {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    badRequest("Request body must be a JSON object");
  }

  const outer = raw as Record<string, unknown>;
  const action = outer.action;

  if (typeof action !== "string" || !ACTIONS.has(action as Action)) {
    badRequest(`Unsupported action: ${String(action)}`);
  }

  const body = outer.body;
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    badRequest("Envelope body must be an object");
  }

  return {
    action: action as Action,
    body: body as Record<string, unknown>,
  };
}

// ---------------------------------------------------------------------------
// accept_challenge
// ---------------------------------------------------------------------------

export function parseAcceptChallenge(
  body: Record<string, unknown>,
): AcceptChallengeInput {
  const requestId = reqUuid(body, "request_id");
  const scheduledStartTime = optTimestamp(body, "scheduled_start_time");
  const venue = optStr(body, "venue");
  const format = optObject(body, "format");
  const decisionNote = optStr(body, "decision_note");
  const toTeamId = optUuid(body, "to_team_id");
  const toTeamXi = optUuidArray(body, "to_team_xi");
  const toTeamKeeperId = optUuid(body, "to_team_keeper_id");

  // If a non-empty XI is provided, the keeper (if specified) must be in it.
  if (
    toTeamKeeperId != null &&
    toTeamXi.length > 0 &&
    !toTeamXi.includes(toTeamKeeperId)
  ) {
    badRequest("Wicket-keeper must be part of the picked XI");
  }

  return {
    requestId,
    scheduledStartTime,
    venue,
    format,
    decisionNote,
    toTeamId,
    toTeamXi,
    toTeamKeeperId,
  };
}

// ---------------------------------------------------------------------------
// accept_pool_application
// ---------------------------------------------------------------------------

export function parseAcceptPoolApplication(
  body: Record<string, unknown>,
): AcceptPoolApplicationInput {
  const applicationId = reqUuid(body, "application_id");
  const decisionNote = optStr(body, "decision_note");

  return {
    applicationId,
    decisionNote,
  };
}
