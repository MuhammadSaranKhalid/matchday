// record-ball — HTTP API Endpoint for recording a cricket delivery.
//
// Clean Layered Architecture:
//   1. Request parsing & CORS preflight handling
//   2. Supabase Auth verification via @supabase/server
//   3. Schema validation & Type coercion
//   4. Atomic Transaction execution via ScoringService

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsPreflight, json } from "../_shared/http.ts";
import { authenticateRequest } from "./services/auth_service.ts";
import { parseAndValidateRecordBall } from "./schemas/record_ball_schema.ts";
import { HttpSignal, scoringService } from "./services/scoring_service.ts";

Deno.serve(async (req) => {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") return corsPreflight();

  // 2. Authentication via @supabase/server
  const auth = await authenticateRequest(req);
  if (auth.error || !auth.actorId) {
    return json(auth.error?.status ?? 401, {
      ok: false,
      error: {
        code: auth.error?.code ?? "UNAUTHENTICATED",
        message: auth.error?.message ?? "Invalid or missing session",
      },
    });
  }
  const actor = auth.actorId;

  // 3. Body Parsing
  let rawBody: Record<string, unknown>;
  try {
    rawBody = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: { code: "BAD_REQUEST", message: "Request body is not valid JSON" },
    });
  }

  // 4. Schema Validation
  const idempotencyHeader = req.headers.get("Idempotency-Key");
  const validation = parseAndValidateRecordBall(rawBody, idempotencyHeader);
  if (validation.error) {
    return json(400, {
      ok: false,
      error: validation.error,
    });
  }

  // 5. Service Execution
  try {
    const out = await scoringService.recordDelivery(actor, validation.data!);

    // Broadcast to Ably channels for live spectators (non-blocking)
    const ablyKey = Deno.env.get("ABLY_API_KEY");
    if (ablyKey && !out.duplicate) {
      try {
        const ably = new (await import("npm:ably@2.4.1")).default.Rest(ablyKey);
        const matchId = validation.data!.matchId;
        // Broadcast ball to spectator feed
        ably.channels.get(`match:${matchId}:balls`).publish("ball_recorded", {
          ball: out.ball,
          innings: out.innings,
          transition: out.transition,
        }).catch((e: unknown) => console.error("[record-ball] Ably balls broadcast failed:", e));

        // Broadcast updated state to match state feed
        ably.channels.get(`match:${matchId}:state`).publish("match_state_updated", {
          innings: out.innings,
          transition: out.transition,
        }).catch((e: unknown) => console.error("[record-ball] Ably state broadcast failed:", e));
      } catch (ablyErr) {
        console.error("[record-ball] Could not initialize Ably broadcast:", ablyErr);
      }
    }

    return json(200, {
      ok: true,
      ball: out.ball,
      innings: out.innings,
      transition: out.transition,
      duplicate: out.duplicate,
      data: out,
    });
  } catch (e) {
    if (e instanceof HttpSignal) {
      return json(e.status, {
        ok: false,
        error: { code: e.code, message: e.message },
      });
    }

    console.error("[record-ball] Internal error:", e);
    return json(500, {
      ok: false,
      error: { code: "INTERNAL_ERROR", message: String(e) },
    });
  }
});
