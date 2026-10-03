import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { ApproveRegistrationHandler } from '../../../libs/modules/tournaments/src/application/handlers/approve-registration.handler.js';
import type {
  CommandQueryExecutor,
  TournamentCommandContext,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TournamentAuthorizationRepository,
  TournamentEntryRepository,
  TournamentRegistrationRepository,
  TournamentRootRepository,
  TournamentRootSnapshot,
  TournamentSquadRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { ApproveRegistrationCommand } from '../../../libs/modules/tournaments/src/domain/command/participation-commands.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('ApproveRegistrationHandler', () => {
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
  const entryId = '88888888-8888-4000-8000-888888888888';

  let rootRepo: {
    lockTournament: ReturnType<typeof vi.fn>;
    findTournament: ReturnType<typeof vi.fn>;
  };
  let tournamentAuthRepo: { require: ReturnType<typeof vi.fn> };
  let registrationRepo: {
    lockRegistration: ReturnType<typeof vi.fn>;
    resolveRegistration: ReturnType<typeof vi.fn>;
    getProposalMembers: ReturnType<typeof vi.fn>;
  };
  let entryRepo: {
    findActiveEntryByTeam: ReturnType<typeof vi.fn>;
    countActiveEntries: ReturnType<typeof vi.fn>;
    createEntry: ReturnType<typeof vi.fn>;
  };
  let squadRepo: {
    materializeSquadFromProposal: ReturnType<typeof vi.fn>;
    isPlayerInActiveTeamRoster: ReturnType<typeof vi.fn>;
    isPlayerInActiveTournamentSquad: ReturnType<typeof vi.fn>;
  };

  let handler: ApproveRegistrationHandler;

  const validTournamentSnapshot: TournamentRootSnapshot = {
    tournamentId,
    tournamentName: 'Summer Cup',
    tournamentType: 'knockout',
    sportId: 'cricket',
    ownerUserId: '00000000-0000-4000-8000-000000000000',
    publicationState: 'published',
    registrationState: 'open',
    entryState: 'editable',
    competitionState: 'not_started',
    terminationState: 'none',
    revision: 1,
    entryRevision: 3,
    maxTeams: 8,
    registrationDeadline: '2099-12-31',
    entryFee: 100,
  };

  // Resource-oriented: only registrationId in resources; tournamentId is derived
  const command: ApproveRegistrationCommand = {
    commandId: context.commandId,
    action: 'tournament.registration.approve',
    resources: { registrationId },
    payload: {},
  };

  beforeEach(() => {
    rootRepo = {
      lockTournament: vi.fn().mockResolvedValue({ ...validTournamentSnapshot }),
      // findTournament is called after approval to read the updated entry_revision
      findTournament: vi
        .fn()
        .mockResolvedValue({ ...validTournamentSnapshot, entryRevision: 4 }),
    };
    tournamentAuthRepo = {
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
        message: 'Hello',
        decisionReason: null,
        decidedBy: null,
        decidedAt: null,
        withdrawnAt: null,
        withdrawnBy: null,
        withdrawalReason: null,
      }),
      resolveRegistration: vi.fn().mockResolvedValue(undefined),
      getProposalMembers: vi.fn().mockResolvedValue([
        {
          proposalMemberId: 'p1',
          registrationId,
          tournamentId,
          teamId,
          userId: 'u1',
          unclaimedId: null,
        },
      ]),
    };
    entryRepo = {
      findActiveEntryByTeam: vi.fn().mockResolvedValue(null),
      countActiveEntries: vi.fn().mockResolvedValue(4),
      createEntry: vi.fn().mockResolvedValue({
        entryId,
        tournamentId,
        teamId,
        registrationId,
        status: 'active',
        entrySource: 'application',
        acceptedBy: principal.userId,
        acceptedAt: new Date(),
        withdrawnAt: null,
        withdrawnBy: null,
        withdrawalReason: null,
        squadState: 'editable',
        squadRevision: 1,
      }),
    };
    squadRepo = {
      materializeSquadFromProposal: vi.fn().mockResolvedValue(1),
      isPlayerInActiveTeamRoster: vi.fn().mockResolvedValue(true),
      isPlayerInActiveTournamentSquad: vi.fn().mockResolvedValue(false),
    };

    handler = new ApproveRegistrationHandler(
      rootRepo as unknown as TournamentRootRepository,
      tournamentAuthRepo as unknown as TournamentAuthorizationRepository,
      registrationRepo as unknown as TournamentRegistrationRepository,
      entryRepo as unknown as TournamentEntryRepository,
      squadRepo as unknown as TournamentSquadRepository,
    );
  });

  it('approves registration and materializes squad proposal successfully', async () => {
    const result = await handler.execute(context, command);

    expect(result).toEqual({
      registrationId,
      entryId,
      entryRevision: 4,
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
      status: 'approved',
      decidedBy: principal.userId,
    });
    expect(entryRepo.createEntry).toHaveBeenCalledWith(tx, {
      tournamentId,
      teamId,
      registrationId,
      acceptedBy: principal.userId,
      entrySource: 'application',
    });
    expect(squadRepo.materializeSquadFromProposal).toHaveBeenCalled();
  });

  it('rejects approval if registration is not in pending status', async () => {
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

  it('rejects approval if team already has an active entry', async () => {
    entryRepo.findActiveEntryByTeam.mockResolvedValueOnce({
      entryId: 'existing-entry',
      tournamentId,
      teamId,
      status: 'active',
    });

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown conflict');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.CONFLICT,
      );
    }
  });

  it('rejects approval if tournament capacity has been reached', async () => {
    rootRepo.lockTournament.mockResolvedValueOnce({
      ...validTournamentSnapshot,
      maxTeams: 8,
    });
    entryRepo.countActiveEntries.mockResolvedValueOnce(8);

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown capacity reached');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.CAPACITY_REACHED,
      );
    }
  });

  it('rejects approval if proposed squad member is no longer on team roster', async () => {
    squadRepo.isPlayerInActiveTeamRoster.mockResolvedValueOnce(false);

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown rule violation');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.RULE_VIOLATION,
      );
    }
  });

  it('rejects approval if entry set is locked', async () => {
    rootRepo.lockTournament.mockResolvedValueOnce({
      ...validTournamentSnapshot,
      entryState: 'locked',
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
