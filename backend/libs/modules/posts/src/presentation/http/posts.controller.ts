import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { CurrentPrincipal } from '../../../../../platform/src/auth/current-principal.decorator.js';
import { SupabaseAuthGuard } from '../../../../../platform/src/auth/supabase-auth.guard.js';
import { CreatePostService } from '../../application/create-post.service.js';
import type { CreatePostCommand } from '../../application/post-command.ports.js';
import { PublishPostService } from '../../application/publish-post.service.js';
import { createPostSchema } from './schemas/create-post.schema.js';

@UseGuards(SupabaseAuthGuard)
@Controller('posts')
export class PostsController {
  constructor(
    private readonly createPost: CreatePostService,
    private readonly publishPost: PublishPostService,
  ) {}

  @Post()
  async create(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Body({ schema: createPostSchema }) command: CreatePostCommand,
  ) {
    return this.createPost.execute(principal, command);
  }

  @Post(':postId/publish')
  async publish(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('postId', new ParseUUIDPipe()) postId: string,
  ) {
    return this.publishPost.execute(principal, postId);
  }

  @Get(':postId/status')
  async status(
    @CurrentPrincipal() principal: AuthenticatedPrincipal,
    @Param('postId', new ParseUUIDPipe()) postId: string,
  ) {
    return this.publishPost.status(principal, postId);
  }
}
