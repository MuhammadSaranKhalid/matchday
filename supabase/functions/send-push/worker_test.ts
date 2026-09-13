// deno-lint-ignore-file require-await
// Async test doubles deliberately model the Promise-based production adapter.
import {
  fcmMessage,
  type Job,
  type JobStore,
  processJob,
  sendFcm,
} from "./worker.ts";
function assert(v: unknown, message = "assertion failed"): asserts v {
  if (!v) throw new Error(message);
}
const job: Job = {
  msg_id: "9007199254740993",
  read_ct: 1,
  message: {
    notification_id: "notification",
    token_id: "device",
    recipient_id: "user",
    revision: 2,
    title: "New type",
    body: "Rendered once",
    route: null,
    type_key: "future.event",
    importance: "normal",
  },
};
function store() {
  const events: string[] = [];
  const s: JobStore = {
    exists: async () => true,
    previous: async () => null,
    suppression: async () => null,
    token: async () => "secret-token",
    record: async (_, r) => {
      events.push(r.status);
    },
    archive: async () => {
      events.push("archived");
    },
    revoke: async () => {
      events.push("revoked");
    },
  };
  return { s, events };
}
Deno.test("never records sent before provider acceptance", async () => {
  const { s, events } = store();
  await processJob(job, s, async () => {
    assert(events.length === 0);
    events.push("accepted");
    return { status: "sent" };
  });
  assert(events.join(",") === "accepted,sent,archived");
});
Deno.test("transport failure stays queued", async () => {
  const { s, events } = store();
  await processJob(job, s, async () => {
    throw Error("timeout");
  });
  assert(events.join(",") === "failed");
});
Deno.test("failed persistence does not acknowledge job", async () => {
  const { s, events } = store();
  s.record = async () => {
    throw Error("db down");
  };
  let failed = false;
  try {
    await processJob(job, s, async () => ({ status: "sent" }));
  } catch {
    failed = true;
  }
  assert(failed && events.length === 0);
});
Deno.test("completed device is not resent after acknowledgement failure", async () => {
  const { s, events } = store();
  s.previous = async () => ({ status: "sent", retryable: false });
  await processJob(job, s, async () => {
    throw Error("must not send");
  });
  assert(events.join(",") === "archived");
});
Deno.test("permanent failures are not resent on redelivery", async () => {
  const { s, events } = store();
  s.previous = async () => ({ status: "failed", retryable: false });
  await processJob(job, s, async () => {
    throw Error("must not send");
  });
  assert(events.join(",") === "archived");
});
Deno.test("new mute suppresses previously queued job", async () => {
  const { s, events } = store();
  s.suppression = async () => "skipped_mute";
  await processJob(job, s, async () => {
    throw Error("must not send");
  });
  assert(events.join(",") === "skipped_mute,archived");
});
Deno.test("retry budget produces archived failure", async () => {
  const { s, events } = store();
  await processJob(
    { ...job, read_ct: 5 },
    s,
    async () => ({ status: "failed", retryable: true }),
  );
  assert(events.join(",") === "failed,archived");
});
Deno.test("bad request does not delete a valid token", async () => {
  const r = await sendFcm(
    job,
    "token",
    "project",
    "oauth",
    (() =>
      Promise.resolve(Response.json(
        { error: { status: "INVALID_ARGUMENT" } },
        { status: 400 },
      ))) as typeof fetch,
  );
  assert(r.status === "failed" && !r.retryable);
});
Deno.test("UNREGISTERED revokes the exact device after recording outcome", async () => {
  const { s, events } = store();
  const r = await sendFcm(
    job,
    "token",
    "project",
    "oauth",
    (() =>
      Promise.resolve(Response.json(
        {
          error: {
            details: [{
              "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
              errorCode: "UNREGISTERED",
            }],
          },
        },
        { status: 404 },
      ))) as typeof fetch,
  );
  await processJob(job, s, async () => r);
  assert(events.join(",") === "invalid_token,revoked,archived");
});
Deno.test("new types retain rendered copy and stable collapse identity", () => {
  const m = fcmMessage(job, "token").message;
  assert(m.notification.body === "Rendered once");
  assert(m.data.route === "/notifications");
  assert(m.android.notification.tag === "notification");
  assert(m.android.priority === "NORMAL");
});
