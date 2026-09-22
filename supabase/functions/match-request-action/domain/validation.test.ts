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
    scheduled_start_time: "2026-09-23T10:00:00Z",
    venue: "  National Stadium  ",
    format: { overs: 20 },
    decision_note: "  Agreed!  ",
    to_team_id: ids.toTeam,
    to_team_xi: [ids.player],
    to_team_keeper_id: ids.player,
  });

  assertEquals(parsed.requestId, ids.request);
  assertEquals(parsed.scheduledStartTime, "2026-09-23T10:00:00Z");
  assertEquals(parsed.venue, "National Stadium");
  assertEquals(parsed.format?.overs, 20);
  assertEquals(parsed.decisionNote, "Agreed!");
  assertEquals(parsed.toTeamId, ids.toTeam);
  assertEquals(parsed.toTeamXi, [ids.player]);
  assertEquals(parsed.toTeamKeeperId, ids.player);
});

Deno.test("parseAcceptChallenge handles optional and empty fields", () => {
  const parsed = parseAcceptChallenge({
    request_id: ids.request,
    venue: "   ",
    decision_note: "",
  });

  assertEquals(parsed.requestId, ids.request);
  assertEquals(parsed.scheduledStartTime, null);
  assertEquals(parsed.venue, null);
  assertEquals(parsed.format, null);
  assertEquals(parsed.decisionNote, null);
  assertEquals(parsed.toTeamId, null);
  assertEquals(parsed.toTeamXi, []);
  assertEquals(parsed.toTeamKeeperId, null);
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

Deno.test("parseAcceptChallenge rejects malformed timestamps", () => {
  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        scheduled_start_time: "not-a-date",
      }),
    CommandError,
    "scheduled_start_time must be a valid ISO timestamp",
  );
});

Deno.test("parseAcceptChallenge rejects non-array or invalid XI UUIDs", () => {
  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        to_team_xi: "not an array",
      }),
    CommandError,
    "to_team_xi must be an array",
  );

  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        to_team_xi: ["not-a-uuid"],
      }),
    CommandError,
    "to_team_xi items must be valid UUIDs",
  );
});

Deno.test("parseAcceptChallenge rejects keeper not in picked XI when XI is non-empty", () => {
  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        to_team_xi: [ids.player],
        to_team_keeper_id: ids.otherPlayer,
      }),
    CommandError,
    "Wicket-keeper must be part of the picked XI",
  );
});

Deno.test("parseAcceptChallenge permits keeper if XI is empty", () => {
  const parsed = parseAcceptChallenge({
    request_id: ids.request,
    to_team_xi: [],
    to_team_keeper_id: ids.otherPlayer,
  });
  assertEquals(parsed.toTeamKeeperId, ids.otherPlayer);
});

Deno.test("parseAcceptChallenge rejects malformed format JSON", () => {
  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        format: "not-an-object",
      }),
    CommandError,
    "format must be a JSON object",
  );
  assertThrows(
    () =>
      parseAcceptChallenge({
        request_id: ids.request,
        format: ["array"],
      }),
    CommandError,
    "format must be a JSON object",
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
