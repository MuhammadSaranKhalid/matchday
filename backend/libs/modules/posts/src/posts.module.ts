import { getQueueToken } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import type { Queue } from 'bullmq';

import { MEDIA_OBJECT_STORAGE, type MediaObjectStorage } from '../../media/src/application/ports/media-object-storage.js';
import { MediaModule } from '@modules/media';
import { AuthModule } from '../../../platform/src/auth/auth.module.js';
import { DatabaseExecutorService } from '../../../platform/src/database/database-executor.service.js';
import { DatabaseModule } from '../../../platform/src/database/database.module.js';
import { QueueModule } from '../../../platform/src/queue/queue.module.js';
import { CreatePostService } from './application/create-post.service.js';
import type { MediaJobProducer } from './application/post-command.ports.js';
import { PublishPostService } from './application/publish-post.service.js';
import { PostsController } from './presentation/http/posts.controller.js';
import { BullMqMediaJobProducer } from './infrastructure/queue/bullmq-media-job.producer.js';
import { PostgresPostCommandRepository } from './infrastructure/persistence/postgres-post-command.repository.js';

const MEDIA_JOB_PRODUCER = Symbol('MediaJobProducer');

@Module({
  imports: [AuthModule, DatabaseModule, MediaModule, QueueModule],
  controllers: [PostsController],
  providers: [
    {
      provide: PostgresPostCommandRepository,
      inject: [DatabaseExecutorService],
      useFactory: (database: DatabaseExecutorService) => new PostgresPostCommandRepository(database),
    },
    {
      provide: MEDIA_JOB_PRODUCER,
      inject: [getQueueToken('media')],
      useFactory: (queue: Queue) => new BullMqMediaJobProducer(queue),
    },
    {
      provide: CreatePostService,
      inject: [PostgresPostCommandRepository, MEDIA_OBJECT_STORAGE],
      useFactory: (repository: PostgresPostCommandRepository, storage: MediaObjectStorage) =>
        new CreatePostService(repository, storage),
    },
    {
      provide: PublishPostService,
      inject: [PostgresPostCommandRepository, MEDIA_OBJECT_STORAGE, MEDIA_JOB_PRODUCER],
      useFactory: (
        repository: PostgresPostCommandRepository,
        storage: MediaObjectStorage,
        producer: MediaJobProducer,
      ) => new PublishPostService(repository, storage, producer),
    },
  ],
})
export class PostsModule {}
