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
import { ApproveRegistrationHandler } from '../../application/handlers/approve-registration.handler.js';
import { FreezeSquadHandler } from '../../application/handlers/freeze-squad.handler.js';
import { RegisterTeamHandler } from '../../application/handlers/register-team.handler.js';
import { RejectRegistrationHandler } from '../../application/handlers/reject-registration.handler.js';
import { WithdrawPendingRegistrationHandler } from '../../application/handlers/withdraw-pending-registration.handler.js';
import { WithdrawTournamentEntryHandler } from '../../application/handlers/withdraw-tournament-entry.handler.js';

import type {
  ApproveRegistrationCommand,
  FreezeSquadCommand,
  RegisterTeamCommand,
  RejectRegistrationCommand,
  WithdrawPendingRegistrationCommand,
  WithdrawTournamentEntryCommand,
} from '../../domain/command/participation-commands.js';

import {
  type ApproveRegistrationBody,
  approveRegistrationSchema,
} from './schemas/approve-registration.schema.js';
import {
  type FreezeSquadBody,
  freezeSquadSchema,
} from './schemas/freeze-squad.schema.js';
import {
  approveRegistrationResponseSchema,
  freezeSquadResponseSchema,
  registerTeamResponseSchema,
  rejectRegistrationResponseSchema,
  withdrawPendingRegistrationResponseSchema,
  withdrawTournamentEntryResponseSchema,
} from './schemas/participation-response.schema.js';
import {
  type RegisterTeamBody,
  registerTeamSchema,
} from './schemas/register-team.schema.js';
import {
  type RejectRegistrationBody,
  rejectRegistrationSchema,
} from './schemas/reject-registration.schema.js';
import {
  type WithdrawTournamentEntryBody,
  withdrawTournamentEntrySchema,
} from './schemas/withdraw-entry.schema.js';
import {
  type WithdrawPendingRegistrationBody,
  withdrawPendingRegistrationSchema,
} from './schemas/withdraw-registration.schema.js';

@UseGuards(SupabaseAuthGuard)
@Controller('tournaments')
export class TournamentsParticipationController {
  constructor(
    private readonly commandExecutor: TournamentCommandExecutor,
    private readonly registerTeamHandler: RegisterTeamHandler,
    private readonly approveRegistrationHandler: ApproveRegistrationHandler,
    private readonly rejectRegistrationHandler: RejectRegistrationHandler,
    private readonly withdrawPendingRegistrationHandler: WithdrawPendingRegistrationHandler,
    private readonly withdrawTournamentEntryHandler: WithdrawTournamentEntryHandler,
    private readonly freezeSquadHandler: FreezeSquadHandler,
  ) {}

  @Post(':tournamentId/registrations')
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

  @Post(':tournamentId/registrations/:registrationId/approve')
  @SerializeOptions({ schema: approveRegistrationResponseSchema })
  async approveRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: approveRegistrationSchema }) body: ApproveRegistrationBody,
  ) {
    const command: ApproveRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.approve',
      resources: { tournamentId, registrationId },
      payload: {},
    };
    return this.commandExecutor.execute(
      principal,
      command,
      this.approveRegistrationHandler,
    );
  }

  @Post(':tournamentId/registrations/:registrationId/reject')
  @SerializeOptions({ schema: rejectRegistrationResponseSchema })
  async rejectRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: rejectRegistrationSchema }) body: RejectRegistrationBody,
  ) {
    const command: RejectRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.reject',
      resources: { tournamentId, registrationId },
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

  @Post(':tournamentId/registrations/:registrationId/withdraw')
  @SerializeOptions({ schema: withdrawPendingRegistrationResponseSchema })
  async withdrawRegistration(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Param('registrationId', new ParseUUIDPipe()) registrationId: string,
    @Body({ schema: withdrawPendingRegistrationSchema })
    body: WithdrawPendingRegistrationBody,
  ) {
    const command: WithdrawPendingRegistrationCommand = {
      commandId: body.commandId,
      action: 'tournament.registration.withdraw_pending',
      resources: { tournamentId, registrationId },
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

  @Post(':tournamentId/entries/:entryId/withdraw')
  @SerializeOptions({ schema: withdrawTournamentEntryResponseSchema })
  async withdrawEntry(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: withdrawTournamentEntrySchema })
    body: WithdrawTournamentEntryBody,
  ) {
    const command: WithdrawTournamentEntryCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.withdraw',
      resources: { tournamentId, entryId },
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

  @Post(':tournamentId/entries/:entryId/freeze-squad')
  @SerializeOptions({ schema: freezeSquadResponseSchema })
  async freezeSquad(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('tournamentId', new ParseUUIDPipe()) tournamentId: string,
    @Param('entryId', new ParseUUIDPipe()) entryId: string,
    @Body({ schema: freezeSquadSchema }) body: FreezeSquadBody,
  ) {
    const command: FreezeSquadCommand = {
      commandId: body.commandId,
      action: 'tournament.entry.freeze_squad',
      resources: { tournamentId, entryId },
      expectedRevision: body.expectedRevision,
      payload: {},
    };
    return this.commandExecutor.execute(principal, command, this.freezeSquadHandler);
  }
}
