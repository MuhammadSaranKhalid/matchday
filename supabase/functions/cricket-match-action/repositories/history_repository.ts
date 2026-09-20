import type {
  MatchLifecycle,
  Tx,
} from "../types.ts";

export class HistoryRepository {
  async recordResultTransition(
    tx: Tx,
    args: {
      matchId: string;
      previousStatus: MatchLifecycle;
      newStatus: MatchLifecycle;
      resultPayload: Record<string, unknown>;
      reason: string | null;
      actorId: string;
    },
  ): Promise<void> {
    await tx`
      insert into public.match_result_history (
        match_id,
        previous_status,
        new_status,
        result_payload,
        reason,
        recorded_by
      )
      values (
        ${args.matchId}::uuid,
        ${args.previousStatus}::public.match_status,
        ${args.newStatus}::public.match_status,
        ${tx.json(args.resultPayload)},
        ${args.reason},
        ${args.actorId}::uuid
      )
    `;
  }
}
