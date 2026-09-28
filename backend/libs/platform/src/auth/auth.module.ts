import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PlatformConfiguration } from '../config/configuration.js';
import { SupabaseTokenVerifierService } from './supabase-token-verifier.service.js';
import { TOKEN_VERIFIER } from './token-verifier.js';

@Module({
  providers: [
    {
      provide: TOKEN_VERIFIER,
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) =>
        new SupabaseTokenVerifierService(configuration.get('auth', { infer: true })),
    },
  ],
  exports: [TOKEN_VERIFIER],
})
export class AuthModule {}
