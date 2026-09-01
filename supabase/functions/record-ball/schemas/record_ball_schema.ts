// Schema validation and DTO parser for record-ball API endpoint.

export interface RecordDeliveryInput {
  matchId: string;
  inningsNumber: number;
  idempotencyKey: string;

  // Delivery as entered by scorer
  isLegalDelivery: boolean;
  ballType: string;
  runsScored: number;
  extras: number;
  isWicket: boolean;
  wicketType: string | null;
  dismissedPlayerId: string | null;
  batsmanId: string | null;
  nonStrikerId: string | null;
  bowlerId: string | null;
  fielderId: string | null;
  commentary: string | null;

  // Computed state from device engine
  overNumber: number;
  ballInOver: number;
  isFreeHit: boolean;
  isBowlerCredited: boolean;
  ballsPerOver: number;
  strikerAfter: string | null;
  nonStrikerAfter: string | null;
  bowlerAfter: string | null;
  isAllOut: boolean;
  inningsEnded: boolean;
}

export interface ValidationError {
  field: string;
  message: string;
}

export function parseAndValidateRecordBall(
  body: Record<string, unknown>,
  idempotencyHeader?: string | null,
): { data?: RecordDeliveryInput; error?: { code: string; message: string; details?: ValidationError[] } } {
  // Support clean REST fields with fallback to legacy p_* fields
  const matchId = (body.match_id ?? body.p_match_id) as string | undefined;
  const rawInningsNumber = body.innings_number ?? body.p_innings_number;
  const inningsNumber = Number(rawInningsNumber);
  const idempotencyKey = (
    idempotencyHeader ?? body.idempotency_key ?? body.p_idempotency_key
  ) as string | undefined;

  const errors: ValidationError[] = [];

  if (!matchId || typeof matchId !== "string" || matchId.trim().length === 0) {
    errors.push({ field: "match_id", message: "match_id is required" });
  }

  if (rawInningsNumber === undefined || !Number.isFinite(inningsNumber) || inningsNumber < 1) {
    errors.push({ field: "innings_number", message: "innings_number must be an integer >= 1" });
  }

  if (!idempotencyKey || typeof idempotencyKey !== "string" || idempotencyKey.trim().length === 0) {
    errors.push({
      field: "idempotency_key",
      message: "idempotency_key (or Idempotency-Key header) is required",
    });
  }

  if (errors.length > 0) {
    return {
      error: {
        code: "VALIDATION_FAILED",
        message: "Invalid request payload",
        details: errors,
      },
    };
  }

  // Delivery attributes (clean nested delivery or top-level)
  const delivery = (body.delivery ?? {}) as Record<string, unknown>;
  const computed = (body.computed ?? {}) as Record<string, unknown>;

  const isLegalDelivery = (delivery.is_legal ?? body.is_legal_delivery ?? body.p_is_legal_delivery) === true;
  const ballType = String(delivery.ball_type ?? body.ball_type ?? body.p_ball_type ?? "legal");
  const runsScored = num(delivery.runs_scored ?? body.runs_scored ?? body.p_runs_scored, 0);
  const extras = num(delivery.extras ?? body.extras ?? body.p_extras, 0);
  const isWicket = (delivery.is_wicket ?? body.is_wicket ?? body.p_is_wicket) === true;
  const wicketType = (delivery.wicket_type ?? body.wicket_type ?? body.p_wicket_type ?? null) as string | null;
  const dismissedPlayerId = (delivery.dismissed_player_id ?? body.dismissed_player_id ?? body.p_dismissed_player_id ?? null) as string | null;
  const batsmanId = (delivery.batsman_id ?? body.batsman_id ?? body.p_batsman_id ?? null) as string | null;
  const nonStrikerId = (delivery.non_striker_id ?? body.non_striker_id ?? body.p_non_striker_id ?? null) as string | null;
  const bowlerId = (delivery.bowler_id ?? body.bowler_id ?? body.p_bowler_id ?? null) as string | null;
  const fielderId = (delivery.fielder_id ?? body.fielder_id ?? body.p_fielder_id ?? null) as string | null;
  const commentary = (delivery.commentary ?? body.commentary ?? body.p_commentary ?? null) as string | null;

  // Computed delivery metrics
  const overNumber = num(computed.over_number ?? body.over_number ?? body.p_over_number, 0);
  const ballInOver = num(computed.ball_in_over ?? body.ball_in_over ?? body.p_ball_in_over, 0);
  const isFreeHit = (computed.is_free_hit ?? body.is_free_hit ?? body.p_is_free_hit) === true;
  const isBowlerCredited = (computed.is_bowler_credited ?? body.is_bowler_credited ?? body.p_is_bowler_credited) === true;
  const ballsPerOver = num(computed.balls_per_over ?? body.balls_per_over ?? body.p_balls_per_over, 6);
  const strikerAfter = (computed.striker_after ?? body.striker_after ?? body.p_striker_after ?? null) as string | null;
  const nonStrikerAfter = (computed.non_striker_after ?? body.non_striker_after ?? body.p_non_striker_after ?? null) as string | null;
  const bowlerAfter = (computed.bowler_after ?? body.bowler_after ?? body.p_bowler_after ?? null) as string | null;
  const isAllOut = (computed.is_all_out ?? body.is_all_out ?? body.p_is_all_out) === true;
  const inningsEnded = (computed.innings_ended ?? body.innings_ended ?? body.p_innings_ended) === true;

  return {
    data: {
      matchId: matchId!,
      inningsNumber: inningsNumber!,
      idempotencyKey: idempotencyKey!,
      isLegalDelivery,
      ballType,
      runsScored,
      extras,
      isWicket,
      wicketType,
      dismissedPlayerId,
      batsmanId,
      nonStrikerId,
      bowlerId,
      fielderId,
      commentary,
      overNumber,
      ballInOver,
      isFreeHit,
      isBowlerCredited,
      ballsPerOver,
      strikerAfter,
      nonStrikerAfter,
      bowlerAfter,
      isAllOut,
      inningsEnded,
    },
  };
}

function num(v: unknown, fallback: number): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}
