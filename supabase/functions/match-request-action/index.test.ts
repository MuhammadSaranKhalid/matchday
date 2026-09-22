// Handler unit tests for match-request-action.
//
// The handler is extracted into handleRequest(req, deps) so tests can inject
// fake authentication and command dependencies without opening sockets.

import { assertEquals } from "jsr:@std/assert@1";
import { handleRequest, type HandlerDependencies } from "./index.ts";

// ---------------------------------------------------------------------------
// Fake dependencies
// ---------------------------------------------------------------------------

const ids = {
  actor: "00000000-0000-4000-8000-000000000001",
  match: "13000000-0000-4000-8000-000000000001",
};

function authedDeps(overrides: Partial<HandlerDependencies> = {}): HandlerDependencies {
  return {
    authenticate: async (_req) => ({ actorId: ids.actor }),
    runCommand: async (_action, _actorId, _body) => ({ matchId: ids.match }),
    ...overrides,
  };
}

function unauthDeps(): HandlerDependencies {
  return {
    authenticate: async (_req) => ({
      error: { status: 401, code: "UNAUTHENTICATED", message: "No session" },
    }),
    runCommand: async () => { throw new Error("should not be called"); },
  };
}

function makeRequest(method: string, body?: unknown): Request {
  return new Request("https://example.com/functions/v1/match-request-action", {
    method,
    headers: { "Content-Type": "application/json", "Authorization": "Bearer tok" },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

Deno.test("OPTIONS returns 200 for CORS preflight", async () => {
  const resp = await handleRequest(makeRequest("OPTIONS"), authedDeps());
  assertEquals(resp.status, 200);
});

Deno.test("unauthenticated request returns 401", async () => {
  const req = makeRequest("POST", { action: "accept_challenge", body: {} });
  const resp = await handleRequest(req, unauthDeps());
  const json = await resp.json();

  assertEquals(resp.status, 401);
  assertEquals(json.ok, false);
  assertEquals(json.error.code, "UNAUTHENTICATED");
});

Deno.test("invalid JSON body returns 400", async () => {
  const req = new Request("https://example.com/functions/v1/match-request-action", {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": "Bearer tok" },
    body: "not-json{{{",
  });
  const resp = await handleRequest(req, authedDeps());
  const json = await resp.json();

  assertEquals(resp.status, 400);
  assertEquals(json.ok, false);
  assertEquals(json.error.code, "BAD_REQUEST");
});

Deno.test("unsupported action returns 400", async () => {
  const req = makeRequest("POST", { action: "unknown_action", body: {} });
  const resp = await handleRequest(req, authedDeps());
  const json = await resp.json();

  assertEquals(resp.status, 400);
  assertEquals(json.ok, false);
});

Deno.test("accept_challenge dispatches and returns match_id", async () => {
  const req = makeRequest("POST", {
    action: "accept_challenge",
    body: {
      request_id: "90000000-0000-4000-8000-000000000001",
      to_team_xi: [],
    },
  });
  const resp = await handleRequest(req, authedDeps());
  const json = await resp.json();

  assertEquals(resp.status, 200);
  assertEquals(json.ok, true);
  assertEquals(json.match_id, ids.match);
});

Deno.test("accept_pool_application dispatches and returns match_id", async () => {
  const req = makeRequest("POST", {
    action: "accept_pool_application",
    body: {
      application_id: "99000000-0000-4000-8000-000000000001",
    },
  });
  const resp = await handleRequest(req, authedDeps());
  const json = await resp.json();

  assertEquals(resp.status, 200);
  assertEquals(json.ok, true);
  assertEquals(json.match_id, ids.match);
});

Deno.test("command error is forwarded to HTTP response", async () => {
  const { CommandError } = await import("./domain/errors.ts");

  const deps = authedDeps({
    runCommand: async (_action, _actorId, _body) => {
      throw new CommandError(409, "CONFLICT", "Request already accepted");
    },
  });

  const req = makeRequest("POST", {
    action: "accept_challenge",
    body: {
      request_id: "90000000-0000-4000-8000-000000000001",
      to_team_xi: [],
    },
  });
  const resp = await handleRequest(req, deps);
  const json = await resp.json();

  assertEquals(resp.status, 409);
  assertEquals(json.ok, false);
  assertEquals(json.error.code, "CONFLICT");
});

Deno.test("success without match_id is treated as server failure", async () => {
  const deps = authedDeps({
    // deno-lint-ignore require-await
    runCommand: async () => ({ matchId: "" }),
  });

  const req = makeRequest("POST", {
    action: "accept_challenge",
    body: {
      request_id: "90000000-0000-4000-8000-000000000001",
      to_team_xi: [],
    },
  });
  const resp = await handleRequest(req, deps);
  const json = await resp.json();

  assertEquals(resp.status, 500);
  assertEquals(json.ok, false);
});
