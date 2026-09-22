// Repository for isolated database queries and transactions in record-ball.

import type { RecordDeliveryInput } from "../schemas/record_ball_schema.ts";

export class MatchRepository {
  // deno-lint-ignore no-explicit-any
  async getOrIncrementRevision(
    tx: any,
    matchId: string,
    readOnly: boolean,
  ): Promise<number> {
    const rows = readOnly
      ? await tx`
          select state_revision
          from public.cricket_matches
          where match_id = ${matchId}::uuid
        `
      : await tx`
          update public.cricket_matches
          set state_revision = state_revision + 1,
              updated_at = now()
          where match_id = ${matchId}::uuid
          returning state_revision
        `;
    return Number(rows[0]?.state_revision ?? 0);
  }

  // deno-lint-ignore no-explicit-any
  async checkWriterEntitlement(
    tx: any,
    matchId: string,
    inningsNumber: number,
  ): Promise<boolean> {
    const rows = await tx`
      select public._can_score_innings(
        ${matchId}::uuid,
        ${inningsNumber}::integer
      ) as allowed
    `;

    return rows[0]?.allowed === true;
  }

  // deno-lint-ignore no-explicit-any
  async lockInningsState(
    tx: any,
    matchId: string,
    inningsNumber: number,
  ): Promise<
    {
      inningsId: string;
      version: number;
    } | null
  > {
    const rows = await tx`
      select
        innings_id,
        version
      from public.cricket_match_innings_state
      where match_id = ${matchId}::uuid
        and innings_number =
              ${inningsNumber}
      for update
    `;

    if (rows.length === 0) {
      return null;
    }

    return {
      inningsId: rows[0].innings_id as string,
      version: Number(rows[0].version),
    };
  }

