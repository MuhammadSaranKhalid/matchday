// supabase/functions/send-push/index.ts
//
// Fans a notifications-row insert out to every device the recipient is
// signed in on. Invoked from the `notifications_invoke_send_push` trigger
// (see migration 0900_device_tokens.sql).
//
// Required secrets (set via `supabase secrets set ...`):
//   FCM_PROJECT_ID         — Firebase project id (e.g. "matchday-44ed4")
//   FCM_SERVICE_ACCOUNT    — paste the entire JSON of a service-account key
//                            with "Firebase Cloud Messaging API" enabled
//
// Optional secrets (Supabase Functions auto-provides these):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// The trigger calls this function with the service-role key as a Bearer
// token; the function checks it manually below. `verify_jwt = false` lives
// in config.toml [functions.send-push] for that reason.

// Deno + Supabase edge-runtime type declarations. Keeps `Deno.serve` etc.
// typed when viewed with a Deno-aware LSP. The non-Deno TypeScript server
// in the IDE will still flag `npm:` / `jsr:` specifiers — that is purely
// editor noise and does not affect deploy.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore — `npm:` specifier is resolved by Deno at deploy time.
import { createClient } from "npm:@supabase/supabase-js@2";

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get("FCM_SERVICE_ACCOUNT")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

const sa: ServiceAccount = JSON.parse(FCM_SERVICE_ACCOUNT_JSON);

// ── Google OAuth: JWT → access token ─────────────────────────────────────
// Service-account assertion flow per
// https://developers.google.com/identity/protocols/oauth2/service-account.
// We cache the access token in-memory for its lifetime (1h) so a burst of
// notification inserts doesn't hammer the token endpoint.
let cachedToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.token;
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const encoder = new TextEncoder();
  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_")
      .replace(/=+$/, "");
  const headerB64 = encode(header);
  const claimB64 = encode(claim);
  const signingInput = `${headerB64}.${claimB64}`;

  // PEM → CryptoKey
  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const jwt = `${signingInput}.${sigB64}`;

  const res = await fetch(claim.aud, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`google oauth failed: ${res.status} ${await res.text()}`);
  }
  const data = await res.json() as { access_token: string; expires_in: number };
  cachedToken = {
    token: data.access_token,
    expiresAt: Date.now() + (data.expires_in - 60) * 1000,
  };
  return cachedToken.token;
}

// ── Notification → push message mapping ───────────────────────────────────
// One place to map server-side notification type + payload → the title/body
// shown by the OS, and the deep-link route the tap should follow. Add new
// types here as they're added to the notifications enum.

interface NotifRow {
  notification_id: string;
  recipient_id: string;
  type: string;
  payload: Record<string, unknown>;
}

interface PushContent {
  title: string;
  body: string;
  route: string;
}

// deno-lint-ignore no-explicit-any
async function teamName(supabase: any, id: unknown): Promise<string | null> {
  if (typeof id !== "string") return null;
  const { data } = await supabase
    .from("teams")
    .select("team_name")
    .eq("team_id", id)
    .maybeSingle();
  return (data as { team_name?: string } | null)?.team_name ?? null;
}

