// search-teams — Team search & discovery.
//
// In V1, teams do not store location coordinates or cities.
// Discovery is based on name search (trigram & word_similarity) and status/privacy filters.
// Proximity and location-based discovery will be introduced in V2.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json, corsPreflight } from "../_shared/http.ts";

const HARD_LIMIT = 50;
const MIN_QUERY_LEN = 2;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflight();

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Missing bearer token" },
    });
  }
  const asUser = userClient(authHeader);
  const { data: userData, error: userErr } = await asUser.auth.getUser();
  const actor = userData?.user?.id;
  if (userErr || !actor) {
    return json(401, {
      ok: false,
      error: { code: "unauthenticated", message: "Invalid session" },
    });
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch (_) {
    // Empty body = browse mode. Allowed.
  }

  const qRaw = typeof body.q === "string" ? (body.q as string).trim() : "";
  const q: string | null = qRaw.length >= MIN_QUERY_LEN ? qRaw : null;
  const limit = Math.min(
    HARD_LIMIT,
    Math.max(1, typeof body.limit === "number" ? (body.limit as number) : HARD_LIMIT),
  );

  const sql = db();

  try {
    const results = await sql`
      select
        t.team_id,
        t.team_name,
        t.logo_url,
        t.logo_monogram,
        t.team_colors,
        null::jsonb as location,
        t.is_verified,
        t.created_at,
        t.updated_at,
        null::float8 as distance_km,
        case
          when ${q}::text is not null then
            coalesce(word_similarity(${q}::text, t.search_name), 0)::float8
          else 0::float8
        end as score
      from public.teams t
      where t.status = 'active'
        and t.privacy = 'public'
        and case
              when ${q}::text is not null then
                (t.search_name like ${q} || '%' or ${q} <% t.search_name)
              else true
            end
      order by score desc, t.is_verified desc, t.updated_at desc, t.team_id asc
      limit ${limit}`;

    return json(200, { results });
  } catch (e) {
    console.error("search-teams failed:", e);
    return json(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});
