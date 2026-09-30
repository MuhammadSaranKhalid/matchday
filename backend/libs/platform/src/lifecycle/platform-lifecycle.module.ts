import { Global, Module } from '@nestjs/common';
import { ReadinessService } from './readiness.service.js';

@Global()
@Module({
  providers: [ReadinessService],
  exports: [ReadinessService],
})
export class PlatformLifecycleModule {}
