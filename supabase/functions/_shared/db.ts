// Connection helpers for the match edge functions.
//
//  • userClient — acts AS the caller (forwards their JWT). RLS + auth.uid()
//                 apply, so server-side rules like _can_score_match() see the
//                 real user. Used for authorization and user-scoped reads.
//  • db()       — a pooled DIRECT Postgres connection (postgres.js). This is how
//                 the match functions run real multi-statement TRANSACTIONS
//                 (lock → check version → write balls + innings_state → commit),
//                 which PostgREST / supabase-js cannot do.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import { createClient } from "npm:@supabase/supabase-js@2";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import postgres from "npm:postgres@3.4.5";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

export function userClient(authHeader: string) {
  return createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
}

// ── Direct Postgres connection ───────────────────────────────────────────────
// Mode: Supabase recommends the Supavisor TRANSACTION pooler (port 6543) for
// edge/serverless — many short transactions, IPv4-reachable (the direct
// endpoint is IPv6-only without the paid add-on). Supabase's own edge example
// passes SUPABASE_DB_URL to postgres.js with `prepare:false`, implying that in
// the edge runtime SUPABASE_DB_URL IS the transaction pooler — but the secrets
// doc only calls it the "connect directly" URL and never pins the port. So:
//   • default to SUPABASE_DB_URL,
//   • allow MATCH_DB_URL to override it with an explicit transaction-pooler
//     string (copied from the dashboard's "Transaction pooler" connect dialog)
//     WITHOUT a code change, if SUPABASE_DB_URL ever resolves to direct :5432,
//   • log host:port (never credentials) so the deploy logs prove which we got.
// `prepare:false` is REQUIRED in transaction mode (it cannot honor prepared
// statements). SSL is pre-configured for deployed edge functions, so no `ssl`
// option. The small bounded pool + idle/lifetime caps prevent the
// "Max client connections reached" exhaustion that postgres.js's bare defaults
// (max:10, never-idle) invite across many warm instances.
function dbUrl(): string {
  return Deno.env.get("MATCH_DB_URL") ?? Deno.env.get("SUPABASE_DB_URL")!;
}

let _sql: ReturnType<typeof postgres> | null = null;
export function db() {
  if (_sql) return _sql;
  const url = dbUrl();
  try {
    console.log("[record-ball] db host:", new URL(url).host);
  } catch (_) {
    // non-fatal: only a diagnostic log
  }
  _sql = postgres(url, {
    prepare: false, // required for Supavisor transaction mode (port 6543)
    max: 3, // small per-instance pool — avoid pooler connection exhaustion
    idle_timeout: 20, // seconds: release idle pooled connections between bursts
    max_lifetime: 60 * 30, // seconds: recycle a connection after ~30 min
    connect_timeout: 10, // seconds: fail fast on a saturated pooler
  });
  // Release connections cleanly when the warm edge instance is recycled.
  addEventListener("beforeunload", () => {
    _sql?.end({ timeout: 5 });
  });
  return _sql;
}
