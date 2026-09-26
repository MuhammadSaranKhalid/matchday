import { SupabaseClient } from '@supabase/supabase-js';
import { MediaStorage } from '../core/media-storage';
import { TransientMediaError } from '../core/errors';

export class SupabaseMediaStorage implements MediaStorage {
  constructor(private readonly supabase: SupabaseClient) {}

  async downloadStaging(stagingPath: string): Promise<Buffer> {
    const { data, error } = await this.supabase.storage
      .from('post-media-staging')
      .download(stagingPath);

    if (error || !data) {
      throw new TransientMediaError(
        `Failed to download staging asset ${stagingPath}: ${error?.message}`,
        error,
      );
    }

    return Buffer.from(await data.arrayBuffer());
  }

  async uploadFinal(path: string, bytes: Buffer): Promise<void> {
    const { error } = await this.supabase.storage
      .from('post-media')
      .upload(path, bytes, {
        contentType: 'image/webp',
        cacheControl: '31536000',
        upsert: false,
      });

    if (!error) return;

    // Idempotent retry: if file already exists with identical path, verify rather than fail
    if (error.message.toLowerCase().includes('already exists')) {
      const slash = path.lastIndexOf('/');
      const folder = slash !== -1 ? path.substring(0, slash) : '';
      const file = slash !== -1 ? path.substring(slash + 1) : path;

      const { data: listData, error: listError } = await this.supabase.storage
        .from('post-media')
        .list(folder, { search: file });

      if (!listError && listData?.some((item: any) => item.name === file)) {
        return;
      }
    }

    throw new TransientMediaError(
      `Failed to upload final immutable asset ${path}: ${error.message}`,
      error,
    );
  }

  async deleteStaging(stagingPath: string): Promise<void> {
    const { error } = await this.supabase.storage
      .from('post-media-staging')
      .remove([stagingPath]);

    if (error) {
      console.warn(`[SupabaseMediaStorage] Warning: Failed to delete staging object ${stagingPath}:`, error.message);
    }
  }
}
