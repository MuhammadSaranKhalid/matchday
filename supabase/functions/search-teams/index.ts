// search-teams — Team search & discovery.
//
// Three behavioural modes derived from inputs:
//   q only             → name search (trigram, word_similarity)
//   center only        → near-me browse (ST_DWithin hard radius)
//   q + center         → blended (name predicate, distance boosts ranking)
//   neither            → browse (verified + recent)
//
// Service role bypasses RLS, so this function IS the access control: the SQL
// hard-filters status='active' AND privacy='public' on every path. See
// docs/search-feature-design.md §16.
//
// All user input (q, lat/lng, country, etc.) flows through postgres.js
// tagged-template parameters — there is no string-concat path. The function
// is the only writer of search SQL; never accept a SQL fragment from the
// client.
//
// Top-N cap, no pagination. A blended score cannot be offset-paginated
// coherently (review concern #3). The client refines instead.
//
// City-net fallback (§10.3): when q is present and the primary name-trigram
// query returns fewer than FALLBACK_THRESHOLD hits, run a second query
// matching `location->>'city' ILIKE '%q%'`. Dedupe by team_id; city hits
// always rank below name hits (their score is 0). This is the safety net
// for null-coord teams and for queries that are city names, not team names.
//
// Country defaults from the caller's profile when not provided. If the
// caller has no country either, no country filter is applied (D12).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json, corsPreflight } from "../_shared/http.ts";

const HARD_LIMIT = 50;
const FALLBACK_THRESHOLD = 10;
const DEFAULT_RADIUS_KM = 100;
const DEFAULT_SCALE_KM = 15;
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
  const lat: number | null =
    typeof body.lat === "number" ? (body.lat as number) : null;
  const lng: number | null =
    typeof body.lng === "number" ? (body.lng as number) : null;
  const hasCenter = lat !== null && lng !== null;
  const radiusKm =
    typeof body.radiusKm === "number"
      ? (body.radiusKm as number)
      : DEFAULT_RADIUS_KM;
  const scaleKm =
    typeof body.scaleKm === "number"
      ? (body.scaleKm as number)
      : DEFAULT_SCALE_KM;
  let countryCode: string | null =
    typeof body.countryCode === "string" ? (body.countryCode as string) : null;
  const limit = Math.min(
    HARD_LIMIT,
    Math.max(1, typeof body.limit === "number" ? (body.limit as number) : HARD_LIMIT),
  );
  const radiusM = Math.max(1, Math.round(radiusKm * 1000));

  const sql = db();

  // Country default: caller's profile country. If absent, no country filter.
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

  try {
    // ── Primary path: name-trigram + near-me + blend. ──────────────────────
    // The CTE binds every parameter once and the planner constant-folds the
    // CASE branches per row. Operand order is `q <% search_name` —
    // semantically "q is contained within search_name" — and
    // `word_similarity(q, search_name)` matches it.
    const primary = await sql`
      with q_inputs as (
        select
          ${q}::text                                              as q,
          case when ${hasCenter}
               then st_setsrid(st_makepoint(${lng}::float8, ${lat}::float8), 4326)::geography
               end                                                as center,
          ${scaleKm}::float8                                      as scale_km,
          ${radiusM}::int                                         as radius_m,
          ${countryCode}::text                                    as country
      )
      select
        t.team_id,
        t.team_name,
        t.logo_url,
        t.logo_monogram,
        t.team_colors,
        t.location,
        t.is_verified,
        t.created_at,
        t.updated_at,
        case when qi.center is not null and t.location_point is not null
             then st_distance(t.location_point, qi.center) / 1000.0
        end as distance_km,
        (
          (case when qi.q is not null
                then 0.6 * coalesce(word_similarity(qi.q, t.search_name), 0)
                else 0
           end)
          +
          (case when qi.center is not null and t.location_point is not null
                then 0.4 * (
                  1.0 / (1.0 + (st_distance(t.location_point, qi.center) / 1000.0) / qi.scale_km)
                )
                else 0
           end)
        ) as score
      from public.teams t
      cross join q_inputs qi
      where t.status = 'active'
        and t.privacy = 'public'
        and (qi.country is null or t.location->>'country_code' = qi.country)
        and case
              when qi.q is not null then
                (t.search_name like qi.q || '%' or qi.q <% t.search_name)
              when qi.center is not null then
                (t.location_point is not null
                 and st_dwithin(t.location_point, qi.center, qi.radius_m))
              else true
            end
      order by score desc, t.is_verified desc, t.updated_at desc, t.team_id asc
      limit ${limit}`;

    // ── §10.3 city-net fallback. ───────────────────────────────────────────
    // Only when q is present AND primary was thin. Dedupe in JS over ≤50
    // rows is trivial; merged city hits keep score 0 so name matches stay on
    // top. Country filter is reapplied so a thin primary in PK does not
    // surface IN teams via the city net.
    let results = primary as Array<Record<string, unknown>>;
    if (q != null && results.length < FALLBACK_THRESHOLD) {
      const seen = new Set(results.map((r) => r.team_id));
      const remaining = limit - results.length;
      const cityNet = await sql`
        select
          t.team_id,
          t.team_name,
          t.logo_url,
          t.logo_monogram,
          t.team_colors,
          t.location,
          t.is_verified,
          t.created_at,
          t.updated_at,
          null::float8 as distance_km,
          0::float8 as score
        from public.teams t
        where t.status = 'active'
          and t.privacy = 'public'
          and (${countryCode}::text is null or t.location->>'country_code' = ${countryCode})
          and t.location->>'city' ilike '%' || ${q} || '%'
        order by t.is_verified desc, t.updated_at desc, t.team_id asc
        limit ${Math.max(0, remaining)}`;
      const append: Array<Record<string, unknown>> = [];
      for (const row of cityNet) {
        if (seen.has(row.team_id)) continue;
        append.push(row);
        if (results.length + append.length >= limit) break;
      }
      results = [...results, ...append];
    }

    return json(200, { results });
  } catch (e) {
    console.error("search-teams failed:", e);
    return json(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});
