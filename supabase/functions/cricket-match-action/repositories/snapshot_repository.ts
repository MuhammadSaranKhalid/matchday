import type { Tx } from "../types.ts";

export class SnapshotRepository {
  async match(
    tx: Tx,
    matchId: string,
  ): Promise<unknown> {
    const rows = await tx`
      select *
      from public.cricket_match_details
      where match_id = ${matchId}::uuid
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
      where match_id = ${matchId}::uuid
        and innings_number = ${inningsNumber}
      limit 1
    `;
    return rows[0] ?? null;
  }
}
