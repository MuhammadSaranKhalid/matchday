import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

const root = process.cwd();

function readRequired(path: string): string {
  const fullPath = join(root, path);
  expect(existsSync(fullPath), `${path} must exist`).toBe(true);
  return readFileSync(fullPath, 'utf8');
}

describe('production container foundation', () => {
  it('builds API and worker as separate non-root Node 24 targets', () => {
    const dockerfile = readRequired('Dockerfile');

    expect(dockerfile).toMatch(/FROM node:24[^\n]* AS build/);
    expect(dockerfile).toMatch(/FROM node:24[^\n]* AS api/);
    expect(dockerfile).toMatch(/FROM node:24[^\n]* AS worker/);
    expect(dockerfile).toContain('pnpm install --frozen-lockfile');
    expect(dockerfile).toContain('pnpm install --prod --frozen-lockfile');
    expect(dockerfile).toMatch(/USER node/g);
    expect(dockerfile).toContain('apps/api/src/main.js');
    expect(dockerfile).toContain('apps/worker/src/main.js');
    expect(dockerfile).not.toMatch(/COPY[^\n]*\.\.\//);
    expect(dockerfile).not.toMatch(
      /COPY(?: --\S+)*\s+(?:\.\.\/)*(?:app|supabase|website|media-worker)(?:\/|\s)/,
    );
  });

  it('runs both services with bounded graceful shutdown and a private Redis', () => {
    const compose = readRequired('docker-compose.yml');

    expect(compose).toMatch(/api:\n[\s\S]*target: api/);
    expect(compose).toMatch(/worker:\n[\s\S]*target: worker/);
    expect(compose.match(/init: true/g)).toHaveLength(2);
    expect(compose.match(/stop_grace_period:/g)).toHaveLength(2);
    expect(compose).toMatch(/api:\n[\s\S]*healthcheck:/);
    expect(compose).toMatch(/redis:\n/);

    const redisBlock = compose.split(/\n  redis:\n/, 2)[1] ?? '';
    expect(redisBlock).not.toMatch(/^\s{4}ports:/m);
    expect(compose).not.toMatch(/^\s{2}(postgres|supabase):/m);
    expect(compose.match(/context: \./g)).toHaveLength(2);
    expect(compose).not.toMatch(/context: \.\./);
  });
});
