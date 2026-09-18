import { createClient } from "@supabase/supabase-js";
import { getAccessToken } from "./oauth.ts";
import { type ChatPushJob, processChatPushJob } from "./worker.ts";

Deno.serve(async (req) => {
  const secret = Deno.env.get("NOTIFICATION_WORKER_SECRET");
  if (!secret || req.headers.get("x-worker-secret") !== secret) {
    return new Response("unauthorized", { status: 401 });
  }

  if (req.method !== "POST") {
    return new Response("method not allowed", { status: 405 });
  }

  let body: { message_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("bad request: invalid json", { status: 400 });
  }

  const messageId = body.message_id;
  if (!messageId) {
    return new Response("bad request: missing message_id", { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const projectId = Deno.env.get("FCM_PROJECT_ID");

  if (!supabaseUrl || !serviceRoleKey || !projectId) {
    console.error("Missing required environment variables for send-chat-push");
    return new Response("internal configuration error", { status: 500 });
  }

  const db = createClient(supabaseUrl, serviceRoleKey, {
    global: {
      fetch: (input, init) =>
        fetch(input, { ...init, signal: AbortSignal.timeout(10000) }),
    },
  });

  try {
    const accessToken = await getAccessToken();

    // Prepare authoritative jobs server-side in Postgres
    const { data, error } = await db.rpc("prepare_chat_push_jobs", {
      p_message_id: messageId,
    });

    if (error) {
      console.error("Error in prepare_chat_push_jobs:", error);
      return new Response("database error", { status: 500 });
    }

    const jobs = (data ?? []) as ChatPushJob[];
    if (jobs.length === 0) {
      return Response.json({ dispatched: 0, status: "no_eligible_recipients" });
    }

    const outcomes = await Promise.allSettled(
      jobs.map((job) => processChatPushJob(db, job, projectId, accessToken)),
    );

    const sent = outcomes.filter(
      (r) => r.status === "fulfilled" && r.value.status === "sent",
    ).length;
    const failed = outcomes.filter(
      (r) =>
        r.status === "rejected" ||
        (r.status === "fulfilled" && r.value.status === "failed"),
    ).length;
    const invalidToken = outcomes.filter(
      (r) => r.status === "fulfilled" && r.value.status === "invalid_token",
    ).length;

    return Response.json({
      dispatched: jobs.length,
      sent,
      failed,
      invalid_token: invalidToken,
    });
  } catch (err) {
    console.error("send-chat-push execution failed:", err);
    return new Response("worker unavailable", { status: 503 });
  }
});
