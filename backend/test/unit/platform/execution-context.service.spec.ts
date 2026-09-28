import { describe, expect, it } from 'vitest';

import {
  ExecutionContextService,
  type ExecutionContextValues,
} from '../../../libs/platform/src/context/execution-context.service.js';
import { normalizeCorrelationId } from '../../../libs/shared-kernel/src/identifiers/correlation-id.js';

describe('ExecutionContextService', () => {
  it('preserves context through nested asynchronous calls', async () => {
    const service = new ExecutionContextService();
    const context: ExecutionContextValues = {
      requestId: '30e4e942-c846-4f9f-bde7-49963529a8b5',
      correlationId: '9b7575be-2f8b-4d89-9162-b9d26f091119',
      userId: 'user-1',
      socketId: 'socket-1',
      eventId: 'event-1',
      jobId: 'job-1',
    };

    const observed = await service.run(context, async () => {
      await Promise.resolve();
      return service.get();
    });

    expect(observed).toEqual(context);
    expect(service.get()).toEqual({});
  });

  it('does not leak context between concurrent promises', async () => {
    const service = new ExecutionContextService();
    const run = (requestId: string, delay: number) =>
      service.run(
        { requestId, correlationId: requestId },
        async () => {
          await new Promise((resolve) => setTimeout(resolve, delay));
          return service.get().requestId;
        },
      );

    await expect(Promise.all([run('request-a', 5), run('request-b', 0)])).resolves.toEqual([
      'request-a',
      'request-b',
    ]);
  });
});

describe('normalizeCorrelationId', () => {
  it('preserves a valid UUID', () => {
    const id = '3b9e09ec-80d9-4f32-86cc-95ed204583f6';
    expect(normalizeCorrelationId(id)).toBe(id);
  });

  it.each([undefined, null, '', 'not-a-uuid', ['uuid']])(
    'replaces malformed identifier %o with a UUID',
    (value) => {
      expect(normalizeCorrelationId(value)).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
      );
    },
  );
});
