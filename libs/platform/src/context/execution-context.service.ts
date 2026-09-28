import { AsyncLocalStorage } from 'node:async_hooks';

import { Injectable } from '@nestjs/common';

export interface ExecutionContextValues {
  readonly requestId: string;
  readonly correlationId: string;
  readonly userId?: string;
  readonly socketId?: string;
  readonly eventId?: string;
  readonly jobId?: string;
}

@Injectable()
export class ExecutionContextService {
  private readonly storage = new AsyncLocalStorage<Readonly<ExecutionContextValues>>();

  run<T>(context: ExecutionContextValues, callback: () => T): T {
    return this.storage.run(Object.freeze({ ...context }), callback);
  }

  get(): Readonly<Partial<ExecutionContextValues>> {
    return this.storage.getStore() ?? Object.freeze({});
  }
}