// deno-lint-ignore no-explicit-any
async function pushContentFor(supabase: any, n: NotifRow): Promise<PushContent> {
  switch (n.type) {
    case "team_invitation":
      return {
        title: "Team invite",
        body: "You were invited to a team",
        route: "/notifications",
      };
    case "post_like":
      return {
        title: "New like",
        body: "Someone liked your post",
        route: "/notifications",
      };
    case "post_comment":
      return {
        title: "New comment",
        body: "Someone commented on your post",
        route: "/notifications",
      };
    case "comment_reply":
      return {
        title: "Reply",
        body: "Someone replied to your comment",
        route: "/notifications",
      };
    case "mention":
      return {
        title: "Mention",
        body: "You were mentioned",
        route: "/notifications",
      };
    case "follow":
      return {
        title: "New follower",
        body: "Someone started following you",
        route: "/notifications",
      };
    case "match_starting":
      return {
        title: "Match starting",
        body: "Your match is about to start",
        route: "/notifications",
      };
    case "claim_decision":
      return {
        title: "Claim update",
        body: "Your claim request was updated",
        route: "/notifications",
      };
    case "match_request": {
      const from = await teamName(supabase, n.payload.from_team_id);
      const requestId = n.payload.request_id;
      return {
        title: from ? `${from} challenged you` : "New match challenge",
        body: "Tap to accept, counter or decline",
        route: typeof requestId === "string"
          ? `/challenges/${requestId}`
          : "/notifications",
      };
    }
    case "match_request_decision": {
      const status = String(n.payload.status ?? "");
      const other = (await teamName(supabase, n.payload.to_team_id)) ??
        "The other team";
      const byStatus: Record<string, { title: string; body: string }> = {
        accepted: { title: "Challenge accepted", body: `${other} accepted your match` },
        declined: { title: "Challenge declined", body: `${other} declined your challenge` },
        countered: { title: "Counter-offer", body: `${other} proposed new terms — tap to review` },
        cancelled: { title: "Match cancelled", body: "Your match was cancelled" },
        expired: { title: "Challenge expired", body: "Your challenge expired with no reply" },
      };
      const c = byStatus[status] ??
        { title: "Challenge update", body: "Your match challenge was updated" };
      return { ...c, route: "/notifications" };
    }
    default:
      return {
        title: "Circk",
        body: "You have a new notification",
        route: "/notifications",
      };
  }
}

// ── Chat-message push (path B for migration 0802 trigger) ────────────────
// The `messages_invoke_send_push` trigger in migration 0802 calls this
// function with `{message_id}` (not `{notification_id}` like the rest of
// the app). We branch on which key is present and dispatch separately.
//
// We don't insert into the `notifications` table on every chat message —
// chats already have their own unread bookkeeping (`chat_members
// .last_read_at`), so the notifications-row path would just duplicate
// state. The trade-off: chat messages don't show up in the in-app
// Notifications screen, but the chat list IS the notifications screen
// for messaging.

interface ChatMessageRow {
  message_id: string;
  chat_id: string;
  sender_id: string | null;
  body: string;
  sender: { display_name: string | null } | null;
  chat: { team: { team_name: string | null } | null } | null;
}

function chatMessagePushContent(m: ChatMessageRow): PushContent {
  const senderName = m.sender?.display_name ?? "Someone";
  const teamName = m.chat?.team?.team_name ?? "Chat";
  const trimmed = m.body.length > 140 ? m.body.slice(0, 140) + "…" : m.body;
  return {
    title: teamName,
    body: `${senderName}: ${trimmed}`,
    route: `/messages/${m.chat_id}`,
  };
}

// deno-lint-ignore no-explicit-any
async function handleMessagePush(supabase: any, messageId: string): Promise<Response> {
  // 1. Load the message + sender display name + chat → team_name.
  const { data: msg, error: msgErr } = await supabase
    .from("messages")
    .select(
      "message_id, chat_id, sender_id, body, " +
        "sender:profiles(display_name), " +
        "chat:chats(team:teams(team_name))",
    )
    .eq("message_id", messageId)
    .single<ChatMessageRow>();
  if (msgErr || !msg) {
    return new Response(`message not found: ${msgErr?.message}`, { status: 404 });
  }

  // 2. Recipient user_ids — every active chat member except the sender.
  // Mirrors the loop in `broadcast_new_message` (migration 0802).
  const { data: members, error: membersErr } = await supabase
    .from("chat_members")
    .select("user_id")
    .eq("chat_id", msg.chat_id)
    .is("left_at", null)
    .not("user_id", "is", null);
  if (membersErr) {
    return new Response(`members lookup failed: ${membersErr.message}`, {
      status: 500,
    });
  }
  const recipients = (members ?? [])
    .map((m: { user_id: string }) => m.user_id)
    .filter((id: string) => id !== msg.sender_id);
  if (recipients.length === 0) {
    return new Response(JSON.stringify({ sent: 0, skipped: "no_recipients" }), {
      headers: { "content-type": "application/json" },
    });
  }

  // 3. Device tokens for all recipients in one query.
  const { data: tokens, error: tokenErr } = await supabase
    .from("device_tokens")
    .select("token_id, fcm_token, platform")
    .in("user_id", recipients);
  if (tokenErr) {
    return new Response(`tokens lookup failed: ${tokenErr.message}`, { status: 500 });
  }
  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, skipped: "no_devices" }), {
      headers: { "content-type": "application/json" },
    });
  }

  // 4. Dispatch.
  const content = chatMessagePushContent(msg);
  const result = await dispatchPush({
    supabase,
    tokens,
    content,
    data: {
      message_id: msg.message_id,
      chat_id: msg.chat_id,
      type: "chat_message",
      route: content.route,
    },
    logTag: `msg=${msg.message_id} chat=${msg.chat_id}`,
  });
  return new Response(JSON.stringify(result), {
    headers: { "content-type": "application/json" },
  });
}

