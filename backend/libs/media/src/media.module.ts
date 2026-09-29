import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';

import type { PlatformConfiguration } from '../../platform/src/config/configuration.js';
import { MEDIA_OBJECT_STORAGE } from './application/ports/media-object-storage.js';
import { SupabaseMediaStorageService } from './infrastructure/supabase/supabase-media-storage.service.js';

@Module({
  providers: [
    {
      provide: MEDIA_OBJECT_STORAGE,
      inject: [ConfigService],
      useFactory: (configuration: ConfigService<PlatformConfiguration, true>) => {
        const storage = configuration.get('mediaStorage', { infer: true });
        const client = createClient(storage.supabaseUrl, storage.secretKey, {
          auth: {
            autoRefreshToken: false,
            detectSessionInUrl: false,
            persistSession: false,
          },
        });
        return new SupabaseMediaStorageService(client);
      },
    },
  ],
  exports: [MEDIA_OBJECT_STORAGE],
})
export class MediaModule {}
