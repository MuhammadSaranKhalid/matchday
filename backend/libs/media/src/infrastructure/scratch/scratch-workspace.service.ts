import { mkdir, mkdtemp, rm } from 'node:fs/promises';
import { join } from 'node:path';

import type { ScratchWorkspace } from '../../application/ports/scratch-workspace.js';

export class ScratchWorkspaceService implements ScratchWorkspace {
  constructor(private readonly root = '/tmp/matchday-media') {}

  async use<T>(work: (workspace: string) => Promise<T>): Promise<T> {
    await mkdir(this.root, { recursive: true, mode: 0o700 });
    const workspace = await mkdtemp(join(this.root, 'job-'));
    try {
      return await work(workspace);
    } finally {
      await rm(workspace, { recursive: true, force: true });
    }
  }
}
