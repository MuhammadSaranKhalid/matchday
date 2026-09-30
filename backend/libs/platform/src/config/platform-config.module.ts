import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { buildConfiguration, type PlatformConfiguration } from './configuration.js';
import { parseEnvironment } from './environment.schema.js';

export function loadPlatformConfiguration(): PlatformConfiguration {
  return buildConfiguration(parseEnvironment(process.env));
}

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      isGlobal: true,
      load: [loadPlatformConfiguration],
    }),
  ],
  exports: [ConfigModule],
})
export class PlatformConfigModule {}
