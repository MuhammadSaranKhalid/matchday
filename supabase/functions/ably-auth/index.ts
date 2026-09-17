// supabase/functions/ably-auth/index.ts
//
// Generates scoped, signed Ably TokenRequests for authenticated Supabase users.
// Ensures that clients only have access to their permitted channels.
//
// Root Ably secret remains strictly on the server (via ABLY_API_KEY environment variable).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — npm: specifier resolved by Deno at runtime
import * as Ably from "npm:ably@2.4.1";
// @ts-ignore — npm: specifier resolved by Deno at runtime
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsPreflight, json } from "../_shared/http.ts";

const ABLY_API_KEY = Deno.env.get("ABLY_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") return corsPreflight();

  if (!ABLY_API_KEY) {
    console.error("[ably-auth] Missing ABLY_API_KEY environment variable.");
    return json(500, {
      ok: false,
      error: {
        code: "CONFIG_ERROR",
        message: "Server real-time key not configured. Please set ABLY_API_KEY.",
      },
    });
  }

  // 2. Auth verification from Bearer header
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json(401, {
      ok: false,
      error: { code: "UNAUTHENTICATED", message: "Missing Authorization header" },
    });
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: { user }, error: authError } = await adminClient.auth.getUser(token);
  if (authError || !user) {
    return json(401, {
      ok: false,
      error: { code: "UNAUTHORIZED", message: "Invalid or expired session" },
    });
  }

  const userId = user.id;

  try {
    // 3. Query caller's active channel memberships
    const { data: memberships, error: memError } = await adminClient
      .from("channel_members")
      .select("channel_id")
      .eq("user_id", userId)
      .in("status", ["active", "pending"]);

    if (memError) {
      console.warn("[ably-auth] Failed to query memberships, continuing with private channels only:", memError);
    }

    // 4. Construct strictly scoped capabilities
    // Clients can ONLY subscribe and announce presence on channels they belong to.
    // Publish permissions for messages are forbidden (messages write exclusively via Supabase RPC).
    const capability: Record<string, string[]> = {
      // User's private notification channel (inbox updates, alerts)
      [`user:${userId}:*`]: ["subscribe"],
      // Match event feeds (live ticker, ball-by-ball, state)
      "match:*:live": ["subscribe"],
      "match:*": ["subscribe"],
      // Team feeds
      "team:*": ["subscribe", "presence"],
    };

    for (const row of memberships ?? []) {
      capability[`chat:${row.channel_id}`] = ["subscribe", "presence"];
    }

    // 5. Generate Ably Token Request
    const ably = new Ably.Rest(ABLY_API_KEY);
    const tokenRequest = await ably.auth.createTokenRequest({
      clientId: userId,
      capability: JSON.stringify(capability),
      ttl: 3600 * 1000, // 1 hour token TTL
    });

    return json(200, tokenRequest);
  } catch (err) {
    console.error("[ably-auth] Token generation error:", err);
    return json(500, {
      ok: false,
      error: { code: "INTERNAL_ERROR", message: String(err) },
    });
  }
});
