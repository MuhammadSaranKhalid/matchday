import { Module } from '@nestjs/common';
import { AuthModule } from '../../../platform/src/auth/auth.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';

import { TournamentCommandExecutor } from './application/command-executor/tournament-command-executor.js';
import {
  TOURNAMENT_TRANSACTION_EXECUTOR,
  type TournamentTransactionExecutor,
} from './application/ports/tournament-command.ports.js';
import {
  TOURNAMENT_AUTHORIZATION_REPOSITORY,
  TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
  TOURNAMENT_ROOT_REPOSITORY,
  type TournamentCommandReceiptRepository,
} from './application/ports/tournament-repository.ports.js';
import { PostgresTournamentAuthorizationRepository } from './infrastructure/persistence/postgres-tournament-authorization.repository.js';
import { PostgresTournamentCommandReceiptRepository } from './infrastructure/persistence/postgres-tournament-command-receipt.repository.js';
import { PostgresTournamentRootRepository } from './infrastructure/persistence/postgres-tournament-root.repository.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  providers: [
    {
      provide: TOURNAMENT_AUTHORIZATION_REPOSITORY,
      useClass: PostgresTournamentAuthorizationRepository,
    },
    {
      provide: TOURNAMENT_ROOT_REPOSITORY,
      useClass: PostgresTournamentRootRepository,
    },
    {
      provide: TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
      useClass: PostgresTournamentCommandReceiptRepository,
    },
    {
      provide: TOURNAMENT_TRANSACTION_EXECUTOR,
      inject: [DatabaseExecutorService],
      useFactory: (db: DatabaseExecutorService): TournamentTransactionExecutor => ({
        withCommandTransaction: (principal, work) =>
          db.withCommandTransaction(principal, (client) => work(client)),
      }),
    },
    {
      provide: TournamentCommandExecutor,
      inject: [TOURNAMENT_TRANSACTION_EXECUTOR, TOURNAMENT_COMMAND_RECEIPT_REPOSITORY],
      useFactory: (
        txExecutor: TournamentTransactionExecutor,
        receiptRepo: TournamentCommandReceiptRepository,
      ) => new TournamentCommandExecutor(txExecutor, receiptRepo),
    },
  ],
  exports: [
    TournamentCommandExecutor,
    TOURNAMENT_AUTHORIZATION_REPOSITORY,
    TOURNAMENT_ROOT_REPOSITORY,
    TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
    TOURNAMENT_TRANSACTION_EXECUTOR,
  ],
})
export class TournamentsModule {}
