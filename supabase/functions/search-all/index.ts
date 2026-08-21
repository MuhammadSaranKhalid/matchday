// search-all — unified Explore search + browse.
//
// Two modes, selected by whether `q` is present:
//   q present (>=2 chars) → SEARCH:  players + teams + matches, grouped
//   q absent              → BROWSE:  live matches, recent teams, new players
//
// v1 ships WITHOUT geo. No coordinates exist anywhere in the database yet
// (nothing in the client captures them — see docs/explore-feature-design.md),
// so proximity ranking would sort an empty dimension and the near-me
// permission prompt would be spent for nothing. Ranking is pure text
// relevance. When capture lands, add the distance-decay term from
// `search-teams` here; the response shape already carries the fields.
//
// Service role bypasses RLS, so this function IS the access control:
//   teams     → status='active' AND privacy='public'
//   profiles  → account_status='active' AND appear_in_search
//   unclaimed → claimed_by_user_id IS NULL, and NEVER phone_number/email
//   matches   → public read (matches_read_public), tournaments filtered to public
// Each WHERE must stay byte-identical to its partial index predicate or the
// planner drops the index (docs/search-feature-design.md §17).
//
// All user input flows through postgres.js tagged-template parameters. There
// is no string-concat path; never accept a SQL fragment from the client.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { db, userClient } from "../_shared/db.ts";
import { json, corsPreflight } from "../_shared/http.ts";

const MIN_QUERY_LEN = 2;
const PER_GROUP_LIMIT = 20;
const PER_GROUP_HARD_CAP = 50;
const BROWSE_LIVE_LIMIT = 10;
const BROWSE_TEAM_LIMIT = 10;
const BROWSE_PLAYER_LIMIT = 10;

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

  // `kind` narrows to one group for the "See all" drill-down. Validated
  // against a literal allow-list — never interpolated into SQL.
  const kindRaw = typeof body.kind === "string" ? (body.kind as string) : null;
  const kind =
    kindRaw === "players" || kindRaw === "teams" || kindRaw === "matches"
      ? kindRaw
      : null;

  const limit = Math.min(
    PER_GROUP_HARD_CAP,
    Math.max(
      1,
      typeof body.limit === "number" ? (body.limit as number) : PER_GROUP_LIMIT,
    ),
  );

  const sql = db();

  try {
    if (q === null) return json(200, await browse(sql, actor));
    return json(200, await search(sql, q, kind, limit));
  } catch (e) {
    console.error("search-all failed:", e);
    return json(500, {
      ok: false,
      error: { code: "query_failed", message: String(e) },
    });
  }
});

// ─── SEARCH ──────────────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
async function search(sql: any, q: string, kind: string | null, limit: number) {
  const wantPlayers = kind === null || kind === "players";
  const wantTeams = kind === null || kind === "teams";
  const wantMatches = kind === null || kind === "matches";

  // Fire the groups concurrently — they are independent reads and the pool
  // is sized for it (max 3). Sequential awaits would triple latency on the
  // debounced keystroke path.
  const [players, teams, matches] = await Promise.all([
    wantPlayers ? searchPlayers(sql, q, limit) : Promise.resolve([]),
    wantTeams ? searchTeams(sql, q, limit) : Promise.resolve([]),
    wantMatches ? searchMatches(sql, q, limit) : Promise.resolve([]),
  ]);

  return { players, teams, matches };
}

