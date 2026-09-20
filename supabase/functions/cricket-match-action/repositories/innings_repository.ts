import type {
  TeamSide,
  Tx,
} from "../types.ts";

export class InningsRepository {
  async bothBattersAreInXi(
    tx: Tx,
    matchId: string,
    side: TeamSide,
    strikerId: string,
    nonStrikerId: string,
  ): Promise<boolean> {
    const rows = await tx`
      select count(*)::int as n
      from public.match_players mp
      join public.cricket_match_players cmp
        on cmp.match_player_id = mp.match_player_id
       and cmp.match_id = mp.match_id
      where mp.match_id = ${matchId}::uuid
        and mp.team_side = ${side}
        and cmp.is_playing_xi = true
        and mp.match_player_id in (
          ${strikerId}::uuid,
          ${nonStrikerId}::uuid
        )
    `;

    return Number(rows[0]?.n ?? 0) === 2;
  }

  async bowlerIsInXi(
    tx: Tx,
    matchId: string,
    side: TeamSide,
    bowlerId: string,
  ): Promise<boolean> {
    const rows = await tx`
      select exists (
        select 1
        from public.match_players mp
        join public.cricket_match_players cmp
          on cmp.match_player_id = mp.match_player_id
         and cmp.match_id = mp.match_id
        where mp.match_id = ${matchId}::uuid
          and mp.team_side = ${side}
          and cmp.is_playing_xi = true
          and mp.match_player_id = ${bowlerId}::uuid
      ) as allowed
    `;

    return rows[0]?.allowed === true;
  }

  async upsertInnings(
    tx: Tx,
    args: {
      matchId: string;
      inningsNumber: number;
      battingSide: TeamSide;
      bowlingSide: TeamSide;
      oversAllocated: number;
    },
  ): Promise<string> {
    const rows = await tx`
      insert into public.cricket_match_innings (
        match_id,
        innings_number,
        batting_team_side,
        bowling_team_side,
        overs_allocated
      )
      values (
        ${args.matchId}::uuid,
        ${args.inningsNumber},
        ${args.battingSide},
        ${args.bowlingSide},
        ${args.oversAllocated}
      )
      on conflict (match_id, innings_number)
      do update set
        batting_team_side =
          excluded.batting_team_side,
        bowling_team_side =
          excluded.bowling_team_side,
        overs_allocated =
          excluded.overs_allocated,
        updated_at = now()
      returning innings_id
    `;

    return rows[0].innings_id as string;
  }

  async upsertOpenersState(
    tx: Tx,
    args: {
      inningsId: string;
      matchId: string;
      inningsNumber: number;
      strikerId: string;
      nonStrikerId: string;
    },
  ): Promise<void> {
    await tx`
      insert into public.cricket_match_innings_state (
        innings_id,
        match_id,
        innings_number,
        striker_id,
        non_striker_id
      )
      values (
        ${args.inningsId}::uuid,
        ${args.matchId}::uuid,
        ${args.inningsNumber},
        ${args.strikerId}::uuid,
        ${args.nonStrikerId}::uuid
      )
      on conflict (innings_id)
      do update set
        striker_id = excluded.striker_id,
        non_striker_id = excluded.non_striker_id,
        version =
          public.cricket_match_innings_state.version + 1,
        updated_at = now()
    `;
  }

  async upsertLiveState(
    tx: Tx,
    args: {
      inningsId: string;
      matchId: string;
      inningsNumber: number;
      strikerId: string;
      nonStrikerId: string;
      bowlerId: string;
      target: number | null;
    },
  ): Promise<void> {
    await tx`
      insert into public.cricket_match_innings_state (
        innings_id,
        match_id,
        innings_number,
        striker_id,
        non_striker_id,
        bowler_id,
        target
      )
      values (
        ${args.inningsId}::uuid,
        ${args.matchId}::uuid,
        ${args.inningsNumber},
        ${args.strikerId}::uuid,
        ${args.nonStrikerId}::uuid,
        ${args.bowlerId}::uuid,
        ${args.target}
      )
      on conflict (innings_id)
      do update set
        striker_id = excluded.striker_id,
        non_striker_id = excluded.non_striker_id,
        bowler_id = excluded.bowler_id,
        target = coalesce(
          excluded.target,
          public.cricket_match_innings_state.target
        ),
        version =
          public.cricket_match_innings_state.version + 1,
        updated_at = now()
    `;
  }

