import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { WithdrawPendingRegistrationHandler } from '../../../libs/modules/tournaments/src/application/handlers/withdraw-pending-registration.handler.js';
import type {
  CommandQueryExecutor,
  TournamentCommandContext,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TournamentRegistrationRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { WithdrawPendingRegistrationCommand } from '../../../libs/modules/tournaments/src/domain/command/participation-commands.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('WithdrawPendingRegistrationHandler', () => {
  const principal: AuthenticatedPrincipal = {
    userId: '11111111-1111-4000-8000-111111111111',
    sessionId: '55555555-5555-4000-8000-555555555555',
    appMetadata: {},
  };

  const tx = {} as CommandQueryExecutor;
  const context: TournamentCommandContext = {
    tx,
    principal,
    commandId: '99999999-9999-4000-8000-999999999999',
  };

  const tournamentId = '22222222-2222-4000-8000-222222222222';
  const registrationId = '77777777-7777-4000-8000-777777777777';
  const teamId = '33333333-3333-4000-8000-333333333333';

  let teamAuthRepo: { require: ReturnType<typeof vi.fn> };
  let registrationRepo: {
    lockRegistration: ReturnType<typeof vi.fn>;
    withdrawRegistration: ReturnType<typeof vi.fn>;
  };

  let handler: WithdrawPendingRegistrationHandler;

  const command: WithdrawPendingRegistrationCommand = {
    commandId: context.commandId,
    action: 'tournament.registration.withdraw_pending',
    resources: { registrationId },
    payload: {
      reason: 'Schedule conflict',
    },
  };

  beforeEach(() => {
    teamAuthRepo = {
      require: vi.fn().mockResolvedValue(undefined),
    };
    registrationRepo = {
      lockRegistration: vi.fn().mockResolvedValue({
        registrationId,
        tournamentId,
        teamId,
        registeredBy: '55555555-5555-4000-8000-555555555555',
        registeredAt: new Date(),
        status: 'pending',
        message: null,
        decisionReason: null,
        decidedBy: null,
        decidedAt: null,
        withdrawnAt: null,
        withdrawnBy: null,
        withdrawalReason: null,
      }),
      withdrawRegistration: vi.fn().mockResolvedValue(undefined),
    };

    handler = new WithdrawPendingRegistrationHandler(
      teamAuthRepo as unknown as TeamAuthorizationRepository,
      registrationRepo as unknown as TournamentRegistrationRepository,
    );
  });

  it('withdraws registration as team authority successfully', async () => {
    const result = await handler.execute(context, command);

    expect(result).toEqual({
      registrationId,
      status: 'withdrawn',
    });
    expect(registrationRepo.lockRegistration).toHaveBeenCalledWith(
      tx,
      registrationId,
    );
    expect(teamAuthRepo.require).toHaveBeenCalledWith(
      tx,
      teamId,
      'team.tournament.enter',
    );
    expect(registrationRepo.withdrawRegistration).toHaveBeenCalledWith(tx, {
      registrationId,
      withdrawnBy: principal.userId,
      withdrawalReason: 'Schedule conflict',
    });
  });

  it('fails if actor is not team authority', async () => {
    teamAuthRepo.require.mockRejectedValueOnce(
      TournamentError.forbidden('Forbidden'),
    );

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown forbidden');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.FORBIDDEN,
      );
    }
  });

  it('fails if registration is already approved', async () => {
    registrationRepo.lockRegistration.mockResolvedValueOnce({
      registrationId,
      tournamentId,
      teamId,
      status: 'approved',
    });

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown invalid state');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.INVALID_STATE,
      );
    }
  });
});
