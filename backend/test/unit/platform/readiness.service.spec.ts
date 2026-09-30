import { describe, expect, it } from 'vitest';

import { ReadinessService } from '../../../libs/platform/src/lifecycle/readiness.service.js';

describe('ReadinessService', () => {
  it('starts not ready', () => {
    expect(new ReadinessService().isReady()).toBe(false);
  });

  it('becomes ready when marked ready', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    expect(readiness.isReady()).toBe(true);
  });

  it('becomes not ready while stopping and remains not ready', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    expect(readiness.isReady()).toBe(true);

    readiness.markStopping();
    expect(readiness.isReady()).toBe(false);

    readiness.markReady();
    expect(readiness.isReady()).toBe(false);
  });

  it('marks stopping on beforeApplicationShutdown hook', () => {
    const readiness = new ReadinessService();
    readiness.markReady();
    expect(readiness.isReady()).toBe(true);

    readiness.beforeApplicationShutdown();
    expect(readiness.isReady()).toBe(false);
  });
});
