// link-preview — server-rendered landing pages for shared matchday links.
//
// WHY THIS EXISTS
//   The app shares links to joinmatchday.com (profile_view.dart, team_share.dart,
//   tournament_published_screen.dart) and NOTHING serves that host. A link
//   pasted into WhatsApp today shows no title, no image, no description, and
//   tapping it lands on nothing. CLAUDE.md §17 lists the App/Universal Link
//   plumbing as done in-repo but the hosting as an outstanding external step —
//   this is that step.
//
//   It has to be an edge function, not an RPC: link unfurlers (WhatsApp,
//   iMessage, Slack, X, Facebook) issue a plain unauthenticated GET and do NOT
//   run JavaScript. They need HTML with Open Graph tags in the response body.
//   That is a public HTTP endpoint returning generated markup — the documented
//   Edge Function use case.
//
// WHAT IT SERVES
//   GET /u/<username>   → profile preview
//   GET /t/<uuid>       → team OR tournament (see the disambiguation note)
//   GET /c/<uuid>       → tournament (the intended prefix; see below)
//   GET /m/<uuid>       → match preview, with the live score when there is one
//   GET /.well-known/assetlinks.json             → Android App Links
//   GET /.well-known/apple-app-site-association  → iOS Universal Links
//
// THE /t/ COLLISION (found 2026-09-06)
//   team_share.dart documents the intended scheme as "/u/ user, /t/ team,
//   /c/ competition", and shares teams at /t/<team_id>. But
//   tournament_published_screen.dart ALSO shares at /t/<tournament_id>, and
//   app_router.dart maps every /t/:id to /tournaments/:id — so a shared TEAM
//   link opens the app on a tournament route that cannot resolve.
//
//   Rather than break links already in circulation, /t/<uuid> is resolved by
//   looking the id up in teams first, then tournaments. Both old links keep
//   working. /c/<uuid> is the going-forward tournament prefix and the router
//   now honours both.
//
// AUTH
//   verify_jwt = false. Unfurlers send no Authorization header, and every row
//   this reads is public at the RLS layer (profiles_read_public,
//   teams_read_public, tournaments_read_visible, matches_read_all). It uses the
//   ANON key deliberately — never the service role — so RLS is the access
//   control and a private tournament cannot leak through a preview.
//
// Responses are always HTML (or JSON for /.well-known), never the {ok,error}
// envelope the JSON functions use: the caller here is a crawler or a browser.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

// Public site identity. Overridable per-environment via secrets so staging
// previews do not claim to be the production brand.
const SITE = Deno.env.get("PUBLIC_SITE_URL") ?? "https://joinmatchday.com";
const BRAND = "matchday";
const DEFAULT_IMAGE = `${SITE}/og-default.png`;
const PLAY_URL = Deno.env.get("PLAY_STORE_URL") ??
  "https://play.google.com/store/apps/details?id=com.matchday.app";
const APP_STORE_URL = Deno.env.get("APP_STORE_URL") ?? "";

// Native app identity, for the association files below.
const ANDROID_PACKAGE = Deno.env.get("ANDROID_PACKAGE") ?? "com.matchday.app";
const ANDROID_SHA256 = Deno.env.get("ANDROID_CERT_SHA256") ?? "";
const APPLE_TEAM_ID = Deno.env.get("APPLE_TEAM_ID") ?? "";
const APPLE_BUNDLE_ID = Deno.env.get("APPLE_BUNDLE_ID") ?? "com.matchday.app";

const anon = () =>
  createClient(SUPABASE_URL, ANON_KEY, { auth: { persistSession: false } });

// ─── HTML helpers ────────────────────────────────────────────────────────────

/** Escape for interpolation into HTML text and double-quoted attributes. */
function esc(s: unknown): string {
  return String(s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function html(status: number, body: string, cacheSeconds: number): Response {
  return new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      // Unfurlers hammer these and the underlying rows change slowly.
      // s-maxage lets a CDN serve the crawler without touching Postgres.
      "cache-control": `public, max-age=60, s-maxage=${cacheSeconds}`,
      "x-content-type-options": "nosniff",
    },
  });
}

