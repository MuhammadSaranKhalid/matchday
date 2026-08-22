// list-my-matches — returns ONLY the matches the caller participates in.
//
// WHY THIS EXISTS
//   The `matches` table is world-readable at the RLS layer
//   (`matches_read_public USING (true)` — intentional, so spectators can browse
//   any match). An unfiltered `from('matches').select()` therefore returns the
//   ENTIRE table, which leaked strangers' matches into every user's "my matches"
//   list. Scoping has to be explicit; this function is that scope.
//
//   A match is "mine" when:
//     • I created it (matches.created_by), OR
//     • a team I'm a member of is playing (team_members.user_id ↔ team_a/team_b), OR
//     • a team I own / manage is playing (teams.owner_id / teams.managers ↔
//       team_a/team_b), OR
//     • I'm an assigned match official (match_officials.user_id).
//
//   The owner/manager clause is load-bearing: a team's owner/manager is recorded
//   in `teams.owner_id` / `teams.managers`, NOT necessarily as a `team_members`
//   row (creating a team does not enrol the creator in the roster). A friendly's
//   match row is created by the ACCEPTING manager (matches.created_by = the
//   accepter), so without this clause the REQUESTING manager — who is neither
//   created_by nor a team_member — never saw the accepted match, even though
//   their team is team_a. (They still got the "request accepted" notification,
//   which is keyed off match_requests.requested_by, hence the mismatch.)
//
// DEV-PHASE CHOICE
//   The scope lives in an edge function rather than a Postgres RPC so it can be
//   iterated/redeployed without DB migrations while the schema is still
//   churning. Promote to a SQL function / view (the cleaner long-term home) once
//   the schema settles.
//
// WEB / CORS
//   The app now also runs on web, so browser calls trigger a CORS preflight —
//   hence the OPTIONS handler and CORS headers on every response.
//
// Responses:
//   200 { matches: [...] }                  — the caller's scoped matches, newest first
//   401 { ok:false, error:{code,message} }  — not signed in / invalid session
//   500 { ok:false, error:{code,message} }  — query failed

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import { createClient } from "npm:@supabase/supabase-js@2";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import postgres from "npm:postgres@3.4.5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });
}

// Pooled direct Postgres connection (Supavisor transaction pooler in the edge
// runtime). Same settings as _shared/db.ts; inlined to keep this function
// self-contained for one-shot deploys. `prepare:false` is required in
// transaction-pooler mode.
let _sql: ReturnType<typeof postgres> | null = null;
function db() {
  if (_sql) return _sql;
  const url = Deno.env.get("MATCH_DB_URL") ?? Deno.env.get("SUPABASE_DB_URL")!;
  _sql = postgres(url, {
    prepare: false,
    max: 3,
    idle_timeout: 20,
    max_lifetime: 60 * 30,
    connect_timeout: 10,
  });
  addEventListener("beforeunload", () => {
    _sql?.end({ timeout: 5 });
  });
  return _sql;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }

  // Identify the caller from their (gateway-verified) JWT.
  const asUser = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await asUser.auth.getUser();
  const actor = userData?.user?.id;
  if (userErr || !actor) {
    return reply(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Invalid session" },
    });
  }

  // Participant scope. Returns full `matches` rows (m.*) so the Flutter
  // MatchDto.fromJson maps them exactly like the old direct select did.
  try {
    const sql = db();
    const rows = await sql`
      select m.*
        from matches m
       where m.created_by = ${actor}
          or m.team_a_captain = ${actor}
          or m.team_b_captain = ${actor}
          or exists (
            select 1 from team_members tm
             where tm.team_id in (m.team_a_id, m.team_b_id)
               and tm.user_id = ${actor}
          )
          or exists (
            select 1 from teams t
             where t.team_id in (m.team_a_id, m.team_b_id)
               and (t.owner_id = ${actor} or ${actor} = any(t.managers))
          )
          or exists (
            select 1 from match_players mp
             where mp.match_id = m.match_id
               and mp.user_id = ${actor}
          )
       order by m.created_at desc`;
    return reply(200, { matches: rows });
  } catch (e) {
    console.error("list-my-matches failed:", e);
    return reply(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});
