// list-my-chats — returns the calling user's chat inbox in one round-trip.
//
// WHY THIS EXISTS
//   The chat inbox needs (per row): the chat header, the latest message
//   preview, the unread count for the current user, and the team join for
//   the chat name. PostgREST embedded selects can do the team join + latest
//   message via nested resources, but the unread count is a correlated
//   subquery that the SDK can't express cleanly. Plus we want to compute
//   `last_message_from_me` server-side so the client doesn't re-derive it.
//   One Postgres query nails all of that.
//
// DEV-PHASE CHOICE
//   The shape lives in an edge function rather than an RPC so it can be
//   iterated without DB migrations while the chat layer is still moving
//   (per the dev-phase feedback memory). Promote to a SQL function / view
//   once the inbox shape settles.
//
// RLS NOTE
//   The function uses a direct DB connection (postgres lib), bypassing
//   RLS. Authorization is enforced by parameterising every query on the
//   verified `actor` — the inbox is filtered to chats the caller is an
//   active member of via `chat_members.user_id = actor AND left_at IS
//   NULL`. There's no path here that could leak another user's chats.
//
// Response shapes:
//   200 { chats: [...] }                    — newest first, sort key
//                                             last_message_at desc nulls last
//   401 { ok:false, error:{code,message} }  — not signed in / invalid session
//   500 { ok:false, error:{code,message} }  — query failed

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

// Pooled direct Postgres connection (Supavisor transaction pooler in the edge
// runtime). Inlined to keep this function self-contained, matching the
// list-my-matches pattern. `prepare:false` is required in transaction-pooler
// mode.
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

  try {
    const sql = db();
    // ONE query: chat header + my chat_members (for last_read_at) + team
    // join (for name) + lateral latest non-deleted message + correlated
    // unread count. The lateral subquery scales fine because messages has
    // (chat_id, created_at desc) as an index — getting the top 1 per chat
    // is an index scan.
    const rows = await sql`
      select
        c.chat_id,
        c.type,
        c.team_id,
        c.last_message_at,
        c.created_at,
        c.updated_at,
        t.team_name as team_name,
        t.logo_url as team_logo_url,
        t.logo_monogram as team_logo_monogram,
        (t.team_colors->>'primary') as team_primary_color,
        lm.body as last_message_body,
        lm.sender_id as last_message_sender_id,
        (lm.sender_id is not distinct from ${actor})::boolean as last_message_from_me,
        (
          select count(*)::int from messages m
           where m.chat_id = c.chat_id
             and m.created_at > coalesce(cm.last_read_at, 'epoch'::timestamptz)
             and m.sender_id is distinct from ${actor}
             and m.deleted_at is null
        ) as unread_count
      from chats c
      join chat_members cm
        on cm.chat_id = c.chat_id
       and cm.user_id = ${actor}
       and cm.left_at is null
      left join teams t on t.team_id = c.team_id
      left join lateral (
        select m.body, m.sender_id, m.created_at
          from messages m
         where m.chat_id = c.chat_id
           and m.deleted_at is null
         order by m.created_at desc
         limit 1
      ) lm on true
      order by c.last_message_at desc nulls last`;
    return reply(200, { chats: rows });
  } catch (e) {
    console.error("list-my-chats failed:", e);
    return reply(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});
