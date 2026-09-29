import type { AuthenticatedPrincipal } from '../../../platform/src/auth/authenticated-principal.js';
import { ApplicationError } from '../../../platform/src/errors/application-error.js';
import type { MediaObjectStorage } from '../../../media/src/application/ports/media-object-storage.js';
import { MEDIA_POLICY } from '../../../media/src/domain/media-policy.js';
import type {
  MediaJobProducer,
  PostCommandRepository,
  PostProcessingStatus,
  UploadedMediaMetadata,
} from './post-command.ports.js';

export class PublishPostService {
  constructor(
    private readonly repository: Omit<PostCommandRepository, 'reserveDraft'>,
    private readonly storage: Pick<MediaObjectStorage, 'headStaging'>,
    private readonly producer: MediaJobProducer,
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
      const metadata = await this.storage.headStaging(item.stagingPath);
      if (metadata === null) {
        throw invalidMedia('POST_MEDIA_MISSING', 'An expected upload is missing');
      }
      if (metadata.bytes > MEDIA_POLICY.source.maxBytes) {
        throw invalidMedia('POST_MEDIA_TOO_LARGE', 'An uploaded image exceeds the size limit');
      }
      if (metadata.contentType !== MEDIA_POLICY.source.mimeType) {
        throw invalidMedia('POST_MEDIA_INVALID_TYPE', 'An uploaded object is not a JPEG image');
      }
      uploaded.push({
        mediaId: item.mediaId,
        bytes: metadata.bytes,
        contentType: metadata.contentType,
      });
    }

    if (uploaded.length > 0) await this.repository.markUploaded(principal, postId, uploaded);

    for (const item of post.media) {
      if (item.status !== 'ready' && item.status !== 'failed') {
        await this.producer.enqueueImage(item.mediaId);
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
  return new ApplicationError(code, message, 400);
}

function notFound(): ApplicationError {
  return new ApplicationError('POST_NOT_FOUND', 'Post not found', 404);
}
