import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';

import type { PlatformConfiguration } from '../config/configuration.js';
import { SupabaseAuthGuard } from './supabase-auth.guard.js';
import { SupabaseTokenVerifierService } from './supabase-token-verifier.service.js';
import { TokenVerifier } from './token-verifier.js';

@Module({
  providers: [
    {
      provide: TokenVerifier,
      inject: [ConfigService],
      useFactory: (
        configuration: ConfigService<PlatformConfiguration, true>,
      ) => {
        const auth = configuration.get('auth', { infer: true });
        const client = createClient(
          auth.supabaseUrl,
          auth.publishableKey,
          {
            auth: {
              autoRefreshToken: false,
              detectSessionInUrl: false,
              persistSession: false,
            },
          },
        );

        return new SupabaseTokenVerifierService(
          client.auth,
          auth,
        );
      },
    },
    SupabaseAuthGuard,
  ],
  exports: [
    TokenVerifier,
    SupabaseAuthGuard,
  ],
})
export class AuthModule {}
