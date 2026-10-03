import {
  Body,
  Controller,
  Param,
  ParseUUIDPipe,
  Post,
  SerializeOptions,
  UseGuards,
} from '@nestjs/common';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { CurrentPrincipal } from '../../../../../platform/src/auth/current-principal.decorator.js';
import { SupabaseAuthGuard } from '../../../../../platform/src/auth/supabase-auth.guard.js';

import { TournamentCommandExecutor } from '../../application/command-executor/tournament-command-executor.js';
import { AddSquadMemberHandler } from '../../application/handlers/add-squad-member.handler.js';
import { ApproveRegistrationHandler } from '../../application/handlers/approve-registration.handler.js';
import { FreezeSquadHandler } from '../../application/handlers/freeze-squad.handler.js';
import { RecordEntryPaymentHandler } from '../../application/handlers/record-entry-payment.handler.js';
import { RegisterTeamHandler } from '../../application/handlers/register-team.handler.js';
import { RejectRegistrationHandler } from '../../application/handlers/reject-registration.handler.js';
import { RemoveSquadMemberHandler } from '../../application/handlers/remove-squad-member.handler.js';
import { VoidEntryPaymentHandler } from '../../application/handlers/void-entry-payment.handler.js';
import { WithdrawPendingRegistrationHandler } from '../../application/handlers/withdraw-pending-registration.handler.js';
import { WithdrawTournamentEntryHandler } from '../../application/handlers/withdraw-tournament-entry.handler.js';

import type {
  AddSquadMemberCommand,
  ApproveRegistrationCommand,
  FreezeSquadCommand,
  RecordEntryPaymentCommand,
  RegisterTeamCommand,
  RejectRegistrationCommand,
  RemoveSquadMemberCommand,
  VoidEntryPaymentCommand,
  WithdrawPendingRegistrationCommand,
  WithdrawTournamentEntryCommand,
} from '../../domain/command/participation-commands.js';

import {
  type AddSquadMemberBody,
  addSquadMemberSchema,
} from './schemas/add-squad-member.schema.js';
import {
  type ApproveRegistrationBody,
  approveRegistrationSchema,
} from './schemas/approve-registration.schema.js';
import {
  type FreezeSquadBody,
  freezeSquadSchema,
} from './schemas/freeze-squad.schema.js';
import {
  addSquadMemberResponseSchema,
  approveRegistrationResponseSchema,
  freezeSquadResponseSchema,
  recordEntryPaymentResponseSchema,
  registerTeamResponseSchema,
  rejectRegistrationResponseSchema,
  removeSquadMemberResponseSchema,
  voidEntryPaymentResponseSchema,
  withdrawPendingRegistrationResponseSchema,
  withdrawTournamentEntryResponseSchema,
} from './schemas/participation-response.schema.js';
import {
  type RecordPaymentBody,
  recordPaymentSchema,
} from './schemas/record-payment.schema.js';
import {
  type RegisterTeamBody,
  registerTeamSchema,
} from './schemas/register-team.schema.js';
import {
  type RejectRegistrationBody,
  rejectRegistrationSchema,
} from './schemas/reject-registration.schema.js';
import {
  type RemoveSquadMemberBody,
  removeSquadMemberSchema,
} from './schemas/remove-squad-member.schema.js';
import {
  type VoidPaymentBody,
  voidPaymentSchema,
} from './schemas/void-payment.schema.js';
import {
  type WithdrawTournamentEntryBody,
  withdrawTournamentEntrySchema,
} from './schemas/withdraw-entry.schema.js';
import {
  type WithdrawPendingRegistrationBody,
  withdrawPendingRegistrationSchema,
} from './schemas/withdraw-registration.schema.js';

@UseGuards(SupabaseAuthGuard)
@Controller()
export class TournamentsParticipationController {
  constructor(
    private readonly commandExecutor: TournamentCommandExecutor,
    private readonly registerTeamHandler: RegisterTeamHandler,
    private readonly approveRegistrationHandler: ApproveRegistrationHandler,
    private readonly rejectRegistrationHandler: RejectRegistrationHandler,
    private readonly withdrawPendingRegistrationHandler: WithdrawPendingRegistrationHandler,
    private readonly withdrawTournamentEntryHandler: WithdrawTournamentEntryHandler,
    private readonly addSquadMemberHandler: AddSquadMemberHandler,
    private readonly removeSquadMemberHandler: RemoveSquadMemberHandler,
    private readonly freezeSquadHandler: FreezeSquadHandler,
    private readonly recordEntryPaymentHandler: RecordEntryPaymentHandler,
    private readonly voidEntryPaymentHandler: VoidEntryPaymentHandler,
  ) {}

  // 1. RegisterTeam (parent tournamentId scoped)
  @Post('tournaments/:tournamentId/registrations')
  @SerializeOptions({ schema: registerTeamResponseSchema })
  async registerTeam(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Body({ schema: registerTeamSchema }) body: RegisterTeamBody,
  ) {
    const command: RegisterTeamCommand = {
      commandId: body.commandId,
      action: 'tournament.team.register',
      resources: { tournamentId },
      payload: {
        teamId: body.teamId,
        message: body.message,
        squadProposal: body.squadProposal,
      },
    };
    return this.commandExecutor.execute(principal, command, this.registerTeamHandler);
  }

