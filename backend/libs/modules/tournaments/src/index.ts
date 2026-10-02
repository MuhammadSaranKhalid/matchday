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

export { TournamentCommandExecutor } from './application/command-executor/tournament-command-executor.js';

export {
  TOURNAMENT_TRANSACTION_EXECUTOR,
  type CommandQueryExecutor,
  type TournamentCommandContext,
  type TournamentCommandExecutionResult,
  type TournamentCommandHandler,
  type TournamentTransactionExecutor,
} from './application/ports/tournament-command.ports.js';

export {
  TOURNAMENT_AUTHORIZATION_REPOSITORY,
  TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
  TOURNAMENT_ROOT_REPOSITORY,
  type TournamentAuthorizationRepository,
  type TournamentCommandReceiptRecord,
  type TournamentCommandReceiptRepository,
  type TournamentRootRepository,
  type TournamentRootSnapshot,
} from './application/ports/tournament-repository.ports.js';
