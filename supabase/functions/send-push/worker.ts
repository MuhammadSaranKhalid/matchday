import type { SupabaseClient } from "@supabase/supabase-js";

export interface Job {
  msg_id: string;
  read_ct: number;
  message: {
    notification_id: string;
    revision: number;
    token_id: string;
    recipient_id: string;
    title: string;
    body: string;
    route: string | null;
    type_key: string;
    importance: string;
  };
}
export interface SendResult {
  status: "sent" | "failed" | "invalid_token";
  provider_message_id?: string;
  error?: string;
  retryable?: boolean;
}
export interface JobStore {
  exists(job: Job): Promise<boolean>;
  previous(job: Job): Promise<{ status: string; retryable: boolean } | null>;
  suppression(job: Job): Promise<string | null>;
  token(job: Job): Promise<string | null>;
  record(
    job: Job,
    result: {
      status: string;
      error?: string;
      provider_message_id?: string;
      retryable?: boolean;
    },
  ): Promise<void>;
  revoke(job: Job, token: string): Promise<void>;
  archive(job: Job): Promise<void>;
}

// Separated from HTTP/OAuth for deterministic failure-window tests.
export async function processJob(
  job: Job,
  store: JobStore,
  send: (job: Job, token: string) => Promise<SendResult>,
): Promise<void> {
  if (!await store.exists(job)) {
    await store.archive(job);
    return;
  }
  const previous = await store.previous(job);
  if (previous && (previous.status !== "failed" || !previous.retryable)) {
    await store.archive(job);
    return;
  }
  // A retry cannot silently change a terminal failed outcome into a success
  // after the configured attempt budget has been exhausted.
  if (job.read_ct > 5) {
    await store.record(job, {
      status: "failed",
      error: "retry_budget_exhausted",
    });
    await store.archive(job);
    return;
  }
  const suppressed = await store.suppression(job);
  if (suppressed) {
    await store.record(job, { status: suppressed });
    await store.archive(job);
    return;
  }
  const token = await store.token(job);
  if (!token) {
    await store.record(job, { status: "no_token" });
    await store.archive(job);
    return;
  }
  let result: SendResult;
  try {
    result = await send(job, token);
  } catch {
    result = { status: "failed", error: "transport_failure", retryable: true };
  }
  // Persist actual result before ack. Failure here leaves the lease to expire.
  await store.record(job, result);
  if (result.status === "invalid_token") await store.revoke(job, token);
  if (result.status !== "failed" || !result.retryable || job.read_ct >= 5) {
    await store.archive(job);
  }
}

export function fcmMessage(job: Job, token: string) {
  const n = job.message;
  return {
    message: {
      token,
      notification: { title: n.title, body: n.body },
      data: {
        notification_id: n.notification_id,
        type_key: n.type_key,
        route: n.route ?? "/notifications",
      },
      android: {
        priority: n.importance === "high" ? "HIGH" : "NORMAL",
        notification: { tag: n.notification_id },
      },
      apns: {
        headers: {
          "apns-priority": n.importance === "high" ? "10" : "5",
          "apns-collapse-id": n.notification_id,
        },
      },
    },
  };
}

export async function sendFcm(
  job: Job,
  token: string,
  projectId: string,
  accessToken: string,
  request: typeof fetch = fetch,
): Promise<SendResult> {
  const res = await request(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      signal: AbortSignal.timeout(10000),
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(fcmMessage(job, token)),
    },
  );
  const body = await res.json().catch(() => ({}));
  if (res.ok) return { status: "sent", provider_message_id: body.name };
  const details = body.error?.details ?? [];
  const code = details.find((d: { "@type"?: string }) =>
    d["@type"] === "type.googleapis.com/google.firebase.fcm.v1.FcmError"
  )?.errorCode;
  // HTTP 400 can mean a malformed message, not a dead device token.
  if (code === "UNREGISTERED") return { status: "invalid_token", error: code };
  return {
    status: "failed",
    error: code ?? `fcm_http_${res.status}`,
    retryable: res.status === 429 || res.status >= 500 || res.status === 401,
  };
}

function checked<T>(result: { data: T; error: { message: string } | null }): T {
  if (result.error) throw new Error(result.error.message);
  return result.data;
}

export function databaseStore(db: SupabaseClient, queue: string): JobStore {
  const key = (j: Job) => ({
    notification_id: j.message.notification_id,
    revision: j.message.revision,
    device_key: j.message.token_id,
    channel: "push",
  });
  return {
    async exists(j) {
      return !!checked(
        await db.from("notifications").select("notification_id")
          .eq("notification_id", j.message.notification_id).maybeSingle(),
      );
    },
    async previous(j) {
      return checked(
        await db.from("notification_deliveries").select("status,retryable")
          .match(key(j)).maybeSingle(),
      ) ?? null;
    },
    async suppression(j) {
      return checked(
        await db.rpc("notification_push_status", {
          p_id: j.message.notification_id,
          p_revision: j.message.revision,
        }),
      );
    },
    async token(j) {
      return checked(
        await db.from("device_tokens").select("fcm_token")
          .eq("token_id", j.message.token_id).eq(
            "user_id",
            j.message.recipient_id,
          )
          .maybeSingle(),
      )?.fcm_token ?? null;
    },
    async record(j, result) {
      checked(
        await db.from("notification_deliveries")
          .upsert({
            ...key(j),
            status: result.status,
            error: result.error ?? null,
            retryable: result.retryable ?? false,
            provider_message_id: result.provider_message_id ?? null,
            attempts: j.read_ct,
          }),
      );
    },
    async revoke(j, token) {
      checked(
        await db.from("device_tokens").delete()
          .eq("token_id", j.message.token_id).eq("fcm_token", token),
      );
    },
    async archive(j) {
      checked(
        await db.rpc("finish_notification_job", {
          p_queue: queue,
          p_id: j.msg_id,
        }),
      );
    },
  };
}
