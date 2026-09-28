import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { buildConfiguration } from './configuration.js';
import { parseEnvironment } from './environment.schema.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      isGlobal: true,
      validate: parseEnvironment,
      load: [() => buildConfiguration(parseEnvironment(process.env))],
    }),
  ],
})
export class PlatformConfigModule {}
