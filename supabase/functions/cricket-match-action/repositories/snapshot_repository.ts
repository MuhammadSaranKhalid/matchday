import type { Tx } from "../types.ts";

export class SnapshotRepository {
  async room(
    tx: Tx,
    matchId: string,
  ): Promise<unknown> {
    const rows = await tx`
      select public.get_match_room_snapshot(
        ${matchId}::uuid
      ) as snapshot
    `;
    return rows[0]?.snapshot ?? null;
  }
  async match(
    tx: Tx,
    matchId: string,
  ): Promise<unknown> {
    const rows = await tx`
      select *
      from public.cricket_match_details
      where match_id =
              ${matchId}::uuid
      limit 1
    `;

    return rows[0] ?? null;
  }

  async innings(
    tx: Tx,
    matchId: string,
    inningsNumber: number,
  ): Promise<unknown> {
    const rows = await tx`
      select *
      from public.cricket_match_innings_state
      where match_id =
              ${matchId}::uuid
        and innings_number =
              ${inningsNumber}
      limit 1
    `;

    return rows[0] ?? null;
  }
}