// Registered profiles + unclaimed players in one ranked list.
//
// Operand order is `q <% search_name` — "q is contained within search_name" —
// matching word_similarity(q, search_name), same as search-teams. A prefix
// LIKE is unioned in so short exact-prefix queries stay fast and always hit.
// deno-lint-ignore no-explicit-any
function searchPlayers(sql: any, q: string, limit: number) {
  return sql`
    with registered as (
      select
        'profile'::text                     as player_type,
        p.user_id::text                     as id,
        p.display_name                      as name,
        p.username,
        p.profile_photo_url                 as photo_url,
        p.location->>'city'                 as city,
        pp.player_role::text                as player_role,
        pp.batting_style::text              as batting_style,
        pp.bowling_style::text              as bowling_style,
        p.is_verified,
        false                               as is_unclaimed,
        null::text                          as team_context,
        (select count(*)::int from public.follows f
          where f.target_type = 'user' and f.target_id = p.user_id)
                                            as follower_count,
        coalesce(word_similarity(${q}, p.search_name), 0)::float8 as score
      from public.profiles p
      left join public.player_profiles pp on pp.user_id = p.user_id
      where p.account_status = 'active'
        and coalesce((p.discoverability->>'appear_in_search')::boolean, true)
        and (p.search_name like ${q} || '%' or ${q} <% p.search_name)
    ),
    unclaimed as (
      -- NEVER select phone_number / email here. See migration 20260821000000.
      select
        'unclaimed'::text                   as player_type,
        u.unclaimed_id::text                as id,
        u.display_name                      as name,
        null::text                          as username,
        null::text                          as photo_url,
        null::text                          as city,
        u.player_profile->>'player_role'    as player_role,
        u.player_profile->>'batting_style'  as batting_style,
        u.player_profile->>'bowling_style'  as bowling_style,
        false                               as is_verified,
        true                                as is_unclaimed,
        (select t.team_name
           from public.team_members tm
           join public.teams t on t.team_id = tm.team_id
          where tm.unclaimed_id = u.unclaimed_id
          order by tm.joined_at asc
          limit 1)                          as team_context,
        0::int                              as follower_count,
        -- Unclaimed rows rank slightly below an equally-matching real profile:
        -- a signed-up player is the more useful result for the same string.
        (coalesce(word_similarity(${q}, u.search_name), 0) * 0.9)::float8 as score
      from public.unclaimed_players u
      where u.claimed_by_user_id is null
        and (u.search_name like ${q} || '%' or ${q} <% u.search_name)
    )
    select * from (
      select * from registered
      union all
      select * from unclaimed
    ) both_kinds
    order by score desc, is_verified desc, follower_count desc, id asc
    limit ${limit}`;
}

// Name-only team search. Same projection as `search-teams` so the Flutter DTO
// is shared; distance_km is always null in v1 (no coordinates exist).
// deno-lint-ignore no-explicit-any
function searchTeams(sql: any, q: string, limit: number) {
  return sql`
    select
      t.team_id,
      t.team_name,
      t.logo_url,
      t.logo_monogram,
      t.team_colors,
      t.location,
      t.is_verified,
      t.founded_year,
      t.team_type::text as team_type,
      null::float8 as distance_km,
      coalesce(word_similarity(${q}, t.search_name), 0)::float8 as score
    from public.teams t
    where t.status = 'active'
      and t.privacy = 'public'
      and (t.search_name like ${q} || '%' or ${q} <% t.search_name)
    order by score desc, t.is_verified desc, t.updated_at desc, t.team_id asc
    limit ${limit}`;
}

// Matches are found through the names of the teams playing, or the venue.
// Ranked live-first, then by recency — a live match is the most valuable
// result on this screen.
// deno-lint-ignore no-explicit-any
function searchMatches(sql: any, q: string, limit: number) {
  return sql`
    ${matchProjection(sql)}
    where (
        ta.search_name like ${q} || '%' or ${q} <% ta.search_name
        or tb.search_name like ${q} || '%' or ${q} <% tb.search_name
        or lower(public.f_unaccent(coalesce(m.venue, ''))) like '%' || lower(public.f_unaccent(${q})) || '%'
      )
      and m.status <> 'abandoned'
      and (m.tournament_id is null or tr.privacy = 'public')
    order by
      (m.status = 'live') desc,
      coalesce(m.actual_start_time, m.scheduled_start_time) desc nulls last,
      m.match_id asc
    limit ${limit}`;
}

// ─── BROWSE ──────────────────────────────────────────────────────────────────

