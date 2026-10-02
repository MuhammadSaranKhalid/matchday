import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { RejectRegistrationHandler } from '../../../libs/modules/tournaments/src/application/handlers/reject-registration.handler.js';
import type {
  CommandQueryExecutor,
  TournamentCommandContext,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentRegistrationRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { RejectRegistrationCommand } from '../../../libs/modules/tournaments/src/domain/command/participation-commands.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('RejectRegistrationHandler', () => {
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

  let tournamentAuthRepo: { require: ReturnType<typeof vi.fn> };
  let registrationRepo: {
    lockRegistration: ReturnType<typeof vi.fn>;
    resolveRegistration: ReturnType<typeof vi.fn>;
  };

  let handler: RejectRegistrationHandler;

  const command: RejectRegistrationCommand = {
    commandId: context.commandId,
    action: 'tournament.registration.reject',
    resources: { tournamentId, registrationId },
    payload: {
      reason: 'Incomplete documents',
    },
  };

  beforeEach(() => {
    tournamentAuthRepo = {
      require: vi.fn().mockResolvedValue(undefined),
    };
    registrationRepo = {
      lockRegistration: vi.fn().mockResolvedValue({
        registrationId,
        tournamentId,
        teamId: '33333333-3333-4000-8000-333333333333',
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
      resolveRegistration: vi.fn().mockResolvedValue(undefined),
    };

    handler = new RejectRegistrationHandler(
      tournamentAuthRepo as unknown as TournamentAuthorizationRepository,
      registrationRepo as unknown as TournamentRegistrationRepository,
    );
  });

  it('rejects registration with reason successfully', async () => {
    const result = await handler.execute(context, command);

    expect(result).toEqual({
      registrationId,
      status: 'rejected',
    });
    expect(tournamentAuthRepo.require).toHaveBeenCalledWith(
      tx,
      tournamentId,
      'tournament.registration.review',
    );
    expect(registrationRepo.lockRegistration).toHaveBeenCalledWith(
      tx,
      registrationId,
    );
    expect(registrationRepo.resolveRegistration).toHaveBeenCalledWith(tx, {
      registrationId,
      status: 'rejected',
      decidedBy: principal.userId,
      decisionReason: 'Incomplete documents',
    });
  });

  it('fails if registration belongs to another tournament', async () => {
    registrationRepo.lockRegistration.mockResolvedValueOnce({
      registrationId,
      tournamentId: 'another-tournament',
      teamId: '33333333-3333-4000-8000-333333333333',
      status: 'pending',
    });

    await expect(handler.execute(context, command)).rejects.toThrow(
      TournamentError,
    );
  });

  it('fails if registration is not pending', async () => {
    registrationRepo.lockRegistration.mockResolvedValueOnce({
      registrationId,
      tournamentId,
      teamId: '33333333-3333-4000-8000-333333333333',
      status: 'rejected',
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
