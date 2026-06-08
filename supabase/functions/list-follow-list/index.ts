// list-follow-list — return a user's followers OR following list, with
// the caller's relationship to each listed person attached (used by the
// followers screen to render the FOLLOWS YOU tag and the tri-state
// Follow / Follow back / Following button).
//
// WHY THIS EXISTS
//   The follows table doesn't have a FK from target_id → profiles
//   (target_id is polymorphic across users/teams/tournaments), so a
//   plain PostgREST embed can't join the "following" direction. Both
//   directions also need TWO EXISTS subqueries per row — the caller's
//   relationship in each direction — which the SDK can't express
//   cleanly. One Postgres query nails all of that.
//
// DEV-PHASE CHOICE
//   Edge function not SQL RPC, per the dev-phase preference (same
//   posture as list-my-chats / list-my-matches / record-ball). Promote
//   to RPC once the shape settles.
//
// RLS NOTE
//   The function uses a direct DB connection (postgres lib), bypassing
//   RLS. Read-side authorization is enforced by the `follows` table's
//   `follows_read_public` policy (all follower lists are public in
//   v1); the function additionally parameterises every query on the
//   verified `actor` from the JWT so the caller's-relationship flags
//   are always computed against the right user. v1.2 will need a
//   privacy gate here once private accounts land.
//
// Response shapes:
//   200 { entries: [{user_id, display_name, username, avatar_url,
//                    you_follow, they_follow_you}] }
//   401 { ok:false, error:{code,message} }   — not signed in
//   400 { ok:false, error:{code,message} }   — bad body / direction
//   500 { ok:false, error:{code,message} }   — query failed

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — `npm:` specifier resolved by Deno at deploy time.
import { createClient } from "npm:@supabase/supabase-js@2";
// @ts-ignore — `npm:` specifier resolved by Deno at deploy time.
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

// Pooled direct Postgres connection (Supavisor transaction pooler in the
// edge runtime). Matches list-my-chats. `prepare:false` is required in
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

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return reply(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }

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

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return reply(400, {
      ok: false,
      error: { code: "bad_request", message: "Body must be JSON" },
    });
  }
  const payload = body as Record<string, unknown> | null;
  const userId = payload?.["user_id"];
  const direction = payload?.["direction"];
  const limit = Math.max(1, Math.min(Number(payload?.["limit"] ?? 100), 500));
  const offset = Math.max(0, Number(payload?.["offset"] ?? 0));

  if (typeof userId !== "string" || !UUID_RE.test(userId)) {
    return reply(400, {
      ok: false,
      error: { code: "bad_request", message: "user_id must be a UUID" },
    });
  }
  if (direction !== "followers" && direction !== "following") {
    return reply(400, {
      ok: false,
      error: {
        code: "bad_request",
        message: "direction must be 'followers' or 'following'",
      },
    });
  }

  try {
    const sql = db();
    let rows;
    if (direction === "followers") {
      // People who follow user_id. The listed person is the follower;
      // their relationship to the actor is computed via two EXISTS
      // subqueries.
      rows = await sql`
        select
          f.follower_id as user_id,
          p.display_name,
          p.username,
          p.profile_photo_url as avatar_url,
          exists (
            select 1 from public.follows
             where follower_id = ${actor}::uuid
               and target_type = 'user'
               and target_id = f.follower_id
          ) as you_follow,
          exists (
            select 1 from public.follows
             where follower_id = f.follower_id
               and target_type = 'user'
               and target_id = ${actor}::uuid
          ) as they_follow_you
        from public.follows f
        join public.profiles p on p.user_id = f.follower_id
        where f.target_type = 'user'
          and f.target_id   = ${userId}::uuid
        order by f.created_at desc
        limit ${limit} offset ${offset}`;
    } else {
      // People user_id follows. The listed person is the target.
      rows = await sql`
        select
          f.target_id as user_id,
          p.display_name,
          p.username,
          p.profile_photo_url as avatar_url,
          exists (
            select 1 from public.follows
             where follower_id = ${actor}::uuid
               and target_type = 'user'
               and target_id = f.target_id
          ) as you_follow,
          exists (
            select 1 from public.follows
             where follower_id = f.target_id
               and target_type = 'user'
               and target_id = ${actor}::uuid
          ) as they_follow_you
        from public.follows f
        join public.profiles p on p.user_id = f.target_id
        where f.follower_id = ${userId}::uuid
          and f.target_type = 'user'
        order by f.created_at desc
        limit ${limit} offset ${offset}`;
    }
    return reply(200, { entries: rows });
  } catch (e) {
    console.error("list-follow-list failed:", e);
    return reply(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});