// No query: the discovery state. v1 leads with live matches (real data, and
// the most compelling thing in the app), then recently-active teams and new
// players. This deliberately replaces the design's proximity sections
// ("Teams near you") until coordinates exist — a distance-ordered list of an
// empty dimension would be a lie.
// deno-lint-ignore no-explicit-any
async function browse(sql: any, actor: string) {
  const [live, teams, players] = await Promise.all([
    sql`
      ${matchProjection(sql)}
      where m.status in ('live', 'innings_break', 'super_over')
        and (m.tournament_id is null or tr.privacy = 'public')
      order by coalesce(m.actual_start_time, m.scheduled_start_time) desc nulls last,
               m.match_id asc
      limit ${BROWSE_LIVE_LIMIT}`,
    sql`
      select
        t.team_id,
        t.team_name,
        t.logo_url,
        t.logo_monogram,
        t.team_colors,
        t.location,
        t.is_verified,
        t.founded_year,
        t.team_type::text as team_type,
        null::float8 as distance_km,
        0::float8 as score
      from public.teams t
      where t.status = 'active'
        and t.privacy = 'public'
      order by t.is_verified desc, t.updated_at desc, t.team_id asc
      limit ${BROWSE_TEAM_LIMIT}`,
    sql`
      select
        'profile'::text        as player_type,
        p.user_id::text        as id,
        p.display_name         as name,
        p.username,
        p.profile_photo_url    as photo_url,
        p.location->>'city'    as city,
        pp.player_role::text   as player_role,
        pp.batting_style::text as batting_style,
        pp.bowling_style::text as bowling_style,
        p.is_verified,
        false                  as is_unclaimed,
        null::text             as team_context,
        (select count(*)::int from public.follows f
          where f.target_type = 'user' and f.target_id = p.user_id)
                               as follower_count,
        0::float8              as score
      from public.profiles p
      left join public.player_profiles pp on pp.user_id = p.user_id
      where p.account_status = 'active'
        and coalesce((p.discoverability->>'appear_in_search')::boolean, true)
        and p.username is not null
        -- "Players to follow" should never suggest the caller to themselves.
        and p.user_id <> ${actor}::uuid
      order by p.is_verified desc, p.last_active_at desc nulls last, p.user_id asc
      limit ${BROWSE_PLAYER_LIMIT}`,
  ]);

  return { live, teams, players, matches: [] };
}

// ─── shared match projection ─────────────────────────────────────────────────

// Both the browse rail and match search need the same columns, including the
// live score and which side is batting.
//
// Batting side is DERIVED, not stored: match_innings_state has no batting-team
// column, so we reconstruct it from the toss. Innings 1 is batted by the toss
// winner if they chose 'bat', otherwise by the other team; innings 2 flips.
// If the toss is not recorded yet there is no score to attribute anyway.
// deno-lint-ignore no-explicit-any
function matchProjection(sql: any) {
  return sql`
    select
      m.match_id,
      m.status::text        as status,
      m.venue,
      m.scheduled_start_time,
      m.actual_start_time,
      m.team_a_id,
      ta.team_name          as team_a_name,
      ta.team_colors        as team_a_colors,
      ta.logo_url           as team_a_logo,
      m.team_b_id,
      tb.team_name          as team_b_name,
      tb.team_colors        as team_b_colors,
      tb.logo_url           as team_b_logo,
      tr.tournament_name,
      s.innings_number,
      s.total_runs,
      s.total_wickets,
      s.legal_ball_count,
      s.target,
      case
        when m.toss_won_by is null or m.toss_decision is null then null
        when s.innings_number is null then null
        -- innings 1 batting team
        when s.innings_number = 1 then
          case when m.toss_decision = 'bat' then m.toss_won_by
               when m.toss_won_by = m.team_a_id then m.team_b_id
               else m.team_a_id end
        -- innings 2 is the other side
        else
          case when m.toss_decision = 'bat' then
                 case when m.toss_won_by = m.team_a_id then m.team_b_id
                      else m.team_a_id end
               else m.toss_won_by end
      end as batting_team_id
    from public.matches m
    left join public.teams ta on ta.team_id = m.team_a_id
    left join public.teams tb on tb.team_id = m.team_b_id
    left join public.tournaments tr on tr.tournament_id = m.tournament_id
    -- Latest innings only: a completed match would otherwise return one row
    -- per innings and duplicate in the list.
    left join lateral (
      select mis.innings_number, mis.total_runs, mis.total_wickets,
             mis.legal_ball_count, mis.target
        from public.match_innings_state mis
       where mis.match_id = m.match_id
       order by mis.innings_number desc
       limit 1
    ) s on true`;
}