interface Preview {
  title: string;
  description: string;
  image: string;
  /** In-app path the deep link should resolve to. */
  path: string;
  /** og:type — "profile" for people, "website" for everything else. */
  ogType?: string;
}

/**
 * The landing page. Carries the OG/Twitter tags the unfurler reads, and for a
 * human visitor an immediate attempt to open the app followed by a store link.
 *
 * The redirect is NOT server-side (302): a 302 would send the crawler away
 * before it read the tags, and the unfurl would be blank. The page must render
 * for the crawler and only then move a real browser along.
 */
function page(p: Preview): string {
  const url = `${SITE}${p.path}`;
  const deepLink = `matchday:/${p.path}`;
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(p.title)} · ${BRAND}</title>
<meta name="description" content="${esc(p.description)}">

<meta property="og:site_name" content="${BRAND}">
<meta property="og:type" content="${esc(p.ogType ?? "website")}">
<meta property="og:url" content="${esc(url)}">
<meta property="og:title" content="${esc(p.title)}">
<meta property="og:description" content="${esc(p.description)}">
<meta property="og:image" content="${esc(p.image)}">
<meta property="og:image:alt" content="${esc(p.title)}">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(p.title)}">
<meta name="twitter:description" content="${esc(p.description)}">
<meta name="twitter:image" content="${esc(p.image)}">

