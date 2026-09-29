import type { AuthenticatedPrincipal } from '../../../platform/src/auth/authenticated-principal.js';
import { ApplicationError } from '../../../platform/src/errors/application-error.js';
import type { MediaObjectStorage } from '../../../media/src/application/ports/media-object-storage.js';
import type {
  CreatePostCommand,
  PostCommandRepository,
} from './post-command.ports.js';

type SignedPostMedia = Readonly<{
  mediaId: string;
  position: number;
  stagingPath: string;
  uploadToken: string;
}>;

export class CreatePostService {
  constructor(
    private readonly repository: Pick<PostCommandRepository, 'reserveDraft'>,
    private readonly storage: Pick<MediaObjectStorage, 'createSignedUpload'>,
  ) {}

  async execute(principal: AuthenticatedPrincipal, command: CreatePostCommand): Promise<Readonly<{
    postId: string;
    status: 'draft';
    media: readonly SignedPostMedia[];
  }>> {
    if (command.media.length > 4) {
      throw new ApplicationError(
        'POST_MEDIA_LIMIT_EXCEEDED',
        'A post can contain at most four images',
        400,
      );
    }
    if (command.media.length === 0 && (command.text === undefined || command.text.trim() === '')) {
      throw new ApplicationError(
        'POST_CONTENT_REQUIRED',
        'A post must contain text or an image',
        400,
      );
    }

    const draft = await this.repository.reserveDraft(principal, command);
    const ordered = [...draft.media].sort((left, right) => left.position - right.position);
    const media = await Promise.all(ordered.map(async (item) => {
      const signed = await this.storage.createSignedUpload(item.stagingPath);
      return Object.freeze({
        ...item,
        uploadToken: signed.token,
      });
    }));

    return Object.freeze({ postId: draft.postId, status: 'draft', media: Object.freeze(media) });
  }
}
