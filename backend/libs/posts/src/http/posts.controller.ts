import {
  Body,
  Controller,
  Get,
  Headers,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';

import {
  TOKEN_VERIFIER,
  TokenVerificationError,
  type TokenVerifier,
} from '../../../platform/src/auth/token-verifier.js';
import { CreatePostService } from '../application/create-post.service.js';
import { PublishPostService } from '../application/publish-post.service.js';
import { CreatePostCommandDto } from './post-command.dto.js';

@Controller('posts')
export class PostsController {
  constructor(
    @Inject(TOKEN_VERIFIER) private readonly verifier: TokenVerifier,
    private readonly createPost: CreatePostService,
    private readonly publishPost: PublishPostService,
  ) {}

  @Post()
  async create(
    @Headers('authorization') authorization: string | undefined,
    @Body() command: CreatePostCommandDto,
  ) {
    return this.createPost.execute(await this.authenticate(authorization), command);
  }

  @Post(':postId/publish')
  async publish(
    @Headers('authorization') authorization: string | undefined,
    @Param('postId', new ParseUUIDPipe()) postId: string,
  ) {
    return this.publishPost.execute(await this.authenticate(authorization), postId);
  }

  @Get(':postId/status')
  async status(
    @Headers('authorization') authorization: string | undefined,
    @Param('postId', new ParseUUIDPipe()) postId: string,
  ) {
    return this.publishPost.status(await this.authenticate(authorization), postId);
  }

  private async authenticate(authorization: string | undefined) {
    const match = /^Bearer ([^\s]+)$/i.exec(authorization ?? '');
    if (match?.[1] === undefined) throw new UnauthorizedException('Authentication required');
    try {
      return await this.verifier.verify(match[1]);
    } catch (error) {
      if (error instanceof TokenVerificationError) {
        if (error.code === 'verification_unavailable') {
          throw new ServiceUnavailableException('Authentication service unavailable');
        }
        throw new UnauthorizedException('Invalid access token');
      }
      throw error;
    }
  }
}