  // 2. ApproveRegistration (resource-oriented)
  @Post('tournament-registrations/:registrationId/approve')
  @SerializeOptions({ schema: approveRegistrationResponseSchema })
  async approveRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: approveRegistrationSchema }) body: ApproveRegistrationBody,
  ) {
    const command: ApproveRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.approve',
      resources: { registrationId },
      payload: {},
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.approveRegistrationHandler,
    );
  }

  // 3. RejectRegistration (resource-oriented)
  @Post('tournament-registrations/:registrationId/reject')
  @SerializeOptions({ schema: rejectRegistrationResponseSchema })
  async rejectRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: rejectRegistrationSchema }) body: RejectRegistrationBody,
  ) {
    const command: RejectRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.reject',
      resources: { registrationId },
      payload: {
        reason: body.reason,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.rejectRegistrationHandler,
    );
  }

  // 4. WithdrawPendingRegistration (resource-oriented)
  @Post('tournament-registrations/:registrationId/withdraw')
  @SerializeOptions({ schema: withdrawPendingRegistrationResponseSchema })
  async withdrawRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: withdrawPendingRegistrationSchema })
    body: WithdrawPendingRegistrationBody,
  ) {
    const command: WithdrawPendingRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.withdraw_pending',
      resources: { registrationId },
      payload: {
        reason: body.reason,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.withdrawPendingRegistrationHandler,
    );
  }

  // 5. WithdrawTournamentEntry (resource-oriented)
  @Post('tournament-entries/:entryId/withdraw')
  @SerializeOptions({ schema: withdrawTournamentEntryResponseSchema })
  async withdrawEntry(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: withdrawTournamentEntrySchema })
    body: WithdrawTournamentEntryBody,
  ) {
    const command: WithdrawTournamentEntryCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.withdraw',
      resources: { entryId },
      expectedRevision: body.expectedRevision,
      payload: {
        reason: body.reason,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.withdrawTournamentEntryHandler,
    );
  }

  // 6. AddSquadMember (resource-oriented under entry)
  @Post('tournament-entries/:entryId/squad-members')
  @SerializeOptions({ schema: addSquadMemberResponseSchema })
  async addSquadMember(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: addSquadMemberSchema }) body: AddSquadMemberBody,
  ) {
    const command: AddSquadMemberCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.squad.add_member',
      resources: { entryId },
      expectedRevision: body.expectedRevision,
      payload: {
        userId: body.userId,
        unclaimedId: body.unclaimedId,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.addSquadMemberHandler,
    );
  }

  // 7. RemoveSquadMember (resource-oriented directly on squad member)
  @Post('tournament-squad-members/:squadMemberId/remove')
  @SerializeOptions({ schema: removeSquadMemberResponseSchema })
  async removeSquadMember(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('squadMemberId', new ParseUUIDPipe()) squadMemberId: string,
    @Body({ schema: removeSquadMemberSchema }) body: RemoveSquadMemberBody,
  ) {
    const command: RemoveSquadMemberCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.squad.remove_member',
      resources: { squadMemberId },
      expectedRevision: body.expectedRevision,
      payload: {
        reason: body.reason,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.removeSquadMemberHandler,
    );
  }

  // 8. FreezeSquad (resource-oriented under entry)
  @Post('tournament-entries/:entryId/squad/freeze')
  @SerializeOptions({ schema: freezeSquadResponseSchema })
  async freezeSquad(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: freezeSquadSchema }) body: FreezeSquadBody,
  ) {
    const command: FreezeSquadCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.freeze_squad',
      resources: { entryId },
      expectedRevision: body.expectedRevision,
      payload: {},
    };
    return this.commandExecutor.execute(principal, command, this.freezeSquadHandler);
  }

  // 9. RecordEntryPayment (resource-oriented under entry)
  @Post('tournament-entries/:entryId/payments')
  @SerializeOptions({ schema: recordEntryPaymentResponseSchema })
  async recordPayment(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: recordPaymentSchema }) body: RecordPaymentBody,
  ) {
    const command: RecordEntryPaymentCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.payment.record',
      resources: { entryId },
      payload: {
        amount: body.amount,
        paymentChannel: body.paymentChannel,
        paymentReference: body.paymentReference,
        notes: body.notes,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.recordEntryPaymentHandler,
    );
  }

  // 10. VoidEntryPayment (resource-oriented directly on payment)
  @Post('tournament-entry-payments/:paymentId/void')
  @SerializeOptions({ schema: voidEntryPaymentResponseSchema })
  async voidPayment(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('paymentId', new ParseUUIDPipe()) paymentId: string,
    @Body({ schema: voidPaymentSchema }) body: VoidPaymentBody,
  ) {
    const command: VoidEntryPaymentCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.payment.void',
      resources: { paymentId },
      payload: {
        voidReason: body.voidReason,
      },
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.voidEntryPaymentHandler,
    );
  }
}
