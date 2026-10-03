import { Module } from '@nestjs/common';
import { AuthModule } from '../../../platform/src/auth/auth.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';

import { TournamentCommandExecutor } from './application/command-executor/tournament-command-executor.js';
import { AddSquadMemberHandler } from './application/handlers/add-squad-member.handler.js';
import { ApproveRegistrationHandler } from './application/handlers/approve-registration.handler.js';
import { FreezeSquadHandler } from './application/handlers/freeze-squad.handler.js';
import { RecordEntryPaymentHandler } from './application/handlers/record-entry-payment.handler.js';
import { RegisterTeamHandler } from './application/handlers/register-team.handler.js';
import { RejectRegistrationHandler } from './application/handlers/reject-registration.handler.js';
import { RemoveSquadMemberHandler } from './application/handlers/remove-squad-member.handler.js';
import { VoidEntryPaymentHandler } from './application/handlers/void-entry-payment.handler.js';
import { WithdrawPendingRegistrationHandler } from './application/handlers/withdraw-pending-registration.handler.js';
import { WithdrawTournamentEntryHandler } from './application/handlers/withdraw-tournament-entry.handler.js';
import {
  TOURNAMENT_TRANSACTION_EXECUTOR,
  type TournamentTransactionExecutor,
} from './application/ports/tournament-command.ports.js';
import {
  TEAM_AUTHORIZATION_REPOSITORY,
  type TeamAuthorizationRepository,
  TEAM_TOURNAMENT_REPOSITORY,
  type TeamTournamentRepository,
  TOURNAMENT_AUTHORIZATION_REPOSITORY,
  type TournamentAuthorizationRepository,
  TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
  type TournamentCommandReceiptRepository,
  TOURNAMENT_ENTRY_REPOSITORY,
  type TournamentEntryRepository,
  TOURNAMENT_PAYMENT_REPOSITORY,
  type TournamentPaymentRepository,
  TOURNAMENT_REGISTRATION_REPOSITORY,
  type TournamentRegistrationRepository,
  TOURNAMENT_ROOT_REPOSITORY,
  type TournamentRootRepository,
  TOURNAMENT_SQUAD_REPOSITORY,
  type TournamentSquadRepository,
} from './application/ports/tournament-repository.ports.js';
import { PostgresTeamAuthorizationRepository } from './infrastructure/persistence/postgres-team-authorization.repository.js';
import { PostgresTeamTournamentRepository } from './infrastructure/persistence/postgres-team-tournament.repository.js';
import { PostgresTournamentAuthorizationRepository } from './infrastructure/persistence/postgres-tournament-authorization.repository.js';
import { PostgresTournamentCommandReceiptRepository } from './infrastructure/persistence/postgres-tournament-command-receipt.repository.js';
import { PostgresTournamentEntryRepository } from './infrastructure/persistence/postgres-tournament-entry.repository.js';
import { PostgresTournamentPaymentRepository } from './infrastructure/persistence/postgres-tournament-payment.repository.js';
import { PostgresTournamentRegistrationRepository } from './infrastructure/persistence/postgres-tournament-registration.repository.js';
import { PostgresTournamentRootRepository } from './infrastructure/persistence/postgres-tournament-root.repository.js';
import { PostgresTournamentSquadRepository } from './infrastructure/persistence/postgres-tournament-squad.repository.js';
import { TournamentsParticipationController } from './presentation/http/tournaments-participation.controller.js';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [TournamentsParticipationController],
  providers: [
    // ─── Repositories ──────────────────────────────────────────────────────────
    {
      provide: TOURNAMENT_AUTHORIZATION_REPOSITORY,
      useClass: PostgresTournamentAuthorizationRepository,
    },
    {
      provide: TEAM_AUTHORIZATION_REPOSITORY,
      useClass: PostgresTeamAuthorizationRepository,
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
      provide: TOURNAMENT_REGISTRATION_REPOSITORY,
      useClass: PostgresTournamentRegistrationRepository,
    },
    {
      provide: TOURNAMENT_ENTRY_REPOSITORY,
      useClass: PostgresTournamentEntryRepository,
    },
    {
      provide: TOURNAMENT_SQUAD_REPOSITORY,
      useClass: PostgresTournamentSquadRepository,
    },
    {
      provide: TOURNAMENT_PAYMENT_REPOSITORY,
      useClass: PostgresTournamentPaymentRepository,
    },
    {
      provide: TEAM_TOURNAMENT_REPOSITORY,
      useClass: PostgresTeamTournamentRepository,
    },

    // ─── Transaction Executor ─────────────────────────────────────────────────
    {
      provide: TOURNAMENT_TRANSACTION_EXECUTOR,
      inject: [DatabaseExecutorService],
      useFactory: (dbExecutor: DatabaseExecutorService): TournamentTransactionExecutor => ({
        withCommandTransaction: (principal, work) =>
          dbExecutor.withCommandTransaction(principal, work),
      }),
    },

    // ─── Command Pipeline Executor ───────────────────────────────────────────
    {
      provide: TournamentCommandExecutor,
      inject: [TOURNAMENT_TRANSACTION_EXECUTOR, TOURNAMENT_COMMAND_RECEIPT_REPOSITORY],
      useFactory: (
        txExecutor: TournamentTransactionExecutor,
        receiptRepo: TournamentCommandReceiptRepository,
      ) => new TournamentCommandExecutor(txExecutor, receiptRepo),
    },

    // ─── Command Handlers ─────────────────────────────────────────────────────
    {
      provide: RegisterTeamHandler,
      inject: [
        TOURNAMENT_ROOT_REPOSITORY,
        TOURNAMENT_REGISTRATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TEAM_TOURNAMENT_REPOSITORY,
        TEAM_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_SQUAD_REPOSITORY,
      ],
      useFactory: (
        rootRepo: TournamentRootRepository,
        regRepo: TournamentRegistrationRepository,
        entryRepo: TournamentEntryRepository,
        teamRepo: TeamTournamentRepository,
        teamAuthRepo: TeamAuthorizationRepository,
        squadRepo: TournamentSquadRepository,
      ) =>
        new RegisterTeamHandler(
          rootRepo,
          regRepo,
          entryRepo,
          teamRepo,
          teamAuthRepo,
          squadRepo,
        ),
    },
    {
      provide: ApproveRegistrationHandler,
      inject: [
        TOURNAMENT_ROOT_REPOSITORY,
        TOURNAMENT_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_REGISTRATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_SQUAD_REPOSITORY,
      ],
      useFactory: (
        rootRepo: TournamentRootRepository,
        tournamentAuthRepo: TournamentAuthorizationRepository,
        regRepo: TournamentRegistrationRepository,
        entryRepo: TournamentEntryRepository,
        squadRepo: TournamentSquadRepository,
      ) =>
        new ApproveRegistrationHandler(
          rootRepo,
          tournamentAuthRepo,
          regRepo,
          entryRepo,
          squadRepo,
        ),
    },
    {
      provide: RejectRegistrationHandler,
      inject: [
        TOURNAMENT_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_REGISTRATION_REPOSITORY,
      ],
      useFactory: (
        tournamentAuthRepo: TournamentAuthorizationRepository,
        regRepo: TournamentRegistrationRepository,
      ) => new RejectRegistrationHandler(tournamentAuthRepo, regRepo),
    },
    {
      provide: WithdrawPendingRegistrationHandler,
      inject: [
        TEAM_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_REGISTRATION_REPOSITORY,
      ],
      useFactory: (
        teamAuthRepo: TeamAuthorizationRepository,
        regRepo: TournamentRegistrationRepository,
      ) =>
        new WithdrawPendingRegistrationHandler(
          teamAuthRepo,
          regRepo,
        ),
    },
    {
      provide: WithdrawTournamentEntryHandler,
      inject: [
        TOURNAMENT_ROOT_REPOSITORY,
        TEAM_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_SQUAD_REPOSITORY,
      ],
      useFactory: (
        rootRepo: TournamentRootRepository,
        teamAuthRepo: TeamAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
        squadRepo: TournamentSquadRepository,
      ) =>
        new WithdrawTournamentEntryHandler(
          rootRepo,
          teamAuthRepo,
          entryRepo,
          squadRepo,
        ),
    },
    {
      provide: AddSquadMemberHandler,
      inject: [
        TEAM_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_SQUAD_REPOSITORY,
      ],
      useFactory: (
        teamAuthRepo: TeamAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
        squadRepo: TournamentSquadRepository,
      ) =>
        new AddSquadMemberHandler(
          teamAuthRepo,
          entryRepo,
          squadRepo,
        ),
    },
    {
      provide: RemoveSquadMemberHandler,
      inject: [
        TEAM_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_SQUAD_REPOSITORY,
      ],
      useFactory: (
        teamAuthRepo: TeamAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
        squadRepo: TournamentSquadRepository,
      ) =>
        new RemoveSquadMemberHandler(
          teamAuthRepo,
          entryRepo,
          squadRepo,
        ),
    },
    {
      provide: FreezeSquadHandler,
      inject: [
        TOURNAMENT_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
      ],
      useFactory: (
        tournamentAuthRepo: TournamentAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
      ) =>
        new FreezeSquadHandler(
          tournamentAuthRepo,
          entryRepo,
        ),
    },
    {
      provide: RecordEntryPaymentHandler,
      inject: [
        TOURNAMENT_ROOT_REPOSITORY,
        TOURNAMENT_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_PAYMENT_REPOSITORY,
      ],
      useFactory: (
        rootRepo: TournamentRootRepository,
        tournamentAuthRepo: TournamentAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
        paymentRepo: TournamentPaymentRepository,
      ) =>
        new RecordEntryPaymentHandler(
          rootRepo,
          tournamentAuthRepo,
          entryRepo,
          paymentRepo,
        ),
    },
    {
      provide: VoidEntryPaymentHandler,
      inject: [
        TOURNAMENT_AUTHORIZATION_REPOSITORY,
        TOURNAMENT_ENTRY_REPOSITORY,
        TOURNAMENT_PAYMENT_REPOSITORY,
      ],
      useFactory: (
        tournamentAuthRepo: TournamentAuthorizationRepository,
        entryRepo: TournamentEntryRepository,
        paymentRepo: TournamentPaymentRepository,
      ) =>
        new VoidEntryPaymentHandler(
          tournamentAuthRepo,
          entryRepo,
          paymentRepo,
        ),
    },
  ],
  exports: [
    TournamentCommandExecutor,
    TOURNAMENT_AUTHORIZATION_REPOSITORY,
    TEAM_AUTHORIZATION_REPOSITORY,
    TOURNAMENT_ROOT_REPOSITORY,
    TOURNAMENT_COMMAND_RECEIPT_REPOSITORY,
    TOURNAMENT_REGISTRATION_REPOSITORY,
    TOURNAMENT_ENTRY_REPOSITORY,
    TOURNAMENT_SQUAD_REPOSITORY,
    TOURNAMENT_PAYMENT_REPOSITORY,
    TEAM_TOURNAMENT_REPOSITORY,
    TOURNAMENT_TRANSACTION_EXECUTOR,
    RegisterTeamHandler,
    ApproveRegistrationHandler,
    RejectRegistrationHandler,
    WithdrawPendingRegistrationHandler,
    WithdrawTournamentEntryHandler,
    AddSquadMemberHandler,
    RemoveSquadMemberHandler,
    FreezeSquadHandler,
    RecordEntryPaymentHandler,
    VoidEntryPaymentHandler,
  ],
})
export class TournamentsModule {}
