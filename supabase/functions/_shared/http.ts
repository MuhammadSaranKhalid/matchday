// Tiny JSON-response helper shared by the match edge functions.
//
// CORS: every match function is now reachable from the web build, so browser
// calls trigger a CORS preflight. Responses MUST carry these headers or the
// browser blocks the body even on a 200. The preflight itself (OPTIONS) is
// answered per-function via `corsPreflight()` BEFORE any auth check — a
// preflight carries no Authorization header, so an auth gate at the top of the
// handler would 401 it (the record-ball bug this fixes).

export const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });
}

/** 200 response for a CORS preflight. Call this first, before auth. */
export function corsPreflight(): Response {
  return new Response("ok", { headers: CORS });
}
