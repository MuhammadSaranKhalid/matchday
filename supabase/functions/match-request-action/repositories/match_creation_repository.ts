// MatchCreationRepository — creates the normalized match aggregate.
//
// Ownership model:
//   1. INSERT into public.matches (sport-neutral shell only)
//   2. UPDATE public.match_teams to resolve the two team slots
//   3. INSERT into public.cricket_matches (Cricket rules and setup state)
//   4. CALL public.sync_match_participants(match_id) — canonical participant creation
//   5. UPDATE is_wicket_keeper on cricket_match_players for keeper choices
//
// INVARIANTS enforced here:
//   - Does not write team_a_id or team_b_id (removed matches columns)
//   - Does not INSERT into public.match_players directly
//   - Does not INSERT into public.cricket_match_players directly
//   - The deferred trigger repeats sync_match_participants at commit; the
//     immediate call gives us rows on which to set keeper flags.

import type { Tx } from "../types.ts";

export interface CreateMatchInput {
  venue: string | null;
  scheduledStartTime: string | null;
  /** Normalised rules snapshot from the challenge format fields. */
  format: Record<string, unknown>;
  /** Sender / host team → placed in team_a slot. */
  teamAId: string;
  /** Receiver / applicant team → placed in team_b slot. */
  teamBId: string;
  /** Keeper for team_a (from fromTeamKeeperId on the challenge row). */
  teamAKeeperId: string | null;
  /** Keeper for team_b (from toTeamKeeperId in the accept body or applicantKeeperId). */
  teamBKeeperId: string | null;
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
    const formatCode: string =
      (input.format["format_preset"] as string | undefined) ??
      (input.format["format_code"] as string | undefined) ??
      "t20";

    await tx`
      insert into public.cricket_matches (
        match_id,
        format_code,
        rules_snapshot,
        setup_side
      ) values (
        ${matchId}::uuid,
        ${formatCode},
        ${tx.json(input.format)},
        'team_a'
      )
    `;

    // -----------------------------------------------------------------------
    // 4. Canonical participant synchronisation.
    //    The constraint trigger repeats this at commit — the immediate call
    //    materialises rows so keeper flags can be applied in step 5.
    // -----------------------------------------------------------------------
    await tx`
      select public.sync_match_participants(${matchId}::uuid)
    `;

    // -----------------------------------------------------------------------
    // 5. Optional keeper flags.
    //    Matches players by user_id or unclaimed_id within the relevant side.
    // -----------------------------------------------------------------------
    if (input.teamAKeeperId != null || input.teamBKeeperId != null) {
      await tx`
        update public.cricket_match_players cmp
        set is_wicket_keeper = true
        from public.match_players mp
        where cmp.match_player_id = mp.match_player_id
          and cmp.match_id = ${matchId}::uuid
          and mp.match_id = ${matchId}::uuid
          and (
            (mp.team_side = 'team_a' and ${input.teamAKeeperId} is not null and (
              mp.user_id = ${input.teamAKeeperId}::uuid
              or mp.unclaimed_id = ${input.teamAKeeperId}::uuid
            ))
            or
            (mp.team_side = 'team_b' and ${input.teamBKeeperId} is not null and (
              mp.user_id = ${input.teamBKeeperId}::uuid
              or mp.unclaimed_id = ${input.teamBKeeperId}::uuid
            ))
          )
      `;
    }

    return matchId;
  }

  /**
   * Normalises a raw format object from a challenge row into the canonical
   * rules snapshot.  Maps legacy `overs` key to `overs_per_innings`.
   */
  static normalizeFormat(
    raw: Record<string, unknown> | null,
  ): Record<string, unknown> {
    const base: Record<string, unknown> = {
      players_per_team: 11,
      overs_per_innings: 20,
      balls_per_over: 6,
      max_overs_per_bowler: 4,
    };

    const merged = { ...base, ...(raw ?? {}) };

    // Canonical key always wins over legacy spelling.
    const oversPerInnings =
      Number(merged["overs_per_innings"]) ||
      Number(merged["overs"]) ||
      20;
    merged["overs_per_innings"] = oversPerInnings;

    return merged;
  }
}
