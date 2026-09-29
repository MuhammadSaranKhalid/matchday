import { describe, expect, it } from 'vitest';

import { ReadinessService } from '../../../libs/platform/src/health/readiness.service.js';

describe('ReadinessService', () => {
  it('starts not ready', () => {
    expect(new ReadinessService().isReady()).toBe(false);
  });

  it('requires both process and queue initialization', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    expect(readiness.isReady()).toBe(false);
    readiness.markQueuesInitialized();
    readiness.markReady();
    readiness.markQueuesInitialized();
    expect(readiness.isReady()).toBe(true);
  });

  it('becomes not ready while stopping and keeps that terminal state', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    readiness.markQueuesInitialized();
    readiness.markStopping();
    readiness.markStopping();
    readiness.markReady();
    readiness.markQueuesInitialized();
    expect(readiness.isReady()).toBe(false);
  });
});
