import type { AuthenticatedPrincipal } from '../../../../platform/src/auth/authenticated-principal.js';

export type PostProcessingStatus = 'processing' | 'published' | 'failed';
export type PostMediaState = 'pending_upload' | 'uploaded' | 'processing' | 'ready' | 'failed';

export interface CreatePostCommand {
  readonly clientCommandId: string;
  readonly publisherType: 'user' | 'team' | 'tournament';
  readonly publisherId: string;
  readonly postKind: string;
  readonly text?: string;
  readonly media: readonly Readonly<{
    width: number;
    height: number;
    bytes: number;
    mimeType: 'image/jpeg';
  }>[];
}

export interface ReservedMedia {
  readonly mediaId: string;
  readonly position: number;
  readonly stagingPath: string;
}

export interface ReservedPost {
  readonly postId: string;
  readonly status: 'draft';
  readonly media: readonly ReservedMedia[];
}

export interface OwnedPostMedia extends ReservedMedia {
  readonly status: PostMediaState;
}

export interface OwnedPost {
  readonly postId: string;
  readonly status: 'draft' | PostProcessingStatus;
  readonly media: readonly OwnedPostMedia[];
}

export interface UploadedMediaMetadata {
  readonly mediaId: string;
  readonly bytes: number;
  readonly contentType: string;
}

export const POST_COMMAND_REPOSITORY = Symbol('POST_COMMAND_REPOSITORY');

export interface PostCommandRepository {
  reserveDraft(principal: AuthenticatedPrincipal, command: CreatePostCommand): Promise<ReservedPost>;
  findOwnedPost(principal: AuthenticatedPrincipal, postId: string): Promise<OwnedPost | null>;
  markUploaded(
    principal: AuthenticatedPrincipal,
    postId: string,
    media: readonly UploadedMediaMetadata[],
  ): Promise<void>;
  publishTextOnly(principal: AuthenticatedPrincipal, postId: string): Promise<void>;
  getOwnedStatus(
    principal: AuthenticatedPrincipal,
    postId: string,
  ): Promise<PostProcessingStatus | null>;
}