<link rel="canonical" href="${esc(url)}">
<style>
  :root { color-scheme: light dark; }
  body { margin:0; min-height:100dvh; display:grid; place-items:center;
         font:16px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif;
         background:#0f1115; color:#f3f4f6; text-align:center; padding:24px; }
  .card { max-width:420px; }
  img.hero { width:96px; height:96px; border-radius:50%; object-fit:cover;
             background:#1f2430; }
  h1 { font-size:1.35rem; margin:16px 0 4px; }
  p  { color:#9aa3b2; margin:0 0 24px; }
  a.cta { display:inline-block; padding:12px 22px; border-radius:999px;
          background:#22c55e; color:#06210f; font-weight:600;
          text-decoration:none; }
  a.alt { display:block; margin-top:14px; color:#9aa3b2; font-size:.9rem; }
</style>
</head>
<body>
  <div class="card">
    <img class="hero" src="${esc(p.image)}" alt="">
    <h1>${esc(p.title)}</h1>
    <p>${esc(p.description)}</p>
    <a class="cta" href="${esc(deepLink)}">Open in ${BRAND}</a>
    ${PLAY_URL ? `<a class="alt" href="${esc(PLAY_URL)}">Get it on Google Play</a>` : ""}
    ${APP_STORE_URL ? `<a class="alt" href="${esc(APP_STORE_URL)}">Download on the App Store</a>` : ""}
  </div>
  <script>
    // Only a real browser reaches this; crawlers do not execute scripts, so the
    // tags above are already read by the time anything here runs.
    setTimeout(function () { location.href = ${JSON.stringify(deepLink)}; }, 50);
  </script>
</body>
</html>`;
}

function notFound(what: string): Response {
  return html(
    404,
    page({
      title: `${what} not found`,
      description: `This ${what.toLowerCase()} link is no longer valid.`,
      image: DEFAULT_IMAGE,
      path: "/",
    }),
    60,
  );
}

// ─── Resolvers ───────────────────────────────────────────────────────────────

async function profilePreview(username: string): Promise<Preview | null> {
  const { data } = await anon()
    .from("profiles")
    .select("username, display_name, profile_photo_url, bio, account_status")
    .eq("username", username.toLowerCase())
    .eq("account_status", "active")
    .maybeSingle();
  if (!data) return null;
  return {
    title: data.display_name ?? `@${data.username}`,
    description: data.bio?.trim()
      ? data.bio
      : `@${data.username} plays cricket on ${BRAND}.`,
    image: data.profile_photo_url ?? DEFAULT_IMAGE,
    path: `/u/${data.username}`,
    ogType: "profile",
  };
}

async function teamPreview(teamId: string): Promise<Preview | null> {
  const { data } = await anon()
    .from("teams")
    .select("team_id, team_name, team_type, logo_url, location, status")
    .eq("team_id", teamId)
    .maybeSingle();
  if (!data || data.status !== "active") return null;
  const city = (data.location as Record<string, unknown> | null)?.city;
  return {
    title: data.team_name,
    description: city
      ? `${data.team_type ?? "Cricket"} team from ${city}. Follow them on ${BRAND}.`
      : `Follow ${data.team_name} on ${BRAND}.`,
    image: data.logo_url ?? DEFAULT_IMAGE,
    path: `/t/${data.team_id}`,
  };
}

async function tournamentPreview(id: string): Promise<Preview | null> {
  const { data } = await anon()
    .from("tournaments")
    .select(
      "tournament_id, tournament_name, tournament_type, banner_image_url, logo_url, location, status, privacy",
    )
    .eq("tournament_id", id)
    .maybeSingle();
  // `tournaments_read_visible` already hides private cups from anon, but be
  // explicit rather than relying on the policy staying that shape.
  if (!data || data.privacy !== "public") return null;
  const city = (data.location as Record<string, unknown> | null)?.city;
  return {
    title: data.tournament_name,
    description: [
      data.tournament_type ? String(data.tournament_type).replace(/_/g, " ") : null,
      city ? `in ${city}` : null,
      data.status ? `· ${data.status}` : null,
    ].filter(Boolean).join(" ") || `A cricket tournament on ${BRAND}.`,
    image: data.banner_image_url ?? data.logo_url ?? DEFAULT_IMAGE,
    path: `/c/${data.tournament_id}`,
  };
}

async function matchPreview(matchId: string): Promise<Preview | null> {
  const sb = anon();
  const { data: m } = await sb
    .from("matches")
    .select(
      "match_id, status, match_format, venue, scheduled_start_time, team_a_id, team_b_id, result",
    )
    .eq("match_id", matchId)
    .maybeSingle();
  if (!m) return null;

  const ids = [m.team_a_id, m.team_b_id].filter(Boolean) as string[];
  const { data: teams } = ids.length
    ? await sb.from("teams").select("team_id, team_name, logo_url").in("team_id", ids)
    : { data: [] as { team_id: string; team_name: string; logo_url: string | null }[] };
  const nameOf = (id: string | null) =>
    teams?.find((t) => t.team_id === id)?.team_name ?? "TBC";
  const title = `${nameOf(m.team_a_id)} vs ${nameOf(m.team_b_id)}`;

  // A completed match leads with its result; a live one with its score; an
  // upcoming one with when and where.
  let description: string;
  const summary = (m.result as Record<string, unknown> | null)?.summary;
  if (summary) {
    description = String(summary);
  } else if (m.status === "live" || m.status === "innings_break") {
    const { data: st } = await sb
      .from("cricket_match_innings_state")
      .select("total_runs, total_wickets, legal_ball_count, innings_number")
      .eq("match_id", matchId)
      .order("innings_number", { ascending: false })
      .limit(1)
      .maybeSingle();
    description = st
      ? `Live — ${st.total_runs}/${st.total_wickets} (${Math.floor((st.legal_ball_count ?? 0) / 6)}.${(st.legal_ball_count ?? 0) % 6} ov)`
      : "Live now on matchday.";
  } else {
    const when = m.scheduled_start_time
      ? new Date(m.scheduled_start_time as string).toUTCString().slice(0, 16)
      : null;
    description = [when, m.venue].filter(Boolean).join(" · ") ||
      `A ${m.match_format ?? "cricket"} match on ${BRAND}.`;
  }

  return {
    title,
    description,
    image: teams?.find((t) => t.logo_url)?.logo_url ?? DEFAULT_IMAGE,
    path: `/matches/${m.match_id}`,
  };
}

// ─── Association files ───────────────────────────────────────────────────────
// Served from here so the App/Universal Link verification CLAUDE.md §17 lists
// as an outstanding external step can be completed without standing up a
// separate web host. Both must be reachable at the apex domain, so the domain's
// /.well-known/* has to route to this function.

function assetLinks(): Response {
  const body = ANDROID_SHA256
    ? JSON.stringify([{
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: ANDROID_PACKAGE,
        sha256_cert_fingerprints: ANDROID_SHA256.split(",").map((s) => s.trim()),
      },
    }])
    : JSON.stringify([]);
  return new Response(body, {
    status: ANDROID_SHA256 ? 200 : 503,
    headers: { "content-type": "application/json", "cache-control": "public, max-age=300" },
  });
}

function appleAppSiteAssociation(): Response {
  const appId = APPLE_TEAM_ID ? `${APPLE_TEAM_ID}.${APPLE_BUNDLE_ID}` : null;
  const body = appId
    ? JSON.stringify({
      applinks: {
        details: [{ appIDs: [appId], components: [{ "/": "/u/*" }, { "/": "/t/*" }, { "/": "/c/*" }, { "/": "/m/*" }] }],
      },
    })
    : JSON.stringify({});
  // MUST be application/json and have no file extension (Apple rejects
  // otherwise). 503 while unconfigured so a misconfiguration is loud rather
  // than silently serving an empty association.
  return new Response(body, {
    status: appId ? 200 : 503,
    headers: { "content-type": "application/json", "cache-control": "public, max-age=300" },
  });
}

// ─── Handler ─────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // No corsPreflight() here, unlike the JSON functions: this endpoint is
  // consumed by crawlers and top-level browser navigations, not by fetch() from
  // the app, so there is no preflight to answer and no CORS header to add.
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response("Method not allowed", { status: 405 });
  }

  const url = new URL(req.url);
  // Strip the function mount prefix. This has to tolerate all three shapes the
  // path arrives in: the edge runtime hands the handler `/link-preview/u/x`
  // (it has already eaten `/functions/v1`), a direct call to the deployed URL
  // gives `/functions/v1/link-preview/u/x`, and a domain rewrite gives plain
  // `/u/x`. Stripping only the longest form silently produced the fallback
  // brand card for every request when served locally.
  const path = url.pathname
    .replace(/^\/functions\/v1/, "")
    .replace(/^\/link-preview/, "") || "/";
  const seg = path.split("/").filter(Boolean);

  try {
    if (path === "/.well-known/assetlinks.json") return assetLinks();
    if (path === "/.well-known/apple-app-site-association") {
      return appleAppSiteAssociation();
    }

    if (seg.length === 2) {
      const [kind, id] = seg;
      if (kind === "u") {
        const p = await profilePreview(id);
        return p ? html(200, page(p), 300) : notFound("Profile");
      }
      if (kind === "c") {
        const p = await tournamentPreview(id);
        return p ? html(200, page(p), 300) : notFound("Tournament");
      }
      if (kind === "m") {
        const p = await matchPreview(id);
        // Live scores go stale fast; a completed match does not.
        return p ? html(200, page(p), p.description.startsWith("Live") ? 15 : 300) : notFound("Match");
      }
      if (kind === "t") {
        // The collision documented at the top: try team, then tournament, so
        // every link already shared under /t/ keeps resolving.
        const t = await teamPreview(id);
        if (t) return html(200, page(t), 300);
        const c = await tournamentPreview(id);
        return c ? html(200, page(c), 300) : notFound("Page");
      }
    }

    // Anything else (including "/") gets the brand card rather than a bare 404,
    // so a mistyped or truncated forwarded link still says what this is.
    return html(
      200,
      page({
        title: BRAND,
        description: "Cricket, organised. Teams, tournaments and ball-by-ball scoring.",
        image: DEFAULT_IMAGE,
        path: "/",
      }),
      300,
    );
  } catch (e) {
    console.error("link-preview failed:", e);
    // Still return a valid page: a 500 in an unfurler shows a broken link, and
    // the brand card is a better failure than nothing.
    return html(
      500,
      page({
        title: BRAND,
        description: "Cricket, organised.",
        image: DEFAULT_IMAGE,
        path: "/",
      }),
      0,
    );
  }
});
