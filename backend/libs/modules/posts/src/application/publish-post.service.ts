import type { AuthenticatedPrincipal } from '@shared-kernel/identity/authenticated-principal.js';
import { ApplicationError } from '@shared-kernel/errors/application-error.js';
import type {
  MediaProcessingDispatcher,
  MediaUploadService,
} from '@modules/media';
import type {
  PostCommandRepository,
  PostProcessingStatus,
  UploadedMediaMetadata,
} from './post-command.ports.js';

export class PublishPostService {
  constructor(
    private readonly repository: Omit<PostCommandRepository, 'reserveDraft'>,
    private readonly mediaUpload: Pick<MediaUploadService, 'verifyUpload'>,
    private readonly dispatcher: Pick<MediaProcessingDispatcher, 'dispatch'>,
  ) {}

  async execute(
    principal: AuthenticatedPrincipal,
    postId: string,
  ): Promise<Readonly<{ status: 'processing' | 'published' }>> {
    const post = await this.repository.findOwnedPost(principal, postId);
    if (post === null) throw notFound();
    if (post.status === 'published') return Object.freeze({ status: 'published' });

    if (post.media.length === 0) {
      await this.repository.publishTextOnly(principal, postId);
      return Object.freeze({ status: 'published' });
    }

    const pending = post.media.filter((item) => item.status === 'pending_upload');
    const uploaded: UploadedMediaMetadata[] = [];
    for (const item of pending) {
      const result = await this.mediaUpload.verifyUpload(item.stagingPath);
      switch (result.status) {
        case 'missing':
          throw invalidMedia('POST_MEDIA_MISSING', 'An expected upload is missing');
        case 'too_large':
          throw invalidMedia('POST_MEDIA_TOO_LARGE', 'An uploaded image exceeds the size limit');
        case 'invalid_type':
          throw invalidMedia('POST_MEDIA_INVALID_TYPE', 'An uploaded object is not a JPEG image');
        case 'valid':
          uploaded.push({
            mediaId: item.mediaId,
            bytes: result.bytes,
            contentType: result.contentType,
          });
          break;
      }
    }

    if (uploaded.length > 0) await this.repository.markUploaded(principal, postId, uploaded);

    for (const item of post.media) {
      if (item.status !== 'ready' && item.status !== 'failed') {
        await this.dispatcher.dispatch(item.mediaId);
      }
    }

    return Object.freeze({ status: 'processing' });
  }

  async status(
    principal: AuthenticatedPrincipal,
    postId: string,
  ): Promise<Readonly<{ status: PostProcessingStatus }>> {
    const status = await this.repository.getOwnedStatus(principal, postId);
    if (status === null) throw notFound();
    return Object.freeze({ status });
  }
}

function invalidMedia(code: string, message: string): ApplicationError {
  return new ApplicationError(code, message, 'validation');
}

function notFound(): ApplicationError {
  return new ApplicationError('POST_NOT_FOUND', 'Post not found', 'not_found');
}
