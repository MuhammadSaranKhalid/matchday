import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { CommandError } from "./errors.ts";
import {
  parseAcceptChallenge,
  parseAcceptPoolApplication,
  parseEnvelope,
} from "./validation.ts";

const ids = {
  request: "90000000-0000-4000-8000-000000000001",
  application: "99000000-0000-4000-8000-000000000001",
  toTeam: "11000000-0000-4000-8000-000000000002",
  player: "15000000-0000-4000-8000-000000000001",
  otherPlayer: "15000000-0000-4000-8000-000000000002",
};

Deno.test("parseEnvelope accepts valid accept_challenge envelope", () => {
  const direct = parseEnvelope({
    action: "accept_challenge",
    body: {
      request_id: ids.request,
      to_team_xi: [ids.player],
    },
  });
  assertEquals(direct.action, "accept_challenge");
  assertEquals(direct.body.request_id, ids.request);
});

Deno.test("parseEnvelope accepts valid accept_pool_application envelope", () => {
  const pool = parseEnvelope({
    action: "accept_pool_application",
    body: {
      application_id: ids.application,
    },
  });
  assertEquals(pool.action, "accept_pool_application");
  assertEquals(pool.body.application_id, ids.application);
});

Deno.test("parseEnvelope rejects non-object raw envelope", () => {
  assertThrows(
    () => parseEnvelope("not an object"),
    CommandError,
    "Request body must be a JSON object",
  );
  assertThrows(
    () => parseEnvelope(null),
    CommandError,
    "Request body must be a JSON object",
  );
  assertThrows(
    () => parseEnvelope([]),
    CommandError,
    "Request body must be a JSON object",
  );
});

Deno.test("parseEnvelope rejects unsupported action", () => {
  assertThrows(
    () => parseEnvelope({ action: "unknown", body: {} }),
    CommandError,
    "Unsupported action",
  );
  assertThrows(
    () => parseEnvelope({ action: 123, body: {} }),
    CommandError,
    "Unsupported action",
  );
});

Deno.test("parseEnvelope rejects non-object body", () => {
  assertThrows(
    () => parseEnvelope({ action: "accept_challenge", body: "invalid" }),
    CommandError,
    "Envelope body must be an object",
  );
  assertThrows(
    () => parseEnvelope({ action: "accept_challenge", body: null }),
    CommandError,
    "Envelope body must be an object",
  );
});

Deno.test("parseAcceptChallenge parses valid payload with normalization", () => {
  const parsed = parseAcceptChallenge({
    request_id: ids.request,
    decision_note: "  Agreed!  ",
    to_team_id: ids.toTeam,
  });

  assertEquals(parsed.requestId, ids.request);
  assertEquals(parsed.decisionNote, "Agreed!");
  assertEquals(parsed.toTeamId, ids.toTeam);
});

Deno.test("parseAcceptChallenge handles optional and empty fields", () => {
  const parsed = parseAcceptChallenge({
    request_id: ids.request,
    decision_note: "",
  });

  assertEquals(parsed.requestId, ids.request);
  assertEquals(parsed.decisionNote, null);
  assertEquals(parsed.toTeamId, null);
});

Deno.test("parseAcceptChallenge rejects non-UUID request_id", () => {
  assertThrows(
    () => parseAcceptChallenge({ request_id: "not-a-uuid" }),
    CommandError,
    "valid UUID",
  );
  assertThrows(
    () => parseAcceptChallenge({}),
    CommandError,
    "request_id is required",
  );
});

Deno.test("parseAcceptChallenge rejects non-UUID to_team_id", () => {
  assertThrows(
    () => parseAcceptChallenge({ request_id: ids.request, to_team_id: "not-a-uuid" }),
    CommandError,
    "valid UUID",
  );
});

Deno.test("parseAcceptPoolApplication parses valid payload", () => {
  const parsed = parseAcceptPoolApplication({
    application_id: ids.application,
    decision_note: "Accepted for weekend",
  });
  assertEquals(parsed.applicationId, ids.application);
  assertEquals(parsed.decisionNote, "Accepted for weekend");
});

Deno.test("parseAcceptPoolApplication rejects missing or invalid application_id", () => {
  assertThrows(
    () => parseAcceptPoolApplication({}),
    CommandError,
    "application_id is required",
  );
  assertThrows(
    () => parseAcceptPoolApplication({ application_id: "invalid" }),
    CommandError,
    "application_id must be a valid UUID",
  );
});
