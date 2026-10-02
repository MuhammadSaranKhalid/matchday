export interface TournamentCommandMetadata {
  readonly commandId: string;
  readonly expectedRevision?: number;
}

export interface TournamentResourceIdentifiers {
  readonly tournamentId?: string;
  readonly stageId?: string;
  readonly groupId?: string;
  readonly roundId?: string;
  readonly fixtureId?: string;
  readonly registrationId?: string;
  readonly entryId?: string;
  readonly [key: string]: string | undefined;
}

export interface TournamentCommand<TPayload = unknown> {
  readonly commandId: string;
  readonly action: string;
  readonly resources: TournamentResourceIdentifiers;
  readonly expectedRevision?: number;
  readonly payload: TPayload;
}
