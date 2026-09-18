import type { SupabaseClient } from "@supabase/supabase-js";

export interface ChatPushJob {
  token_id: string;
  fcm_token: string;
  platform: string;
  recipient_id: string;
  title: string;
  body: string;
  route: string | null;
  type_key: string;
  importance: string;
  chat_id: string;
  message_id: string;
  sender_id: string;
}

export interface SendResult {
  status: "sent" | "failed" | "invalid_token";
  provider_message_id?: string;
  error?: string;
  retryable?: boolean;
}

export function fcmMessage(job: ChatPushJob) {
  return {
    message: {
      token: job.fcm_token,
      notification: { title: job.title, body: job.body },
      data: {
        chat_id: job.chat_id,
        message_id: job.message_id,
        sender_id: job.sender_id,
        type_key: job.type_key,
        route: job.route ?? `/messages/${job.chat_id}`,
      },
      android: {
        priority: job.importance === "high" ? "HIGH" : "NORMAL",
        notification: { tag: `chat:${job.chat_id}` },
      },
      apns: {
        headers: {
          "apns-priority": job.importance === "high" ? "10" : "5",
          "apns-collapse-id": `chat:${job.chat_id}`,
        },
      },
    },
  };
}

export async function sendFcm(
  job: ChatPushJob,
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
      body: JSON.stringify(fcmMessage(job)),
    },
  );
  const body = await res.json().catch(() => ({}));
  if (res.ok) return { status: "sent", provider_message_id: body.name };
  const details = body.error?.details ?? [];
  const code = details.find((d: { "@type"?: string }) =>
    d["@type"] === "type.googleapis.com/google.firebase.fcm.v1.FcmError"
  )?.errorCode;

  if (code === "UNREGISTERED") return { status: "invalid_token", error: code };
  return {
    status: "failed",
    error: code ?? `fcm_http_${res.status}`,
    retryable: res.status === 429 || res.status >= 500 || res.status === 401,
  };
}

export async function processChatPushJob(
  db: SupabaseClient,
  job: ChatPushJob,
  projectId: string,
  accessToken: string,
  send: (
    job: ChatPushJob,
    projectId: string,
    accessToken: string,
  ) => Promise<SendResult> = sendFcm,
): Promise<SendResult> {
  let result: SendResult;
  try {
    result = await send(job, projectId, accessToken);
  } catch (err) {
    result = {
      status: "failed",
      error: err instanceof Error ? err.message : "transport_failure",
      retryable: true,
    };
  }

  // Revoke invalid tokens immediately upon FCM reporting UNREGISTERED
  if (result.status === "invalid_token") {
    await db.from("device_tokens").delete().eq("token_id", job.token_id);
  }

  return result;
}