  // Canonical side mapping is match_teams. UUID aliases are loaded only for
  // in-memory scoring/result calculations.
  // deno-lint-ignore no-explicit-any
  async getMatch(
    tx: any,
    matchId: string,
  ) {
    const rows = await tx`
      select
        m.status,
        m.winner_side,

        team_a.team_id
          as team_a_id,
        team_b.team_id
          as team_b_id,

        cm.toss_won_by,
        cm.toss_decision,
        cm.rules_snapshot
          as format

      from public.matches m

      join public.match_teams team_a
        on team_a.match_id = m.match_id
       and team_a.team_side = 'team_a'

      join public.match_teams team_b
        on team_b.match_id = m.match_id
       and team_b.team_side = 'team_b'

      join public.cricket_matches cm
        on cm.match_id = m.match_id

      where m.match_id =
              ${matchId}::uuid
        and m.sport_id = 'cricket'

      for update of
        m,
        team_a,
        team_b,
        cm
    `;

    return rows[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async getCricketMatchDetails(
    tx: any,
    matchId: string,
  ) {
    const rows = await tx`
      select *
      from public.cricket_match_details
      where match_id =
              ${matchId}::uuid
    `;

    return rows[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async getNextDeliverySeq(
    tx: any,
    inningsId: string,
  ): Promise<number> {
    const rows = await tx`
      select
        coalesce(max(seq), 0) + 1
          as next_seq
      from public.cricket_match_deliveries
      where innings_id =
              ${inningsId}::uuid
    `;

    return Number(
      rows[0]?.next_seq ?? 1,
    );
  }

  // deno-lint-ignore no-explicit-any
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
      insert into public.cricket_match_deliveries (
        innings_id,
        match_id,
        innings_number,
        seq,
        over_number,
        ball_in_over,
        is_legal_delivery,
        delivery_type,
        runs_off_bat,
        extra_runs,
        is_free_hit,
        is_wicket,
        wicket_type,
        is_four,
        is_six,
        is_boundary,
        striker_id,
        non_striker_id,
        bowler_id,
        fielder_id,
        idempotency_key,
        commentary,
        recorded_by
      )
      values (
        ${inningsId}::uuid,
        ${input.matchId}::uuid,
        ${input.inningsNumber},
        ${nextSeq},
        ${input.overNumber},
        ${input.ballInOver},
        ${input.isLegalDelivery},
        ${input.ballType},
        ${input.runsScored},
        ${input.extras},
        ${input.isFreeHit},
        ${input.isWicket},
        ${input.wicketType},
        ${isFour},
        ${isSix},
        ${isBoundary},
        ${input.batsmanId}::uuid,
        ${input.nonStrikerId}::uuid,
        ${input.bowlerId}::uuid,
        ${input.fielderId}::uuid,
        ${input.idempotencyKey},
        ${input.commentary},
        ${actor}::uuid
      )
      on conflict (
        innings_id,
        idempotency_key
      )
      do nothing
      returning *
    `;

    return inserted[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async findDeliveryByIdempotencyKey(
    tx: any,
    inningsId: string,
    idempotencyKey: string,
  ) {
    const existing = await tx`
      select *
      from public.cricket_match_deliveries
      where innings_id =
              ${inningsId}::uuid
        and idempotency_key =
              ${idempotencyKey}
    `;

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
      insert into public.cricket_match_wickets (
        delivery_id,
        innings_id,
        player_out_id,
        dismissal_kind,
        is_bowler_credited,
        credited_bowler_id,
        primary_fielder_id,
        fall_of_wicket_score,
        fall_of_wicket_number,
        fall_of_wicket_overs
      )
      select
        ${deliveryId}::uuid,
        ${inningsId}::uuid,
        ${
      input.dismissedPlayerId ??
        input.batsmanId
    }::uuid,
        ${input.wicketType!},
        ${input.isBowlerCredited},
        ${input.bowlerId}::uuid,
        ${input.fielderId}::uuid,
        coalesce(
          sum(
            d.runs_off_bat +
            d.extra_runs
          ),
          0
        )::int,
        count(*) filter (
          where d.is_wicket
        )::int,
        round(
          (
            count(*) filter (
              where d.is_legal_delivery
            )
          )::numeric
          / greatest(
              ${input.ballsPerOver},
              1
            ),
          1
        )
      from public.cricket_match_deliveries d
      where d.innings_id =
              ${inningsId}::uuid
        and d.is_undone = false
      on conflict do nothing
    `;
  }

  // deno-lint-ignore no-explicit-any
  async resumInningsState(
    tx: any,
    inningsId: string,
    input: RecordDeliveryInput,
  ) {
    const updated = await tx`
      update public.cricket_match_innings_state s
      set
        total_runs =
          agg.runs,
        total_wickets =
          agg.wickets,
        legal_ball_count =
          agg.legal,
        total_wides =
          agg.wides,
        total_no_balls =
          agg.no_balls,
        total_byes =
          agg.byes,
        total_leg_byes =
          agg.leg_byes,
        total_penalties =
          agg.penalties,
        striker_id =
          ${input.strikerAfter}::uuid,
        non_striker_id =
          ${input.nonStrikerAfter}::uuid,
        bowler_id =
          ${input.bowlerAfter}::uuid,
        is_all_out =
          ${input.isAllOut},
        version =
          s.version + 1,
        updated_at = now()

      from (
        select
          coalesce(
            sum(
              runs_off_bat +
              extra_runs
            ),
            0
          )::int as runs,

          (
            count(*) filter (
              where is_wicket
            )
          )::int as wickets,

          (
            count(*) filter (
              where is_legal_delivery
            )
          )::int as legal,

          coalesce(
            sum(extra_runs)
            filter (
              where delivery_type =
                    'wide'
            ),
            0
          )::int as wides,

          coalesce(
            sum(extra_runs)
            filter (
              where delivery_type =
                    'no_ball'
            ),
            0
          )::int as no_balls,

          coalesce(
            sum(extra_runs)
            filter (
              where delivery_type =
                    'bye'
            ),
            0
          )::int as byes,

          coalesce(
            sum(extra_runs)
            filter (
              where delivery_type =
                    'leg_bye'
            ),
            0
          )::int as leg_byes,

          coalesce(
            sum(extra_runs)
            filter (
              where delivery_type =
                    'penalty'
            ),
            0
          )::int as penalties

        from public.cricket_match_deliveries
        where innings_id =
                ${inningsId}::uuid
          and is_undone = false
      ) agg

      where s.innings_id =
              ${inningsId}::uuid
      returning s.*
    `;

    return updated[0] ?? null;
  }

  // deno-lint-ignore no-explicit-any
  async getInningsStates(
    tx: any,
    matchId: string,
  ) {
    return await tx`
      select
        innings_number,
        total_runs,
        total_wickets,
        legal_ball_count,
        is_all_out
      from public.cricket_match_innings_state
      where match_id =
              ${matchId}::uuid
      order by innings_number
    `;
  }

  // deno-lint-ignore no-explicit-any
  async setMatchStatusInningsBreak(
    tx: any,
    matchId: string,
  ): Promise<void> {
    await tx`
      update public.cricket_matches
      set
        phase = 'innings_break',
        updated_at = now()
      where match_id =
              ${matchId}::uuid
    `;

    await tx`
      update public.matches
      set
        status = 'live',
        updated_at = now()
      where match_id =
              ${matchId}::uuid
    `;
  }

  // deno-lint-ignore no-explicit-any
  async setMatchCompleted(
    tx: any,
    matchId: string,
    result: unknown,
  ): Promise<void> {
    const r = (result ?? {}) as Record<string, unknown>;

    const winnerSide = r.winner_side === "team_a" ||
        r.winner_side === "team_b"
      ? r.winner_side
      : null;

    const description = typeof r.description === "string"
      ? r.description
      : null;

    await tx`
      update public.cricket_matches
      set
        phase = 'complete',
        result =
          ${tx.json(result)},
        result_summary =
          ${description},
        updated_at = now()
      where match_id =
              ${matchId}::uuid
    `;

    await tx`
      update public.matches
      set
        status = 'completed',
        completed_at = now(),
        winner_side =
          ${winnerSide},
        updated_at = now()
      where match_id =
              ${matchId}::uuid
    `;

    if (winnerSide) {
      await this.advanceWinner(
        tx,
        matchId,
        winnerSide,
      );
    }
  }

  // Tournament bracket propagation uses canonical match_teams and immediately
  // materializes the winning team into the future fixture's participant rows.
  // deno-lint-ignore no-explicit-any
  private async advanceWinner(
    tx: any,
    sourceMatchId: string,
    winnerSide: "team_a" | "team_b",
  ): Promise<void> {
    const winnerRows = await tx`
      select team_id
      from public.match_teams
      where match_id =
              ${sourceMatchId}::uuid
        and team_side =
              ${winnerSide}
      limit 1
    `;

    const winnerTeamId = winnerRows[0]?.team_id as string | null | undefined;

    if (!winnerTeamId) {
      return;
    }

    const targets = await tx`
      select
        m.match_id,
        m.status::text as status,
        case
          when m.prev_match_a_id =
                 ${sourceMatchId}::uuid
            then 'team_a'
          when m.prev_match_b_id =
                 ${sourceMatchId}::uuid
            then 'team_b'
        end as target_side
      from public.matches m
      where m.prev_match_a_id =
              ${sourceMatchId}::uuid
         or m.prev_match_b_id =
              ${sourceMatchId}::uuid
      for update
    `;

    for (const target of targets) {
      if (!target.target_side) {
        continue;
      }

      if (target.status !== "scheduled") {
        throw new Error(
          "Cannot advance a winner into a bracket match that has already started",
        );
      }

      await tx`
        delete from public.match_players
        where match_id =
                ${target.match_id}::uuid
          and team_side =
                ${target.target_side}
      `;

      await tx`
        update public.match_teams
        set team_id =
              ${winnerTeamId}::uuid
        where match_id =
                ${target.match_id}::uuid
          and team_side =
                ${target.target_side}
      `;

      await tx`
        insert into public.match_players (
          match_id,
          team_side,
          user_id,
          unclaimed_id,
          display_name,
          jersey_number
        )
        select
          ${target.match_id}::uuid,
          ${target.target_side},
          tm.user_id,
          tm.unclaimed_id,
          coalesce(
            pr.display_name,
            up.display_name,
            'Player'
          ),
          tm.jersey_number
        from public.team_members tm
        join public.matches m
          on m.match_id =
             ${target.match_id}::uuid
        left join public.tournament_teams tt
          on tt.tournament_id = m.tournament_id
         and tt.team_id =
             ${winnerTeamId}::uuid
         and tt.status = 'approved'
        left join public.profiles pr
          on pr.user_id = tm.user_id
        left join public.unclaimed_players up
          on up.unclaimed_id = tm.unclaimed_id
        where tm.team_id =
                ${winnerTeamId}::uuid
          and tm.status = 'active'
          and tm.in_squad = true
          and (
            m.tournament_id is null
            or coalesce(
                 cardinality(tt.squad),
                 0
               ) = 0
            or tm.user_id = any(tt.squad)
            or tm.unclaimed_id = any(tt.squad)
          )
      `;

      await tx`
        insert into public.cricket_match_players (
          match_player_id,
          match_id,
          is_captain,
          is_vice_captain,
          is_wicket_keeper
        )
        select
          mp.match_player_id,
          mp.match_id,
          coalesce(
            mp.user_id =
              public._team_current_captain(
                ${winnerTeamId}::uuid
              ),
            false
          ),
          false,
          false
        from public.match_players mp
        join public.matches m
          on m.match_id = mp.match_id
        where mp.match_id =
                ${target.match_id}::uuid
          and mp.team_side =
                ${target.target_side}
          and m.sport_id = 'cricket'
      `;
    }
  }
}

export const matchRepository = new MatchRepository();
