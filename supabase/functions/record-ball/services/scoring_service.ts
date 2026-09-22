// Scoring Service: business logic and transaction orchestration for ball recording.

import { db } from "../../_shared/db.ts";
import {
  computeResult,
  type InningsLine,
} from "../../_shared/scoring/result.ts";
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
    kind:
      | "none"
      | "innings_break"
      | "completed";
    result?: unknown;
  };
  duplicate: boolean;
  revision: number;
}

export class ScoringService {
  async recordDelivery(
    actorId: string,
    input: RecordDeliveryInput,
  ): Promise<RecordDeliveryResult> {
    const sql = db();

    return await sql.begin(
      async (tx) => {
        await setTransactionJwtClaims(
          tx,
          actorId,
        );

        const isAllowed = await matchRepository
          .checkWriterEntitlement(
            tx,
            input.matchId,
            input.inningsNumber,
          );

        if (!isAllowed) {
          throw new HttpSignal(
            403,
            "FORBIDDEN",
            "Only the batting side can score this innings",
          );
        }

        const lockedInnings = await matchRepository
          .lockInningsState(
            tx,
            input.matchId,
            input.inningsNumber,
          );

        if (!lockedInnings) {
          throw new HttpSignal(
            409,
            "INNINGS_NOT_STARTED",
            "Innings has not been started for this match",
          );
        }

        const inningsId = lockedInnings.inningsId;

        const match = await matchRepository.getMatch(
          tx,
          input.matchId,
        );

        if (!match) {
          throw new HttpSignal(
            404,
            "MATCH_NOT_FOUND",
            "Cricket match not found",
          );
        }

        if (
          [
            "completed",
            "abandoned",
            "cancelled",
          ].includes(
            match.status as string,
          )
        ) {
          throw new HttpSignal(
            409,
            "MATCH_FINALIZED",
            "Match is already finished",
          );
        }

        const nextSeq = await matchRepository
          .getNextDeliverySeq(
            tx,
            inningsId,
          );

        let ball = await matchRepository
          .insertDelivery(
            tx,
            input,
            inningsId,
            nextSeq,
            actorId,
          );

        let alreadyStored = false;

        if (!ball) {
          alreadyStored = true;

          ball = await matchRepository
            .findDeliveryByIdempotencyKey(
              tx,
              inningsId,
              input.idempotencyKey,
            );
        }

        if (
          !alreadyStored &&
          input.isWicket &&
          input.wicketType
        ) {
          await matchRepository
            .insertWicket(
              tx,
              ball.delivery_id,
              inningsId,
              input,
            );
        }

        const updatedState = await matchRepository
          .resumInningsState(
            tx,
            inningsId,
            input,
          );

        let transition: RecordDeliveryResult["transition"] = { kind: "none" };

        if (
          input.inningsEnded &&
          !alreadyStored
        ) {
          const fmt = (match.format ?? {}) as Record<string, unknown>;

          const inningsPerSide = Math.max(
            num(
              fmt.innings_per_side,
              1,
            ),
            1,
          );

          const isFinalInnings = input.inningsNumber >=
            inningsPerSide * 2;

          if (!isFinalInnings) {
            await matchRepository
              .setMatchStatusInningsBreak(
                tx,
                input.matchId,
              );

            transition = {
              kind: "innings_break",
            };
          } else {
            const innRows = await matchRepository
              .getInningsStates(
                tx,
                input.matchId,
              );

            const inningsLines = toInningsLines(
              innRows,
              match,
            );

            const res = computeResult(
              inningsLines,
              {
                oversPerInnings: num(
                  fmt.overs_per_innings,
                  0,
                ),
                playersPerTeam: num(
                  fmt.players_per_team,
                  11,
                ),
                ballsPerOver: num(
                  fmt.balls_per_over,
                  6,
                ),
                maxOversPerBowler: num(
                  fmt.max_overs_per_bowler,
                  0,
                ),
                inningsPerSide,
                ballType: (
                  fmt.ball_type as
                    | "leather"
                    | "tape"
                    | "tennis"
                ) ??
                  "leather",
                wicketsToAllOut: fmt.wickets_to_all_out !=
                    null
                  ? Number(
                    fmt.wickets_to_all_out,
                  )
                  : undefined,
              },
            );

            const winnerSide = res.winnerTeamId ==
                null
              ? null
              : res.winnerTeamId ===
                  match.team_a_id
              ? "team_a"
              : res.winnerTeamId ===
                  match.team_b_id
              ? "team_b"
              : null;

            if (
              res.winnerTeamId &&
              !winnerSide
            ) {
              throw new HttpSignal(
                500,
                "INVALID_RESULT_WINNER",
                "Scoring result winner is not one of the match sides",
              );
            }

            await matchRepository
              .setMatchCompleted(
                tx,
                input.matchId,
                {
                  winner_side: winnerSide,
                  win_type: res.winType,
                  win_margin: res.winMargin,
                  description: res.description,
                  summary: res.description,
                },
              );

            transition = {
              kind: "completed",
              result: res,
            };
          }
        }

        const matchSnapshot = await matchRepository
          .getCricketMatchDetails(
            tx,
            input.matchId,
          );

        const revision = await matchRepository.getOrIncrementRevision(
          tx,
          input.matchId,
          alreadyStored,
        );

        return {
          ball,
          innings: updatedState,
          match: matchSnapshot,
          transition,
          duplicate: alreadyStored,
          revision,
        };
      },
    );
  }
}

export const scoringService = new ScoringService();

function num(
  value: unknown,
  fallback: number,
): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

// toss_won_by is a SIDE. Team UUIDs are resolved through the two in-memory
// values that came from match_teams.
// deno-lint-ignore no-explicit-any
function toInningsLines(
  rows: any[],
  match: any,
): InningsLine[] {
  const teamA = (match?.team_a_id ?? null) as string | null;

  const teamB = (match?.team_b_id ?? null) as string | null;

  const tossSide = (match?.toss_won_by ?? null) as "team_a" | "team_b" | null;

  const decision = (match?.toss_decision ?? null) as string | null;

  const firstSide: "team_a" | "team_b" = !tossSide || !decision
    ? "team_a"
    : decision === "bat"
    ? tossSide
    : tossSide === "team_a"
    ? "team_b"
    : "team_a";

  const firstTeam = firstSide === "team_a" ? teamA : teamB;

  const secondTeam = firstSide === "team_a" ? teamB : teamA;

  return rows.map((row) => {
    const n = Number(
      row.innings_number,
    );

    return {
      inningsNumber: n,
      battingTeamId: (
        n % 2 === 1 ? firstTeam : secondTeam
      ) ?? "",
      runs: Number(row.total_runs),
      wickets: Number(row.total_wickets),
      legalBalls: Number(
        row.legal_ball_count,
      ),
      isAllOut: row.is_all_out === true,
    };
  });
}
