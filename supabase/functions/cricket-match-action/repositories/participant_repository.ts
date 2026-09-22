import type { TeamSide, Tx } from "../types.ts";

export interface CreatedParticipant {
  participant: Record<string, unknown>;
  revision: number;
}

export class ParticipantRepository {
  async findByIdempotencyKey(
    tx: Tx,
    matchId: string,
    key: string,
  ): Promise<Record<string, unknown> | null> {
    const rows = await tx`
      select *
      from public.match_players
      where match_id = ${matchId}::uuid
        and creation_idempotency_key = ${key}
      limit 1
    `;
    return rows[0] ?? null;
  }

  async createMatchParticipant(
    tx: Tx,
    args: {
      matchId: string;
      side: TeamSide;
      displayName: string;
      idempotencyKey: string;
      actorId: string;
    },
  ): Promise<CreatedParticipant> {
    const identities = await tx`
      insert into public.unclaimed_players (
        sport_id,
        display_name,
        added_by
      )
      values (
        'cricket',
        ${args.displayName},
        ${args.actorId}::uuid
      )
      returning unclaimed_id
    `;

    const unclaimedId = identities[0].unclaimed_id as string;

    const players = await tx`
      insert into public.match_players (
        match_id,
        team_side,
        unclaimed_id,
        display_name,
        source,
        added_by,
        creation_idempotency_key
      )
      values (
        ${args.matchId}::uuid,
        ${args.side},
        ${unclaimedId}::uuid,
        ${args.displayName},
        'match_added',
        ${args.actorId}::uuid,
        ${args.idempotencyKey}
      )
      returning *
    `;

    const participant = players[0] as Record<string, unknown>;

    await tx`
      insert into public.cricket_match_players (
        match_player_id,
        match_id,
        is_playing_xi
      )
      values (
        ${participant.match_player_id}::uuid,
        ${args.matchId}::uuid,
        true
      )
    `;

    const revisions = await tx`
      update public.cricket_matches
      set state_revision = state_revision + 1,
          updated_at = now()
      where match_id = ${args.matchId}::uuid
      returning state_revision
    `;

    return {
      participant,
      revision: Number(revisions[0].state_revision),
    };
  }
}
