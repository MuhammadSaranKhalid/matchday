import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  resolve: {
    alias: {
      '@app/api': fileURLToPath(new URL('./apps/api/src', import.meta.url)),
      '@app/worker': fileURLToPath(new URL('./apps/worker/src', import.meta.url)),
      '@modules/posts': fileURLToPath(new URL('./libs/modules/posts/src/index.ts', import.meta.url)),
      '@modules/media': fileURLToPath(new URL('./libs/modules/media/src/index.ts', import.meta.url)),
      '@modules/tournaments': fileURLToPath(new URL('./libs/modules/tournaments/src/index.ts', import.meta.url)),
      '@platform': fileURLToPath(new URL('./libs/platform/src', import.meta.url)),
      '@shared-kernel': fileURLToPath(new URL('./libs/shared-kernel/src', import.meta.url)),
    },
  },
  test: {
    environment: 'node',
    globals: false,
    restoreMocks: true,
    clearMocks: true,
    mockReset: true,
  },
});
