// ChallengeRepository — row locks and terminal transitions for match_challenges
// and match_pool_applications.
//
// All methods MUST be called inside an active sql.begin() transaction.
// Every terminal update returns its affected-row count; zero rows throws CONFLICT.

import { conflict, notFound } from "../domain/errors.ts";
import type { Tx } from "../types.ts";

export interface ChallengeRow {
  requestId: string;
  fromTeamId: string;
  toTeamId: string | null;
  status: "pending" | "countered" | "accepted" | "declined" | "cancelled" | "expired";
  proposedFormat: Record<string, unknown>;
  proposedStartTime: string | null;
  proposedVenue: string | null;
  counteredFormat: Record<string, unknown> | null;
  counteredStartTime: string | null;
  counteredVenue: string | null;
  fromTeamXi: string[];
  fromTeamKeeperId: string | null;
  requestedBy: string | null;
}

export interface ApplicationRow {
  applicationId: string;
  requestId: string;
  applicantTeamId: string;
  applicantXi: string[];
  applicantKeeperId: string | null;
  status: "pending" | "accepted" | "rejected" | "withdrawn";
}

export interface LockedChallengeForPool {
  requestId: string;
  fromTeamId: string;
  status: string;
  proposedFormat: Record<string, unknown>;
  proposedStartTime: string | null;
  proposedVenue: string | null;
  fromTeamXi: string[];
  fromTeamKeeperId: string | null;
}

export class ChallengeRepository {
  async lockChallenge(tx: Tx, requestId: string): Promise<ChallengeRow> {
    const rows = await tx`
      select
        request_id           as "requestId",
        from_team_id         as "fromTeamId",
        to_team_id           as "toTeamId",
        status,
        coalesce(proposed_format, '{}')::jsonb  as "proposedFormat",
        proposed_start_time  as "proposedStartTime",
        proposed_venue       as "proposedVenue",
        countered_format     as "counteredFormat",
        countered_start_time as "counteredStartTime",
        countered_venue      as "counteredVenue",
        coalesce(from_team_xi, '{}')::uuid[]    as "fromTeamXi",
        from_team_keeper_id  as "fromTeamKeeperId",
        requested_by         as "requestedBy"
      from public.match_challenges
      where request_id = ${requestId}::uuid
      for update
    `;

    if (rows.length === 0) notFound("Match request not found");

    return rows[0] as ChallengeRow;
  }

  async lockApplication(tx: Tx, applicationId: string): Promise<ApplicationRow> {
    const rows = await tx`
      select
        application_id    as "applicationId",
        request_id        as "requestId",
        applicant_team_id as "applicantTeamId",
        coalesce(applicant_xi, '{}')::uuid[] as "applicantXi",
        applicant_keeper_id as "applicantKeeperId",
        status
      from public.match_pool_applications
      where application_id = ${applicationId}::uuid
      for update
    `;

    if (rows.length === 0) notFound("Application not found");

    return rows[0] as ApplicationRow;
  }

  async lockChallengeForApp(
    tx: Tx,
    requestId: string,
  ): Promise<LockedChallengeForPool> {
    const rows = await tx`
      select
        request_id          as "requestId",
        from_team_id        as "fromTeamId",
        status,
        coalesce(proposed_format, '{}')::jsonb as "proposedFormat",
        proposed_start_time as "proposedStartTime",
        proposed_venue      as "proposedVenue",
        coalesce(from_team_xi, '{}')::uuid[]   as "fromTeamXi",
        from_team_keeper_id as "fromTeamKeeperId"
      from public.match_challenges
      where request_id = ${requestId}::uuid
      for update
    `;

    if (rows.length === 0) notFound("Match request not found");

    return rows[0] as LockedChallengeForPool;
  }

  /** Guarded terminal update for direct challenges. Zero rows → CONFLICT. */
  async acceptChallenge(
    tx: Tx,
    requestId: string,
    observedStatus: string,
    matchId: string,
    actorId: string,
    note: string | null,
    toTeamId: string,
  ): Promise<number> {
    const rows = await tx`
      update public.match_challenges
      set
        status       = 'accepted',
        decided_by   = ${actorId}::uuid,
        decided_at   = now(),
        decision_note = ${note},
        match_id     = ${matchId}::uuid,
        to_team_id   = ${toTeamId}::uuid
      where request_id = ${requestId}::uuid
        and status = ${observedStatus}
    `;

    const affected = rows.count ?? 0;
    if (affected === 0) {
      conflict("Request changed under us; concurrent acceptance conflict");
    }
    return affected;
  }

  /** Accept the selected pool application. */
  async acceptApplication(
    tx: Tx,
    applicationId: string,
    note: string | null,
  ): Promise<void> {
    await tx`
      update public.match_pool_applications
      set
        status       = 'accepted',
        decided_at   = now(),
        decision_note = ${note},
        updated_at   = now()
      where application_id = ${applicationId}::uuid
    `;
  }

  /** Reject all pending competitors for the same challenge. */
  async rejectCompetingApplications(
    tx: Tx,
    requestId: string,
    selectedApplicationId: string,
  ): Promise<number> {
    const rows = await tx`
      update public.match_pool_applications
      set
        status       = 'rejected',
        decided_at   = now(),
        decision_note = 'Another opponent was selected for this fixture',
        updated_at   = now()
      where request_id = ${requestId}::uuid
        and application_id <> ${selectedApplicationId}::uuid
        and status = 'pending'
    `;
    return rows.count ?? 0;
  }

  /** Guarded terminal update for the parent open challenge (pool path). */
  async acceptChallengeForPool(
    tx: Tx,
    requestId: string,
    matchId: string,
    actorId: string,
    note: string | null,
    toTeamId: string,
  ): Promise<number> {
    const rows = await tx`
      update public.match_challenges
      set
        status       = 'accepted',
        decided_by   = ${actorId}::uuid,
        decided_at   = now(),
        decision_note = ${note},
        match_id     = ${matchId}::uuid,
        to_team_id   = ${toTeamId}::uuid
      where request_id = ${requestId}::uuid
        and status = 'pending'
    `;

    const affected = rows.count ?? 0;
    if (affected === 0) {
      conflict("Open challenge changed under us; concurrent acceptance conflict");
    }
    return affected;
  }
}
