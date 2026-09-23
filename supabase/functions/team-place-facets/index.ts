// team-place-facets — top cities by team count, for the search filter chips.
//
// Reads from our own `teams` table — never Google Places. Every chip is a
// city that actually has discoverable teams, so a chip can never lead to an
// empty list. Country defaults from the caller's profile when not provided;
// if the caller has no country either, no country filter is applied (D12).
//
// See docs/search-feature-design.md §13 and §16. Same privacy hard-filter as
// search-teams (status='active' AND privacy='public') — the service role
// bypasses RLS, so the SQL is the access boundary.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json, corsPreflight } from "../_shared/http.ts";

const HARD_LIMIT = 100;

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
    // Empty body = use caller's country (or no filter).
  }

  let countryCode: string | null =
    typeof body.countryCode === "string" ? (body.countryCode as string) : null;

  const sql = db();

  if (countryCode == null) {
    try {
      const rows = await sql`
        select location->>'country_code' as country
          from public.profiles
         where user_id = ${actor}
         limit 1`;
      countryCode = (rows[0]?.country as string | null) ?? null;
    } catch (_) {
      countryCode = null;
    }
  }

  // In V1, teams do not store location coordinates or cities.
  // Location facets are deferred to V2.
  return json(200, { facets: [] });
});
