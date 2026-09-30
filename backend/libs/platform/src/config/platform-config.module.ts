import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { buildConfiguration, type PlatformConfiguration } from './configuration.js';
import { parseEnvironment } from './environment.schema.js';

let cachedConfiguration: PlatformConfiguration | undefined;

export function loadPlatformConfiguration(): PlatformConfiguration {
  if (!cachedConfiguration) {
    cachedConfiguration = buildConfiguration(parseEnvironment(process.env));
  }
  return cachedConfiguration;
}

export function resetPlatformConfigurationCache(): void {
  cachedConfiguration = undefined;
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
