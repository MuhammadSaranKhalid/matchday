export { TournamentsModule } from './tournaments.module.js';

export {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
  type TournamentErrorCode,
} from './domain/errors/tournament-error-codes.js';

export {
  type TournamentCommand,
  type TournamentCommandMetadata,
  type TournamentResourceIdentifiers,
} from './domain/command/tournament-command.js';

export {
  canonicalJsonStringify,
  computeRequestFingerprint,
} from './domain/command/fingerprint.js';

export { assertExpectedRevision } from './domain/revision/assert-expected-revision.js';

export {
  type ProposedSquadMember,
  type PaymentChannelType,
  type RegisterTeamCommand,
  type RegisterTeamPayload,
  type RegisterTeamResult,
  type ApproveRegistrationCommand,
  type ApproveRegistrationPayload,
  type ApproveRegistrationResult,
  type RejectRegistrationCommand,
  type RejectRegistrationPayload,
  type RejectRegistrationResult,
  type WithdrawPendingRegistrationCommand,
  type WithdrawPendingRegistrationPayload,
  type WithdrawPendingRegistrationResult,
  type WithdrawTournamentEntryCommand,
  type WithdrawTournamentEntryPayload,
  type WithdrawTournamentEntryResult,
  type AddSquadMemberCommand,
  type AddSquadMemberPayload,
  type AddSquadMemberResult,
  type RemoveSquadMemberCommand,
  type RemoveSquadMemberPayload,
  type RemoveSquadMemberResult,
  type FreezeSquadCommand,
  type FreezeSquadPayload,
  type FreezeSquadResult,
  type RecordEntryPaymentCommand,
  type RecordEntryPaymentPayload,
  type RecordEntryPaymentResult,
  type VoidEntryPaymentCommand,
  type VoidEntryPaymentPayload,
  type VoidEntryPaymentResult,
} from './domain/command/participation-commands.js';

export { TournamentCommandExecutor } from './application/command-executor/tournament-command-executor.js';

export {
  RegisterTeamHandler,
} from './application/handlers/register-team.handler.js';
export {
  ApproveRegistrationHandler,
} from './application/handlers/approve-registration.handler.js';
export {
  RejectRegistrationHandler,
} from './application/handlers/reject-registration.handler.js';
export {
  WithdrawPendingRegistrationHandler,
} from './application/handlers/withdraw-pending-registration.handler.js';
export {
  WithdrawTournamentEntryHandler,
} from './application/handlers/withdraw-tournament-entry.handler.js';
export {
  FreezeSquadHandler,
} from './application/handlers/freeze-squad.handler.js';

export {
  TOURNAMENT_TRANSACTION_EXECUTOR,
  type CommandQueryExecutor,
  type TournamentCommandContext,
  type TournamentCommandExecutionResult,
  type TournamentCommandHandler,
  type TournamentTransactionExecutor,
} from './application/ports/tournament-command.ports.js';

export {
  TEAM_AUTHORIZATION_REPOSITORY,
  TEAM_TOURNAMENT_REPOSITORY,
  TOURNAMENT_AUTHORIZATION_REPOSITORY,
  TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
  TOURNAMENT_ENTRY_REPOSITORY,
  TOURNAMENT_PAYMENT_REPOSITORY,
  TOURNAMENT_REGISTRATION_REPOSITORY,
  TOURNAMENT_ROOT_REPOSITORY,
  TOURNAMENT_SQUAD_REPOSITORY,
  type TeamAuthorizationRepository,
  type TeamSnapshot,
  type TeamTournamentRepository,
  type TournamentAuthorizationRepository,
  type TournamentCommandReceiptRecord,
  type TournamentCommandReceiptRepository,
  type EntrySnapshot,
  type TournamentEntryRepository,
  type PaymentSnapshot,
  type TournamentPaymentRepository,
  type ProposalMemberSnapshot,
  type RegistrationSnapshot,
  type TournamentRegistrationRepository,
  type TournamentRootRepository,
  type TournamentRootSnapshot,
  type SquadMemberSnapshot,
  type TournamentSquadRepository,
} from './application/ports/tournament-repository.ports.js';

export { TournamentsParticipationController } from './presentation/http/tournaments-participation.controller.js';
