import { Global, Module } from '@nestjs/common';

import { ExecutionContextService } from './execution-context.service.js';
import { RequestContextMiddleware } from './request-context.middleware.js';

@Global()
@Module({
  providers: [ExecutionContextService, RequestContextMiddleware],
  exports: [ExecutionContextService, RequestContextMiddleware],
})
export class ExecutionContextModule {}
