// record-ball — HTTP API Endpoint for recording a cricket delivery.
//
// Realtime contract:
//   ball_recorded          -> raw delivery row
//   innings_changed        -> versioned invalidation envelope
//   match_completed        -> versioned invalidation envelope
//
// PostgreSQL remains authoritative; state events tell clients which revision
// to reconcile. The balls channel retains the full delivery row for the
// low-latency scoring projection.

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

        const eventType = out.transition.kind === "completed"
          ? "match_completed"
          : "innings_changed";
        await ably.channels
          .get(`match:${matchId}:state`)
          .publish(eventType, {
            eventId: crypto.randomUUID(),
            matchId,
            revision: out.revision,
            eventType,
            inningsNumber: validation.data!.inningsNumber,
            occurredAt: new Date().toISOString(),
          });
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
      revision: out.revision,
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