  async hasLockedOpeners(
    tx: Tx,
    matchId: string,
    inningsNumber: number,
  ): Promise<boolean> {
    const rows = await tx`
      select exists (
        select 1
        from public.cricket_match_innings_state s
        where s.match_id = ${matchId}::uuid
          and s.innings_number = ${inningsNumber}
          and s.striker_id is not null
          and s.non_striker_id is not null
      ) as ready
    `;

    return rows[0]?.ready === true;
  }

  async lockState(
    tx: Tx,
    matchId: string,
    inningsNumber: number,
  ): Promise<{
    inningsId: string;
    version: number;
  } | null> {
    const rows = await tx`
      select innings_id, version
      from public.cricket_match_innings_state
      where match_id = ${matchId}::uuid
        and innings_number = ${inningsNumber}
      for update
    `;

    if (rows.length === 0) return null;

    return {
      inningsId: rows[0].innings_id as string,
      version: Number(rows[0].version),
    };
  }

  async deleteLatestDelivery(
    tx: Tx,
    matchId: string,
    inningsNumber: number,
  ): Promise<Record<string, unknown> | null> {
    const rows = await tx`
      with target as (
        select delivery_id
        from public.cricket_match_deliveries
        where match_id = ${matchId}::uuid
          and innings_number = ${inningsNumber}
          and is_undone = false
        order by seq desc
        limit 1
      )
      delete from public.cricket_match_deliveries d
      using target
      where d.delivery_id = target.delivery_id
      returning d.*
    `;

    return rows[0] ?? null;
  }

  async recomputeStateAfterUndo(
    tx: Tx,
    args: {
      matchId: string;
      inningsNumber: number;
      deleted: Record<string, unknown>;
    },
  ): Promise<void> {
    const deleted = args.deleted;

    await tx`
      update public.cricket_match_innings_state s
      set
        total_runs = agg.runs,
        total_wickets = agg.wickets,
        legal_ball_count = agg.legal,
        total_wides = agg.wides,
        total_no_balls = agg.no_balls,
        total_byes = agg.byes,
        total_leg_byes = agg.leg_byes,
        total_penalties = agg.penalties,

        striker_id = coalesce(
          ${deleted.striker_id ?? null}::uuid,
          s.striker_id
        ),
        non_striker_id = coalesce(
          ${deleted.non_striker_id ?? null}::uuid,
          s.non_striker_id
        ),
        bowler_id = coalesce(
          ${deleted.bowler_id ?? null}::uuid,
          s.bowler_id
        ),

        is_all_out = false,
        version = s.version + 1,
        updated_at = now()

      from (
        select
          coalesce(
            sum(runs_off_bat + extra_runs),
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
            sum(extra_runs) filter (
              where delivery_type = 'wide'
            ),
            0
          )::int as wides,

          coalesce(
            sum(extra_runs) filter (
              where delivery_type = 'no_ball'
            ),
            0
          )::int as no_balls,

          coalesce(
            sum(extra_runs) filter (
              where delivery_type = 'bye'
            ),
            0
          )::int as byes,

          coalesce(
            sum(extra_runs) filter (
              where delivery_type = 'leg_bye'
            ),
            0
          )::int as leg_byes,

          coalesce(
            sum(extra_runs) filter (
              where delivery_type = 'penalty'
            ),
            0
          )::int as penalties

        from public.cricket_match_deliveries
        where match_id = ${args.matchId}::uuid
          and innings_number = ${args.inningsNumber}
          and is_undone = false
      ) agg

      where s.match_id = ${args.matchId}::uuid
        and s.innings_number = ${args.inningsNumber}
    `;
  }

  async deleteAllForMatch(
    tx: Tx,
    matchId: string,
  ): Promise<void> {
    // State, deliveries and wickets cascade from the innings rows.
    await tx`
      delete from public.cricket_match_innings
      where match_id = ${matchId}::uuid
    `;
  }
}
