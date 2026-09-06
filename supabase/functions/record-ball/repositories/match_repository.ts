// Repository for isolated database queries and transactions in record-ball.

import type { RecordDeliveryInput } from "../schemas/record_ball_schema.ts";

export class MatchRepository {
  // deno-lint-ignore no-explicit-any
  async checkWriterEntitlement(tx: any, matchId: string, inningsNumber: number): Promise<boolean> {
    const rows = await tx`
      select public._can_score_innings(${matchId}::uuid, ${inningsNumber}::integer) as allowed`;
    return rows[0]?.allowed === true;
  }

  // deno-lint-ignore no-explicit-any
  async lockInningsState(
    tx: any,
    matchId: string,
    inningsNumber: number,
  ): Promise<{ inningsId: string; version: number } | null> {
    const rows = await tx`
      select innings_id, version
        from match_innings_state
       where match_id = ${matchId} and innings_number = ${inningsNumber}
       for update`;
    if (rows.length === 0) return null;
    return {
      inningsId: rows[0].innings_id as string,
      version: Number(rows[0].version),
    };
  }

  // deno-lint-ignore no-explicit-any
  async getMatch(tx: any, matchId: string) {
    const rows = await tx`
      select status, toss_won_by, toss_decision, team_a_id, team_b_id, format
        from matches where match_id = ${matchId}`;
    return rows[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async getNextDeliverySeq(tx: any, inningsId: string): Promise<number> {
    const rows = await tx`
      select coalesce(max(seq), 0) + 1 as next_seq
        from match_deliveries where innings_id = ${inningsId}`;
    return Number(rows[0]?.next_seq ?? 1);
  }

  // deno-lint-ignore no-explicit-any
  // One column per fact. This used to write every value twice — into
  // delivery_type AND ball_type, runs_off_bat AND runs_scored, striker_id AND
  // batsman_id, recorded_by AND created_by — because the table carried both
  // spellings. total_runs is GENERATED from runs_off_bat + extra_runs, so the
  // pairs disagreeing would have silently corrupted the innings total. The
  // alias columns were dropped 2026-09-06.
  async insertDelivery(
    tx: any,
    input: RecordDeliveryInput,
    inningsId: string,
    nextSeq: number,
    actor: string,
  ) {
    const isFour = input.runsScored === 4;
    const isSix = input.runsScored === 6;
    const isBoundary = isFour || isSix;

    const inserted = await tx`
      insert into match_deliveries (
        innings_id, match_id, innings_number, seq,
        over_number, ball_in_over, is_legal_delivery, delivery_type,
        runs_off_bat, extra_runs, is_free_hit,
        is_wicket, wicket_type, is_four, is_six, is_boundary,
        striker_id, non_striker_id, bowler_id, fielder_id,
        idempotency_key, commentary, recorded_by
      ) values (
        ${inningsId}, ${input.matchId}, ${input.inningsNumber}, ${nextSeq},
        ${input.overNumber}, ${input.ballInOver},
        ${input.isLegalDelivery},
        ${input.ballType},
        ${input.runsScored},
        ${input.extras},
        ${input.isFreeHit},
        ${input.isWicket},
        ${input.wicketType},
        ${isFour}, ${isSix}, ${isBoundary},
        ${input.batsmanId}, ${input.nonStrikerId}, ${input.bowlerId},
        ${input.fielderId},
        ${input.idempotencyKey}, ${input.commentary},
        ${actor}
      )
      on conflict (innings_id, idempotency_key) do nothing
      returning *`;
    return inserted[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async findDeliveryByIdempotencyKey(tx: any, inningsId: string, idempotencyKey: string) {
    const existing = await tx`
      select * from match_deliveries
       where innings_id = ${inningsId} and idempotency_key = ${idempotencyKey}`;
    return existing[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async insertWicket(
    tx: any,
    deliveryId: string,
    inningsId: string,
    input: RecordDeliveryInput,
  ): Promise<void> {
    await tx`
      insert into match_wickets (
        delivery_id, innings_id, player_out_id, dismissal_kind,
        is_bowler_credited, credited_bowler_id, primary_fielder_id,
        fall_of_wicket_score, fall_of_wicket_number, fall_of_wicket_overs
      )
      select
        ${deliveryId}, ${inningsId},
        ${input.dismissedPlayerId ?? input.batsmanId},
        ${input.wicketType!},
        ${input.isBowlerCredited},
        ${input.bowlerId},
        ${input.fielderId},
        coalesce(sum(d.runs_off_bat + d.extra_runs), 0)::int,
        count(*) filter (where d.is_wicket)::int,
        round(
          (count(*) filter (where d.is_legal_delivery))::numeric
          / greatest(${input.ballsPerOver}, 1), 1
        )
      from match_deliveries d
      where d.innings_id = ${inningsId} and d.is_undone = false
      on conflict do nothing`;
  }

  // deno-lint-ignore no-explicit-any
  async resumInningsState(
    tx: any,
    inningsId: string,
    input: RecordDeliveryInput,
  ) {
    const updated = await tx`
      update match_innings_state s set
        total_runs       = agg.runs,
        total_wickets    = agg.wickets,
        legal_ball_count = agg.legal,
        total_wides      = agg.wides,
        total_no_balls   = agg.no_balls,
        total_byes       = agg.byes,
        total_leg_byes   = agg.leg_byes,
        total_penalties  = agg.penalties,
        striker_id       = ${input.strikerAfter},
        non_striker_id   = ${input.nonStrikerAfter},
        bowler_id        = ${input.bowlerAfter},
        is_all_out       = ${input.isAllOut},
        version          = s.version + 1,
        updated_at       = now()
      from (
        select
          coalesce(sum(runs_off_bat + extra_runs), 0)::int as runs,
          (count(*) filter (where is_wicket))::int as wickets,
          (count(*) filter (where is_legal_delivery))::int as legal,
          coalesce(sum(extra_runs) filter (where delivery_type = 'wide'), 0)::int as wides,
          coalesce(sum(extra_runs) filter (where delivery_type = 'no_ball'), 0)::int as no_balls,
          coalesce(sum(extra_runs) filter (where delivery_type = 'bye'), 0)::int as byes,
          coalesce(sum(extra_runs) filter (where delivery_type = 'leg_bye'), 0)::int as leg_byes,
          coalesce(sum(extra_runs) filter (where delivery_type = 'penalty'), 0)::int as penalties
        from match_deliveries
        where innings_id = ${inningsId} and is_undone = false
      ) agg
      where s.innings_id = ${inningsId}
      returning s.*`;
    return updated[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async getInningsStates(tx: any, matchId: string) {
    return await tx`
      select innings_number, total_runs, total_wickets, legal_ball_count, is_all_out
        from match_innings_state
       where match_id = ${matchId}
       order by innings_number`;
  }

  // deno-lint-ignore no-explicit-any
  async setMatchStatusInningsBreak(tx: any, matchId: string): Promise<void> {
    await tx`
      update matches set status = 'innings_break', updated_at = now()
       where match_id = ${matchId}`;
  }

  // deno-lint-ignore no-explicit-any
  async setMatchCompleted(tx: any, matchId: string, result: unknown): Promise<void> {
    await tx`
      update matches set
        status = 'completed',
        end_time = now(),
        updated_at = now(),
        result = ${tx.json(result)}
       where match_id = ${matchId}`;
  }
}

export const matchRepository = new MatchRepository();
