import { Module } from '@nestjs/common';
import {
  MediaModule,
  MediaUploadService,
} from '@modules/media';

import { AuthModule } from '../../../platform/src/auth/auth.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';

import { CreatePostService } from './application/create-post.service.js';
import {
  POST_COMMAND_REPOSITORY,
  type PostCommandRepository,
} from './application/post-command.ports.js';
import { PublishPostService } from './application/publish-post.service.js';
import { PostgresPostCommandRepository } from './infrastructure/persistence/postgres-post-command.repository.js';
import { PostsController } from './presentation/http/posts.controller.js';

@Module({
  imports: [AuthModule, DatabaseModule, MediaModule],
  controllers: [PostsController],
  providers: [
    {
      provide: POST_COMMAND_REPOSITORY,
      inject: [DatabaseExecutorService],
      useFactory: (database: DatabaseExecutorService) =>
        new PostgresPostCommandRepository(database),
    },
    {
      provide: CreatePostService,
      inject: [POST_COMMAND_REPOSITORY, MediaUploadService],
      useFactory: (
        repository: PostCommandRepository,
        mediaUpload: MediaUploadService,
      ) => new CreatePostService(repository, mediaUpload),
    },
    {
      provide: PublishPostService,
      inject: [
        POST_COMMAND_REPOSITORY,
        MediaUploadService,
      ],
      useFactory: (
        repository: PostCommandRepository,
        mediaUpload: MediaUploadService,
      ) => new PublishPostService(repository, mediaUpload),
    },
  ],
})
export class PostsModule {}
