export interface ProcessMediaTaskPayload {
  mediaId: string;
}

export interface VariantMetadata {
  path: string;
  width: number;
  height: number;
  sizeBytes: number;
  size_bytes?: number;
  bytes?: number;
  mimeType: string;
  mime_type?: string;
  mime?: string;
}

export type VariantMap = Record<string, VariantMetadata>;

export interface PostMediaRow {
  media_id: string;
  post_id: string;
  position: number;
  status: string;
  staging_path: string;
  final_prefix: string;
  source_width: number | null;
  source_height: number | null;
  display_width: number | null;
  display_height: number | null;
  blurhash: string | null;
  variants: VariantMap;
  pipeline_version: number;
  processing_attempts: number;
}
