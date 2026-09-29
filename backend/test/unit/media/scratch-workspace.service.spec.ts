import { access, mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { describe, expect, it } from 'vitest';

import { ScratchWorkspaceService } from '../../../libs/modules/media/src/infrastructure/scratch/scratch-workspace.service.js';

describe('ScratchWorkspaceService', () => {
  it('removes the isolated job directory even when work throws', async () => {
    const root = join(tmpdir(), `matchday-scratch-${process.pid}`);
    await mkdir(root, { recursive: true });
    const service = new ScratchWorkspaceService(root);
    let workspace = '';
    await expect(service.use(async (path) => {
      workspace = path;
      await writeFile(join(path, 'source.jpg'), 'bytes');
      throw new Error('failed');
    })).rejects.toThrow('failed');
    await expect(access(workspace)).rejects.toThrow();
  });
});
