import type { INestApplication } from '@nestjs/common';
import { StandardSchemaValidationPipe, VersioningType } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { TournamentCommandExecutor } from '../../libs/modules/tournaments/src/application/command-executor/tournament-command-executor.js';
import { AddSquadMemberHandler } from '../../libs/modules/tournaments/src/application/handlers/add-squad-member.handler.js';
import { ApproveRegistrationHandler } from '../../libs/modules/tournaments/src/application/handlers/approve-registration.handler.js';
import { FreezeSquadHandler } from '../../libs/modules/tournaments/src/application/handlers/freeze-squad.handler.js';
import { RecordEntryPaymentHandler } from '../../libs/modules/tournaments/src/application/handlers/record-entry-payment.handler.js';
import { RegisterTeamHandler } from '../../libs/modules/tournaments/src/application/handlers/register-team.handler.js';
import { RejectRegistrationHandler } from '../../libs/modules/tournaments/src/application/handlers/reject-registration.handler.js';
import { RemoveSquadMemberHandler } from '../../libs/modules/tournaments/src/application/handlers/remove-squad-member.handler.js';
import { VoidEntryPaymentHandler } from '../../libs/modules/tournaments/src/application/handlers/void-entry-payment.handler.js';
import { WithdrawPendingRegistrationHandler } from '../../libs/modules/tournaments/src/application/handlers/withdraw-pending-registration.handler.js';
import { WithdrawTournamentEntryHandler } from '../../libs/modules/tournaments/src/application/handlers/withdraw-tournament-entry.handler.js';
import { TournamentsParticipationController } from '../../libs/modules/tournaments/src/presentation/http/tournaments-participation.controller.js';
import {
  TokenVerificationError,
  TokenVerifier,
} from '../../libs/platform/src/auth/token-verifier.js';

const principal: AuthenticatedPrincipal = {
  userId: '10000000-0000-4000-8000-000000000001',
  sessionId: '50000000-0000-4000-8000-000000000001',
  appMetadata: {},
};

const tournamentId = '20000000-0000-4000-8000-000000000001';
const teamId = '30000000-0000-4000-8000-000000000001';
const registrationId = '40000000-0000-4000-8000-000000000001';
const entryId = '50000000-0000-4000-8000-000000000001';
const squadMemberId = '60000000-0000-4000-8000-000000000001';
const paymentId = '70000000-0000-4000-8000-000000000001';
const memberUserId = '80000000-0000-4000-8000-000000000001';
const commandId = '90000000-0000-4000-8000-000000000001';

