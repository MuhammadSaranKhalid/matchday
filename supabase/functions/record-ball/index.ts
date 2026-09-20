// record-ball — HTTP API Endpoint for recording a cricket delivery.
//
// Phase 2 realtime contract:
//   ball_recorded          -> raw delivery row
//   innings_state_updated  -> raw innings-state row
//   match_state_updated    -> raw cricket_match_details row
//
// Flutter consumes those exact DTO shapes. Do not wrap them in
// {ball:...}/{innings:...} on the Ably event itself.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { corsPreflight, json } from "../_shared/http.ts";
import { authenticateRequest } from "./services/auth_service.ts";
import { parseAndValidateRecordBall } from "./schemas/record_ball_schema.ts";
import { HttpSignal, scoringService } from "./services/scoring_service.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflight();

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

  let rawBody: Record<string, unknown>;
  try {
    rawBody = await req.json();
  } catch {
    return json(400, {
      ok: false,
      error: { code: "BAD_REQUEST", message: "Request body is not valid JSON" },
    });
  }

  const idempotencyHeader = req.headers.get("Idempotency-Key");
  const validation = parseAndValidateRecordBall(rawBody, idempotencyHeader);
  if (validation.error) {
    return json(400, {
      ok: false,
      error: validation.error,
    });
  }

  try {
    const out = await scoringService.recordDelivery(
      auth.actorId,
      validation.data!,
    );

    const ablyKey = Deno.env.get("ABLY_API_KEY");
    if (ablyKey && !out.duplicate) {
      try {
        const Ably = (await import("npm:ably@2.4.1")).default;
        const ably = new Ably.Rest(ablyKey);
        const matchId = validation.data!.matchId;

        await ably.channels
          .get(`match:${matchId}:balls`)
          .publish("ball_recorded", out.ball);

        if (out.innings) {
          await ably.channels
            .get(`match:${matchId}:state`)
            .publish("innings_state_updated", out.innings);
        }

        if (out.match) {
          await ably.channels
            .get(`match:${matchId}:state`)
            .publish("match_state_updated", out.match);
        }
      } catch (ablyErr) {
        console.error("[record-ball] Ably broadcast failed:", ablyErr);
      }
    }

    return json(200, {
      ok: true,
      ball: out.ball,
      innings: out.innings,
      match: out.match,
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
