import { describe, expect, it } from 'vitest';

import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';

describe('ReadinessService', () => {
  it('starts not ready', () => {
    expect(new ReadinessService().isReady()).toBe(false);
  });

  it('becomes ready and tolerates repeated ready transitions', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    readiness.markReady();
    expect(readiness.isReady()).toBe(true);
  });

  it('becomes not ready while stopping and keeps that terminal state', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    readiness.markStopping();
    readiness.markStopping();
    readiness.markReady();
    expect(readiness.isReady()).toBe(false);
  });
});
