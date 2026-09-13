// Scheduled, bounded pgmq consumer. Required: FCM_PROJECT_ID,
// FCM_SERVICE_ACCOUNT, NOTIFICATION_WORKER_SECRET (also stored in Vault as
// notification_worker_secret). No direct notification/message send endpoint.
import { createClient } from "@supabase/supabase-js";
import { getAccessToken } from "./oauth.ts";
import { databaseStore, type Job, processJob, sendFcm } from "./worker.ts";

Deno.serve(async (req) => {
  const secret = Deno.env.get("NOTIFICATION_WORKER_SECRET");
  if (!secret || req.headers.get("x-worker-secret") !== secret) {
    return new Response("unauthorized", { status: 401 });
  }
  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    {
      global: {
        fetch: (input, init) =>
          fetch(input, { ...init, signal: AbortSignal.timeout(10000) }),
      },
    },
  );
  try {
    // Obtain OAuth before claiming jobs; a configuration error consumes no leases.
    const accessToken = await getAccessToken();
    const outcomes: PromiseSettledResult<void>[] = [];
    for (const queue of ["notifications_push", "notifications_push_bulk"]) {
      const { data, error } = await db.rpc("read_notification_jobs", {
        p_queue: queue,
      });
      if (error) throw error;
      const jobs = (data ?? []) as Job[];
      outcomes.push(
        ...await Promise.allSettled(
          jobs.map((j) =>
            processJob(
              j,
              databaseStore(db, queue),
              (job, token) =>
                sendFcm(
                  job,
                  token,
                  Deno.env.get("FCM_PROJECT_ID")!,
                  accessToken,
                ),
            )
          ),
        ),
      );
    }
    const failed = outcomes.filter((r) => r.status === "rejected").length;
    // Do not log notification contents, tokens or provider response bodies.
    console.log(JSON.stringify({ processed: outcomes.length, failed }));
    return Response.json({ processed: outcomes.length, failed });
  } catch {
    console.error(
      "Notification worker failed; unacknowledged jobs remain queued",
    );
    return new Response("worker unavailable", { status: 503 });
  }
});
