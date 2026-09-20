import type {
  Action,
  TransactionOutput,
} from "../types.ts";

// Realtime is deliberately OUTSIDE the SQL transaction.
//
// PostgreSQL commit is authoritative. If Ably is unavailable, persistence still
// succeeds and clients can recover by snapshot reads/polling.
export async function publishAfterCommit(
  matchId: string,
  action: Action,
  out: TransactionOutput,
): Promise<void> {
  const key = Deno.env.get("ABLY_API_KEY");

  if (!key) {
    console.warn(
      "[cricket-match-action] ABLY_API_KEY not configured",
    );
    return;
  }

  try {
    const Ably =
      (await import("npm:ably@2.4.1")).default;
    const ably = new Ably.Rest(key);

    if (out.match) {
      await ably.channels
        .get(`match:${matchId}:state`)
        .publish(
          "match_state_updated",
          out.match,
        );
    }

    if (out.innings) {
      await ably.channels
        .get(`match:${matchId}:state`)
        .publish(
          "innings_state_updated",
          out.innings,
        );
    }

    if (
      action === "undo_last_ball" &&
      out.ballsResync &&
      out.inningsNumber != null
    ) {
      await ably.channels
        .get(`match:${matchId}:balls`)
        .publish(
          "balls_resync",
          {
            innings_number:
              out.inningsNumber,
          },
        );
    }
  } catch (error) {
    console.error(
      "[cricket-match-action] Ably publish failed",
      error,
    );
  }
}
