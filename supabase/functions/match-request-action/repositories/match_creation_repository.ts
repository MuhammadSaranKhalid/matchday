// MatchCreationRepository — creates the normalized match aggregate.
//
// Ownership model:
//   1. INSERT into public.matches (sport-neutral shell only)
//   2. UPDATE public.match_teams to resolve the two team slots
//   3. INSERT into public.cricket_matches (Cricket rules and setup state)
//   4. CALL public.sync_match_participants(match_id) — canonical participant creation
//
// INVARIANTS enforced here:
//   - Does not write team_a_id or team_b_id (removed matches columns)
//   - Does not INSERT into public.match_players directly
//   - Does not INSERT into public.cricket_match_players directly
//   - Participant snapshot is exclusively owned by sync_match_participants(match_id).

import type { Tx } from "../types.ts";

export interface CreateMatchInput {
  venue: string | null;
  scheduledStartTime: string | null;
  formatCode: string;
  rules: Record<string, unknown>;
  teamAId: string;
  teamBId: string;
  actorId: string;
}

export class MatchCreationRepository {
  async createFriendlyCricketMatch(
    tx: Tx,
    input: CreateMatchInput,
  ): Promise<string> {
    // -----------------------------------------------------------------------
    // 1. Sport-neutral fixture shell — only the columns public.matches owns.
    // -----------------------------------------------------------------------
    const matchRows = await tx`
      insert into public.matches (
        match_type,
        tournament_id,
        venue,
        sport_id,
        scheduled_start_time,
        status,
        created_by
      ) values (
        'friendly',
        null,
        ${input.venue},
        'cricket',
        coalesce(${input.scheduledStartTime}::timestamptz, now()),
        'scheduled',
        ${input.actorId}::uuid
      )
      returning match_id as "matchId"
    `;

    const matchId: string = matchRows[0].matchId;

    // -----------------------------------------------------------------------
    // 2. Resolve the two stable team-side slots.
    //    The AFTER INSERT trigger on matches already created these rows.
    // -----------------------------------------------------------------------
    await tx`
      update public.match_teams
      set team_id = case team_side
        when 'team_a' then ${input.teamAId}::uuid
        when 'team_b' then ${input.teamBId}::uuid
      end
      where match_id = ${matchId}::uuid
    `;

    // -----------------------------------------------------------------------
    // 3. Cricket extension — rules and setup state.
    //    Inserting this row schedules the deferred participant sync trigger.
    // -----------------------------------------------------------------------
    await tx`
      insert into public.cricket_matches (
        match_id,
        format_code,
        rules_snapshot,
        setup_side
      ) values (
        ${matchId}::uuid,
        ${input.formatCode},
        ${tx.json(input.rules)},
        'team_a'
      )
    `;

    // -----------------------------------------------------------------------
    // 4. Canonical participant synchronisation.
    // -----------------------------------------------------------------------
    await tx`
      select public.sync_match_participants(${matchId}::uuid)
    `;

    return matchId;
  }
}
