// Scoring Service: Business logic and transaction orchestration for ball recording.

import { db } from "../../_shared/db.ts";
import { computeResult, type InningsLine } from "../../_shared/scoring/result.ts";
import type { RecordDeliveryInput } from "../schemas/record_ball_schema.ts";
import { matchRepository } from "../repositories/match_repository.ts";
import { setTransactionJwtClaims } from "./auth_service.ts";

export class HttpSignal extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "HttpSignal";
  }
}

export interface RecordDeliveryResult {
  ball: unknown;
  innings: unknown;
  match: unknown;
  transition: {
    kind: "none" | "innings_break" | "completed";
    result?: unknown;
  };
  duplicate: boolean;
}

export class ScoringService {
  async recordDelivery(actorId: string, input: RecordDeliveryInput): Promise<RecordDeliveryResult> {
    const sql = db();

    return await sql.begin(async (tx) => {
      await setTransactionJwtClaims(tx, actorId);

      const isAllowed = await matchRepository.checkWriterEntitlement(
        tx,
        input.matchId,
        input.inningsNumber,
      );
      if (!isAllowed) {
        throw new HttpSignal(403, "FORBIDDEN", "Only the batting side can score this innings");
      }

      const lockedInnings = await matchRepository.lockInningsState(
        tx,
        input.matchId,
        input.inningsNumber,
      );
      if (!lockedInnings) {
        throw new HttpSignal(409, "INNINGS_NOT_STARTED", "Innings has not been started for this match");
      }
      const inningsId = lockedInnings.inningsId;

      // Reads the shared shell + cricket_matches extension.
      const match = await matchRepository.getMatch(tx, input.matchId);
      if (!match) {
        throw new HttpSignal(404, "MATCH_NOT_FOUND", "Cricket match not found");
      }
      if (["completed", "abandoned", "cancelled"].includes(match.status as string)) {
        throw new HttpSignal(409, "MATCH_FINALIZED", "Match is already finished");
      }

      const nextSeq = await matchRepository.getNextDeliverySeq(tx, inningsId);
      let ball = await matchRepository.insertDelivery(tx, input, inningsId, nextSeq, actorId);
      let alreadyStored = false;

      if (!ball) {
        alreadyStored = true;
        ball = await matchRepository.findDeliveryByIdempotencyKey(
          tx,
          inningsId,
          input.idempotencyKey,
        );
      }

      if (!alreadyStored && input.isWicket && input.wicketType) {
        await matchRepository.insertWicket(tx, ball.delivery_id, inningsId, input);
      }

      const updatedState = await matchRepository.resumInningsState(tx, inningsId, input);

      let transition: RecordDeliveryResult["transition"] = { kind: "none" };

      if (input.inningsEnded && !alreadyStored) {
        const fmt = (match.format ?? {}) as Record<string, unknown>;
        const inningsPerSide = Math.max(num(fmt.innings_per_side, 1), 1);
        const isFinalInnings = input.inningsNumber >= inningsPerSide * 2;

        if (!isFinalInnings) {
          await matchRepository.setMatchStatusInningsBreak(tx, input.matchId);
          transition = { kind: "innings_break" };
        } else {
          const innRows = await matchRepository.getInningsStates(tx, input.matchId);
          const inningsLines = toInningsLines(innRows, match);
          const res = computeResult(inningsLines, {
            oversPerInnings: num(fmt.overs_per_innings, 0),
            playersPerTeam: num(fmt.players_per_team, 11),
            ballsPerOver: num(fmt.balls_per_over, 6),
            maxOversPerBowler: num(fmt.max_overs_per_bowler, 0),
            inningsPerSide,
            ballType: (fmt.ball_type as "leather" | "tape" | "tennis") ?? "leather",
            wicketsToAllOut: fmt.wickets_to_all_out != null
              ? Number(fmt.wickets_to_all_out)
              : undefined,
          });

          await matchRepository.setMatchCompleted(tx, input.matchId, {
            winner_team_id: res.winnerTeamId,
            win_type: res.winType,
            win_margin: res.winMargin,
            description: res.description,
            summary: res.description,
          });
          transition = { kind: "completed", result: res };
        }
      }

      const matchSnapshot =
        await matchRepository.getCricketMatchDetails(tx, input.matchId);

      return {
        ball,
        innings: updatedState,
        match: matchSnapshot,
        transition,
        duplicate: alreadyStored,
      };
    });
  }
}

export const scoringService = new ScoringService();

function num(v: unknown, fallback: number): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

// deno-lint-ignore no-explicit-any
function toInningsLines(rows: any[], m: any): InningsLine[] {
  const teamA = (m?.team_a_id ?? null) as string | null;
  const teamB = (m?.team_b_id ?? null) as string | null;
  const tossWon = (m?.toss_won_by ?? null) as string | null;
  const decision = (m?.toss_decision ?? null) as string | null;
  const batsFirst = tossWon && decision
    ? (decision === "bat" ? tossWon : (tossWon === teamA ? teamB : teamA))
    : teamA;
  const other = batsFirst === teamA ? teamB : teamA;
  return rows.map((r) => {
    const n = Number(r.innings_number);
    return {
      inningsNumber: n,
      battingTeamId: (n % 2 === 1 ? batsFirst : other) ?? "",
      runs: Number(r.total_runs),
      wickets: Number(r.total_wickets),
      legalBalls: Number(r.legal_ball_count),
      isAllOut: r.is_all_out === true,
    };
  });
}
