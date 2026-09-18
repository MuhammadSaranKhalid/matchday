import {
  type ChatPushJob,
  fcmMessage,
  processChatPushJob,
} from "./worker.ts";

function assert(v: unknown, message = "assertion failed"): asserts v {
  if (!v) throw new Error(message);
}

const mockJob: ChatPushJob = {
  token_id: "tok-uuid-1",
  fcm_token: "fcm-device-token-xyz",
  platform: "android",
  recipient_id: "user-uuid-recipient",
  title: "Saran Khalid",
  body: "Saran Khalid: Hello matchday",
  route: "/messages/chat-channel-1",
  type_key: "chat.message.received",
  importance: "high",
  chat_id: "chat-channel-1",
  message_id: "msg-uuid-99",
  sender_id: "user-uuid-sender",
};

Deno.test("fcmMessage constructs correct payload with structured chat identifiers and native collapse tags", () => {
  const payload = fcmMessage(mockJob);
  assert(payload.message.token === "fcm-device-token-xyz");
  assert(payload.message.notification.title === "Saran Khalid");
  assert(payload.message.notification.body === "Saran Khalid: Hello matchday");
  assert(payload.message.data.chat_id === "chat-channel-1");
  assert(payload.message.data.message_id === "msg-uuid-99");
  assert(payload.message.data.sender_id === "user-uuid-sender");
  assert(payload.message.data.type_key === "chat.message.received");
  assert(payload.message.data.route === "/messages/chat-channel-1");
  assert(payload.message.android.priority === "HIGH");
  assert(payload.message.android.notification.tag === "chat:chat-channel-1");
  assert(payload.message.apns.headers["apns-priority"] === "10");
  assert(payload.message.apns.headers["apns-collapse-id"] === "chat:chat-channel-1");
});

Deno.test("processChatPushJob deletes token on UNREGISTERED", async () => {
  const deletedTokens: string[] = [];

  const fakeDb = {
    from: (table: string) => ({
      delete: () => ({
        eq: async (col: string, val: string) => {
          if (table === "device_tokens" && col === "token_id") {
            deletedTokens.push(val);
          }
          return { data: null, error: null };
        },
      }),
    }),
  } as unknown;

  const res = await processChatPushJob(
    fakeDb as any,
    mockJob,
    "proj-123",
    "access-tok",
    async () => ({ status: "invalid_token", error: "UNREGISTERED" }),
  );

  assert(res.status === "invalid_token");
  assert(deletedTokens.length === 1);
  assert(deletedTokens[0] === "tok-uuid-1");
});
