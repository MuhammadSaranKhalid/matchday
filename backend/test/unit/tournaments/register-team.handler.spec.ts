import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { RegisterTeamHandler } from '../../../libs/modules/tournaments/src/application/handlers/register-team.handler.js';
import type {
  CommandQueryExecutor,
  TournamentCommandContext,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-command.ports.js';
import type {
  TeamAuthorizationRepository,
  TeamTournamentRepository,
  TournamentEntryRepository,
  TournamentRegistrationRepository,
  TournamentRootRepository,
  TournamentRootSnapshot,
  TournamentSquadRepository,
} from '../../../libs/modules/tournaments/src/application/ports/tournament-repository.ports.js';
import type { RegisterTeamCommand } from '../../../libs/modules/tournaments/src/domain/command/participation-commands.js';
import {
  TOURNAMENT_ERROR_CODES,
  TournamentError,
} from '../../../libs/modules/tournaments/src/domain/errors/tournament-error-codes.js';

describe('RegisterTeamHandler', () => {
  const principal: AuthenticatedPrincipal = {
    userId: '11111111-1111-4000-8000-111111111111',
    sessionId: '55555555-5555-4000-8000-555555555555',
    appMetadata: {},
  };

  // tx must expose `query` because the deadline check uses tx.query directly
  const tx = {
    query: vi.fn().mockResolvedValue({ rows: [{ is_passed: false }] }),
  } as unknown as CommandQueryExecutor;

  const context: TournamentCommandContext = {
    tx,
    principal,
    commandId: '99999999-9999-4000-8000-999999999999',
  };

  const tournamentId = '22222222-2222-4000-8000-222222222222';
  const teamId = '33333333-3333-4000-8000-333333333333';

  let rootRepo: { lockTournament: ReturnType<typeof vi.fn> };
  let registrationRepo: {
    hasPendingRegistration: ReturnType<typeof vi.fn>;
    createRegistration: ReturnType<typeof vi.fn>;
    createProposalMembers: ReturnType<typeof vi.fn>;
  };
  let entryRepo: {
    findActiveEntryByTeam: ReturnType<typeof vi.fn>;
    countActiveEntries: ReturnType<typeof vi.fn>;
  };
  let teamRepo: { findTeam: ReturnType<typeof vi.fn> };
  let teamAuthRepo: { require: ReturnType<typeof vi.fn> };
  let squadRepo: { isPlayerInActiveTeamRoster: ReturnType<typeof vi.fn> };

  let handler: RegisterTeamHandler;

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
    entryRevision: 1,
    maxTeams: 8,
    registrationDeadline: '2099-12-31',
    entryFee: 100,
  };

  const command: RegisterTeamCommand = {
    commandId: context.commandId,
    action: 'tournament.team.register',
    resources: { tournamentId },
    payload: {
      teamId,
      message: 'Looking forward to it',
      squadProposal: [
        { userId: '44444444-4444-4000-8000-444444444444' },
      ],
    },
  };

  beforeEach(() => {
    (tx as { query: ReturnType<typeof vi.fn> }).query = vi
      .fn()
      .mockResolvedValue({ rows: [{ is_passed: false }] });

    rootRepo = {
      lockTournament: vi.fn().mockResolvedValue({ ...validTournamentSnapshot }),
    };
    registrationRepo = {
      hasPendingRegistration: vi.fn().mockResolvedValue(false),
      createRegistration: vi
        .fn()
        .mockResolvedValue('77777777-7777-4000-8000-777777777777'),
      createProposalMembers: vi.fn().mockResolvedValue(undefined),
    };
    entryRepo = {
      findActiveEntryByTeam: vi.fn().mockResolvedValue(null),
      countActiveEntries: vi.fn().mockResolvedValue(2),
    };
    teamRepo = {
      findTeam: vi.fn().mockResolvedValue({
        teamId,
        sportId: 'cricket',
        status: 'active',
        teamName: 'Warriors',
      }),
    };
    teamAuthRepo = {
      require: vi.fn().mockResolvedValue(undefined),
    };
    squadRepo = {
      // proposal member active-roster check: succeed by default
      isPlayerInActiveTeamRoster: vi.fn().mockResolvedValue(true),
    };

    handler = new RegisterTeamHandler(
      rootRepo as unknown as TournamentRootRepository,
      registrationRepo as unknown as TournamentRegistrationRepository,
      entryRepo as unknown as TournamentEntryRepository,
      teamRepo as unknown as TeamTournamentRepository,
      teamAuthRepo as unknown as TeamAuthorizationRepository,
      squadRepo as unknown as TournamentSquadRepository,
    );
  });

  it('registers team and proposal members successfully', async () => {
    const result = await handler.execute(context, command);

    expect(result).toEqual({
      registrationId: '77777777-7777-4000-8000-777777777777',
      status: 'pending',
    });
    expect(rootRepo.lockTournament).toHaveBeenCalledWith(tx, tournamentId);
    expect(teamRepo.findTeam).toHaveBeenCalledWith(tx, teamId);
    expect(teamAuthRepo.require).toHaveBeenCalledWith(
      tx,
      teamId,
      'team.tournament.enter',
    );
    expect(registrationRepo.hasPendingRegistration).toHaveBeenCalledWith(
      tx,
      tournamentId,
      teamId,
    );
    expect(registrationRepo.createRegistration).toHaveBeenCalledWith(tx, {
      tournamentId,
      teamId,
      registeredBy: principal.userId,
      message: 'Looking forward to it',
    });
    expect(registrationRepo.createProposalMembers).toHaveBeenCalledWith(tx, {
      registrationId: '77777777-7777-4000-8000-777777777777',
      tournamentId,
      teamId,
      submittedBy: principal.userId,
      members: command.payload.squadProposal,
    });
  });

  it('rejects registration if registration is not open', async () => {
    rootRepo.lockTournament.mockResolvedValueOnce({
      ...validTournamentSnapshot,
      registrationState: 'closed',
    });

    await expect(handler.execute(context, command)).rejects.toThrow(
      TournamentError,
    );
  });

  it('rejects registration if deadline has passed', async () => {
    (tx as { query: ReturnType<typeof vi.fn> }).query = vi
      .fn()
      .mockResolvedValue({ rows: [{ is_passed: true }] });

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.INVALID_STATE,
      );
    }
  });

  it('rejects registration if team is not found', async () => {
    teamRepo.findTeam.mockResolvedValueOnce(null);

    try {
      await handler.execute(context, command);
      expect.fail('Should have thrown');
    } catch (error) {
      expect(error).toBeInstanceOf(TournamentError);
      expect((error as TournamentError).code).toBe(
        TOURNAMENT_ERROR_CODES.NOT_FOUND,
      );
    }
  });

  it('rejects registration if team is not active', async () => {
    teamRepo.findTeam.mockResolvedValueOnce({
      teamId,
      sportId: 'cricket',
      status: 'archived',
      teamName: 'Warriors',
    });

    await expect(handler.execute(context, command)).rejects.toThrow(
      TournamentError,
    );
  });

  it('rejects registration if team sport does not match tournament sport', async () => {
    teamRepo.findTeam.mockResolvedValueOnce({
      teamId,
      sportId: 'football',
      status: 'active',
      teamName: 'Warriors',
    });

    await expect(handler.execute(context, command)).rejects.toThrow(
      TournamentError,
    );
  });

  it('rejects registration if duplicate pending registration exists', async () => {
    registrationRepo.hasPendingRegistration.mockResolvedValueOnce(true);

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

  it('rejects registration if team already has an active entry', async () => {
    entryRepo.findActiveEntryByTeam.mockResolvedValueOnce({
      entryId: '88888888-8888-4000-8000-888888888888',
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
});