// ── Shared FCM dispatch ───────────────────────────────────────────────────
// Used by both push paths. Fans the content + data payload out to every
// supplied token; drops `device_tokens` rows for any token FCM reports as
// dead (404 / 400 / INVALID_ARGUMENT).

// deno-lint-ignore no-explicit-any
async function dispatchPush(opts: {
  supabase: any;
  tokens: Array<{ token_id: string; fcm_token: string; platform: string }>;
  content: PushContent;
  data: Record<string, string>;
  logTag: string;
}): Promise<{ sent: number; deadCount: number }> {
  const accessToken = await getAccessToken();
  const fcmUrl =
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;
  let sent = 0;
  const deadTokens: string[] = [];

  await Promise.all(opts.tokens.map(async (t) => {
    const message = {
      message: {
        token: t.fcm_token,
        notification: { title: opts.content.title, body: opts.content.body },
        data: opts.data,
        android: { priority: "HIGH" },
        apns: { headers: { "apns-priority": "10" } },
      },
    };
    const res = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "authorization": `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(message),
    });
    if (res.ok) {
      sent++;
      return;
    }
    const errText = await res.text().catch(() => "");
    console.error(`send-push FCM reject status=${res.status} body=${errText}`);
    if (res.status === 404 || res.status === 400) {
      deadTokens.push(t.fcm_token);
    }
  }));

  console.log(
    `send-push result ${opts.logTag} tokens=${opts.tokens.length} ` +
      `sent=${sent} dead=${deadTokens.length}`,
  );

  if (deadTokens.length > 0) {
    await opts.supabase.from("device_tokens").delete().in("fcm_token", deadTokens);
  }

  return { sent, deadCount: deadTokens.length };
}

// ── HTTP handler ──────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  // The trigger sends the service-role key as a Bearer token. Reject calls
  // that don't carry it — keeps the function private even with
  // `--no-verify-jwt`.
  const auth = req.headers.get("authorization") ?? "";
  if (auth !== `Bearer ${SERVICE_ROLE_KEY}`) {
    return new Response("unauthorized", { status: 401 });
  }

  let body: { notification_id?: string; message_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("bad json", { status: 400 });
  }
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // Path B: chat-message push (from messages_invoke_send_push trigger).
  if (body.message_id) {
    return handleMessagePush(supabase, body.message_id);
  }

  const notificationId = body.notification_id;
  if (!notificationId) {
    return new Response("missing notification_id or message_id", {
      status: 400,
    });
  }

  // 1. Load the notification row.
  const { data: notif, error: notifErr } = await supabase
    .from("notifications")
    .select("notification_id, recipient_id, type, payload")
    .eq("notification_id", notificationId)
    .single<NotifRow>();
  if (notifErr || !notif) {
    return new Response(`notification not found: ${notifErr?.message}`, {
      status: 404,
    });
  }

  // 2. Load all device tokens for this recipient.
  const { data: tokens, error: tokenErr } = await supabase
    .from("device_tokens")
    .select("token_id, fcm_token, platform")
    .eq("user_id", notif.recipient_id);
  if (tokenErr) {
    return new Response(`tokens lookup failed: ${tokenErr.message}`, {
      status: 500,
    });
  }
  if (!tokens || tokens.length === 0) {
    return new Response(
      JSON.stringify({ sent: 0, skipped: "no_devices" }),
      { headers: { "content-type": "application/json" } },
    );
  }

  // 3. Build the message and fan out via the shared helper.
  const content = await pushContentFor(supabase, notif);
  const result = await dispatchPush({
    supabase,
    tokens,
    content,
    data: {
      notification_id: notif.notification_id,
      type: notif.type,
      route: content.route,
    },
    logTag: `notif=${notificationId} type=${notif.type}`,
  });
  return new Response(JSON.stringify(result), {
    headers: { "content-type": "application/json" },
  });
});
