import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { FreezeSquadHandler } from '../../../libs/modules/tournaments/src/application/handlers/freeze-squad.handler.js';
import type {
  CommandQueryExecutor,
  TournamentCommandContext,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { FreezeSquadCommand } from '../../../libs/modules/tournaments/src/domain/command/participation-commands.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('FreezeSquadHandler', () => {
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
  const entryId = '88888888-8888-4000-8000-888888888888';
  const teamId = '33333333-3333-4000-8000-333333333333';

  let tournamentAuthRepo: { require: ReturnType<typeof vi.fn> };
  let entryRepo: {
    lockEntry: ReturnType<typeof vi.fn>;
    freezeSquad: ReturnType<typeof vi.fn>;
  };

  let handler: FreezeSquadHandler;

  const command: FreezeSquadCommand = {
    commandId: context.commandId,
    action: 'tournament.entry.freeze_squad',
    resources: { entryId },
    expectedRevision: 2,
    payload: {},
  };

  beforeEach(() => {
    tournamentAuthRepo = {
      require: vi.fn().mockResolvedValue(undefined),
    };
    entryRepo = {
      lockEntry: vi.fn().mockResolvedValue({
        entryId,
        tournamentId,
        teamId,
        registrationId: '77777777-7777-4000-8000-777777777777',
        status: 'active',
        entrySource: 'application',
        acceptedBy: '00000000-0000-4000-8000-000000000000',
        acceptedAt: new Date(),
        withdrawnAt: null,
        withdrawnBy: null,
        withdrawalReason: null,
        squadState: 'editable',
        squadRevision: 2,
      }),
      freezeSquad: vi.fn().mockResolvedValue(3),
    };

    handler = new FreezeSquadHandler(
      tournamentAuthRepo as unknown as TournamentAuthorizationRepository,
      entryRepo as unknown as TournamentEntryRepository,
    );
  });

  it('freezes squad successfully with revision increment', async () => {
    const result = await handler.execute(context, command);

    expect(result).toEqual({
      entryId,
      squadState: 'frozen',
      squadRevision: 3,
    });
    expect(entryRepo.lockEntry).toHaveBeenCalledWith(tx, entryId);
    expect(tournamentAuthRepo.require).toHaveBeenCalledWith(
      tx,
      tournamentId,
      'tournament.squad.review',
    );
    expect(entryRepo.freezeSquad).toHaveBeenCalledWith(tx, {
      entryId,
      expectedRevision: 2,
    });
  });

  it('fails if entry is not active', async () => {
    entryRepo.lockEntry.mockResolvedValueOnce({
      entryId,
      tournamentId,
      teamId,
      status: 'withdrawn',
      squadState: 'editable',
      squadRevision: 2,
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

  it('fails if squad is already frozen', async () => {
    entryRepo.lockEntry.mockResolvedValueOnce({
      entryId,
      tournamentId,
      teamId,
      status: 'active',
      squadState: 'frozen',
      squadRevision: 3,
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

  it('fails if actor lacks tournament squad review capability', async () => {
    tournamentAuthRepo.require.mockRejectedValueOnce(
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

  it('fails if expected revision does not match', async () => {
    const staleCommand: FreezeSquadCommand = {
      ...command,
      expectedRevision: 1, // entry has squadRevision: 2
    };

    try {
      await handler.execute(context, staleCommand);
      expect.fail('Should have thrown conflict');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.STALE_REVISION,
      );
    }
  });
});