describe('Tournaments Participation HTTP Endpoints (E2E)', () => {
  let app: INestApplication;
  const verifier = { verify: vi.fn().mockResolvedValue(principal) };
  const commandExecutor = { execute: vi.fn() };
  const registerTeamHandler = {} as RegisterTeamHandler;
  const approveRegistrationHandler = {} as ApproveRegistrationHandler;
  const rejectRegistrationHandler = {} as RejectRegistrationHandler;
  const withdrawPendingRegistrationHandler =
    {} as WithdrawPendingRegistrationHandler;
  const withdrawTournamentEntryHandler = {} as WithdrawTournamentEntryHandler;
  const addSquadMemberHandler = {} as AddSquadMemberHandler;
  const removeSquadMemberHandler = {} as RemoveSquadMemberHandler;
  const freezeSquadHandler = {} as FreezeSquadHandler;
  const recordEntryPaymentHandler = {} as RecordEntryPaymentHandler;
  const voidEntryPaymentHandler = {} as VoidEntryPaymentHandler;

  beforeEach(async () => {
    verifier.verify.mockResolvedValue(principal);
    commandExecutor.execute.mockReset();

    const module = await Test.createTestingModule({
      controllers: [TournamentsParticipationController],
      providers: [
        { provide: TokenVerifier, useValue: verifier },
        { provide: TournamentCommandExecutor, useValue: commandExecutor },
        { provide: RegisterTeamHandler, useValue: registerTeamHandler },
        {
          provide: ApproveRegistrationHandler,
          useValue: approveRegistrationHandler,
        },
        {
          provide: RejectRegistrationHandler,
          useValue: rejectRegistrationHandler,
        },
        {
          provide: WithdrawPendingRegistrationHandler,
          useValue: withdrawPendingRegistrationHandler,
        },
        {
          provide: WithdrawTournamentEntryHandler,
          useValue: withdrawTournamentEntryHandler,
        },
        {
          provide: AddSquadMemberHandler,
          useValue: addSquadMemberHandler,
        },
        {
          provide: RemoveSquadMemberHandler,
          useValue: removeSquadMemberHandler,
        },
        { provide: FreezeSquadHandler, useValue: freezeSquadHandler },
        {
          provide: RecordEntryPaymentHandler,
          useValue: recordEntryPaymentHandler,
        },
        {
          provide: VoidEntryPaymentHandler,
          useValue: voidEntryPaymentHandler,
        },
      ],
    }).compile();

    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
    app.useGlobalPipes(new StandardSchemaValidationPipe());
    await app.init();
  });

  afterEach(async () => {
    if (app) {
      await app.close();
    }
  });

  it('requires a valid bearer token for participation endpoints', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/tournaments/${tournamentId}/registrations`)
      .send({ commandId, teamId })
      .expect(401);

    expect(commandExecutor.execute).not.toHaveBeenCalled();
  });

  it('rejects invalid token with 401', async () => {
    verifier.verify.mockRejectedValueOnce(
      new TokenVerificationError('invalid_token'),
    );

    await request(app.getHttpServer())
      .post(`/api/v1/tournaments/${tournamentId}/registrations`)
      .set('authorization', 'Bearer bad-token')
      .send({ commandId, teamId })
      .expect(401);

    expect(commandExecutor.execute).not.toHaveBeenCalled();
  });

  it('registers a team via POST /tournaments/:tournamentId/registrations', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { registrationId, status: 'pending' },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournaments/${tournamentId}/registrations`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        teamId,
        message: 'Looking forward to the tournament',
      })
      .expect(201);

    expect(response.body).toEqual({
      result: { registrationId, status: 'pending' },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.team.register',
        resources: { tournamentId },
        payload: {
          teamId,
          message: 'Looking forward to the tournament',
          squadProposal: [],
        },
      }),
      registerTeamHandler,
    );
  });

  it('approves registration via POST /tournament-registrations/:registrationId/approve', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { registrationId, entryId, entryRevision: 2 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-registrations/${registrationId}/approve`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId })
      .expect(201);

    expect(response.body).toEqual({
      result: { registrationId, entryId, entryRevision: 2 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.registration.approve',
        resources: { registrationId },
      }),
      approveRegistrationHandler,
    );
  });

  it('rejects registration via POST /tournament-registrations/:registrationId/reject', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { registrationId, status: 'rejected' },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-registrations/${registrationId}/reject`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, reason: 'Roster incomplete' })
      .expect(201);

    expect(response.body).toEqual({
      result: { registrationId, status: 'rejected' },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.registration.reject',
        resources: { registrationId },
        payload: { reason: 'Roster incomplete' },
      }),
      rejectRegistrationHandler,
    );
  });

  it('withdraws registration via POST /tournament-registrations/:registrationId/withdraw', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { registrationId, status: 'withdrawn' },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-registrations/${registrationId}/withdraw`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, reason: 'Withdrawing application' })
      .expect(201);

    expect(response.body).toEqual({
      result: { registrationId, status: 'withdrawn' },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.registration.withdraw_pending',
        resources: { registrationId },
        payload: { reason: 'Withdrawing application' },
      }),
      withdrawPendingRegistrationHandler,
    );
  });

  it('withdraws tournament entry via POST /tournament-entries/:entryId/withdraw', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { entryId, status: 'withdrawn', entryRevision: 3 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/withdraw`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, reason: 'Unable to travel', expectedRevision: 2 })
      .expect(201);

    expect(response.body).toEqual({
      result: { entryId, status: 'withdrawn', entryRevision: 3 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.withdraw',
        resources: { entryId },
        expectedRevision: 2,
        payload: { reason: 'Unable to travel' },
      }),
      withdrawTournamentEntryHandler,
    );
  });

  it('adds squad member via POST /tournament-entries/:entryId/squad-members', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { squadMemberId, squadRevision: 2 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/squad-members`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, userId: memberUserId, expectedRevision: 1 })
      .expect(201);

    expect(response.body).toEqual({
      result: { squadMemberId, squadRevision: 2 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.squad.add_member',
        resources: { entryId },
        expectedRevision: 1,
        payload: { userId: memberUserId, unclaimedId: undefined },
      }),
      addSquadMemberHandler,
    );
  });

  it('removes squad member via POST /tournament-squad-members/:squadMemberId/remove', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { squadMemberId, squadRevision: 3 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-squad-members/${squadMemberId}/remove`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, reason: 'Player withdrew', expectedRevision: 2 })
      .expect(201);

    expect(response.body).toEqual({
      result: { squadMemberId, squadRevision: 3 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.squad.remove_member',
        resources: { squadMemberId },
        expectedRevision: 2,
        payload: { reason: 'Player withdrew' },
      }),
      removeSquadMemberHandler,
    );
  });

  it('freezes squad via POST /tournament-entries/:entryId/squad/freeze', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { entryId, squadState: 'frozen', squadRevision: 4 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/squad/freeze`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId, expectedRevision: 3 })
      .expect(201);

    expect(response.body).toEqual({
      result: { entryId, squadState: 'frozen', squadRevision: 4 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.freeze_squad',
        resources: { entryId },
        expectedRevision: 3,
        payload: {},
      }),
      freezeSquadHandler,
    );
  });

  it('records entry payment via POST /tournament-entries/:entryId/payments', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { paymentId, entryId, amount: 5000 },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/payments`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        amount: 5000,
        paymentChannel: 'cash',
        notes: 'Paid in person',
      })
      .expect(201);

    expect(response.body).toEqual({
      result: { paymentId, entryId, amount: 5000 },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.payment.record',
        resources: { entryId },
        payload: {
          amount: 5000,
          paymentChannel: 'cash',
          paymentReference: undefined,
          notes: 'Paid in person',
        },
      }),
      recordEntryPaymentHandler,
    );
  });

  it('voids entry payment via POST /tournament-entry-payments/:paymentId/void', async () => {
    commandExecutor.execute.mockResolvedValueOnce({
      result: { paymentId, isVoid: true },
      status: 'executed',
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/tournament-entry-payments/${paymentId}/void`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        voidReason: 'Duplicate entry recorded by mistake',
      })
      .expect(201);

    expect(response.body).toEqual({
      result: { paymentId, isVoid: true },
      status: 'executed',
    });
    expect(commandExecutor.execute).toHaveBeenCalledWith(
      principal,
      expect.objectContaining({
        commandId,
        action: 'tournament.entry.payment.void',
        resources: { paymentId },
        payload: {
          voidReason: 'Duplicate entry recorded by mistake',
        },
      }),
      voidEntryPaymentHandler,
    );
  });

  it('rejects invalid request body with 400', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/tournaments/${tournamentId}/registrations`)
      .set('authorization', 'Bearer valid-token')
      .send({ commandId: 'not-a-uuid', teamId })
      .expect(400);

    expect(commandExecutor.execute).not.toHaveBeenCalled();
  });

  it('requires expectedRevision for all revision-sensitive participation commands', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/withdraw`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        reason: 'Unable to continue',
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/squad-members`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        userId: memberUserId,
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(
        `/api/v1/tournament-squad-members/${squadMemberId}/remove`,
      )
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
        reason: 'Player withdrew',
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/api/v1/tournament-entries/${entryId}/squad/freeze`)
      .set('authorization', 'Bearer valid-token')
      .send({
        commandId,
      })
      .expect(400);

    expect(commandExecutor.execute).not.toHaveBeenCalled();
  });
});
